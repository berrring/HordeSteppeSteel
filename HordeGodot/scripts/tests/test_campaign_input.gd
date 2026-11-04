extends SceneTree

# Route real viewport events through 3D physics picking and HUD button input.
func _init():
	call_deferred("run")
func click(pos: Vector2):
	var motion := InputEventMouseMotion.new()
	motion.position = pos
	root.push_input(motion, true)
	await physics_frame
	var down := InputEventMouseButton.new()
	down.button_index = MOUSE_BUTTON_LEFT
	down.pressed = true
	down.position = pos
	root.push_input(down, true)
	await physics_frame
	var up := InputEventMouseButton.new()
	up.button_index = MOUSE_BUTTON_LEFT
	up.pressed = false
	up.position = pos
	root.push_input(up, true)
	await physics_frame
	await process_frame
func run():
	root.size = Vector2i(1280, 720)
	var gm = root.get_node("GameManager")
	gm.start_new_campaign("mongol", "checkpoint_slice")
	var controller = load("res://scripts/core/campaign_controller.gd").new()
	root.add_child(controller)
	controller.camera_rig.focus_on(Vector3(0,0,0), 16)
	await create_timer(1).timeout
	var source = controller.map_3d.province_nodes.sarai
	var point = controller.camera_rig.camera.unproject_position(source.global_position + Vector3(0, 0.12, 0))
	await click(point)
	print("INPUT source selection: ", controller.map_3d.current_selected_pid)
	var target = controller.map_3d.province_nodes.crossroads
	point = controller.camera_rig.camera.unproject_position(target.global_position + Vector3(0, 0.12, 0))
	await click(point)
	print("INPUT destination prompt: ", controller.hud.attack_target_pid)
	var ok: bool = controller.map_3d.current_selected_pid == "sarai" and controller.hud.attack_target_pid == "crossroads"
	await click(controller.hud.btn_confirm_attack.get_global_rect().get_center())
	await create_timer(1.2).timeout
	print("INPUT confirm opens battle: ", controller.has_node("ActiveBattle"))
	ok = ok and controller.has_node("ActiveBattle")
	print("Campaign input: ", "PASS" if ok else "FAIL")
	quit(0 if ok else 1)
