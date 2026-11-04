extends SceneTree

# Optional rendered smoke check. Run without --headless and provide a writable
# output directory after --. Does not change campaign data or project settings.
const Rig = preload("res://scripts/camera/strategic_camera.gd")
const Map = preload("res://scripts/map/campaign_map_3d.gd")

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	if DisplayServer.get_name() == "headless":
		print("SKIP rendered check: requires a rendering display driver")
		quit()
		return
	var args: PackedStringArray = OS.get_cmdline_user_args()
	if args.is_empty():
		push_error("Provide an output directory after --")
		quit(1)
		return
	var output: String = args[0]
	DirAccess.make_dir_recursive_absolute(output)
	root.size = Vector2i(1280, 720)
	var world := Node3D.new()
	root.add_child(world)
	var light := DirectionalLight3D.new()
	light.rotation_degrees = Vector3(-55, -35, 0)
	light.light_energy = 1.1
	world.add_child(light)
	var environment := WorldEnvironment.new()
	environment.environment = Environment.new()
	environment.environment.background_mode = Environment.BG_COLOR
	environment.environment.background_color = preload("res://scripts/visuals/model_builder.gd").BLUE
	environment.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.environment.ambient_light_color = preload("res://scripts/visuals/model_builder.gd").WHITE
	environment.environment.ambient_light_energy = 0.65
	world.add_child(environment)
	var gm = root.get_node("GameManager")
	gm.start_new_campaign("mongol", "checkpoint_slice")
	var map := Map.new()
	world.add_child(map)
	map.build_map(gm.provinces)
	map.select_province("crossroads")
	var rig := Rig.new()
	world.add_child(rig)
	rig.focus_on(Vector3(0.75, 0, 0.5), 14.0)
	for i: int in range(30):
		await process_frame
	await capture(output.path_join("checkpoint_perspective.png"))
	rig.toggle_projection()
	await capture(output.path_join("checkpoint_orthographic.png"))
	gm.start_new_campaign("mongol", "full_campaign")
	map.build_map(gm.provinces)
	rig.focus_on(Vector3.ZERO, 24.0)
	for i: int in range(30):
		await process_frame
	await capture(output.path_join("full_campaign.png"))
	quit()

func capture(path: String) -> void:
	await RenderingServer.frame_post_draw
	var image: Image = root.get_texture().get_image()
	var result: Error = image.save_png(path)
	if result != OK:
		push_error("Could not save rendered check: " + path)
		quit(1)
	print("RENDERED ", path)
