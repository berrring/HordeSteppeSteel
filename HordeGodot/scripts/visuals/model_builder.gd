class_name ModelBuilder
extends RefCounted

const Palette = preload("res://scripts/core/palette.gd")

# Cache materials for high performance and visual consistency
static var _materials: Dictionary = {}
static var _initialized: bool = false

static func get_mat(name: String, color: Color = Color.WHITE, roughness: float = 0.8, metallic: float = 0.0) -> StandardMaterial3D:
	if not _initialized:
		_initialized = true
		_init_materials()
	if not _materials.has(name):
		var mat = StandardMaterial3D.new()
		mat.albedo_color = color
		mat.roughness = roughness
		mat.metallic = metallic
		mat.shading_mode = BaseMaterial3D.SHADING_MODE_PER_PIXEL
		mat.diffuse_mode = BaseMaterial3D.DIFFUSE_LAMBERT
		mat.specular_mode = BaseMaterial3D.SPECULAR_SCHLICK_GGX
		# Gamified miniature rim highlight for crisp low-poly silhouettes
		mat.rim_enabled = true
		mat.rim = 0.42
		mat.rim_tint = 0.35
		_materials[name] = mat
	return _materials[name]

static func _init_materials():
	# Official Canon Five-Color Palette Materials
	# 1. Steppe Green / Olive (#6B8E23)
	get_mat("steppe_grass", Palette.STEPPE_GREEN, 0.85, 0.0)
	get_mat("forest_grass", Palette.STEPPE_GREEN.darkened(0.25), 0.8, 0.0)
	get_mat("arid_steppe", Color(0.74, 0.66, 0.44), 0.9, 0.0)
	get_mat("water", Color(0.18, 0.58, 0.82), 0.12, 0.15)
	get_mat("rock", Color(0.52, 0.52, 0.50), 0.75, 0.05)
	get_mat("rock_dark", Palette.DEEP_STEEL_BLUE.lightened(0.12), 0.8, 0.05)
	get_mat("cliff_bedrock", Color(0.28, 0.22, 0.17), 0.85, 0.0)
	get_mat("dirt_road", Color(0.58, 0.44, 0.28), 0.9, 0.0)
	
	# 2. Wood Brown (#5C4033)
	get_mat("wood_dark", Palette.WOOD_BROWN.darkened(0.25), 0.8, 0.0)
	get_mat("wood_log", Palette.WOOD_BROWN, 0.75, 0.0)
	get_mat("wood_plank", Palette.WOOD_BROWN.lightened(0.28), 0.7, 0.0)
	get_mat("bridge_wood", Palette.WOOD_BROWN.lightened(0.15), 0.75, 0.0)
	get_mat("pedestal_base", Palette.WOOD_BROWN.darkened(0.4), 0.4, 0.25)
	get_mat("straw_thatch", Color(0.82, 0.72, 0.38), 0.85, 0.0)
	
	# 3. Bronze Gold (#DAA520)
	get_mat("gold_ornament", Palette.BRONZE_GOLD, 0.25, 0.9)
	get_mat("bronze", Palette.BRONZE_GOLD.darkened(0.12), 0.35, 0.8)
	get_mat("flower_yellow", Palette.BRONZE_GOLD, 0.5, 0.0)
	
	# 4. Snow White / Light Gray (#E8ECEF)
	get_mat("snow", Palette.SNOW_WHITE, 0.65, 0.0)
	get_mat("birch_bark", Palette.SNOW_WHITE.darkened(0.04), 0.55, 0.0)
	get_mat("yurt_felt", Palette.SNOW_WHITE.darkened(0.06), 0.85, 0.0)
	get_mat("horse_grey", Palette.SNOW_WHITE.darkened(0.12), 0.7, 0.0)
	get_mat("flower_white", Palette.SNOW_WHITE, 0.5, 0.0)
	
	# 5. Deep Steel Blue (#2B3A4A)
	get_mat("steel", Color(0.80, 0.82, 0.86), 0.28, 0.9)
	get_mat("steel_dark", Palette.DEEP_STEEL_BLUE, 0.35, 0.85)
	get_mat("iron_dark", Palette.DEEP_STEEL_BLUE.darkened(0.25), 0.4, 0.75)
	
	# Foliage
	get_mat("pine_needles", Palette.STEPPE_GREEN.darkened(0.45), 0.65, 0.0)
	get_mat("oak_leaves", Palette.STEPPE_GREEN.darkened(0.12), 0.7, 0.0)
	get_mat("birch_leaves", Palette.STEPPE_GREEN.lightened(0.22), 0.65, 0.0)
	
	# Factions & Special Effects
	get_mat("yurt_red", Palette.FACTION_RUS, 0.75, 0.0)
	get_mat("flower_red", Palette.FACTION_RUS, 0.5, 0.0)
	get_mat("mongol_leather", Palette.WOOD_BROWN.lightened(0.12), 0.65, 0.0)
	get_mat("horse_brown", Palette.WOOD_BROWN, 0.7, 0.0)
	get_mat("horse_black", Color(0.14, 0.13, 0.12), 0.65, 0.0)
	
	get_mat("faction_mongol", Palette.FACTION_MONGOL, 0.55, 0.1)
	get_mat("faction_cuman", Palette.FACTION_CUMAN, 0.55, 0.1)
	get_mat("faction_rus", Palette.FACTION_RUS, 0.55, 0.1)
	get_mat("faction_byzantine", Palette.FACTION_BYZANTINE, 0.55, 0.1)
	get_mat("faction_seljuk", Palette.FACTION_SELJUK, 0.55, 0.1)
	get_mat("faction_khwarazm", Palette.FACTION_KHWARAZM, 0.55, 0.1)
	get_mat("faction_neutral", Palette.FACTION_NEUTRAL, 0.65, 0.05)
	
	var ember = get_mat("ember_glow", Color(1.0, 0.48, 0.12), 0.2, 0.0)
	ember.emission_enabled = true
	ember.emission = Color(1.0, 0.52, 0.15)
	ember.emission_energy_multiplier = 2.4


# -------------------------------------------------------------
# HELPER: MESH CREATION PRIMITIVES
# -------------------------------------------------------------
static func _add_box(parent: Node3D, size: Vector3, pos: Vector3, mat: Material, rot: Vector3 = Vector3.ZERO) -> MeshInstance3D:
	var mi = MeshInstance3D.new()
	var mesh = BoxMesh.new()
	mesh.size = size
	mi.mesh = mesh
	mi.material_override = mat
	mi.position = pos
	if rot != Vector3.ZERO:
		mi.rotation_degrees = rot
	parent.add_child(mi)
	return mi

static func _add_cylinder(parent: Node3D, top_rad: float, bot_rad: float, height: float, pos: Vector3, mat: Material, radial_seg: int = 8) -> MeshInstance3D:
	var mi = MeshInstance3D.new()
	var mesh = CylinderMesh.new()
	mesh.top_radius = top_rad
	mesh.bottom_radius = bot_rad
	mesh.height = height
	mesh.radial_segments = radial_seg
	mi.mesh = mesh
	mi.material_override = mat
	mi.position = pos
	parent.add_child(mi)
	return mi

static func _add_sphere(parent: Node3D, radius: float, pos: Vector3, mat: Material, rings: int = 6, radial: int = 8) -> MeshInstance3D:
	var mi = MeshInstance3D.new()
	var mesh = SphereMesh.new()
	mesh.radius = radius
	mesh.height = radius * 2.0
	mesh.rings = rings
	mesh.radial_segments = radial
	mi.mesh = mesh
	mi.material_override = mat
	mi.position = pos
	parent.add_child(mi)
	return mi

static func _add_cone(parent: Node3D, base_rad: float, height: float, pos: Vector3, mat: Material, segs: int = 7) -> MeshInstance3D:
	return _add_cylinder(parent, 0.0, base_rad, height, pos, mat, segs)


# -------------------------------------------------------------
# ENVIRONMENT OBJECTS
# -------------------------------------------------------------

# Tree 1: Steppe Conifer / Pine
static func create_pine_tree(scale_factor: float = 1.0) -> Node3D:
	_init_materials()
	var root = Node3D.new()
	root.name = "PineTree"
	
	# Trunk
	_add_cylinder(root, 0.08 * scale_factor, 0.12 * scale_factor, 0.8 * scale_factor, Vector3(0, 0.4 * scale_factor, 0), get_mat("wood_dark"))
	
	# Needle tiers (3 stacked cones)
	_add_cone(root, 0.45 * scale_factor, 0.65 * scale_factor, Vector3(0, 0.7 * scale_factor, 0), get_mat("pine_needles"))
	_add_cone(root, 0.35 * scale_factor, 0.55 * scale_factor, Vector3(0, 1.05 * scale_factor, 0), get_mat("pine_needles"))
	_add_cone(root, 0.22 * scale_factor, 0.45 * scale_factor, Vector3(0, 1.35 * scale_factor, 0), get_mat("pine_needles"))
	
	return root

# Tree 2: Broadleaf / Oak
static func create_oak_tree(scale_factor: float = 1.0) -> Node3D:
	_init_materials()
	var root = Node3D.new()
	root.name = "OakTree"
	
	# Trunk
	_add_cylinder(root, 0.12 * scale_factor, 0.18 * scale_factor, 0.9 * scale_factor, Vector3(0, 0.45 * scale_factor, 0), get_mat("wood_log"))
	
	# Clustered stylized canopy
	var mat_leaf = get_mat("oak_leaves")
	_add_sphere(root, 0.48 * scale_factor, Vector3(0, 1.1 * scale_factor, 0), mat_leaf)
	_add_sphere(root, 0.38 * scale_factor, Vector3(0.2 * scale_factor, 1.25 * scale_factor, 0.15 * scale_factor), mat_leaf)
	_add_sphere(root, 0.35 * scale_factor, Vector3(-0.2 * scale_factor, 1.05 * scale_factor, -0.15 * scale_factor), mat_leaf)
	_add_sphere(root, 0.32 * scale_factor, Vector3(0.05 * scale_factor, 1.4 * scale_factor, -0.1 * scale_factor), mat_leaf)
	
	return root

# Tree 3: Rus' Forest Birch
static func create_birch_tree(scale_factor: float = 1.0) -> Node3D:
	_init_materials()
	var root = Node3D.new()
	root.name = "BirchTree"
	
	# Slender white trunk
	_add_cylinder(root, 0.06 * scale_factor, 0.09 * scale_factor, 1.1 * scale_factor, Vector3(0, 0.55 * scale_factor, 0), get_mat("birch_bark"))
	
	# High light foliage
	var mat_b = get_mat("birch_leaves")
	_add_sphere(root, 0.35 * scale_factor, Vector3(0, 1.2 * scale_factor, 0), mat_b)
	_add_sphere(root, 0.28 * scale_factor, Vector3(0.12 * scale_factor, 1.45 * scale_factor, 0.05 * scale_factor), mat_b)
	
	return root

# Rocks & Boulders
static func create_rock_cluster(scale_factor: float = 1.0) -> Node3D:
	_init_materials()
	var root = Node3D.new()
	root.name = "RockCluster"
	var mat_r = get_mat("rock")
	var mat_rd = get_mat("rock_dark")
	
	_add_box(root, Vector3(0.6, 0.4, 0.5) * scale_factor, Vector3(0, 0.2 * scale_factor, 0), mat_r, Vector3(15, 25, 10))
	_add_box(root, Vector3(0.45, 0.35, 0.4) * scale_factor, Vector3(0.35, 0.15, 0.1) * scale_factor, mat_rd, Vector3(-10, 40, -15))
	_add_box(root, Vector3(0.3, 0.25, 0.3) * scale_factor, Vector3(-0.3, 0.1, -0.2) * scale_factor, mat_r, Vector3(25, -20, 30))
	
	return root

# Steppe Hillock / Elevation
static func create_hill_mesh(width: float, height: float, depth: float) -> Node3D:
	_init_materials()
	var root = Node3D.new()
	root.name = "HillElevation"
	
	# Tiered rounded hill
	_add_cylinder(root, width * 0.4, width * 0.5, height * 0.6, Vector3(0, height * 0.3, 0), get_mat("steppe_grass"), 10)
	_add_cylinder(root, width * 0.2, width * 0.4, height * 0.4, Vector3(0, height * 0.8, 0), get_mat("rock"), 8)
	
	return root

# Farm / Pasture
static func create_pasture_plot(scale_factor: float = 1.0) -> Node3D:
	_init_materials()
	var root = Node3D.new()
	root.name = "Pasture"
	
	# Field base
	_add_box(root, Vector3(1.2, 0.05, 1.2) * scale_factor, Vector3(0, 0.025, 0), get_mat("dirt_road"))
	# Hay bale
	_add_cylinder(root, 0.15 * scale_factor, 0.15 * scale_factor, 0.25 * scale_factor, Vector3(0.3, 0.15, 0.2) * scale_factor, get_mat("straw_thatch"), 6)
	# Wooden fence rails
	_add_box(root, Vector3(1.1, 0.1, 0.04) * scale_factor, Vector3(0, 0.1, 0.55 * scale_factor), get_mat("wood_plank"))
	_add_box(root, Vector3(1.1, 0.1, 0.04) * scale_factor, Vector3(0, 0.1, -0.55 * scale_factor), get_mat("wood_plank"))
	
	return root

# Charming Low-Poly Flower Patch (Gamified flora)
static func create_flower_patch(scale_factor: float = 1.0) -> Node3D:
	_init_materials()
	var root = Node3D.new()
	root.name = "FlowerPatch"
	
	var mat_stem = get_mat("steppe_grass")
	var colors = [get_mat("flower_red"), get_mat("flower_yellow"), get_mat("flower_white")]
	var offsets = [
		Vector3(0, 0, 0), Vector3(0.12, 0, 0.08), Vector3(-0.10, 0, 0.11),
		Vector3(-0.08, 0, -0.09), Vector3(0.09, 0, -0.12)
	]
	for i in range(offsets.size()):
		var p = offsets[i] * scale_factor
		var col = colors[i % colors.size()]
		# Stem
		_add_cylinder(root, 0.012 * scale_factor, 0.015 * scale_factor, 0.14 * scale_factor, p + Vector3(0, 0.07 * scale_factor, 0), mat_stem, 4)
		# Blossom head (faceted low-poly dot)
		_add_sphere(root, 0.038 * scale_factor, p + Vector3(0, 0.15 * scale_factor, 0), col, 4, 4)
	return root

# Cozy Steppe Campfire with Glowing Embers
static func create_campfire(scale_factor: float = 1.0) -> Node3D:
	_init_materials()
	var root = Node3D.new()
	root.name = "Campfire"
	
	var mat_rock = get_mat("rock")
	var mat_log = get_mat("wood_dark")
	var mat_ember = get_mat("ember_glow")
	
	# Circular ring of 6 small stones
	for i in range(6):
		var ang = (i / 6.0) * TAU
		var sp = Vector3(cos(ang) * 0.22, 0.04, sin(ang) * 0.22) * scale_factor
		_add_box(root, Vector3(0.08, 0.07, 0.08) * scale_factor, sp, mat_rock, Vector3(10, i * 45, -15))
		
	# Crossed logs
	_add_cylinder(root, 0.03 * scale_factor, 0.03 * scale_factor, 0.38 * scale_factor, Vector3(0, 0.06 * scale_factor, 0), mat_log, 4)
	_add_box(root, Vector3(0.05, 0.05, 0.36) * scale_factor, Vector3(0, 0.07 * scale_factor, 0), mat_log, Vector3(0, 60, 0))
	_add_box(root, Vector3(0.05, 0.05, 0.36) * scale_factor, Vector3(0, 0.07 * scale_factor, 0), mat_log, Vector3(0, -60, 0))
	
	# Glowing ember core
	_add_box(root, Vector3(0.12, 0.10, 0.12) * scale_factor, Vector3(0, 0.08 * scale_factor, 0), mat_ember)
	return root

# Stylized Low-Poly Wooden Bridge for river crossings
static func create_bridge(length: float = 1.4, width: float = 0.6) -> Node3D:
	_init_materials()
	var root = Node3D.new()
	root.name = "RiverBridge"
	var mat_wood = get_mat("bridge_wood")
	var mat_dark = get_mat("wood_dark")
	
	# Main deck
	_add_box(root, Vector3(width, 0.08, length), Vector3(0, 0.06, 0), mat_wood)
	# Side timber railings
	_add_box(root, Vector3(0.05, 0.16, length), Vector3(width * 0.5 - 0.03, 0.16, 0), mat_dark)
	_add_box(root, Vector3(0.05, 0.16, length), Vector3(-width * 0.5 + 0.03, 0.16, 0), mat_dark)
	# Support posts
	_add_cylinder(root, 0.04, 0.05, 0.35, Vector3(width * 0.5 - 0.03, -0.05, length * 0.35), mat_dark, 4)
	_add_cylinder(root, 0.04, 0.05, 0.35, Vector3(-width * 0.5 + 0.03, -0.05, length * 0.35), mat_dark, 4)
	_add_cylinder(root, 0.04, 0.05, 0.35, Vector3(width * 0.5 - 0.03, -0.05, -length * 0.35), mat_dark, 4)
	_add_cylinder(root, 0.04, 0.05, 0.35, Vector3(-width * 0.5 + 0.03, -0.05, -length * 0.35), mat_dark, 4)
	return root


# -------------------------------------------------------------
# SETTLEMENTS & FORTS
# -------------------------------------------------------------

# Mongol Yurt (Ger)
static func create_yurt(radius: float = 0.6, is_khan: bool = false) -> Node3D:
	_init_materials()
	var root = Node3D.new()
	root.name = "Yurt"
	
	var mat_felt = get_mat("yurt_felt")
	var mat_red = get_mat("yurt_red")
	var mat_wood = get_mat("wood_dark")
	var mat_gold = get_mat("gold_ornament")
	
	# Cylindrical base
	var base_h = radius * 0.7
	_add_cylinder(root, radius, radius, base_h, Vector3(0, base_h * 0.5, 0), mat_felt, 12)
	
	# Decorative red felt band around midriff
	_add_cylinder(root, radius * 1.01, radius * 1.01, base_h * 0.15, Vector3(0, base_h * 0.6, 0), mat_red, 12)
	
	# Conical roof
	var roof_h = radius * 0.65
	_add_cylinder(root, radius * 0.15, radius * 1.05, roof_h, Vector3(0, base_h + roof_h * 0.5, 0), mat_felt, 12)
	
	# Smoke ring (Töno) at apex
	var tono_mat = mat_gold if is_khan else mat_red
	_add_cylinder(root, radius * 0.18, radius * 0.18, 0.08, Vector3(0, base_h + roof_h + 0.04, 0), tono_mat, 8)
	
	# Wooden door frame & felt door
	var door_w = radius * 0.35
	var door_h = base_h * 0.8
	_add_box(root, Vector3(door_w, door_h, 0.08), Vector3(0, door_h * 0.5, radius * 0.96), mat_wood)
	_add_box(root, Vector3(door_w * 0.8, door_h * 0.9, 0.06), Vector3(0, door_h * 0.48, radius * 0.98), mat_red)
	
	return root

# Complete Mongol Camp
static func create_mongol_camp(is_capital: bool = false) -> Node3D:
	_init_materials()
	var root = Node3D.new()
	root.name = "MongolCamp"
	
	# Central Great Khan's Yurt
	var khan_yurt = create_yurt(0.7 if is_capital else 0.55, is_capital)
	root.add_child(khan_yurt)
	
	# Satellite Yurts
	var yurt2 = create_yurt(0.4, false)
	yurt2.position = Vector3(0.9, 0, 0.4)
	root.add_child(yurt2)
	
	if is_capital:
		var yurt3 = create_yurt(0.42, false)
		yurt3.position = Vector3(-0.85, 0, 0.5)
		root.add_child(yurt3)
	
	# Campfire
	var mat_rock = get_mat("rock_dark")
	var mat_wood = get_mat("wood_dark")
	var fire_pos = Vector3(0, 0, 1.0)
	_add_cylinder(root, 0.22, 0.22, 0.06, fire_pos, mat_rock, 6)
	_add_box(root, Vector3(0.25, 0.08, 0.08), fire_pos + Vector3(0, 0.04, 0), mat_wood, Vector3(0, 45, 0))
	_add_box(root, Vector3(0.25, 0.08, 0.08), fire_pos + Vector3(0, 0.04, 0), mat_wood, Vector3(0, -45, 0))
	
	# Nine White Banners / Tug Pole
	var banner = create_faction_banner("mongol", 1.8 if is_capital else 1.4)
	banner.position = Vector3(-0.6, 0, -0.6)
	root.add_child(banner)
	
	# Hitching post
	_add_cylinder(root, 0.04, 0.04, 0.4, Vector3(0.8, 0.2, -0.5), mat_wood)
	_add_cylinder(root, 0.04, 0.04, 0.4, Vector3(1.3, 0.2, -0.5), mat_wood)
	_add_box(root, Vector3(0.6, 0.06, 0.06), Vector3(1.05, 0.35, -0.5), mat_wood)
	
	return root

# Rus' Fortified Settlement / Kremlin
static func create_rus_fortress(is_capital: bool = false) -> Node3D:
	_init_materials()
	var root = Node3D.new()
	root.name = "RusFortress"
	
	var mat_log = get_mat("wood_log")
	var mat_dark = get_mat("wood_dark")
	var mat_roof = get_mat("wood_plank")
	var mat_gold = get_mat("gold_ornament")
	
	# Wooden Palisade Walls (square fort)
	var wall_r = 0.9 if is_capital else 0.7
	var wall_h = 0.5
	var wall_thick = 0.12
	# 4 walls
	_add_box(root, Vector3(wall_r * 2.0, wall_h, wall_thick), Vector3(0, wall_h * 0.5, wall_r), mat_log)
	_add_box(root, Vector3(wall_r * 2.0, wall_h, wall_thick), Vector3(0, wall_h * 0.5, -wall_r), mat_log)
	_add_box(root, Vector3(wall_thick, wall_h, wall_r * 2.0), Vector3(wall_r, wall_h * 0.5, 0), mat_log)
	_add_box(root, Vector3(wall_thick, wall_h, wall_r * 2.0), Vector3(-wall_r, wall_h * 0.5, 0), mat_log)
	
	# Corner Watchtowers (4 log towers with hipped roofs)
	var corners = [
		Vector3(wall_r, 0, wall_r),
		Vector3(-wall_r, 0, wall_r),
		Vector3(wall_r, 0, -wall_r),
		Vector3(-wall_r, 0, -wall_r)
	]
	for c in corners:
		var t_h = 0.8
		var t_w = 0.28
		_add_box(root, Vector3(t_w, t_h, t_w), c + Vector3(0, t_h * 0.5, 0), mat_log)
		# Pyramid roof
		_add_cylinder(root, 0.0, t_w * 0.8, 0.35, c + Vector3(0, t_h + 0.175, 0), mat_roof, 4)
	
	# Central Hall / Church
	if is_capital:
		# Wooden Church with Onion Dome
		_add_box(root, Vector3(0.7, 0.7, 0.7), Vector3(0, 0.35, 0), mat_log)
		_add_cylinder(root, 0.0, 0.55, 0.4, Vector3(0, 0.9, 0), mat_roof, 4)
		# Drum + Onion Dome
		_add_cylinder(root, 0.14, 0.14, 0.25, Vector3(0, 1.15, 0), mat_dark)
		_add_sphere(root, 0.22, Vector3(0, 1.35, 0), mat_gold)
		# Cross
		_add_box(root, Vector3(0.04, 0.2, 0.04), Vector3(0, 1.6, 0), mat_gold)
		_add_box(root, Vector3(0.12, 0.04, 0.04), Vector3(0, 1.62, 0), mat_gold)
	else:
		# Boyar Log Izba
		_add_box(root, Vector3(0.65, 0.5, 0.5), Vector3(0, 0.25, 0), mat_log)
		_add_cylinder(root, 0.0, 0.48, 0.35, Vector3(0, 0.65, 0), mat_roof, 4)
	
	# Gatehouse with Rus' Banner
	var banner = create_faction_banner("rus", 1.8 if is_capital else 1.4)
	banner.position = Vector3(0.4, 0, wall_r + 0.3)
	root.add_child(banner)
	
	return root

# Middle Eastern / Seljuk Settlement
static func create_seljuk_settlement(is_capital: bool = false) -> Node3D:
	_init_materials()
	var root = Node3D.new()
	root.name = "SeljukSettlement"
	
	var mat_stone = get_mat("rock")
	var mat_sand = get_mat("arid_steppe")
	var mat_blue = get_mat("faction_seljuk")
	var mat_gold = get_mat("gold_ornament")
	
	# Flat roof sandstone compound
	_add_box(root, Vector3(1.1, 0.45, 0.8), Vector3(0, 0.225, 0), mat_sand)
	_add_box(root, Vector3(0.6, 0.35, 0.5), Vector3(0.2, 0.55, 0), mat_sand)
	
	# Central Turquoise Dome
	var dome_r = 0.35 if is_capital else 0.25
	_add_cylinder(root, dome_r, dome_r, 0.15, Vector3(-0.15, 0.5, 0), mat_stone, 10)
	_add_sphere(root, dome_r, Vector3(-0.15, 0.6 + dome_r * 0.5, 0), mat_blue)
	
	# Minaret Tower
	var minaret_h = 1.3 if is_capital else 0.9
	_add_cylinder(root, 0.12, 0.16, minaret_h, Vector3(0.65, minaret_h * 0.5, 0.45), mat_sand, 8)
	_add_sphere(root, 0.14, Vector3(0.65, minaret_h + 0.1, 0.45), mat_gold)
	
	var banner = create_faction_banner("seljuk", 1.6)
	banner.position = Vector3(-0.6, 0, 0.5)
	root.add_child(banner)
	
	return root

# Khwarazmian / Eastern Settlement
static func create_khwarazm_settlement(is_capital: bool = false) -> Node3D:
	_init_materials()
	var root = Node3D.new()
	root.name = "KhwarazmSettlement"
	
	var mat_stone = get_mat("arid_steppe")
	var mat_green = get_mat("faction_khwarazm")
	var mat_brick = get_mat("wood_plank")
	
	# Caravanserai high walls
	_add_box(root, Vector3(1.2, 0.5, 1.0), Vector3(0, 0.25, 0), mat_stone)
	# Inner courtyard cutout effect (upper structure)
	_add_box(root, Vector3(0.5, 0.4, 0.5), Vector3(0, 0.6, 0), mat_brick)
	# Emerald tiled dome
	_add_sphere(root, 0.32, Vector3(0, 0.85, 0), mat_green)
	
	var banner = create_faction_banner("khwarazm", 1.6)
	banner.position = Vector3(0.7, 0, 0.5)
	root.add_child(banner)
	
	return root

# Neutral Steppe Outpost
static func create_neutral_outpost() -> Node3D:
	_init_materials()
	var root = Node3D.new()
	root.name = "NeutralOutpost"
	
	var mat_log = get_mat("wood_log")
	var mat_plank = get_mat("wood_plank")
	
	# Watchtower
	_add_box(root, Vector3(0.35, 0.8, 0.35), Vector3(0, 0.4, 0), mat_log)
	_add_box(root, Vector3(0.5, 0.1, 0.5), Vector3(0, 0.85, 0), mat_plank)
	_add_cylinder(root, 0.0, 0.38, 0.3, Vector3(0, 1.05, 0), mat_plank, 4)
	
	# Small trader yurt
	var yurt = create_yurt(0.38, false)
	yurt.position = Vector3(0.6, 0, 0.2)
	root.add_child(yurt)
	
	var banner = create_faction_banner("neutral", 1.2)
	banner.position = Vector3(-0.4, 0, 0.3)
	root.add_child(banner)
	
	return root


# Cuman / Kipchak Steppe Camp
static func create_cuman_camp(is_capital: bool = false) -> Node3D:
	_init_materials()
	var root = Node3D.new()
	root.name = "CumanCamp"
	
	# Central Yurt with turquoise trim
	var yurt1 = create_yurt(0.65 if is_capital else 0.5, is_capital)
	yurt1.position = Vector3(0, 0, 0)
	root.add_child(yurt1)
	
	if is_capital:
		var yurt2 = create_yurt(0.42, false)
		yurt2.position = Vector3(-0.75, 0, 0.4)
		root.add_child(yurt2)
		
	var banner = create_faction_banner("cuman", 1.8 if is_capital else 1.4)
	banner.position = Vector3(0.55, 0, 0.45)
	root.add_child(banner)
	return root

# Byzantine Fortified Settlement / Outpost
static func create_byzantine_settlement(is_capital: bool = false) -> Node3D:
	_init_materials()
	var root = Node3D.new()
	root.name = "ByzantineSettlement"
	
	var mat_stone = get_mat("rock")
	var mat_roof = get_mat("wood_dark")
	var mat_dome = get_mat("gold_ornament")
	
	# Stone Basilica / Keep
	var w = 0.8 if is_capital else 0.6
	_add_box(root, Vector3(w, 0.5, w * 0.8), Vector3(0, 0.25, 0), mat_stone)
	# Terracotta hip roof
	_add_cylinder(root, 0.0, w * 0.6, 0.3, Vector3(0, 0.65, 0), mat_roof, 4)
	if is_capital:
		_add_sphere(root, 0.2, Vector3(0, 0.85, 0), mat_dome)
		
	var banner = create_faction_banner("byzantine", 1.8 if is_capital else 1.4)
	banner.position = Vector3(0.6, 0, 0.4)
	root.add_child(banner)
	return root

# -------------------------------------------------------------
# FACTION BANNERS
# -------------------------------------------------------------
static func create_faction_banner(faction: String, height: float = 1.5) -> Node3D:
	_init_materials()
	var root = Node3D.new()
	root.name = "FactionBanner"
	
	var mat_pole = get_mat("wood_dark")
	var mat_gold = get_mat("gold_ornament")
	var mat_flag = get_mat("faction_neutral")
	
	match faction:
		"mongol":
			mat_flag = get_mat("faction_mongol")
		"cuman", "kipchak":
			mat_flag = get_mat("faction_cuman")
		"rus":
			mat_flag = get_mat("faction_rus")
		"byzantine":
			mat_flag = get_mat("faction_byzantine")
		"seljuk":
			mat_flag = get_mat("faction_seljuk")
		"khwarazm":
			mat_flag = get_mat("faction_khwarazm")
	
	# Vertical Pole
	_add_cylinder(root, 0.03, 0.04, height, Vector3(0, height * 0.5, 0), mat_pole, 6)
	# Finial / Spearhead atop pole
	_add_cone(root, 0.07, 0.18, Vector3(0, height + 0.09, 0), mat_gold, 4)
	
	# Waving Banner Flag
	var flag_w = 0.55
	var flag_h = 0.4
	_add_box(root, Vector3(flag_w, flag_h, 0.02), Vector3(flag_w * 0.5 + 0.02, height - 0.22, 0), mat_flag)
	# Gold fringe border on flag
	_add_box(root, Vector3(flag_w, 0.04, 0.025), Vector3(flag_w * 0.5 + 0.02, height - 0.42, 0), mat_gold)
	
	return root


# -------------------------------------------------------------
# DETAILED 3D UNIT FIGURINES
# -------------------------------------------------------------

static func _add_figurine_pedestal(parent: Node3D, f_color: Color, radius: float = 0.42):
	var ped = Node3D.new()
	ped.name = "Pedestal"
	_add_cylinder(ped, radius, radius * 1.08, 0.05, Vector3(0, 0.025, 0), get_mat("pedestal_base"), 14)
	var mat_f = get_mat("ped_f_" + f_color.to_html(false), f_color)
	_add_cylinder(ped, radius * 0.9, radius * 0.9, 0.015, Vector3(0, 0.055, 0), mat_f, 14)
	parent.add_child(ped)

# Stylized Horse (reused for cavalry)
static func _build_horse(parent: Node3D, horse_mat: Material, scale_m: float = 1.0) -> Node3D:
	var horse = Node3D.new()
	horse.name = "Horse"
	
	# Body
	_add_box(horse, Vector3(0.35, 0.32, 0.7) * scale_m, Vector3(0, 0.48 * scale_m, 0), horse_mat)
	# 4 Legs
	var leg_w = 0.07 * scale_m
	var leg_h = 0.38 * scale_m
	_add_cylinder(horse, leg_w, leg_w * 0.8, leg_h, Vector3(0.12, 0.19, 0.24) * scale_m, horse_mat, 6)
	_add_cylinder(horse, leg_w, leg_w * 0.8, leg_h, Vector3(-0.12, 0.19, 0.24) * scale_m, horse_mat, 6)
	_add_cylinder(horse, leg_w, leg_w * 0.8, leg_h, Vector3(0.12, 0.19, -0.24) * scale_m, horse_mat, 6)
	_add_cylinder(horse, leg_w, leg_w * 0.8, leg_h, Vector3(-0.12, 0.19, -0.24) * scale_m, horse_mat, 6)
	# Neck (angled)
	_add_box(horse, Vector3(0.18, 0.35, 0.24) * scale_m, Vector3(0, 0.65 * scale_m, -0.28 * scale_m), horse_mat, Vector3(25, 0, 0))
	# Head
	_add_box(horse, Vector3(0.16, 0.2, 0.28) * scale_m, Vector3(0, 0.78 * scale_m, -0.42 * scale_m), horse_mat, Vector3(-15, 0, 0))
	# Tail
	_add_cylinder(horse, 0.03 * scale_m, 0.06 * scale_m, 0.35 * scale_m, Vector3(0, 0.45 * scale_m, 0.45 * scale_m), horse_mat, 4)
	
	parent.add_child(horse)
	return horse

# 1. Mongol Horse Archer
static func create_horse_archer_unit(faction_color: Color = Color(0.9, 0.75, 0.22)) -> Node3D:
	_init_materials()
	var root = Node3D.new()
	root.name = "HorseArcher"
	
	_add_figurine_pedestal(root, faction_color, 0.52)
	
	var mat_horse = get_mat("horse_brown")
	var mat_robe = get_mat("faction_mongol")
	var mat_leather = get_mat("mongol_leather")
	var mat_bow = get_mat("wood_dark")
	var mat_gold = get_mat("gold_ornament")
	
	# Horse
	_build_horse(root, mat_horse, 1.0)
	
	# Saddle & Blanket
	_add_box(root, Vector3(0.38, 0.08, 0.35), Vector3(0, 0.66, 0.02), mat_robe)
	
	# Rider Torso
	_add_box(root, Vector3(0.25, 0.35, 0.2), Vector3(0, 0.88, 0.02), mat_robe)
	# Head & Pointed Mongol Malgai Cap
	_add_sphere(root, 0.11, Vector3(0, 1.12, 0.02), mat_leather)
	_add_cone(root, 0.12, 0.18, Vector3(0, 1.25, 0.02), mat_robe, 6)
	# Recurve Composite Bow in left hand
	_add_cylinder(root, 0.025, 0.025, 0.6, Vector3(-0.25, 0.9, -0.15), mat_bow, 4)
	# Quiver on back
	_add_cylinder(root, 0.06, 0.05, 0.4, Vector3(0.12, 0.95, 0.16), mat_leather, 6)
	
	return root

# 2. Heavy Cavalry (Armored Cataphract / Mongol Guard)
static func create_heavy_cavalry_unit(faction_color: Color = Color(0.9, 0.75, 0.22)) -> Node3D:
	_init_materials()
	var root = Node3D.new()
	root.name = "HeavyCavalry"
	
	_add_figurine_pedestal(root, faction_color, 0.58)
	
	var mat_horse = get_mat("horse_black")
	var mat_armor = get_mat("steel")
	var mat_trim = get_mat("faction_mongol")
	var mat_lance = get_mat("wood_dark")
	
	# Horse
	_build_horse(root, mat_horse, 1.1)
	
	# Horse Armor Barding / Champron
	_add_box(root, Vector3(0.4, 0.28, 0.5), Vector3(0, 0.52, 0), mat_armor)
	_add_box(root, Vector3(0.18, 0.18, 0.15), Vector3(0, 0.88, -0.45), mat_armor)
	
	# Armored Rider Torso
	_add_box(root, Vector3(0.28, 0.38, 0.22), Vector3(0, 0.92, 0.02), mat_armor)
	# Steel Spiked Helmet
	_add_sphere(root, 0.12, Vector3(0, 1.18, 0.02), mat_armor)
	_add_cone(root, 0.04, 0.15, Vector3(0, 1.34, 0.02), mat_armor, 4)
	# Couched Lance
	_add_cylinder(root, 0.03, 0.03, 1.6, Vector3(0.24, 0.95, -0.4), mat_lance, 4)
	_add_cone(root, 0.06, 0.25, Vector3(0.24, 1.0, -1.25), mat_armor, 4)
	# Shield
	_add_cylinder(root, 0.2, 0.2, 0.04, Vector3(-0.22, 0.92, 0.02), mat_trim, 8)
	
	return root

# 3. Rus' Infantry Soldier with Shield & Axe
static func create_infantry_unit(faction_color: Color = Color(0.78, 0.2, 0.2)) -> Node3D:
	_init_materials()
	var root = Node3D.new()
	root.name = "InfantryUnit"
	
	_add_figurine_pedestal(root, faction_color, 0.38)
	
	var mat_tunic = get_mat("faction_rus")
	var mat_chainmail = get_mat("steel")
	var mat_wood = get_mat("wood_dark")
	var mat_iron = get_mat("iron_dark")
	var mat_leather = get_mat("wood_dark")
	
	# Two legs
	_add_cylinder(root, 0.07, 0.07, 0.42, Vector3(0.1, 0.21, 0), mat_leather, 6)
	_add_cylinder(root, 0.07, 0.07, 0.42, Vector3(-0.1, 0.21, 0), mat_leather, 6)
	
	# Torso in Mail Hauberk + Crimson Tunic
	_add_box(root, Vector3(0.3, 0.42, 0.2), Vector3(0, 0.62, 0), mat_chainmail)
	_add_box(root, Vector3(0.32, 0.2, 0.22), Vector3(0, 0.52, 0), mat_tunic)
	
	# Conical Helmet
	_add_sphere(root, 0.11, Vector3(0, 0.92, 0), mat_chainmail)
	_add_cone(root, 0.12, 0.18, Vector3(0, 1.05, 0), mat_chainmail, 6)
	
	# Large Rus' Kite / Tear-drop Shield
	var shield_pos = Vector3(-0.24, 0.65, 0.1)
	_add_box(root, Vector3(0.05, 0.55, 0.32), shield_pos, mat_tunic)
	_add_box(root, Vector3(0.06, 0.55, 0.06), shield_pos, mat_chainmail) # Shield Cross boss
	_add_box(root, Vector3(0.06, 0.06, 0.32), shield_pos, mat_chainmail)
	
	# Right hand Battle Axe
	_add_cylinder(root, 0.02, 0.02, 0.65, Vector3(0.24, 0.65, 0.05), mat_wood, 4)
	_add_box(root, Vector3(0.04, 0.16, 0.14), Vector3(0.24, 0.92, 0.1), mat_iron)
	
	return root

# 4. Heavy Spearman / Druzhina
static func create_spearman_unit(faction_color: Color = Color(0.78, 0.2, 0.2)) -> Node3D:
	_init_materials()
	var root = Node3D.new()
	root.name = "SpearmanUnit"
	
	_add_figurine_pedestal(root, faction_color, 0.38)
	
	var mat_tunic = get_mat("faction_rus")
	var mat_armor = get_mat("steel")
	var mat_wood = get_mat("wood_dark")
	var mat_iron = get_mat("steel")
	
	# Legs
	_add_cylinder(root, 0.07, 0.07, 0.42, Vector3(0.1, 0.21, 0), get_mat("wood_dark"), 6)
	_add_cylinder(root, 0.07, 0.07, 0.42, Vector3(-0.1, 0.21, 0), get_mat("wood_dark"), 6)
	
	# Torso & Spangenhelm
	_add_box(root, Vector3(0.3, 0.44, 0.2), Vector3(0, 0.63, 0), mat_armor)
	_add_sphere(root, 0.11, Vector3(0, 0.94, 0), mat_armor)
	_add_cone(root, 0.12, 0.2, Vector3(0, 1.08, 0), mat_armor, 4)
	
	# Tall Upright Spear (2.0m)
	_add_cylinder(root, 0.025, 0.025, 2.0, Vector3(0.22, 1.0, 0.15), mat_wood, 4)
	_add_cone(root, 0.05, 0.3, Vector3(0.22, 2.1, 0.15), mat_iron, 4)
	
	# Round Shield on left arm
	_add_cylinder(root, 0.24, 0.24, 0.04, Vector3(-0.22, 0.65, 0.05), mat_tunic, 8)
	_add_sphere(root, 0.07, Vector3(-0.25, 0.65, 0.05), mat_armor)
	
	return root

# 5. Siege Engine (Traction Trebuchet)
static func create_siege_engine(faction_color: Color = Color(0.5, 0.5, 0.5)) -> Node3D:
	_init_materials()
	var root = Node3D.new()
	root.name = "SiegeEngine"
	
	_add_figurine_pedestal(root, faction_color, 0.62)
	
	var mat_timber = get_mat("wood_log")
	var mat_iron = get_mat("iron_dark")
	var mat_stone = get_mat("rock")
	
	# Base Frame (Heavy timber beams)
	_add_box(root, Vector3(0.8, 0.12, 1.2), Vector3(0, 0.1, 0), mat_timber)
	# 4 Wheels
	for pos in [Vector3(0.45, 0.12, 0.45), Vector3(-0.45, 0.12, 0.45), Vector3(0.45, 0.12, -0.45), Vector3(-0.45, 0.12, -0.45)]:
		_add_cylinder(root, 0.14, 0.14, 0.08, pos, mat_timber, 8)
	
	# A-Frame Uprights
	_add_box(root, Vector3(0.08, 0.8, 0.08), Vector3(0.35, 0.5, 0), mat_timber, Vector3(0, 0, -15))
	_add_box(root, Vector3(0.08, 0.8, 0.08), Vector3(-0.35, 0.5, 0), mat_timber, Vector3(0, 0, 15))
	
	# Throwing Beam
	_add_box(root, Vector3(0.08, 0.08, 1.4), Vector3(0, 0.85, 0.2), mat_timber, Vector3(25, 0, 0))
	# Counterweight / Sling Bucket
	_add_box(root, Vector3(0.3, 0.3, 0.3), Vector3(0, 0.6, 0.7), mat_stone)
	
	return root
