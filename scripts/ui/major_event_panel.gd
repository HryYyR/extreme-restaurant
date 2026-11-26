extends VBoxContainer

const Style = preload("res://scripts/ui/style.gd")
const Icon = preload("res://scripts/ui/ui_icon.gd")
const THEMES = {
	"food_festival": ["crowd", Color("f1c082")],
	"thug_visit": ["alert", Color("f2a392")],
	"group_booking": ["table", Color("a9d6b8")],
	"food_inspection": ["check", Color("c2d0f4")],
	"bad_weather": ["clock", Color("a6c7db")],
	"food_review": ["star", Color("f6d79d")],
}

signal confirmed

func populate(event: Dictionary, challenge: Dictionary, viewed: bool, guest: Dictionary) -> void:
	add_theme_constant_override("separation", 12)
	var motif = THEMES.get(event.id, ["alert", Style.GOLD])
	var accent: Color = motif[1]
	var spread = HBoxContainer.new()
	spread.add_theme_constant_override("separation", 13)
	add_child(spread)
	var poster = Style.card()
	poster.custom_minimum_size.x = 353
	poster.add_theme_stylebox_override("panel", Style.box(Color("192b30"), accent.darkened(.45), 12, 9))
	spread.add_child(poster)
	var cover = VBoxContainer.new()
	cover.add_theme_constant_override("separation", 8)
	poster.add_child(cover)
	_add_art(cover, event)
	var date = "第 %d 天" % int(event.from_day) if event.from_day == event.to_day else "第 %d–%d 天" % [int(event.from_day), int(event.to_day)]
	Style.readout(cover, "clock", date, "事件生效日期", accent, 14)
	var story = Style.text(str(event.description), 14, Style.MUTED, true)
	story.custom_minimum_size.x = 320
	cover.add_child(story)
	var detail = VBoxContainer.new()
	detail.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	detail.add_theme_constant_override("separation", 10)
	spread.add_child(detail)
	var effects = _section(detail, "营业影响", motif[0], accent)
	for line in effect_lines(event, guest):
		var paragraph = Style.text(line, 15, Style.INK, true)
		paragraph.custom_minimum_size.x = 365
		effects.add_child(paragraph)
	if not challenge.is_empty():
		var goal = _section(detail, "限时任务", "star", Style.GOLD)
		goal.add_child(Style.text("每天各获 %d 闪星 · 奖励 %s" % [int(challenge.required), reward_text(challenge.reward)], 14, Style.MUTED))
		var stamps = HBoxContainer.new()
		stamps.add_theme_constant_override("separation", 6)
		goal.add_child(stamps)
		for entry in challenge.days:
			var earned = int(entry.stars)
			var tint = Style.GOLD if earned >= int(challenge.required) else Style.MUTED
			var stamp = Style.card()
			stamp.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			stamp.add_theme_stylebox_override("panel", Style.box(Color("263c3d"), tint.darkened(.48), 8, 6))
			stamps.add_child(stamp)
			var column = VBoxContainer.new()
			column.add_theme_constant_override("separation", 3)
			stamp.add_child(column)
			var date_label = Style.text("第 %d 天" % int(entry.day), 12, tint)
			date_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			column.add_child(date_label)
			var pips = HBoxContainer.new()
			pips.alignment = BoxContainer.ALIGNMENT_CENTER
			pips.add_theme_constant_override("separation", 3)
			column.add_child(pips)
			for i in range(int(challenge.required)):
				pips.add_child(Icon.make("star" if i < earned else "star_outline", tint, 12))
	var grant = event.notice.get("grant", {})
	var confirm = Style.button("确定并领取 " + reward_text(grant) if not viewed and not grant.is_empty() else "确定", true)
	confirm.name = "ConfirmMajorEvent"
	confirm.pressed.connect(confirmed.emit)
	add_child(confirm)
	detail.modulate.a = .3
	detail.create_tween().tween_property(detail, "modulate:a", 1.0, .30).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)

func _section(parent: VBoxContainer, title: String, glyph: String, accent: Color) -> VBoxContainer:
	var card = Style.card()
	card.add_theme_stylebox_override("panel", Style.box(Style.BG, accent.darkened(.52), 9, 11))
	parent.add_child(card)
	var stack = VBoxContainer.new()
	stack.add_theme_constant_override("separation", 7)
	card.add_child(stack)
	Style.readout(stack, glyph, title, "", accent, 16)
	return stack

func _add_art(parent: VBoxContainer, event: Dictionary) -> void:
	var path = str(event.notice.get("art", ""))
	if path.is_empty():
		var banner = InspectionBanner.new()
		banner.name = "MajorEventArtwork"
		banner.custom_minimum_size.y = 168
		parent.add_child(banner)
		return
	var art = TextureRect.new()
	art.name = "MajorEventArtwork"
	art.custom_minimum_size.y = 188
	art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	art.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if ResourceLoader.exists(path):
		art.texture = load(path) as Texture2D
	else:
		var raster = Image.load_from_file(path)
		if raster != null and not raster.is_empty(): art.texture = ImageTexture.create_from_image(raster)
	parent.add_child(art)

class InspectionBanner extends Control:
	func _draw() -> void:
		var border = Style.box(Color("253f43"), Color("6c8880"), 11, 0)
		draw_style_box(border, Rect2(Vector2.ZERO, size))
		var center = size * .5
		for i in range(5):
			var offset = (i - 2) * 87.0
			draw_arc(center + Vector2(offset, 0), 44, -PI * .78, PI * .78, 40, Color("a4c7b1", .15), 2, true)
		draw_circle(center, 55, Color("213439"), true, -1, true)
		draw_circle(center, 51, Style.GOLD, false, 2, true)
		draw_rect(Rect2(center + Vector2(-21, -29), Vector2(42, 60)), Color("fbebca"))
		draw_rect(Rect2(center + Vector2(-10, -32), Vector2(20, 8)), Color("b99568"))
		for y in [-12, 0, 12]:
			var start = center + Vector2(-12, y)
			draw_polyline(PackedVector2Array([start, start + Vector2(3, 4), start + Vector2(8, -3)]), Color("497c68"), 2, true)
			draw_line(start + Vector2(12, 1), start + Vector2(22, 1), Color("907b62"), 1.5)

static func reward_text(reward: Dictionary) -> String:
	var parts = []
	if reward.has("reputation"): parts.append("%d 声望" % int(reward.reputation))
	if reward.has("gold"): parts.append("%d 金币" % int(reward.gold))
	return "和".join(parts)

static func peak_time(peak: Dictionary) -> String:
	var start = int(peak.start_minute)
	var end = int(peak.end_minute)
	@warning_ignore("integer_division")
	return "%02d:%02d–%02d:%02d" % [start / 60, start % 60, end / 60, end % 60]

static func effect_lines(event: Dictionary, guest: Dictionary) -> Array:
	var lines = []
	var traffic = event.get("traffic", {})
	var names = {"normal":"普通客人","rare":"稀有客人","2":"双人组","4":"四人组"}
	var counts = []
	for category in names:
		if not traffic.has(category): continue
		var pct = roundi(float(traffic[category]) * 100.0)
		counts.append("%s %s%d%%" % [names[category], "+" if pct > 0 else "", pct])
	if not counts.is_empty(): lines.append("每天  " + " · ".join(counts))
	if event.has("regular_traffic_multiplier"):
		lines.append("每天的常规客流减少 %d%%" % roundi((1.0 - float(event.regular_traffic_multiplier)) * 100))
	if not guest.is_empty():
		if guest.get("unlimited_food_wait", false):
			lines.append("第 %d 天来一人，第 %d 天来两人。记得留出双人桌。" % [int(event.from_day), int(event.to_day)])
			lines.append("地痞会一直等到上菜，每人每轮等餐扣 %d 声望。" % int(guest.food_penalty_per_cycle))
		elif event.has("quality_inspection"):
			var config = event.quality_inspection
			lines.append("%d 位安全员同桌用餐，用餐时长为平时的 %d 倍。" % [int(event.special_visits[0].size), int(guest.eat_time_multiplier)])
			var base = roundi((1.0 - float(config.neutral_quality)) * 100.0 * int(config.reputation_per_percentage_point))
			lines.append("全组餐点平均品质 %d%% 时声望持平。100%% 品质扣 %d 声望，超出标准有奖励。" % [roundi(float(config.neutral_quality) * 100), -base])
			lines.append("未上齐的餐点会拉低检查结果。")
		else:
			lines.append("会有一位%s到店。" % guest.name)
	if event.has("arrival_peak"): lines.append("%s 集中约 %d%% 的计划客流" % [peak_time(event.arrival_peak), roundi(float(event.arrival_peak.share) * 100.0)])
	if event.has("quality_expectation_add"): lines.append("客人品质要求 +%d 个百分点" % roundi(float(event.quality_expectation_add) * 100.0))
	if event.has("payment_pct"): lines.append("菜价收益 +%d%%" % roundi(float(event.payment_pct) * 100.0))
	return lines
