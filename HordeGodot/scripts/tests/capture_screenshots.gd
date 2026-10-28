extends SceneTree

# Screenshot capture script
func _init():
	print("Starting screenshot capture...")
	_run_capture()

func _run_capture():
	DirAccess.make_dir_absolute("res://screenshots")
	
	# Step 1: Capture Main Menu
	print("Capturing Main Menu...")
	var menu = load("res://scenes/main_menu/main_menu.tscn").instantiate()
	root.add_child(menu)
	
	# Render several frames to ensure materials, shaders, and diorama are fully uploaded
	for f in range(20):
		await process_frame
		
	var img_menu = root.get_viewport().get_texture().get_image()
	if img_menu:
		img_menu.save_png("res://screenshots/main_menu.png")
		print("Saved res://screenshots/main_menu.png")
	menu.free()
	
	# Step 2: Capture Campaign Map View
	print("Capturing Campaign View...")
	var gm = root.get_node_or_null("GameManager")
	if gm == null:
		var GMClass = load("res://scripts/core/game_manager.gd")
		gm = GMClass.new()
		gm.name = "GameManager"
		root.add_child(gm)
	gm.start_new_campaign()
	
	var camp = load("res://scenes/campaign/campaign_view.tscn").instantiate()
	root.add_child(camp)
	
	for f in range(25):
		await process_frame
		
	var img_camp = root.get_viewport().get_texture().get_image()
	if img_camp:
		img_camp.save_png("res://screenshots/campaign_map.png")
		print("Saved res://screenshots/campaign_map.png")
		
	# Select a province to show selection ring and path
	if camp.map_3d:
		camp.map_3d.select_province("sarai")
		
	for f in range(15):
		await process_frame
		
	var img_selected = root.get_viewport().get_texture().get_image()
	if img_selected:
		img_selected.save_png("res://screenshots/campaign_selection.png")
		print("Saved res://screenshots/campaign_selection.png")
		
	camp.free()
	
	# Step 3: Capture Tactical Battle Scene
	print("Capturing Tactical Battle Scene...")
	var battle = load("res://scenes/combat/tactical_battle.tscn").instantiate()
	root.add_child(battle)
	battle.setup_battle("sarai", "kiev", gm)
	
	for f in range(25):
		await process_frame
		
	var img_battle = root.get_viewport().get_texture().get_image()
	if img_battle:
		img_battle.save_png("res://screenshots/tactical_battle.png")
		print("Saved res://screenshots/tactical_battle.png")
	battle.free()
	
	if gm:
		gm.free()
		
	print("All screenshots successfully captured!")
	quit(0)
