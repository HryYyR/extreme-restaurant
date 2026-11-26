extends RefCounted

static func paint(canvas: CanvasItem, bounds: Rect2, definition: Dictionary, turns: int = 0) -> void:
	var tint = Color(str(definition.color))
	var edge = minf(bounds.size.x, bounds.size.y)
	var line = maxf(1.0, edge * .035)
	var center = bounds.get_center()
	var base = bounds.grow(-maxf(2.0, edge * .08))
	canvas.draw_rect(Rect2(base.position + Vector2(edge * .05, edge * .06), base.size), Color("382a33", .23))
	canvas.draw_rect(base, tint.darkened(.55))
	base = base.grow(-line * 1.25)
	canvas.draw_rect(base, tint.darkened(.23))
	canvas.draw_rect(base, tint.lightened(.20), false, line)
	match str(definition.id):
		"breeze_fan":
			canvas.draw_circle(center, edge * .30, Color("314f51"), true, -1, true)
			for i in range(5):
				var angle = TAU * float(i) / 5.0
				var petal = center + Vector2.from_angle(angle) * edge * .15
				canvas.draw_circle(petal, edge * .095, tint.lightened(.25), true, -1, true)
			canvas.draw_circle(center, edge * .065, Color("f8dfaa"), true, -1, true)
		"meal_bell":
			var radius = edge * .23
			canvas.draw_circle(center, radius * 1.35, Color(tint.lightened(.25), .38), true, -1, true)
			canvas.draw_circle(center, radius, tint.lightened(.45), true, -1, true)
			canvas.draw_line(center - Vector2(radius, 0), center + Vector2(radius, 0), tint.darkened(.33), line)
			canvas.draw_line(center - Vector2(0, radius), center + Vector2(0, radius), tint.darkened(.33), line)
		"gold_lantern":
			var canopy = PackedVector2Array([center + Vector2(-.28, -.08) * edge, center + Vector2(0, -.30) * edge, center + Vector2(.28, -.08) * edge])
			canvas.draw_colored_polygon(canopy, Color("7f5940"))
			canvas.draw_rect(Rect2(center - Vector2(.16, .10) * edge, Vector2(.32, .32) * edge), Color("fbe4a1"))
			for column in [-.12, 0.0, .12]:
				canvas.draw_line(center + Vector2(column, -.11) * edge, center + Vector2(column, .22) * edge, Color("ab7944"), line)
			canvas.draw_line(center + Vector2(-.21, .23) * edge, center + Vector2(.21, .23) * edge, Color("7f5940"), line * 1.5)
		"lotus_pond":
			canvas.draw_rect(base.grow(-edge * .09), Color("51838b"))
			for offset in [Vector2(-.22,.08), Vector2(.04,-.18), Vector2(.18,.15)]:
				var blossom = center + offset * edge
				canvas.draw_circle(blossom, edge * .14, Color("6ba291"), true, -1, true)
				canvas.draw_circle(blossom, edge * .085, Color("f5c8c4"), true, -1, true)
		"wish_screen":
			for fraction in [.21, .5, .79]:
				var local = Vector2(fraction, .5) if turns % 2 != 0 else Vector2(.5, fraction)
				var bloom = base.position + base.size * local
				canvas.draw_circle(bloom, edge * .14, tint.lightened(.37), true, -1, true)
				canvas.draw_circle(bloom, edge * .062, Color("fff0b9"), true, -1, true)
		"peach_pavilion":
			canvas.draw_rect(base.grow(-edge * .1), Color("716349"))
			for offset in [Vector2(-.25,-.18), Vector2(.23,-.16), Vector2(-.19,.19), Vector2(.24,.22), Vector2.ZERO]:
				var bloom = center + offset * edge
				canvas.draw_circle(bloom, edge * .15, Color("71977e"), true, -1, true)
				canvas.draw_circle(bloom - Vector2.ONE * edge * .035, edge * .10, tint.lightened(.2), true, -1, true)
		"herb_rack":
			for offset in [Vector2(-.16, -.11), Vector2(.19, -.10), Vector2(-.12, .15), Vector2(.19, .15)]:
				var stalk = center + offset * edge
				canvas.draw_line(stalk + Vector2(0, .12) * edge, stalk + Vector2(0, -.12) * edge, Color("e3d59e"), line)
				canvas.draw_circle(stalk + Vector2(-.055, -.01) * edge, edge * .075, tint.lightened(.25), true, -1, true)
				canvas.draw_circle(stalk + Vector2(.057, -.07) * edge, edge * .075, tint.lightened(.35), true, -1, true)
		_:
			for offset in [Vector2(-.19, -.17), Vector2(.19,-.17), Vector2(-.19,.19), Vector2(.19,.19)]:
				var jar = center + offset * edge
				canvas.draw_circle(jar, edge * .115, tint.lightened(.42), true, -1, true)
				canvas.draw_circle(jar, edge * .054, tint.darkened(.26), true, -1, true)
	if definition.shape == "forward":
		var forward = Vector2.DOWN.rotated(turns * PI * .5)
		var side = forward.rotated(PI * .5)
		var tip = center + forward * edge * .40
		canvas.draw_polyline(PackedVector2Array([tip - forward * edge * .16 + side * edge * .10, tip, tip - forward * edge * .16 - side * edge * .10]), Color("fff1c1"), line * 1.35, true)
