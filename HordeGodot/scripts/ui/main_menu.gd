class_name MainMenu
extends Node3D

const ModelBuilder = preload("res://scripts/visuals/model_builder.gd")

var camera_pivot: Node3D
var cam: Camera3D
var ui_layer: CanvasLayer

var settings_modal: PanelContainer
var info_label: Label

func _ready():
	_setup_3d_diorama()
	_setup_ui()

func _setup_3d_diorama():
	# Directional Sun (Golden Hour)
	var sun = DirectionalLight3D.new()
	sun.light_color = Color(1.0, 0.90, 0.72)
	sun.light_energy = 1.4
	sun.shadow_enabled = true
	sun.rotation_degrees = Vector3(-35, 45, 0)
	add_child(sun)
	
	# World Environment
	var env_node = WorldEnvironment.new()
	var env = Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.12, 0.09, 0.07)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.55, 0.45, 0.38)
	env.ambient_light_energy = 0.9
	env.fog_enabled = true
	env.fog_light_color = Color(0.5, 0.4, 0.3)
	env.fog_density = 0.015
	env_node.environment = env
	add_child(env_node)
	
	# Rotating Camera Pivot
	camera_pivot = Node3D.new()
	camera_pivot.name = "CameraPivot"
	add_child(camera_pivot)
	
	cam = Camera3D.new()
	cam.position = Vector3(0, 3.2, 7.8)
	cam.rotation_degrees = Vector3(-20, 0, 0)
	cam.fov = 38.0
	cam.current = true
	camera_pivot.add_child(cam)
	
	# Miniature Battlefield Diorama Base
	var diorama_root = Node3D.new()
	diorama_root.name = "Diorama"
	add_child(diorama_root)
	
	# Steppe ground cylinder
	var base_mesh = MeshInstance3D.new()
	var cyl = CylinderMesh.new()
	cyl.top_radius = 5.2
	cyl.bottom_radius = 5.5
	cyl.height = 0.6
	cyl.radial_segments = 16
	base_mesh.mesh = cyl
	base_mesh.material_override = ModelBuilder.get_mat("steppe_grass")
	base_mesh.position = Vector3(0, -0.3, 0)
	diorama_root.add_child(base_mesh)
	
	# Steppe side (Mongol Camp)
	var mongol_camp = ModelBuilder.create_mongol_camp(true)
	mongol_camp.position = Vector3(-1.8, 0, -0.5)
	mongol_camp.rotation_degrees = Vector3(0, 25, 0)
	diorama_root.add_child(mongol_camp)
	
	var horse_archer = ModelBuilder.create_horse_archer_unit(Color(0.9, 0.75, 0.22))
	horse_archer.position = Vector3(-0.8, 0, 1.2)
	horse_archer.rotation_degrees = Vector3(0, 75, 0)
	diorama_root.add_child(horse_archer)
	
	# Rus' side (Fortress & Warriors)
	var rus_fort = ModelBuilder.create_rus_fortress(false)
	rus_fort.position = Vector3(2.0, 0, -0.6)
	rus_fort.rotation_degrees = Vector3(0, -35, 0)
	diorama_root.add_child(rus_fort)
	
	var druzhina = ModelBuilder.create_infantry_unit(Color(0.78, 0.2, 0.2))
	druzhina.position = Vector3(0.8, 0, 1.0)
	druzhina.rotation_degrees = Vector3(0, -75, 0)
	diorama_root.add_child(druzhina)
	
	# Environmental dressing
	var p1 = ModelBuilder.create_pine_tree(1.2)
	p1.position = Vector3(2.8, 0, 1.5)
	diorama_root.add_child(p1)
	
	var p2 = ModelBuilder.create_birch_tree(1.1)
	p2.position = Vector3(1.2, 0, -2.4)
	diorama_root.add_child(p2)
	
	var p3 = ModelBuilder.create_oak_tree(1.1)
	p3.position = Vector3(-2.8, 0, 1.8)
	diorama_root.add_child(p3)
	
	var rocks = ModelBuilder.create_rock_cluster(1.2)
	rocks.position = Vector3(0, 0, -1.8)
	diorama_root.add_child(rocks)

func _process(delta: float):
	if camera_pivot:
		camera_pivot.rotation.y += delta * 0.08

func _setup_ui():
	ui_layer = CanvasLayer.new()
	ui_layer.name = "UILayer"
	add_child(ui_layer)
	
	# Title & Menu Card (Left side)
	var menu_panel = PanelContainer.new()
	menu_panel.offset_left = 60
	menu_panel.offset_top = 80
	menu_panel.offset_right = 440
	menu_panel.offset_bottom = 640
	
	var sb = StyleBoxFlat.new()
	sb.bg_color = Color(0.10, 0.08, 0.06, 0.92)
	sb.set_border_width_all(2)
	sb.border_color = Color(0.78, 0.62, 0.28)
	sb.set_corner_radius_all(8)
	sb.content_margin_left = 32
	sb.content_margin_right = 32
	sb.content_margin_top = 32
	sb.content_margin_bottom = 32
	menu_panel.add_theme_stylebox_override("panel", sb)
	ui_layer.add_child(menu_panel)
	
	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 16)
	menu_panel.add_child(vbox)
	
	var lbl_title = Label.new()
	lbl_title.text = "HORDE"
	lbl_title.add_theme_font_size_override("font_size", 54)
	lbl_title.add_theme_color_override("font_color", Color(1.0, 0.88, 0.32))
	lbl_title.add_theme_constant_override("outline_size", 8)
	lbl_title.add_theme_color_override("font_outline_color", Color(0.1, 0.05, 0.02))
	vbox.add_child(lbl_title)
	
	var lbl_sub = Label.new()
	lbl_sub.text = "STEPPE AND STEEL"
	lbl_sub.add_theme_font_size_override("font_size", 22)
	lbl_sub.add_theme_color_override("font_color", Color(0.9, 0.45, 0.35))
	lbl_sub.add_theme_constant_override("outline_size", 4)
	lbl_sub.add_theme_color_override("font_outline_color", Color(0.08, 0.04, 0.02))
	vbox.add_child(lbl_sub)
	
	var lbl_desc = Label.new()
	lbl_desc.text = "A 3D Turn-Based Eurasian Grand Strategy Game"
	lbl_desc.add_theme_font_size_override("font_size", 14)
	lbl_desc.add_theme_color_override("font_color", Color(0.8, 0.75, 0.65))
	lbl_desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vbox.add_child(lbl_desc)
	
	var hs = HSeparator.new()
	vbox.add_child(hs)
	
	# Menu Buttons
	var btn_new = _create_menu_button("⚔ NEW CAMPAIGN", Color(0.42, 0.28, 0.12), Color(0.92, 0.75, 0.28))
	btn_new.pressed.connect(_on_new_campaign_pressed)
	vbox.add_child(btn_new)
	
	var btn_continue = _create_menu_button("📜 CONTINUE CAMPAIGN", Color(0.24, 0.20, 0.16), Color(0.65, 0.52, 0.3))
	btn_continue.pressed.connect(_on_continue_pressed)
	vbox.add_child(btn_continue)
	
	var btn_settings = _create_menu_button("⚙ SETTINGS", Color(0.24, 0.20, 0.16), Color(0.65, 0.52, 0.3))
	btn_settings.pressed.connect(_on_settings_pressed)
	vbox.add_child(btn_settings)
	
	var btn_quit = _create_menu_button("🚪 QUIT", Color(0.35, 0.12, 0.12), Color(0.8, 0.3, 0.3))
	btn_quit.pressed.connect(_on_quit_pressed)
	vbox.add_child(btn_quit)
	
	info_label = Label.new()
	info_label.text = "v0.2.0 • Godot 4 Low-Poly 3D Edition"
	info_label.add_theme_font_size_override("font_size", 12)
	info_label.add_theme_color_override("font_color", Color(0.6, 0.55, 0.45))
	vbox.add_child(info_label)
	
	# Settings Modal
	_create_settings_modal()

func _create_menu_button(label: String, bg_col: Color, border_col: Color) -> Button:
	var btn = Button.new()
	btn.text = label
	btn.custom_minimum_size = Vector2(0, 48)
	btn.add_theme_font_size_override("font_size", 18)
	btn.add_theme_color_override("font_color", Color(1.0, 0.95, 0.85))
	
	var sb_n = StyleBoxFlat.new()
	sb_n.bg_color = bg_col
	sb_n.set_border_width_all(2)
	sb_n.border_color = border_col
	sb_n.set_corner_radius_all(6)
	btn.add_theme_stylebox_override("normal", sb_n)
	
	var sb_h = StyleBoxFlat.new()
	sb_h.bg_color = bg_col.lightened(0.2)
	sb_h.set_border_width_all(2)
	sb_h.border_color = border_col.lightened(0.3)
	sb_h.set_corner_radius_all(6)
	btn.add_theme_stylebox_override("hover", sb_h)
	
	return btn

func _create_settings_modal():
	settings_modal = PanelContainer.new()
	settings_modal.name = "SettingsModal"
	settings_modal.set_anchors_preset(Control.PRESET_CENTER)
	settings_modal.offset_left = -240
	settings_modal.offset_top = -220
	settings_modal.offset_right = 240
	settings_modal.offset_bottom = 220
	
	var sb = StyleBoxFlat.new()
	sb.bg_color = Color(0.12, 0.10, 0.08, 0.98)
	sb.set_border_width_all(2)
	sb.border_color = Color(0.72, 0.58, 0.28)
	sb.set_corner_radius_all(8)
	sb.content_margin_left = 28
	sb.content_margin_right = 28
	sb.content_margin_top = 24
	sb.content_margin_bottom = 24
	settings_modal.add_theme_stylebox_override("panel", sb)
	settings_modal.visible = false
	ui_layer.add_child(settings_modal)
	
	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 14)
	settings_modal.add_child(vbox)
	
	var title = Label.new()
	title.text = "SETTINGS & AUDIO"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 22)
	title.add_theme_color_override("font_color", Color(1.0, 0.88, 0.35))
	vbox.add_child(title)
	
	# Audio Volume Sliders
	var am = _get_audio_manager()
	
	var lbl_master = Label.new()
	lbl_master.text = "Master Volume"
	vbox.add_child(lbl_master)
	var s_master = HSlider.new()
	s_master.min_value = 0.0
	s_master.max_value = 1.0
	s_master.step = 0.05
	s_master.value = am.master_volume if am else 0.85
	s_master.value_changed.connect(func(v): if am: am.set_master_volume(v))
	vbox.add_child(s_master)
	
	var lbl_music = Label.new()
	lbl_music.text = "Music Volume"
	vbox.add_child(lbl_music)
	var s_music = HSlider.new()
	s_music.min_value = 0.0
	s_music.max_value = 1.0
	s_music.step = 0.05
	s_music.value = am.music_volume if am else 0.65
	s_music.value_changed.connect(func(v): if am: am.set_music_volume(v))
	vbox.add_child(s_music)
	
	var lbl_sfx = Label.new()
	lbl_sfx.text = "SFX Volume"
	vbox.add_child(lbl_sfx)
	var s_sfx = HSlider.new()
	s_sfx.min_value = 0.0
	s_sfx.max_value = 1.0
	s_sfx.step = 0.05
	s_sfx.value = am.sfx_volume if am else 0.8
	s_sfx.value_changed.connect(func(v): if am: am.set_sfx_volume(v))
	vbox.add_child(s_sfx)
	
	var btn_fs = CheckButton.new()
	btn_fs.text = "Fullscreen Mode"
	btn_fs.button_pressed = (DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN or DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN)
	btn_fs.toggled.connect(func(pressed):
		if pressed:
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN)
		else:
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
	)
	vbox.add_child(btn_fs)
	
	var btn_close = Button.new()
	btn_close.text = "Close"
	btn_close.pressed.connect(func():
		_play_click()
		settings_modal.visible = false
	)
	vbox.add_child(btn_close)

func _play_click():
	var am = _get_audio_manager()
	if am:
		am.play_click()

func _get_audio_manager():
	var loop = Engine.get_main_loop() as SceneTree
	if loop and loop.root and loop.root.has_node("AudioManager"):
		return loop.root.get_node("AudioManager")
	return null

func _on_new_campaign_pressed():
	_play_click()
	var gm = _get_game_manager()
	if gm:
		gm.start_new_campaign()
	get_tree().change_scene_to_file("res://scenes/campaign/campaign_view.tscn")

func _on_continue_pressed():
	_play_click()
	var gm = _get_game_manager()
	if gm and gm.load_game():
		get_tree().change_scene_to_file("res://scenes/campaign/campaign_view.tscn")
	else:
		info_label.text = "No saved game found. Starting new campaign..."
		_on_new_campaign_pressed()

func _on_settings_pressed():
	_play_click()
	settings_modal.visible = true

func _on_quit_pressed():
	_play_click()
	get_tree().quit()

func _get_game_manager():
	var root = Engine.get_main_loop().root if Engine.get_main_loop() else null
	if root and root.has_node("GameManager"):
		return root.get_node("GameManager")
	return null
