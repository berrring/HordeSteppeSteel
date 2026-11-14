extends SceneTree
const Controller = preload("res://scripts/core/campaign_controller.gd")
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
	var gm = root.get_node("GameManager")
	gm.start_new_campaign("rus")
	var controller = Controller.new()
	root.add_child(controller)
	var release := InputEventMouseButton.new()
	release.button_index = MOUSE_BUTTON_RIGHT
	release.pressed = false
	controller.camera_rig.is_dragging = true
	controller.camera_rig._input(release)
	verify(not controller.camera_rig.is_dragging, "Releasing drag over HUD cannot leave camera stuck")
	var hud = controller.hud
	var map = controller.map_3d
	map.select_province("moscow")
	verify(hud.selected_pid == "moscow", "Map and HUD selection synchronized")
	verify(map.province_nodes.moscow.army_label_3d.visible and "80" in map.province_nodes.moscow.army_label_3d.text, "Initial army count visible")
	verify(map.province_nodes.kipchak.is_targetable, "Rus can target neighboring Mongol territory")
	verify(map.province_nodes.novgorod.is_targetable, "Friendly neighboring destination highlighted")
	hud.prompt_attack("moscow", "novgorod")
	verify(hud.attack_container.visible and hud.btn_confirm_attack.text == "MARCH / MERGE", "Friendly march confirmation")
	var total: int = gm.get_army_strength(gm.provinces.moscow.army) + gm.get_army_strength(gm.provinces.novgorod.army)
	hud._on_confirm_attack_pressed()
	verify(controller.commands_busy and map.orders_locked and hud.btn_end_turn.disabled, "March locks other commands")
	var turn_before: int = gm.turn
	controller._on_end_turn()
	controller._on_attack("kiev", "sarai")
	verify(gm.turn == turn_before and not controller.has_node("ActiveBattle"), "Cannot advance turn or queue attack during march")
	await create_timer(1.2).timeout
	verify(not controller.commands_busy and gm.provinces.moscow.army == null, "March completes and unlocks")
	verify(gm.get_army_strength(gm.provinces.novgorod.army) == total, "Actual HUD march conserves soldiers")
	verify(map.current_selected_pid == "novgorod" and hud.selected_pid == "novgorod", "Destination selected on arrival")
	map.select_province("kiev")
	gm.factions.rus.wood = 1000
	controller._on_construct("town_center")
	controller._on_construct("town_center")
	verify(gm.provinces.kiev.buildings.count("town_center") == 1 and gm.factions.rus.wood == 880, "Controller rejects duplicate construction")
	hud._on_help_pressed()
	controller._on_end_turn()
	verify(gm.turn == turn_before, "Modal prevents end turn")
	hud.hide_modals()
	await process_frame
	await process_frame
	verify(not hud.btn_end_turn.disabled, "Closing help restores action buttons")
	gm.start_new_campaign("mongol", "checkpoint_slice")
	controller._on_campaign_loaded()
	await process_frame
	verify(map.province_nodes.size() == 3 and is_instance_valid(map.movement_path), "Scenario reload rebuilds map and retains path renderer")
	map.select_province("sarai")
	gm.factions.mongol.bonus_attack = 100.0
	var old_settlement = map.province_nodes.crossroads.settlement_node
	controller._on_attack("sarai", "crossroads")
	verify(controller.commands_busy and gm.current_state == gm.GameState.BATTLE, "Attack reserves state before march animation")
	controller._on_attack("sarai", "crossroads")
	controller._on_recruit("infantry")
	controller._on_end_turn()
	await create_timer(1.2).timeout
	var battle = controller.get_node_or_null("ActiveBattle")
	verify(battle != null, "March opens tactical battle")
	if battle != null:
		battle._on_autoresolve_pressed()
		battle._on_finish_battle_clicked()
	await process_frame
	verify(not controller.commands_busy and hud.visible and gm.current_state == gm.GameState.CAMPAIGN, "Battle returns to campaign and restores input")
	verify(map.province_nodes.crossroads.settlement_node != old_settlement, "Captured settlement refreshes despite shared campaign dictionary")
	verify(gm.provinces.crossroads.owner == "mongol" and gm.moves_left(gm.provinces.crossroads.army) == 0, "Capture spends movement")
	verify(map.current_selected_pid == "crossroads" and hud.selected_pid == "crossroads", "Capture keeps HUD and map synchronized")
	var save_path: String = "user://campaign_flow_test.json"
	verify(gm.save_game(save_path), "Save completed campaign action")
	gm.start_new_campaign("seljuk")
	controller._on_campaign_loaded()
	verify(map.province_nodes.size() == 12, "Full campaign has all provinces")
	verify(gm.load_game(save_path) and map.province_nodes.size() == 3, "Loading checkpoint immediately rebuilds full campaign map")
	verify(hud.selected_pid == "" and map.current_selected_pid == "", "Load clears stale selections")
	await process_frame
	verify(is_instance_valid(map.movement_path), "Reloaded movement path remains alive next frame")
	DirAccess.remove_absolute(ProjectSettings.globalize_path(save_path))
	controller.free()
	gm.start_new_campaign("mongol", "checkpoint_slice")
	gm.provinces.sarkel.owner = "mongol"
	gm.provinces.sarkel.army = null
	gm.evaluate_campaign()
	var finished = Controller.new()
	root.add_child(finished)
	verify(finished.hud.game_over_modal.visible, "Continuing a finished campaign shows outcome")
	finished.free()
	print("Campaign flow: ", checks, " checks, failures: ", failed)
	quit(1 if failed else 0)
