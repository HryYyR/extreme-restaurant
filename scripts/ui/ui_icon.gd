extends Control

var glyph := ""
var tint := Color.WHITE
var extent := 20.0

static func make(name: String, color: Color, pixels := 20.0) -> Control:
	var icon = new()
	icon.glyph = name
	icon.tint = color
	icon.extent = pixels
	icon.custom_minimum_size = Vector2.ONE * pixels
	icon.size_flags_vertical = SIZE_SHRINK_CENTER
	icon.mouse_filter = MOUSE_FILTER_IGNORE
	return icon

static func center_in(button: Button, name: String, color: Color, pixels := 20.0) -> Control:
	var icon = make(name, color, pixels)
	button.add_child(icon)
	icon.set_anchors_and_offsets_preset(PRESET_CENTER)
	icon.offset_left = -pixels * 0.5
	icon.offset_top = -pixels * 0.5
	icon.offset_right = pixels * 0.5
	icon.offset_bottom = pixels * 0.5
	return icon

func set_glyph(name: String, color: Color) -> void:
	if glyph == name and tint == color: return
	glyph = name
	tint = color
	queue_redraw()

func _stroke(points: Array, thickness := 1.7) -> void:
	draw_polyline(PackedVector2Array(points), tint, thickness, true)

func _fill_shape(points: Array) -> void:
	draw_colored_polygon(PackedVector2Array(points), tint)

func _draw() -> void:
	draw_set_transform((size - Vector2.ONE * extent) * 0.5, 0.0, Vector2.ONE * (extent / 24.0))
	match glyph:
		"district":
			_stroke([Vector2(3, 5), Vector2(10, 3), Vector2(15, 5), Vector2(21, 3), Vector2(21, 19), Vector2(15, 21), Vector2(10, 19), Vector2(3, 21), Vector2(3, 5)])
			draw_line(Vector2(10, 3), Vector2(10, 19), tint, 1.5, true)
			draw_line(Vector2(15, 5), Vector2(15, 21), tint, 1.5, true)
		"history":
			draw_rect(Rect2(5, 3, 15, 18), tint, false, 1.6, true)
			draw_line(Vector2(2, 6), Vector2(2, 19), tint, 1.6, true)
			_stroke([Vector2(8, 16), Vector2(11, 12), Vector2(14, 14), Vector2(17, 8)])
		"follow":
			draw_circle(Vector2(12, 12), 5.3, tint, false, 1.5, true)
			draw_circle(Vector2(12, 12), 1.45, tint, true, -1, true)
			for side in [Vector2.UP, Vector2.RIGHT, Vector2.DOWN, Vector2.LEFT]:
				draw_line(Vector2(12, 12) + side * 8, Vector2(12, 12) + side * 11, tint, 1.8, true)
		"income":
			draw_rect(Rect2(3, 15, 4, 6), tint)
			draw_rect(Rect2(10, 12, 4, 9), tint)
			draw_rect(Rect2(17, 8, 4, 13), tint)
			_stroke([Vector2(3, 11), Vector2(9, 7), Vector2(13, 8), Vector2(20, 3), Vector2(15, 3)])
		"coins":
			draw_circle(Vector2(8, 14), 5, tint, false, 1.7, true)
			draw_arc(Vector2(15, 9), 6, -2.6, 1.9, 22, tint, 1.7, true)
			draw_line(Vector2(8, 11), Vector2(8, 17), tint, 1.4, true)
		"reputation":
			draw_circle(Vector2(12, 9), 5.6, tint, false, 1.7, true)
			draw_circle(Vector2(12, 9), 2.4, tint)
			_stroke([Vector2(8, 14), Vector2(7, 21), Vector2(12, 18), Vector2(17, 21), Vector2(16, 14)])
		"star", "star_outline":
			var points: Array = []
			for index in range(10):
				var radius = 10.0 if index % 2 == 0 else 4.25
				points.append(Vector2(12, 12) + Vector2.UP.rotated(index * TAU / 10.0) * radius)
			if glyph == "star":
				_fill_shape(points)
			else:
				points.append(points[0])
				_stroke(points, 1.4)
		"clock":
			draw_circle(Vector2(12, 12), 8.5, tint, false, 1.7, true)
			_stroke([Vector2(12, 6), Vector2(12, 12), Vector2(16, 14)])
		"rent":
			_stroke([Vector2(3, 10), Vector2(12, 3), Vector2(21, 10)])
			_stroke([Vector2(5, 9), Vector2(5, 20), Vector2(19, 20), Vector2(19, 9)])
			draw_rect(Rect2(10, 13, 4, 7), tint, false, 1.5, true)
		"settings":
			draw_circle(Vector2(12, 12), 7, tint, false, 2.2, true)
			draw_circle(Vector2(12, 12), 2.8, tint, false, 1.5, true)
			for index in range(8):
				var direction = Vector2.UP.rotated(index * TAU / 8.0)
				draw_line(Vector2(12, 12) + direction * 7, Vector2(12, 12) + direction * 10, tint, 2.4, true)
		"play":
			_fill_shape([Vector2(7, 4), Vector2(21, 12), Vector2(7, 20)])
		"pause":
			draw_rect(Rect2(6, 4, 4, 16), tint)
			draw_rect(Rect2(14, 4, 4, 16), tint)
		"recipe":
			_stroke([Vector2(12, 6), Vector2(8, 4), Vector2(3, 4), Vector2(3, 18), Vector2(8, 18), Vector2(12, 20), Vector2(16, 18), Vector2(21, 18), Vector2(21, 4), Vector2(16, 4), Vector2(12, 6), Vector2(12, 20)])
			draw_line(Vector2(6, 9), Vector2(9, 9), tint, 1.5, true)
			draw_line(Vector2(15, 9), Vector2(18, 9), tint, 1.5, true)
		"close":
			draw_line(Vector2(6, 6), Vector2(18, 18), tint, 1.8, true)
			draw_line(Vector2(18, 6), Vector2(6, 18), tint, 1.8, true)
		"lock":
			draw_rect(Rect2(5, 10, 14, 10), tint, false, 1.8, true)
			draw_arc(Vector2(12, 9), 4.4, PI, TAU, 14, tint, 1.8, true)
			draw_line(Vector2(12, 14), Vector2(12, 17), tint, 2, true)
		"expand":
			_stroke([Vector2(4, 9), Vector2(4, 4), Vector2(9, 4)])
			_stroke([Vector2(15, 4), Vector2(20, 4), Vector2(20, 9)])
			_stroke([Vector2(20, 15), Vector2(20, 20), Vector2(15, 20)])
			_stroke([Vector2(9, 20), Vector2(4, 20), Vector2(4, 15)])
			draw_line(Vector2(8, 12), Vector2(16, 12), tint, 1.6, true)
			draw_line(Vector2(12, 8), Vector2(12, 16), tint, 1.6, true)
		"alert":
			_stroke([Vector2(12, 2), Vector2(22, 20), Vector2(2, 20), Vector2(12, 2)])
			_stroke([Vector2(12, 8), Vector2(12, 13)])
			draw_circle(Vector2(12, 16.5), 1, tint)
		"check":
			_stroke([Vector2(5, 12), Vector2(10, 17), Vector2(20, 7)], 2.2)
		"table":
			draw_rect(Rect2(3, 6, 18, 5), tint, false, 1.7, true)
			draw_line(Vector2(6, 11), Vector2(6, 20), tint, 1.7, true)
			draw_line(Vector2(18, 11), Vector2(18, 20), tint, 1.7, true)
		"build":
			_stroke([Vector2(8, 4), Vector2(5, 7), Vector2(9, 11), Vector2(12, 8), Vector2(16, 12), Vector2(20, 8), Vector2(15, 3), Vector2(8, 4)])
			_stroke([Vector2(11, 10), Vector2(3, 18), Vector2(6, 21), Vector2(14, 13)])
		"wall":
			draw_rect(Rect2(3, 5, 18, 14), tint, false, 1.7, true)
			draw_line(Vector2(3, 12), Vector2(21, 12), tint, 1.7, true)
			draw_line(Vector2(9, 5), Vector2(9, 12), tint, 1.7, true)
			draw_line(Vector2(15, 12), Vector2(15, 19), tint, 1.7, true)
		"move":
			for angle in range(4):
				var turn = angle * PI * .5
				var tip = Vector2(12, 12) + Vector2(0, -9).rotated(turn)
				draw_line(Vector2(12, 12), tip, tint, 1.7, true)
				_stroke([Vector2(12,12) + Vector2(-3,-6).rotated(turn), tip, Vector2(12,12) + Vector2(3,-6).rotated(turn)])
		"rotate":
			draw_arc(Vector2(12, 12), 7, -PI * .78, PI * .83, 24, tint, 1.9, true)
			_stroke([Vector2(2, 15), Vector2(6, 16), Vector2(8, 12)])
		"split":
			_stroke([Vector2(9, 5), Vector2(4, 5), Vector2(4, 19), Vector2(9, 19)])
			_stroke([Vector2(15, 5), Vector2(20, 5), Vector2(20, 19), Vector2(15, 19)])
			_stroke([Vector2(10, 9), Vector2(7, 12), Vector2(10, 15)])
			_stroke([Vector2(14, 9), Vector2(17, 12), Vector2(14, 15)])
		"store":
			_stroke([Vector2(4, 12), Vector2(4, 20), Vector2(20, 20), Vector2(20, 12)])
			_stroke([Vector2(12, 3), Vector2(12, 14), Vector2(8, 10)])
			draw_line(Vector2(12, 14), Vector2(16, 10), tint, 1.7, true)
		"keys":
			draw_rect(Rect2(2, 5, 20, 14), tint, false, 1.6, true)
			for x in [6, 10, 14, 18]: draw_circle(Vector2(x, 10), 1.0, tint)
			draw_line(Vector2(7, 15), Vector2(17, 15), tint, 1.7, true)
		"stove":
			draw_rect(Rect2(4, 4, 16, 16), tint, false, 1.7, true)
			for point in [Vector2(8, 8), Vector2(16, 8), Vector2(8, 16), Vector2(16, 16)]:
				draw_circle(point, 1.65, tint)
		"bag":
			draw_rect(Rect2(5, 8, 14, 13), tint, false, 1.7, true)
			draw_arc(Vector2(12, 8), 3.7, PI, TAU, 12, tint, 1.65, true)
			draw_line(Vector2(5, 13), Vector2(19, 13), tint, 1.6, true)
			draw_rect(Rect2(10, 12, 4, 4), tint)
		"trophy":
			_stroke([Vector2(7, 4), Vector2(17, 4), Vector2(17, 11), Vector2(14, 15), Vector2(10, 15), Vector2(7, 11), Vector2(7, 4)])
			_stroke([Vector2(7, 6), Vector2(4, 6), Vector2(4, 10), Vector2(7, 11)])
			_stroke([Vector2(17, 6), Vector2(20, 6), Vector2(20, 10), Vector2(17, 11)])
			draw_line(Vector2(12, 15), Vector2(12, 20), tint, 1.7, true)
			draw_line(Vector2(8, 20), Vector2(16, 20), tint, 1.7, true)
		"chef":
			draw_arc(Vector2(7.4, 10.5), 3.5, 1.75, 5.2, 13, tint, 1.6, true)
			draw_arc(Vector2(12, 8.5), 4.4, 3.65, 5.8, 13, tint, 1.6, true)
			draw_arc(Vector2(16.6, 10.5), 3.5, -1.9, 1.4, 13, tint, 1.6, true)
			_stroke([Vector2(7, 14), Vector2(7, 19), Vector2(17, 19), Vector2(17, 14)])
		"crowd":
			draw_circle(Vector2(8, 8), 3, tint)
			draw_circle(Vector2(17, 9), 2.5, tint)
			draw_arc(Vector2(8, 17), 4.5, PI, TAU, 14, tint, 1.8, true)
			draw_arc(Vector2(17, 17), 4, 3.8, TAU, 14, tint, 1.8, true)
		"door":
			_stroke([Vector2(12, 4), Vector2(20, 4), Vector2(20, 20), Vector2(12, 20)])
			_stroke([Vector2(3, 12), Vector2(14, 12), Vector2(10, 8)])
			draw_line(Vector2(14, 12), Vector2(10, 16), tint, 1.7, true)
