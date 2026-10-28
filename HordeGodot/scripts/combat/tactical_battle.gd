class_name TacticalBattle
extends Control

signal battle_completed(result: Dictionary)

const ModelBuilder = preload("res://scripts/visuals/model_builder.gd")

# Battle Data
var attacker_faction: String = "mongol"
var defender_faction: String = "rus"
var attacker_pid: String = ""
var defender_pid: String = ""

# Squad data structures:
# Array of Dictionaries: {id, faction, type, count, max_count, hp, max_hp, attack, defense, range, acted, node, hp_bar, count_lbl}
var attacker_squads: Array[Dictionary] = []
var defender_squads: Array[Dictionary] = []

var selected_squad_index: int = -1
var is_player_turn: bool = true
var round_number: int = 1
var is_busy: bool = false # During animations

# 3D SubViewport & Camera
var sub_viewport: SubViewport
var battlefield_root: Node3D
var battle_cam: Camera3D

# UI Nodes
var top_panel: PanelContainer
var lbl_attacker_info: Label
var lbl_defender_info: Label
var bar_attacker_str: ProgressBar
var bar_defender_str: ProgressBar
var lbl_round: Label

var unit_card: PanelContainer
var lbl_unit_title: Label
var lbl_unit_stats: Label
var lbl_unit_tactics: Label
var btn_attack: Button
var btn_defend: Button
var btn_end_turn: Button
var btn_autoresolve: Button
var btn_retreat: Button

var preview_label: Label
var log_label: Label

# Final Result Overlay
var result_modal: PanelContainer
var lbl_result_title: Label
var lbl_result_stats: Label
var btn_result_continue: Button

var game_manager_ref = null
var audio_manager_ref = null

func setup_battle(att_pid: String, def_pid: String, gm_override = null, am_override = null):
	attacker_pid = att_pid
	defender_pid = def_pid
	if gm_override != null:
		game_manager_ref = gm_override
	if am_override != null:
		audio_manager_ref = am_override
	
	var gm = _get_game_manager()
	if gm == null:
		return
		
	var att_p = gm.provinces[att_pid]
	var def_p = gm.provinces[def_pid]
	
	attacker_faction = att_p.army.faction if att_p.army else "mongol"
	defender_faction = def_p.owner if def_p.owner != "" else "neutral"
	
	# Build squad data from province armies
	attacker_squads.clear()
	defender_squads.clear()
	
	if att_p.army and not att_p.army.units.is_empty():
		for u in att_p.army.units:
			attacker_squads.append(_create_squad_dict(u, attacker_faction))
	else:
		attacker_squads.append(_create_squad_dict({"type": "horse_archer", "count": 60}, attacker_faction))
		
	if def_p.army and not def_p.army.units.is_empty():
		for u in def_p.army.units:
			defender_squads.append(_create_squad_dict(u, defender_faction))
	else:
		# Militia garrison if undefended
		defender_squads.append(_create_squad_dict({"type": "infantry", "count": 40}, defender_faction))
		
	_build_ui()
	_build_3d_battlefield()
	_update_top_bar()
	_select_first_available_unit()
	
	# Launch automated combat resolution sequence
	_start_automated_battle_sequence()

func _create_squad_dict(unit_info: Dictionary, f_id: String) -> Dictionary:
	var utype = unit_info.type
	var count = int(unit_info.count)
	var gm = _get_game_manager()
	var stats = gm.get_unit_stats(utype) if gm else {}
	
	var base_hp = stats.get("hp", 80)
	var base_atk = stats.get("attack", 40)
	var base_def = stats.get("defense", 30)
	var base_rng = stats.get("range", 1)
	
	# Apply faction modifier
	var atk_mult = 1.0
	var def_mult = 1.0
	if gm and gm.factions.has(f_id):
		atk_mult = gm.factions[f_id].get("bonus_attack", 1.0)
		def_mult = gm.factions[f_id].get("bonus_defense", 1.0)
		
	return {
		"faction": f_id,
		"type": utype,
		"count": count,
		"max_count": count,
		"hp": base_hp * count,
		"max_hp": base_hp * count,
		"base_hp_per_man": base_hp,
		"attack": int(base_atk * atk_mult),
		"defense": int(base_def * def_mult),
		"range": base_rng,
		"acted": false,
		"defending": false,
		"node": null,
		"highlight": null,
		"badge": null,
	}

# -------------------------------------------------------------
# 3D BATTLEFIELD SETUP
# -------------------------------------------------------------
func _build_3d_battlefield():
	var vp_container = SubViewportContainer.new()
	vp_container.set_anchors_preset(Control.PRESET_FULL_RECT)
	vp_container.stretch = true
	add_child(vp_container)
	move_child(vp_container, 0) # Place behind 2D UI
	
	sub_viewport = SubViewport.new()
	sub_viewport.name = "BattleSubViewport"
	sub_viewport.own_world_3d = true
	sub_viewport.msaa_3d = Viewport.MSAA_2X
	vp_container.add_child(sub_viewport)
	
	battlefield_root = Node3D.new()
	battlefield_root.name = "Battlefield3D"
	sub_viewport.add_child(battlefield_root)
	
	# Camera
	battle_cam = Camera3D.new()
	battle_cam.position = Vector3(0, 5.5, 9.5)
	battle_cam.rotation_degrees = Vector3(-28, 0, 0)
	battle_cam.fov = 42.0
	battle_cam.current = true
	battlefield_root.add_child(battle_cam)
	
	# Lighting & Atmosphere
	var sun = DirectionalLight3D.new()
	sun.light_color = Color(1.0, 0.94, 0.85)
	sun.light_energy = 1.35
	sun.shadow_enabled = true
	sun.rotation_degrees = Vector3(-42, 35, 0)
	battlefield_root.add_child(sun)
	
	var env_node = WorldEnvironment.new()
	var env = Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.12, 0.10, 0.08)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.5, 0.45, 0.4)
	env.fog_enabled = true
	env.fog_light_color = Color(0.45, 0.38, 0.32)
	env.fog_density = 0.012
	env_node.environment = env
	battlefield_root.add_child(env_node)
	
	# Arena Ground Plateau
	var ground = MeshInstance3D.new()
	var cyl = CylinderMesh.new()
	cyl.top_radius = 9.0
	cyl.bottom_radius = 9.4
	cyl.height = 0.5
	cyl.radial_segments = 16
	ground.mesh = cyl
	ground.material_override = ModelBuilder.get_mat("steppe_grass")
	ground.position = Vector3(0, -0.25, 0)
	battlefield_root.add_child(ground)
	
	# Decorative rocks and trees on periphery
	var p1 = ModelBuilder.create_pine_tree(1.2)
	p1.position = Vector3(-5.5, 0, -3.5)
	battlefield_root.add_child(p1)
	var p2 = ModelBuilder.create_birch_tree(1.1)
	p2.position = Vector3(5.5, 0, -3.2)
	battlefield_root.add_child(p2)
	var rock = ModelBuilder.create_rock_cluster(1.1)
	rock.position = Vector3(0, 0, -4.5)
	battlefield_root.add_child(rock)
	
	# Spawn Attacker Squad Models (Left side, X: -4.5 to -2.0)
	for i in range(attacker_squads.size()):
		var sq = attacker_squads[i]
		var model = _instance_unit_3d(sq.type, attacker_faction)
		var z_pos = (i - (attacker_squads.size() - 1) * 0.5) * 2.2
		model.position = Vector3(-3.2, 0, z_pos)
		model.rotation_degrees = Vector3(0, 90, 0) # Facing east toward enemy
		battlefield_root.add_child(model)
		sq["node"] = model
		
		# 3D Selection Ring & Badge
		var ring = _create_unit_ring(Color(1.0, 0.85, 0.2))
		model.add_child(ring)
		sq["highlight"] = ring
		
		var badge = _create_unit_badge(sq.count, Color(1.0, 0.9, 0.4))
		model.add_child(badge)
		sq["badge"] = badge
		
	# Spawn Defender Squad Models (Right side, X: 2.0 to 4.5)
	for i in range(defender_squads.size()):
		var sq = defender_squads[i]
		var model = _instance_unit_3d(sq.type, defender_faction)
		var z_pos = (i - (defender_squads.size() - 1) * 0.5) * 2.2
		model.position = Vector3(3.2, 0, z_pos)
		model.rotation_degrees = Vector3(0, -90, 0) # Facing west toward attacker
		battlefield_root.add_child(model)
		sq["node"] = model
		
		var ring = _create_unit_ring(Color(0.9, 0.25, 0.2))
		model.add_child(ring)
		sq["highlight"] = ring
		
		var badge = _create_unit_badge(sq.count, Color(0.95, 0.5, 0.5))
		model.add_child(badge)
		sq["badge"] = badge

func _instance_unit_3d(utype: String, faction: String) -> Node3D:
	var f_col = Color(0.9, 0.75, 0.22) if faction == "mongol" else Color(0.78, 0.2, 0.2)
	match utype:
		"horse_archer", "light_cavalry":
			return ModelBuilder.create_horse_archer_unit(f_col)
		"heavy_cavalry":
			return ModelBuilder.create_heavy_cavalry_unit(f_col)
		"spearman":
			return ModelBuilder.create_spearman_unit(f_col)
		"siege":
			return ModelBuilder.create_siege_engine(f_col)
		_:
			return ModelBuilder.create_infantry_unit(f_col)

func _create_unit_ring(color: Color) -> MeshInstance3D:
	var mi = MeshInstance3D.new()
	var t_mesh = TorusMesh.new()
	t_mesh.inner_radius = 0.65
	t_mesh.outer_radius = 0.8
	t_mesh.rings = 12
	t_mesh.ring_segments = 4
	mi.mesh = t_mesh
	
	var mat = StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.albedo_color = color
	mi.material_override = mat
	mi.position = Vector3(0, 0.05, 0)
	mi.visible = false
	return mi

func _create_unit_badge(count: int, color: Color) -> Label3D:
	var lbl = Label3D.new()
	lbl.text = "⚔ " + str(count)
	lbl.position = Vector3(0, 1.6, 0)
	lbl.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	lbl.no_depth_test = true
	lbl.font_size = 28
	lbl.outline_size = 6
	lbl.outline_modulate = Color(0.1, 0.05, 0.02)
	lbl.modulate = color
	return lbl

# -------------------------------------------------------------
# 2D UI & COMMAND PANEL
# -------------------------------------------------------------
func _build_ui():
	# Top Section
	top_panel = PanelContainer.new()
	top_panel.set_anchors_preset(Control.PRESET_TOP_WIDE)
	top_panel.offset_bottom = 75
	top_panel.add_theme_stylebox_override("panel", _create_sb(Color(0.10, 0.08, 0.06, 0.94), Color(0.78, 0.62, 0.28), 2))
	add_child(top_panel)
	
	var top_vbox = VBoxContainer.new()
	top_panel.add_child(top_vbox)
	
	var top_hbox = HBoxContainer.new()
	top_hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	top_hbox.add_theme_constant_override("separation", 32)
	top_vbox.add_child(top_hbox)
	
	lbl_attacker_info = Label.new()
	lbl_attacker_info.text = "ATTACKER: MONGOL KHANATE (450)"
	lbl_attacker_info.add_theme_font_size_override("font_size", 16)
	lbl_attacker_info.add_theme_color_override("font_color", Color(1.0, 0.85, 0.3))
	top_hbox.add_child(lbl_attacker_info)
	
	lbl_round = Label.new()
	lbl_round.text = "⚔ ROUND 1 — YOUR COMMAND"
	lbl_round.add_theme_font_size_override("font_size", 18)
	lbl_round.add_theme_color_override("font_color", Color(1.0, 0.95, 0.85))
	top_hbox.add_child(lbl_round)
	
	lbl_defender_info = Label.new()
	lbl_defender_info.text = "DEFENDER: RUS' PRINCIPALITIES (380)"
	lbl_defender_info.add_theme_font_size_override("font_size", 16)
	lbl_defender_info.add_theme_color_override("font_color", Color(0.95, 0.4, 0.35))
	top_hbox.add_child(lbl_defender_info)
	
	# Health/Strength Progress Bar
	var bars_hbox = HBoxContainer.new()
	bars_hbox.add_theme_constant_override("separation", 16)
	top_vbox.add_child(bars_hbox)
	
	bar_attacker_str = ProgressBar.new()
	bar_attacker_str.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bar_attacker_str.max_value = 100
	bar_attacker_str.value = 100
	bars_hbox.add_child(bar_attacker_str)
	
	bar_defender_str = ProgressBar.new()
	bar_defender_str.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bar_defender_str.max_value = 100
	bar_defender_str.value = 100
	bars_hbox.add_child(bar_defender_str)
	
	# Bottom Command & Unit Details Card
	unit_card = PanelContainer.new()
	unit_card.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	unit_card.offset_top = -165
	unit_card.offset_left = 40
	unit_card.offset_right = -40
	unit_card.offset_bottom = -15
	unit_card.add_theme_stylebox_override("panel", _create_sb(Color(0.12, 0.10, 0.08, 0.96), Color(0.72, 0.58, 0.28), 2, 8))
	add_child(unit_card)
	
	var card_hbox = HBoxContainer.new()
	card_hbox.add_theme_constant_override("separation", 24)
	unit_card.add_child(card_hbox)
	
	# Left: Unit info
	var info_vbox = VBoxContainer.new()
	info_vbox.custom_minimum_size = Vector2(320, 0)
	card_hbox.add_child(info_vbox)
	
	lbl_unit_title = Label.new()
	lbl_unit_title.text = "Selected Unit"
	lbl_unit_title.add_theme_font_size_override("font_size", 20)
	lbl_unit_title.add_theme_color_override("font_color", Color(1.0, 0.88, 0.35))
	info_vbox.add_child(lbl_unit_title)
	
	lbl_unit_stats = Label.new()
	lbl_unit_stats.text = "Troops: 100/100 | Attack: 35 | Defense: 20 | Range: 2"
	info_vbox.add_child(lbl_unit_stats)
	
	lbl_unit_tactics = Label.new()
	lbl_unit_tactics.text = "Tactical Role: Fast Horse Archer. Ranged hit-and-run advantage."
	lbl_unit_tactics.add_theme_color_override("font_color", Color(0.8, 0.75, 0.65))
	lbl_unit_tactics.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	info_vbox.add_child(lbl_unit_tactics)
	
	# Middle: Actions
	var action_vbox = VBoxContainer.new()
	action_vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	action_vbox.add_theme_constant_override("separation", 10)
	card_hbox.add_child(action_vbox)
	
	var act_row = HBoxContainer.new()
	act_row.add_theme_constant_override("separation", 12)
	action_vbox.add_child(act_row)
	
	btn_attack = _create_btn("⚔ STRIKE NOW", Color(0.55, 0.18, 0.12), Color(0.9, 0.35, 0.25))
	btn_attack.pressed.connect(_on_attack_pressed)
	act_row.add_child(btn_attack)
	
	btn_defend = _create_btn("🛡 BRACE (+30% Def)", Color(0.20, 0.26, 0.32), Color(0.45, 0.6, 0.8))
	btn_defend.pressed.connect(_on_defend_pressed)
	act_row.add_child(btn_defend)
	
	var row2 = HBoxContainer.new()
	row2.add_theme_constant_override("separation", 12)
	action_vbox.add_child(row2)
	
	btn_autoresolve = _create_btn("⚡ SKIP TO REPORT", Color(0.17, 0.23, 0.29), Color(0.85, 0.65, 0.13))
	btn_autoresolve.pressed.connect(_on_autoresolve_pressed)
	row2.add_child(btn_autoresolve)
	
	btn_retreat = _create_btn("🏳 TACTICAL RETREAT", Color(0.28, 0.12, 0.12), Color(0.6, 0.25, 0.25))
	btn_retreat.pressed.connect(_on_retreat_pressed)
	row2.add_child(btn_retreat)
	
	btn_end_turn = _create_btn("PAUSE / STEP", Color(0.25, 0.20, 0.15), Color(0.7, 0.6, 0.3))
	btn_end_turn.pressed.connect(_on_end_round_pressed)
	row2.add_child(btn_end_turn)
	
	# Right: Attack Preview & Feedback
	var log_vbox = VBoxContainer.new()
	log_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	card_hbox.add_child(log_vbox)
	
	preview_label = Label.new()
	preview_label.text = "Target: None selected (Click enemy squad or press Attack to strike closest)"
	preview_label.add_theme_color_override("font_color", Color(1.0, 0.85, 0.4))
	preview_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	log_vbox.add_child(preview_label)
	
	log_label = Label.new()
	log_label.text = "Battle commenced. Order your squads to strike or brace!"
	log_label.add_theme_color_override("font_color", Color(0.75, 0.9, 0.75))
	log_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	log_vbox.add_child(log_label)
	
	# Result Modal
	_create_result_modal()

func _create_sb(bg: Color, border: Color, bw: int = 2, r: int = 6) -> StyleBoxFlat:
	var sb = StyleBoxFlat.new()
	sb.bg_color = bg
	sb.set_border_width_all(bw)
	sb.border_color = border
	sb.set_corner_radius_all(r)
	sb.content_margin_left = 16
	sb.content_margin_right = 16
	sb.content_margin_top = 10
	sb.content_margin_bottom = 10
	return sb

func _create_btn(text: String, bg: Color, border: Color) -> Button:
	var btn = Button.new()
	btn.text = text
	btn.custom_minimum_size = Vector2(160, 42)
	btn.add_theme_stylebox_override("normal", _create_sb(bg, border, 1, 4))
	btn.add_theme_stylebox_override("hover", _create_sb(bg.lightened(0.2), border.lightened(0.3), 1, 4))
	return btn

func _create_result_modal():
	result_modal = PanelContainer.new()
	result_modal.set_anchors_preset(Control.PRESET_CENTER)
	result_modal.offset_left = -300
	result_modal.offset_top = -180
	result_modal.offset_right = 300
	result_modal.offset_bottom = 180
	result_modal.add_theme_stylebox_override("panel", _create_sb(Color(0.10, 0.08, 0.06, 0.98), Color(0.9, 0.75, 0.3), 3, 10))
	result_modal.visible = false
	add_child(result_modal)
	
	var vbox = VBoxContainer.new()
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_theme_constant_override("separation", 16)
	result_modal.add_child(vbox)
	
	lbl_result_title = Label.new()
	lbl_result_title.text = "VICTORY!"
	lbl_result_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl_result_title.add_theme_font_size_override("font_size", 30)
	lbl_result_title.add_theme_color_override("font_color", Color(1.0, 0.88, 0.35))
	vbox.add_child(lbl_result_title)
	
	lbl_result_stats = Label.new()
	lbl_result_stats.text = "Casualties & spoils..."
	lbl_result_stats.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl_result_stats.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vbox.add_child(lbl_result_stats)
	
	btn_result_continue = Button.new()
	btn_result_continue.text = "Claim Victory & Return to Campaign"
	btn_result_continue.add_theme_font_size_override("font_size", 18)
	btn_result_continue.add_theme_stylebox_override("normal", _create_sb(Color(0.35, 0.25, 0.15), Color(0.9, 0.75, 0.3), 2, 6))
	btn_result_continue.pressed.connect(_on_finish_battle_clicked)
	vbox.add_child(btn_result_continue)

# -------------------------------------------------------------
# COMBAT INTERACTIONS & LOGIC
# -------------------------------------------------------------
func _select_first_available_unit():
	for i in range(attacker_squads.size()):
		if attacker_squads[i].count > 0 and not attacker_squads[i].acted:
			_select_squad(i)
			return
	_select_squad(0)

func _select_squad(idx: int):
	selected_squad_index = idx
	for i in range(attacker_squads.size()):
		var sq = attacker_squads[i]
		if sq.highlight:
			sq.highlight.visible = (i == idx and sq.count > 0)
			
	_update_unit_card()

func _update_unit_card():
	if selected_squad_index < 0 or selected_squad_index >= attacker_squads.size():
		return
	var sq = attacker_squads[selected_squad_index]
	var type_name = sq.type.replace("_", " ").capitalize()
	lbl_unit_title.text = "%s Squad (%d warriors)" % [type_name, sq.count]
	lbl_unit_stats.text = "Health: %d/%d | Atk: %d | Def: %d | Range: %d" % [
		sq.hp, sq.max_hp, sq.attack, sq.defense, sq.range
	]
	
	match sq.type:
		"horse_archer":
			lbl_unit_tactics.text = "Tactics: Mounted composite bowmen. Devastating ranged harassment, bonus vs Infantry."
		"heavy_cavalry":
			lbl_unit_tactics.text = "Tactics: Armored lance charge. Massive burst shock damage, vulnerable to Spearmen."
		"spearman":
			lbl_unit_tactics.text = "Tactics: Pike wall formation. High defense, repels cavalry charges."
		"siege":
			lbl_unit_tactics.text = "Tactics: Long-range bombardment. Crushes fortified garrisons."
		_:
			lbl_unit_tactics.text = "Tactics: Resilient foot soldiers with shields and axes. Reliable frontline defense."
			
	btn_attack.disabled = (sq.count <= 0 or sq.acted or not is_player_turn or is_busy)
	btn_defend.disabled = (sq.count <= 0 or sq.acted or not is_player_turn or is_busy)
	
	# Target preview
	var target = _get_best_target()
	if target:
		var dmg_est = _estimate_damage(sq, target)
		preview_label.text = "Target: %s (%d left) | Projected losses: ~%d warriors" % [
			target.type.replace("_", " ").capitalize(), target.count, dmg_est
		]
	else:
		preview_label.text = "All enemy squads eliminated!"

func _get_best_target() -> Dictionary:
	# Find living enemy squad with lowest count or closest
	for sq in defender_squads:
		if sq.count > 0:
			return sq
	return {}

func _estimate_damage(attacker: Dictionary, defender: Dictionary) -> int:
	var ratio = float(attacker.count) / float(attacker.max_count)
	var raw = float(attacker.attack) * ratio * 1.8
	var def_val = float(defender.defense) * (float(defender.count) / float(defender.max_count))
	if defender.get("defending", false):
		def_val *= 1.3
	var actual = maxf(1.0, raw - def_val * 0.4)
	return int(clampf(actual, 1.0, float(defender.count)))

func _on_attack_pressed():
	if is_busy or not is_player_turn or selected_squad_index < 0:
		return
	var attacker = attacker_squads[selected_squad_index]
	if attacker.acted or attacker.count <= 0:
		return
		
	var target = _get_best_target()
	if target.is_empty():
		return
		
	_execute_attack(attacker, target, true)

func _on_defend_pressed():
	if is_busy or not is_player_turn or selected_squad_index < 0:
		return
	var attacker = attacker_squads[selected_squad_index]
	attacker.acted = true
	attacker.defending = true
	_play_sound("shield")
	log_label.text = "%s braced defensive formation (+30%% defense)!" % attacker.type.replace("_", " ").capitalize()
	_check_player_phase_complete()

func _execute_attack(attacker: Dictionary, defender: Dictionary, is_player: bool):
	is_busy = true
	var att_name = attacker.type.replace("_", " ").capitalize()
	var def_name = defender.type.replace("_", " ").capitalize()
	
	# 1. Play attack sound
	match attacker.type:
		"horse_archer", "siege":
			_play_sound("arrow")
		"heavy_cavalry":
			_play_sound("cavalry")
		_:
			_play_sound("sword")
			
	# 2. Animate 3D lunge or projectile
	var tween = create_tween()
	var orig_pos = attacker.node.position
	var target_pos = defender.node.position
	var lunge_pos = orig_pos.lerp(target_pos, 0.45)
	
	tween.tween_property(attacker.node, "position", lunge_pos, 0.18).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_callback(func():
		# Deal damage
		var dmg = _estimate_damage(attacker, defender)
		# Add variance
		dmg = int(dmg * randf_range(0.85, 1.2))
		dmg = clamp(dmg, 1, defender.count)
		
		defender.count -= dmg
		defender.hp = max(0, defender.hp - dmg * defender.base_hp_per_man)
		
		_play_sound("sword" if attacker.type != "siege" else "shield")
		_show_floating_damage(defender.node.position, dmg, Color(1.0, 0.3, 0.2))
		
		# Update badge
		if defender.badge:
			defender.badge.text = "⚔ " + str(defender.count)
			if defender.count <= 0:
				defender.badge.visible = false
				defender.node.visible = false
				
		log_label.text = "%s attacks %s for %d casualties!" % [att_name, def_name, dmg]
		_update_top_bar()
	)
	tween.tween_property(attacker.node, "position", orig_pos, 0.22).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tween.tween_callback(func():
		attacker.acted = true
		is_busy = false
		if is_player:
			_check_player_phase_complete()
	)

func _show_floating_damage(pos: Vector3, dmg: int, color: Color):
	var lbl = Label3D.new()
	lbl.text = "-" + str(dmg)
	lbl.position = pos + Vector3(0, 2.0, 0)
	lbl.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	lbl.no_depth_test = true
	lbl.font_size = 36
	lbl.outline_size = 8
	lbl.outline_modulate = Color(0, 0, 0)
	lbl.modulate = color
	battlefield_root.add_child(lbl)
	
	var tw = create_tween()
	tw.tween_property(lbl, "position", lbl.position + Vector3(0, 1.2, 0), 0.65).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tw.parallel().tween_property(lbl, "modulate:a", 0.0, 0.65)
	tw.tween_callback(lbl.queue_free)

func _check_player_phase_complete():
	if _check_battle_over():
		return
		
	# Check if all player units have acted
	var all_acted = true
	for sq in attacker_squads:
		if sq.count > 0 and not sq.acted:
			all_acted = false
			break
			
	if all_acted:
		_start_enemy_turn()
	else:
		_select_first_available_unit()

func _on_end_round_pressed():
	if is_busy or not is_player_turn:
		return
	_start_enemy_turn()

func _start_enemy_turn():
	is_player_turn = false
	lbl_round.text = "⚔ ENEMY COUNTER-ATTACK PHASE..."
	lbl_round.add_theme_color_override("font_color", Color(0.95, 0.45, 0.35))
	_update_unit_card()
	
	# Execute enemy attacks sequentially
	var living_enemies = []
	for sq in defender_squads:
		if sq.count > 0:
			living_enemies.append(sq)
			
	if living_enemies.is_empty():
		_check_battle_over()
		return
		
	var tw = create_tween()
	for i in range(living_enemies.size()):
		var enemy = living_enemies[i]
		tw.tween_interval(0.4)
		tw.tween_callback(func():
			if _check_battle_over():
				return
			# Find living player target
			var target = _get_player_target()
			if not target.is_empty():
				_execute_attack(enemy, target, false)
		)
		
	tw.tween_interval(0.5)
	tw.tween_callback(func():
		if not _check_battle_over():
			_start_next_round()
	)

func _start_automated_battle_sequence():
	if _check_battle_over():
		return
	is_player_turn = true
	lbl_round.text = "⚔ AUTOMATED BATTLE — ROUND %d EXCHANGES..." % round_number
	lbl_round.add_theme_color_override("font_color", Color(1.0, 0.85, 0.3))
	
	var living_attackers = []
	for sq in attacker_squads:
		if sq.count > 0:
			living_attackers.append(sq)
			
	if living_attackers.is_empty():
		_check_battle_over()
		return
		
	var tw = create_tween()
	for i in range(living_attackers.size()):
		var sq = living_attackers[i]
		tw.tween_interval(0.35)
		tw.tween_callback(func():
			if _check_battle_over():
				return
			var target = _get_best_target()
			if not target.is_empty() and sq.count > 0:
				_execute_attack(sq, target, false)
		)
		
	tw.tween_interval(0.4)
	tw.tween_callback(func():
		if not _check_battle_over():
			_start_enemy_turn()
	)

func _get_player_target() -> Dictionary:
	for sq in attacker_squads:
		if sq.count > 0:
			return sq
	return {}

func _start_next_round():
	round_number += 1
	is_player_turn = true
	lbl_round.text = "⚔ ROUND %d" % round_number
	lbl_round.add_theme_color_override("font_color", Color(1.0, 0.95, 0.85))
	
	# Reset actions
	for sq in attacker_squads:
		sq.acted = false
		sq.defending = false
	for sq in defender_squads:
		sq.acted = false
		sq.defending = false
		
	_select_first_available_unit()
	_start_automated_battle_sequence()

func _check_battle_over() -> bool:
	var att_living = 0
	for sq in attacker_squads:
		if sq.count > 0:
			att_living += sq.count
			
	var def_living = 0
	for sq in defender_squads:
		if sq.count > 0:
			def_living += sq.count
			
	if def_living <= 0:
		_finish_combat(true)
		return true
	elif att_living <= 0:
		_finish_combat(false)
		return true
	return false

func _on_autoresolve_pressed():
	# Skip directly to battle report via calculation
	var max_rounds = 10
	while max_rounds > 0:
		max_rounds -= 1
		# Attacker strikes
		for att in attacker_squads:
			var target = _get_best_target()
			if not target.is_empty() and att.count > 0:
				var dmg = _estimate_damage(att, target)
				target.count = max(0, target.count - dmg)
		# Defender strikes
		for def in defender_squads:
			var target = _get_player_target()
			if not target.is_empty() and def.count > 0:
				var dmg = _estimate_damage(def, target)
				target.count = max(0, target.count - dmg)
		if _check_battle_over():
			return
	_finish_combat(true)

func _on_retreat_pressed():
	if is_busy:
		return
	_play_sound("horn")
	_finish_combat(false, true)

func _finish_combat(victory: bool, retreated: bool = false):
	is_busy = true
	result_modal.visible = true
	
	var total_att_lost = 0
	var att_living = 0
	for sq in attacker_squads:
		total_att_lost += (sq.max_count - sq.count)
		if sq.count > 0:
			att_living += sq.count
		
	var total_def_lost = 0
	var def_living = 0
	for sq in defender_squads:
		total_def_lost += (sq.max_count - sq.count)
		if sq.count > 0:
			def_living += sq.count
		
	var gm = _get_game_manager()
	var def_name = gm.provinces[defender_pid].name if gm and gm.provinces.has(defender_pid) else "Territory"
	
	var am = _get_audio_manager()
	if victory:
		if am: am.play_victory()
		lbl_result_title.text = "👑 VICTORY AT %s!" % def_name.to_upper()
		lbl_result_title.add_theme_color_override("font_color", Color(0.85, 0.65, 0.13)) # Bronze Gold
		var narrative = "Strategic Report: Our mobile composite bowmen and shock cavalry breached the defensive lines of %s. Routed enemy forces have capitulated, and the province now flies our banners!" % def_name
		lbl_result_stats.text = "%s\n\nAttacker (%s): %d casualties | %d surviving\nDefender (%s): %d casualties | %d surviving" % [
			narrative,
			attacker_faction.capitalize(), total_att_lost, att_living,
			defender_faction.capitalize(), total_def_lost, def_living
		]
		btn_result_continue.text = "Claim Province & Return to Campaign"
	elif retreated:
		if am: am.play_horn()
		lbl_result_title.text = "TACTICAL RETREAT"
		lbl_result_title.add_theme_color_override("font_color", Color(0.9, 0.7, 0.4))
		var narrative = "Strategic Report: Orderly withdrawal sounded. Surviving warriors broke engagement and fell back in good order without being encircled."
		lbl_result_stats.text = "%s\n\nAttacker (%s): %d casualties | %d surviving\nDefender (%s): %d casualties | %d surviving" % [
			narrative,
			attacker_faction.capitalize(), total_att_lost, att_living,
			defender_faction.capitalize(), total_def_lost, def_living
		]
		btn_result_continue.text = "Return to Campaign"
	else:
		if am: am.play_defeat()
		lbl_result_title.text = "DEFEAT — ASSAULT REPULSED"
		lbl_result_title.add_theme_color_override("font_color", Color(0.95, 0.3, 0.25))
		var narrative = "Strategic Report: The defensive ramparts and garrison counter-charges blunted our assault on %s. Our surviving forces have fallen back to replenish." % def_name
		lbl_result_stats.text = "%s\n\nAttacker (%s): %d casualties | %d surviving\nDefender (%s): %d casualties | %d surviving" % [
			narrative,
			attacker_faction.capitalize(), total_att_lost, att_living,
			defender_faction.capitalize(), total_def_lost, def_living
		]
		btn_result_continue.text = "Acknowledge Defeat"

func _on_finish_battle_clicked():
	var victory = (lbl_result_title.text.begins_with("👑"))
	var gm = _get_game_manager()
	
	var res = {
		"winner": "attacker" if victory else "defender",
		"attacker_pid": attacker_pid,
		"defender_pid": defender_pid,
	}
	
	if gm:
		# Apply casualty updates back to GameState
		var att_p = gm.provinces[attacker_pid]
		var def_p = gm.provinces[defender_pid]
		
		if victory:
			# Province captured
			def_p.owner = attacker_faction
			# Transfer surviving units
			var surv_units = []
			for sq in attacker_squads:
				if sq.count > 0:
					surv_units.append({"type": sq.type, "count": sq.count})
			def_p.army = {"faction": attacker_faction, "units": surv_units}
			att_p.army = null
			def_p.defense_bonus = max(0, def_p.defense_bonus - 5)
			gm.province_captured.emit(defender_pid, attacker_faction)
		else:
			# Attacker takes casualties or wiped
			var surv_units = []
			for sq in attacker_squads:
				if sq.count > 0:
					surv_units.append({"type": sq.type, "count": sq.count})
			if surv_units.is_empty():
				att_p.army = null
			else:
				att_p.army.units = surv_units
				
	battle_completed.emit(res)
	queue_free()

func _update_top_bar():
	var att_living = 0
	var att_max = 0
	for sq in attacker_squads:
		att_living += sq.count
		att_max += sq.max_count
		
	var def_living = 0
	var def_max = 0
	for sq in defender_squads:
		def_living += sq.count
		def_max += sq.max_count
		
	lbl_attacker_info.text = "ATTACKER: %s (%d)" % [attacker_faction.to_upper(), att_living]
	lbl_defender_info.text = "DEFENDER: %s (%d)" % [defender_faction.to_upper(), def_living]
	
	bar_attacker_str.max_value = att_max
	bar_attacker_str.value = att_living
	bar_defender_str.max_value = def_max
	bar_defender_str.value = def_living

func _play_sound(sfx_name: String):
	var am = _get_audio_manager()
	if am:
		match sfx_name:
			"horn": am.play_war_horn()
			"drum": am.play_war_drum()
			"arrow": am.play_arrow()
			"sword": am.play_sword()
			"shield": am.play_shield()
			"cavalry": am.play_cavalry()

func _get_game_manager():
	if game_manager_ref != null and is_instance_valid(game_manager_ref):
		return game_manager_ref
	if is_inside_tree() and get_tree().root:
		if get_tree().root.has_node("GameManager"):
			return get_tree().root.get_node("GameManager")
	var loop = Engine.get_main_loop() as SceneTree
	if loop and loop.root and loop.root.has_node("GameManager"):
		return loop.root.get_node("GameManager")
	var p = get_parent()
	while p:
		if p.has_node("GameManager"):
			return p.get_node("GameManager")
		p = p.get_parent()
	return null

func _get_audio_manager():
	if audio_manager_ref != null and is_instance_valid(audio_manager_ref):
		return audio_manager_ref
	if is_inside_tree() and get_tree().root:
		if get_tree().root.has_node("AudioManager"):
			return get_tree().root.get_node("AudioManager")
	var loop = Engine.get_main_loop() as SceneTree
	if loop and loop.root and loop.root.has_node("AudioManager"):
		return loop.root.get_node("AudioManager")
	var p = get_parent()
	while p:
		if p.has_node("AudioManager"):
			return p.get_node("AudioManager")
		p = p.get_parent()
	return null
