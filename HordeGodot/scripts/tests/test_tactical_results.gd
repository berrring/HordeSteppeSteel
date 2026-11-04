extends SceneTree
const GM = preload("res://scripts/core/game_manager.gd")
const Battle = preload("res://scripts/combat/tactical_battle.gd")
var checks: int = 0
var failed: int = 0
func verify(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failed += 1
		push_error(message)
func _init() -> void:
	call_deferred("run")
func run() -> void:
	var gm = GM.new()
	root.add_child(gm)
	for victory in [true, false]:
		gm.start_new_campaign("mongol", "checkpoint_slice")
		gm.factions.mongol.bonus_attack = 100.0 if victory else 0.0
		gm.provinces.sarai.army.units = [{"type": "infantry", "count": 1}, {"type": "infantry", "count": 100}]
		var original: Dictionary = gm.provinces.duplicate(true)
		var battle = Battle.new()
		root.add_child(battle)
		battle.setup_battle("sarai", "crossroads", gm)
		var result: Dictionary = battle.calculated_result.duplicate(true)
		verify(result.attacker_won == victory, "Forced outcome")
		original.sarai.army["moves_left"] = 0
		verify(gm.provinces == original, "Battle reservation spends movement without applying casualties early")
		battle._on_autoresolve_pressed()
		for i in range(battle.attacker_squads.size()):
			verify(battle.attacker_squads[i].count == result.attacker_stack_counts[i], "Displayed attackers match exact stack losses")
		for i in range(battle.defender_squads.size()):
			verify(battle.defender_squads[i].count == result.defender_stack_counts[i], "Displayed defenders match calculation")
		var emissions: Array = []
		battle.battle_completed.connect(func(payload): emissions.append(payload))
		# Result must not be inferred from translated UI text.
		battle.lbl_result_title.text = "Translated battle report"
		battle._on_finish_battle_clicked()
		battle._on_finish_battle_clicked()
		verify(emissions.size() == 1 and emissions[0] == result, "Structured result emitted once")
		var army = gm.provinces.crossroads.army if victory else gm.provinces.sarai.army
		verify(army.units == result.surviving_attackers, "Authoritative survivors equal report")
		verify(gm.provinces.crossroads.owner == ("mongol" if victory else "neutral"), "Province ownership reflects result")
		if victory:
			verify(gm.factions.neutral.is_defeated, "Eliminated faction flagged")
			verify(gm.provinces.crossroads.defense_bonus == 0, "Tactical capture preserves fortification damage")
		await process_frame
	gm.start_new_campaign("mongol", "checkpoint_slice")
	var retreat = Battle.new()
	root.add_child(retreat)
	retreat.setup_battle("sarai", "crossroads", gm)
	retreat._on_retreat_pressed()
	verify(not retreat.calculated_result.attacker_won, "Retreat yields defender victory")
	verify(retreat.calculated_result.surviving_defenders == gm.provinces.crossroads.army.units, "Retreat preserves defenders")
	retreat._on_finish_battle_clicked()
	verify(gm.provinces.sarai.army != null and gm.provinces.crossroads.owner == "neutral", "Retreat retains source army and ownership")
	await process_frame
	# Verify normal animation reaches the same endpoint without skipping.
	gm.start_new_campaign("mongol", "checkpoint_slice")
	gm.provinces.crossroads.army = null
	var animated = Battle.new()
	root.add_child(animated)
	animated.setup_battle("sarai", "crossroads", gm)
	verify(animated.defender_squads.is_empty(), "No invented militia for null defender")
	await create_timer(2.5).timeout
	verify(animated.result_modal.visible, "Animation finishes")
	verify(animated.attacker_squads[0].count == animated.calculated_result.attacker_stack_counts[0], "Animated casualties match result")
	animated.free()
	gm.free()
	print("Tactical results: ", checks, " checks, failures: ", failed)
	quit(1 if failed else 0)
