class_name BattleStyle
extends RefCounted
const GOLD = Color("ba9660")
const PALE = Color("e5dfca")
const MUTED = Color("a3ada4")
const CYAN = Color("75ded7")
const RED = Color("ec777b")
const GREEN = Color("8ad6a4")

static func box(border: Color = GOLD, fill: Color = Color("0c1517f2")) -> StyleBoxFlat:
	var style = StyleBoxFlat.new()
	style.bg_color = fill
	style.border_color = border
	style.set_border_width_all(1)
	style.set_corner_radius_all(3)
	style.content_margin_left = 12
	style.content_margin_right = 12
	style.content_margin_top = 8
	style.content_margin_bottom = 8
	return style

static func make_theme() -> Theme:
	var t = Theme.new()
	t.default_font = load("res://sinderella/assets/body.ttf")
	t.default_font_size = 16
	t.set_color("font_color", "Label", PALE)
	t.set_color("font_color", "Button", PALE)
	t.set_color("font_hover_color", "Button", CYAN)
	t.set_color("font_disabled_color", "Button", Color("697873"))
	t.set_stylebox("panel", "Panel", box())
	t.set_stylebox("panel", "PanelContainer", box())
	t.set_stylebox("normal", "Button", box(Color("645b46")))
	t.set_stylebox("hover", "Button", box(CYAN, Color("163033")))
	t.set_stylebox("pressed", "Button", box(CYAN, Color("235052")))
	t.set_stylebox("focus", "Button", box(CYAN, Color(0, 0, 0, 0)))
	t.set_stylebox("disabled", "Button", box(Color("35413a"), Color("0c1517d9")))
	t.set_stylebox("background", "ProgressBar", bar_box(Color("080e11")))
	t.set_stylebox("fill", "ProgressBar", bar_box(Color("48ab78")))
	t.set_stylebox("panel", "PopupPanel", box())
	return t

static func bar_box(color: Color) -> StyleBoxFlat:
	var style = StyleBoxFlat.new()
	style.bg_color = color
	style.set_content_margin_all(0)
	style.set_corner_radius_all(2)
	return style

static func label(text: String, font_size: int = 16, color: Color = PALE) -> Label:
	var node = Label.new()
	node.text = text
	node.add_theme_font_size_override("font_size", font_size)
	node.add_theme_color_override("font_color", color)
	node.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return node
