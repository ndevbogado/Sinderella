class_name ComicPanel
extends Control

var panel_data: Dictionary = {}

var _image: TextureRect
var _border: Panel
var _text_nodes: Array[Control] = []
var _base_image_position := Vector2.ZERO


func configure(data: Dictionary) -> void:
	panel_data = data.duplicate(true)
	clip_contents = true
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	# El filtrado lineal sin mipmaps mantiene nítidas las letras ya dibujadas
	# dentro de páginas de cómic reducidas a la resolución del juego.
	texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	_build_image()
	_build_border()
	_build_texts()


func set_normalized_rect(normalized_rect: Array, viewport_size: Vector2) -> void:
	if normalized_rect.size() < 4:
		return
	position = Vector2(float(normalized_rect[0]), float(normalized_rect[1])) * viewport_size
	size = Vector2(float(normalized_rect[2]), float(normalized_rect[3])) * viewport_size
	_update_inner_layout()


func start_internal_motion(duration: float) -> void:
	if Settings.reduce_motion or _image == null:
		return
	var zoom_from := float(panel_data.get("zoom_from", 1.0))
	var zoom_to := float(panel_data.get("zoom_to", 1.045))
	var pan_value: Array = panel_data.get("pan", [0.0, 0.0])
	var pan := Vector2(float(pan_value[0]), float(pan_value[1])) * size
	_image.scale = Vector2.ONE * zoom_from
	_image.position = _base_image_position - pan * 0.5
	var tween := create_tween().set_parallel(true)
	tween.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(_image, "scale", Vector2.ONE * zoom_to, duration)
	tween.tween_property(_image, "position", _base_image_position + pan * 0.5, duration)


func set_border_opacity(value: float) -> void:
	if _border != null:
		_border.modulate.a = value


func _build_image() -> void:
	_image = TextureRect.new()
	_image.name = "Artwork"
	_image.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_image.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	_image.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_image.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var image_path := str(panel_data.get("image", ""))
	if not image_path.is_empty():
		_image.texture = load(image_path)
	add_child(_image)


func _build_border() -> void:
	_border = Panel.new()
	_border.name = "InkBorder"
	_border.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_border.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var style := StyleBoxFlat.new()
	style.bg_color = Color.TRANSPARENT
	style.border_color = Color(str(panel_data.get("border_color", "#e8dfcf")))
	style.set_border_width_all(int(panel_data.get("border_width", 3)))
	style.set_corner_radius_all(int(panel_data.get("corner_radius", 2)))
	_border.add_theme_stylebox_override("panel", style)
	add_child(_border)


func _build_texts() -> void:
	var texts: Array = panel_data.get("texts", [])
	for text_data_value in texts:
		var text_data: Dictionary = text_data_value
		# Un Panel no impone el tamaño mínimo del Label. PanelContainer hacía que
		# el texto con ajuste de línea se midiera cuando todavía tenía ancho cero,
		# agrandando el globo hasta ocupar casi toda la viñeta.
		var holder := Panel.new()
		holder.mouse_filter = Control.MOUSE_FILTER_IGNORE
		holder.set_meta("rect", text_data.get("rect", [0.05, 0.05, 0.4, 0.2]))
		holder.set_meta("allow_overflow", bool(text_data.get("allow_overflow", false)))
		holder.rotation_degrees = float(text_data.get("rotation", 0.0))
		holder.z_index = int(text_data.get("z_index", 10))
		var kind := str(text_data.get("kind", "dialogue"))
		_apply_text_style(holder, kind, text_data)
		var label := Label.new()
		label.text = str(text_data.get("text", ""))
		label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		label.clip_text = true
		label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		label.horizontal_alignment = _alignment_from_string(str(text_data.get("align", "center")))
		label.add_theme_font_size_override("font_size", int(text_data.get("font_size", 20)))
		if kind == "dialogue" or kind == "thought":
			label.add_theme_color_override(
				"font_color", _read_color(text_data, "text_color", Color("#11141a"))
			)
			label.add_theme_color_override("font_shadow_color", Color.TRANSPARENT)
			label.add_theme_color_override("font_outline_color", Color.TRANSPARENT)
		elif kind == "sfx":
			label.add_theme_color_override(
				"font_color", _read_color(text_data, "text_color", UITheme.GOLD_BRIGHT)
			)
			label.add_theme_color_override("font_outline_color", Color("#080a0e"))
			label.add_theme_constant_override("outline_size", 7)
		else:
			label.add_theme_color_override(
				"font_color", _read_color(text_data, "text_color", UITheme.BONE)
			)
		holder.add_child(label)
		_layout_text_label(label, kind, text_data)
		add_child(holder)
		_text_nodes.append(holder)


func _apply_text_style(holder: Panel, kind: String, text_data: Dictionary) -> void:
	var style := StyleBoxFlat.new()
	match kind:
		"dialogue":
			style.bg_color = _read_color(text_data, "background_color", Color("#f7f2e8fa"))
			style.border_color = _read_color(text_data, "border_color", Color("#11141a"))
			style.set_border_width_all(int(text_data.get("border_width", 2)))
			style.set_corner_radius_all(int(text_data.get("corner_radius", 16)))
		"thought":
			style.bg_color = _read_color(text_data, "background_color", Color("#eee9dff7"))
			style.border_color = _read_color(text_data, "border_color", Color("#606775"))
			style.set_border_width_all(int(text_data.get("border_width", 1)))
			style.set_corner_radius_all(int(text_data.get("corner_radius", 22)))
		"sfx":
			style.bg_color = Color.TRANSPARENT
			style.border_color = Color.TRANSPARENT
		"_narration", "narration", "location":
			style.bg_color = _read_color(text_data, "background_color", Color("#090d14f2"))
			style.border_color = _read_color(text_data, "border_color", UITheme.GOLD)
			style.border_width_left = int(text_data.get("border_width", 3))
			style.set_corner_radius_all(int(text_data.get("corner_radius", 3)))
		_:
			style.bg_color = _read_color(text_data, "background_color", Color("#090d14ed"))
	holder.add_theme_stylebox_override("panel", style)


func _layout_text_label(label: Label, kind: String, text_data: Dictionary) -> void:
	label.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var horizontal_padding := float(text_data.get("padding_x", 16.0))
	var vertical_padding := float(text_data.get("padding_y", 9.0))
	if kind == "sfx":
		horizontal_padding = float(text_data.get("padding_x", 3.0))
		vertical_padding = float(text_data.get("padding_y", 3.0))
	label.offset_left = horizontal_padding
	label.offset_top = vertical_padding
	label.offset_right = -horizontal_padding
	label.offset_bottom = -vertical_padding


func _read_color(data: Dictionary, property_name: String, fallback: Color) -> Color:
	if not data.has(property_name):
		return fallback
	return Color(str(data[property_name]))


func _alignment_from_string(value: String) -> HorizontalAlignment:
	match value:
		"left":
			return HORIZONTAL_ALIGNMENT_LEFT
		"right":
			return HORIZONTAL_ALIGNMENT_RIGHT
		_:
			return HORIZONTAL_ALIGNMENT_CENTER


func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED and is_node_ready():
		_update_inner_layout()


func _update_inner_layout() -> void:
	if _image != null:
		_image.pivot_offset = size * 0.5
		var offset_data: Array = panel_data.get("image_offset", [0.0, 0.0])
		_base_image_position = Vector2(float(offset_data[0]), float(offset_data[1])) * size
		_image.position = _base_image_position
	for holder in _text_nodes:
		var rect_data: Array = holder.get_meta("rect")
		if rect_data.size() >= 4:
			var normalized_position := Vector2(float(rect_data[0]), float(rect_data[1]))
			var normalized_size := Vector2(float(rect_data[2]), float(rect_data[3]))
			if not bool(holder.get_meta("allow_overflow", false)):
				normalized_position.x = clampf(normalized_position.x, 0.0, 0.98)
				normalized_position.y = clampf(normalized_position.y, 0.0, 0.98)
				normalized_size.x = clampf(
					normalized_size.x, 0.02, 1.0 - normalized_position.x
				)
				normalized_size.y = clampf(
					normalized_size.y, 0.02, 1.0 - normalized_position.y
				)
			holder.position = normalized_position * size
			holder.size = normalized_size * size
