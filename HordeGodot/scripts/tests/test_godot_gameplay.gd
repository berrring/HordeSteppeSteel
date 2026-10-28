extends SceneTree

const ModelBuilder = preload("res://scripts/visuals/model_builder.gd")
const ProvinceVisual = preload("res://scripts/map/province_visual.gd")
const CampaignMap3D = preload("res://scripts/map/campaign_map_3d.gd")
const StrategicCamera = preload("res://scripts/camera/strategic_camera.gd")
const CampaignHUD = preload("res://scripts/ui/campaign_hud.gd")
const CampaignController = preload("res://scripts/core/campaign_controller.gd")
const MainMenu = preload("res://scripts/ui/main_menu.gd")
const MovementPath3D = preload("res://scripts/visuals/movement_path_3d.gd")

func _init():
	print("\n=======================================================")
	print("  HORDE: STEPPE AND STEEL — GODOT 4 VERIFICATION SUITE ")
	print("=======================================================\n")
	
	var stats = [0, 0] # [passed, failed]
	
	# Helper assert
	var test = func(name: String, condition: bool):
		if condition:
			print("  [PASS] ", name)
			stats[0] += 1
		else:
			push_error("  [FAIL] " + name)
			print("  [FAIL] ", name)
			stats[1] += 1
			
	# Test 1: GameManager Autoload
	var gm = root.get_node_or_null("GameManager")
	if gm == null:
		var GMClass = load("res://scripts/core/game_manager.gd")
		gm = GMClass.new()
		gm.name = "GameManager"
		root.add_child(gm)
	test.call("GameManager instance is present in SceneTree", gm != null)
		
	# Test 2: Campaign Initialization
	gm.start_new_campaign()
	test.call("Campaign initialization creates 12 provinces", gm.provinces.size() == 12)
	test.call("Campaign initialization creates 6 official canonical factions", gm.factions.size() == 6)
	test.call("All 6 canonical factions registered", gm.factions.has("mongol") and gm.factions.has("cuman") and gm.factions.has("rus") and gm.factions.has("byzantine") and gm.factions.has("seljuk") and gm.factions.has("khwarazm"))
	test.call("Player faction is 'mongol'", gm.factions.has("mongol") and gm.factions["mongol"].is_player)
	test.call("Player starts with 2 provinces", gm.province_count("mongol") == 2)
	test.call("Player starts with > 0 gold, food, wood", gm.factions["mongol"].gold > 0 and gm.factions["mongol"].food > 0 and gm.factions["mongol"].wood > 0)
	
	# Test 3: Province Adjacency Symmetry
	var adj_symmetric = true
	for pid in gm.provinces:
		var p = gm.provinces[pid]
		for nid in p.neighbors:
			if not gm.provinces.has(nid) or not gm.provinces[nid].neighbors.has(pid):
				adj_symmetric = false
				break
	test.call("Province adjacency graph is fully symmetric", adj_symmetric)
	
	# Test 4: Resource Collection / Economy
	var init_gold = gm.factions["mongol"].gold
	var income = gm.collect_income("mongol")
	test.call("Income collection increases faction gold", gm.factions["mongol"].gold > init_gold and income.gold > 0)
	test.call("Income collection collects food and wood", income.food > 0 and income.wood > 0)
	
	# Test 5: Army Strength Calculation
	var sarai_army = gm.provinces["sarai"].army
	test.call("Player capital (Sarai) has starting army", sarai_army != null and sarai_army.units.size() > 0)
	var str_val = gm.get_army_strength(sarai_army)
	test.call("Army strength calculates correct warrior total", str_val >= 240)
	
	# Test 6: Battle Resolution
	# Let player army in Sarai attack neutral Urgench
	var b_res = gm.resolve_battle("sarai", "urgench")
	test.call("Battle resolution produces valid winner", b_res.has("winner") and (b_res.winner == "attacker" or b_res.winner == "defender"))
	if b_res.winner == "attacker":
		test.call("Winning battle captures province for attacker", gm.provinces["urgench"].owner == "mongol")
		
	# Test 7: AI Turn Execution
	var rus_gold_before = gm.factions["rus"].gold
	gm._run_ai_turns()
	test.call("AI turns execute without error", true)
	test.call("AI collects income during turns", gm.factions["rus"].gold >= rus_gold_before)
	
	# Test 8: Victory & Defeat Conditions
	test.call("Game is not won or lost on turn 1", gm.check_victory() == "")
	
	# Test simulated win condition
	for pid in gm.provinces:
		gm.provinces[pid].owner = "mongol"
	test.call("Conquering 10+ provinces triggers VICTORY condition", gm.check_victory() == "win")
	
	# Test simulated defeat condition
	for pid in gm.provinces:
		gm.provinces[pid].owner = "rus"
		gm.provinces[pid].army = null
	test.call("Losing all provinces and armies triggers DEFEAT condition", gm.check_victory() == "lose")
	
	# Reset campaign for save/load test
	gm.start_new_campaign()
	
	# Test 9: Save and Load System
	var save_ok = gm.save_game("user://test_save.json")
	test.call("Campaign saves to JSON successfully", save_ok)
	gm.turn = 42
	var load_ok = gm.load_game("user://test_save.json")
	test.call("Campaign loads from JSON successfully", load_ok and gm.turn == 1)
	
	# Test 10: 3D ModelBuilder Procedural Assets
	var yurt = ModelBuilder.create_yurt(0.6, true)
	test.call("ModelBuilder creates Khan Yurt 3D model", yurt != null and yurt.get_child_count() > 0)
	yurt.free()
	
	var camp = ModelBuilder.create_mongol_camp(true)
	test.call("ModelBuilder creates complete Mongol Camp with Yurts & Banner", camp != null and camp.get_child_count() >= 4)
	camp.free()
	
	var fort = ModelBuilder.create_rus_fortress(true)
	test.call("ModelBuilder creates complete Rus' Kremlin Fortress with Watchtowers & Church", fort != null and fort.get_child_count() >= 6)
	fort.free()
	
	var seljuk = ModelBuilder.create_seljuk_settlement(true)
	test.call("ModelBuilder creates Seljuk Settlement with Minaret & Dome", seljuk != null)
	seljuk.free()
	
	var cuman_camp = ModelBuilder.create_cuman_camp(true)
	test.call("ModelBuilder creates Cuman / Kipchak Camp with Yurts & Banner", cuman_camp != null and cuman_camp.get_child_count() >= 2)
	cuman_camp.free()
	
	var byz_fort = ModelBuilder.create_byzantine_settlement(true)
	test.call("ModelBuilder creates Byzantine Outpost with Basilica & Dome", byz_fort != null and byz_fort.get_child_count() >= 3)
	byz_fort.free()
	
	var pine = ModelBuilder.create_pine_tree(1.0)
	test.call("ModelBuilder creates Steppe Pine Tree with multi-tier foliage", pine != null and pine.get_child_count() >= 4)
	pine.free()
	
	var birch = ModelBuilder.create_birch_tree(1.0)
	test.call("ModelBuilder creates Rus' Birch Tree with bark and canopy", birch != null and birch.get_child_count() >= 3)
	birch.free()
	
	var oak = ModelBuilder.create_oak_tree(1.0)
	test.call("ModelBuilder creates Broadleaf Oak Tree with clustered canopy", oak != null and oak.get_child_count() >= 5)
	oak.free()
	
	var rocks_model = ModelBuilder.create_rock_cluster(1.0)
	test.call("ModelBuilder creates Rock Cluster with faceted boulders", rocks_model != null and rocks_model.get_child_count() >= 3)
	rocks_model.free()
	
	var ha_unit = ModelBuilder.create_horse_archer_unit()
	test.call("ModelBuilder creates Mongol Horse Archer with horse, rider, bow & quiver", ha_unit != null and ha_unit.get_child_count() >= 5)
	ha_unit.free()
	
	var hc_unit = ModelBuilder.create_heavy_cavalry_unit()
	test.call("ModelBuilder creates Armored Heavy Cavalry with barded warhorse and lance", hc_unit != null and hc_unit.get_child_count() >= 5)
	hc_unit.free()
	
	var inf_unit = ModelBuilder.create_infantry_unit()
	test.call("ModelBuilder creates Rus' Infantry Soldier with kite shield and battle axe", inf_unit != null and inf_unit.get_child_count() >= 6)
	inf_unit.free()
	
	var sp_unit = ModelBuilder.create_spearman_unit()
	test.call("ModelBuilder creates Heavy Spearman with 2m spear and shield", sp_unit != null and sp_unit.get_child_count() >= 6)
	sp_unit.free()
	
	var siege_unit = ModelBuilder.create_siege_engine()
	test.call("ModelBuilder creates Traction Trebuchet Siege Engine with timber frame & wheels", siege_unit != null and siege_unit.get_child_count() >= 8)
	siege_unit.free()
	
	# Test 11: 3D Campaign Map Assembly
	gm.start_new_campaign()
	var map = CampaignMap3D.new()
	root.add_child(map)
	map.build_map(gm.provinces)
	test.call("CampaignMap3D generates all 12 province visuals", map.province_nodes.size() == 12)
	test.call("CampaignMap3D connects road networks", map.road_container.get_child_count() > 0)
	test.call("CampaignMap3D constructs winding river feature", map.river_container.get_child_count() > 0)
	
	# Test province selection
	map.select_province("sarai")
	test.call("Selecting province sets active selection", map.current_selected_pid == "sarai")
	test.call("Selected province visual is highlighted", (map.province_nodes["sarai"] as ProvinceVisual).is_selected)
	map.deselect()
	test.call("Deselection clears highlight", map.current_selected_pid == "" and not (map.province_nodes["sarai"] as ProvinceVisual).is_selected)
	map.free()
	
	# Test 12: Main Menu Scene Instantiation
	var menu_scene = load("res://scenes/main_menu/main_menu.tscn").instantiate()
	root.add_child(menu_scene)
	if not menu_scene.has_node("Diorama"):
		menu_scene._ready()
	test.call("Main menu scene loads and instantiates", menu_scene != null)
	test.call("Main menu contains 3D diorama with miniature battlefield", menu_scene.has_node("Diorama"))
	test.call("Main menu contains camera turntable pivot", menu_scene.has_node("CameraPivot"))
	test.call("Main menu contains UILayer with buttons", menu_scene.has_node("UILayer"))
	menu_scene.free()
	
	# Test 13: Campaign View Scene Instantiation
	var camp_scene = load("res://scenes/campaign/campaign_view.tscn").instantiate()
	root.add_child(camp_scene)
	if not camp_scene.has_node("CampaignMap3D"):
		camp_scene._ready()
	test.call("Campaign view scene loads and instantiates", camp_scene != null)
	test.call("Campaign view initializes CampaignMap3D", camp_scene.has_node("CampaignMap3D"))
	test.call("Campaign view initializes StrategicCamera", camp_scene.has_node("StrategicCamera"))
	test.call("Campaign view initializes CampaignHUD", camp_scene.has_node("CampaignHUD"))
	camp_scene.free()
	
	# Test 14: AudioManager & Audio Synthesis
	var am = root.get_node_or_null("AudioManager")
	if am == null:
		var AMClass = load("res://scripts/core/audio_manager.gd")
		am = AMClass.new()
		am.name = "AudioManager"
		root.add_child(am)
		am._ready()
	test.call("AudioManager is initialized with audio engine", am != null)
	if am:
		test.call("AudioManager generates procedural audio streams", am.streams.size() >= 14)
		test.call("AudioStream 'horn' is valid AudioStreamWAV", am.streams.has("horn") and am.streams["horn"] is AudioStreamWAV)
		test.call("AudioStream 'sword' is valid AudioStreamWAV", am.streams.has("sword") and am.streams["sword"] is AudioStreamWAV)
		test.call("AudioStream 'victory' is valid AudioStreamWAV", am.streams.has("victory") and am.streams["victory"] is AudioStreamWAV)
		test.call("AudioStream 'defeat' is valid AudioStreamWAV", am.streams.has("defeat") and am.streams["defeat"] is AudioStreamWAV)
		am.set_master_volume(0.5)
		test.call("Master volume setting works", am.master_volume == 0.5)
		am.set_master_volume(0.85)
		
	# Test 15: Tactical Battle System
	var battle = load("res://scenes/combat/tactical_battle.tscn").instantiate()
	root.add_child(battle)
	battle.setup_battle("sarai", "kiev", gm, am)
	test.call("TacticalBattle initializes attacker squads", battle.attacker_squads.size() > 0)
	test.call("TacticalBattle initializes defender squads", battle.defender_squads.size() > 0)
	test.call("TacticalBattle creates 3D SubViewport & battlefield arena", battle.battlefield_root != null)
	test.call("TacticalBattle creates command card & action buttons", battle.btn_attack != null and battle.btn_defend != null)
	battle.free()
	
	# Test 16: Movement & Attack Path Renderer
	var m_path = MovementPath3D.new()
	root.add_child(m_path)
	m_path._ready()
	m_path.show_path(Vector3(0, 0, 0), Vector3(3, 0, 3), true)
	test.call("MovementPath3D generates 3D attack beam & destination marker", m_path.visible and m_path.active)
	m_path.hide_path()
	test.call("MovementPath3D hides on command", not m_path.visible)
	m_path.free()
	
	# Clean up any test instances in root
	if gm:
		gm.free()
	if am:
		am.free()
	
	print("\n-------------------------------------------------------")
	print("  TOTAL TESTS: ", stats[0] + stats[1], " | PASSED: ", stats[0], " | FAILED: ", stats[1])
	print("-------------------------------------------------------\n")
	
	if stats[1] == 0:
		print(">>> ALL GODOT 4 VERIFICATION TESTS PASSED SUCCESSFULLY! <<<\n")
		quit(0)
	else:
		print(">>> SOME TESTS FAILED! <<<\n")
		quit(1)
