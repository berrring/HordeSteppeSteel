class_name ProvinceVisual
extends Node3D

const ModelBuilder = preload("res://scripts/visuals/model_builder.gd")

signal clicked(province_id: String)
signal mouse_entered_province(province_id: String)
signal mouse_exited_province(province_id: String)

var province_id: String = ""
var province_data: Dictionary = {}
var is_selected: bool = false
var is_targetable: bool = false
var is_hovered: bool = false

# Visual nodes
var terrain_mesh: MeshInstance3D
var settlement_node: Node3D
var army_node: Node3D
var highlight_ring: MeshInstance3D
var banner_node: Node3D
var label_3d: Label3D
var army_label_3d: Label3D
var collision_area: Area3D

func setup(p_id: String, data: Dictionary):
	province_id = p_id
	province_data = data
	position = Vector3(data.x, 0, data.z)
	
	_build_terrain()
	_build_settlement()
	_build_decorations()
	_build_army_representation()
	_build_labels()
	_build_highlight_ring()
	_build_interaction_area()
	update_state()

func _build_terrain():
	# Distinct biome materials
	var mat_name = "steppe_grass"
	if province_id in ["novgorod", "moscow", "kiev"]:
		mat_name = "forest_grass"
	elif province_id in ["tabriz", "samarkand", "bukhara"]:
		mat_name = "arid_steppe"
	elif province_id in ["karakorum", "shangdu"]:
		mat_name = "rock"
	
	var mat = ModelBuilder.get_mat(mat_name)
	
	# Hex-like low-poly terrain plateau (radius 1.8, height 0.3)
	terrain_mesh = MeshInstance3D.new()
	var mesh = CylinderMesh.new()
	mesh.top_radius = 1.65
	mesh.bottom_radius = 1.8
	mesh.height = 0.35
	mesh.radial_segments = 7 # Stylized faceted look
	terrain_mesh.mesh = mesh
	terrain_mesh.material_override = mat
	terrain_mesh.position = Vector3(0, -0.175, 0)
	add_child(terrain_mesh)
	
	# Territory border ring
	var border_ring = MeshInstance3D.new()
	var t_mesh = TorusMesh.new()
	t_mesh.inner_radius = 1.6
	t_mesh.outer_radius = 1.72
	t_mesh.rings = 7
	t_mesh.ring_segments = 4
	border_ring.mesh = t_mesh
	border_ring.material_override = _get_faction_mat(province_data.owner)
	border_ring.position = Vector3(0, 0.01, 0)
	border_ring.name = "BorderRing"
	add_child(border_ring)

func _build_settlement():
	var owner_f = province_data.owner
	var is_cap = province_data.is_capital
	
	match owner_f:
		"mongol":
			settlement_node = ModelBuilder.create_mongol_camp(is_cap)
		"cuman", "kipchak":
			settlement_node = ModelBuilder.create_cuman_camp(is_cap)
		"rus":
			settlement_node = ModelBuilder.create_rus_fortress(is_cap)
		"byzantine":
			settlement_node = ModelBuilder.create_byzantine_settlement(is_cap)
		"seljuk":
			settlement_node = ModelBuilder.create_seljuk_settlement(is_cap)
		"khwarazm":
			settlement_node = ModelBuilder.create_khwarazm_settlement(is_cap)
		_:
			settlement_node = ModelBuilder.create_neutral_outpost()
	
	settlement_node.position = Vector3(0, 0, 0)
	settlement_node.name = "Settlement"
	add_child(settlement_node)

func _build_decorations():
	# Procedural environmental dressing based on province type
	var seed_val = province_id.hash()
	var rng = RandomNumberGenerator.new()
	rng.seed = seed_val
	
	# Trees
	var tree_count = 3
	if province_id in ["novgorod", "moscow", "kiev"]:
		tree_count = 6 # Rus' forest province
	elif province_id in ["sarai", "kipchak"]:
		tree_count = 2 # Steppe grasslands
	elif province_id in ["tabriz", "bukhara"]:
		tree_count = 1 # Arid steppe
		
	for i in range(tree_count):
		var angle = rng.randf_range(0.0, TAU)
		var dist = rng.randf_range(0.8, 1.4)
		var pos = Vector3(cos(angle) * dist, 0, sin(angle) * dist)
		
		var tree: Node3D
		if province_id in ["novgorod", "kiev"]:
			tree = ModelBuilder.create_birch_tree(rng.randf_range(0.8, 1.15))
		elif province_id in ["moscow", "karakorum"]:
			tree = ModelBuilder.create_pine_tree(rng.randf_range(0.8, 1.2))
		else:
			tree = ModelBuilder.create_oak_tree(rng.randf_range(0.75, 1.1))
			
		tree.position = pos
		tree.rotation.y = rng.randf_range(0, TAU)
		add_child(tree)
		
	# Rocks & Pasture
	if rng.randf() > 0.4:
		var rocks = ModelBuilder.create_rock_cluster(rng.randf_range(0.7, 1.0))
		rocks.position = Vector3(rng.randf_range(-1.2, 1.2), 0, rng.randf_range(-1.2, 1.2))
		add_child(rocks)
		
	# Steppe grass tufts & shrubs
	for j in range(4):
		var g_angle = rng.randf_range(0.0, TAU)
		var g_dist = rng.randf_range(0.6, 1.5)
		var g_pos = Vector3(cos(g_angle) * g_dist, 0, sin(g_angle) * g_dist)
		var tuft = ModelBuilder._add_cone(self, 0.12, 0.22, g_pos + Vector3(0, 0.11, 0), ModelBuilder.get_mat("steppe_grass"), 5)
		tuft.name = "GrassTuft"
		
	# Boundary stone marker
	var stone_pos = Vector3(cos(seed_val) * 1.6, 0.15, sin(seed_val) * 1.6)
	var b_stone = ModelBuilder._add_cylinder(self, 0.08, 0.14, 0.35, stone_pos, ModelBuilder.get_mat("rock"), 6)
	b_stone.name = "BoundaryStone"
		
	if province_data.owner == "mongol" or province_id in ["kipchak", "sarai"]:
		var pasture = ModelBuilder.create_pasture_plot(0.8)
		pasture.position = Vector3(0.9, 0, -0.6)
		add_child(pasture)

func _build_army_representation():
	army_node = Node3D.new()
	army_node.name = "ArmyNode"
	army_node.position = Vector3(-0.65, 0, 0.75) # To the front-left of settlement
	add_child(army_node)
	_refresh_army_model()

func _refresh_army_model():
	# Clear old children
	for child in army_node.get_children():
		child.queue_free()
		
	var army = province_data.army
	if army == null or army.units.is_empty():
		if army_label_3d:
			army_label_3d.visible = false
		return
		
	# Determine dominant unit type and faction
	var main_unit_type = army.units[0].type
	var faction = army.faction
	var f_color = Color(0.9, 0.75, 0.22) if faction == "mongol" else Color(0.78, 0.2, 0.2)
	
	var unit_fig: Node3D
	match main_unit_type:
		"horse_archer", "light_cavalry":
			unit_fig = ModelBuilder.create_horse_archer_unit(f_color)
		"heavy_cavalry":
			unit_fig = ModelBuilder.create_heavy_cavalry_unit(f_color)
		"spearman":
			unit_fig = ModelBuilder.create_spearman_unit(f_color)
		"siege":
			unit_fig = ModelBuilder.create_siege_engine(f_color)
		_:
			unit_fig = ModelBuilder.create_infantry_unit(f_color)
			
	unit_fig.scale = Vector3(0.55, 0.55, 0.55)
	army_node.add_child(unit_fig)
	
	# Update floating army strength badge
	if army_label_3d:
		var total_strength = 0
		for u in army.units:
			total_strength += int(u.count)
		army_label_3d.text = "⚔ " + str(total_strength)
		army_label_3d.visible = true

func _build_labels():
	# Province Name 3D billboard label
	label_3d = Label3D.new()
	label_3d.text = province_data.name
	label_3d.position = Vector3(0, 1.85, 0)
	label_3d.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label_3d.no_depth_test = true
	label_3d.font_size = 32
	label_3d.outline_size = 8
	label_3d.outline_modulate = Color(0.08, 0.06, 0.04, 1.0)
	label_3d.modulate = Color(1.0, 0.95, 0.85)
	add_child(label_3d)
	
	# Army badge label
	army_label_3d = Label3D.new()
	army_label_3d.position = Vector3(-0.65, 1.15, 0.75)
	army_label_3d.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	army_label_3d.no_depth_test = true
	army_label_3d.font_size = 28
	army_label_3d.outline_size = 6
	army_label_3d.outline_modulate = Color(0.1, 0.0, 0.0, 1.0)
	army_label_3d.modulate = Color(1.0, 0.85, 0.3)
	army_label_3d.visible = false
	add_child(army_label_3d)

func _build_highlight_ring():
	highlight_ring = MeshInstance3D.new()
	var t_mesh = TorusMesh.new()
	t_mesh.inner_radius = 1.72
	t_mesh.outer_radius = 1.92
	t_mesh.rings = 16
	t_mesh.ring_segments = 6
	highlight_ring.mesh = t_mesh
	
	var h_mat = StandardMaterial3D.new()
	h_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	h_mat.albedo_color = Color(1.0, 0.85, 0.2, 0.9)
	highlight_ring.material_override = h_mat
	highlight_ring.position = Vector3(0, 0.05, 0)
	highlight_ring.visible = false
	highlight_ring.name = "HighlightRing"
	add_child(highlight_ring)

func _build_interaction_area():
	collision_area = Area3D.new()
	collision_area.name = "ClickArea"
	var col_shape = CollisionShape3D.new()
	var cyl = CylinderShape3D.new()
	cyl.radius = 1.75
	cyl.height = 1.2
	col_shape.shape = cyl
	col_shape.position = Vector3(0, 0.5, 0)
	collision_area.add_child(col_shape)
	add_child(collision_area)
	
	collision_area.input_event.connect(_on_input_event)
	collision_area.mouse_entered.connect(_on_mouse_entered)
	collision_area.mouse_exited.connect(_on_mouse_exited)

func _on_input_event(_camera: Camera3D, event: InputEvent, _pos: Vector3, _normal: Vector3, _shape_idx: int):
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		clicked.emit(province_id)

func _on_mouse_entered():
	is_hovered = true
	mouse_entered_province.emit(province_id)
	update_state()

func _on_mouse_exited():
	is_hovered = false
	mouse_exited_province.emit(province_id)
	update_state()

func set_selected(selected: bool):
	is_selected = selected
	update_state()

func set_targetable(targetable: bool):
	is_targetable = targetable
	update_state()

func update_state():
	if not highlight_ring:
		return
		
	var mat = highlight_ring.material_override as StandardMaterial3D
	if not mat:
		return
		
	if is_selected:
		highlight_ring.visible = true
		mat.albedo_color = Color(1.0, 0.85, 0.1, 1.0) # Radiant Gold selection
		highlight_ring.scale = Vector3(1.02, 1.0, 1.02)
	elif is_targetable:
		highlight_ring.visible = true
		mat.albedo_color = Color(0.9, 0.2, 0.15, 0.95) # Crimson Attack Target
		highlight_ring.scale = Vector3(1.0, 1.0, 1.0)
	elif is_hovered:
		highlight_ring.visible = true
		mat.albedo_color = Color(1.0, 1.0, 1.0, 0.6) # Soft white hover
		highlight_ring.scale = Vector3(0.98, 1.0, 0.98)
	else:
		highlight_ring.visible = false
		
	# Refresh owner border ring
	var border = get_node_or_null("BorderRing") as MeshInstance3D
	if border:
		border.material_override = _get_faction_mat(province_data.owner)

func refresh_from_data(new_data: Dictionary):
	var owner_changed = (province_data.owner != new_data.owner)
	province_data = new_data
	
	if owner_changed:
		# Rebuild settlement to match new owner
		if settlement_node:
			settlement_node.queue_free()
		_build_settlement()
		
	_refresh_army_model()
	update_state()

func _get_faction_mat(faction_id: String) -> Material:
	match faction_id:
		"mongol":
			return ModelBuilder.get_mat("faction_mongol")
		"cuman", "kipchak":
			return ModelBuilder.get_mat("faction_cuman")
		"rus":
			return ModelBuilder.get_mat("faction_rus")
		"byzantine":
			return ModelBuilder.get_mat("faction_byzantine")
		"seljuk":
			return ModelBuilder.get_mat("faction_seljuk")
		"khwarazm":
			return ModelBuilder.get_mat("faction_khwarazm")
		_:
			return ModelBuilder.get_mat("faction_neutral")
