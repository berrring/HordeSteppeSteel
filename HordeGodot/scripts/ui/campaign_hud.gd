class_name CampaignHUD
extends CanvasLayer

signal end_turn_requested
signal recruit_requested(unit_type: String)
signal construct_requested(building_type: String)
signal attack_requested(attacker_pid: String, defender_pid: String)
signal return_to_menu_requested

var selected_pid: String = ""
var attack_target_pid: String = ""

# UI Containers
var top_bar: PanelContainer
var lbl_faction: Label
var lbl_turn: Label
var lbl_gold: Label
var lbl_food: Label
var lbl_wood: Label
var lbl_provinces: Label

var left_panel: PanelContainer
var lbl_province_name: Label
var lbl_province_details: Label
var army_list_container: VBoxContainer
var recruit_container: VBoxContainer
var construct_container: VBoxContainer
var attack_container: VBoxContainer
var lbl_attack_info: Label

var right_panel: PanelContainer
var btn_end_turn: Button

var battle_modal: PanelContainer
var lbl_battle_title: Label
var lbl_battle_details: Label

var game_over_modal: PanelContainer
var lbl_game_over_title: Label
var lbl_game_over_details: Label

var help_modal: PanelContainer
var event_log_label: Label

func _ready():
	_create_ui()
	hide_modals()
	update_resources()
	deselect_province()

# -------------------------------------------------------------
# STYLING HELPERS
# -------------------------------------------------------------
func _create_stylebox(bg_color: Color, border_color: Color = Color(0,0,0,0), border_w: int = 0, corner_r: int = 4) -> StyleBoxFlat:
	var sb = StyleBoxFlat.new()
	sb.bg_color = bg_color
	if border_w > 0:
		sb.set_border_width_all(border_w)
		sb.border_color = border_color
	sb.set_corner_radius_all(corner_r)
	sb.content_margin_left = 12
	sb.content_margin_right = 12
	sb.content_margin_top = 8
	sb.content_margin_bottom = 8
	return sb

func _create_ui():
	# Top Bar
	top_bar = PanelContainer.new()
	top_bar.name = "TopBar"
	top_bar.set_anchors_preset(Control.PRESET_TOP_WIDE)
	top_bar.offset_bottom = 54
	top_bar.add_theme_stylebox_override("panel", _create_stylebox(Color(0.12, 0.10, 0.08, 0.94), Color(0.72, 0.58, 0.28), 2, 0))
	add_child(top_bar)
	
	var top_hbox = HBoxContainer.new()
	top_hbox.alignment = BoxContainer.ALIGNMENT_BEGIN
	top_hbox.add_theme_constant_override("separation", 24)
	top_bar.add_child(top_hbox)
	
	lbl_faction = Label.new()
	lbl_faction.text = "🐎 THE GOLDEN HORDE"
	lbl_faction.add_theme_color_override("font_color", Color(1.0, 0.86, 0.35))
	lbl_faction.add_theme_font_size_override("font_size", 18)
	top_hbox.add_child(lbl_faction)
	
	lbl_turn = Label.new()
	lbl_turn.text = "Turn 1 / 60"
	lbl_turn.add_theme_color_override("font_color", Color(0.9, 0.9, 0.9))
	top_hbox.add_child(lbl_turn)
	
	lbl_gold = Label.new()
	lbl_gold.text = "💰 500g (+150)"
	lbl_gold.tooltip_text = "Treasury: Accumulates each turn from province taxes.\nUsed to recruit warriors and maintain troops."
	lbl_gold.mouse_filter = Control.MOUSE_FILTER_PASS
	lbl_gold.add_theme_color_override("font_color", Color(1.0, 0.88, 0.4))
	top_hbox.add_child(lbl_gold)
	
	lbl_food = Label.new()
	lbl_food.text = "🌾 300f (+100)"
	lbl_food.tooltip_text = "Grain & Pasture: Sustains armies.\nRequired alongside Gold to recruit new squads."
	lbl_food.mouse_filter = Control.MOUSE_FILTER_PASS
	lbl_food.add_theme_color_override("font_color", Color(0.75, 0.95, 0.55))
	top_hbox.add_child(lbl_food)
	
	lbl_wood = Label.new()
	lbl_wood.text = "🪵 200w (+50)"
	lbl_wood.tooltip_text = "Timber Reserves: Harvested from forests.\nUsed to build defensive stockades, pastures, and markets."
	lbl_wood.mouse_filter = Control.MOUSE_FILTER_PASS
	lbl_wood.add_theme_color_override("font_color", Color(0.95, 0.78, 0.55))
	top_hbox.add_child(lbl_wood)
	
	lbl_provinces = Label.new()
	lbl_provinces.text = "🏛 Prov: 2 / 10"
	lbl_provinces.tooltip_text = "Territories Controlled: Conquer 10 provinces across Eurasia to achieve total victory."
	lbl_provinces.mouse_filter = Control.MOUSE_FILTER_PASS
	lbl_provinces.add_theme_color_override("font_color", Color(0.85, 0.85, 1.0))
	top_hbox.add_child(lbl_provinces)
	
	# Spacer
	var spacer = Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top_hbox.add_child(spacer)
	
	var btn_help = Button.new()
	btn_help.text = "Help / Keys"
	btn_help.add_theme_stylebox_override("normal", _create_stylebox(Color(0.24, 0.20, 0.16), Color(0.6, 0.5, 0.3), 1, 4))
	btn_help.pressed.connect(_on_help_pressed)
	top_hbox.add_child(btn_help)
	
	var btn_save = Button.new()
	btn_save.text = "Save"
	btn_save.add_theme_stylebox_override("normal", _create_stylebox(Color(0.24, 0.20, 0.16), Color(0.6, 0.5, 0.3), 1, 4))
	btn_save.pressed.connect(_on_save_pressed)
	top_hbox.add_child(btn_save)
	
	var btn_load = Button.new()
	btn_load.text = "Load"
	btn_load.add_theme_stylebox_override("normal", _create_stylebox(Color(0.24, 0.20, 0.16), Color(0.6, 0.5, 0.3), 1, 4))
	btn_load.pressed.connect(_on_load_pressed)
	top_hbox.add_child(btn_load)
	
	var btn_menu = Button.new()
	btn_menu.text = "Menu"
	btn_menu.add_theme_stylebox_override("normal", _create_stylebox(Color(0.35, 0.15, 0.15), Color(0.8, 0.3, 0.3), 1, 4))
	btn_menu.pressed.connect(_on_menu_pressed)
	top_hbox.add_child(btn_menu)
	
	# Left Selected Province Panel
	left_panel = PanelContainer.new()
	left_panel.name = "LeftPanel"
	left_panel.offset_left = 18
	left_panel.offset_top = 70
	left_panel.offset_right = 340
	left_panel.offset_bottom = 690
	left_panel.add_theme_stylebox_override("panel", _create_stylebox(Color(0.12, 0.10, 0.08, 0.92), Color(0.72, 0.58, 0.28), 2, 6))
	add_child(left_panel)
	
	var left_scroll = ScrollContainer.new()
	left_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	left_panel.add_child(left_scroll)
	
	var left_vbox = VBoxContainer.new()
	left_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	left_vbox.add_theme_constant_override("separation", 10)
	left_scroll.add_child(left_vbox)
	
	lbl_province_name = Label.new()
	lbl_province_name.text = "Province Name"
	lbl_province_name.add_theme_font_size_override("font_size", 20)
	lbl_province_name.add_theme_color_override("font_color", Color(1.0, 0.88, 0.4))
	left_vbox.add_child(lbl_province_name)
	
	lbl_province_details = Label.new()
	lbl_province_details.text = "Details...\nIncome..."
	lbl_province_details.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	left_vbox.add_child(lbl_province_details)
	
	var hs1 = HSeparator.new()
	left_vbox.add_child(hs1)
	
	# Garrison / Army section
	var lbl_army_header = Label.new()
	lbl_army_header.text = "Garrison / Troops:"
	lbl_army_header.add_theme_color_override("font_color", Color(0.9, 0.85, 0.7))
	left_vbox.add_child(lbl_army_header)
	
	army_list_container = VBoxContainer.new()
	left_vbox.add_child(army_list_container)
	
	# Attack Action Box
	attack_container = VBoxContainer.new()
	attack_container.visible = false
	left_vbox.add_child(attack_container)
	
	var hs_atk = HSeparator.new()
	attack_container.add_child(hs_atk)
	
	lbl_attack_info = Label.new()
	lbl_attack_info.text = "Attack Neighbor?"
	lbl_attack_info.add_theme_color_override("font_color", Color(1.0, 0.4, 0.35))
	attack_container.add_child(lbl_attack_info)
	
	var btn_confirm_attack = Button.new()
	btn_confirm_attack.text = "⚔ LAUNCH ATTACK"
	btn_confirm_attack.add_theme_stylebox_override("normal", _create_stylebox(Color(0.55, 0.15, 0.12), Color(0.9, 0.3, 0.2), 2, 4))
	btn_confirm_attack.pressed.connect(_on_confirm_attack_pressed)
	attack_container.add_child(btn_confirm_attack)
	
	var hs2 = HSeparator.new()
	left_vbox.add_child(hs2)
	
	# Recruitment section
	recruit_container = VBoxContainer.new()
	left_vbox.add_child(recruit_container)
	
	var lbl_rec_header = Label.new()
	lbl_rec_header.text = "Recruit Units:"
	lbl_rec_header.add_theme_color_override("font_color", Color(0.9, 0.85, 0.7))
	recruit_container.add_child(lbl_rec_header)
	
	var units_to_recruit = [
		{"type": "horse_archer", "label": "Horse Archer (150g, 50f)", "tip": "Fast skirmisher mounted archers.\nAtk: 35 | Def: 20 | Range: 2 | Move: 3\nTactical Advantage vs Infantry."},
		{"type": "light_cavalry", "label": "Light Cavalry (120g, 40f)", "tip": "Swift steppe outriders.\nAtk: 30 | Def: 25 | Range: 1 | Move: 3\nHigh mobility flanking."},
		{"type": "heavy_cavalry", "label": "Heavy Cavalry (250g, 80f)", "tip": "Armored shock cavalry.\nAtk: 55 | Def: 45 | Range: 1 | Move: 2\nDevastating charge burst. Vulnerable to Spearmen."},
		{"type": "infantry", "label": "Infantry (100g, 30f)", "tip": "Shielded foot soldiers.\nAtk: 40 | Def: 50 | Range: 1 | Move: 1\nResilient frontline defense."},
		{"type": "spearman", "label": "Spearman (110g, 35f)", "tip": "Pike wall infantry.\nAtk: 45 | Def: 55 | Range: 1 | Move: 1\nCounters cavalry charges."},
		{"type": "siege", "label": "Siege Engine (300g, 20f)", "tip": "Traction trebuchet.\nAtk: 70 | Def: 10 | Range: 3 | Move: 1\nLong-range bombardment vs fortifications."},
	]
	for u in units_to_recruit:
		var btn = Button.new()
		btn.text = u.label
		btn.tooltip_text = u.tip
		btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
		btn.add_theme_stylebox_override("normal", _create_stylebox(Color(0.20, 0.25, 0.18), Color(0.4, 0.6, 0.3), 1, 4))
		var utype = u.type
		btn.pressed.connect(func():
			_play_click()
			recruit_requested.emit(utype)
		)
		recruit_container.add_child(btn)
		
	var hs3 = HSeparator.new()
	left_vbox.add_child(hs3)
	
	# Construct section
	construct_container = VBoxContainer.new()
	left_vbox.add_child(construct_container)
	
	var lbl_con_header = Label.new()
	lbl_con_header.text = "Construct Buildings:"
	lbl_con_header.add_theme_color_override("font_color", Color(0.9, 0.85, 0.7))
	construct_container.add_child(lbl_con_header)
	
	var buildings = [
		{"type": "palisade", "label": "Palisade (+10 Def | 100w)", "tip": "Timber stockade rampart.\nGrants +10 defense bonus to defending garrison forces.\nCost: 100 Wood"},
		{"type": "pasture", "label": "Pasture (+40 Food | 80w)", "tip": "Fenced grazing meadows.\nGenerates +40 Food per turn for unit recruitment.\nCost: 80 Wood"},
		{"type": "market", "label": "Market (+50 Gold | 120w)", "tip": "Bazaar & trade post.\nYields +50 Gold revenue per turn.\nCost: 120 Wood"},
	]
	for b in buildings:
		var btn = Button.new()
		btn.text = b.label
		btn.tooltip_text = b.tip
		btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
		btn.add_theme_stylebox_override("normal", _create_stylebox(Color(0.24, 0.20, 0.16), Color(0.65, 0.5, 0.3), 1, 4))
		var btype = b.type
		btn.pressed.connect(func():
			_play_click()
			construct_requested.emit(btype)
		)
		construct_container.add_child(btn)
		
	# Right Panel: End Turn
	right_panel = PanelContainer.new()
	right_panel.name = "RightPanel"
	right_panel.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	right_panel.offset_left = -220
	right_panel.offset_top = -90
	right_panel.offset_right = -20
	right_panel.offset_bottom = -20
	right_panel.add_theme_stylebox_override("panel", _create_stylebox(Color(0.12, 0.10, 0.08, 0.94), Color(0.72, 0.58, 0.28), 2, 6))
	add_child(right_panel)
	
	btn_end_turn = Button.new()
	btn_end_turn.text = "⚔ END TURN"
	btn_end_turn.add_theme_font_size_override("font_size", 22)
	btn_end_turn.add_theme_color_override("font_color", Color(1.0, 0.92, 0.5))
	btn_end_turn.add_theme_stylebox_override("normal", _create_stylebox(Color(0.42, 0.28, 0.12), Color(0.92, 0.75, 0.28), 2, 6))
	btn_end_turn.add_theme_stylebox_override("hover", _create_stylebox(Color(0.55, 0.38, 0.18), Color(1.0, 0.88, 0.4), 2, 6))
	btn_end_turn.pressed.connect(func(): end_turn_requested.emit())
	right_panel.add_child(btn_end_turn)
	
	# Event Log Label (bottom left above ground)
	event_log_label = Label.new()
	event_log_label.offset_left = 360
	event_log_label.offset_top = 660
	event_log_label.offset_right = 1000
	event_log_label.offset_bottom = 705
	event_log_label.add_theme_color_override("font_color", Color(1.0, 0.9, 0.75))
	event_log_label.text = "Campaign initialized. Lead the Horde to victory across the steppe!"
	add_child(event_log_label)
	
	# Battle Modal
	_create_battle_modal()
	
	# Game Over Modal
	_create_game_over_modal()
	
	# Help Modal
	_create_help_modal()

func _create_battle_modal():
	battle_modal = PanelContainer.new()
	battle_modal.name = "BattleModal"
	battle_modal.set_anchors_preset(Control.PRESET_CENTER)
	battle_modal.offset_left = -280
	battle_modal.offset_top = -180
	battle_modal.offset_right = 280
	battle_modal.offset_bottom = 180
	battle_modal.add_theme_stylebox_override("panel", _create_stylebox(Color(0.12, 0.08, 0.06, 0.98), Color(0.9, 0.3, 0.2), 3, 8))
	add_child(battle_modal)
	
	var vbox = VBoxContainer.new()
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_theme_constant_override("separation", 16)
	battle_modal.add_child(vbox)
	
	lbl_battle_title = Label.new()
	lbl_battle_title.text = "BATTLE REPORT"
	lbl_battle_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl_battle_title.add_theme_font_size_override("font_size", 26)
	lbl_battle_title.add_theme_color_override("font_color", Color(1.0, 0.85, 0.3))
	vbox.add_child(lbl_battle_title)
	
	lbl_battle_details = Label.new()
	lbl_battle_details.text = "Combat results..."
	lbl_battle_details.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl_battle_details.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vbox.add_child(lbl_battle_details)
	
	var btn_close = Button.new()
	btn_close.text = "Continue Campaign"
	btn_close.add_theme_stylebox_override("normal", _create_stylebox(Color(0.25, 0.35, 0.2), Color(0.6, 0.8, 0.4), 2, 6))
	btn_close.pressed.connect(func(): battle_modal.visible = false)
	vbox.add_child(btn_close)

func _create_game_over_modal():
	game_over_modal = PanelContainer.new()
	game_over_modal.name = "GameOverModal"
	game_over_modal.set_anchors_preset(Control.PRESET_CENTER)
	game_over_modal.offset_left = -300
	game_over_modal.offset_top = -190
	game_over_modal.offset_right = 300
	game_over_modal.offset_bottom = 190
	game_over_modal.add_theme_stylebox_override("panel", _create_stylebox(Color(0.1, 0.08, 0.06, 0.98), Color(1.0, 0.84, 0.25), 3, 8))
	add_child(game_over_modal)
	
	var vbox = VBoxContainer.new()
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_theme_constant_override("separation", 18)
	game_over_modal.add_child(vbox)
	
	lbl_game_over_title = Label.new()
	lbl_game_over_title.text = "VICTORY!"
	lbl_game_over_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl_game_over_title.add_theme_font_size_override("font_size", 32)
	lbl_game_over_title.add_theme_color_override("font_color", Color(1.0, 0.88, 0.35))
	vbox.add_child(lbl_game_over_title)
	
	lbl_game_over_details = Label.new()
	lbl_game_over_details.text = "The Steppe bows before your might."
	lbl_game_over_details.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl_game_over_details.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vbox.add_child(lbl_game_over_details)
	
	var btn_menu = Button.new()
	btn_menu.text = "Return to Main Menu"
	btn_menu.add_theme_font_size_override("font_size", 20)
	btn_menu.add_theme_stylebox_override("normal", _create_stylebox(Color(0.35, 0.25, 0.15), Color(0.9, 0.75, 0.3), 2, 6))
	btn_menu.pressed.connect(func(): return_to_menu_requested.emit())
	vbox.add_child(btn_menu)

func _create_help_modal():
	help_modal = PanelContainer.new()
	help_modal.name = "HelpModal"
	help_modal.set_anchors_preset(Control.PRESET_CENTER)
	help_modal.offset_left = -260
	help_modal.offset_top = -240
	help_modal.offset_right = 260
	help_modal.offset_bottom = 240
	help_modal.add_theme_stylebox_override("panel", _create_stylebox(Color(0.12, 0.10, 0.08, 0.98), Color(0.72, 0.58, 0.28), 2, 8))
	add_child(help_modal)
	
	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 12)
	help_modal.add_child(vbox)
	
	var title = Label.new()
	title.text = "PAUSE & STRATEGIC SETTINGS"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 20)
	title.add_theme_color_override("font_color", Color(1.0, 0.85, 0.3))
	vbox.add_child(title)
	
	# Audio Volume Controls
	var am = _get_audio_manager()
	
	var lbl_m = Label.new()
	lbl_m.text = "Master Volume"
	vbox.add_child(lbl_m)
	var s_m = HSlider.new()
	s_m.min_value = 0.0
	s_m.max_value = 1.0
	s_m.step = 0.05
	s_m.value = am.master_volume if am else 0.85
	s_m.value_changed.connect(func(v): if am: am.set_master_volume(v))
	vbox.add_child(s_m)
	
	var lbl_mus = Label.new()
	lbl_mus.text = "Music Volume"
	vbox.add_child(lbl_mus)
	var s_mus = HSlider.new()
	s_mus.min_value = 0.0
	s_mus.max_value = 1.0
	s_mus.step = 0.05
	s_mus.value = am.music_volume if am else 0.65
	s_mus.value_changed.connect(func(v): if am: am.set_music_volume(v))
	vbox.add_child(s_mus)
	
	var lbl_s = Label.new()
	lbl_s.text = "SFX Volume"
	vbox.add_child(lbl_s)
	var s_s = HSlider.new()
	s_s.min_value = 0.0
	s_s.max_value = 1.0
	s_s.step = 0.05
	s_s.value = am.sfx_volume if am else 0.8
	s_s.value_changed.connect(func(v): if am: am.set_sfx_volume(v))
	vbox.add_child(s_s)
	
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
	
	var hs = HSeparator.new()
	vbox.add_child(hs)
	
	var text = Label.new()
	text.text = "Controls:\n• WASD / Right-Drag: Pan Camera | Scroll: Zoom\n• Left-Click: Select Province or Attack Target\n• ESC: Toggle Pause Menu"
	text.add_theme_font_size_override("font_size", 13)
	text.add_theme_color_override("font_color", Color(0.85, 0.8, 0.7))
	vbox.add_child(text)
	
	var btn_hbox = HBoxContainer.new()
	btn_hbox.add_theme_constant_override("separation", 16)
	vbox.add_child(btn_hbox)
	
	var btn_ok = Button.new()
	btn_ok.text = "Resume Game"
	btn_ok.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	btn_ok.pressed.connect(func():
		_play_click()
		help_modal.visible = false
	)
	btn_hbox.add_child(btn_ok)
	
	var btn_menu_quit = Button.new()
	btn_menu_quit.text = "Main Menu"
	btn_menu_quit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	btn_menu_quit.pressed.connect(func():
		_play_click()
		return_to_menu_requested.emit()
	)
	btn_hbox.add_child(btn_menu_quit)

func _unhandled_input(event: InputEvent):
	if event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
		help_modal.visible = not help_modal.visible
		_play_click()

func _play_click():
	var am = _get_audio_manager()
	if am:
		am.play_click()

func _get_audio_manager():
	var loop = Engine.get_main_loop() as SceneTree
	if loop and loop.root and loop.root.has_node("AudioManager"):
		return loop.root.get_node("AudioManager")
	return null

func hide_modals():
	battle_modal.visible = false
	game_over_modal.visible = false
	help_modal.visible = false

func update_resources():
	var gm = _get_game_manager()
	if gm == null:
		return
	var player = gm.get_player_faction()
	if player.is_empty():
		return
		
	var income = {"gold": 0, "food": 0, "wood": 0}
	for pid in gm.provinces:
		if gm.provinces[pid].owner == "mongol":
			income.gold += gm.provinces[pid].income_gold
			income.food += gm.provinces[pid].income_food
			income.wood += gm.provinces[pid].income_wood
			
	lbl_turn.text = "Turn %d / %d" % [gm.turn, gm.max_turns]
	lbl_gold.text = "💰 %dg (+%d)" % [player.gold, income.gold]
	lbl_food.text = "🌾 %df (+%d)" % [player.food, income.food]
	lbl_wood.text = "🪵 %dw (+%d)" % [player.wood, income.wood]
	lbl_provinces.text = "🏛 Prov: %d / %d" % [gm.province_count("mongol"), gm.provinces_to_win]

func select_province(pid: String):
	selected_pid = pid
	attack_target_pid = ""
	attack_container.visible = false
	
	var gm = _get_game_manager()
	if gm == null or not gm.provinces.has(pid):
		deselect_province()
		return
		
	var p = gm.provinces[pid]
	var is_player = (p.owner == "mongol")
	left_panel.visible = true
	
	var cap_tag = " [CAPITAL]" if p.is_capital else ""
	var owner_name = "Neutral"
	var owner_f = gm.factions.get(p.owner, {})
	if not owner_f.is_empty():
		owner_name = owner_f.name
		
	lbl_province_name.text = p.name + cap_tag
	lbl_province_details.text = "Ruler: %s\nIncome: +%dg, +%df, +%dw\nDefense Bonus: +%d" % [
		owner_name, p.income_gold, p.income_food, p.income_wood, p.defense_bonus
	]
	
	# Update army list
	for child in army_list_container.get_children():
		child.queue_free()
		
	if p.army != null and not p.army.units.is_empty():
		for u in p.army.units:
			var u_lbl = Label.new()
			var name_str = u.type.replace("_", " ").capitalize()
			u_lbl.text = "• %s: %d warriors" % [name_str, u.count]
			u_lbl.add_theme_color_override("font_color", Color(1.0, 0.9, 0.75))
			army_list_container.add_child(u_lbl)
	else:
		var empty_lbl = Label.new()
		empty_lbl.text = "No garrison present."
		empty_lbl.add_theme_color_override("font_color", Color(0.6, 0.6, 0.6))
		army_list_container.add_child(empty_lbl)
		
	# Show/hide recruit & construct only for player-owned
	recruit_container.visible = is_player
	construct_container.visible = is_player

func prompt_attack(attacker_id: String, defender_id: String):
	selected_pid = attacker_id
	attack_target_pid = defender_id
	var gm = _get_game_manager()
	if gm == null:
		return
	var def_p = gm.provinces[defender_id]
	var def_f = gm.factions.get(def_p.owner, {})
	var owner_str = def_f.name if not def_f.is_empty() else "Neutral"
	
	lbl_attack_info.text = "TARGET: %s (%s)\nStrength: ~%d" % [
		def_p.name, owner_str, gm.get_army_strength(def_p.army)
	]
	attack_container.visible = true

func _on_confirm_attack_pressed():
	if selected_pid != "" and attack_target_pid != "":
		attack_requested.emit(selected_pid, attack_target_pid)
		attack_container.visible = false

func deselect_province():
	selected_pid = ""
	attack_target_pid = ""
	left_panel.visible = false

func show_battle_result(res: Dictionary, attacker_pid: String, defender_pid: String):
	var gm = _get_game_manager()
	if gm == null:
		return
	var def_name = gm.provinces[defender_pid].name
	
	if res.winner == "attacker":
		lbl_battle_title.text = "⚔ VICTORY IN %s!" % def_name.to_upper()
		lbl_battle_title.add_theme_color_override("font_color", Color(0.4, 0.95, 0.4))
		lbl_battle_details.text = "Your forces broke the defenders and seized control of %s!\nThe territory now swears fealty to the Golden Horde." % def_name
		log_event("Victory! Captured %s!" % def_name)
	else:
		lbl_battle_title.text = "DEFEAT AT %s" % def_name.to_upper()
		lbl_battle_title.add_theme_color_override("font_color", Color(0.95, 0.3, 0.3))
		lbl_battle_details.text = "The garrison held firm and repulsed our charge with heavy casualties."
		log_event("Attack repulsed at %s." % def_name)
		
	battle_modal.visible = true
	update_resources()

func show_game_over(is_victory: bool):
	if is_victory:
		lbl_game_over_title.text = "👑 VICTORY OVER EURASIA!"
		lbl_game_over_title.add_theme_color_override("font_color", Color(1.0, 0.88, 0.25))
		lbl_game_over_details.text = "The Golden Horde reigns supreme from the Danube to the Altai!\nYour rivals have yielded or been driven from history."
	else:
		lbl_game_over_title.text = "DEFEAT — THE HORDE COLLAPSES"
		lbl_game_over_title.add_theme_color_override("font_color", Color(0.95, 0.3, 0.25))
		lbl_game_over_details.text = "Your banners lie in the dust, and your people are scattered across the steppe."
	game_over_modal.visible = true

func log_event(msg: String):
	if event_log_label:
		event_log_label.text = msg

func _on_help_pressed():
	help_modal.visible = not help_modal.visible

func _on_save_pressed():
	var gm = _get_game_manager()
	if gm:
		if gm.save_game():
			log_event("Campaign successfully saved to disk.")
		else:
			log_event("Failed to save campaign.")

func _on_load_pressed():
	var gm = _get_game_manager()
	if gm:
		if gm.load_game():
			log_event("Campaign loaded successfully.")
			update_resources()
			deselect_province()
		else:
			log_event("No saved game found.")

func _on_menu_pressed():
	return_to_menu_requested.emit()

func _get_game_manager():
	var root = Engine.get_main_loop().root if Engine.get_main_loop() else null
	if root and root.has_node("GameManager"):
		return root.get_node("GameManager")
	return null
