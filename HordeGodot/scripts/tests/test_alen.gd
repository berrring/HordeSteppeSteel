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
	# Test authored offsets and an in-flight tracking target, not only defaults.
	rig.camera.projection = Camera3D.PROJECTION_PERSPECTIVE
	rig.current_zoom = 14.0
	rig.target_zoom = 18.0
	rig._update_camera_transform()
	rig.position = Vector3(2, 0, -3)
	rig.target_position = Vector3(4, 0, 1)
	rig.camera.position += Vector3(0.4, 0.3, 0.7)
	rig.camera.rotation.z = 0.03
	rig.camera.h_offset = 0.15
	rig.camera.v_offset = -0.1
	var before_transform: Transform3D = rig.camera.global_transform
	var before_target: Vector3 = rig.target_position
	rig.toggle_projection()
	check(rig.camera.global_transform.is_equal_approx(before_transform), "Custom camera transform survives orthographic switch")
	check(rig.target_position == before_target and rig.target_zoom == 18.0, "Switch preserves tracking and in-flight zoom target")
	check(is_equal_approx(rig.camera.h_offset, 0.15) and is_equal_approx(rig.camera.v_offset, -0.1), "Lens offsets survive switch")
	rig.toggle_projection()
	check(rig.camera.global_transform.is_equal_approx(before_transform), "Custom transform survives perspective return without zoom")
	rig.toggle_projection()
	rig.target_position = rig.position
	rig.target_zoom = rig.current_zoom
	before_transform = rig.camera.global_transform
	var previous_zoom: float = rig.current_zoom
	rig._unhandled_input(wheel)
	rig._process(0.01)
	check(rig.current_zoom < previous_zoom and rig.current_zoom > rig.target_zoom, "Wheel zoom interpolates smoothly")
	check(rig.camera.global_transform.is_equal_approx(before_transform), "Orthographic interpolation never moves camera")
	rig._process(1.0)
	var ortho_size: float = rig.camera.size
	rig.toggle_projection()
	check(is_equal_approx(ortho_size, rig.camera.position.z * 2.0 * tan(deg_to_rad(21.0))), "Return from zoomed orthographic matches tracked-plane footprint")
	check(is_equal_approx(rig.camera.position.x, 0.4) and is_equal_approx(rig.camera.position.y, 0.3), "Zoom preserves authored lateral offsets")
	for projection: int in [Camera3D.PROJECTION_PERSPECTIVE, Camera3D.PROJECTION_ORTHOGONAL]:
		rig.camera.projection = projection
		for i: int in range(30):
			rig._unhandled_input(wheel)
		check(rig.target_zoom == rig.min_zoom, "Minimum zoom limit in mode " + str(projection))
		wheel.button_index = MOUSE_BUTTON_WHEEL_DOWN
		for i: int in range(30):
			rig._unhandled_input(wheel)
		check(rig.target_zoom == rig.max_zoom, "Maximum zoom limit in mode " + str(projection))
		wheel.button_index = MOUSE_BUTTON_WHEEL_UP
		rig._process(1.0)
		check(rig.camera.fov == 42.0, "FOV remains exactly 42 while zooming in mode " + str(projection))
	rig.camera.position = Vector3(0, 0, rig.current_zoom)
	rig.camera.rotation = Vector3.ZERO
	rig.camera.h_offset = 0.0
	rig.camera.v_offset = 0.0
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
		var collider: CollisionShape3D = province.get_node("ClickArea").get_child(0)
		var cylinder: CylinderShape3D = collider.shape
		check(is_equal_approx(collider.global_position.y + cylinder.height * 0.5, expected + 0.12), pid + " collider top matches grass surface")
		check(is_equal_approx(collider.global_position.y - cylinder.height * 0.5, -0.44), pid + " collider base rests on table")
		check(is_equal_approx(province.get_node("Settlement").position.y, 0.12), pid + " settlement rests on terrain")
		check(is_equal_approx(province.get_node("ArmyNode").position.y, 0.12), pid + " army rests on terrain")
		var cap: MeshInstance3D = province.get_node("GrassCap")
		var terrain_material: StandardMaterial3D = cap.material_override
		check(is_equal_approx(terrain_material.roughness, 0.85), pid + " exact terrain roughness")
		var arrays: Array = cap.mesh.surface_get_arrays(0)
		var normals: PackedVector3Array = arrays[Mesh.ARRAY_NORMAL]
		var flat: bool = true
		for i: int in range(0, normals.size(), 3):
			flat = flat and normals[i].is_equal_approx(normals[i + 1]) and normals[i].is_equal_approx(normals[i + 2])
		check(flat, pid + " terrain has flat triangle normals")
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
	var bridge: Node3D = map.road_container.get_node("Connection_sarai_crossroads")
	check(bridge.get_child_count() == 7, "Sarai to Crossroads uses a supported timber bridge")
	for i: int in range(3, bridge.get_child_count()):
		var post: MeshInstance3D = bridge.get_child(i)
		var bottom: Vector3 = post.to_global(Vector3(0, post.mesh.get_aabb().position.y, 0))
		check(is_equal_approx(bottom.y, -0.44), "Bridge support reaches table bed: " + str(i))
	var route: PackedVector3Array = map.surface_route("sarai", "crossroads")
	check(is_equal_approx(route[0].y, route[1].y) and is_equal_approx(route[2].y, route[3].y), "March stays level on both plateaus")
	check(route[1].y < route[2].y, "March follows elevated road incline")
	var completed: Array[bool] = [false]
	map.animate_army_march("sarai", "crossroads", func(): completed[0] = true)
	await create_timer(0.15).timeout
	var marching: Node3D = map.get_node("HorseArcher")
	check(is_equal_approx(marching.position.y, route[0].y), "Animated march remains on departure plateau")
	await create_timer(1.4).timeout
	check(completed[0] and not is_instance_valid(marching), "Animated march completes and removes temporary unit")
	check(Models.get_mat("dirt_road").albedo_color.a == 1.0, "March dust does not fade shared road materials")
	map.select_province("sarai")
	var path: Node3D = map.movement_path
	map.build_map(gm.provinces)
	await process_frame
	check(is_instance_valid(path) and not path.is_queued_for_deletion(), "Map rebuild preserves movement preview")
	gm.start_new_campaign("mongol", "full_campaign")
	map.build_map(gm.provinces)
	check(map.current_selected_pid.is_empty(), "Rebuild clears stale selection")
	check(map.province_nodes.size() == 12 and gm.factions.size() == 6, "Full campaign retains all provinces and factions")
	check(is_zero_approx(map.province_nodes.sarai.position.y), "Full campaign retains original terrain layout")
	for pid: String in map.province_nodes:
		check(is_zero_approx(map.province_nodes[pid].position.y), "Full campaign original elevation: " + pid)
	gm.start_new_campaign("mongol", "checkpoint_slice")
	map.build_map(gm.provinces)
	check(map.province_nodes.size() == 3 and is_equal_approx(map.province_nodes.crossroads.position.y, 0.5), "Full campaign returns to elevated checkpoint")
	var allowed: Array[Color] = [Models.GREEN, Models.BROWN, Models.GOLD, Models.WHITE, Models.BLUE]
	for key: String in Models._materials:
		var mat: StandardMaterial3D = Models._materials[key]
		check(mat.albedo_color in allowed and mat.metallic == 0.0 and mat.roughness >= 0.85, "Palette and matte material: " + key)
	map.free()
	rig.free()
	print("ALEN: ", checks - failures, "/", checks, " passed")
	quit(1 if failures else 0)
