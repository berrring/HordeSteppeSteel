class_name CampaignController
extends Node3D

const Palette = preload("res://scripts/core/palette.gd")
const CampaignMap3D = preload("res://scripts/map/campaign_map_3d.gd")
const StrategicCamera = preload("res://scripts/camera/strategic_camera.gd")
const CampaignHUD = preload("res://scripts/ui/campaign_hud.gd")
const TacticalBattle = preload("res://scripts/combat/tactical_battle.gd")
const FXManager = preload("res://scripts/visuals/fx_manager.gd")

var map_3d: CampaignMap3D
var camera_rig: StrategicCamera
var hud: CampaignHUD
var sun_light: DirectionalLight3D
var commands_busy: bool = false

var env_node: WorldEnvironment

func _ready():
	_setup_environment()
	
	map_3d = CampaignMap3D.new()
	map_3d.name = "CampaignMap3D"
	add_child(map_3d)
	
	camera_rig = StrategicCamera.new()
	camera_rig.name = "StrategicCamera"
	add_child(camera_rig)
	
	hud = CampaignHUD.new()
	hud.name = "CampaignHUD"
	add_child(hud)
	
	# Connect signals
	map_3d.province_selected.connect(_on_province_selected)
	map_3d.attack_target_selected.connect(_on_attack_target_selected)
	
	hud.end_turn_requested.connect(_on_end_turn)
	hud.recruit_requested.connect(_on_recruit)
	hud.construct_requested.connect(_on_construct)
	hud.attack_requested.connect(_on_attack)
	hud.return_to_menu_requested.connect(_on_return_to_menu)
	
	# Ensure game manager is initialized
	var gm = _get_game_manager()
	if gm != null:
		if gm.provinces.is_empty():
			gm.start_new_campaign()
		gm.game_over.connect(_on_game_over)
		gm.campaign_loaded.connect(_on_campaign_loaded)
		map_3d.build_map(gm.provinces)
		hud.update_resources()
		
		# Focus camera on player capital or first owned province
		var cap_pid = ""
		for pid in gm.provinces:
			if gm.provinces[pid].owner == gm.current_faction:
				if gm.provinces[pid].is_capital:
					cap_pid = pid
					break
				elif cap_pid == "":
					cap_pid = pid
		if cap_pid != "" and gm.provinces.has(cap_pid):
			var cap_p = gm.provinces[cap_pid]
			camera_rig.focus_on(Vector3(cap_p.x, 0, cap_p.z), 13.0)

		if gm.current_state in [gm.GameState.VICTORY, gm.GameState.DEFEAT]:
			hud.show_game_over(gm.current_state == gm.GameState.VICTORY)

func _process(_delta: float) -> void:
	if not is_instance_valid(hud) or not is_instance_valid(map_3d):
		return
	var gm = _get_game_manager()
	var blocked: bool = commands_busy or hud.has_open_modal() or gm == null or gm.current_state != gm.GameState.CAMPAIGN
	map_3d.orders_locked = blocked
	if camera_rig:
		camera_rig.set_process(not blocked)
		camera_rig.set_process_unhandled_input(not blocked)
		if blocked:
			camera_rig.is_dragging = false

func _setup_environment():
	# Directional Sun (Crisp Warm Golden-Hour Lighting)
	sun_light = DirectionalLight3D.new()
	sun_light.name = "SunLight"
	sun_light.light_color = Color(1.0, 0.96, 0.88)
	sun_light.light_energy = 1.45
	sun_light.shadow_enabled = true
	sun_light.shadow_blur = 1.2
	sun_light.directional_shadow_max_distance = 65.0
	sun_light.rotation_degrees = Vector3(-45, 42, 0)
	add_child(sun_light)
	
	# World Environment with Gamified Polytopia-inspired Atmosphere
	env_node = WorldEnvironment.new()
	env_node.name = "WorldEnvironment"
	var env = Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.18, 0.22, 0.28) # Deep twilight background for crisp tile contrast
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.52, 0.48, 0.44)
	env.ambient_light_energy = 0.95
	
	# Atmospheric depth fog
	env.fog_enabled = true
	env.fog_light_color = Color(0.32, 0.38, 0.45)
	env.fog_density = 0.007
	env.fog_aerial_perspective = 0.35
	
	# AAA-grade Tonemapping & Subtle Bloom
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	env.tonemap_exposure = 1.15
	env.glow_enabled = true
	env.glow_intensity = 0.35
	env.glow_bloom = 0.10
	env.glow_blend_mode = Environment.GLOW_BLEND_MODE_SOFTLIGHT
	
	env_node.environment = env
	add_child(env_node)

func _update_act_atmosphere(turn: int, p_count: int):
	if sun_light == null or env_node == null or env_node.environment == null:
		return
	var env = env_node.environment
	if p_count >= 7 or turn >= 16:
		# Act III: Resolution — Deep dramatic lighting, steel-blue shadows, bronze-gold highlights
		sun_light.light_color = Palette.BRONZE_GOLD.lightened(0.2)
		sun_light.light_energy = 1.45
		env.ambient_light_color = Palette.DEEP_STEEL_BLUE.lightened(0.2)
		env.fog_light_color = Palette.DEEP_STEEL_BLUE.lightened(0.4)
		env.fog_density = 0.014
	elif p_count >= 4 or turn >= 6:
		# Act II: Confrontation — Late summer into autumn crisp fog
		sun_light.light_color = Color(0.96, 0.88, 0.76)
		sun_light.light_energy = 1.25
		env.ambient_light_color = Color(0.44, 0.45, 0.48)
		env.fog_light_color = Color(0.60, 0.62, 0.65)
		env.fog_density = 0.011
	else:
		# Act I: Setup — Warm spring steppe sunshine
		sun_light.light_color = Color(1.0, 0.95, 0.86)
		sun_light.light_energy = 1.3
		env.ambient_light_color = Color(0.48, 0.44, 0.40)
		env.fog_light_color = Color(0.55, 0.50, 0.45)
		env.fog_density = 0.008

func _on_province_selected(pid: String):
	if commands_busy:
		return
	if pid == "":
		hud.deselect_province()
	else:
		hud.select_province(pid)

func _on_attack_target_selected(attacker_pid: String, defender_pid: String):
	if not commands_busy:
		hud.prompt_attack(attacker_pid, defender_pid)

func _set_commands_busy(value: bool) -> void:
	commands_busy = value
	map_3d.orders_locked = value
	hud.commands_locked = value
	hud.update_actions_state()

func _on_attack(attacker_pid: String, defender_pid: String):
	var gm = _get_game_manager()
	if gm == null or commands_busy or hud.has_open_modal():
		return
	var validation: Dictionary = gm.validate_army_order(attacker_pid, defender_pid)
	if not validation.allowed:
		hud.log_event(validation.reason)
		_play_audio("error")
		return
	if gm.provinces[defender_pid].owner == gm.current_faction:
		var moved: Dictionary = gm.move_army(attacker_pid, defender_pid)
		if not moved.allowed:
			hud.log_event(moved.reason)
			return
		_set_commands_busy(true)
		map_3d.animate_army_march(attacker_pid, defender_pid, func():
			_set_commands_busy(false)
			map_3d.refresh_all(gm.provinces)
			map_3d.select_province(defender_pid)
			hud.update_resources()
			hud.log_event("Army marched to %s. Movement left: %d." % [gm.provinces[defender_pid].name, gm.moves_left(gm.provinces[defender_pid].army)])
		)
		return
	var result: Dictionary = gm.begin_battle(attacker_pid, defender_pid)
	if result.is_empty():
		return
	_set_commands_busy(true)
	map_3d.animate_army_march(attacker_pid, defender_pid, func():
		hud.visible = false
		camera_rig.set_process(false)
		camera_rig.set_process_unhandled_input(false)
		camera_rig.is_dragging = false
		var battle = TacticalBattle.new()
		battle.name = "ActiveBattle"
		add_child(battle)
		battle.battle_completed.connect(_on_tactical_battle_completed)
		battle.setup_battle(attacker_pid, defender_pid, gm)
	)

func _on_tactical_battle_completed(result: Dictionary):
	_set_commands_busy(false)
	hud.visible = true
	camera_rig.set_process(true)
	camera_rig.set_process_unhandled_input(true)
	var gm = _get_game_manager()
	if gm == null:
		return
		
	map_3d.refresh_all(gm.provinces)
	hud.update_resources()
	map_3d.deselect()
	
	var def_pid = result.defender_pid
	if gm.provinces.has(def_pid):
		var p = gm.provinces[def_pid]
		if result.winner == "attacker":
			FXManager.spawn_floating_text(self, Vector3(p.x, 0, p.z), "CAPTURED!", Color(1.0, 0.88, 0.3))
			map_3d.select_province(def_pid)
			var faction_name = gm.factions[gm.current_faction].name if gm.factions.has(gm.current_faction) else "Our Realm"
			hud.log_event("Victory! Province of %s swearing fealty to the %s." % [p.name, faction_name])
		else:
			hud.log_event("Assault on %s was repulsed." % p.name)
			
	gm.evaluate_campaign()

func _on_recruit(unit_type: String):
	var gm = _get_game_manager()
	if gm == null or commands_busy or hud.has_open_modal():
		return
	var result: Dictionary = gm.recruit_units(hud.selected_pid, unit_type)
	if not result.allowed:
		_play_audio("error")
		hud.log_event(result.reason)
		return
	_play_audio("recruit")
	_refresh_selected_province()
	hud.log_event(result.reason)

func _on_construct(building_type: String):
	var gm = _get_game_manager()
	if gm == null or commands_busy or hud.has_open_modal():
		return
	var result: Dictionary = gm.construct_building(hud.selected_pid, building_type)
	if not result.allowed:
		_play_audio("error")
		hud.log_event(result.reason)
		return
	_play_audio("build")
	_refresh_selected_province()
	hud.log_event(result.reason)

func _refresh_selected_province() -> void:
	var gm = _get_game_manager()
	map_3d.refresh_all(gm.provinces)
	hud.update_resources()
	if hud.selected_pid != "":
		hud.select_province(hud.selected_pid)

func _on_campaign_loaded() -> void:
	var gm = _get_game_manager()
	map_3d.build_map(gm.provinces)
	map_3d.deselect()
	hud.hide_modals()
	hud.update_resources()
	_update_act_atmosphere(gm.turn, gm.province_count(gm.current_faction))
	for p in gm.provinces.values():
		if p.owner == gm.current_faction:
			camera_rig.focus_on(Vector3(p.x, 0, p.z))
			break

func _on_end_turn():
	var gm = _get_game_manager()
	if gm == null or commands_busy or hud.has_open_modal():
		return
	_set_commands_busy(true)
	_play_audio("drum")
	gm.end_turn()
	_set_commands_busy(false)
	_refresh_selected_province()
	_update_act_atmosphere(gm.turn, gm.province_count(gm.current_faction))
	var summary: String = "Turn %d — %s. Income collected." % [gm.turn, gm.season_name()]
	if not gm.campaign_log.is_empty():
		summary += " " + " ".join(gm.campaign_log)
	hud.log_event(summary)

func _play_audio(type: String):
	var loop = Engine.get_main_loop() as SceneTree
	if loop and loop.root and loop.root.has_node("AudioManager"):
		var am = loop.root.get_node("AudioManager")
		match type:
			"click": am.play_click()
			"recruit": am.play_recruit()
			"build": am.play_build()
			"drum": am.play_war_drum()
			"horn": am.play_war_horn()
			"error": am.play_error()

func _on_game_over(is_victory: bool):
	hud.show_game_over(is_victory)

func _on_return_to_menu():
	if commands_busy:
		return
	get_tree().change_scene_to_file("res://scenes/main_menu/main_menu.tscn")

func _get_game_manager():
	var root = Engine.get_main_loop().root if Engine.get_main_loop() else null
	if root and root.has_node("GameManager"):
		return root.get_node("GameManager")
	return null
