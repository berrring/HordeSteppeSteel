extends SceneTree

const ModelBuilder = preload("res://scripts/visuals/model_builder.gd")
const Palette = preload("res://scripts/core/palette.gd")

func _init():
	print("Generating Checkpoint 4 Visual Sheets...")
	_generate_sheets()

func _generate_sheets():
	# -------------------------------------------------------------
	# SHEET 1: CHARACTER & ENVIRONMENT SPECIFICATION SHEET
	# -------------------------------------------------------------
	print("Rendering 03_character_and_environment_sheet.png...")
	var sheet_root = Node3D.new()
	root.add_child(sheet_root)
	
	# Light & Env
	var sun = DirectionalLight3D.new()
	sun.light_color = Color(1.0, 0.95, 0.88)
	sun.light_energy = 1.3
	sun.shadow_enabled = true
	sun.rotation_degrees = Vector3(-40, 40, 0)
	sheet_root.add_child(sun)
	
	var env_node = WorldEnvironment.new()
	var env = Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.16, 0.19, 0.24)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.55, 0.50, 0.44)
	env.ambient_light_energy = 0.95
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	env.tonemap_exposure = 1.15
	env.glow_enabled = true
	env.glow_intensity = 0.35
	env.glow_bloom = 0.10
	env_node.environment = env
	sheet_root.add_child(env_node)
	
	# Camera
	var cam = Camera3D.new()
	cam.position = Vector3(0, 3.8, 8.2)
	cam.rotation_degrees = Vector3(-18, 0, 0)
	cam.fov = 42.0
	cam.current = true
	sheet_root.add_child(cam)
	
	# Tier 1: Cliff base
	var p_base = MeshInstance3D.new()
	var c_mesh = CylinderMesh.new()
	c_mesh.top_radius = 8.6
	c_mesh.bottom_radius = 9.0
	c_mesh.height = 0.45
	c_mesh.radial_segments = 24
	p_base.mesh = c_mesh
	p_base.material_override = ModelBuilder.get_mat("cliff_bedrock")
	p_base.position = Vector3(0, -0.3, 0)
	sheet_root.add_child(p_base)
	
	# Tier 2: Lush Grass Top Platter
	var platter = MeshInstance3D.new()
	var cyl = CylinderMesh.new()
	cyl.top_radius = 8.4
	cyl.bottom_radius = 8.6
	cyl.height = 0.18
	cyl.radial_segments = 24
	platter.mesh = cyl
	platter.material_override = ModelBuilder.get_mat("steppe_grass")
	platter.position = Vector3(0, 0.0, 0)
	sheet_root.add_child(platter)
	
	# Row 1 (Units in Front, Z ~ 1.0):
	# 1. Mongol Horse Archer
	var ha = ModelBuilder.create_horse_archer_unit(Palette.FACTION_MONGOL)
	ha.position = Vector3(-4.0, 0, 1.2)
	ha.rotation_degrees = Vector3(0, 20, 0)
	sheet_root.add_child(ha)
	
	# 2. Armored Heavy Cavalry
	var hc = ModelBuilder.create_heavy_cavalry_unit(Palette.FACTION_SELJUK)
	hc.position = Vector3(-2.0, 0, 1.2)
	hc.rotation_degrees = Vector3(0, 15, 0)
	sheet_root.add_child(hc)
	
	# 3. Rus' Infantry Axeman
	var inf = ModelBuilder.create_infantry_unit(Palette.FACTION_RUS)
	inf.position = Vector3(0.0, 0, 1.2)
	inf.rotation_degrees = Vector3(0, -10, 0)
	sheet_root.add_child(inf)
	
	# 4. Heavy Spearman
	var sp = ModelBuilder.create_spearman_unit(Palette.FACTION_BYZANTINE)
	sp.position = Vector3(2.0, 0, 1.2)
	sp.rotation_degrees = Vector3(0, -20, 0)
	sheet_root.add_child(sp)
	
	# 5. Traction Trebuchet Siege Engine
	var tr = ModelBuilder.create_siege_engine(Palette.FACTION_MONGOL)
	tr.position = Vector3(4.0, 0, 1.2)
	tr.rotation_degrees = Vector3(0, -35, 0)
	sheet_root.add_child(tr)
	
	# Row 2 (Architecture & Environment in Back, Z ~ -2.0):
	# 1. Steppe Pine Tree
	var p1 = ModelBuilder.create_pine_tree(1.2)
	p1.position = Vector3(-4.5, 0, -1.8)
	sheet_root.add_child(p1)
	
	# 2. Khan's Yurt Headquarters
	var yurt = ModelBuilder.create_mongol_camp(true)
	yurt.position = Vector3(-2.2, 0, -2.0)
	yurt.rotation_degrees = Vector3(0, 15, 0)
	sheet_root.add_child(yurt)
	
	# 3. Rus' Kremlin Fortress
	var fort = ModelBuilder.create_rus_fortress(true)
	fort.position = Vector3(1.2, 0, -2.2)
	fort.rotation_degrees = Vector3(0, -20, 0)
	sheet_root.add_child(fort)
	
	# 4. Birch Tree
	var b1 = ModelBuilder.create_birch_tree(1.1)
	b1.position = Vector3(3.8, 0, -1.5)
	sheet_root.add_child(b1)
	
	# 5. Rock Cluster
	var rk = ModelBuilder.create_rock_cluster(1.2)
	rk.position = Vector3(4.8, 0, -2.2)
	sheet_root.add_child(rk)
	
	# 2D Annotation UI Overlay
	var ui = CanvasLayer.new()
	root.add_child(ui)
	
	var header_panel = PanelContainer.new()
	header_panel.set_anchors_preset(Control.PRESET_TOP_WIDE)
	header_panel.offset_bottom = 60
	var sb_h = StyleBoxFlat.new()
	sb_h.bg_color = Color(0.10, 0.08, 0.06, 0.94)
	sb_h.set_border_width_all(2)
	sb_h.border_color = Palette.BRONZE_GOLD
	header_panel.add_theme_stylebox_override("panel", sb_h)
	ui.add_child(header_panel)
	
	var h_box = HBoxContainer.new()
	h_box.alignment = BoxContainer.ALIGNMENT_CENTER
	h_box.add_theme_constant_override("separation", 30)
	header_panel.add_child(h_box)
	
	var title = Label.new()
	title.text = "HORDE: STEPPE & STEEL  —  3D CHARACTER & ENVIRONMENT SPECIFICATION SHEET"
	title.add_theme_font_size_override("font_size", 18)
	title.add_theme_color_override("font_color", Color(1.0, 0.88, 0.35))
	h_box.add_child(title)
	
	# Bottom Palette Swatches & Labels Card
	var footer_panel = PanelContainer.new()
	footer_panel.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	footer_panel.offset_top = -68
	footer_panel.offset_left = 30
	footer_panel.offset_right = -30
	footer_panel.offset_bottom = -12
	var sb_f = StyleBoxFlat.new()
	sb_f.bg_color = Color(0.10, 0.08, 0.06, 0.96)
	sb_f.set_border_width_all(1)
	sb_f.border_color = Palette.BRONZE_GOLD
	sb_f.set_corner_radius_all(6)
	footer_panel.add_theme_stylebox_override("panel", sb_f)
	ui.add_child(footer_panel)
	
	var f_box = HBoxContainer.new()
	f_box.alignment = BoxContainer.ALIGNMENT_CENTER
	f_box.add_theme_constant_override("separation", 24)
	footer_panel.add_child(f_box)
	
	var lbl_annot = Label.new()
	lbl_annot.text = "Front: Horse Archer (~140 poly) | Heavy Cavalry (~190 poly) | Rus' Axeman (~110 poly) | Spearman (~90 poly) | Trebuchet (~85 poly)\nBack: Steppe Pine | Khan Yurt (~120 poly) | Rus' Fortress (~240 poly) | Birch Tree | Granite Boulders"
	lbl_annot.add_theme_font_size_override("font_size", 12)
	lbl_annot.add_theme_color_override("font_color", Color(0.9, 0.85, 0.75))
	f_box.add_child(lbl_annot)
	
	# Wait frames to render
	for f in range(25):
		await process_frame
		
	var img1 = root.get_viewport().get_texture().get_image()
	if img1:
		img1.save_png("c:/Users/user/Desktop/HordeSteppeSteel/Checkpoint4_Pitch_and_Technical_Bridge/03_character_and_environment_sheet.png")
		print("Saved 03_character_and_environment_sheet.png")
		
	ui.free()
	sheet_root.free()
	
	# -------------------------------------------------------------
	# SHEET 2: BLOCKOUT & SPATIAL COMPOSITION DIAGRAM
	# -------------------------------------------------------------
	print("Rendering 05_level_blockout_diagram.png...")
	var block_root = Node3D.new()
	root.add_child(block_root)
	
	var sun2 = DirectionalLight3D.new()
	sun2.light_color = Color(1.0, 0.98, 0.92)
	sun2.light_energy = 1.35
	sun2.shadow_enabled = true
	sun2.rotation_degrees = Vector3(-45, 45, 0)
	block_root.add_child(sun2)
	
	var env_node2 = WorldEnvironment.new()
	var env2 = Environment.new()
	env2.background_mode = Environment.BG_COLOR
	env2.background_color = Color(0.14, 0.16, 0.18)
	env_node2.environment = env2
	block_root.add_child(env_node2)
	
	var cam2 = Camera3D.new()
	cam2.position = Vector3(0, 9.5, 9.0)
	cam2.rotation_degrees = Vector3(-45, 0, 0)
	cam2.fov = 42.0
	cam2.current = true
	block_root.add_child(cam2)
	
	# Untextured/Stylized Blockout Material (Clay Grey & Wireframe-like contrast)
	var mat_ground = StandardMaterial3D.new()
	mat_ground.albedo_color = Color(0.32, 0.35, 0.38)
	mat_ground.roughness = 0.9
	
	var mat_water = StandardMaterial3D.new()
	mat_water.albedo_color = Color(0.20, 0.40, 0.55)
	mat_water.roughness = 0.3
	
	var mat_prov_a = StandardMaterial3D.new()
	mat_prov_a.albedo_color = Color(0.55, 0.45, 0.25) # Player start blockout
	
	var mat_prov_b = StandardMaterial3D.new()
	mat_prov_b.albedo_color = Color(0.50, 0.25, 0.25) # Enemy choke blockout
	
	var mat_prov_c = StandardMaterial3D.new()
	mat_prov_c.albedo_color = Color(0.35, 0.45, 0.35) # Neutral flank blockout
	
	var mat_road = StandardMaterial3D.new()
	mat_road.albedo_color = Color(0.65, 0.60, 0.50)
	
	# Base Terrain Plate
	var b_ground = MeshInstance3D.new()
	var b_box = BoxMesh.new()
	b_box.size = Vector3(16, 0.4, 12)
	b_ground.mesh = b_box
	b_ground.material_override = mat_ground
	b_ground.position = Vector3(0, -0.2, 0)
	block_root.add_child(b_ground)
	
	# River Trench Blockout
	var river_block = MeshInstance3D.new()
	var r_mesh = BoxMesh.new()
	r_mesh.size = Vector3(16, 0.42, 1.6)
	river_block.mesh = r_mesh
	river_block.material_override = mat_water
	river_block.position = Vector3(0, -0.18, 0)
	river_block.rotation_degrees = Vector3(0, 15, 0)
	block_root.add_child(river_block)
	
	# Bridge / Choke Crossing Blockout
	var bridge = MeshInstance3D.new()
	var br_mesh = BoxMesh.new()
	br_mesh.size = Vector3(1.2, 0.5, 2.4)
	bridge.mesh = br_mesh
	bridge.material_override = mat_road
	bridge.position = Vector3(0, 0, 0)
	bridge.rotation_degrees = Vector3(0, 15, 0)
	block_root.add_child(bridge)
	
	# Province Node 1 (Player Hub: Sarai)
	var p1_mesh = MeshInstance3D.new()
	var p1_cyl = CylinderMesh.new()
	p1_cyl.top_radius = 2.4
	p1_cyl.bottom_radius = 2.6
	p1_cyl.height = 0.6
	p1_mesh.mesh = p1_cyl
	p1_mesh.material_override = mat_prov_a
	p1_mesh.position = Vector3(-4.0, 0.1, 2.5)
	block_root.add_child(p1_mesh)
	
	# Settlement Blockout Geometry on P1 (Cylinders & Prisms)
	var yurt_b = MeshInstance3D.new()
	var y_cyl = CylinderMesh.new()
	y_cyl.top_radius = 0.7
	y_cyl.bottom_radius = 0.7
	y_cyl.height = 0.6
	yurt_b.mesh = y_cyl
	yurt_b.material_override = mat_road
	yurt_b.position = Vector3(-4.0, 0.7, 2.5)
	block_root.add_child(yurt_b)
	
	# Province Node 2 (Contested Frontier: Kiev)
	var p2_mesh = MeshInstance3D.new()
	var p2_cyl = CylinderMesh.new()
	p2_cyl.top_radius = 2.2
	p2_cyl.bottom_radius = 2.4
	p2_cyl.height = 0.6
	p2_mesh.mesh = p2_cyl
	p2_mesh.material_override = mat_prov_b
	p2_mesh.position = Vector3(3.8, 0.1, -2.5)
	block_root.add_child(p2_mesh)
	
	# Fort Blockout Geometry on P2 (Box Tower & Walls)
	var fort_b = MeshInstance3D.new()
	var fort_box = BoxMesh.new()
	fort_box.size = Vector3(1.0, 1.2, 1.0)
	fort_b.mesh = fort_box
	fort_b.material_override = mat_road
	fort_b.position = Vector3(3.8, 1.0, -2.5)
	block_root.add_child(fort_b)
	
	# Province Node 3 (Flank Steppe: Kipchak)
	var p3_mesh = MeshInstance3D.new()
	var p3_cyl = CylinderMesh.new()
	p3_cyl.top_radius = 2.0
	p3_cyl.bottom_radius = 2.2
	p3_cyl.height = 0.5
	p3_mesh.mesh = p3_cyl
	p3_mesh.material_override = mat_prov_c
	p3_mesh.position = Vector3(-3.8, 0.05, -3.0)
	block_root.add_child(p3_mesh)
	
	# Road Connections
	var rd1 = MeshInstance3D.new()
	var rd1_m = BoxMesh.new()
	rd1_m.size = Vector3(0.6, 0.45, 5.0)
	rd1.mesh = rd1_m
	rd1.material_override = mat_road
	rd1.position = Vector3(-2.0, 0, 1.2)
	rd1.rotation_degrees = Vector3(0, 50, 0)
	block_root.add_child(rd1)
	
	var rd2 = MeshInstance3D.new()
	var rd2_m = BoxMesh.new()
	rd2_m.size = Vector3(0.6, 0.45, 5.0)
	rd2.mesh = rd2_m
	rd2.material_override = mat_road
	rd2.position = Vector3(1.9, 0, -1.2)
	rd2.rotation_degrees = Vector3(0, 50, 0)
	block_root.add_child(rd2)
	
	# 3D In-Scene Blockout Labels
	var lbl1 = Label3D.new()
	lbl1.text = "PROVINCE A: SARAI\n[Player Hub / Capital]\nElevation: +0.6m | Yurts"
	lbl1.position = Vector3(-4.0, 2.2, 2.5)
	lbl1.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	lbl1.font_size = 22
	lbl1.outline_size = 6
	lbl1.modulate = Color(1.0, 0.88, 0.4)
	block_root.add_child(lbl1)
	
	var lbl2 = Label3D.new()
	lbl2.text = "PROVINCE B: KIEV\n[Enemy Fortress / Choke]\nElevation: +0.6m | Kremlin"
	lbl2.position = Vector3(3.8, 2.4, -2.5)
	lbl2.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	lbl2.font_size = 22
	lbl2.outline_size = 6
	lbl2.modulate = Color(1.0, 0.4, 0.4)
	block_root.add_child(lbl2)
	
	var lbl_bridge = Label3D.new()
	lbl_bridge.text = "CRITICAL CHOKE POINT\nRiver Crossing & Road Transition"
	lbl_bridge.position = Vector3(0, 1.4, 0)
	lbl_bridge.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	lbl_bridge.font_size = 20
	lbl_bridge.outline_size = 5
	lbl_bridge.modulate = Color(0.6, 0.9, 1.0)
	block_root.add_child(lbl_bridge)
	
	# 2D Header Overlay for Blockout
	var ui2 = CanvasLayer.new()
	root.add_child(ui2)
	
	var h2 = PanelContainer.new()
	h2.set_anchors_preset(Control.PRESET_TOP_WIDE)
	h2.offset_bottom = 54
	var sb_b = StyleBoxFlat.new()
	sb_b.bg_color = Color(0.10, 0.12, 0.15, 0.94)
	sb_b.set_border_width_all(2)
	sb_b.border_color = Color(0.35, 0.55, 0.75)
	h2.add_theme_stylebox_override("panel", sb_b)
	ui2.add_child(h2)
	
	var h2_lbl = Label.new()
	h2_lbl.text = "LEVEL DESIGN BLOCKOUT SCHEMATIC: STRATEGIC PROVINCE GRID & RIVER CROSSING"
	h2_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	h2_lbl.add_theme_font_size_override("font_size", 16)
	h2_lbl.add_theme_color_override("font_color", Color(0.85, 0.92, 1.0))
	h2.add_child(h2_lbl)
	
	for f in range(25):
		await process_frame
		
	var img2 = root.get_viewport().get_texture().get_image()
	if img2:
		img2.save_png("c:/Users/user/Desktop/HordeSteppeSteel/Checkpoint4_Pitch_and_Technical_Bridge/05_level_blockout_diagram.png")
		print("Saved 05_level_blockout_diagram.png")
		
	ui2.free()
	block_root.free()
	print("Checkpoint 4 Visual Sheets Generation Complete!")
	quit(0)
