class_name MainMenu
extends Node3D

const ModelBuilder = preload("res://scripts/visuals/model_builder.gd")
const Palette = preload("res://scripts/core/palette.gd")

var camera_pivot: Node3D
var cam: Camera3D
var ui_layer: CanvasLayer

var settings_modal: PanelContainer
var faction_modal: PanelContainer
var info_label: Label

# Faction selection state
var selected_faction_id: String = "mongol"
var faction_card_buttons: Dictionary = {}

var lbl_fact_title: Label
var lbl_fact_leader: Label
var lbl_fact_quote: Label
var lbl_fact_desc: Label
var lbl_fact_bonuses: Label
var lbl_fact_realm: Label
var btn_embark: Button

const FACTIONS_CATALOG = {
	"mongol": {
		"id": "mongol",
		"name": "Mongol Khanate",
		"subtitle": "The Golden Horde of the Great Steppe",
		"leader": "Khagan Genghis Khan",
		"capital": "Sarai",
		"color": Color(0.85, 0.65, 0.13), # Bronze Gold
		"icon": "🐎",
		"difficulty": "Standard",
		"quote": "“The greatest joy is to scatter your enemy, to drive him before you, to see his cities reduced to ashes.”",
		"desc": "Rulers of the vast Eurasian steppe, the Mongol tumens strike with terrifying speed and master composite bowmanship. Their nomadic pastoral economy is optimized for rapid mobile warfare, swift encirclement, and devastating open-field cavalry charges.",
		"bonuses": [
			"🏹 +15% Cavalry Attack Power in open terrain",
			"⚡ +20% Campaign Army Movement Speed",
			"🐎 Superior Horse Archers with ranged hit-and-run tactics",
			"⛺ Nomadic yurt settlements with low maintenance overhead"
		],
		"starting_realm": "Controls Sarai (Capital) and Kipchak Steppe with 240+ veteran horse archers and light riders."
	},
	"rus": {
		"id": "rus",
		"name": "Rus' Principalities",
		"subtitle": "Slavic Shields and Northern Kremlins",
		"leader": "Grand Prince of Novgorod & Kiev",
		"capital": "Novgorod",
		"color": Color(0.65, 0.18, 0.14), # Rus' Crimson
		"icon": "🛡",
		"difficulty": "Defensive / Advanced",
		"quote": "“Whoever comes to us with a sword shall perish by the sword. On that the Russian land stands and will stand.”",
		"desc": "Hardened by dense boreal forests, frozen rivers, and relentless border skirmishes, the Rus' warriors fight behind formidable wooden kremlins and heavy iron-rimmed shields. Their Druzhina footmen withstand brutal punishment and break enemy assaults.",
		"bonuses": [
			"🏰 +30% Defensive Fortification Bonus across all provinces",
			"🪵 +50% Timber Production (-15% stockade construction costs)",
			"🪓 Elite Druzhina Axemen & Shielded Spearmen with high physical armor",
			"❄ Attrition resistance during winter turns and northern campaigns"
		],
		"starting_realm": "Controls Novgorod (Capital), Moscow, and Kiev with sturdy defensive infantry garrisons."
	},
	"cuman": {
		"id": "cuman",
		"name": "Cumans / Kipchaks",
		"subtitle": "Wild Horsemen of the Polovtsian Plains",
		"leader": "Khan of the Wild Field",
		"capital": "Bukhara",
		"color": Color(0.13, 0.70, 0.67), # Turquoise Steppe Cyan
		"icon": "🏹",
		"difficulty": "Aggressive / Fast",
		"quote": "“Our roof is the open sky and our walls the boundless horizon. No fortress can cage the wind of the steppe.”",
		"desc": "Fierce pastoral nomads of the Desht-i Qipchaq plains. Masters of lightning raids, feigned retreats, and desert skirmishing. Their lightweight mobile armies cross arid steppes with unmatched agility, overwhelming complacent garrisons.",
		"bonuses": [
			"🐎 +25% Movement across Steppes, Arid plains, and River crossings",
			"💰 -20% Recruitment & Upkeep Cost for Light Cavalry and Raiders",
			"🌪 Nomadic Swarm doctrine: rapid early-game pressure and outflanking",
			"🌾 Mobile herds yielding resilient food replenishment on the march"
		],
		"starting_realm": "Controls Bukhara (Capital) with fast Kipchak nomad raiders and skirmish archers."
	},
	"byzantine": {
		"id": "byzantine",
		"name": "Byzantine Empire",
		"subtitle": "Heirs of Rome • Imperial Silk Outpost",
		"leader": "Strategos of Cherson",
		"capital": "Urgench",
		"color": Color(0.55, 0.15, 0.55), # Imperial Purple
		"icon": "🦅",
		"difficulty": "Tactical / Heavy",
		"quote": "“Rome does not bow to the wilderness. Discipline, faith, and iron will endure long after the hordes dissolve.”",
		"desc": "The Roman legacy endures through disciplined armored cataphracts, professional spear phalanxes, and sophisticated architectural engineering. Their stone basilicas and high walls project civilizing order and immense endurance onto turbulent frontiers.",
		"bonuses": [
			"🛡 +20% Physical Armor & Defense for all military units",
			"🏛 +25% Fortification Resistance and Basilica trade income",
			"⚔ Armored Varangian Guards & Heavy Cataphract Shock Cavalry",
			"📜 Administrative resilience: reduced corruption and high province stability"
		],
		"starting_realm": "Controls Urgench (Capital Outpost) with heavily armored cataphracts and phalanx spearmen."
	},
	"seljuk": {
		"id": "seljuk",
		"name": "Seljuk Sultanate",
		"subtitle": "Great Seljuks of Persia and Rum",
		"leader": "Sultan of Rum & Khorasan",
		"capital": "Tabriz",
		"color": Color(0.18, 0.45, 0.70), # Cobalt Blue
		"icon": "⚔",
		"difficulty": "Siege / Heavy",
		"quote": "“Our siege engines shatter the walls of stone; our arrows blot out the sun above the highest citadels.”",
		"desc": "Fusing Islamic siege engineering with Turkish horse warfare, the Seljuks excel at breaching fortified strongholds and crushing entrenched defenders. Their balanced tumens field deadly traction trebuchets alongside noble Ghilman lancers.",
		"bonuses": [
			"🎯 -25% Siege Engine & Trebuchet Construction Cost",
			"⚔ +10% Combined-Arms Attack and Defense bonus across mixed armies",
			"☄ Heavy Siege Trebuchets that pulverize high-defense enemy provinces",
			"🕌 Grand Bazaar trade networks boosting both Gold and Wood revenues"
		],
		"starting_realm": "Controls Tabriz (Capital) and Samarkand with heavy siege engines and veteran footmen."
	},
	"khwarazm": {
		"id": "khwarazm",
		"name": "Khwarazmshah Dynasty",
		"subtitle": "Grand Emperors of the Silk Road",
		"leader": "Shahanshah of Khwarazm",
		"capital": "Karakorum",
		"color": Color(0.18, 0.55, 0.34), # Silk Road Emerald
		"icon": "👑",
		"difficulty": "Economic / Rich",
		"quote": "“All the wealth of East and West pours into our bazaars. Our steel is tempered in purest gold.”",
		"desc": "Controlling the richest oasis crossroads of Eurasian commerce, the Khwarazmian Shahs command immense merchant revenues. Their deep treasury enables rapid urban expansion, mercenary mobilization, and elite Royal Lancers.",
		"bonuses": [
			"💰 +25% Gold Tax Revenue and Caravan Trade Income in all provinces",
			"🛡 +10% Heavy Cavalry Attack and Armor rating",
			"🪙 Economic supremacy: rapid province modernization and high recruitment capacity",
			"💎 Silk Road Royal Lancers with crushing charge impact"
		],
		"starting_realm": "Controls Karakorum (Capital), Zhongdu, and Shangdu with vast merchant wealth."
	}
}

func _ready():
	_setup_3d_diorama()
	_setup_ui()

func _setup_3d_diorama():
	# Directional Sun (Golden Hour)
	var sun = DirectionalLight3D.new()
	sun.light_color = Color(1.0, 0.94, 0.82)
	sun.light_energy = 1.45
	sun.shadow_enabled = true
	sun.shadow_blur = 1.2
	sun.rotation_degrees = Vector3(-35, 45, 0)
	add_child(sun)
	
	# World Environment with rich contrast & subtle bloom
	var env_node = WorldEnvironment.new()
	var env = Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.16, 0.19, 0.24) # Deep twilight atmosphere
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.55, 0.48, 0.42)
	env.ambient_light_energy = 0.95
	env.fog_enabled = true
	env.fog_light_color = Color(0.32, 0.36, 0.42)
	env.fog_density = 0.012
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	env.tonemap_exposure = 1.15
	env.glow_enabled = true
	env.glow_intensity = 0.35
	env.glow_bloom = 0.12
	env.glow_blend_mode = Environment.GLOW_BLEND_MODE_SOFTLIGHT
	env_node.environment = env
	add_child(env_node)
	
	# Rotating Camera Pivot
	camera_pivot = Node3D.new()
	camera_pivot.name = "CameraPivot"
	add_child(camera_pivot)
	
	cam = Camera3D.new()
	cam.position = Vector3(0, 3.2, 7.8)
	cam.rotation_degrees = Vector3(-20, 0, 0)
	cam.fov = 38.0
	cam.current = true
	camera_pivot.add_child(cam)
	
	# Miniature Battlefield Diorama Base
	var diorama_root = Node3D.new()
	diorama_root.name = "Diorama"
	add_child(diorama_root)
	
	# Tier 1: Layered earthy cliff bedrock base
	var base_cliff = MeshInstance3D.new()
	var cyl_c = CylinderMesh.new()
	cyl_c.top_radius = 5.2
	cyl_c.bottom_radius = 5.6
	cyl_c.height = 0.5
	cyl_c.radial_segments = 20
	base_cliff.mesh = cyl_c
	base_cliff.material_override = ModelBuilder.get_mat("cliff_bedrock")
	base_cliff.position = Vector3(0, -0.32, 0)
	diorama_root.add_child(base_cliff)
	
	# Tier 2: Lush bevelled grass plate
	var base_mesh = MeshInstance3D.new()
	var cyl = CylinderMesh.new()
	cyl.top_radius = 5.0
	cyl.bottom_radius = 5.2
	cyl.height = 0.18
	cyl.radial_segments = 20
	base_mesh.mesh = cyl
	base_mesh.material_override = ModelBuilder.get_mat("steppe_grass")
	base_mesh.position = Vector3(0, 0.0, 0)
	diorama_root.add_child(base_mesh)
	
	# Steppe side (Mongol Camp & Yurt)
	var mongol_camp = ModelBuilder.create_mongol_camp(true)
	mongol_camp.position = Vector3(-1.8, 0.09, -0.5)
	mongol_camp.rotation_degrees = Vector3(0, 25, 0)
	diorama_root.add_child(mongol_camp)
	
	var campfire = ModelBuilder.create_campfire(1.2)
	campfire.position = Vector3(-2.2, 0.09, 0.7)
	diorama_root.add_child(campfire)
	
	var horse_archer = ModelBuilder.create_horse_archer_unit(Color(0.9, 0.75, 0.22))
	horse_archer.position = Vector3(-0.8, 0.09, 1.2)
	horse_archer.rotation_degrees = Vector3(0, 75, 0)
	diorama_root.add_child(horse_archer)
	
	# Rus' side (Fortress & Warriors)
	var rus_fort = ModelBuilder.create_rus_fortress(false)
	rus_fort.position = Vector3(2.0, 0.09, -0.6)
	rus_fort.rotation_degrees = Vector3(0, -35, 0)
	diorama_root.add_child(rus_fort)
	
	var druzhina = ModelBuilder.create_infantry_unit(Color(0.78, 0.2, 0.2))
	druzhina.position = Vector3(0.8, 0.09, 1.0)
	druzhina.rotation_degrees = Vector3(0, -75, 0)
	diorama_root.add_child(druzhina)
	
	# Environmental dressing
	var flowers1 = ModelBuilder.create_flower_patch(1.2)
	flowers1.position = Vector3(-0.4, 0.09, 1.8)
	diorama_root.add_child(flowers1)
	
	var flowers2 = ModelBuilder.create_flower_patch(1.1)
	flowers2.position = Vector3(1.6, 0.09, 0.8)
	diorama_root.add_child(flowers2)
	
	var p1 = ModelBuilder.create_pine_tree(1.2)
	p1.position = Vector3(2.8, 0.09, 1.5)
	diorama_root.add_child(p1)
	
	var p2 = ModelBuilder.create_birch_tree(1.1)
	p2.position = Vector3(1.2, 0.09, -2.4)
	diorama_root.add_child(p2)
	
	var p3 = ModelBuilder.create_oak_tree(1.1)
	p3.position = Vector3(-2.8, 0.09, 1.8)
	diorama_root.add_child(p3)
	
	var rocks = ModelBuilder.create_rock_cluster(1.2)
	rocks.position = Vector3(0, 0.09, -1.8)
	diorama_root.add_child(rocks)

func _process(delta: float):
	if camera_pivot:
		camera_pivot.rotation.y += delta * 0.08

func _setup_ui():
	ui_layer = CanvasLayer.new()
	ui_layer.name = "UILayer"
	add_child(ui_layer)
	
	# Title & Menu Card (Left side)
	var menu_panel = PanelContainer.new()
	menu_panel.offset_left = 60
	menu_panel.offset_top = 80
	menu_panel.offset_right = 440
	menu_panel.offset_bottom = 640
	
	var sb = StyleBoxFlat.new()
	sb.bg_color = Color(0.10, 0.08, 0.06, 0.92)
	sb.set_border_width_all(2)
	sb.border_color = Color(0.78, 0.62, 0.28)
	sb.set_corner_radius_all(8)
	sb.content_margin_left = 32
	sb.content_margin_right = 32
	sb.content_margin_top = 32
	sb.content_margin_bottom = 32
	menu_panel.add_theme_stylebox_override("panel", sb)
	ui_layer.add_child(menu_panel)
	
	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 16)
	menu_panel.add_child(vbox)
	
	var lbl_title = Label.new()
	lbl_title.text = "HORDE"
	lbl_title.add_theme_font_size_override("font_size", 54)
	lbl_title.add_theme_color_override("font_color", Color(1.0, 0.88, 0.32))
	lbl_title.add_theme_constant_override("outline_size", 8)
	lbl_title.add_theme_color_override("font_outline_color", Color(0.1, 0.05, 0.02))
	vbox.add_child(lbl_title)
	
	var lbl_sub = Label.new()
	lbl_sub.text = "STEPPE AND STEEL"
	lbl_sub.add_theme_font_size_override("font_size", 22)
	lbl_sub.add_theme_color_override("font_color", Color(0.9, 0.45, 0.35))
	lbl_sub.add_theme_constant_override("outline_size", 4)
	lbl_sub.add_theme_color_override("font_outline_color", Color(0.08, 0.04, 0.02))
	vbox.add_child(lbl_sub)
	
	var lbl_desc = Label.new()
	lbl_desc.text = "A 3D Turn-Based Eurasian Grand Strategy Game"
	lbl_desc.add_theme_font_size_override("font_size", 14)
	lbl_desc.add_theme_color_override("font_color", Color(0.8, 0.75, 0.65))
	lbl_desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vbox.add_child(lbl_desc)
	
	var hs = HSeparator.new()
	vbox.add_child(hs)
	
	# Menu Buttons
	var btn_new = _create_menu_button("⚔ NEW CAMPAIGN", Color(0.42, 0.28, 0.12), Color(0.92, 0.75, 0.28))
	btn_new.pressed.connect(_on_new_campaign_pressed)
	vbox.add_child(btn_new)
	
	var btn_continue = _create_menu_button("📜 CONTINUE CAMPAIGN", Color(0.24, 0.20, 0.16), Color(0.65, 0.52, 0.3))
	btn_continue.pressed.connect(_on_continue_pressed)
	vbox.add_child(btn_continue)
	
	var btn_settings = _create_menu_button("⚙ SETTINGS", Color(0.24, 0.20, 0.16), Color(0.65, 0.52, 0.3))
	btn_settings.pressed.connect(_on_settings_pressed)
	vbox.add_child(btn_settings)
	
	var btn_quit = _create_menu_button("🚪 QUIT", Color(0.35, 0.12, 0.12), Color(0.8, 0.3, 0.3))
	btn_quit.pressed.connect(_on_quit_pressed)
	vbox.add_child(btn_quit)
	
	info_label = Label.new()
	info_label.text = "v0.2.1 • Team Arsenal Canon Edition"
	info_label.add_theme_font_size_override("font_size", 12)
	info_label.add_theme_color_override("font_color", Color(0.6, 0.55, 0.45))
	vbox.add_child(info_label)
	
	# Modals
	_create_settings_modal()
	_create_faction_select_modal()

func _create_menu_button(label: String, bg_col: Color, border_col: Color) -> Button:
	var btn = Button.new()
	btn.text = label
	btn.custom_minimum_size = Vector2(0, 48)
	btn.add_theme_font_size_override("font_size", 18)
	btn.add_theme_color_override("font_color", Color(1.0, 0.95, 0.85))
	
	var sb_n = StyleBoxFlat.new()
	sb_n.bg_color = bg_col
	sb_n.set_border_width_all(2)
	sb_n.border_color = border_col
	sb_n.set_corner_radius_all(6)
	btn.add_theme_stylebox_override("normal", sb_n)
	
	var sb_h = StyleBoxFlat.new()
	sb_h.bg_color = bg_col.lightened(0.2)
	sb_h.set_border_width_all(2)
	sb_h.border_color = border_col.lightened(0.3)
	sb_h.set_corner_radius_all(6)
	btn.add_theme_stylebox_override("hover", sb_h)
	
	return btn

# ------------------------------------------------------------------------------
# FACTION SELECTION MODAL
# ------------------------------------------------------------------------------
func _create_faction_select_modal():
	faction_modal = PanelContainer.new()
	faction_modal.name = "FactionSelectModal"
	faction_modal.set_anchors_preset(Control.PRESET_CENTER)
	faction_modal.offset_left = -530
	faction_modal.offset_top = -325
	faction_modal.offset_right = 530
	faction_modal.offset_bottom = 325
	
	var sb = StyleBoxFlat.new()
	sb.bg_color = Color(0.10, 0.08, 0.06, 0.98)
	sb.set_border_width_all(2)
	sb.border_color = Palette.BRONZE_GOLD
	sb.set_corner_radius_all(10)
	sb.content_margin_left = 24
	sb.content_margin_right = 24
	sb.content_margin_top = 20
	sb.content_margin_bottom = 20
	faction_modal.add_theme_stylebox_override("panel", sb)
	faction_modal.visible = false
	ui_layer.add_child(faction_modal)
	
	var main_vbox = VBoxContainer.new()
	main_vbox.add_theme_constant_override("separation", 14)
	faction_modal.add_child(main_vbox)
	
	# Top Modal Header
	var header_hbox = HBoxContainer.new()
	main_vbox.add_child(header_hbox)
	
	var header_vbox = VBoxContainer.new()
	header_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header_hbox.add_child(header_vbox)
	
	var title = Label.new()
	title.text = "⚔ CHOOSE YOUR CIVILIZATION"
	title.add_theme_font_size_override("font_size", 24)
	title.add_theme_color_override("font_color", Color(1.0, 0.88, 0.35))
	header_vbox.add_child(title)
	
	var sub = Label.new()
	sub.text = "Select a historical realm to lead across medieval Eurasia. Each faction features distinct military units, economic doctrines, and strategic traits."
	sub.add_theme_font_size_override("font_size", 13)
	sub.add_theme_color_override("font_color", Color(0.8, 0.75, 0.68))
	header_vbox.add_child(sub)
	
	var hs_top = HSeparator.new()
	main_vbox.add_child(hs_top)
	
	# Main Content Area: Left = Faction Cards List, Right = Detailed Dossier
	var body_hbox = HBoxContainer.new()
	body_hbox.size_flags_vertical = Control.SIZE_EXPAND_FILL
	body_hbox.add_theme_constant_override("separation", 20)
	main_vbox.add_child(body_hbox)
	
	# Left: Faction List
	var left_vbox = VBoxContainer.new()
	left_vbox.custom_minimum_size = Vector2(340, 0)
	left_vbox.add_theme_constant_override("separation", 8)
	body_hbox.add_child(left_vbox)
	
	var lbl_list_title = Label.new()
	lbl_list_title.text = "AVAILABLE REALMS (6):"
	lbl_list_title.add_theme_font_size_override("font_size", 13)
	lbl_list_title.add_theme_color_override("font_color", Palette.BRONZE_GOLD)
	left_vbox.add_child(lbl_list_title)
	
	var faction_order = ["mongol", "rus", "cuman", "byzantine", "seljuk", "khwarazm"]
	for fid in faction_order:
		var fdata = FACTIONS_CATALOG[fid]
		var btn = Button.new()
		btn.custom_minimum_size = Vector2(340, 56)
		btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
		
		# Inner container for card layout
		var card_hbox = HBoxContainer.new()
		card_hbox.set_anchors_preset(Control.PRESET_FULL_RECT)
		card_hbox.offset_left = 12
		card_hbox.offset_right = -12
		card_hbox.add_theme_constant_override("separation", 12)
		card_hbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
		btn.add_child(card_hbox)
		
		# Faction color stripe
		var stripe = ColorRect.new()
		stripe.custom_minimum_size = Vector2(6, 40)
		stripe.color = fdata.color
		stripe.mouse_filter = Control.MOUSE_FILTER_IGNORE
		card_hbox.add_child(stripe)
		
		var icon_lbl = Label.new()
		icon_lbl.text = fdata.icon
		icon_lbl.add_theme_font_size_override("font_size", 22)
		icon_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
		card_hbox.add_child(icon_lbl)
		
		var text_vbox = VBoxContainer.new()
		text_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		text_vbox.alignment = BoxContainer.ALIGNMENT_CENTER
		text_vbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
		card_hbox.add_child(text_vbox)
		
		var name_lbl = Label.new()
		name_lbl.text = fdata.name
		name_lbl.add_theme_font_size_override("font_size", 16)
		name_lbl.add_theme_color_override("font_color", Color(1.0, 0.95, 0.90))
		name_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
		text_vbox.add_child(name_lbl)
		
		var tag_lbl = Label.new()
		tag_lbl.text = fdata.subtitle
		tag_lbl.add_theme_font_size_override("font_size", 11)
		tag_lbl.add_theme_color_override("font_color", Color(0.75, 0.70, 0.60))
		tag_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
		text_vbox.add_child(tag_lbl)
		
		var f_id_capture = fid
		btn.pressed.connect(func(): _select_faction(f_id_capture))
		left_vbox.add_child(btn)
		faction_card_buttons[fid] = btn
		
	# Right: Faction Dossier Card
	var right_panel = PanelContainer.new()
	right_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	right_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	
	var r_sb = StyleBoxFlat.new()
	r_sb.bg_color = Color(0.14, 0.12, 0.10, 0.95)
	r_sb.set_border_width_all(1)
	r_sb.border_color = Color(0.60, 0.48, 0.25)
	r_sb.set_corner_radius_all(8)
	r_sb.content_margin_left = 20
	r_sb.content_margin_right = 20
	r_sb.content_margin_top = 16
	r_sb.content_margin_bottom = 16
	right_panel.add_theme_stylebox_override("panel", r_sb)
	body_hbox.add_child(right_panel)
	
	var right_vbox = VBoxContainer.new()
	right_vbox.add_theme_constant_override("separation", 10)
	right_panel.add_child(right_vbox)
	
	# Header in Dossier
	lbl_fact_title = Label.new()
	lbl_fact_title.text = "MONGOL KHANATE"
	lbl_fact_title.add_theme_font_size_override("font_size", 22)
	lbl_fact_title.add_theme_color_override("font_color", Color(1.0, 0.85, 0.3))
	right_vbox.add_child(lbl_fact_title)
	
	lbl_fact_leader = Label.new()
	lbl_fact_leader.text = "Ruler: Khagan Genghis Khan  |  Capital: Sarai  |  Difficulty: Standard"
	lbl_fact_leader.add_theme_font_size_override("font_size", 13)
	lbl_fact_leader.add_theme_color_override("font_color", Color(0.85, 0.78, 0.65))
	right_vbox.add_child(lbl_fact_leader)
	
	# Quote
	lbl_fact_quote = Label.new()
	lbl_fact_quote.text = "“The greatest joy is to scatter your enemy, to drive him before you...”"
	lbl_fact_quote.add_theme_font_size_override("font_size", 12)
	lbl_fact_quote.add_theme_color_override("font_color", Color(0.9, 0.75, 0.50))
	lbl_fact_quote.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	right_vbox.add_child(lbl_fact_quote)
	
	var hs_mid = HSeparator.new()
	right_vbox.add_child(hs_mid)
	
	# Description
	lbl_fact_desc = Label.new()
	lbl_fact_desc.text = "Rulers of the vast Eurasian steppe..."
	lbl_fact_desc.add_theme_font_size_override("font_size", 13)
	lbl_fact_desc.add_theme_color_override("font_color", Color(0.9, 0.88, 0.82))
	lbl_fact_desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	right_vbox.add_child(lbl_fact_desc)
	
	# Bonuses Section
	var lbl_bonus_hdr = Label.new()
	lbl_bonus_hdr.text = "UNIQUE CIVILIZATION BONUSES & DOCTRINES:"
	lbl_bonus_hdr.add_theme_font_size_override("font_size", 13)
	lbl_bonus_hdr.add_theme_color_override("font_color", Palette.BRONZE_GOLD)
	right_vbox.add_child(lbl_bonus_hdr)
	
	lbl_fact_bonuses = Label.new()
	lbl_fact_bonuses.text = "• +15% Cavalry Attack Power\n• +20% Movement Speed"
	lbl_fact_bonuses.add_theme_font_size_override("font_size", 13)
	lbl_fact_bonuses.add_theme_color_override("font_color", Color(0.85, 0.95, 0.75))
	lbl_fact_bonuses.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	right_vbox.add_child(lbl_fact_bonuses)
	
	# Starting Realm
	lbl_fact_realm = Label.new()
	lbl_fact_realm.text = "Realm Start: Controls Sarai (Capital) and Kipchak Steppe."
	lbl_fact_realm.add_theme_font_size_override("font_size", 12)
	lbl_fact_realm.add_theme_color_override("font_color", Color(0.75, 0.70, 0.60))
	lbl_fact_realm.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	right_vbox.add_child(lbl_fact_realm)
	
	# Bottom Action Bar
	var hs_bottom = HSeparator.new()
	main_vbox.add_child(hs_bottom)
	
	var footer_hbox = HBoxContainer.new()
	footer_hbox.add_theme_constant_override("separation", 16)
	main_vbox.add_child(footer_hbox)
	
	var btn_back = Button.new()
	btn_back.text = "← BACK TO MENU"
	btn_back.custom_minimum_size = Vector2(180, 46)
	btn_back.add_theme_font_size_override("font_size", 15)
	var sb_back = StyleBoxFlat.new()
	sb_back.bg_color = Color(0.24, 0.20, 0.16)
	sb_back.set_border_width_all(1)
	sb_back.border_color = Color(0.65, 0.52, 0.3)
	sb_back.set_corner_radius_all(6)
	btn_back.add_theme_stylebox_override("normal", sb_back)
	btn_back.pressed.connect(func():
		_play_click()
		faction_modal.visible = false
	)
	footer_hbox.add_child(btn_back)
	
	btn_embark = Button.new()
	btn_embark.text = "⚔ EMBARK ON CAMPAIGN AS MONGOL KHANATE"
	btn_embark.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	btn_embark.custom_minimum_size = Vector2(0, 46)
	btn_embark.add_theme_font_size_override("font_size", 16)
	btn_embark.add_theme_color_override("font_color", Color(1.0, 0.98, 0.90))
	var sb_emb = StyleBoxFlat.new()
	sb_emb.bg_color = Color(0.48, 0.32, 0.12)
	sb_emb.set_border_width_all(2)
	sb_emb.border_color = Palette.BRONZE_GOLD
	sb_emb.set_corner_radius_all(6)
	btn_embark.add_theme_stylebox_override("normal", sb_emb)
	btn_embark.pressed.connect(_on_embark_campaign_pressed)
	footer_hbox.add_child(btn_embark)
	
	# Initial selection
	_select_faction("mongol")

func _select_faction(faction_id: String):
	_play_click()
	selected_faction_id = faction_id
	if not FACTIONS_CATALOG.has(faction_id):
		return
	var fdata = FACTIONS_CATALOG[faction_id]
	
	# Update buttons styling
	for fid in faction_card_buttons:
		var btn = faction_card_buttons[fid]
		var is_sel = (fid == faction_id)
		var sb_btn = StyleBoxFlat.new()
		sb_btn.set_corner_radius_all(6)
		if is_sel:
			sb_btn.bg_color = Color(0.25, 0.20, 0.14, 0.98)
			sb_btn.set_border_width_all(2)
			sb_btn.border_color = Palette.BRONZE_GOLD
		else:
			sb_btn.bg_color = Color(0.14, 0.11, 0.09, 0.85)
			sb_btn.set_border_width_all(1)
			sb_btn.border_color = Color(0.35, 0.30, 0.24)
		btn.add_theme_stylebox_override("normal", sb_btn)
		
		var sb_h = StyleBoxFlat.new()
		sb_h.set_corner_radius_all(6)
		sb_h.bg_color = sb_btn.bg_color.lightened(0.15)
		sb_h.set_border_width_all(2)
		sb_h.border_color = Palette.BRONZE_GOLD.lightened(0.2)
		btn.add_theme_stylebox_override("hover", sb_h)
		
	# Update dossier text
	lbl_fact_title.text = fdata.icon + "  " + fdata.name.to_upper()
	lbl_fact_title.add_theme_color_override("font_color", fdata.color)
	
	lbl_fact_leader.text = "Ruler: %s  |  Capital: %s  |  Difficulty: %s" % [fdata.leader, fdata.capital, fdata.difficulty]
	lbl_fact_quote.text = fdata.quote
	lbl_fact_desc.text = fdata.desc
	
	var bonus_text = ""
	for b in fdata.bonuses:
		bonus_text += "• " + b + "\n"
	lbl_fact_bonuses.text = bonus_text.strip_edges()
	
	lbl_fact_realm.text = "🗺 " + fdata.starting_realm
	
	btn_embark.text = "⚔ EMBARK ON CAMPAIGN AS " + fdata.name.to_upper()
	var sb_emb = StyleBoxFlat.new()
	sb_emb.bg_color = fdata.color.darkened(0.5)
	sb_emb.set_border_width_all(2)
	sb_emb.border_color = fdata.color
	sb_emb.set_corner_radius_all(6)
	btn_embark.add_theme_stylebox_override("normal", sb_emb)

func _on_embark_campaign_pressed():
	_play_click()
	var gm = _get_game_manager()
	if gm:
		gm.start_new_campaign(selected_faction_id)
	get_tree().change_scene_to_file("res://scenes/campaign/campaign_view.tscn")

func _create_settings_modal():
	settings_modal = PanelContainer.new()
	settings_modal.name = "SettingsModal"
	settings_modal.set_anchors_preset(Control.PRESET_CENTER)
	settings_modal.offset_left = -240
	settings_modal.offset_top = -220
	settings_modal.offset_right = 240
	settings_modal.offset_bottom = 220
	
	var sb = StyleBoxFlat.new()
	sb.bg_color = Color(0.12, 0.10, 0.08, 0.98)
	sb.set_border_width_all(2)
	sb.border_color = Color(0.72, 0.58, 0.28)
	sb.set_corner_radius_all(8)
	sb.content_margin_left = 28
	sb.content_margin_right = 28
	sb.content_margin_top = 24
	sb.content_margin_bottom = 24
	settings_modal.add_theme_stylebox_override("panel", sb)
	settings_modal.visible = false
	ui_layer.add_child(settings_modal)
	
	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 14)
	settings_modal.add_child(vbox)
	
	var title = Label.new()
	title.text = "SETTINGS & AUDIO"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 22)
	title.add_theme_color_override("font_color", Color(1.0, 0.88, 0.35))
	vbox.add_child(title)
	
	# Audio Volume Sliders
	var am = _get_audio_manager()
	
	var lbl_master = Label.new()
	lbl_master.text = "Master Volume"
	vbox.add_child(lbl_master)
	var s_master = HSlider.new()
	s_master.min_value = 0.0
	s_master.max_value = 1.0
	s_master.step = 0.05
	s_master.value = am.master_volume if am else 0.85
	s_master.value_changed.connect(func(v): if am: am.set_master_volume(v))
	vbox.add_child(s_master)
	
	var lbl_music = Label.new()
	lbl_music.text = "Music Volume"
	vbox.add_child(lbl_music)
	var s_music = HSlider.new()
	s_music.min_value = 0.0
	s_music.max_value = 1.0
	s_music.step = 0.05
	s_music.value = am.music_volume if am else 0.65
	s_music.value_changed.connect(func(v): if am: am.set_music_volume(v))
	vbox.add_child(s_music)
	
	var lbl_sfx = Label.new()
	lbl_sfx.text = "SFX Volume"
	vbox.add_child(lbl_sfx)
	var s_sfx = HSlider.new()
	s_sfx.min_value = 0.0
	s_sfx.max_value = 1.0
	s_sfx.step = 0.05
	s_sfx.value = am.sfx_volume if am else 0.8
	s_sfx.value_changed.connect(func(v): if am: am.set_sfx_volume(v))
	vbox.add_child(s_sfx)
	
	var btn_fs = CheckButton.new()
	btn_fs.text = "Fullscreen Mode"
	btn_fs.button_pressed = (DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN or DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN)
	btn_fs.toggled.connect(func(pressed):
		if pressed:
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN)
		else:
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
	)
	vbox.add_child(btn_fs)
	
	var btn_close = Button.new()
	btn_close.text = "Close"
	btn_close.pressed.connect(func():
		_play_click()
		settings_modal.visible = false
	)
	vbox.add_child(btn_close)

func _play_click():
	var am = _get_audio_manager()
	if am:
		am.play_click()

func _get_audio_manager():
	var loop = Engine.get_main_loop() as SceneTree
	if loop and loop.root and loop.root.has_node("AudioManager"):
		return loop.root.get_node("AudioManager")
	return null

func _on_new_campaign_pressed():
	_play_click()
	if faction_modal:
		faction_modal.visible = true
		_select_faction(selected_faction_id)

func _on_continue_pressed():
	_play_click()
	var gm = _get_game_manager()
	if gm and gm.load_game():
		get_tree().change_scene_to_file("res://scenes/campaign/campaign_view.tscn")
	else:
		info_label.text = "No saved game found. Starting new campaign..."
		_on_new_campaign_pressed()

func _on_settings_pressed():
	_play_click()
	settings_modal.visible = true

func _on_quit_pressed():
	_play_click()
	get_tree().quit()

func _unhandled_input(event: InputEvent):
	if event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
		if faction_modal and faction_modal.visible:
			faction_modal.visible = false
			_play_click()
		elif settings_modal and settings_modal.visible:
			settings_modal.visible = false
			_play_click()

func _get_game_manager():
	var root = Engine.get_main_loop().root if Engine.get_main_loop() else null
	if root and root.has_node("GameManager"):
		return root.get_node("GameManager")
	return null
