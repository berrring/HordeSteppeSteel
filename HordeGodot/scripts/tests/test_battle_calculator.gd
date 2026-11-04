extends SceneTree

const Calculator = preload("res://scripts/combat/battle_calculator.gd")
var checks: int = 0
var failed: int = 0

func verify(condition: bool, message: String) -> void:
	checks += 1
	if not condition:
		push_error(message)
		failed += 1

func _init() -> void:
	var calculator := Calculator.new()
	verify(calculator.army_strength(null) == 0, "Null army")
	verify(calculator.army_strength({"units": [{"count": 12}, {"count": 8}]}) == 20, "Strength sums counts")
	var army: Dictionary = {"faction": "mongol", "units": [{"type": "infantry", "count": 100}]}
	var snapshot: Dictionary = army.duplicate(true)
	var rng := RandomNumberGenerator.new()
	for seed_value in range(100):
		rng.seed = seed_value
		var win: Dictionary = calculator.calculate(army, null, 0, 1, 1, rng)
		verify(win.attacker_won and win.surviving_defenders.is_empty(), "Undefended victory")
		verify(win.surviving_attackers[0].count >= 70 and win.surviving_attackers[0].count <= 95, "Winning retention")
		rng.seed = seed_value
		var loss: Dictionary = calculator.calculate(army, army, 1000, 1, 1, rng)
		verify(not loss.attacker_won and loss.surviving_defenders == army.units, "Defender retains army")
		verify(loss.surviving_attackers[0].count >= 40 and loss.surviving_attackers[0].count <= 70, "Losing retention")
		var weak: Dictionary = {"units": [{"type": "infantry", "count": 1}]}
		var routed: Dictionary = calculator.calculate(army, weak, 0, 100, 1, rng)
		verify(routed.attacker_won and routed.surviving_defenders.is_empty(), "Small stack rounding")
	verify(army == snapshot, "Pure calculation leaves input unchanged")
	rng.seed = 42
	var replay: Dictionary = calculator.calculate(army, army, 2, 1.2, 1.1, rng)
	rng.seed = 42
	verify(replay == calculator.calculate(army, army, 2, 1.2, 1.1, rng), "Seeded replay")
	print("Battle calculator: ", checks, " checks, failures: ", failed)
	quit(1 if failed else 0)
