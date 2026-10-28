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

func _setup_environment():
	# Directional Sun
	sun_light = DirectionalLight3D.new()
	sun_light.name = "SunLight"
	sun_light.light_color = Color(1.0, 0.95, 0.86)
	sun_light.light_energy = 1.3
	sun_light.shadow_enabled = true
	sun_light.rotation_degrees = Vector3(-48, 38, 0)
	add_child(sun_light)
	
	# World Environment with Atmosphere
	env_node = WorldEnvironment.new()
	env_node.name = "WorldEnvironment"
	var env = Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.14, 0.12, 0.10)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.48, 0.44, 0.40)
	env.ambient_light_energy = 0.85
	
	# Atmospheric fog for depth
	env.fog_enabled = true
	env.fog_light_color = Color(0.55, 0.50, 0.45)
	env.fog_density = 0.008
	env.fog_aerial_perspective = 0.4
	
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
	if pid == "":
		hud.deselect_province()
	else:
		hud.select_province(pid)

func _on_attack_target_selected(attacker_pid: String, defender_pid: String):
	hud.prompt_attack(attacker_pid, defender_pid)

func _on_attack(attacker_pid: String, defender_pid: String):
	var gm = _get_game_manager()
	if gm == null:
		return
		
	# First animate army marching to the target border
	map_3d.animate_army_march(attacker_pid, defender_pid, func():
		hud.visible = false
		var battle = TacticalBattle.new()
		battle.name = "ActiveBattle"
		add_child(battle)
		battle.setup_battle(attacker_pid, defender_pid)
		battle.battle_completed.connect(func(res: Dictionary):
			hud.visible = true
			_on_tactical_battle_completed(res)
		)
	)

func _on_tactical_battle_completed(result: Dictionary):
	var gm = _get_game_manager()
	if gm == null:
		return
		
	map_3d.refresh_all(gm.provinces)
	hud.update_resources()
	hud.deselect_province()
	
	var def_pid = result.defender_pid
	if gm.provinces.has(def_pid):
		var p = gm.provinces[def_pid]
		if result.winner == "attacker":
			FXManager.spawn_floating_text(self, Vector3(p.x, 0, p.z), "CAPTURED!", Color(1.0, 0.88, 0.3))
			hud.select_province(def_pid)
			var faction_name = gm.factions[gm.current_faction].name if gm.factions.has(gm.current_faction) else "Our Realm"
			hud.log_event("Victory! Province of %s swearing fealty to the %s." % [p.name, faction_name])
		else:
			hud.log_event("Assault on %s was repulsed." % p.name)
			
	# Check overall campaign victory
	var vic = gm.check_victory()
	if vic == "win":
		_on_game_over(true)
	elif vic == "lose":
		_on_game_over(false)

func _on_recruit(unit_type: String):
	var gm = _get_game_manager()
	if gm == null or hud.selected_pid == "":
		return
		
	var pid = hud.selected_pid
	var p = gm.provinces.get(pid, null)
	if p == null or p.owner != gm.current_faction:
		return
		
	var stats = gm.get_unit_stats(unit_type)
	var player = gm.get_player_faction()
	var cost_gold = stats.get("cost_gold", 100)
	var cost_food = stats.get("cost_food", 30)
	
	if player.gold < cost_gold or player.food < cost_food:
		_play_audio("error")
		hud.log_event("Not enough resources to recruit %s (Needs %dg, %df)!" % [unit_type.replace("_", " "), cost_gold, cost_food])
		return
		
	player.gold -= cost_gold
	player.food -= cost_food
	_play_audio("recruit")
	
	if p.army == null:
		p.army = {"faction": gm.current_faction, "units": []}
		
	# Find existing unit group or add new
	var found = false
	for u in p.army.units:
		if u.type == unit_type:
			u.count += 50
			found = true
			break
	if not found:
		p.army.units.append({"type": unit_type, "count": 50})
		
	FXManager.spawn_floating_text(self, Vector3(p.x, 0, p.z), "+50 Warriors", Color(0.9, 0.85, 0.3))
	hud.log_event("Recruited 50 %s in %s!" % [unit_type.replace("_", " "), p.name])
	map_3d.refresh_all(gm.provinces)
	hud.update_resources()
	hud.select_province(pid)

func _on_construct(building_type: String):
	var gm = _get_game_manager()
	if gm == null or hud.selected_pid == "":
		return
		
	var pid = hud.selected_pid
	var p = gm.provinces.get(pid, null)
	if p == null or p.owner != gm.current_faction:
		return
		
	var player = gm.get_player_faction()
	
	match building_type:
		"town_center":
			if player.wood < 120:
				_play_audio("error")
				hud.log_event("Need 120 wood for Town Center!")
				return
			player.wood -= 120
			p.income_gold += 40
			p.income_food += 20
			FXManager.spawn_floating_text(self, Vector3(p.x, 0, p.z), "+40g +20f", Palette.BRONZE_GOLD)
			hud.log_event("Developed Town Center in %s (+40 Gold, +20 Food)!" % p.name)
		"barracks":
			if player.wood < 100:
				_play_audio("error")
				hud.log_event("Need 100 wood for Barracks!")
				return
			player.wood -= 100
			p.defense_bonus += 15
			FXManager.spawn_floating_text(self, Vector3(p.x, 0, p.z), "+15 Defense", Color(0.7, 0.85, 1.0))
			hud.log_event("Constructed Barracks in %s (+15 Defense)!" % p.name)
		"stables":
			if player.wood < 80:
				_play_audio("error")
				hud.log_event("Need 80 wood for Stables!")
				return
			player.wood -= 80
			p.income_food += 40
			FXManager.spawn_floating_text(self, Vector3(p.x, 0, p.z), "+40 Food", Color(0.65, 0.95, 0.55))
			hud.log_event("Erected Stables in %s (+40 Food/turn)!" % p.name)
		"fortification":
			if player.wood < 100:
				_play_audio("error")
				hud.log_event("Need 100 wood for Fortifications!")
				return
			player.wood -= 100
			p.defense_bonus += 20
			FXManager.spawn_floating_text(self, Vector3(p.x, 0, p.z), "+20 Defense", Color(0.7, 0.85, 1.0))
			hud.log_event("Built Watchtowers & Fortifications in %s (+20 Defense)!" % p.name)
		"palisade":
			if player.wood < 80:
				_play_audio("error")
				hud.log_event("Need 80 wood for Palisade!")
				return
			player.wood -= 80
			p.defense_bonus += 10
			FXManager.spawn_floating_text(self, Vector3(p.x, 0, p.z), "+10 Defense", Color(0.7, 0.85, 1.0))
			hud.log_event("Built Palisade in %s (+10 Defense)!" % p.name)
		"pasture":
			if player.wood < 80:
				_play_audio("error")
				hud.log_event("Need 80 wood for Pasture!")
				return
			player.wood -= 80
			p.income_food += 40
			FXManager.spawn_floating_text(self, Vector3(p.x, 0, p.z), "+40 Food", Color(0.65, 0.95, 0.55))
			hud.log_event("Constructed Pasture in %s (+40 Food/turn)!" % p.name)
		"market":
			if player.wood < 120:
				_play_audio("error")
				hud.log_event("Need 120 wood for Market!")
				return
			player.wood -= 120
			p.income_gold += 50
			FXManager.spawn_floating_text(self, Vector3(p.x, 0, p.z), "+50 Gold", Color(1.0, 0.88, 0.3))
			hud.log_event("Established Market in %s (+50 Gold/turn)!" % p.name)
			
	_play_audio("build")
	p.buildings.append(building_type)
	hud.update_resources()
	hud.select_province(pid)

func _on_end_turn():
	var gm = _get_game_manager()
	if gm == null:
		return
		
	_play_audio("drum")
	gm.end_turn()
	map_3d.refresh_all(gm.provinces)
	hud.update_resources()
	_update_act_atmosphere(gm.turn, gm.province_count(gm.current_faction))
	hud.log_event("Turn %d began. Income collected across your territories." % gm.turn)
	
	# Re-select current if still valid
	if hud.selected_pid != "":
		hud.select_province(hud.selected_pid)

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
	get_tree().change_scene_to_file("res://scenes/main_menu/main_menu.tscn")

func _get_game_manager():
	var root = Engine.get_main_loop().root if Engine.get_main_loop() else null
	if root and root.has_node("GameManager"):
		return root.get_node("GameManager")
	return null
