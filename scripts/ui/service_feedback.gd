extends Control

const Style = preload("res://scripts/ui/style.gd")
const TRAVEL_TIME := 0.60
const RING_TIME := 0.19
const MAX_FLIGHTS := 14

var wallet: Label
var flights: Array[Dictionary] = []
var amounts := {}
var displayed := {}
var rolls := {}
var pulses := {}
var font: Font

func _ready() -> void:
	mouse_filter = MOUSE_FILTER_IGNORE
	font = Style.font()

func attach_counter(label: Label) -> void:
	var row = label.get_parent()
	var index = label.get_index()
	# Containers resize and reset child transforms when text changes. Animate inside a fixed slot.
	var slot = Control.new()
	slot.mouse_filter = MOUSE_FILTER_IGNORE
	slot.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(slot)
	row.move_child(slot, index)
	label.reparent(slot, false)
	label.set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	var fit = func(): slot.custom_minimum_size = label.get_combined_minimum_size()
	label.minimum_size_changed.connect(fit)
	label.resized.connect(func(): label.pivot_offset = label.size * .5)
	fit.call()

func show_resource(label: Label, value: int, suffix := "") -> void:
	if not amounts.has(label):
		amounts[label] = value
		_display(float(value), label, suffix)
		return
	var previous = int(amounts[label])
	if value == previous: return
	amounts[label] = value
	var running: Tween = rolls.get(label)
	if running != null and running.is_valid(): running.kill()
	var duration = clampf(.38 + log(1.0 + absf(value - previous)) * .045, .4, .74)
	var roll = create_tween()
	rolls[label] = roll
	roll.tween_method(_display.bind(label, suffix), float(displayed[label]), float(value), duration).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	roll.finished.connect(func(): rolls.erase(label))
	_pulse(label, value > previous)

func _display(value: float, label: Label, suffix: String) -> void:
	displayed[label] = value
	var text = "%d%s" % [roundi(value), suffix]
	if label.text != text: label.text = text

func _pulse(label: Label, gained: bool) -> void:
	var running: Tween = pulses.get(label)
	if running != null and running.is_valid(): running.kill()
	label.pivot_offset = label.size * 0.5
	var pulse = create_tween().set_parallel(true)
	pulses[label] = pulse
	pulse.tween_property(label, "scale", Vector2(1.16, 1.27), .075).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	var tint = Color(1.12, 1.09, .86) if gained else Color(1.15, .75, .67)
	pulse.tween_property(label, "modulate", tint, .075)
	pulse.chain().tween_interval(.045)
	pulse.chain().tween_property(label, "scale", Vector2.ONE, .25).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	pulse.parallel().tween_property(label, "modulate", Color.WHITE, .24)

func add_payment(viewport_origin: Vector2, value: int) -> void:
	var origin = get_global_transform_with_canvas().affine_inverse() * viewport_origin
	if not Rect2(Vector2.ZERO, size).grow(8).has_point(origin): return
	if value <= 0 or flights.size() >= MAX_FLIGHTS: return
	flights.append({"origin": origin, "amount": value, "age": 0.0, "side": 1.0 if flights.size() % 2 == 0 else -1.0})
	queue_redraw()

func reset() -> void:
	flights.clear()
	amounts.clear()
	displayed.clear()
	for roll in rolls.values():
		if roll.is_valid(): roll.kill()
	rolls.clear()
	for label in pulses:
		if pulses[label].is_valid(): pulses[label].kill()
		if is_instance_valid(label):
			label.scale = Vector2.ONE
			label.modulate = Color.WHITE
	pulses.clear()
	queue_redraw()

func _process(delta: float) -> void:
	if flights.is_empty(): return
	for i in range(flights.size() - 1, -1, -1):
		var flight = flights[i]
		flight.age += delta
		if flight.age >= TRAVEL_TIME + RING_TIME: flights.remove_at(i)
	queue_redraw()

func _draw() -> void:
	if not is_instance_valid(wallet) or flights.is_empty(): return
	var wallet_point = wallet.get_global_transform_with_canvas() * (wallet.size * .5)
	var target = get_global_transform_with_canvas().affine_inverse() * wallet_point
	for flight in flights:
		var age = float(flight.age)
		if age >= TRAVEL_TIME:
			var arrival = (age - TRAVEL_TIME) / RING_TIME
			draw_arc(target, lerpf(5, 22, arrival), 0, TAU, 26, Color("ffda8b", .8 * (1.0 - arrival)), 2, true)
			continue
		var origin: Vector2 = flight.origin
		var ratio = smoothstep(0.035, TRAVEL_TIME, age)
		var bend = origin.lerp(target, .53) + Vector2(24.0 * flight.side, -clampf(origin.distance_to(target) * .23, 35, 116))
		var p = origin.bezier_interpolate(bend, bend, target, ratio)
		var trail = origin.bezier_interpolate(bend, bend, target, maxf(0.0, ratio - .055))
		draw_line(trail, p, Color("ffca74", .46), 3.0, true)
		_draw_coin(p, age, ratio)
		if age < .41:
			_draw_amount(origin, int(flight.amount), age)

func _draw_coin(point: Vector2, age: float, ratio: float) -> void:
	var width = lerpf(.54, 1.0, absf(cos(age * 14.5)))
	var radius = lerpf(8.0, 5.0, ratio)
	draw_set_transform(point, -.18, Vector2(width, 1))
	draw_circle(Vector2(.9, 1.3), radius + 1.15, Color("67402c"), true, -1.0, true)
	draw_circle(Vector2.ZERO, radius, Color("d89243"), true, -1.0, true)
	draw_circle(Vector2(-.6, -.7), radius - 1.15, Color("ffcc69"), true, -1.0, true)
	draw_arc(Vector2(-.6, -.7), radius - 2.45, PI * .88, PI * 1.68, 12, Color("fff0a6"), 1.25, true)
	draw_line(Vector2(0, -radius * .38), Vector2(0, radius * .33), Color("b97837"), 1.4, true)
	draw_set_transform(Vector2.ZERO, 0, Vector2.ONE)

func _draw_amount(origin: Vector2, value: int, age: float) -> void:
	var lift = smoothstep(0.0, .41, age)
	var alpha = 1.0 - smoothstep(.21, .41, age)
	var text = "+%d" % value
	var baseline = origin + Vector2(19 + lift * 8, 14 - lift * 23)
	draw_string_outline(font, baseline, text, HORIZONTAL_ALIGNMENT_LEFT, -1, 15, 4, Color("463528", alpha))
	draw_string(font, baseline, text, HORIZONTAL_ALIGNMENT_LEFT, -1, 15, Color("ffe2a2", alpha))
