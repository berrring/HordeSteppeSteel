extends SceneTree

const EconomyManager = preload("res://scripts/core/economy_manager.gd")
const CampaignHUD = preload("res://scripts/ui/campaign_hud.gd")

func _init():
	print("\n=======================================================")
	print("  HORDE: STEPPE AND STEEL — ECONOMY VALIDATION TESTS  ")
	print("=======================================================\n")
	
	var stats = [0, 0] # [passed, failed]
	
	var test = func(name: String, condition: bool):
		if condition:
			print("  [PASS] ", name)
			stats[0] += 1
		else:
			push_error("  [FAIL] " + name)
			print("  [FAIL] ", name)
			stats[1] += 1

	# Test 1: EconomyManager instance & statelessness
	var em = EconomyManager.new()
	test.call("EconomyManager is RefCounted service", em is RefCounted)
	
	# Test 2: Verified Building Data (Source of truth: campaign_controller.gd:238-303)
	var all_b = EconomyManager.get_all_buildings()
	test.call("All 7 canonical buildings registered in EconomyManager", all_b.size() == 7 and all_b.has("town_center") and all_b.has("barracks") and all_b.has("stables") and all_b.has("fortification") and all_b.has("palisade") and all_b.has("pasture") and all_b.has("market"))
	test.call("Building wood costs match authoritative specification",
		all_b["town_center"].wood_cost == 120 and
		all_b["barracks"].wood_cost == 100 and
		all_b["stables"].wood_cost == 80 and
		all_b["fortification"].wood_cost == 100 and
		all_b["palisade"].wood_cost == 80 and
		all_b["pasture"].wood_cost == 80 and
		all_b["market"].wood_cost == 120
	)
	
	# Test 3: Building eligibility when resources and ownership are valid
	var test_prov = {
		"id": "sarai",
		"name": "Sarai Steppe",
		"owner": "mongol",
		"buildings": []
	}
	var test_faction = {
		"id": "mongol",
		"gold": 500,
		"food": 300,
		"wood": 200
	}
	var res_valid = EconomyManager.can_build(test_prov, test_faction, "town_center")
	test.call("can_build permits construction with sufficient wood and ownership", res_valid.allowed == true and res_valid.reason == "Ready to construct")
	
	# Test 4: Insufficient wood rejection
	var test_poor_faction = {
		"id": "mongol",
		"gold": 500,
		"food": 300,
		"wood": 50 # Needs 120 for town_center
	}
	var res_insufficient = EconomyManager.can_build(test_prov, test_poor_faction, "town_center")
	test.call("can_build rejects construction when faction wood is insufficient", res_insufficient.allowed == false and "Insufficient wood" in res_insufficient.reason)
	
	# Test 5: Strict uniqueness validation (duplicate building rejection)
	var test_built_prov = {
		"id": "sarai",
		"name": "Sarai Steppe",
		"owner": "mongol",
		"buildings": ["town_center"]
	}
	var res_duplicate = EconomyManager.can_build(test_built_prov, test_faction, "town_center")
	test.call("can_build strictly enforces uniqueness and rejects duplicate construction", res_duplicate.allowed == false and "already constructed" in res_duplicate.reason)
	
	# Test 6: Foreign territory rejection
	var test_foreign_prov = {
		"id": "sarkel",
		"name": "Sarkel Redoubt",
		"owner": "rus",
		"buildings": []
	}
	var res_foreign = EconomyManager.can_build(test_foreign_prov, test_faction, "town_center")
	test.call("can_build rejects construction in unowned or enemy province", res_foreign.allowed == false and "not controlled" in res_foreign.reason)
	
	# Test 7: Unknown building rejection
	var res_unknown = EconomyManager.can_build(test_prov, test_faction, "space_station")
	test.call("can_build rejects non-existent building types", res_unknown.allowed == false and "Unknown building" in res_unknown.reason)
	
	# Test 8: Recruitment affordability validation
	var unit_stats = {"cost_gold": 150, "cost_food": 50}
	var res_rec_valid = EconomyManager.can_recruit(test_faction, unit_stats)
	test.call("can_recruit permits recruitment when gold and food are available", res_rec_valid.allowed == true)
	
	# Test 9: Insufficient gold recruitment rejection
	var low_gold_faction = {"id": "mongol", "gold": 100, "food": 300}
	var res_rec_low_gold = EconomyManager.can_recruit(low_gold_faction, unit_stats)
	test.call("can_recruit rejects recruitment when gold is insufficient", res_rec_low_gold.allowed == false and "Insufficient gold" in res_rec_low_gold.reason)
	
	# Test 10: Insufficient food recruitment rejection
	var low_food_faction = {"id": "mongol", "gold": 500, "food": 20}
	var res_rec_low_food = EconomyManager.can_recruit(low_food_faction, unit_stats)
	test.call("can_recruit rejects recruitment when food is insufficient", res_rec_low_food.allowed == false and "Insufficient food" in res_rec_low_food.reason)
	
	# Test 11: Statelessness verification (no inputs mutated)
	test.call("can_build does not mutate province buildings array", test_prov.buildings.size() == 0)
	test.call("can_build does not mutate faction wood treasury", test_faction.wood == 200)
	test.call("can_recruit does not mutate faction gold or food treasury", test_faction.gold == 500 and test_faction.food == 300)
	
	# Test 12: Campaign HUD Theme & Button Dynamic Reflection
	var GMClass = load("res://scripts/core/game_manager.gd")
	var gm = GMClass.new()
	gm.name = "GameManager"
	root.add_child(gm)
	gm.start_new_campaign("mongol", "checkpoint_slice")
	
	var hud = CampaignHUD.new()
	root.add_child(hud)
	
	# Select Sarai
	hud.select_province("sarai")
	test.call("HUD construct_buttons contains all 7 buildings", hud.construct_buttons.size() == 7)
	test.call("HUD recruit_buttons contains all 6 military units", hud.recruit_buttons.size() == 6)
	
	# Initially player has 200w; town_center costs 120w -> should be enabled
	var tc_btn = hud.construct_buttons["town_center"]
	test.call("HUD town center button is enabled with sufficient wood", tc_btn.disabled == false)
	
	# Simulate building town_center in Sarai
	gm.provinces["sarai"].buildings.append("town_center")
	hud.update_actions_state()
	test.call("HUD disables already-built structure button immediately with [BUILT] marker", tc_btn.disabled == true and "[BUILT]" in tc_btn.text)
	
	# Simulate emptying wood reserves
	gm.factions["mongol"].wood = 10
	hud.update_actions_state()
	var barracks_btn = hud.construct_buttons["barracks"]
	test.call("HUD disables building button when wood is depleted and updates tooltip", barracks_btn.disabled == true and "Disabled" in barracks_btn.tooltip_text)
	
	# Verify theme resource exists and is loaded
	var theme_loaded = ResourceLoader.exists("res://assets/theme/game_theme.tres")
	test.call("game_theme.tres is present in assets/theme/", theme_loaded)
	
	hud.free()
	gm.free()
	
	print("\n-------------------------------------------------------")
	print("  TOTAL TESTS: ", stats[0] + stats[1], " | PASSED: ", stats[0], " | FAILED: ", stats[1])
	print("-------------------------------------------------------\n")
	
	if stats[1] == 0:
		print(">>> ALL ECONOMY VALIDATION TESTS PASSED SUCCESSFULLY! <<<\n")
		quit(0)
	else:
		print(">>> SOME TESTS FAILED! <<<\n")
		quit(1)
