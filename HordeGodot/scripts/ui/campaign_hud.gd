class_name CampaignHUD
extends CanvasLayer

## ==============================================================================
## HORDE: STEPPE & STEEL — CAMPAIGN HUD & THEMED PRESENTATION
## ==============================================================================
## Author: Ayaz (Subsystem: Economy Validation & UI Presentation)
##
## Integrates EconomyManager stateless validation with dynamic UI updates,
## theme-driven styling following the official 5-color palette, and
## authoritative transaction dispatch.
## ==============================================================================

const Palette = preload("res://scripts/core/palette.gd")
const EconomyManager = preload("res://scripts/core/economy_manager.gd")

signal end_turn_requested
signal recruit_requested(unit_type: String)
signal construct_requested(building_type: String)
signal attack_requested(attacker_pid: String, defender_pid: String)
signal return_to_menu_requested

var commands_locked: bool = false
var btn_confirm_attack: Button
var _last_modal_visible: bool = false
var modal_blocker: Control

var selected_pid: String = ""
var attack_target_pid: String = ""

# UI Containers
var top_bar: PanelContainer
var lbl_faction: Label
var lbl_turn: Label
var lbl_act: Label
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

# Cached button registries for dynamic economy validation
var recruit_buttons: Dictionary = {}
var construct_buttons: Dictionary = {}
var recruit_tooltips: Dictionary = {}

func _ready():
	if top_bar == null:
		_create_ui()
	_apply_theme()
	hide_modals()
	update_resources()
	deselect_province()

# -------------------------------------------------------------
# PALETTE & STYLING HELPERS (OFFICIAL 5-COLOR SYSTEM)
# -------------------------------------------------------------
func _apply_theme():
	var theme_path = "res://assets/theme/game_theme.tres"
	if ResourceLoader.exists(theme_path):
		var custom_theme = load(theme_path) as Theme
		if custom_theme:
			for child in get_children():
				if child is Control:
					child.theme = custom_theme

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

func _create_panel_stylebox() -> StyleBoxFlat:
	# Panels: Deep Steel Blue (#2B3A4A) with 2px Bronze Gold border (#DAA520) and 4px corner radius
	return _create_stylebox(Palette.DEEP_STEEL_BLUE, Palette.BRONZE_GOLD, 2, 4)

func _create_tactical_button_style(state: String) -> StyleBoxFlat:
	# Tactical Buttons (Recruit/Build): Wood Brown (#5C4033)
	var sb = StyleBoxFlat.new()
	sb.set_corner_radius_all(4)
	sb.content_margin_left = 10
	sb.content_margin_right = 10
	sb.content_margin_top = 6
	sb.content_margin_bottom = 6
	
	match state:
		"normal":
			sb.bg_color = Palette.WOOD_BROWN
			sb.border_color = Palette.BRONZE_GOLD
			sb.set_border_width_all(1)
		"hover":
			sb.bg_color = Palette.WOOD_BROWN.lightened(0.15)
			sb.border_color = Palette.BRONZE_GOLD.lightened(0.25)
			sb.set_border_width_all(1)
		"pressed":
			sb.bg_color = Palette.WOOD_BROWN.darkened(0.15)
			sb.border_color = Palette.BRONZE_GOLD
			sb.set_border_width_all(1)
		"disabled":
			# Disabled Elements: Controlled alpha (0.40) and dimmed text
			sb.bg_color = Color(Palette.WOOD_BROWN.r, Palette.WOOD_BROWN.g, Palette.WOOD_BROWN.b, 0.40)
			sb.border_color = Color(Palette.BRONZE_GOLD.r, Palette.BRONZE_GOLD.g, Palette.BRONZE_GOLD.b, 0.30)
			sb.set_border_width_all(1)
	return sb

func _create_primary_button_style(state: String) -> StyleBoxFlat:
	# Primary Buttons (End Turn): Steppe Green (#6B8E23)
	var sb = StyleBoxFlat.new()
	sb.set_corner_radius_all(4)
	sb.content_margin_left = 14
	sb.content_margin_right = 14
	sb.content_margin_top = 8
	sb.content_margin_bottom = 8
	
	match state:
		"normal":
			sb.bg_color = Palette.STEPPE_GREEN
			sb.border_color = Palette.BRONZE_GOLD
			sb.set_border_width_all(2)
		"hover":
			sb.bg_color = Palette.STEPPE_GREEN.lightened(0.15)
			sb.border_color = Palette.BRONZE_GOLD.lightened(0.25)
			sb.set_border_width_all(2)
		"pressed":
			sb.bg_color = Palette.STEPPE_GREEN.darkened(0.15)
			sb.border_color = Palette.BRONZE_GOLD
			sb.set_border_width_all(2)
		"disabled":
			sb.bg_color = Color(Palette.STEPPE_GREEN.r, Palette.STEPPE_GREEN.g, Palette.STEPPE_GREEN.b, 0.40)
			sb.border_color = Color(Palette.BRONZE_GOLD.r, Palette.BRONZE_GOLD.g, Palette.BRONZE_GOLD.b, 0.30)
			sb.set_border_width_all(1)
	return sb

func _style_tactical_button(btn: Button):
	btn.add_theme_stylebox_override("normal", _create_tactical_button_style("normal"))
	btn.add_theme_stylebox_override("hover", _create_tactical_button_style("hover"))
	btn.add_theme_stylebox_override("pressed", _create_tactical_button_style("pressed"))
	btn.add_theme_stylebox_override("disabled", _create_tactical_button_style("disabled"))
	btn.add_theme_stylebox_override("focus", _create_tactical_button_style("hover"))
	btn.add_theme_color_override("font_color", Palette.SNOW_WHITE)
	btn.add_theme_color_override("font_hover_color", Color.WHITE)
	btn.add_theme_color_override("font_pressed_color", Palette.BRONZE_GOLD)
	btn.add_theme_color_override("font_disabled_color", Color(Palette.SNOW_WHITE.r, Palette.SNOW_WHITE.g, Palette.SNOW_WHITE.b, 0.40))

# -------------------------------------------------------------
# UI CONSTRUCTION
# -------------------------------------------------------------
func _create_ui():
	# Top Bar
	top_bar = PanelContainer.new()
	top_bar.name = "TopBar"
	top_bar.set_anchors_preset(Control.PRESET_TOP_WIDE)
	top_bar.offset_bottom = 90
	top_bar.add_theme_stylebox_override("panel", _create_panel_stylebox())
	add_child(top_bar)
	
	var top_hbox = HFlowContainer.new()
	top_hbox.alignment = BoxContainer.ALIGNMENT_BEGIN
	top_hbox.add_theme_constant_override("h_separation", 12)
	top_bar.add_child(top_hbox)
	
	lbl_faction = Label.new()
	lbl_faction.text = "🐎 THE GOLDEN HORDE"
	lbl_faction.add_theme_color_override("font_color", Palette.BRONZE_GOLD)
	lbl_faction.add_theme_font_size_override("font_size", 18)
	top_hbox.add_child(lbl_faction)
	
	lbl_turn = Label.new()
	lbl_turn.text = "Turn 1 / 60"
	lbl_turn.add_theme_color_override("font_color", Palette.SNOW_WHITE)
	top_hbox.add_child(lbl_turn)
	
	lbl_act = Label.new()
	lbl_act.text = "⚔ ACT I: SETUP"
	lbl_act.add_theme_color_override("font_color", Palette.BRONZE_GOLD)
	lbl_act.add_theme_font_size_override("font_size", 14)
	top_hbox.add_child(lbl_act)
	
	lbl_gold = Label.new()
	lbl_gold.text = "💰 500g (+150)"
	lbl_gold.tooltip_text = "Treasury: Accumulates each turn from province taxes.\nUsed to recruit warriors and maintain troops."
	lbl_gold.mouse_filter = Control.MOUSE_FILTER_PASS
	lbl_gold.add_theme_color_override("font_color", Palette.BRONZE_GOLD)
	top_hbox.add_child(lbl_gold)
	
	lbl_food = Label.new()
	lbl_food.text = "🌾 300f (+100)"
	lbl_food.tooltip_text = "Grain & Pasture: Sustains armies.\nRequired alongside Gold to recruit new squads."
	lbl_food.mouse_filter = Control.MOUSE_FILTER_PASS
	lbl_food.add_theme_color_override("font_color", Palette.STEPPE_GREEN.lightened(0.2))
	top_hbox.add_child(lbl_food)
	
	lbl_wood = Label.new()
	lbl_wood.text = "🪵 200w (+50)"
	lbl_wood.tooltip_text = "Timber Reserves: Harvested from forests.\nUsed to build defensive stockades, pastures, and markets."
	lbl_wood.mouse_filter = Control.MOUSE_FILTER_PASS
	lbl_wood.add_theme_color_override("font_color", Palette.WOOD_BROWN.lightened(0.45))
	top_hbox.add_child(lbl_wood)
	
	lbl_provinces = Label.new()
	lbl_provinces.text = "🏛 Prov: 2 / 10"
	lbl_provinces.tooltip_text = "Territories Controlled: Conquer provinces across Eurasia to achieve total victory."
	lbl_provinces.mouse_filter = Control.MOUSE_FILTER_PASS
	lbl_provinces.add_theme_color_override("font_color", Palette.SNOW_WHITE)
	top_hbox.add_child(lbl_provinces)
	
	# Spacer
	var spacer = Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top_hbox.add_child(spacer)
	
	var btn_help = Button.new()
	btn_help.text = "Help / Keys"
	_style_tactical_button(btn_help)
	btn_help.pressed.connect(_on_help_pressed)
	top_hbox.add_child(btn_help)
	
	var btn_save = Button.new()
	btn_save.text = "Save"
	_style_tactical_button(btn_save)
	btn_save.pressed.connect(_on_save_pressed)
	top_hbox.add_child(btn_save)
	
	var btn_load = Button.new()
	btn_load.text = "Load"
	_style_tactical_button(btn_load)
	btn_load.pressed.connect(_on_load_pressed)
	top_hbox.add_child(btn_load)
	
	var btn_menu = Button.new()
	btn_menu.text = "Menu"
	_style_tactical_button(btn_menu)
	btn_menu.pressed.connect(_on_menu_pressed)
	top_hbox.add_child(btn_menu)
	
	# Left Selected Province Panel
	left_panel = PanelContainer.new()
	left_panel.name = "LeftPanel"
	left_panel.set_anchors_preset(Control.PRESET_LEFT_WIDE)
	left_panel.offset_left = 18
	left_panel.offset_top = 110
	left_panel.offset_right = 350
	left_panel.offset_bottom = -25
	left_panel.add_theme_stylebox_override("panel", _create_panel_stylebox())
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
	lbl_province_name.add_theme_color_override("font_color", Palette.BRONZE_GOLD)
	left_vbox.add_child(lbl_province_name)
	
	lbl_province_details = Label.new()
	lbl_province_details.text = "Details...\nIncome..."
	lbl_province_details.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	lbl_province_details.add_theme_color_override("font_color", Palette.SNOW_WHITE)
	left_vbox.add_child(lbl_province_details)
	
	var hs1 = HSeparator.new()
	left_vbox.add_child(hs1)
	
	# Garrison / Army section
	var lbl_army_header = Label.new()
	lbl_army_header.text = "Garrison / Troops:"
	lbl_army_header.add_theme_color_override("font_color", Palette.BRONZE_GOLD)
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
	lbl_attack_info.add_theme_color_override("font_color", Color(1.0, 0.45, 0.35))
	attack_container.add_child(lbl_attack_info)
	
	btn_confirm_attack = Button.new()
	btn_confirm_attack.text = "⚔ LAUNCH ATTACK"
	btn_confirm_attack.add_theme_stylebox_override("normal", _create_stylebox(Color(0.55, 0.15, 0.12), Palette.BRONZE_GOLD, 2, 4))
	btn_confirm_attack.add_theme_stylebox_override("hover", _create_stylebox(Color(0.70, 0.20, 0.15), Palette.BRONZE_GOLD.lightened(0.2), 2, 4))
	btn_confirm_attack.add_theme_stylebox_override("pressed", _create_stylebox(Color(0.40, 0.10, 0.08), Palette.BRONZE_GOLD, 2, 4))
	btn_confirm_attack.add_theme_color_override("font_color", Palette.SNOW_WHITE)
	btn_confirm_attack.pressed.connect(_on_confirm_attack_pressed)
	attack_container.add_child(btn_confirm_attack)
	
	var hs2 = HSeparator.new()
	left_vbox.add_child(hs2)
	
	# Recruitment section
	recruit_container = VBoxContainer.new()
	left_vbox.add_child(recruit_container)
	
	var lbl_rec_header = Label.new()
	lbl_rec_header.text = "Recruit Units:"
	lbl_rec_header.add_theme_color_override("font_color", Palette.BRONZE_GOLD)
	recruit_container.add_child(lbl_rec_header)
	
	var units_to_recruit = [
		{"type": "horse_archer", "label": "Horse Archer (150g, 50f)", "tip": "Fast skirmisher mounted archers.\nAtk: 35 | Def: 20 | Range: 2 | Move: 3\nTactical Advantage vs Infantry."},
		{"type": "light_cavalry", "label": "Light Cavalry (120g, 40f)", "tip": "Swift steppe outriders.\nAtk: 30 | Def: 25 | Range: 1 | Move: 3\nHigh mobility flanking."},
		{"type": "heavy_cavalry", "label": "Heavy Cavalry (250g, 80f)", "tip": "Armored shock cavalry.\nAtk: 55 | Def: 45 | Range: 1 | Move: 2\nDevastating charge burst. Vulnerable to Spearmen."},
		{"type": "infantry", "label": "Infantry (100g, 30f)", "tip": "Shielded foot soldiers.\nAtk: 40 | Def: 50 | Range: 1 | Move: 1\nResilient frontline defense."},
		{"type": "spearman", "label": "Spearman (110g, 35f)", "tip": "Pike wall infantry.\nAtk: 45 | Def: 55 | Range: 1 | Move: 1\nCounters cavalry charges."},
		{"type": "siege", "label": "Siege Engine (300g, 20f)", "tip": "Traction trebuchet.\nAtk: 70 | Def: 10 | Range: 3 | Move: 1\nLong-range bombardment vs fortifications."},
	]
	
	recruit_buttons.clear()
	recruit_tooltips.clear()
	for u in units_to_recruit:
		var btn = Button.new()
		btn.text = u.label
		btn.tooltip_text = u.tip
		btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
		_style_tactical_button(btn)
		
		var utype: String = u.type
		recruit_buttons[utype] = btn
		recruit_tooltips[utype] = u.tip
		
		btn.pressed.connect(func():
			_on_recruit_button_clicked(utype)
		)
		recruit_container.add_child(btn)
		
	var hs3 = HSeparator.new()
	left_vbox.add_child(hs3)
	
	# Construct section (All 7 canonical buildings from campaign_controller.gd)
	construct_container = VBoxContainer.new()
	left_vbox.add_child(construct_container)
	
	var lbl_con_header = Label.new()
	lbl_con_header.text = "Construct Buildings:"
	lbl_con_header.add_theme_color_override("font_color", Palette.BRONZE_GOLD)
	construct_container.add_child(lbl_con_header)
	
	var buildings = [
		{"type": "town_center", "base_label": "Town Center (+40g, +20f | 120w)"},
		{"type": "barracks", "base_label": "Barracks (+15 Def | 100w)"},
		{"type": "stables", "base_label": "Stables (+40 Food | 80w)"},
		{"type": "fortification", "base_label": "Fortifications (+20 Def | 100w)"},
		{"type": "palisade", "base_label": "Palisade (+10 Def | 80w)"},
		{"type": "pasture", "base_label": "Pasture (+40 Food | 80w)"},
		{"type": "market", "base_label": "Market (+50 Gold | 120w)"},
	]
	
	construct_buttons.clear()
	for b in buildings:
		var btn = Button.new()
		btn.text = b.base_label
		btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
		_style_tactical_button(btn)
		
		var btype: String = b.type
		construct_buttons[btype] = btn
		
		btn.pressed.connect(func():
			_on_construct_button_clicked(btype)
		)
		construct_container.add_child(btn)
		
	# Right Panel: Primary Action Button (End Turn)
	right_panel = PanelContainer.new()
	right_panel.name = "RightPanel"
	right_panel.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	right_panel.offset_left = -230
	right_panel.offset_top = -90
	right_panel.offset_right = -20
	right_panel.offset_bottom = -20
	right_panel.add_theme_stylebox_override("panel", _create_panel_stylebox())
	add_child(right_panel)
	
	# Primary Button (End Turn): Steppe Green (#6B8E23)
	btn_end_turn = Button.new()
	btn_end_turn.text = "⚔ END TURN"
	btn_end_turn.add_theme_font_size_override("font_size", 22)
	btn_end_turn.add_theme_color_override("font_color", Palette.SNOW_WHITE)
	btn_end_turn.add_theme_color_override("font_hover_color", Color.WHITE)
	btn_end_turn.add_theme_color_override("font_pressed_color", Palette.BRONZE_GOLD)
	btn_end_turn.add_theme_stylebox_override("normal", _create_primary_button_style("normal"))
	btn_end_turn.add_theme_stylebox_override("hover", _create_primary_button_style("hover"))
	btn_end_turn.add_theme_stylebox_override("pressed", _create_primary_button_style("pressed"))
	btn_end_turn.add_theme_stylebox_override("disabled", _create_primary_button_style("disabled"))
	btn_end_turn.pressed.connect(func():
		_play_click()
		end_turn_requested.emit()
	)
	right_panel.add_child(btn_end_turn)
	
	# Event Log Label
	event_log_label = Label.new()
	event_log_label.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	event_log_label.offset_left = 360
	event_log_label.offset_top = -65
	event_log_label.offset_right = -260
	event_log_label.offset_bottom = -15
	event_log_label.add_theme_color_override("font_color", Palette.SNOW_WHITE)
	event_log_label.text = "Select your army, then a neighboring province to march or attack."
	event_log_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	add_child(event_log_label)
	
	# Transparent input shield prevents clicks reaching the campaign behind dialogs.
	modal_blocker = Control.new()
	modal_blocker.name = "ModalInputShield"
	modal_blocker.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	modal_blocker.mouse_filter = Control.MOUSE_FILTER_STOP
	modal_blocker.visible = false
	add_child(modal_blocker)
	# Modals styled with Deep Steel Blue and Bronze Gold
	_create_battle_modal()
	_create_game_over_modal()
	_create_help_modal()

func _create_battle_modal():
	battle_modal = PanelContainer.new()
	battle_modal.name = "BattleModal"
	battle_modal.set_anchors_preset(Control.PRESET_CENTER)
	battle_modal.offset_left = -280
	battle_modal.offset_top = -180
	battle_modal.offset_right = 280
	battle_modal.offset_bottom = 180
	battle_modal.add_theme_stylebox_override("panel", _create_panel_stylebox())
	add_child(battle_modal)
	
	var vbox = VBoxContainer.new()
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_theme_constant_override("separation", 16)
	battle_modal.add_child(vbox)
	
	lbl_battle_title = Label.new()
	lbl_battle_title.text = "BATTLE REPORT"
	lbl_battle_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl_battle_title.add_theme_font_size_override("font_size", 26)
	lbl_battle_title.add_theme_color_override("font_color", Palette.BRONZE_GOLD)
	vbox.add_child(lbl_battle_title)
	
	lbl_battle_details = Label.new()
	lbl_battle_details.text = "Combat results..."
	lbl_battle_details.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl_battle_details.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	lbl_battle_details.add_theme_color_override("font_color", Palette.SNOW_WHITE)
	vbox.add_child(lbl_battle_details)
	
	var btn_close = Button.new()
	btn_close.text = "Continue Campaign"
	_style_tactical_button(btn_close)
	btn_close.pressed.connect(func():
		_play_click()
		battle_modal.visible = false
	)
	vbox.add_child(btn_close)

func _create_game_over_modal():
	game_over_modal = PanelContainer.new()
	game_over_modal.name = "GameOverModal"
	game_over_modal.set_anchors_preset(Control.PRESET_CENTER)
	game_over_modal.offset_left = -300
	game_over_modal.offset_top = -190
	game_over_modal.offset_right = 300
	game_over_modal.offset_bottom = 190
	game_over_modal.add_theme_stylebox_override("panel", _create_panel_stylebox())
	add_child(game_over_modal)
	
	var vbox = VBoxContainer.new()
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_theme_constant_override("separation", 18)
	game_over_modal.add_child(vbox)
	
	lbl_game_over_title = Label.new()
	lbl_game_over_title.text = "VICTORY!"
	lbl_game_over_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl_game_over_title.add_theme_font_size_override("font_size", 32)
	lbl_game_over_title.add_theme_color_override("font_color", Palette.BRONZE_GOLD)
	vbox.add_child(lbl_game_over_title)
	
	lbl_game_over_details = Label.new()
	lbl_game_over_details.text = "The Steppe bows before your might."
	lbl_game_over_details.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl_game_over_details.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	lbl_game_over_details.add_theme_color_override("font_color", Palette.SNOW_WHITE)
	vbox.add_child(lbl_game_over_details)
	
	var btn_menu = Button.new()
	btn_menu.text = "Return to Main Menu"
	btn_menu.add_theme_font_size_override("font_size", 20)
	_style_tactical_button(btn_menu)
	btn_menu.pressed.connect(func():
		_play_click()
		return_to_menu_requested.emit()
	)
	vbox.add_child(btn_menu)

func _create_help_modal():
	help_modal = PanelContainer.new()
	help_modal.name = "HelpModal"
	help_modal.set_anchors_preset(Control.PRESET_CENTER)
	help_modal.offset_left = -260
	help_modal.offset_top = -240
	help_modal.offset_right = 260
	help_modal.offset_bottom = 240
	help_modal.add_theme_stylebox_override("panel", _create_panel_stylebox())
	add_child(help_modal)
	
	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 12)
	help_modal.add_child(vbox)
	
	var title = Label.new()
	title.text = "STRATEGIC SETTINGS & CONTROLS"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 20)
	title.add_theme_color_override("font_color", Palette.BRONZE_GOLD)
	vbox.add_child(title)
	
	# Audio Volume Controls
	var am = _get_audio_manager()
	
	var lbl_m = Label.new()
	lbl_m.text = "Master Volume"
	lbl_m.add_theme_color_override("font_color", Palette.SNOW_WHITE)
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
	lbl_mus.add_theme_color_override("font_color", Palette.SNOW_WHITE)
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
	lbl_s.add_theme_color_override("font_color", Palette.SNOW_WHITE)
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
	btn_fs.add_theme_color_override("font_color", Palette.SNOW_WHITE)
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
	text.text = "Controls:\n• WASD / Right-Drag: Pan Camera | Scroll: Zoom\n• Select your army, then a neighbor: March / Merge / Attack\n• Movement refreshes each turn; battles use all remaining movement\n• ESC: Toggle Pause Menu\n• F10: Switch Camera Projection"
	text.add_theme_font_size_override("font_size", 13)
	text.add_theme_color_override("font_color", Palette.SNOW_WHITE)
	vbox.add_child(text)
	
	var btn_hbox = HBoxContainer.new()
	btn_hbox.add_theme_constant_override("separation", 16)
	vbox.add_child(btn_hbox)
	
	var btn_ok = Button.new()
	btn_ok.text = "Resume Game"
	btn_ok.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_style_tactical_button(btn_ok)
	btn_ok.pressed.connect(func():
		_play_click()
		help_modal.visible = false
		update_actions_state()
	)
	btn_hbox.add_child(btn_ok)
	
	var btn_menu_quit = Button.new()
	btn_menu_quit.text = "Main Menu"
	btn_menu_quit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_style_tactical_button(btn_menu_quit)
	btn_menu_quit.pressed.connect(func():
		_play_click()
		return_to_menu_requested.emit()
	)
	btn_hbox.add_child(btn_menu_quit)

# -------------------------------------------------------------
# DYNAMIC ECONOMY VALIDATION & ACTIONS UPDATE
# -------------------------------------------------------------
func update_actions_state():
	if top_bar == null:
		_ready()
	var gm = _get_game_manager()
	if gm == null:
		return
		
	var player = gm.get_player_faction()
	var p = gm.provinces.get(selected_pid, null) if selected_pid != "" else null
	var is_player = (p != null and p.owner == gm.current_faction)
	
	# Update construction buttons dynamically
	for btype in construct_buttons:
		var btn: Button = construct_buttons[btype]
		var b_data = EconomyManager.get_building_data(btype)
		var b_name: String = b_data.get("name", btype.capitalize())
		var wood_cost: int = b_data.get("wood_cost", 0)
		var b_desc: String = b_data.get("description", "")
		
		if not is_player or p == null:
			btn.disabled = true
			btn.text = "%s (%dw)" % [b_name, wood_cost]
			btn.tooltip_text = "%s\nCost: %d Wood\nSelect your province to construct." % [b_desc, wood_cost]
			continue
			
		var existing_buildings = p.get("buildings", [])
		if btype in existing_buildings:
			btn.disabled = true
			btn.text = "✔ %s [BUILT]" % b_name
			btn.tooltip_text = "%s\nStatus: Already built in %s.\nUniqueness strictly enforced (limit 1 per province)." % [
				b_desc, p.name
			]
		else:
			var validation = EconomyManager.can_build(p, player, btype)
			if validation.allowed:
				btn.disabled = false
				btn.text = "%s (%dw)" % [b_name, wood_cost]
				btn.tooltip_text = "%s\nCost: %d Wood (Treasury: %d Wood)\nClick to construct." % [
					b_desc, wood_cost, player.get("wood", 0)
				]
			else:
				btn.disabled = true
				btn.text = "%s (%dw)" % [b_name, wood_cost]
				btn.tooltip_text = "%s\nCost: %d Wood (Treasury: %d Wood)\nDisabled: %s" % [
					b_desc, wood_cost, player.get("wood", 0), validation.reason
				]
				
	# Update recruitment buttons dynamically
	for utype in recruit_buttons:
		var btn: Button = recruit_buttons[utype]
		var u_stats = gm.get_unit_stats(utype)
		var cost_gold: int = int(u_stats.get("cost_gold", 0))
		var cost_food: int = int(u_stats.get("cost_food", 0))
		var base_tip: String = recruit_tooltips.get(utype, "")
		var unit_name: String = utype.replace("_", " ").capitalize()
		
		if not is_player or p == null:
			btn.disabled = true
			btn.tooltip_text = "%s\nCost: %dg, %df\nSelect your province to recruit." % [base_tip, cost_gold, cost_food]
			continue
			
		var validation = EconomyManager.can_recruit(player, u_stats)
		if validation.allowed:
			btn.disabled = false
			btn.tooltip_text = "%s\nCost: %dg, %df (Treasury: %dg, %df)\nClick to recruit 50 warriors." % [
				base_tip, cost_gold, cost_food, player.get("gold", 0), player.get("food", 0)
			]
		else:
			btn.disabled = true
			btn.tooltip_text = "%s\nCost: %dg, %df (Treasury: %dg, %df)\nDisabled: %s" % [
				base_tip, cost_gold, cost_food, player.get("gold", 0), player.get("food", 0), validation.reason
			]

	var blocked: bool = commands_locked or gm.current_state != gm.GameState.CAMPAIGN or has_open_modal()
	btn_end_turn.disabled = blocked
	for button in construct_buttons.values() + recruit_buttons.values():
		if blocked:
			button.disabled = true
	if attack_target_pid != "":
		btn_confirm_attack.disabled = blocked or not gm.validate_army_order(selected_pid, attack_target_pid).allowed

func _on_construct_button_clicked(building_type: String):
	var gm = _get_game_manager()
	if gm == null or selected_pid == "" or commands_locked or has_open_modal():
		return
		
	var p = gm.provinces.get(selected_pid, null)
	var player = gm.get_player_faction()
	var validation = EconomyManager.can_build(p, player, building_type)
	if not validation.allowed:
		_play_click()
		log_event("Cannot construct %s: %s" % [building_type, validation.reason])
		return
		
	_play_click()
	construct_requested.emit(building_type)

func _on_recruit_button_clicked(unit_type: String):
	var gm = _get_game_manager()
	if gm == null or selected_pid == "" or commands_locked or has_open_modal():
		return
		
	var player = gm.get_player_faction()
	var u_stats = gm.get_unit_stats(unit_type)
	var validation = EconomyManager.can_recruit(player, u_stats)
	if not validation.allowed:
		_play_click()
		log_event("Cannot recruit %s: %s" % [unit_type.replace("_", " "), validation.reason])
		return
		
	_play_click()
	recruit_requested.emit(unit_type)

# -------------------------------------------------------------
# EVENT HANDLING & CONTROLLER INTEGRATION
# -------------------------------------------------------------
func has_open_modal() -> bool:
	return (is_instance_valid(help_modal) and help_modal.visible) or (is_instance_valid(game_over_modal) and game_over_modal.visible) or (is_instance_valid(battle_modal) and battle_modal.visible)

func _process(_delta: float) -> void:
	if is_instance_valid(left_panel) and is_instance_valid(top_bar):
		left_panel.offset_top = maxf(110.0, top_bar.get_global_rect().end.y + 12.0)
	if is_instance_valid(modal_blocker):
		var open: bool = has_open_modal()
		modal_blocker.visible = open
		if open != _last_modal_visible:
			_last_modal_visible = open
			update_actions_state()

func _unhandled_input(event: InputEvent):
	if commands_locked:
		return
	if event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
		help_modal.visible = not help_modal.visible
		update_actions_state()
		get_viewport().set_input_as_handled()
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
	if top_bar == null:
		_ready()
	var gm = _get_game_manager()
	if gm == null:
		return
	var player = gm.get_player_faction()
	if player.is_empty():
		return
		
	var p_faction = gm.current_faction
	var player_f = gm.factions.get(p_faction, {})
	if lbl_faction and not player_f.is_empty():
		lbl_faction.text = "⚔ " + player_f.name.to_upper()
		lbl_faction.add_theme_color_override("font_color", player_f.get("color", Palette.BRONZE_GOLD))
		
	var income = {"gold": 0, "food": 0, "wood": 0}
	for pid in gm.provinces:
		if gm.provinces[pid].owner == p_faction:
			income.gold += gm.provinces[pid].income_gold
			income.food += gm.provinces[pid].income_food
			income.wood += gm.provinces[pid].income_wood
			
	lbl_turn.text = "Turn %d / %d · %s" % [gm.turn, 30 if gm.current_scenario == "checkpoint_slice" else gm.max_turns, gm.season_name()]
	lbl_gold.text = "💰 %dg (+%d)" % [player.gold, income.gold]
	lbl_food.text = "🌾 %df (+%d)" % [player.food, income.food]
	lbl_wood.text = "🪵 %dw (+%d)" % [player.wood, income.wood]
	var p_count = gm.province_count(p_faction)
	lbl_provinces.text = "Capture Sarkel" if gm.current_scenario == "checkpoint_slice" else "Provinces: %d / %d" % [p_count, gm.provinces_to_win]
	
	if lbl_act:
		if p_count >= 7 or gm.turn >= 16:
			lbl_act.text = "⚔ ACT III: RESOLUTION"
			lbl_act.add_theme_color_override("font_color", Palette.BRONZE_GOLD.lightened(0.2))
		elif p_count >= 4 or gm.turn >= 6:
			lbl_act.text = "⚔ ACT II: CONFRONTATION"
			lbl_act.add_theme_color_override("font_color", Color(0.95, 0.7, 0.4))
		else:
			lbl_act.text = "⚔ ACT I: SETUP"
			lbl_act.add_theme_color_override("font_color", Palette.BRONZE_GOLD)
			
	update_actions_state()

func select_province(pid: String):
	if top_bar == null:
		_ready()
	selected_pid = pid
	attack_target_pid = ""
	attack_container.visible = false
	
	var gm = _get_game_manager()
	if gm == null or not gm.provinces.has(pid):
		deselect_province()
		return
		
	var p = gm.provinces[pid]
	var is_player = (p.owner == gm.current_faction)
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
	
	if p.army != null:
		lbl_province_details.text += "\nMovement: %d / %d (battle uses remaining movement)" % [gm.moves_left(p.army), gm.army_movement(p.army)]
	# Update army list
	for child in army_list_container.get_children():
		army_list_container.remove_child(child)
		child.queue_free()
		
	if p.army != null and not p.army.units.is_empty():
		for u in p.army.units:
			var u_lbl = Label.new()
			var name_str = u.type.replace("_", " ").capitalize()
			u_lbl.text = "• %s: %d warriors" % [name_str, u.count]
			u_lbl.add_theme_color_override("font_color", Palette.SNOW_WHITE)
			army_list_container.add_child(u_lbl)
	else:
		var empty_lbl = Label.new()
		empty_lbl.text = "No garrison present."
		empty_lbl.add_theme_color_override("font_color", Color(Palette.SNOW_WHITE.r, Palette.SNOW_WHITE.g, Palette.SNOW_WHITE.b, 0.50))
		army_list_container.add_child(empty_lbl)
		
	# Show/hide recruit & construct only for player-owned
	recruit_container.visible = is_player
	construct_container.visible = is_player
	
	update_actions_state()

func prompt_attack(attacker_id: String, defender_id: String):
	var gm = _get_game_manager()
	if gm == null or commands_locked:
		return
	var check: Dictionary = gm.validate_army_order(attacker_id, defender_id)
	if not check.allowed:
		log_event(check.reason)
		return
	select_province(attacker_id)
	attack_target_pid = defender_id
	var p: Dictionary = gm.provinces[defender_id]
	var friendly: bool = p.owner == gm.current_faction
	var defense: float = (gm.get_army_strength(p.army) + p.defense_bonus * 10) * gm.factions.get(p.owner, {}).get("bonus_defense", 1.0)
	lbl_attack_info.text = "MARCH TO: %s\nFriendly army will merge. Costs 1 movement." % p.name if friendly else "ATTACK: %s\nEnemy troops: %d · Fortified strength: %d\nBattle ends this army's movement." % [p.name, gm.get_army_strength(p.army), int(defense)]
	lbl_attack_info.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	btn_confirm_attack.text = "MARCH / MERGE" if friendly else "LAUNCH ATTACK"
	attack_container.visible = true
	update_actions_state()

func _on_confirm_attack_pressed():
	var gm = _get_game_manager()
	if commands_locked or has_open_modal() or gm == null:
		return
	if selected_pid != "" and attack_target_pid != "":
		var check: Dictionary = gm.validate_army_order(selected_pid, attack_target_pid)
		if not check.allowed:
			log_event(check.reason)
			return
		attack_container.visible = false
		attack_requested.emit(selected_pid, attack_target_pid)

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
		lbl_battle_title.add_theme_color_override("font_color", Palette.STEPPE_GREEN.lightened(0.2))
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
		lbl_game_over_title.text = "CAMPAIGN VICTORY"
		lbl_game_over_title.add_theme_color_override("font_color", Palette.BRONZE_GOLD)
		lbl_game_over_details.text = "Your faction achieved the campaign objective."
	else:
		lbl_game_over_title.text = "CAMPAIGN DEFEAT"
		lbl_game_over_title.add_theme_color_override("font_color", Color(0.95, 0.3, 0.25))
		lbl_game_over_details.text = "Your banners lie in the dust, and your people are scattered across the steppe."
	game_over_modal.visible = true

func log_event(msg: String):
	if event_log_label:
		event_log_label.text = msg

func _on_help_pressed():
	if commands_locked:
		return
	help_modal.visible = not help_modal.visible

func _on_save_pressed():
	if commands_locked or has_open_modal():
		return
	var gm = _get_game_manager()
	if gm:
		if gm.save_game():
			log_event("Campaign successfully saved to disk.")
		else:
			log_event("Failed to save campaign.")

func _on_load_pressed():
	if commands_locked or has_open_modal():
		return
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

var game_manager_ref = null

func _get_game_manager():
	if game_manager_ref != null:
		return game_manager_ref
	if is_inside_tree() and get_tree() and get_tree().root and get_tree().root.has_node("GameManager"):
		return get_tree().root.get_node("GameManager")
	if get_parent() and get_parent().has_node("GameManager"):
		return get_parent().get_node("GameManager")
	var loop = Engine.get_main_loop() as SceneTree
	if loop and loop.root and loop.root.has_node("GameManager"):
		return loop.root.get_node("GameManager")
	return null
