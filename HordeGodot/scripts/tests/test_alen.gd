extends SceneTree

const CameraRig = preload("res://scripts/camera/strategic_camera.gd")
const Map = preload("res://scripts/map/campaign_map_3d.gd")
const Models = preload("res://scripts/visuals/model_builder.gd")
var failures: int = 0
var checks: int = 0

func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok:
		failures += 1
	print("PASS " if ok else "FAIL ", label)

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var rig := CameraRig.new()
	root.add_child(rig)
	rig.set_process(false)
	var original: Transform3D = rig.camera.global_transform
	var event := InputEventKey.new()
	event.keycode = KEY_F10
	event.pressed = true
	rig._unhandled_input(event)
	check(rig.camera.projection == Camera3D.PROJECTION_ORTHOGONAL, "F10 switches to orthographic")
	check(rig.camera.global_transform.is_equal_approx(original), "Projection toggle preserves camera transform")
	var distance: float = rig.camera.position.z
	var size: float = rig.camera.size
	var wheel := InputEventMouseButton.new()
	wheel.button_index = MOUSE_BUTTON_WHEEL_UP
	wheel.pressed = true
	rig._unhandled_input(wheel)
	rig._process(1.0)
	check(rig.camera.size < size and is_equal_approx(rig.camera.position.z, distance), "Orthographic wheel zoom changes size only")
	event.echo = true
	rig._unhandled_input(event)
	check(rig.camera.projection == Camera3D.PROJECTION_ORTHOGONAL, "Key repeat does not toggle")
	event.echo = false
	rig._unhandled_input(event)
	check(rig.camera.projection == Camera3D.PROJECTION_PERSPECTIVE and rig.camera.fov == 42.0, "F10 restores original perspective FOV")
	rig._unhandled_input(wheel)
	rig._process(1.0)
	check(rig.camera.position.z < distance, "Perspective zoom moves camera")
	for projection: int in [Camera3D.PROJECTION_PERSPECTIVE, Camera3D.PROJECTION_ORTHOGONAL]:
		rig.camera.projection = projection
		var drag := InputEventMouseButton.new()
		drag.button_index = MOUSE_BUTTON_RIGHT
		drag.pressed = true
		drag.position = Vector2(100, 100)
		rig._unhandled_input(drag)
		var before: Vector3 = rig.target_position
		var motion := InputEventMouseMotion.new()
		motion.position = Vector2(150, 120)
		rig._unhandled_input(motion)
		check(not rig.target_position.is_equal_approx(before), "Mouse drag pans in mode " + str(projection))
		drag.pressed = false
		rig._unhandled_input(drag)
		Input.action_press("camera_pan_right")
		before = rig.target_position
		rig._process(0.1)
		Input.action_release("camera_pan_right")
		check(rig.target_position.x > before.x, "Keyboard pans in mode " + str(projection))
	var gm = root.get_node("GameManager")
	gm.start_new_campaign("mongol", "checkpoint_slice")
	var map := Map.new()
	root.add_child(map)
	map.build_map(gm.provinces)
	await physics_frame
	await physics_frame
	for pid: String in ["sarai", "crossroads", "sarkel"]:
		var province: Node3D = map.province_nodes[pid]
		var expected: float = {"sarai": 0.0, "crossroads": 0.5, "sarkel": 0.3}[pid]
		check(is_equal_approx(province.position.y, expected), pid + " elevation")
		check(province.get_node("ClickArea").global_position.is_equal_approx(province.global_position), pid + " collider follows terrain")
		for projection: int in [Camera3D.PROJECTION_PERSPECTIVE, Camera3D.PROJECTION_ORTHOGONAL]:
			rig.camera.projection = projection
			rig.target_position = Vector3(province.position.x, 0, province.position.z)
			rig._process(1.0)
			var screen: Vector2 = rig.camera.unproject_position(province.global_position + Vector3.UP * 0.5)
			var origin: Vector3 = rig.camera.project_ray_origin(screen)
			var query := PhysicsRayQueryParameters3D.create(origin, origin + rig.camera.project_ray_normal(screen) * 200.0)
			query.collide_with_areas = true
			query.collide_with_bodies = false
			var hit: Dictionary = rig.get_world_3d().direct_space_state.intersect_ray(query)
			check(not hit.is_empty() and hit.collider == province.get_node("ClickArea"), pid + " ray picking in mode " + str(projection))
	check(map.road_container.get_child_count() == 6, "Two complete connections and four endpoint markers")
	for road: Node3D in map.road_container.get_children():
		if not str(road.name).begins_with("Connection_"):
			continue
		var deck: MeshInstance3D = road.get_child(0)
		var size_z: float = (deck.mesh as BoxMesh).size.z
		var endpoint_a: Vector3 = road.to_global(Vector3(0, 0, size_z * 0.5))
		var endpoint_b: Vector3 = road.to_global(Vector3(0, 0, -size_z * 0.5))
		var ids: PackedStringArray = str(road.name).split("_")
		check(is_equal_approx(endpoint_a.y, map.province_nodes[ids[1]].position.y + 0.12) and is_equal_approx(endpoint_b.y, map.province_nodes[ids[2]].position.y + 0.12), "Road meets both elevated surfaces: " + str(road.name))
	var path: Node3D = map.movement_path
	map.build_map(gm.provinces)
	await process_frame
	check(is_instance_valid(path) and not path.is_queued_for_deletion(), "Map rebuild preserves movement preview")
	gm.start_new_campaign("mongol", "full_campaign")
	map.build_map(gm.provinces)
	check(map.province_nodes.size() == 12 and gm.factions.size() == 6, "Full campaign retains all provinces and factions")
	check(is_zero_approx(map.province_nodes.sarai.position.y), "Full campaign retains original terrain layout")
	var allowed: Array[Color] = [Models.GREEN, Models.BROWN, Models.GOLD, Models.WHITE, Models.BLUE]
	for key: String in Models._materials:
		var mat: StandardMaterial3D = Models._materials[key]
		check(mat.albedo_color in allowed and mat.metallic == 0.0 and mat.roughness >= 0.85, "Palette and matte material: " + key)
	map.free()
	rig.free()
	print("ALEN: ", checks - failures, "/", checks, " passed")
	quit(1 if failures else 0)
