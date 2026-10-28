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
	# Clear existing
	for child in get_children():
		if child != road_container and child != river_container:
			child.queue_free()
	province_nodes.clear()
	
	for child in road_container.get_children():
		child.queue_free()
	for child in river_container.get_children():
		child.queue_free()
		
	# Instantiate each province
	for pid in provinces_data:
		var p_data = provinces_data[pid]
		var p_vis = ProvinceVisual.new()
		p_vis.name = "Province_" + pid
		add_child(p_vis)
		p_vis.setup(pid, p_data)
		
		p_vis.clicked.connect(_on_province_clicked)
		p_vis.mouse_entered_province.connect(_on_province_entered)
		p_vis.mouse_exited_province.connect(_on_province_exited)
		
		province_nodes[pid] = p_vis
		
	# Build connecting roads between adjacent provinces
	_build_connecting_roads(provinces_data)
	
	# Build winding river
	_build_river()

func _build_connecting_roads(provinces_data: Dictionary):
	var processed_edges = {}
	var mat_road = ModelBuilder.get_mat("dirt_road")
	
	for pid in provinces_data:
		var p1 = provinces_data[pid]
		var pos1 = Vector3(p1.x, 0.06, p1.z)
		
		for neighbor_id in p1.neighbors:
			var edge_key = [pid, neighbor_id]
			edge_key.sort()
			var key_str = edge_key[0] + "_" + edge_key[1]
			
			if processed_edges.has(key_str):
				continue
			processed_edges[key_str] = true
			
			if provinces_data.has(neighbor_id):
				var p2 = provinces_data[neighbor_id]
				var pos2 = Vector3(p2.x, 0.06, p2.z)
				
				var dir = pos2 - pos1
				var dist = dir.length()
				var mid = (pos1 + pos2) * 0.5
				
				# Check if this road crosses the central river line (between X=-2 and X=2)
				var is_river_crossing = (pos1.x * pos2.x < 0 or (abs(mid.x) < 1.2 and abs(mid.z) < 2.5))
				
				if is_river_crossing:
					# Place a stylized wooden bridge over the river
					var bridge = ModelBuilder.create_bridge(dist * 0.45, 0.5)
					bridge.position = mid + Vector3(0, 0.05, 0)
					bridge.rotation.y = atan2(dir.x, dir.z)
					road_container.add_child(bridge)
				else:
					# Create low-poly dirt road strip
					var road_mesh = MeshInstance3D.new()
					var mesh = BoxMesh.new()
					mesh.size = Vector3(0.42, 0.05, dist * 0.70)
					road_mesh.mesh = mesh
					road_mesh.material_override = mat_road
					road_mesh.position = mid
					road_mesh.rotation.y = atan2(dir.x, dir.z)
					road_container.add_child(road_mesh)

func _build_river():
	# Distinct historical river winding from northern forests down through steppe
	var river_points = [
		Vector3(-4.5, -0.05, -9.0),
		Vector3(-3.5, -0.05, -6.5),
		Vector3(-2.0, -0.05, -4.0),
		Vector3(-1.0, -0.05, -1.0),
		Vector3(0.5, -0.05, 1.5),
		Vector3(2.5, -0.05, 3.5),
		Vector3(4.5, -0.05, 5.0),
	]
	
	var mat_water = ModelBuilder.get_mat("water")
	var mat_bank = ModelBuilder.get_mat("arid_steppe")
	
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
		
		# Stylized Water Surface with specular gloss
		var r_mesh = MeshInstance3D.new()
		var box = BoxMesh.new()
		box.size = Vector3(0.85, 0.08, dist)
		r_mesh.mesh = box
		r_mesh.material_override = mat_water
		r_mesh.position = mid
		r_mesh.rotation.y = angle
		river_container.add_child(r_mesh)

func _on_province_clicked(pid: String):
	_play_audio("click")
	var gm = _get_game_manager()
	if gm == null or not gm.provinces.has(pid):
		return
		
	var clicked_p = gm.provinces[pid]
	var player_faction = "mongol"
	
	if current_selected_pid == "":
		select_province(pid)
	else:
		var current_p = gm.provinces[current_selected_pid]
		
		if pid == current_selected_pid:
			deselect()
		elif current_p.owner == player_faction and current_p.neighbors.has(pid):
			if clicked_p.owner != player_faction:
				_play_audio("horn")
				attack_target_selected.emit(current_selected_pid, pid)
			else:
				select_province(pid)
		else:
			select_province(pid)

func select_province(pid: String):
	current_selected_pid = pid
	var gm = _get_game_manager()
	
	var neighbors = []
	var is_player = false
	if gm != null and gm.provinces.has(pid):
		var sel_p = gm.provinces[pid]
		neighbors = sel_p.neighbors
		is_player = (sel_p.owner == "mongol")
		
	# Update highlights on all provinces
	for id in province_nodes:
		var node = province_nodes[id] as ProvinceVisual
		var is_sel = (id == pid)
		var is_adj = neighbors.has(id)
		var is_enemy_adj = is_adj and is_player and gm != null and gm.provinces.has(id) and gm.provinces[id].owner != "mongol"
		
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
	province_hovered.emit(pid)
	
	# Show movement or attack preview path if adjacent to selected province
	if current_selected_pid != "" and pid != current_selected_pid and province_nodes.has(current_selected_pid) and province_nodes.has(pid):
		var gm = _get_game_manager()
		if gm and gm.provinces.has(current_selected_pid):
			var sel_p = gm.provinces[current_selected_pid]
			if sel_p.neighbors.has(pid):
				var p1 = gm.provinces[current_selected_pid]
				var p2 = gm.provinces[pid]
				var pos1 = Vector3(p1.x, 0, p1.z)
				var pos2 = Vector3(p2.x, 0, p2.z)
				var is_attack = (sel_p.owner == "mongol" and p2.owner != "mongol")
				if movement_path:
					movement_path.show_path(pos1, pos2, is_attack)

func _on_province_exited(_pid: String):
	province_hovered.emit("")
	if movement_path:
		movement_path.hide_path()

func animate_army_march(from_pid: String, to_pid: String, on_complete: Callable):
	var gm = _get_game_manager()
	if gm == null or not gm.provinces.has(from_pid) or not gm.provinces.has(to_pid):
		on_complete.call()
		return
		
	var p1 = gm.provinces[from_pid]
	var p2 = gm.provinces[to_pid]
	var pos1 = Vector3(p1.x, 0.05, p1.z)
	var pos2 = Vector3(p2.x, 0.05, p2.z)
	var dir = pos2 - pos1
	
	# Temporary marching figurine
	var march_unit = ModelBuilder.create_horse_archer_unit(Color(0.92, 0.75, 0.22))
	march_unit.scale = Vector3(0.55, 0.55, 0.55)
	march_unit.position = pos1
	march_unit.rotation.y = atan2(dir.x, dir.z)
	add_child(march_unit)
	
	_play_audio("cavalry")
	FXManager.spawn_dust_puff(self, pos1)
	
	var tw = create_tween()
	var duration = 0.95
	
	# Interpolate position
	tw.tween_property(march_unit, "position", pos2, duration).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN_OUT)
	
	# Mid-point dust effect
	var mid = (pos1 + pos2) * 0.5
	tw.parallel().tween_callback(func():
		FXManager.spawn_dust_puff(self, mid)
	).set_delay(duration * 0.5)
	
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
