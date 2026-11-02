extends SceneTree
const AI = preload("res://scripts/ai/strategic_ai.gd")
const GM = preload("res://scripts/core/game_manager.gd")
var failed: int = 0
var checks: int = 0
func verify(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failed += 1
		push_error(message)
func _init() -> void:
	var gm = GM.new()
	gm.start_new_campaign("mongol", "checkpoint_slice")
	var ai := AI.new()
	verify(ai.choose_counterattack(gm.current_scenario, gm.current_faction, gm.provinces, gm.factions).is_empty(), "Do not attack neutral Crossroads")
	gm.provinces.crossroads.owner = "mongol"
	gm.provinces.crossroads.army = {"faction": "mongol", "units": [{"type": "infantry", "count": 1}]}
	var snapshot: Dictionary = gm.factions.duplicate(true)
	verify(not ai.choose_counterattack(gm.current_scenario, gm.current_faction, gm.provinces, gm.factions).is_empty(), "Competitive Rus counterattack")
	verify(gm.factions == snapshot, "Decision does not collect income")
	verify(ai.choose_counterattack("full_campaign", "mongol", gm.provinces, gm.factions).is_empty(), "Checkpoint only")
	verify(ai.choose_counterattack(gm.current_scenario, "mongol", gm.provinces, gm.factions, "neutral").is_empty(), "Neutral never attacks")
	gm.provinces.crossroads.army.units[0].count = 10000
	verify(ai.choose_counterattack(gm.current_scenario, "mongol", gm.provinces, gm.factions).is_empty(), "Avoid stronger defense")
	gm.provinces.crossroads.army = null
	verify(not ai.choose_counterattack(gm.current_scenario, "mongol", gm.provinces, gm.factions).is_empty(), "Null defender")
	gm.factions.rus.gold = 0
	var gold: int = gm.factions.rus.gold
	gm._ai_turn("rus")
	verify(gm.factions.rus.gold == gold + 100 - 100, "AI income collected once before recruitment")
	gm.start_new_campaign("mongol", "checkpoint_slice")
	gm.provinces.crossroads.owner = "mongol"
	gm.provinces.crossroads.army = null
	var crossed: Array = []
	gm.province_captured.connect(func(pid, _fid): crossed.append(pid))
	gm._ai_turn("rus")
	verify(crossed.has("crossroads"), "Turn pipeline executes counterattack")
	gm.free()
	print("Strategic AI: ", checks, " checks, failures: ", failed)
	quit(1 if failed else 0)
