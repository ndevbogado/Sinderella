class_name UITheme
extends RefCounted

const INK := Color("#080b11")
const PANEL := Color("#121822e8")
const PANEL_SOLID := Color("#121822")
const BONE := Color("#ebe5d8")
const MUTED := Color("#9ea6b2")
const GOLD := Color("#c8a766")
const GOLD_BRIGHT := Color("#edd49a")
const CRIMSON := Color("#8f3443")


static func make_theme() -> Theme:
	var theme := Theme.new()
	theme.default_font_size = 18
	theme.set_color("font_color", "Label", BONE)
	theme.set_color("font_shadow_color", "Label", Color(0, 0, 0, 0.75))
	theme.set_constant("shadow_offset_x", "Label", 1)
	theme.set_constant("shadow_offset_y", "Label", 2)

	theme.set_font_size("font_size", "Button", 18)
	theme.set_color("font_color", "Button", BONE)
	theme.set_color("font_hover_color", "Button", GOLD_BRIGHT)
	theme.set_color("font_pressed_color", "Button", GOLD_BRIGHT)
	theme.set_color("font_focus_color", "Button", GOLD_BRIGHT)
	theme.set_color("font_disabled_color", "Button", Color(0.55, 0.57, 0.61, 0.55))
	theme.set_stylebox("normal", "Button", _box(Color("#10151ed9"), Color("#414957"), 1, 8, 14))
	theme.set_stylebox("hover", "Button", _box(Color("#19212ddd"), GOLD, 1, 8, 14))
	theme.set_stylebox("pressed", "Button", _box(Color("#202837ee"), GOLD_BRIGHT, 2, 8, 14))
	theme.set_stylebox("focus", "Button", _box(Color("#19212ddd"), GOLD, 2, 8, 14))
	theme.set_stylebox("disabled", "Button", _box(Color("#0e1219aa"), Color("#333946"), 1, 8, 14))

	theme.set_stylebox("panel", "PanelContainer", _box(PANEL, Color("#3d4654"), 1, 12, 20))
	theme.set_stylebox(
		"background", "ProgressBar", _box(Color("#222935"), Color.TRANSPARENT, 0, 2, 0)
	)
	theme.set_stylebox("fill", "ProgressBar", _box(GOLD, Color.TRANSPARENT, 0, 2, 0))
	theme.set_color("font_color", "ProgressBar", Color.TRANSPARENT)
	theme.set_stylebox("slider", "HSlider", _box(Color("#2b3340"), Color.TRANSPARENT, 0, 4, 0))
	theme.set_stylebox("grabber_area", "HSlider", _box(GOLD, Color.TRANSPARENT, 0, 4, 0))
	theme.set_icon("grabber", "HSlider", _circle_icon(14, GOLD_BRIGHT))
	theme.set_icon("grabber_highlight", "HSlider", _circle_icon(16, Color.WHITE))
	return theme


static func make_panel(
	color: Color = PANEL,
	border: Color = Color("#3d4654"),
	width: int = 1,
	radius: int = 12,
	padding: int = 20
) -> StyleBoxFlat:
	return _box(color, border, width, radius, padding)


static func _box(
	color: Color, border: Color, width: int, radius: int, padding: int
) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.border_color = border
	style.set_border_width_all(width)
	style.set_corner_radius_all(radius)
	style.content_margin_left = padding
	style.content_margin_right = padding
	style.content_margin_top = padding
	style.content_margin_bottom = padding
	return style


static func _circle_icon(size_px: int, color: Color) -> ImageTexture:
	var image := Image.create(size_px, size_px, false, Image.FORMAT_RGBA8)
	image.fill(Color.TRANSPARENT)
	var center := Vector2(size_px - 1, size_px - 1) * 0.5
	var radius := size_px * 0.42
	for y in size_px:
		for x in size_px:
			if Vector2(x, y).distance_to(center) <= radius:
				image.set_pixel(x, y, color)
	return ImageTexture.create_from_image(image)
