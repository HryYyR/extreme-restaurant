extends VBoxContainer

const Style = preload("res://scripts/ui/style.gd")
const Trophies = preload("res://scripts/core/trophies.gd")
const TrophyArt = preload("res://scripts/visuals/trophy_art.gd")
const Grid = preload("res://scripts/core/layout.gd")

signal draw_requested
signal bag_requested
signal place_requested(facility_id: String)

var sim
var opening := false
var reel := Reel.new()
var buy: Button
var skip: Button
var bag: Button
var place: Button
var balance: Label
var ledger: Label
var effect: Label
var prize: Label
var odds_labels: Array[Label] = []

func _ready() -> void:
	name = "TrophyBoxContents"
	add_theme_constant_override("separation", 11)
	var header := HBoxContainer.new()
	add_child(header)
	ledger = Style.text("", 14, Style.MUTED)
	ledger.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(ledger)
	balance = Style.readout(header, "coins", "", "当前金币余额", Style.GOLD)
	reel.custom_minimum_size.y = 248
	reel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	reel.clip_contents = true
	add_child(reel)
	reel.opened.connect(_finish_opening)
	var probabilities := HBoxContainer.new()
	probabilities.add_theme_constant_override("separation", 6)
	add_child(probabilities)
	for grade in range(1, 6):
		var tint = Trophies.grade_color(grade)
		var panel = Style.card()
		panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		panel.add_theme_stylebox_override("panel", Style.box(Color("26363b").lerp(tint, .08), Color("49616a").lerp(tint, .45), 7, 6))
		probabilities.add_child(panel)
		var label = Style.text("", 13, tint)
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.tooltip_text = "第 %d 档品质的当前抽取概率。营业日越晚、累计开箱越多，高品质越常见。" % grade
		label.mouse_filter = Control.MOUSE_FILTER_PASS
		panel.add_child(label)
		odds_labels.append(label)
	var detail = Style.card()
	detail.add_theme_stylebox_override("panel", Style.box(Color("223138"), Color("52605d"), 9, 11))
	add_child(detail)
	var hint := VBoxContainer.new()
	hint.add_theme_constant_override("separation", 3)
	detail.add_child(hint)
	prize = Style.text("", 18, Style.INK)
	hint.add_child(prize)
	effect = Style.text("", 14, Style.MUTED, true)
	hint.add_child(effect)
	var actions := HBoxContainer.new()
	add_child(actions)
	buy = Style.button("", true)
	buy.name = "OpenTrophyBox"
	buy.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	buy.pressed.connect(draw_requested.emit)
	actions.add_child(buy)
	skip = Style.button("跳过动效")
	skip.name = "SkipTrophyOpening"
	skip.pressed.connect(reel.finish)
	actions.add_child(skip)
	place = Style.button("摆放奖杯")
	place.name = "PlaceDrawnTrophy"
	place.pressed.connect(_place)
	actions.add_child(place)
	bag = Style.button("奖杯背包")
	bag.name = "OpenDrawTrophyBag"
	bag.pressed.connect(bag_requested.emit)
	actions.add_child(bag)

func configure(simulation) -> void:
	sim = simulation
	if not sim.last_trophy_id.is_empty(): reel.show_reward(sim.relic_defs[sim.last_trophy_id])
	refresh()

func refresh(offer: Dictionary = {}) -> void:
	var quote = sim.trophy_box_offer() if offer.is_empty() else offer
	balance.text = "%d 金币" % sim.gold
	ledger.text = "今晚第 %d 箱 · 累计 %d 箱" % [sim.trophy_draws_today + (0 if opening else 1), sim.trophy_draws_total]
	ledger.tooltip_text = "每开一箱，今晚下一箱更贵。次日恢复首箱价。"
	for index in odds_labels.size():
		var chance = float(quote.odds[index])
		var amount = "%.2f%%" % chance if chance > 0.0 and chance < 1.0 else "%.1f%%" % chance
		odds_labels[index].text = "%s  %s" % [Trophies.NAMES[index], amount]
	var price = int(quote.gold)
	var empty = int(quote.remaining) == 0
	buy.disabled = opening or empty or sim.gold < price
	buy.text = "开箱中…" if opening else ("奖杯已集齐" if empty else "打开盲盒 · %d 金币" % price)
	buy.tooltip_text = ("还差 %d 金币" % (price - sim.gold)) if sim.gold < price and not empty and not opening else ledger.tooltip_text
	skip.visible = opening
	bag.disabled = opening
	place.hide()
	if opening:
		prize.text = "奖杯即将揭晓"
		prize.add_theme_color_override("font_color", Style.INK)
		effect.text = "即使关闭页面，开出的奖杯也会留在背包。"
	elif sim.last_trophy_id.is_empty():
		prize.text = "展廊收藏"
		prize.add_theme_color_override("font_color", Style.INK)
		effect.text = "开出未收藏的奖杯，放进展廊即可生效。"
	else:
		var trophy = sim.relic_defs[sim.last_trophy_id]
		prize.text = "%s · %s品质" % [trophy.name, Trophies.grade_name(int(trophy.rarity))]
		prize.add_theme_color_override("font_color", Trophies.grade_color(int(trophy.rarity)))
		effect.text = Trophies.description(trophy)
		var id = "trophy_" + sim.last_trophy_id
		var facility = Grid.find(sim.layout, id)
		place.visible = not Grid.placed(facility)
		place.disabled = Grid.facilities(sim.layout, "trophy").size() >= int(sim.attributes.relic_slots)
		place.tooltip_text = "展示位已满，可在奖杯背包收起现有奖杯" if place.disabled else "到展廊选择展示位置"

func animate_opening(result: Dictionary, offer: Dictionary) -> void:
	opening = true
	refresh(offer)
	var rng := RandomNumberGenerator.new()
	rng.seed = hash([result.id, sim.day, sim.trophy_draws_total, "reel"])
	var cards: Array[Dictionary] = []
	for index in range(Reel.STOP_CARD + 6):
		var id = str(result.id) if index == Reel.STOP_CARD else Trophies.sample(offer.pools, offer.odds, rng)
		cards.append(sim.relic_defs[id])
	reel.roll(cards)

func _finish_opening() -> void:
	opening = false
	refresh()

func _place() -> void:
	if not opening and not sim.last_trophy_id.is_empty():
		place_requested.emit("trophy_" + sim.last_trophy_id)

class Reel extends Control:
	signal opened

	const STOP_CARD := 31
	const CARD_PITCH := 124.0
	const BACK := Color("19272e")
	const EDGE := Color("55676b")
	const GOLD := Color("edc68e")
	static var tick_sound: AudioStreamWAV
	static var award_sounds: Dictionary = {}

	var font: Font
	var cards: Array[Dictionary] = []
	var reward: Dictionary = {}
	var rolling := false
	var motion: Tween
	var last_index := 2
	var last_click_time := 0
	var click := AudioStreamPlayer.new()
	var chime := AudioStreamPlayer.new()
	var stage_box: StyleBoxFlat
	var scroll_index := 2.0:
		set(value):
			scroll_index = value
			_play_click()
			queue_redraw()
	var shine := 1.0:
		set(value):
			shine = value
			queue_redraw()

	func _ready() -> void:
		name = "TrophyReel"
		font = Style.font()
		stage_box = Style.box(BACK, EDGE, 11, 0)
		resized.connect(queue_redraw)
		click.volume_db = -21.0
		chime.volume_db = -13.0
		add_child(click)
		add_child(chime)

	func show_reward(item: Dictionary) -> void:
		reward = item
		shine = 1.0

	func roll(sequence: Array[Dictionary]) -> void:
		if rolling: return
		cards = sequence
		reward = {}
		scroll_index = 2.0
		last_index = 2
		last_click_time = 0
		rolling = true
		if tick_sound == null: tick_sound = _tone(0)
		click.stream = tick_sound
		motion = create_tween()
		motion.tween_property(self, "scroll_index", STOP_CARD + .09, 2.73).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		motion.tween_property(self, "scroll_index", float(STOP_CARD), .22).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		motion.tween_interval(.12)
		motion.tween_callback(finish)

	func finish() -> void:
		if not rolling: return
		rolling = false
		if motion != null and motion.is_valid(): motion.kill()
		show_reward(cards[STOP_CARD])
		cards.clear()
		shine = 0.0
		var grade = int(reward.rarity)
		if not award_sounds.has(grade): award_sounds[grade] = _tone(grade)
		chime.stream = award_sounds[grade]
		chime.play()
		motion = create_tween()
		motion.tween_property(self, "shine", 1.0, .58 + .17 * grade)
		opened.emit()

	func _play_click() -> void:
		var tile = roundi(scroll_index)
		if not rolling or tile == last_index: return
		last_index = tile
		var now = Time.get_ticks_msec()
		if now - last_click_time < 43: return
		click.pitch_scale = lerpf(1.18, .89, clampf(scroll_index / STOP_CARD, 0.0, 1.0))
		click.play()
		last_click_time = now

	static func _tone(grade: int) -> AudioStreamWAV:
		const RATE := 16000
		var duration = .041 if grade == 0 else .21 + grade * .073
		var audio = AudioStreamWAV.new()
		audio.mix_rate = RATE
		audio.format = AudioStreamWAV.FORMAT_16_BITS
		var count = ceili(duration * RATE)
		var bytes := PackedByteArray()
		bytes.resize(count * 2)
		for index in count:
			var t = float(index) / RATE
			var envelope = minf(1.0, t * 220.0) * pow(1.0 - t / duration, 2.3)
			var value = sin(TAU * (630.0 if grade == 0 else 330.0 + grade * 71.0) * t)
			if grade > 0:
				var sweep = maxf(0.0, t - .032)
				value = value * .58 + sin(TAU * (495.0 + grade * 78.0) * sweep) * .37
				if grade > 2: value += sin(TAU * (720.0 + grade * 67.0) * maxf(0.0, t - .082)) * .17
			bytes.encode_s16(index * 2, roundi(value * envelope * 16000.0))
		audio.data = bytes
		return audio

	func _draw() -> void:
		if font == null or size.x < 2.0: return
		draw_style_box(stage_box, Rect2(Vector2.ZERO, size))
		var center = size * .5
		draw_rect(Rect2(10, 11, size.x - 20, size.y - 22), Color("294047"), false, 1)
		for y in [25.0, size.y - 25.0]:
			draw_line(Vector2(12, y), Vector2(size.x - 12, y), Color("6d7d76", .52), 1)
		for direction in [-1, 1]:
			var x = 14.0 if direction == 1 else size.x - 14.0
			for y in [18.0, size.y - 18.0]:
				draw_line(Vector2(x, y), Vector2(x + 16 * direction, y), GOLD, 1)
		if rolling:
			_draw_reel(center)
		elif reward.is_empty():
			_draw_case(center)
		else:
			_draw_reward(center)

	func _draw_case(center: Vector2) -> void:
		for radius in [47.0, 63.0, 90.0]:
			draw_circle(center, radius, Color("82a69c", .24), false, 1, true)
		for x in [-1.0, 1.0]:
			draw_line(center + Vector2(x * 88, 0), center + Vector2(x * 126, 0), Color("b4ad8e", .54), 1)
			_diamond(center + Vector2(x * 108, 0), 5, Color("7eaa9e"))
		draw_set_transform(center, 0, Vector2.ONE * 1.42)
		draw_colored_polygon(PackedVector2Array([Vector2(-57,-35), Vector2(-42,-49), Vector2(44,-49), Vector2(58,-34), Vector2(58,38), Vector2(45,48), Vector2(-48,48), Vector2(-57,38)]), Color("0f191e"))
		draw_rect(Rect2(-52,-34,104,73), Color("355255"))
		draw_rect(Rect2(-51,-33,102,24), Color("547071"))
		draw_rect(Rect2(-46,-29,92,64), Color("788c80"), false, 2)
		for x in [-38, 38]:
			var side = signf(x)
			draw_line(Vector2(x, -20), Vector2(x - 10 * side, -28), Color("ac9f80"), 1.25, true)
			draw_line(Vector2(x, 29), Vector2(x - 10 * side, 18), Color("728e7b"), 1.25, true)
		draw_line(Vector2(-46, 36), Vector2(46, 36), Color("2a4145"), 1.65, true)
		draw_rect(Rect2(-53,-14,106,4), Color("ba966d"))
		draw_rect(Rect2(-18,-22,36,39), Color("283436"))
		draw_circle(Vector2(0,-2), 14, Color("c89a60"), true, -1, true)
		draw_circle(Vector2(0,-2), 10, Color("53463c"), true, -1, true)
		_diamond(Vector2(0,-2), 7, Color("f6e3ae"))
		for x in [-43, 43]:
			for y in [-26, 30]: draw_circle(Vector2(x,y), 2.25, GOLD, true, -1, true)
		draw_set_transform(Vector2.ZERO)

	func _draw_reel(center: Vector2) -> void:
		draw_rect(Rect2(1, 36, size.x - 2, size.y - 72), Color("101d25"))
		var reach = ceili(size.x / (2.0 * CARD_PITCH)) + 1
		for index in range(maxi(0, floori(scroll_index) - reach), mini(cards.size(), ceili(scroll_index) + reach)):
			var x = center.x + (index - scroll_index) * CARD_PITCH
			var distance = absf(x - center.x)
			_draw_card(Vector2(x, center.y), cards[index], clampf(1.06 - distance / (size.x * 1.17), .43, 1.0))
		draw_line(Vector2(center.x, 40), Vector2(center.x, size.y - 40), Color("fff0bc", .78), 2, true)
		for side in [-1, 1]:
			var notch = center + Vector2(0, side * (center.y - 29.0))
			draw_colored_polygon(PackedVector2Array([notch + Vector2(-8, 0), notch + Vector2(8, 0), notch + Vector2(0, -side * 11)]), GOLD)

	func _draw_card(center: Vector2, item: Dictionary, alpha: float) -> void:
		var grade = int(item.rarity)
		var tint = Trophies.grade_color(grade)
		var rect = Rect2(center - Vector2(56, 77), Vector2(112, 154))
		draw_rect(rect, Color(BACK.lerp(tint, .19), alpha))
		draw_rect(rect.grow(-2), Color(tint, .46 * alpha), false, 1.0)
		var band = Rect2(rect.position, Vector2(rect.size.x, 4))
		if grade == 5:
			var width = band.size.x / Trophies.PRISM.size()
			for i in Trophies.PRISM.size():
				draw_rect(Rect2(band.position + Vector2(width * i, 0), Vector2(width, 4)), Color(Color(Trophies.PRISM[i]), alpha))
		else:
			draw_rect(band, Color(tint, alpha))
		draw_circle(center + Vector2(0,-12), 33, Color(tint, .10 * alpha), true, -1, true)
		draw_set_transform(center + Vector2(0, -12), 0.0, Vector2.ONE * 1.17)
		TrophyArt.paint(self, item)
		draw_set_transform(Vector2.ZERO)
		_centered(item.name, center + Vector2(0, 44), 14, Color("edf1e6", alpha), 104)
		_centered(Trophies.grade_name(grade), center + Vector2(0, 64), 12, Color(tint, alpha), 104)

	func _draw_reward(center: Vector2) -> void:
		var grade = int(reward.rarity)
		var tint = Trophies.grade_color(grade)
		var ease_out = 1.0 - pow(1.0 - shine, 3.0)
		var still = minf(1.0, shine * 3.0)
		var ring_count = 1 + grade
		for i in ring_count:
			var radius = 48.0 + i * (12.0 if grade < 4 else 13.5) + (1.0 - still) * 11.0
			var glow_tint = Color(Trophies.PRISM[i % Trophies.PRISM.size()]) if grade == 5 else tint
			draw_circle(center, radius, Color(glow_tint, (.13 + .019 * grade) * still), false, 1.2, true)
			if i > 0 and grade >= 3:
				draw_arc(center, radius, i * .92 - shine * 1.5, i * .92 - shine * 1.5 + 1.18, 24, Color(glow_tint, .51 * still), 2, true)
		if grade >= 4:
			_draw_rays(center, grade, ease_out)
		var particle_count = [7, 14, 25, 43, 64][grade - 1]
		for i in particle_count:
			var angle = i * 2.39996
			var distance = (39.0 + float(i * 37 % 70)) * (ease_out * .76 + .24)
			var point = center + Vector2.from_angle(angle) * distance
			var glitter = Color(Trophies.PRISM[i % Trophies.PRISM.size()]) if grade == 5 else tint.lightened(.2)
			var opacity = (.28 + .44 * sin(angle + shine * 7.0) ** 2.0) * still
			if i % 3 == 0:
				_diamond(point, 2.0 + .22 * grade, Color(glitter, opacity))
			else:
				draw_circle(point, 1.05 + .17 * grade, Color(glitter, opacity), true, -1, true)
		_diamond(center, 47, Color(tint, .13))
		draw_set_transform(center + Vector2(0, -6), 0.0, Vector2.ONE * (1.04 + ease_out * .81))
		TrophyArt.paint(self, reward)
		draw_set_transform(Vector2.ZERO)
		_centered(Trophies.grade_name(grade) + "品质", Vector2(center.x, size.y - 38), 14, tint, 160)

	func _draw_rays(center: Vector2, grade: int, progress: float) -> void:
		var count = 11 if grade == 4 else 16
		for index in count:
			var angle = TAU * float(index) / count + progress * .32
			var tint = GOLD if grade == 4 else Color(Trophies.PRISM[index % Trophies.PRISM.size()])
			var start = center + Vector2.from_angle(angle) * 29.0
			var ray = Vector2.from_angle(angle) * lerpf(78.0, 170.0, progress)
			draw_colored_polygon(PackedVector2Array([start, start + ray + ray.orthogonal() * .042, start + ray - ray.orthogonal() * .057]), Color(tint, .10 if grade == 4 else .14))

	func _diamond(center: Vector2, radius: float, tint: Color) -> void:
		draw_colored_polygon(PackedVector2Array([center + Vector2.UP * radius, center + Vector2.RIGHT * radius, center + Vector2.DOWN * radius, center + Vector2.LEFT * radius]), tint)

	func _centered(label: String, at: Vector2, font_size: int, tint: Color, width: float) -> void:
		var step = font.get_string_size(label, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x
		draw_string(font, at - Vector2(minf(step, width) * .5, 0.0), label, HORIZONTAL_ALIGNMENT_LEFT, width, font_size, tint)
