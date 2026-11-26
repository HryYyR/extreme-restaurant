extends RefCounted

const Icon = preload("res://scripts/ui/ui_icon.gd")
const INK = Color("fbf0dc")
const MUTED = Color("b6c9c2")
const BG = Color("162831")
const PANEL = Color("233b40")
const PANEL_LIGHT = Color("304b4e")
const GOLD = Color("f1c181")
const GREEN = Color("9cd7bd")
const RED = Color("ffad98")

static var cached_font: Font

static func font() -> Font:
	if cached_font != null: return cached_font
	var settings = JSON.parse_string(FileAccess.get_file_as_string("res://assets/skins.json"))
	var custom = str(settings.get("font", "")) if settings is Dictionary else ""
	if not custom.is_empty() and ResourceLoader.exists(custom):
		cached_font = load(custom)
		return cached_font
	var system = SystemFont.new()
	system.font_names = PackedStringArray(["Microsoft YaHei", "Noto Sans CJK SC", "PingFang SC", "Arial"])
	system.font_weight = 400
	cached_font = system
	return cached_font

static func box(color: Color = PANEL, border: Color = Color("3d5240"), radius: int = 10, margin: int = 14) -> StyleBoxFlat:
	var style = StyleBoxFlat.new()
	style.bg_color = color
	style.border_color = border
	style.set_border_width_all(1)
	style.set_corner_radius_all(radius)
	style.content_margin_left = margin
	style.content_margin_right = margin
	style.content_margin_top = margin
	style.content_margin_bottom = margin
	return style

static func surface(accent: Color, margin := 14) -> StyleBoxFlat:
	var skin = box(PANEL, Color("547071"), 12, margin)
	skin.border_color = accent.darkened(0.36)
	skin.shadow_color = Color("152535", 0.34)
	skin.shadow_size = 7
	skin.shadow_offset = Vector2(0, 4)
	return skin

static func theme() -> Theme:
	var t = Theme.new()
	t.default_font = font()
	t.default_font_size = 15
	t.set_color("font_color", "Label", INK)
	t.set_color("font_color", "Button", INK)
	t.set_color("font_hover_color", "Button", INK)
	t.set_color("font_disabled_color", "Button", Color("a5b6b3"))
	t.set_stylebox("normal", "Button", box(PANEL_LIGHT, Color("537071"), 7, 10))
	t.set_stylebox("hover", "Button", box(Color("3e6060"), GREEN, 7, 10))
	t.set_stylebox("pressed", "Button", box(Color("466b68"), GOLD, 7, 10))
	t.set_stylebox("disabled", "Button", box(Color("2c4144"), Color("455b5d"), 7, 10))
	t.set_stylebox("focus", "Button", box(Color(0,0,0,0), GOLD, 7, 2))
	t.set_stylebox("panel", "PanelContainer", box(PANEL, Color("526b68")))
	t.set_stylebox("panel", "TooltipPanel", surface(GOLD, 10))
	t.set_color("font_color", "TooltipLabel", INK)
	t.set_stylebox("normal", "LineEdit", box(BG, MUTED.darkened(0.38), 7, 10))
	t.set_color("font_color", "LineEdit", INK)
	t.set_stylebox("focus", "LineEdit", box(BG, GOLD, 7, 10))
	t.set_stylebox("scroll", "VScrollBar", box(BG, BG, 5, 4))
	t.set_stylebox("grabber", "VScrollBar", box(Color("658782"), Color("658782"), 5, 4))
	t.set_stylebox("grabber_highlight", "VScrollBar", box(GREEN, GREEN, 5, 4))
	t.set_constant("separation", "VBoxContainer", 10)
	t.set_constant("separation", "HBoxContainer", 10)
	t.set_stylebox("background", "ProgressBar", box(Color("304536"), Color("304536"), 3, 0))
	t.set_stylebox("fill", "ProgressBar", box(GREEN, GREEN, 3, 0))
	return t

static func text(value: String, size: int = 15, color: Color = INK, wrap: bool = false) -> Label:
	var label = Label.new()
	label.text = value
	label.add_theme_font_size_override("font_size", size)
	label.add_theme_color_override("font_color", color)
	if wrap:
		label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	return label

static func button(value: String, accent: bool = false) -> Button:
	var b = Button.new()
	b.text = value
	b.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	b.custom_minimum_size.y = 38
	if accent:
		b.add_theme_stylebox_override("normal", box(Color("d6a65c"), Color("f1cd8b"), 7, 10))
		b.add_theme_stylebox_override("hover", box(Color("edbf78"), Color("f1cd8b"), 7, 10))
		b.add_theme_stylebox_override("pressed", box(Color("ba8d45"), Color("f1cd8b"), 7, 10))
		b.add_theme_color_override("font_color", Color("213325"))
		b.add_theme_color_override("font_hover_color", Color("213325"))
		b.add_theme_color_override("font_pressed_color", Color("213325"))
	return b

static func card() -> PanelContainer:
	return PanelContainer.new()

static func readout(parent: Control, glyph: String, value: String, description: String, tint: Color = GOLD, points := 17) -> Label:
	var row = HBoxContainer.new()
	row.add_theme_constant_override("separation", 5)
	row.mouse_filter = Control.MOUSE_FILTER_PASS
	row.tooltip_text = description
	parent.add_child(row)
	row.add_child(Icon.make(glyph, tint, 18.0))
	var label = text(value, points, tint)
	label.tooltip_text = description
	row.add_child(label)
	return label
