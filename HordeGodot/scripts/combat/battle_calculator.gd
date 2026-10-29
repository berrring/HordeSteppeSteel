class_name BattleCalculator
extends RefCounted

const FORTIFICATION_SCALE: float = 10.0

func army_strength(army: Variant) -> int:
	if not army is Dictionary:
		return 0
	var total: int = 0
	for unit in army.get("units", []):
		total += maxi(0, int(unit.get("count", 0)))
	return total

# A supplied RNG makes replay and tests deterministic without changing global RNG.
func calculate(attacker: Variant, defender: Variant, defense_bonus: float = 0.0,
		attack_bonus: float = 1.0, defense_multiplier: float = 1.0,
		rng: RandomNumberGenerator = null) -> Dictionary:
	var random := rng
	if random == null:
		random = RandomNumberGenerator.new()
		random.randomize()
	var attack_roll: float = army_strength(attacker) * attack_bonus * random.randf_range(0.7, 1.3)
	var defense_roll: float = (army_strength(defender) + defense_bonus * FORTIFICATION_SCALE) * defense_multiplier * random.randf_range(0.7, 1.3)
	var won: bool = army_strength(attacker) > 0 and attack_roll > defense_roll
	return {
		"winner": "attacker" if won else "defender",
		"attacker_won": won,
		"surviving_attackers": _survivors(attacker, 0.7 if won else 0.4, 0.95 if won else 0.7, 1 if won else 0, random),
		"surviving_defenders": _survivors(defender, 0.1 if won else 1.0, 0.4 if won else 1.0, 0, random),
	}

func _survivors(army: Variant, low: float, high: float, minimum: int, rng: RandomNumberGenerator) -> Array:
	var survivors: Array = []
	if not army is Dictionary:
		return survivors
	for original in army.get("units", []):
		var unit: Dictionary = original.duplicate(true)
		var count: int = maxi(0, int(unit.get("count", 0)))
		unit["count"] = mini(count, maxi(minimum, int(count * rng.randf_range(low, high))))
		if unit.count > 0:
			survivors.append(unit)
	return survivors
