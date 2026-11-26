extends RefCounted

const DARK := Color("39423b")
const GLASS := Color("678680")
const PAPER := Color("f4dfa8")

static func facade(bounds: Rect2, kind: String) -> Rect2:
	var depth = .83 if kind == "stall" else 1.17
	return Rect2(bounds.position.x + .25, bounds.end.y - depth, bounds.size.x - .58, depth)

static func draw(board: Control, lot: Dictionary, evening: float) -> void:
	var box: Rect2 = lot.box
	var roof: Color = lot.roof
	var plaster: Color = lot.wall
	var body = facade(box, lot.kind)
	var base = Vector2(box.position.x + .13, box.end.y - .11)
	board.draw_rect(Rect2(box.position + Vector2(.19, .26), box.size + Vector2(.27, .07)), Color("33483e", .19))
	var right = [Vector2(body.end.x, body.position.y), Vector2(box.end.x, box.position.y + .32), box.end - Vector2(.02,.30), Vector2(body.end.x, body.end.y)]
	_polygon(board, right, plaster.darkened(.36))
	board.draw_rect(body, plaster)
	board.draw_rect(Rect2(body.position.x - .04, body.end.y - .18, body.size.x + .17, .19), plaster.darkened(.29))
	# Each door and window bay sits in its own timber frame.
	var bays = maxi(2, floori(body.size.x / 1.15))
	var span = body.size.x / bays
	for i in range(bays):
		var x = body.position.x + i * span
		board.draw_rect(Rect2(x, body.position.y, .07, body.size.y), plaster.darkened(.48))
		var opening = Rect2(x + span * .18, body.position.y + .24, span * .64, body.size.y - .43)
		if i == int(lot.door) % bays:
			opening.size.y = body.end.y - opening.position.y
			board.draw_rect(opening.grow(.065), DARK)
			board.draw_rect(opening, plaster.darkened(.47))
			board.draw_rect(Rect2(opening.position + Vector2(.10,.07), opening.size * Vector2(.68,.50)), GLASS.lerp(PAPER, evening * .8))
			board.draw_circle(opening.end - Vector2(.14,.27), .045, PAPER)
			board.draw_rect(Rect2(opening.position.x - .15, opening.end.y, opening.size.x + .30, .14), Color("afa694"))
			continue
		_window(board, opening, plaster.darkened(.45), evening)
		if lot.kind == "stall" or (lot.kind == "flat" and i % 2 == 0):
			_goods(board, opening.get_center() + Vector2(0,.18), lot.kind, i)
	var roof_rect = Rect2(box.position + Vector2(-.03,.03), Vector2(box.size.x + .08, body.position.y - box.position.y + .34))
	match str(lot.kind):
		"gable", "hip":
			_tiled_roof(board, roof_rect, roof, lot.kind == "hip")
		"flat":
			_flat_roof(board, roof_rect, roof)
		"glass":
			_glasshouse(board, roof_rect, roof, evening)
		_:
			_canopy(board, roof_rect, roof)
	for i in range(int(lot.steps)):
		board.draw_rect(Rect2(base + Vector2(.24 + i * .20,.17 + i * .09), Vector2(1.14 - .18 * i,.08)), Color("d0bba0"))
	if lot.kind == "gable" and box.size.y > 3.5:
		var chimney = Rect2(box.position.x + box.size.x * .22, box.position.y + .20,.37,.61)
		board.draw_rect(chimney, roof.darkened(.55))
		board.draw_rect(Rect2(chimney.position - Vector2(.065,.05), Vector2(.51,.18)), Color("c0ac8d"))
	if lot.get("side_entry", false):
		_side_entry(board, box, roof, plaster)
	if not str(lot.name).is_empty():
		var sign = sign_rect(lot)
		board.draw_rect(sign.grow(.045), plaster.darkened(.57))
		board.draw_rect(sign, roof.darkened(.46))
		board.draw_line(sign.position + Vector2(.06,.04), Vector2(sign.end.x - .06,sign.position.y+.04), Color("d3ac7c"), .025)

static func sign_rect(lot: Dictionary) -> Rect2:
	var body = facade(lot.box, str(lot.kind))
	var width = minf(body.size.x - .15, maxf(1.3, str(lot.name).length() * .47))
	return Rect2(body.get_center().x - width * .5, body.position.y + .10, width, .43)

static func _window(board: Control, r: Rect2, frame: Color, evening: float) -> void:
	board.draw_rect(r.grow(.062), frame)
	board.draw_rect(r, GLASS.lerp(Color("e9b879"), evening * .88))
	board.draw_rect(Rect2(r.position + Vector2(.08,.08), Vector2(r.size.x - .16,r.size.y * .30)), Color("e6ecd0", .29))
	board.draw_line(Vector2(r.get_center().x,r.position.y), Vector2(r.get_center().x,r.end.y), frame, .043)
	board.draw_line(Vector2(r.position.x,r.get_center().y+.04), Vector2(r.end.x,r.get_center().y+.04), frame, .036)
	board.draw_rect(Rect2(r.position.x - .12, r.end.y + .015, r.size.x + .24, .079), frame.lightened(.22))

static func _tiled_roof(board: Control, box: Rect2, tint: Color, hip: bool) -> void:
	var ridge_y = box.position.y + box.size.y * .43
	var eave = box.end.y - .14
	var ridge_offset = minf(.64, box.size.x * .16) if hip else .15
	var eave_left = Vector2(box.position.x, eave)
	var eave_right = Vector2(box.end.x, eave)
	var ridge_left = Vector2(box.position.x + ridge_offset, ridge_y)
	var ridge_right = Vector2(box.end.x - ridge_offset - .1, ridge_y)
	var back_left = box.position + Vector2(.20,.07)
	var back_right = Vector2(box.end.x - .35, back_left.y)
	_polygon(board, [eave_left, box.position + Vector2(.16,-.01), back_right+Vector2(.13,0), eave_right, eave_right+Vector2(-.13,.20),eave_left+Vector2(.12,.20)], tint.darkened(.58))
	_polygon(board, [back_left,back_right,ridge_right,ridge_left], tint.darkened(.20))
	_polygon(board, [ridge_left,ridge_right,eave_right-Vector2(.07,0),eave_left+Vector2(.07,0)], tint.lightened(.07))
	if hip:
		_polygon(board, [back_right,ridge_right,eave_right-Vector2(.07,0)], tint.darkened(.34))
		_polygon(board, [back_left,ridge_left,eave_left+Vector2(.07,0)], tint.darkened(.10))
	_tile_rows(board, back_left, back_right, ridge_left,ridge_right,tint.darkened(.20))
	_tile_rows(board, ridge_left,ridge_right,eave_left+Vector2(.10,0),eave_right-Vector2(.10,0),tint)
	board.draw_line(ridge_left, ridge_right, tint.darkened(.48), .11)
	board.draw_line(ridge_left - Vector2(0,.035), ridge_right - Vector2(0,.035), tint.lightened(.34), .043)
	board.draw_line(eave_left + Vector2(.11,.055), eave_right - Vector2(.11,-.055), tint.lightened(.30), .064)

static func _tile_rows(board: Control, l1: Vector2, r1: Vector2, l2: Vector2, r2: Vector2, tint: Color) -> void:
	var count = maxi(2, roundi((l2.y-l1.y) / .18))
	for row in range(1,count):
		var t = float(row) / count
		var left = l1.lerp(l2,t) + Vector2(.06,0)
		var right = r1.lerp(r2,t) - Vector2(.06,0)
		board.draw_line(left,right,tint.darkened(.22),.030)
		board.draw_line(left + Vector2(0,.04),right + Vector2(0,.04),tint.lightened(.24),.023)
		var x = left.x + .09 + (row % 2) * .14
		while x < right.x - .1:
			board.draw_line(Vector2(x,left.y),Vector2(x+.026,left.y-.125),tint.darkened(.16),.027)
			x += .29

static func _flat_roof(board: Control, r: Rect2, tint: Color) -> void:
	board.draw_rect(r, tint.darkened(.40))
	board.draw_rect(r.grow(-.13), tint)
	board.draw_rect(r.grow(-.23), tint.darkened(.09), false, .058)
	board.draw_line(r.position + Vector2(.14,.13),Vector2(r.end.x-.14,r.position.y+.13),tint.lightened(.35),.072)
	for i in range(3):
		var unit = Rect2(r.position + Vector2(.40 + i * .44,.34), Vector2(.32,.42))
		board.draw_rect(unit, tint.lightened(.41))
		board.draw_circle(unit.get_center(), .101, tint.darkened(.3), false, .04, true)
	board.draw_line(r.position + Vector2(.20,r.size.y*.67),Vector2(r.end.x-.20,r.position.y+r.size.y*.67),tint.darkened(.24),.042)

static func _glasshouse(board: Control, r: Rect2, tint: Color, evening: float) -> void:
	board.draw_rect(r, Color("41584c"))
	board.draw_rect(r.grow(-.08), tint.darkened(.26))
	var panels = roundi(r.size.x / .63)
	var spacing = r.size.x / panels
	for i in range(panels):
		var x = r.position.x + i * spacing + .076
		var pane = Rect2(x, r.position.y + .12, spacing - .14, r.size.y - .23)
		board.draw_rect(pane, Color("7eae9a").lerp(Color("d1b47a"), evening * .65))
		board.draw_rect(Rect2(pane.position, pane.size * Vector2(1,.39)), Color("c9dfbb", .34))
		for row in range(2):
			var flower = pane.position + Vector2(pane.size.x*.5, pane.size.y * (.48 + row * .29))
			board.draw_circle(flower, .11, Color("567b5c"), true, -1, true)
			board.draw_circle(flower-Vector2(.01,.038), .055, Color("dca27f"), true, -1, true)
	board.draw_line(Vector2(r.position.x+.1,r.get_center().y),Vector2(r.end.x-.12,r.get_center().y),Color("d2d5a6"),.048)
	board.draw_line(r.position+Vector2(.11,.075),Vector2(r.end.x-.1,r.position.y+.075),Color("d7d5b3"),.065)

static func _side_entry(board: Control, box: Rect2, roof: Color, plaster: Color) -> void:
	var edge = Vector2(box.end.x - .22, box.end.y - .72)
	_polygon(board, [edge-Vector2(.10,.21),edge+Vector2(.105,-.40),edge+Vector2(.105,.27),edge+Vector2(-.10,.44)], plaster.darkened(.52))
	board.draw_line(edge + Vector2(.16,-.43), edge + Vector2(.16,.31), Color("c5b18d"), .087)
	board.draw_line(edge + Vector2(.25,-.34), edge + Vector2(.25,.42), roof.darkened(.3), .10)

static func _canopy(board: Control, r: Rect2, tint: Color) -> void:
	board.draw_rect(r, tint.darkened(.45))
	var columns = maxi(4, roundi(r.size.x / .36))
	for i in range(columns):
		var width = (r.size.x-.13) / columns
		var color = tint if i % 2 == 0 else Color("e4c996")
		var x = r.position.x + .065 + i * width
		board.draw_rect(Rect2(x,r.position.y + .06,width,r.size.y - .18),color)
		board.draw_rect(Rect2(x+.055,r.end.y-.16,width-.1,.23),color.darkened(.26))
	board.draw_line(Vector2(r.position.x+.08,r.get_center().y),Vector2(r.end.x-.08,r.get_center().y),Color("fff1cc",.20),.08)

static func _goods(board: Control, p: Vector2, kind: String, seed: int) -> void:
	board.draw_rect(Rect2(p - Vector2(.25,.06), Vector2(.51,.18)), Color("795c47"))
	for i in range(4):
		var tint = Color("d5a55d") if kind == "stall" else Color("b9746c")
		board.draw_circle(p + Vector2(-.16 + (i % 2) * .20, .03 - floorf(i / 2.0)*.13), .070, tint.lightened(.1 * ((i + seed) % 3)), true, -1, true)

static func _polygon(board: Control, points: Array, tint: Color) -> void:
	board.draw_colored_polygon(PackedVector2Array(points), tint)
