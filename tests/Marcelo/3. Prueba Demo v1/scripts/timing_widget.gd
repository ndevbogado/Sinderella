class_name TimingWidget
extends Control

signal resolved(score: float)

const GOOD_ZONE_WIDTH: float = 0.44
const PERFECT_ZONE_WIDTH: float = 0.12
const MIN_TARGET_SEPARATION: float = 0.12
const FEEDBACK_DURATION: float = 0.78

const RESULT_MISS: int = 0
const RESULT_UNSTABLE: int = 1
const RESULT_FIRM: int = 2
const RESULT_PERFECT: int = 3
const RESULT_CENTER: int = 4

var active: bool = false
var resolving: bool = false
var cursor: float = 0.0
var direction: float = 1.0
var speed: float = 0.95
var target_center: float = 0.5
var previous_target_center: float = -1.0
var rng: RandomNumberGenerator = RandomNumberGenerator.new()

var feedback_elapsed: float = 0.0
var feedback_score: float = 0.0
var feedback_kind: int = RESULT_MISS
var feedback_label: String = ""
var feedback_detail: String = ""
var press_direction: float = 1.0

func _ready() -> void:
	custom_minimum_size = Vector2(620, 126)
	mouse_filter = Control.MOUSE_FILTER_STOP
	gui_input.connect(_on_gui_input)
	rng.randomize()
	set_process(true)

func begin(new_speed: float = 0.95) -> void:
	speed = new_speed
	cursor = 0.05
	direction = 1.0
	target_center = _pick_random_target_center()
	previous_target_center = target_center
	feedback_elapsed = 0.0
	feedback_score = 0.0
	feedback_label = ""
	feedback_detail = ""
	resolving = false
	active = true
	queue_redraw()

func _pick_random_target_center() -> float:
	var half_good_width: float = GOOD_ZONE_WIDTH * 0.5
	var minimum_center: float = half_good_width
	var maximum_center: float = 1.0 - half_good_width
	var candidate: float = rng.randf_range(minimum_center, maximum_center)

	# Evita que dos intentos consecutivos parezcan estar en el mismo lugar.
	if previous_target_center >= 0.0:
		for attempt: int in range(8):
			candidate = rng.randf_range(minimum_center, maximum_center)
			if absf(candidate - previous_target_center) >= MIN_TARGET_SEPARATION:
				break

	return candidate

func resolve_now() -> void:
	if not active:
		return

	active = false
	resolving = true
	press_direction = direction
	feedback_score = _calculate_score()
	feedback_kind = _get_feedback_kind(feedback_score)
	feedback_elapsed = 0.0
	feedback_label = _get_feedback_label(feedback_kind)
	feedback_detail = _get_feedback_detail(feedback_kind)
	queue_redraw()

func _calculate_score() -> float:
	var distance: float = absf(cursor - target_center)
	var perfect_half_width: float = PERFECT_ZONE_WIDTH * 0.5
	var good_half_width: float = GOOD_ZONE_WIDTH * 0.5

	# Toda la zona clara cuenta como resultado perfecto.
	if distance <= perfect_half_width:
		var perfect_ratio: float = distance / perfect_half_width
		return lerpf(1.0, 0.92, perfect_ratio)

	# La zona violeta produce resultados firmes o inestables.
	if distance <= good_half_width:
		var good_ratio: float = (distance - perfect_half_width) / (good_half_width - perfect_half_width)
		return lerpf(0.919, 0.45, good_ratio)

	# Fuera de ambas zonas, la puntuación cae gradualmente hasta cero.
	var farthest_edge: float = maxf(target_center, 1.0 - target_center)
	var miss_range: float = maxf(0.001, farthest_edge - good_half_width)
	var miss_ratio: float = clampf((distance - good_half_width) / miss_range, 0.0, 1.0)
	return lerpf(0.449, 0.0, miss_ratio)

func _get_feedback_kind(score: float) -> int:
	if score >= 0.985:
		return RESULT_CENTER
	if score >= 0.92:
		return RESULT_PERFECT
	if score >= 0.72:
		return RESULT_FIRM
	if score >= 0.45:
		return RESULT_UNSTABLE
	return RESULT_MISS

func _get_feedback_label(kind: int) -> String:
	match kind:
		RESULT_CENTER:
			return "CENTRO ABSOLUTO"
		RESULT_PERFECT:
			return "PALABRA PERFECTA"
		RESULT_FIRM:
			return "AFIRMACIÓN FIRME"
		RESULT_UNSTABLE:
			return "CASI"
		_:
			return "FRASE INTERRUMPIDA"

func _get_feedback_detail(kind: int) -> String:
	if kind >= RESULT_PERFECT:
		return "La palabra encajó en la realidad."
	if kind == RESULT_FIRM:
		return "La afirmación se sostiene."

	# El signo se interpreta según la dirección en la que viajaba la aguja.
	# Negativo: se detuvo antes de alcanzar el centro. Positivo: lo sobrepasó.
	var timing_error: float = (cursor - target_center) * press_direction
	if timing_error < 0.0:
		return "Pulsaste demasiado pronto."
	return "Pulsaste demasiado tarde."

func _process(delta: float) -> void:
	if active:
		cursor += direction * speed * delta
		if cursor >= 1.0:
			cursor = 1.0
			direction = -1.0
		elif cursor <= 0.0:
			cursor = 0.0
			direction = 1.0
		queue_redraw()
		return

	if resolving:
		feedback_elapsed += delta
		queue_redraw()
		if feedback_elapsed >= FEEDBACK_DURATION:
			resolving = false
			resolved.emit(feedback_score)

func _on_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		resolve_now()

func _draw() -> void:
	var progress: float = clampf(feedback_elapsed / FEEDBACK_DURATION, 0.0, 1.0) if resolving else 0.0
	var fade: float = 1.0 - progress
	var shake_x: float = _get_shake_offset(progress)
	var bar: Rect2 = Rect2(Vector2(28 + shake_x, 25), Vector2(size.x - 56, 28))
	var good_start: float = target_center - GOOD_ZONE_WIDTH * 0.5
	var perfect_start: float = target_center - PERFECT_ZONE_WIDTH * 0.5

	var base_color: Color = Color("211c2c")
	var good_color: Color = Color("67537b")
	var perfect_color: Color = Color("d9c7ed")
	if resolving:
		var flash_color: Color = _feedback_color(feedback_kind)
		var pulse: float = maxf(0.0, sin(feedback_elapsed * 25.0)) * fade
		base_color = base_color.lerp(flash_color, pulse * 0.22)
		good_color = good_color.lerp(flash_color, pulse * 0.34)
		perfect_color = perfect_color.lerp(Color.WHITE, pulse * 0.55)

	draw_rect(bar, base_color, true)
	draw_rect(
		Rect2(
			Vector2(bar.position.x + bar.size.x * good_start, bar.position.y),
			Vector2(bar.size.x * GOOD_ZONE_WIDTH, bar.size.y)
		),
		good_color,
		true
	)
	draw_rect(
		Rect2(
			Vector2(bar.position.x + bar.size.x * perfect_start, bar.position.y),
			Vector2(bar.size.x * PERFECT_ZONE_WIDTH, bar.size.y)
		),
		perfect_color,
		true
	)
	draw_rect(bar, Color("b9a6c9"), false, 2.0)

	var cursor_x: float = bar.position.x + bar.size.x * cursor
	var hit_point: Vector2 = Vector2(cursor_x, bar.position.y + bar.size.y * 0.5)
	var cursor_color: Color = Color("fff6d7")
	var cursor_width: float = 4.0
	if resolving:
		cursor_color = _feedback_color(feedback_kind)
		cursor_width = 4.0 + fade * 4.0

	draw_line(Vector2(cursor_x, 14), Vector2(cursor_x, 66), cursor_color, cursor_width)
	draw_circle(Vector2(cursor_x, 14), 5.0 + (fade * 3.0 if resolving else 0.0), cursor_color)

	if resolving:
		_draw_feedback_effects(hit_point, bar, progress, fade)
		_draw_feedback_text(progress, fade)

func _get_shake_offset(progress: float) -> float:
	if not resolving:
		return 0.0
	var fade: float = 1.0 - progress
	match feedback_kind:
		RESULT_CENTER:
			return sin(feedback_elapsed * 55.0) * 1.2 * fade
		RESULT_PERFECT:
			return sin(feedback_elapsed * 48.0) * 1.8 * fade
		RESULT_FIRM:
			return sin(feedback_elapsed * 42.0) * 1.0 * fade
		RESULT_UNSTABLE:
			return sin(feedback_elapsed * 52.0) * 3.2 * fade
		_:
			return sin(feedback_elapsed * 68.0) * 7.0 * fade

func _feedback_color(kind: int) -> Color:
	match kind:
		RESULT_CENTER:
			return Color("fff4b0")
		RESULT_PERFECT:
			return Color("f2deff")
		RESULT_FIRM:
			return Color("a9e6d1")
		RESULT_UNSTABLE:
			return Color("f1bd78")
		_:
			return Color("ef7272")

func _draw_feedback_effects(hit_point: Vector2, bar: Rect2, progress: float, fade: float) -> void:
	var effect_color: Color = _feedback_color(feedback_kind)
	effect_color.a = fade

	match feedback_kind:
		RESULT_CENTER:
			# Explosión limpia: dos ondas y rayos simétricos desde el punto exacto.
			_draw_ring(hit_point, 10.0 + progress * 54.0, effect_color, 4.0 * fade)
			_draw_ring(hit_point, 4.0 + progress * 82.0, Color(effect_color, fade * 0.55), 2.0)
			_draw_radial_sparks(hit_point, 18, 18.0 + progress * 38.0, effect_color, fade)
			var white_flash: Color = Color(1.0, 1.0, 1.0, maxf(0.0, 0.25 - progress) * 1.8)
			draw_rect(Rect2(Vector2.ZERO, size), white_flash, true)
		RESULT_PERFECT:
			_draw_ring(hit_point, 8.0 + progress * 46.0, effect_color, 3.0 * fade)
			_draw_radial_sparks(hit_point, 10, 14.0 + progress * 28.0, effect_color, fade)
		RESULT_FIRM:
			_draw_ring(hit_point, 7.0 + progress * 32.0, effect_color, 2.5 * fade)
			var target_x: float = bar.position.x + bar.size.x * target_center
			draw_line(hit_point, Vector2(target_x, hit_point.y), Color(effect_color, fade * 0.45), 2.0)
		RESULT_UNSTABLE:
			# Una estela muestra cuánto faltó y hacia qué lado estaba el centro.
			var target_x: float = bar.position.x + bar.size.x * target_center
			draw_line(hit_point, Vector2(target_x, hit_point.y), Color(effect_color, fade * 0.75), 3.0)
			_draw_chevrons(hit_point, Vector2(target_x, hit_point.y), effect_color, fade)
		_:
			# El cursor se fractura y la barra recibe un golpe seco.
			_draw_cracks(hit_point, effect_color, fade)
			var miss_overlay: Color = Color(effect_color, maxf(0.0, 0.18 - progress * 0.18))
			draw_rect(Rect2(Vector2.ZERO, size), miss_overlay, true)

func _draw_ring(center: Vector2, radius: float, color: Color, width: float) -> void:
	if width <= 0.05:
		return
	draw_arc(center, radius, 0.0, TAU, 48, color, width, true)

func _draw_radial_sparks(center: Vector2, count: int, radius: float, color: Color, fade: float) -> void:
	for index: int in range(count):
		var angle: float = TAU * float(index) / float(count) + feedback_elapsed * 0.35
		var inner: float = radius * 0.55
		var outer: float = radius + 8.0 * fade
		var from_point: Vector2 = center + Vector2(cos(angle), sin(angle)) * inner
		var to_point: Vector2 = center + Vector2(cos(angle), sin(angle)) * outer
		draw_line(from_point, to_point, color, 1.5 + fade * 1.5)

func _draw_chevrons(from_point: Vector2, to_point: Vector2, color: Color, fade: float) -> void:
	var delta: Vector2 = to_point - from_point
	if delta.length() < 3.0:
		return
	var direction_to_target: Vector2 = delta.normalized()
	var perpendicular: Vector2 = Vector2(-direction_to_target.y, direction_to_target.x)
	for index: int in range(3):
		var t: float = 0.28 + float(index) * 0.2
		var center: Vector2 = from_point.lerp(to_point, t)
		var back: Vector2 = center - direction_to_target * 6.0
		draw_line(back + perpendicular * 4.0, center, Color(color, fade), 2.0)
		draw_line(back - perpendicular * 4.0, center, Color(color, fade), 2.0)

func _draw_cracks(center: Vector2, color: Color, fade: float) -> void:
	for index: int in range(7):
		var angle: float = TAU * float(index) / 7.0 + 0.23
		var first: Vector2 = center + Vector2(cos(angle), sin(angle)) * (7.0 + float(index % 2) * 2.0)
		var middle: Vector2 = center + Vector2(cos(angle + 0.12), sin(angle + 0.12)) * (17.0 + float(index % 3) * 3.0)
		var last: Vector2 = center + Vector2(cos(angle - 0.08), sin(angle - 0.08)) * (27.0 + float(index % 2) * 4.0)
		draw_line(first, middle, Color(color, fade), 2.5)
		draw_line(middle, last, Color(color, fade * 0.65), 1.5)

func _draw_feedback_text(progress: float, fade: float) -> void:
	var font: Font = ThemeDB.fallback_font
	var effect_color: Color = _feedback_color(feedback_kind)
	var entrance: float = clampf(progress / 0.22, 0.0, 1.0)
	var label_alpha: float = minf(1.0, entrance * 1.5)
	if progress > 0.78:
		label_alpha *= clampf((1.0 - progress) / 0.22, 0.0, 1.0)

	var bounce: float = sin(entrance * PI) * 5.0
	var label_size: int = 22
	if feedback_kind == RESULT_CENTER:
		label_size = 27
	elif feedback_kind == RESULT_PERFECT:
		label_size = 25

	var label_color: Color = Color(effect_color, label_alpha)
	var detail_color: Color = Color("d8ccde")
	detail_color.a = label_alpha * 0.9
	draw_string(
		font,
		Vector2(0.0, 91.0 - bounce),
		feedback_label,
		HORIZONTAL_ALIGNMENT_CENTER,
		size.x,
		label_size,
		label_color
	)
	draw_string(
		font,
		Vector2(0.0, 116.0),
		feedback_detail,
		HORIZONTAL_ALIGNMENT_CENTER,
		size.x,
		15,
		detail_color
	)
