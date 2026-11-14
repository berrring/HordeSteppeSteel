extends Node

const Economy = preload("res://scripts/core/economy_manager.gd")
const Calculator = preload("res://scripts/combat/battle_calculator.gd")

const Palette = preload("res://scripts/core/palette.gd")

signal turn_ended(turn_number: int)
signal province_captured(province_id: String, new_owner: String)
signal faction_defeated(faction_id: String)
signal game_over(is_victory: bool)
signal state_changed(new_state: String)
signal campaign_loaded

var _processing_turn: bool = false
var _battle_serial: int = 0
var campaign_log: Array[String] = []

enum GameState { MAIN_MENU, CAMPAIGN, BATTLE, VICTORY, DEFEAT }

var current_state: GameState = GameState.MAIN_MENU
var turn: int = 1
var max_turns: int = 60
var provinces_to_win: int = 10
var current_scenario: String = "full_campaign"

# Data containers
var provinces: Dictionary = {}
var factions: Dictionary = {}
var current_faction: String = "mongol"

# Battle context
var battle_context: Dictionary = {}

func _ready():
	pass

func start_new_campaign(chosen_faction: String = "mongol", scenario_mode: String = "full_campaign"):
	if scenario_mode not in ["full_campaign", "checkpoint_slice"]:
		scenario_mode = "full_campaign"
	if scenario_mode == "checkpoint_slice":
		chosen_faction = "mongol"
	elif chosen_faction not in ["mongol", "cuman", "rus", "byzantine", "seljuk", "khwarazm"]:
		chosen_faction = "mongol"
	battle_context.clear()
	campaign_log.clear()
	_processing_turn = false
	current_scenario = scenario_mode
	if scenario_mode == "checkpoint_slice":
		_build_checkpoint_slice()
		_build_checkpoint_factions()
	else:
		_build_provinces()
		_build_factions(chosen_faction)
	current_faction = chosen_faction
	turn = 1
	for fid in factions:
		_reset_movement(fid)
	current_state = GameState.CAMPAIGN
	state_changed.emit("campaign")

func _build_checkpoint_slice():
	provinces.clear()
	var raw = [
		{"id": "sarai", "name": "Sarai Steppe", "x": -3.0, "z": -0.5, "owner": "mongol", "gold": 150, "food": 100, "wood": 60, "defense": 10, "capital": true},
		{"id": "crossroads", "name": "Crossroads Hill", "x": 1.0, "z": 0.5, "owner": "neutral", "gold": 60, "food": 60, "wood": 80, "defense": 5, "capital": false},
		{"id": "sarkel", "name": "Sarkel Redoubt", "x": 4.5, "z": 1.5, "owner": "rus", "gold": 100, "food": 50, "wood": 80, "defense": 20, "capital": true}
	]
	for data in raw:
		var pid: String = data["id"]
		provinces[pid] = {
			"id": pid,
			"name": data["name"],
			"x": data["x"],
			"z": data["z"],
			"owner": data["owner"],
			"income_gold": data["gold"],
			"income_food": data["food"],
			"income_wood": data["wood"],
			"defense_bonus": data["defense"],
			"is_capital": data["capital"],
			"neighbors": [],
			"buildings": [],
			"army": null,
		}
	var edges = [["sarai", "crossroads"], ["crossroads", "sarkel"]]
	for e in edges:
		var p1: String = e[0]
		var p2: String = e[1]
		if provinces.has(p1) and provinces.has(p2):
			if not provinces[p1]["neighbors"].has(p2):
				provinces[p1]["neighbors"].append(p2)
			if not provinces[p2]["neighbors"].has(p1):
				provinces[p2]["neighbors"].append(p1)
	
	provinces["sarai"]["army"] = {
		"faction": "mongol",
		"units": [{"type": "horse_archer", "count": 100}]
	}
	provinces["crossroads"]["army"] = {
		"faction": "neutral",
		"units": [{"type": "spearman", "count": 40}]
	}
	provinces["sarkel"]["army"] = {
		"faction": "rus",
		"units": [{"type": "infantry", "count": 80}]
	}

func _build_checkpoint_factions():
	factions.clear()
	factions["mongol"] = {
		"id": "mongol",
		"name": "Mongol Khanate",
		"color": Palette.BRONZE_GOLD,
		"is_player": true,
		"gold": 500, "food": 300, "wood": 200,
		"is_defeated": false,
		"bonus_attack": 1.15,
		"bonus_defense": 0.9,
		"bonus_movement": 1.2,
	}
	factions["rus"] = {
		"id": "rus",
		"name": "Rus' Outpost",
		"color": Palette.DEEP_STEEL_BLUE,
		"is_player": false,
		"gold": 300, "food": 200, "wood": 150,
		"is_defeated": false,
		"bonus_attack": 1.0,
		"bonus_defense": 1.25,
		"bonus_movement": 0.9,
	}
	factions["neutral"] = {
		"id": "neutral",
		"name": "Local Clans",
		"color": Palette.SNOW_WHITE,
		"is_player": false,
		"gold": 0, "food": 0, "wood": 0,
		"is_defeated": false,
		"bonus_attack": 1.0,
		"bonus_defense": 1.0,
		"bonus_movement": 1.0,
	}

func _build_provinces():
	provinces.clear()
	# Each province: {id, name, x, z, owner, income_gold, income_food, income_wood, defense_bonus, neighbors[], is_capital, buildings[]}
	var raw = [
		# Player start (The Golden Horde)
		{"id": "sarai", "name": "Sarai", "x": 0.0, "z": 0.0, "owner": "mongol", "gold": 150, "food": 100, "wood": 50, "defense": 10, "capital": true},
		{"id": "kipchak", "name": "Kipchak Steppe", "x": -3.0, "z": -3.0, "owner": "mongol", "gold": 120, "food": 130, "wood": 30, "defense": 0, "capital": false},
		# Ancient Rus' Principalities
		{"id": "novgorod", "name": "Novgorod", "x": -4.0, "z": -8.0, "owner": "rus", "gold": 130, "food": 90, "wood": 150, "defense": 15, "capital": true},
		{"id": "moscow", "name": "Moscow", "x": -1.0, "z": -6.0, "owner": "rus", "gold": 140, "food": 100, "wood": 120, "defense": 10, "capital": false},
		{"id": "kiev", "name": "Kiev", "x": -3.0, "z": -5.0, "owner": "rus", "gold": 120, "food": 110, "wood": 100, "defense": 5, "capital": false},
		# Seljuk Sultanate
		{"id": "tabriz", "name": "Tabriz", "x": -2.0, "z": 6.0, "owner": "seljuk", "gold": 120, "food": 80, "wood": 60, "defense": 5, "capital": true},
		{"id": "samarkand", "name": "Samarkand", "x": 2.0, "z": 3.0, "owner": "seljuk", "gold": 150, "food": 90, "wood": 80, "defense": 10, "capital": false},
		# Cumans / Kipchaks
		{"id": "bukhara", "name": "Bukhara", "x": -1.0, "z": 4.5, "owner": "cuman", "gold": 130, "food": 100, "wood": 70, "defense": 5, "capital": true},
		# Khwarazmshah Dynasty
		{"id": "karakorum", "name": "Karakorum", "x": 6.0, "z": -3.0, "owner": "khwarazm", "gold": 160, "food": 80, "wood": 40, "defense": 20, "capital": true},
		{"id": "zhongdu", "name": "Zhongdu", "x": 8.0, "z": -1.0, "owner": "khwarazm", "gold": 180, "food": 120, "wood": 60, "defense": 15, "capital": false},
		{"id": "shangdu", "name": "Shangdu", "x": 7.0, "z": -5.0, "owner": "khwarazm", "gold": 140, "food": 90, "wood": 50, "defense": 10, "capital": false},
		# Byzantine Empire Outpost
		{"id": "urgench", "name": "Urgench", "x": 3.0, "z": 1.0, "owner": "byzantine", "gold": 110, "food": 70, "wood": 60, "defense": 10, "capital": true},
	]
	for data in raw:
		provinces[data.id] = {
			"id": data.id,
			"name": data.name,
			"x": data.x,
			"z": data.z,
			"owner": data.owner,
			"income_gold": data.gold,
			"income_food": data.food,
			"income_wood": data.wood,
			"defense_bonus": data.defense,
			"is_capital": data.capital,
			"neighbors": [],
			"buildings": [],
			"army": null,
		}
	# Adjacency
	var edges = [
		["sarai", "kipchak"], ["sarai", "urgench"], ["sarai", "kiev"],
		["sarai", "samarkand"], ["kipchak", "kiev"], ["kipchak", "moscow"],
		["kipchak", "urgench"], ["kiev", "moscow"], ["moscow", "novgorod"],
		["urgench", "samarkand"], ["urgench", "karakorum"],
		["samarkand", "bukhara"], ["samarkand", "karakorum"],
		["bukhara", "tabriz"], ["tabriz", "samarkand"],
		["karakorum", "zhongdu"], ["karakorum", "shangdu"],
		["zhongdu", "shangdu"],
	]
	for e in edges:
		if provinces.has(e[0]) and provinces.has(e[1]):
			if not provinces[e[0]].neighbors.has(e[1]):
				provinces[e[0]].neighbors.append(e[1])
			if not provinces[e[1]].neighbors.has(e[0]):
				provinces[e[1]].neighbors.append(e[0])

func _build_factions(chosen_faction: String = "mongol"):
	factions.clear()
	# 1. Mongol Khanate (The Golden Horde) - Player Faction
	factions["mongol"] = {
		"id": "mongol",
		"name": "Mongol Khanate",
		"color": Palette.FACTION_MONGOL,
		"is_player": (chosen_faction == "mongol"),
		"gold": 500, "food": 300, "wood": 200,
		"is_defeated": false,
		"bonus_attack": 1.15,
		"bonus_defense": 0.9,
		"bonus_movement": 1.2,
	}
	# 2. Cumans / Kipchaks
	factions["cuman"] = {
		"id": "cuman",
		"name": "Cumans / Kipchaks",
		"color": Palette.FACTION_CUMAN,
		"is_player": (chosen_faction == "cuman"),
		"gold": 350, "food": 320, "wood": 200,
		"is_defeated": false,
		"bonus_attack": 1.1,
		"bonus_defense": 0.95,
		"bonus_movement": 1.25,
	}
	# 3. Ancient Rus' Principalities
	factions["rus"] = {
		"id": "rus",
		"name": "Rus' Principalities",
		"color": Palette.FACTION_RUS,
		"is_player": (chosen_faction == "rus"),
		"gold": 400, "food": 350, "wood": 400,
		"is_defeated": false,
		"bonus_attack": 1.0,
		"bonus_defense": 1.3,
		"bonus_movement": 0.9,
	}
	# 4. Byzantine Empire
	factions["byzantine"] = {
		"id": "byzantine",
		"name": "Byzantine Empire",
		"color": Palette.FACTION_BYZANTINE,
		"is_player": (chosen_faction == "byzantine"),
		"gold": 450, "food": 250, "wood": 250,
		"is_defeated": false,
		"bonus_attack": 1.05,
		"bonus_defense": 1.2,
		"bonus_movement": 0.95,
	}
	# 5. Seljuk Sultanate
	factions["seljuk"] = {
		"id": "seljuk",
		"name": "Seljuk Sultanate",
		"color": Palette.FACTION_SELJUK,
		"is_player": (chosen_faction == "seljuk"),
		"gold": 400, "food": 300, "wood": 250,
		"is_defeated": false,
		"bonus_attack": 1.1,
		"bonus_defense": 1.0,
		"bonus_movement": 1.0,
	}
	# 6. Khwarazmshah Dynasty
	factions["khwarazm"] = {
		"id": "khwarazm",
		"name": "Khwarazmshah Dynasty",
		"color": Palette.FACTION_KHWARAZM,
		"is_player": (chosen_faction == "khwarazm"),
		"gold": 400, "food": 280, "wood": 300,
		"is_defeated": false,
		"bonus_attack": 1.05,
		"bonus_defense": 1.1,
		"bonus_movement": 1.0,
	}
	# Setup starting armies
	_setup_starting_armies()

func _setup_starting_armies():
	# Player (Mongol)
	provinces["sarai"].army = {
		"faction": "mongol",
		"units": [
			{"type": "horse_archer", "count": 100},
			{"type": "horse_archer", "count": 80},
			{"type": "light_cavalry", "count": 60},
		]
	}
	provinces["kipchak"].army = {
		"faction": "mongol",
		"units": [{"type": "horse_archer", "count": 70}]
	}
	# Rus
	provinces["novgorod"].army = {
		"faction": "rus",
		"units": [
			{"type": "infantry", "count": 100},
			{"type": "heavy_cavalry", "count": 50},
		]
	}
	provinces["moscow"].army = {
		"faction": "rus",
		"units": [{"type": "infantry", "count": 80}]
	}
	provinces["kiev"].army = {
		"faction": "rus",
		"units": [{"type": "spearman", "count": 60}]
	}
	# Seljuk
	provinces["tabriz"].army = {
		"faction": "seljuk",
		"units": [
			{"type": "siege", "count": 50},
			{"type": "infantry", "count": 80},
		]
	}
	provinces["samarkand"].army = {
		"faction": "seljuk",
		"units": [{"type": "infantry", "count": 70}]
	}
	# Khwarazmshah
	provinces["karakorum"].army = {
		"faction": "khwarazm",
		"units": [
			{"type": "heavy_cavalry", "count": 80},
			{"type": "infantry", "count": 100},
		]
	}
	# Cuman / Kipchak
	provinces["bukhara"].army = {
		"faction": "cuman",
		"units": [
			{"type": "horse_archer", "count": 90},
			{"type": "light_cavalry", "count": 60},
		]
	}
	# Byzantine Outpost
	provinces["urgench"].army = {
		"faction": "byzantine",
		"units": [
			{"type": "spearman", "count": 80},
			{"type": "heavy_cavalry", "count": 50},
		]
	}
	provinces["zhongdu"].army = {
		"faction": "khwarazm",
		"units": [{"type": "heavy_cavalry", "count": 60}]
	}

func get_unit_stats(unit_type: String) -> Dictionary:
	var stats = {
		"horse_archer": {"hp": 60, "attack": 35, "defense": 20, "movement": 3, "range": 2, "cost_gold": 150, "cost_food": 50},
		"light_cavalry": {"hp": 70, "attack": 30, "defense": 25, "movement": 3, "range": 1, "cost_gold": 120, "cost_food": 40},
		"heavy_cavalry": {"hp": 100, "attack": 55, "defense": 45, "movement": 2, "range": 1, "cost_gold": 250, "cost_food": 80},
		"infantry": {"hp": 90, "attack": 40, "defense": 50, "movement": 1, "range": 1, "cost_gold": 100, "cost_food": 30},
		"spearman": {"hp": 85, "attack": 45, "defense": 55, "movement": 1, "range": 1, "cost_gold": 110, "cost_food": 35},
		"siege": {"hp": 50, "attack": 70, "defense": 10, "movement": 1, "range": 3, "cost_gold": 300, "cost_food": 20},
	}
	return stats.get(unit_type, {})

func get_province_owner_faction(province_id: String) -> Dictionary:
	if not provinces.has(province_id):
		return {}
	var owner_id = provinces[province_id].owner
	if owner_id == "" or not factions.has(owner_id):
		return {}
	return factions[owner_id]

func get_player_faction() -> Dictionary:
	return factions.get(current_faction, {})

func collect_income(faction_id: String) -> Dictionary:
	var income = {"gold": 0, "food": 0, "wood": 0}
	for pid in provinces:
		if provinces[pid].owner == faction_id:
			income.gold += provinces[pid].income_gold
			income.food += provinces[pid].income_food
			income.wood += provinces[pid].income_wood
	if factions.has(faction_id):
		factions[faction_id].gold += income.gold
		factions[faction_id].food += income.food
		factions[faction_id].wood += income.wood
	return income

func get_army_strength(army: Variant) -> int:
	return Calculator.new().army_strength(army)

func army_movement(army: Variant) -> int:
	if get_army_strength(army) <= 0:
		return 0
	var slowest: int = 3
	for unit in army.units:
		slowest = mini(slowest, int(get_unit_stats(unit.type).get("movement", 1)))
	return maxi(1, int(ceil(slowest * factions.get(army.faction, {}).get("bonus_movement", 1.0))))

func moves_left(army: Variant) -> int:
	if army == null:
		return 0
	return int(army.get("moves_left", army_movement(army)))

func _reset_movement(fid: String) -> void:
	for p in provinces.values():
		if p.army != null and p.army.faction == fid:
			p.army["moves_left"] = army_movement(p.army)

func season_name() -> String:
	return ["Spring", "Summer", "Autumn", "Winter"][(turn - 1) % 4]

func can_manage_province(pid: String) -> bool:
	return current_state == GameState.CAMPAIGN and not _processing_turn and provinces.has(pid) and provinces[pid].owner == current_faction

func validate_army_order(source: String, target: String, actor: String = "") -> Dictionary:
	var fid: String = current_faction if actor == "" else actor
	if current_state != GameState.CAMPAIGN or (_processing_turn and fid == current_faction):
		return {"allowed": false, "reason": "Finish the current action first."}
	if not provinces.has(source) or not provinces.has(target) or source == target:
		return {"allowed": false, "reason": "Choose two different provinces."}
	var p: Dictionary = provinces[source]
	if p.owner != fid or p.army == null or p.army.faction != fid or get_army_strength(p.army) == 0:
		return {"allowed": false, "reason": "Select a province containing your army."}
	if target not in p.neighbors:
		return {"allowed": false, "reason": "Armies can only enter connected neighboring provinces."}
	if moves_left(p.army) <= 0:
		return {"allowed": false, "reason": "This army has no movement left. End the turn."}
	return {"allowed": true, "reason": "March" if provinces[target].owner == fid else "Attack"}

func move_army(source: String, target: String, actor: String = "") -> Dictionary:
	var validation: Dictionary = validate_army_order(source, target, actor)
	if not validation.allowed:
		return validation
	var army: Dictionary = provinces[source].army
	if provinces[target].owner != army.faction:
		return {"allowed": false, "reason": "Enemy territory requires a battle."}
	var remaining: int = moves_left(army) - 1
	var destination = provinces[target].army
	if destination == null:
		provinces[target].army = army
	else:
		remaining = mini(remaining, moves_left(destination))
		for incoming in army.units:
			var merged: bool = false
			for unit in destination.units:
				if unit.type == incoming.type:
					unit.count += incoming.count
					merged = true
					break
			if not merged:
				destination.units.append(incoming.duplicate(true))
	provinces[target].army["moves_left"] = mini(remaining, army_movement(provinces[target].army))
	provinces[source].army = null
	return {"allowed": true, "reason": "Army arrived.", "destination": target}

func construct_building(pid: String, building_type: String, actor: String = "") -> Dictionary:
	var fid: String = current_faction if actor == "" else actor
	if not provinces.has(pid) or provinces[pid].owner != fid or not factions.has(fid) or current_state != GameState.CAMPAIGN or (fid == current_faction and _processing_turn):
		return {"allowed": false, "reason": "Select your province during your turn."}
	var p: Dictionary = provinces[pid]
	var faction: Dictionary = factions[fid]
	var check: Dictionary = Economy.can_build(p, faction, building_type)
	if not check.allowed:
		return check
	var data: Dictionary = Economy.get_building_data(building_type)
	faction.wood -= data.wood_cost
	p.income_gold += data.income_gold
	p.income_food += data.income_food
	p.defense_bonus += data.defense_bonus
	p.buildings.append(building_type)
	return {"allowed": true, "reason": "%s completed in %s." % [data.name, p.name]}

func recruit_units(pid: String, unit_type: String, actor: String = "") -> Dictionary:
	var fid: String = current_faction if actor == "" else actor
	if not provinces.has(pid) or provinces[pid].owner != fid or not factions.has(fid) or current_state != GameState.CAMPAIGN:
		return {"allowed": false, "reason": "Recruit only in your own provinces."}
	if fid == current_faction and _processing_turn:
		return {"allowed": false, "reason": "Wait for your turn."}
	var stats: Dictionary = get_unit_stats(unit_type)
	if stats.is_empty():
		return {"allowed": false, "reason": "Unknown unit type."}
	var check: Dictionary = Economy.can_recruit(factions[fid], stats)
	if not check.allowed:
		return check
	factions[fid].gold -= stats.cost_gold
	factions[fid].food -= stats.cost_food
	var p: Dictionary = provinces[pid]
	if p.army == null:
		p.army = {"faction": fid, "units": [], "moves_left": 0}
	var found: bool = false
	for unit in p.army.units:
		if unit.type == unit_type:
			unit.count += 50
			found = true
			break
	if not found:
		p.army.units.append({"type": unit_type, "count": 50})
	p.army["moves_left"] = mini(moves_left(p.army), army_movement(p.army))
	return {"allowed": true, "reason": "Recruited 50 %s in %s." % [unit_type.replace("_", " "), p.name]}

func province_count(faction_id: String) -> int:
	var count = 0
	for pid in provinces:
		if provinces[pid].owner == faction_id:
			count += 1
	return count

func check_victory() -> String:
	if current_scenario == "checkpoint_slice":
		if provinces.has("sarkel") and provinces["sarkel"]["owner"] == current_faction:
			return "win"
		if provinces.has("sarai") and provinces["sarai"]["owner"] != current_faction:
			var has_army = false
			for pid in provinces:
				if provinces[pid]["army"] != null and provinces[pid]["army"]["faction"] == current_faction:
					has_army = true
					break
			if not has_army:
				return "lose"
		if turn > 30:
			return "lose"
		return ""

	var player_provinces = province_count(current_faction)
	if player_provinces >= provinces_to_win:
		return "win"
	var all_defeated = true
	for fid in factions:
		if fid == current_faction:
			continue
		if not factions[fid].is_defeated:
			all_defeated = false
			break
	if all_defeated:
		return "win"
	if player_provinces == 0 and get_army_strength(null) == 0:
		# Check if player has any armies anywhere
		var has_army = false
		for pid in provinces:
			if provinces[pid].army != null and provinces[pid].army.faction == current_faction:
				has_army = true
				break
		if not has_army:
			return "lose"
	if turn > max_turns:
		return "lose"
	return ""

func begin_battle(attacker_pid: String, defender_pid: String, actor: String = "") -> Dictionary:
	var validation: Dictionary = validate_army_order(attacker_pid, defender_pid, actor)
	if not validation.allowed:
		return {}
	var att: Dictionary = provinces[attacker_pid]
	var defender: Dictionary = provinces[defender_pid]
	if defender.owner == att.owner:
		return {}
	_battle_serial += 1
	var result: Dictionary = Calculator.new().calculate(att.army, defender.army, defender.defense_bonus,
		factions.get(att.owner, {}).get("bonus_attack", 1.0), factions.get(defender.owner, {}).get("bonus_defense", 1.0))
	result.merge({"attacker_pid": attacker_pid, "defender_pid": defender_pid, "province": defender_pid, "battle_id": _battle_serial})
	battle_context = {"result": result.duplicate(true), "attacker": att.army.duplicate(true), "defender": defender.army.duplicate(true) if defender.army != null else null}
	att.army["moves_left"] = 0
	current_state = GameState.BATTLE
	return result

func retreat_battle() -> Dictionary:
	if current_state != GameState.BATTLE or battle_context.is_empty():
		return {}
	var previous: Dictionary = battle_context.result
	var p: Dictionary = provinces[previous.defender_pid]
	var result: Dictionary = Calculator.new().calculate(battle_context.attacker, battle_context.defender,
		p.defense_bonus, 0.0, factions.get(p.owner, {}).get("bonus_defense", 1.0))
	for key in ["attacker_pid", "defender_pid", "province", "battle_id"]:
		result[key] = previous[key]
	battle_context.result = result.duplicate(true)
	return result

func resolve_battle(attacker_pid: String, defender_pid: String) -> Dictionary:
	if not provinces.has(attacker_pid):
		return {}
	var result: Dictionary = begin_battle(attacker_pid, defender_pid, provinces[attacker_pid].owner)
	if result.is_empty():
		return {}
	apply_battle_result(attacker_pid, defender_pid, result)
	return result

# Only the active calculation may commit, exactly once.
func apply_battle_result(attacker_pid: String, defender_pid: String, result: Dictionary, tactical_capture: bool = false) -> bool:
	if current_state != GameState.BATTLE or battle_context.is_empty() or result != battle_context.result:
		return false
	if result.attacker_pid != attacker_pid or result.defender_pid != defender_pid:
		return false
	var att_army: Dictionary = battle_context.attacker.duplicate(true)
	var defender_owner: String = provinces[defender_pid].owner
	att_army.units = result.surviving_attackers.duplicate(true)
	att_army["moves_left"] = 0
	if result.attacker_won:
		provinces[defender_pid].owner = att_army.faction
		provinces[defender_pid].army = att_army
		provinces[attacker_pid].army = null
		if tactical_capture:
			provinces[defender_pid].defense_bonus = maxi(0, provinces[defender_pid].defense_bonus - 5)
	else:
		provinces[attacker_pid].army = att_army if not att_army.units.is_empty() else null
	battle_context.clear()
	current_state = GameState.CAMPAIGN
	if result.attacker_won:
		if factions.has(defender_owner) and province_count(defender_owner) == 0:
			factions[defender_owner].is_defeated = true
			faction_defeated.emit(defender_owner)
		province_captured.emit(defender_pid, att_army.faction)
	return true

func evaluate_campaign() -> String:
	var outcome: String = check_victory()
	if outcome != "" and current_state not in [GameState.VICTORY, GameState.DEFEAT]:
		current_state = GameState.VICTORY if outcome == "win" else GameState.DEFEAT
		game_over.emit(outcome == "win")
	return outcome

func end_turn() -> bool:
	if current_state != GameState.CAMPAIGN or _processing_turn:
		return false
	_processing_turn = true
	campaign_log.clear()
	_run_ai_turns()
	turn += 1
	_reset_movement(current_faction)
	collect_income(current_faction)
	_processing_turn = false
	evaluate_campaign()
	turn_ended.emit(turn)
	return true

func _run_ai_turns():
	for fid in factions:
		if fid == current_faction or fid == "neutral" or factions[fid].is_defeated:
			continue
		_ai_turn(fid)

func _ai_turn(faction_id: String):
	if faction_id == "neutral" or not factions.has(faction_id) or factions[faction_id].is_defeated:
		return
	_reset_movement(faction_id)
	# Collect income
	collect_income(faction_id)
	# Recruit at capital
	_ai_recruit(faction_id)
	_ai_develop(faction_id)
	if current_scenario == "checkpoint_slice":
		var action: Dictionary = preload("res://scripts/ai/strategic_ai.gd").new().choose_counterattack(
			current_scenario, current_faction, provinces, factions, faction_id)
		if not action.is_empty():
			var result: Dictionary = resolve_battle(action.attacker_pid, action.defender_pid)
			if not result.is_empty():
				campaign_log.append("Rus counterattacked Crossroads: %s." % ("captured" if result.attacker_won else "repulsed"))
	else:
		# Preserve the original full campaign strategy.
		_ai_attack(faction_id)

func _ai_recruit(faction_id: String):
	var capital_pid: String = ""
	for pid in provinces:
		if provinces[pid].owner == faction_id:
			if capital_pid == "" or provinces[pid].is_capital:
				capital_pid = pid
	if capital_pid != "":
		var unit_type: String = "horse_archer" if factions[faction_id].gold >= 250 else "infantry"
		recruit_units(capital_pid, unit_type, faction_id)

func _ai_develop(fid: String) -> void:
	for pid in provinces:
		if provinces[pid].owner != fid:
			continue
		for building in ["market", "town_center"]:
			if building not in provinces[pid].buildings:
				if construct_building(pid, building, fid).allowed:
					return

func _ai_attack(faction_id: String):
	# Snapshot sources so an army cannot attack repeatedly after capturing territory.
	var sources: Array = provinces.keys()
	for source in sources:
		var p: Dictionary = provinces[source]
		if p.owner != faction_id or p.army == null or moves_left(p.army) <= 0:
			continue
		var attack: float = get_army_strength(p.army) * factions[faction_id].get("bonus_attack", 1.0)
		var target: String = ""
		var weakest: float = INF
		for neighbor in p.neighbors:
			var enemy: Dictionary = provinces[neighbor]
			if enemy.owner == faction_id:
				continue
			var strength: float = (get_army_strength(enemy.army) + enemy.defense_bonus * Calculator.FORTIFICATION_SCALE) * factions.get(enemy.owner, {}).get("bonus_defense", 1.0)
			if strength < weakest:
				weakest = strength
				target = neighbor
		if target != "" and attack > weakest:
			var result: Dictionary = resolve_battle(source, target)
			if not result.is_empty():
				campaign_log.append("%s attacked %s: %s." % [factions[faction_id].name, provinces[target].name, "captured" if result.attacker_won else "repulsed"])
		elif target == "":
			# Interior hosts march toward the nearest border through friendly land.
			var next_step: String = _route_to_front(source, faction_id)
			if next_step != "":
				move_army(source, next_step, faction_id)

func _route_to_front(source: String, fid: String) -> String:
	var queue: Array = [source]
	var first_step: Dictionary = {source: ""}
	while not queue.is_empty():
		var pid: String = queue.pop_front()
		for neighbor in provinces[pid].neighbors:
			if provinces[neighbor].owner != fid:
				if pid != source:
					return first_step[pid]
			elif not first_step.has(neighbor):
				first_step[neighbor] = neighbor if pid == source else first_step[pid]
				queue.append(neighbor)
	return ""

func save_game(path: String = "user://savegame.json") -> bool:
	if current_state == GameState.BATTLE or _processing_turn:
		return false
	var save_data = {
		"version": 2,
		"turn": turn,
		"current_faction": current_faction,
		"current_scenario": current_scenario,
		"provinces": provinces,
		"factions": factions,
	}
	var file = FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		return false
	file.store_string(JSON.stringify(save_data, "\t"))
	file.close()
	return true

func load_game(path: String = "user://savegame.json") -> bool:
	if current_state == GameState.BATTLE or _processing_turn:
		return false
	if not FileAccess.file_exists(path):
		return false
	var file = FileAccess.open(path, FileAccess.READ)
	if file == null:
		return false
	var json = JSON.new()
	var err = json.parse(file.get_as_text())
	file.close()
	if err != OK:
		return false
	var data: Variant = json.data
	if not _valid_save(data):
		return false
	# Commit only after the entire save has passed validation.
	turn = int(data.get("turn", 1))
	current_faction = data.current_faction
	current_scenario = data.get("current_scenario", "full_campaign")
	provinces = data.provinces
	factions = data.factions
	for fid in factions:
		factions[fid]["color"] = Palette.get_faction_color(fid)
		factions[fid]["is_player"] = fid == current_faction
	for p in provinces.values():
		if p.army != null:
			p.army["moves_left"] = clampi(int(p.army.get("moves_left", army_movement(p.army))), 0, army_movement(p.army))
	battle_context.clear()
	campaign_log.clear()
	current_state = GameState.CAMPAIGN
	state_changed.emit("campaign")
	campaign_loaded.emit()
	evaluate_campaign()
	return true

func _valid_save(data: Variant) -> bool:
	if not data is Dictionary or not data.get("provinces") is Dictionary or not data.get("factions") is Dictionary:
		return false
	if not data.get("turn", 1) is float and not data.get("turn", 1) is int:
		return false
	if data.get("turn", 1) < 1 or not data.factions.has(data.get("current_faction", "")):
		return false
	var scenario: String = str(data.get("current_scenario", "full_campaign"))
	if scenario not in ["full_campaign", "checkpoint_slice"] or data.provinces.size() != (3 if scenario == "checkpoint_slice" else 12):
		return false
	var required_provinces: Array = ["sarai", "crossroads", "sarkel"] if scenario == "checkpoint_slice" else ["sarai", "kipchak", "kiev", "moscow", "novgorod", "tabriz", "samarkand", "bukhara", "karakorum", "zhongdu", "shangdu", "urgench"]
	var required_factions: Array = ["mongol", "rus", "neutral"] if scenario == "checkpoint_slice" else ["mongol", "rus", "cuman", "byzantine", "seljuk", "khwarazm"]
	for pid in required_provinces:
		if not data.provinces.has(pid):
			return false
	if data.factions.size() != required_factions.size():
		return false
	for fid in required_factions:
		if not data.factions.has(fid):
			return false
	if scenario == "checkpoint_slice" and data.current_faction != "mongol":
		return false
	for fid in data.factions:
		var f: Variant = data.factions[fid]
		if not f is Dictionary:
			return false
		for key in ["id", "name", "is_defeated", "gold", "food", "wood"]:
			if not f.has(key):
				return false
		if f.id != fid or not f.name is String or not f.is_defeated is bool:
			return false
		for key in ["bonus_attack", "bonus_defense", "bonus_movement"]:
			if f.has(key) and (not _nonnegative_number(f[key]) or f[key] <= 0):
				return false
		for key in ["gold", "food", "wood"]:
			if not _nonnegative_number(f[key]):
				return false
	for pid in data.provinces:
		var p: Variant = data.provinces[pid]
		if not p is Dictionary:
			return false
		for key in ["id", "name", "x", "z", "owner", "neighbors", "army", "buildings", "defense_bonus", "is_capital", "income_gold", "income_food", "income_wood"]:
			if not p.has(key):
				return false
		if p.id != pid or not p.name is String or not p.is_capital is bool:
			return false
		if not p.neighbors is Array or not p.buildings is Array or not data.factions.has(p.owner):
			return false
		for key in ["defense_bonus", "income_gold", "income_food", "income_wood"]:
			if not _nonnegative_number(p[key]):
				return false
		if not (p.x is float or p.x is int) or not (p.z is float or p.z is int):
			return false
		if not is_finite(float(p.x)) or not is_finite(float(p.z)):
			return false
		for neighbor in p.neighbors:
			if not data.provinces.has(neighbor) or not data.provinces[neighbor] is Dictionary or not data.provinces[neighbor].get("neighbors") is Array:
				return false
			if pid not in data.provinces[neighbor].neighbors:
				return false
		if p.army != null:
			if not p.army is Dictionary or p.army.get("faction") != p.owner or not p.army.get("units") is Array:
				return false
			for unit in p.army.units:
				if not unit is Dictionary or not unit.get("type") is String or get_unit_stats(unit.type).is_empty() or not _nonnegative_number(unit.get("count")):
					return false
			if p.army.has("moves_left") and not _nonnegative_number(p.army.moves_left):
				return false
	return true

func _nonnegative_number(value: Variant) -> bool:
	return (value is int or value is float) and is_finite(float(value)) and value >= 0
