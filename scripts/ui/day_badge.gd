extends Control

const Style = preload("res://scripts/ui/style.gd")
var day = 1
var phase = "NIGHT"
var progress = 0.0
var font: Font
var icon_motion: Tween
var rainy := false
var storm := false
var daylight := 0.0:
	set(value):
		daylight = value
		queue_redraw()

func _ready() -> void:
	font = Style.font()
	custom_minimum_size = Vector2(60, 60)
	mouse_filter = Control.MOUSE_FILTER_PASS

func set_state(value: int, mode: String, ratio: float) -> void:
	if day == value and phase == mode and is_equal_approx(progress, ratio): return
	if (phase == "DAY") != (mode == "DAY"):
		if icon_motion != null and icon_motion.is_valid(): icon_motion.kill()
		icon_motion = create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		icon_motion.tween_property(self, "daylight", 1.0 if mode == "DAY" else 0.0, .38)
	day = value
	phase = mode
	progress = ratio
	queue_redraw()

func set_weather(has_rain: bool, has_thunder: bool) -> void:
	if rainy == has_rain and storm == has_thunder: return
	rainy = has_rain
	storm = has_thunder
	queue_redraw()

func _draw_weather(icon: Vector2) -> void:
	var cloud = Color("bcd5d5").lerp(Color("cad6ec"), .78 if storm else .0)
	draw_circle(icon + Vector2(-4, -2), 3.1, cloud, true, -1, true)
	draw_circle(icon + Vector2(0, -4), 4.1, cloud, true, -1, true)
	draw_circle(icon + Vector2(4.5, -1.8), 3.05, cloud, true, -1, true)
	draw_rect(Rect2(icon + Vector2(-4.8, -2), Vector2(10.2, 3.15)), cloud)
	for x in [-5, 0, 5]:
		if storm and x == 0: continue
		var at = icon + Vector2(x, 3)
		draw_line(at, at + Vector2(-1.6, 2.6), Color("93c5d8"), 1.3, true)
	if storm:
		draw_colored_polygon(PackedVector2Array([icon + Vector2(1, 1), icon + Vector2(-2, 5), icon + Vector2(.3, 5), icon + Vector2(-.4, 8), icon + Vector2(3, 4), icon + Vector2(.8, 4)]), Style.GOLD)

func _draw() -> void:
	if font == null: return
	var center = Vector2(size.x * .5, size.y * .5)
	var sky = Color("34464a").lerp(Color("396853"), daylight)
	draw_circle(center, 28, Color("12231e"))
	draw_circle(center, 25, sky)
	draw_arc(center, 26.5, -PI / 2, -PI / 2 + TAU * clampf(progress, 0, 1), 36, Style.GREEN.lerp(Style.GOLD, daylight), 2)
	var icon = center + Vector2(0, -11)
	if rainy:
		_draw_weather(icon)
	if not rainy and daylight < 1.0:
		var moon = PackedVector2Array([Vector2(-.4,-6.7), Vector2(-4.4,-4.8), Vector2(-6.4,-1.3),
			Vector2(-5.7,2.9), Vector2(-2.9,5.7), Vector2(1.2,6.4), Vector2(4.8,4.5), Vector2(5.8,1.9),
			Vector2(2.6,2.6), Vector2(-.2,1.2), Vector2(-1.6,-1.5), Vector2(-1.3,-4.0)])
		for i in range(moon.size()): moon[i] += icon + Vector2(-8 * daylight, 0)
		draw_colored_polygon(moon, Color(Style.GOLD, 1.0 - daylight))
	if not rainy and daylight > 0.0:
		var sun = icon + Vector2(8 * (1.0 - daylight), 0)
		var rays = Color(Style.GOLD, daylight)
		draw_circle(sun, 5, rays)
		for i in range(8):
			var direction = Vector2.RIGHT.rotated(float(i) * TAU / 8.0)
			draw_line(sun + direction * 7, sun + direction * 9, rays, 1.4, true)
	var text = str(day)
	var width = font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, 18).x
	draw_string(font, center + Vector2(-width * .5, 15), text, HORIZONTAL_ALIGNMENT_LEFT, -1, 18, Style.INK)
