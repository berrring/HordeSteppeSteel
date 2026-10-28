class_name Palette
extends RefCounted

# ==============================================================================
# HORDE: STEPPE & STEEL — OFFICIAL FIVE-COLOR PALETTE
# ==============================================================================
# Steppe Green / Olive : Dominant terrain and steppe identity
const STEPPE_GREEN: Color = Color(0.42, 0.56, 0.14)   # #6B8E23

# Wood Brown           : Timber, yurts, palisades, natural materials
const WOOD_BROWN: Color = Color(0.36, 0.25, 0.20)     # #5C4033

# Bronze Gold          : UI accents, resource icons, coins, selection highlights
const BRONZE_GOLD: Color = Color(0.85, 0.65, 0.13)    # #DAA520

# Snow White / Light Gray : Snow, northern provinces, fog, light backgrounds
const SNOW_WHITE: Color = Color(0.91, 0.93, 0.94)     # #E8ECEF

# Deep Steel Blue      : Armor, outlines, dark UI panels, shadows
const DEEP_STEEL_BLUE: Color = Color(0.17, 0.23, 0.29)# #2B3A4A

# ==============================================================================
# SIX OFFICIAL FACTIONS SECONDARY ACCENTS
# ==============================================================================
const FACTION_MONGOL: Color = Color(0.85, 0.65, 0.13)    # Bronze Gold (#DAA520)
const FACTION_CUMAN: Color = Color(0.13, 0.70, 0.67)     # Turquoise Steppe Cyan (#20B2AA)
const FACTION_RUS: Color = Color(0.65, 0.18, 0.14)       # Forged Red / Rus' Crimson (#A52A2A)
const FACTION_BYZANTINE: Color = Color(0.55, 0.15, 0.55) # Imperial Purple (#800080)
const FACTION_SELJUK: Color = Color(0.18, 0.45, 0.70)    # Cobalt Blue (#2B5B84)
const FACTION_KHWARAZM: Color = Color(0.18, 0.55, 0.34)  # Silk Road Emerald (#2E8B57)
const FACTION_NEUTRAL: Color = Color(0.52, 0.50, 0.48)   # Weathered Stone

# ==============================================================================
# UI STYLEBOX GENERATORS (COHESIVE DEEP STEEL BLUE & BRONZE GOLD)
# ==============================================================================
static func get_faction_color(faction_id: String) -> Color:
	match faction_id:
		"mongol": return FACTION_MONGOL
		"cuman", "kipchak": return FACTION_CUMAN
		"rus": return FACTION_RUS
		"byzantine": return FACTION_BYZANTINE
		"seljuk": return FACTION_SELJUK
		"khwarazm": return FACTION_KHWARAZM
		_: return FACTION_NEUTRAL

static func create_panel_style(bg: Color = DEEP_STEEL_BLUE, border: Color = BRONZE_GOLD, border_w: int = 2, radius: int = 4) -> StyleBoxFlat:
	var sb = StyleBoxFlat.new()
	sb.bg_color = bg
	if border_w > 0:
		sb.set_border_width_all(border_w)
		sb.border_color = border
	sb.set_corner_radius_all(radius)
	sb.content_margin_left = 12
	sb.content_margin_right = 12
	sb.content_margin_top = 8
	sb.content_margin_bottom = 8
	return sb

static func create_button_style(bg: Color = DEEP_STEEL_BLUE, border: Color = BRONZE_GOLD, border_w: int = 1, radius: int = 4) -> StyleBoxFlat:
	var sb = StyleBoxFlat.new()
	sb.bg_color = bg
	if border_w > 0:
		sb.set_border_width_all(border_w)
		sb.border_color = border
	sb.set_corner_radius_all(radius)
	sb.content_margin_left = 14
	sb.content_margin_right = 14
	sb.content_margin_top = 8
	sb.content_margin_bottom = 8
	return sb
