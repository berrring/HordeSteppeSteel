class_name StrategicAI
extends RefCounted

const Calculator = preload("res://scripts/combat/battle_calculator.gd")

# Pure decision service: turn orchestration owns income and recruitment.
func choose_counterattack(scenario: String, player: String, provinces: Dictionary, factions: Dictionary, faction_id: String = "rus") -> Dictionary:
	if scenario != "checkpoint_slice" or faction_id != "rus" or player == "rus":
		return {}
	if not provinces.has("sarkel") or not provinces.has("crossroads") or not factions.has("rus"):
		return {}
	if factions.rus.get("is_defeated", false):
		return {}
	var source: Dictionary = provinces.sarkel
	var target: Dictionary = provinces.crossroads
	if source.owner != "rus" or target.owner != player or player == "neutral":
		return {}
	if not "crossroads" in source.get("neighbors", []) or source.army == null:
		return {}
	if source.army.get("faction", "") != "rus":
		return {}
	var calculator := Calculator.new()
	var attack: float = calculator.army_strength(source.army) * factions.rus.get("bonus_attack", 1.0)
	var defense: float = (calculator.army_strength(target.army) + target.get("defense_bonus", 0) * Calculator.FORTIFICATION_SCALE) * factions.get(player, {}).get("bonus_defense", 1.0)
	if attack <= 0 or attack < defense:
		return {}
	return {"attacker_pid": "sarkel", "defender_pid": "crossroads"}
