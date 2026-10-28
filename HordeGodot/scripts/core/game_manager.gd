extends Node

const Palette = preload("res://scripts/core/palette.gd")

signal turn_ended(turn_number: int)
signal province_captured(province_id: String, new_owner: String)
signal faction_defeated(faction_id: String)
signal game_over(is_victory: bool)
signal state_changed(new_state: String)

enum GameState { MAIN_MENU, CAMPAIGN, BATTLE, VICTORY, DEFEAT }

var current_state: GameState = GameState.MAIN_MENU
var turn: int = 1
var max_turns: int = 60
var provinces_to_win: int = 10

# Data containers
var provinces: Dictionary = {}
var factions: Dictionary = {}
var current_faction: String = "mongol"

# Battle context
var battle_context: Dictionary = {}

func _ready():
	pass

func start_new_campaign(chosen_faction: String = "mongol"):
	# Build campaign data
	_build_provinces()
	_build_factions(chosen_faction)
	current_faction = chosen_faction
	turn = 1
	current_state = GameState.CAMPAIGN
	state_changed.emit("campaign")

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
	if army == null:
		return 0
	var total = 0
	for unit in army.units:
		total += unit.count
	return total

func province_count(faction_id: String) -> int:
	var count = 0
	for pid in provinces:
		if provinces[pid].owner == faction_id:
			count += 1
	return count

func check_victory() -> String:
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

func resolve_battle(attacker_pid: String, defender_pid: String) -> Dictionary:
	var att_army = provinces[attacker_pid].army
	var def_army = provinces[defender_pid].army
	var def_bonus = provinces[defender_pid].defense_bonus

	var att_str = get_army_strength(att_army)
	var def_str = get_army_strength(def_army) + def_bonus * 10

	# Apply faction bonuses
	var att_faction = factions.get(att_army.faction, {})
	var att_bonus = att_faction.get("bonus_attack", 1.0)
	var def_faction_id = provinces[defender_pid].owner
	var def_faction = factions.get(def_faction_id, {})
	var def_bonus_mult = def_faction.get("bonus_defense", 1.0) if def_faction else 1.0

	var att_roll = att_str * att_bonus * randf_range(0.7, 1.3)
	var def_roll = def_str * def_bonus_mult * randf_range(0.7, 1.3)

	var result = {}
	if att_roll > def_roll:
		result = {"winner": "attacker", "province": defender_pid}
		# Transfer province
		provinces[defender_pid].owner = att_army.faction
		# Reduce attacker casualties
		for unit in att_army.units:
			unit.count = max(1, int(unit.count * randf_range(0.7, 0.95)))
		# Move army
		provinces[defender_pid].army = att_army
		provinces[attacker_pid].army = null
		# Destroy defender army
		if def_army:
			for unit in def_army.units:
				unit.count = max(0, int(unit.count * randf_range(0.1, 0.4)))
		# Check faction elimination
		if def_faction_id != "" and province_count(def_faction_id) == 0:
			factions[def_faction_id].is_defeated = true
			faction_defeated.emit(def_faction_id)
		province_captured.emit(defender_pid, att_army.faction)
	else:
		result = {"winner": "defender", "province": defender_pid}
		# Attacker takes heavy casualties
		for unit in att_army.units:
			unit.count = max(0, int(unit.count * randf_range(0.4, 0.7)))
		# Remove dead units
		var alive_units = []
		for unit in att_army.units:
			if unit.count > 0:
				alive_units.append(unit)
		att_army.units = alive_units
		if att_army.units.is_empty():
			provinces[attacker_pid].army = null
	return result

func end_turn():
	# Player income
	collect_income(current_faction)
	turn += 1
	# AI turns
	_run_ai_turns()
	# Check conditions
	var result = check_victory()
	if result == "win":
		current_state = GameState.VICTORY
		game_over.emit(true)
	elif result == "lose":
		current_state = GameState.DEFEAT
		game_over.emit(false)
	turn_ended.emit(turn)

func _run_ai_turns():
	for fid in factions:
		if fid == current_faction or factions[fid].is_defeated:
			continue
		_ai_turn(fid)

func _ai_turn(faction_id: String):
	# Collect income
	collect_income(faction_id)
	# Recruit at capital
	_ai_recruit(faction_id)
	# Attack weakest neighbor
	_ai_attack(faction_id)

func _ai_recruit(faction_id: String):
	var capital_pid = ""
	for pid in provinces:
		if provinces[pid].owner == faction_id and provinces[pid].is_capital:
			capital_pid = pid
			break
	if capital_pid == "":
		# Use any owned province
		for pid in provinces:
			if provinces[pid].owner == faction_id:
				capital_pid = pid
				break
	if capital_pid == "" or factions[faction_id].gold < 100:
		return
	var army = provinces[capital_pid].army
	if army == null:
		army = {"faction": faction_id, "units": []}
		provinces[capital_pid].army = army
	var unit_type = "infantry" if factions[faction_id].gold < 250 else "horse_archer"
	var stats = get_unit_stats(unit_type)
	if factions[faction_id].gold >= stats.cost_gold:
		army.units.append({"type": unit_type, "count": 50})
		factions[faction_id].gold -= stats.cost_gold

func _ai_attack(faction_id: String):
	var owned = []
	for pid in provinces:
		if provinces[pid].owner == faction_id and provinces[pid].army != null:
			owned.append(pid)
	for src_pid in owned:
		var army = provinces[src_pid].army
		if army == null or army.units.is_empty():
			continue
		var our_str = get_army_strength(army)
		var best_target = ""
		var best_str = 999999
		for neighbor_pid in provinces[src_pid].neighbors:
			if provinces[neighbor_pid].owner == faction_id:
				continue
			var their_str = get_army_strength(provinces[neighbor_pid].army)
			if their_str < best_str:
				best_str = their_str
				best_target = neighbor_pid
		if best_target != "" and our_str > best_str:
			resolve_battle(src_pid, best_target)

func save_game(path: String = "user://savegame.json") -> bool:
	var save_data = {
		"turn": turn,
		"current_faction": current_faction,
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
	var data = json.data
	turn = data.get("turn", 1)
	current_faction = data.get("current_faction", "mongol")
	provinces = data.get("provinces", {})
	factions = data.get("factions", {})
	current_state = GameState.CAMPAIGN
	state_changed.emit("campaign")
	return true
