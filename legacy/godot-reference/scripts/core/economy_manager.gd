class_name EconomyManager
extends RefCounted

## ==============================================================================
## HORDE: STEPPE & STEEL — STATELESS ECONOMY VALIDATION SERVICE
## ==============================================================================
## Author: Ayaz (Subsystem: Economy Validation & UI Presentation)
##
## RefCounted service owning zero campaign state.
## Pure validation helper preventing race conditions, UI desynchronization,
## illegal construction, and double-spending across campaign turns.
## ==============================================================================

# Verified Building Data (Source of Truth: campaign_controller.gd:238-303)
const BUILDINGS: Dictionary = {
	"town_center": {
		"id": "town_center",
		"name": "Town Center",
		"wood_cost": 120,
		"income_gold": 40,
		"income_food": 20,
		"defense_bonus": 0,
		"description": "Primary settlement center. Yields +40 Gold and +20 Food per turn."
	},
	"barracks": {
		"id": "barracks",
		"name": "Barracks",
		"wood_cost": 100,
		"income_gold": 0,
		"income_food": 0,
		"defense_bonus": 15,
		"description": "Drill grounds and armory. Fortifies defenses (+15)."
	},
	"stables": {
		"id": "stables",
		"name": "Stables",
		"wood_cost": 80,
		"income_gold": 0,
		"income_food": 40,
		"defense_bonus": 0,
		"description": "Horse breeding paddocks. Produces +40 Food per turn."
	},
	"fortification": {
		"id": "fortification",
		"name": "Fortifications",
		"wood_cost": 100,
		"income_gold": 0,
		"income_food": 0,
		"defense_bonus": 20,
		"description": "Log ramparts and watchtowers. Grants +20 defense bonus to garrisons."
	},
	"palisade": {
		"id": "palisade",
		"name": "Palisade",
		"wood_cost": 80,
		"income_gold": 0,
		"income_food": 0,
		"defense_bonus": 10,
		"description": "Timber stockade rampart. Grants +10 defense bonus to defending garrison forces."
	},
	"pasture": {
		"id": "pasture",
		"name": "Pasture",
		"wood_cost": 80,
		"income_gold": 0,
		"income_food": 40,
		"defense_bonus": 0,
		"description": "Seasonal grazing pastures. Produces +40 Food per turn."
	},
	"market": {
		"id": "market",
		"name": "Market",
		"wood_cost": 120,
		"income_gold": 50,
		"income_food": 0,
		"defense_bonus": 0,
		"description": "Steppe trading bazaar. Produces +50 Gold per turn."
	}
}

# Standard recruitment costs and stats
const UNITS: Dictionary = {
	"horse_archer": {"name": "Horse Archer", "cost_gold": 150, "cost_food": 50},
	"light_cavalry": {"name": "Light Cavalry", "cost_gold": 120, "cost_food": 40},
	"heavy_cavalry": {"name": "Heavy Cavalry", "cost_gold": 250, "cost_food": 80},
	"infantry": {"name": "Infantry", "cost_gold": 100, "cost_food": 30},
	"spearman": {"name": "Spearman", "cost_gold": 110, "cost_food": 35},
	"siege": {"name": "Siege Engine", "cost_gold": 300, "cost_food": 20}
}

## Validates building eligibility without mutating campaign state.
## Enforces:
##  1. Building type existence
##  2. Valid province and faction structures
##  3. Province territorial control (ownership)
##  4. Strict uniqueness (cannot build duplicate buildings in the same province)
##  5. Sufficient wood availability in faction treasury
##
## Returns: {"allowed": bool, "reason": String}
static func can_build(province_data: Variant, faction_data: Variant, building_type: String) -> Dictionary:
	# 1. Verify building exists in catalog
	if not BUILDINGS.has(building_type):
		return {"allowed": false, "reason": "Unknown building type: '%s'" % building_type}
	
	# 2. Check province structure
	if province_data == null or not (province_data is Dictionary):
		return {"allowed": false, "reason": "Invalid province data"}
	
	# 3. Check faction structure
	if faction_data == null or not (faction_data is Dictionary):
		return {"allowed": false, "reason": "Invalid faction data"}
		
	# 4. Check territorial ownership
	var f_id: String = str(faction_data.get("id", ""))
	var p_owner: String = str(province_data.get("owner", ""))
	if f_id != "" and p_owner != "" and p_owner != f_id:
		return {
			"allowed": false,
			"reason": "Province '%s' is not controlled by faction '%s' (Owner: '%s')" % [
				province_data.get("name", "Unknown"), f_id, p_owner
			]
		}
		
	# 5. Strict uniqueness enforcement: if building_type in province.buildings: return false
	var existing_buildings = province_data.get("buildings", [])
	if building_type in existing_buildings:
		var b_name: String = BUILDINGS[building_type].name
		var prov_name: String = str(province_data.get("name", "province"))
		return {
			"allowed": false,
			"reason": "%s already constructed in %s" % [b_name, prov_name]
		}
		
	# 6. Verify faction has sufficient Wood
	var wood_cost: int = BUILDINGS[building_type].wood_cost
	var available_wood: int = int(faction_data.get("wood", 0))
	if available_wood < wood_cost:
		return {
			"allowed": false,
			"reason": "Insufficient wood: requires %d wood, available %d" % [wood_cost, available_wood]
		}
		
	return {"allowed": true, "reason": "Ready to construct"}

## Validates recruitment affordability without mutating campaign state.
## Enforces gold and food availability in faction treasury.
##
## Returns: {"allowed": bool, "reason": String}
static func can_recruit(faction_data: Variant, unit_stats: Variant) -> Dictionary:
	if faction_data == null or not (faction_data is Dictionary):
		return {"allowed": false, "reason": "Invalid faction data"}
		
	var stats: Dictionary = {}
	if unit_stats is Dictionary:
		stats = unit_stats
	elif unit_stats is String and UNITS.has(unit_stats):
		stats = UNITS[unit_stats]
	else:
		return {"allowed": false, "reason": "Invalid unit statistics"}
		
	var cost_gold: int = int(stats.get("cost_gold", 0))
	var cost_food: int = int(stats.get("cost_food", 0))
	var current_gold: int = int(faction_data.get("gold", 0))
	var current_food: int = int(faction_data.get("food", 0))
	
	if current_gold < cost_gold and current_food < cost_food:
		return {
			"allowed": false,
			"reason": "Insufficient gold and food: requires %dg, %df (available: %dg, %df)" % [
				cost_gold, cost_food, current_gold, current_food
			]
		}
	if current_gold < cost_gold:
		return {
			"allowed": false,
			"reason": "Insufficient gold: requires %dg (available: %dg)" % [cost_gold, current_gold]
		}
	if current_food < cost_food:
		return {
			"allowed": false,
			"reason": "Insufficient food: requires %df (available: %df)" % [cost_food, current_food]
		}
		
	return {"allowed": true, "reason": "Ready to recruit"}

## Get wood cost for a building type
static func get_building_cost(building_type: String) -> int:
	if BUILDINGS.has(building_type):
		return BUILDINGS[building_type].wood_cost
	return -1

## Get full metadata dictionary for a building type
static func get_building_data(building_type: String) -> Dictionary:
	return BUILDINGS.get(building_type, {})

## Get all building definitions
static func get_all_buildings() -> Dictionary:
	return BUILDINGS.duplicate(true)

## Get all recruitment definitions
static func get_all_units() -> Dictionary:
	return UNITS.duplicate(true)
