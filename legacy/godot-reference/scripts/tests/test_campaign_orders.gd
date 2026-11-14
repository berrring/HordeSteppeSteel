extends SceneTree

const GM = preload("res://scripts/core/game_manager.gd")
var checks: int = 0
var failed: int = 0
func verify(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failed += 1
		push_error(message)
func _init() -> void:
	var gm = GM.new()
	gm.start_new_campaign()
	var initial: Dictionary = gm.provinces.duplicate(true)
	verify(not gm.validate_army_order("missing", "sarai").allowed, "Unknown source rejected")
	verify(not gm.validate_army_order("sarai", "shangdu").allowed, "Non-neighbor rejected")
	verify(gm.resolve_battle("sarai", "shangdu").is_empty(), "Core battle rejects teleport attack")
	verify(not gm.move_army("kiev", "moscow").allowed, "Cannot move another faction's army")
	verify(gm.provinces == initial, "Invalid orders leave state untouched")
	var count: int = gm.get_army_strength(gm.provinces.sarai.army) + gm.get_army_strength(gm.provinces.kipchak.army)
	var old_moves: int = gm.moves_left(gm.provinces.sarai.army)
	verify(gm.move_army("sarai", "kipchak").allowed, "Friendly march succeeds")
	verify(gm.provinces.sarai.army == null and gm.get_army_strength(gm.provinces.kipchak.army) == count, "Merge conserves all soldiers")
	verify(gm.moves_left(gm.provinces.kipchak.army) == old_moves - 1, "March spends one movement")
	gm.provinces.sarai.army = {"faction": "mongol", "units": [{"type": "infantry", "count": 1}], "moves_left": 0}
	verify(gm.move_army("kipchak", "sarai").allowed, "Merge into exhausted army")
	verify(gm.moves_left(gm.provinces.sarai.army) == 0, "Merge cannot refresh movement")
	verify(not gm.move_army("sarai", "kipchak").allowed, "Exhausted army cannot march")
	gm.start_new_campaign()
	gm.factions.mongol.wood = 1000
	var gold_income: int = gm.provinces.sarai.income_gold
	verify(gm.construct_building("sarai", "town_center").allowed, "Construction allowed once")
	verify(not gm.construct_building("sarai", "town_center").allowed, "Duplicate rejected by state owner")
	verify(gm.provinces.sarai.income_gold == gold_income + 40 and gm.factions.mongol.wood == 880, "Construction effects and payment once")
	verify(not gm.construct_building("kiev", "market").allowed, "Foreign construction rejected")
	verify(not gm.construct_building("sarai", "unknown").allowed, "Unknown building rejected")
	var money: int = gm.factions.mongol.gold
	verify(not gm.recruit_units("sarai", "unknown").allowed, "Unknown unit cannot recruit for free")
	verify(gm.factions.mongol.gold == money, "Invalid recruitment has no charge")
	gm.provinces.sarai.army.moves_left = 0
	verify(gm.recruit_units("sarai", "infantry").allowed, "Recruitment succeeds")
	verify(gm.provinces.sarai.army.moves_left == 0, "Recruitment does not refresh exhausted army")
	verify(not gm.recruit_units("kiev", "infantry").allowed, "Foreign recruitment rejected")
	gm.start_new_campaign("mongol", "checkpoint_slice")
	var result: Dictionary = gm.begin_battle("sarai", "crossroads")
	verify(not result.is_empty() and gm.current_state == gm.GameState.BATTLE, "Battle reserves campaign")
	var snapshot: Dictionary = gm.provinces.duplicate(true)
	var turn_before: int = gm.turn
	verify(not gm.end_turn() and gm.turn == turn_before, "Cannot end turn in battle")
	verify(not gm.save_game("user://blocked_test.json"), "Cannot save halfway through battle")
	verify(not gm.construct_building("sarai", "market").allowed, "Cannot build in battle")
	verify(not gm.recruit_units("sarai", "infantry").allowed, "Cannot recruit in battle")
	verify(gm.begin_battle("sarai", "crossroads").is_empty(), "Cannot queue second battle")
	var forged: Dictionary = result.duplicate(true)
	forged.attacker_won = not forged.attacker_won
	verify(not gm.apply_battle_result("sarai", "crossroads", forged), "Forged outcome rejected")
	verify(gm.provinces == snapshot, "Rejected battle actions leave state intact")
	var retreat: Dictionary = gm.retreat_battle()
	verify(not retreat.attacker_won and gm.apply_battle_result("sarai", "crossroads", retreat), "Retreat commits authoritative losses")
	verify(not gm.apply_battle_result("sarai", "crossroads", retreat), "Core rejects duplicate result application")
	verify(gm.provinces.crossroads.owner == "neutral" and gm.moves_left(gm.provinces.sarai.army) == 0, "Retreat neither captures nor restores movement")
	gm.start_new_campaign("mongol", "checkpoint_slice")
	gm.provinces.sarai.army.moves_left = 0
	var gold: int = gm.factions.mongol.gold
	var neutral_before: Dictionary = gm.provinces.crossroads.duplicate(true)
	verify(gm.end_turn(), "Turn advances")
	verify(gm.turn == 2 and gm.season_name() == "Summer", "Turn and season advance together")
	verify(gm.factions.mongol.gold == gold + 150, "Player income exactly once")
	verify(gm.moves_left(gm.provinces.sarai.army) > 0, "Movement refreshes next turn")
	verify(gm.provinces.crossroads == neutral_before, "Rus does not invade neutral checkpoint")
	verify(gm.factions.rus.food == 200, "AI pays food as well as gold for cavalry")
	var save_path: String = "user://orders_test.json"
	gm.provinces.sarai.army.moves_left = 0
	verify(gm.save_game(save_path), "Campaign save succeeds")
	gm.start_new_campaign("rus")
	verify(gm.load_game(save_path), "Checkpoint save reloads")
	verify(gm.moves_left(gm.provinces.sarai.army) == 0, "Loading cannot restore spent movement")
	verify(gm.factions.mongol.color is Color and gm.current_scenario == "checkpoint_slice", "Loaded palette and scenario restored")
	var stable: Dictionary = gm.provinces.duplicate(true)
	for payload in [[], {"provinces": {}, "factions": {}}, {"turn": 1, "current_faction": "mongol", "provinces": stable, "factions": {}}]:
		var file := FileAccess.open(save_path, FileAccess.WRITE)
		file.store_string(JSON.stringify(payload))
		file.close()
		verify(not gm.load_game(save_path) and gm.provinces == stable, "Malformed save rejected transactionally")
	gm.start_new_campaign("mongol", "checkpoint_slice")
	var valid: Dictionary = {"turn": gm.turn, "current_faction": gm.current_faction, "current_scenario": gm.current_scenario, "provinces": gm.provinces.duplicate(true), "factions": gm.factions.duplicate(true)}
	for broken in ["multiplier", "province_id", "faction_id"]:
		var bad_save: Dictionary = valid.duplicate(true)
		if broken == "multiplier":
			bad_save.factions.mongol.bonus_movement = "bad"
		elif broken == "province_id":
			bad_save.provinces["fake"] = bad_save.provinces.sarkel
			bad_save.provinces.erase("sarkel")
		else:
			bad_save.factions.mongol.id = "rus"
		var file := FileAccess.open(save_path, FileAccess.WRITE)
		file.store_string(JSON.stringify(bad_save))
		file.close()
		verify(not gm.load_game(save_path) and gm.provinces == valid.provinces, "Invalid %s rejected before committing save" % broken)
	DirAccess.remove_absolute(ProjectSettings.globalize_path(save_path))
	for fid in ["mongol", "cuman", "rus", "byzantine", "seljuk", "khwarazm"]:
		gm.start_new_campaign(fid)
		var source: String = ""
		var target: String = ""
		for pid in gm.provinces:
			if gm.provinces[pid].owner == fid and gm.provinces[pid].army != null:
				for neighbor in gm.provinces[pid].neighbors:
					if gm.provinces[neighbor].owner != fid:
						source = pid
						target = neighbor
		verify(source != "" and gm.validate_army_order(source, target).allowed, "%s can issue campaign orders" % fid)
	# Deterministic multi-turn campaign: all factions preserve ownership and resource invariants.
	for fid in ["mongol", "rus", "cuman", "byzantine", "seljuk", "khwarazm"]:
		gm.start_new_campaign(fid)
		for i in range(12):
			if gm.current_state != gm.GameState.CAMPAIGN:
				break
			verify(gm.end_turn(), "Long campaign turn advances")
			for p in gm.provinces.values():
				verify(p.army == null or (p.army.faction == p.owner and gm.moves_left(p.army) >= 0), "Army always belongs to province owner")
			for faction in gm.factions.values():
				verify(faction.gold >= 0 and faction.food >= 0 and faction.wood >= 0, "AI cannot overspend resources")
	gm.free()
	print("Campaign orders: ", checks, " checks, failures: ", failed)
	quit(1 if failed else 0)
