class_name CampaignMap3D
extends Node3D

const ModelBuilder = preload("res://scripts/visuals/model_builder.gd")
const ProvinceVisual = preload("res://scripts/map/province_visual.gd")
const MovementPath3D = preload("res://scripts/visuals/movement_path_3d.gd")
const FXManager = preload("res://scripts/visuals/fx_manager.gd")

signal province_selected(province_id: String)
signal attack_target_selected(attacker_pid: String, defender_pid: String)
signal province_hovered(province_id: String)

var province_nodes: Dictionary = {} # pid -> ProvinceVisual
var road_container: Node3D
var river_container: Node3D
var movement_path: MovementPath3D

var current_selected_pid: String = ""
var orders_locked: bool = false

func _init():
	_ensure_containers()

func _ready():
	_ensure_containers()

func _ensure_containers():
	if road_container == null:
		road_container = Node3D.new()
		road_container.name = "Roads"
		add_child(road_container)
	if river_container == null:
		river_container = Node3D.new()
		river_container.name = "Rivers"
		add_child(river_container)
	if movement_path == null:
		movement_path = MovementPath3D.new()
		movement_path.name = "MovementPath3D"
		add_child(movement_path)

func build_map(provinces_data: Dictionary):
	_ensure_containers()
	current_selected_pid = ""
	movement_path.hide_path()
	# Detach old visuals immediately so physics picking cannot hit a stale map.
	# Clear existing
	for child in get_children():
		if child != road_container and child != river_container and child != movement_path:
			remove_child(child)
			child.queue_free()
	province_nodes.clear()
	
	for child in road_container.get_children():
		road_container.remove_child(child)
		child.queue_free()
	for child in river_container.get_children():
		river_container.remove_child(child)
		child.queue_free()
		
	# Instantiate each province
	for pid in provinces_data:
		var p_data = provinces_data[pid]
		var p_vis = ProvinceVisual.new()
		p_vis.name = "Province_" + pid
		add_child(p_vis)
		p_vis.setup(pid, p_data, _elevation(pid, provinces_data))
		
		p_vis.clicked.connect(_on_province_clicked)
		p_vis.mouse_entered_province.connect(_on_province_entered)
		p_vis.mouse_exited_province.connect(_on_province_exited)
		
		province_nodes[pid] = p_vis
		
	# Build connecting roads between adjacent provinces
	_build_connecting_roads(provinces_data)
	
	# Build winding river
	_build_river()

func _elevation(pid: String, data: Dictionary) -> float:
	if data.size() == 3 and data.has("sarai") and data.has("crossroads") and data.has("sarkel"):
		return float(ProvinceVisual.CHECKPOINT_ELEVATIONS.get(pid, 0.0))
	return 0.0

func _build_connecting_roads(provinces_data: Dictionary) -> void:
	var processed: Dictionary = {}
	for pid: String in provinces_data:
		for neighbor: String in provinces_data[pid].neighbors:
			if not provinces_data.has(neighbor):
				continue
			var edge: Array = [pid, neighbor]
			edge.sort()
			var key: String = str(edge)
			if processed.has(key):
				continue
			processed[key] = true
			var route: PackedVector3Array = surface_route(pid, neighbor)
			var a: Vector3 = route[1]
			var b: Vector3 = route[2]
			var horizontal := Vector3(b.x - a.x, 0, b.z - a.z).normalized()
			var distance: float = a.distance_to(b)
			var crossing: bool = route[0].x * route[3].x < 0.0
			var road: Node3D
			if crossing:
				road = ModelBuilder.create_bridge(distance, 0.5)
			else:
				road = Node3D.new()
				ModelBuilder._add_box(road, Vector3(0.42, 0.05, distance), Vector3(0, -0.025, 0), ModelBuilder.get_mat("dirt_road"))
			road.name = "Connection_" + pid + "_" + neighbor
			road.position = (a + b) * 0.5
			road.basis = Basis.looking_at(b - a, Vector3.UP)
			road_container.add_child(road)
			if crossing:
				_ground_bridge_supports(road)
			for endpoint: Vector3 in [a, b]:
				ModelBuilder._add_box(road_container, Vector3(0.08, 0.18, 0.08), endpoint + horizontal.cross(Vector3.UP) * 0.28 + Vector3.UP * 0.09, ModelBuilder.get_mat("snow"))

func _ground_bridge_supports(bridge: Node3D) -> void:
	# A sloping deck needs vertical posts long enough to reach the table bed.
	for i: int in range(3, bridge.get_child_count()):
		var post: MeshInstance3D = bridge.get_child(i) as MeshInstance3D
		var attachment: Vector3 = bridge.position + bridge.basis * Vector3(post.position.x, -0.08, post.position.z)
		var height: float = maxf(0.05, attachment.y + 0.44)
		var mesh := CylinderMesh.new()
		mesh.top_radius = 0.04
		mesh.bottom_radius = 0.05
		mesh.height = height
		mesh.radial_segments = 4
		post.mesh = ModelBuilder.flat_mesh(mesh)
		var center: Vector3 = attachment - Vector3.UP * height * 0.5
		post.position = bridge.basis.inverse() * (center - bridge.position)
		post.basis = bridge.basis.inverse()

func surface_route(from_pid: String, to_pid: String) -> PackedVector3Array:
	var a: Vector3 = province_nodes[from_pid].position + Vector3.UP * ProvinceVisual.SURFACE_Y
	var b: Vector3 = province_nodes[to_pid].position + Vector3.UP * ProvinceVisual.SURFACE_Y
	var horizontal: Vector3 = Vector3(b.x - a.x, 0, b.z - a.z).normalized()
	# Stay level on each plateau, then follow the same incline as its road.
	return PackedVector3Array([a, a + horizontal * 1.6, b - horizontal * 1.6, b])

func _build_river():
	# Distinct historical river winding from northern forests down through steppe
	var river_points = [
		Vector3(-4.5, -0.05, -9.0),
		Vector3(-3.5, -0.05, -6.5),
		Vector3(-2.0, -0.05, -4.0),
		Vector3(-1.0, -0.05, 0.0 if province_nodes.has("crossroads") else -1.0),
		Vector3(0.5, -0.05, 1.5),
		Vector3(2.5, -0.05, 3.5),
		Vector3(4.5, -0.05, 5.0),
	]
	
	var mat_water = ModelBuilder.get_mat("water")
	var mat_bank = ModelBuilder.get_mat("arid_steppe")
	# Faceted joint caps close the gaps between the angled river segments.
	for i: int in range(1, river_points.size() - 1):
		ModelBuilder._add_cylinder(river_container, 0.6, 0.6, 0.06, river_points[i] - Vector3.UP * 0.04, mat_bank, 8)
		ModelBuilder._add_cylinder(river_container, 0.425, 0.425, 0.08, river_points[i], mat_water, 8)
	
	for i in range(river_points.size() - 1):
		var p1 = river_points[i]
		var p2 = river_points[i+1]
		var dir = p2 - p1
		var dist = dir.length()
		var mid = (p1 + p2) * 0.5
		var angle = atan2(dir.x, dir.z)
		
		# River Sandy/Gravel Bank Bed
		var bank_mesh = MeshInstance3D.new()
		var b_box = BoxMesh.new()
		b_box.size = Vector3(1.2, 0.06, dist)
		bank_mesh.mesh = b_box
		bank_mesh.material_override = mat_bank
		bank_mesh.position = mid + Vector3(0, -0.04, 0)
		bank_mesh.rotation.y = angle
		river_container.add_child(bank_mesh)
		
		# Matte steel-blue water stays within the approved palette.
		var r_mesh = MeshInstance3D.new()
		var box = BoxMesh.new()
		box.size = Vector3(0.85, 0.08, dist)
		r_mesh.mesh = box
		r_mesh.material_override = mat_water
		r_mesh.position = mid
		r_mesh.rotation.y = angle
		river_container.add_child(r_mesh)

func _on_province_clicked(pid: String):
	var gm = _get_game_manager()
	if orders_locked or gm == null or gm.current_state != gm.GameState.CAMPAIGN or not gm.provinces.has(pid):
		return
	# Physics picking also runs behind UI panels: never issue map commands there.
	if get_viewport().gui_get_hovered_control() != null:
		return
	_play_audio("click")
	if pid == current_selected_pid:
		deselect()
		return
	if gm.provinces.has(current_selected_pid):
		var validation: Dictionary = gm.validate_army_order(current_selected_pid, pid)
		if validation.allowed:
			attack_target_selected.emit(current_selected_pid, pid)
			return
	select_province(pid)

func select_province(pid: String):
	current_selected_pid = pid
	var gm = _get_game_manager()
	
	var neighbors = []
	var is_player = false
	if gm != null and gm.provinces.has(pid):
		var sel_p = gm.provinces[pid]
		neighbors = sel_p.neighbors
		is_player = (sel_p.owner == gm.current_faction)
		
	# Update highlights on all provinces
	for id in province_nodes:
		var node = province_nodes[id] as ProvinceVisual
		var is_sel = (id == pid)
		var is_adj = neighbors.has(id)
		var is_enemy_adj = is_adj and is_player and gm != null and gm.validate_army_order(pid, id).allowed
		
		node.set_selected(is_sel)
		node.set_targetable(is_enemy_adj)
		
	if movement_path:
		movement_path.hide_path()
	province_selected.emit(pid)

func deselect():
	current_selected_pid = ""
	for id in province_nodes:
		var node = province_nodes[id] as ProvinceVisual
		node.set_selected(false)
		node.set_targetable(false)
	if movement_path:
		movement_path.hide_path()
	province_selected.emit("")

func _on_province_entered(pid: String):
	if orders_locked:
		return
	province_hovered.emit(pid)
	
	# Show movement or attack preview path if adjacent to selected province
	if current_selected_pid != "" and pid != current_selected_pid and province_nodes.has(current_selected_pid) and province_nodes.has(pid):
		var gm = _get_game_manager()
		if gm and gm.provinces.has(current_selected_pid):
			var sel_p = gm.provinces[current_selected_pid]
			if gm.validate_army_order(current_selected_pid, pid).allowed:
				var p2 = gm.provinces[pid]
				var pos1: Vector3 = province_nodes[current_selected_pid].position + Vector3.UP * ProvinceVisual.SURFACE_Y
				var pos2: Vector3 = province_nodes[pid].position + Vector3.UP * ProvinceVisual.SURFACE_Y
				var is_attack = (sel_p.owner == gm.current_faction and p2.owner != gm.current_faction)
				if movement_path:
					movement_path.position = pos1
					movement_path.basis = Basis.looking_at(pos2 - pos1, Vector3.UP)
					movement_path.show_path(Vector3.ZERO, Vector3(0, 0, -pos1.distance_to(pos2)), is_attack)
					movement_path.mat_move.albedo_color = ModelBuilder.GREEN
					movement_path.mat_attack.albedo_color = ModelBuilder.GOLD

func _on_province_exited(_pid: String):
	province_hovered.emit("")
	if movement_path:
		movement_path.hide_path()

func animate_army_march(from_pid: String, to_pid: String, on_complete: Callable):
	var gm = _get_game_manager()
	if gm == null or not gm.provinces.has(from_pid) or not gm.provinces.has(to_pid):
		on_complete.call()
		return
		
	var route: PackedVector3Array = surface_route(from_pid, to_pid)
	var pos1: Vector3 = route[0]
	var pos2: Vector3 = route[3]
	var dir = pos2 - pos1
	
	# Render the host's actual unit family instead of a Mongol horse for everyone.
	var army = gm.provinces[from_pid].army
	if army == null:
		army = gm.provinces[to_pid].army
	var unit_type: String = army.units[0].type if army != null and not army.units.is_empty() else "infantry"
	var color: Color = ModelBuilder.GOLD if army != null and army.faction == "mongol" else ModelBuilder.BLUE
	var march_unit: Node3D
	match unit_type:
		"horse_archer", "light_cavalry": march_unit = ModelBuilder.create_horse_archer_unit(color)
		"heavy_cavalry": march_unit = ModelBuilder.create_heavy_cavalry_unit(color)
		"spearman": march_unit = ModelBuilder.create_spearman_unit(color)
		"siege": march_unit = ModelBuilder.create_siege_engine(color)
		_: march_unit = ModelBuilder.create_infantry_unit(color)
	march_unit.scale = Vector3(0.55, 0.55, 0.55)
	march_unit.position = pos1
	march_unit.rotation.y = atan2(dir.x, dir.z)
	add_child(march_unit)
	
	_play_audio("cavalry")
	FXManager.spawn_dust_puff(self, pos1)
	
	var tw = create_tween()
	var duration = 0.95
	
	# Stay on each plateau, following the road incline only between its edges.
	var total_length: float = 0.0
	for i: int in range(3):
		total_length += route[i].distance_to(route[i + 1])
	for i: int in range(3):
		var segment_duration: float = duration * route[i].distance_to(route[i + 1]) / maxf(total_length, 0.001)
		tw.tween_property(march_unit, "position", route[i + 1], segment_duration)
	
	# Mid-point dust effect
	var mid: Vector3 = (route[1] + route[2]) * 0.5
	var dust_tween: Tween = create_tween()
	dust_tween.tween_callback(func(): FXManager.spawn_dust_puff(self, mid)).set_delay(duration * 0.5)
	
	tw.tween_callback(func():
		FXManager.spawn_dust_puff(self, pos2)
		_play_audio("drum")
		march_unit.queue_free()
		on_complete.call()
	)

func _play_audio(name: String):
	var loop = Engine.get_main_loop() as SceneTree
	if loop and loop.root and loop.root.has_node("AudioManager"):
		var am = loop.root.get_node("AudioManager")
		match name:
			"click": am.play_click()
			"horn": am.play_war_horn()
			"cavalry": am.play_cavalry()
			"drum": am.play_war_drum()

func refresh_all(provinces_data: Dictionary):
	for pid in provinces_data:
		if province_nodes.has(pid):
			(province_nodes[pid] as ProvinceVisual).refresh_from_data(provinces_data[pid])
	if current_selected_pid != "":
		select_province(current_selected_pid)

func _get_game_manager():
	var loop = Engine.get_main_loop() as SceneTree
	if loop and loop.root:
		return loop.root.get_node_or_null("GameManager")
	return null
