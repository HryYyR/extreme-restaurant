extends RefCounted

const LINES = {
	&"arrival": ["好香呀。", "有座吗？", "来碗热的。", "就这家！"],
	&"waiting": ["先喝口茶。", "闻着真香。", "有点期待。", "我等会儿。"],
	&"impatient": ["菜快好了吗？", "茶喝完啦……", "帮我催催？"],
	&"eating": ["呼，好烫！", "味道正好。", "慢慢尝。", "趁热吃！"],
	&"after_meal": ["吃饱啦。", "多谢招待！", "光盘啦。", "下次再来。"],
	&"midnight": ["该回家啦。", "师傅辛苦！", "明天见。"],
	&"closing": ["九点啦？", "要打烊啦。", "街灯亮了。", "这么晚啦。"],
}
const COLORS = {
	&"arrival": Color("549286"), &"waiting": Color("af844b"), &"impatient": Color("b46c56"),
	&"eating": Color("658b54"), &"after_meal": Color("598799"), &"closing": Color("8e779d"), &"midnight": Color("8e779d"),
}
const STATES = {
	&"arrival": ["QUEUE", "SEATING", "CHOOSING"], &"waiting": ["FOOD"], &"impatient": ["FOOD"],
	&"eating": ["EATING"], &"after_meal": ["STAYING", "LEAVING", "AT_EXIT", "EXITING"],
}
const MAX_PENDING := 12
const MIN_GAP_SECONDS := 13.0
const MAX_GAP_SECONDS := 19.0
const REMARK_SECONDS := 2.0

var pending: Array[Dictionary] = []
var rng := RandomNumberGenerator.new()
var last_line := {}
var last_shown := {}
var sequence := 0
var cooldown := 0.0
var bubble
var speaking := {}
var day := -1
var bell_moment := &""
var bell_tick := -1

func _init() -> void:
	rng.randomize()

func reset() -> void:
	pending.clear()
	last_shown.clear()
	day = -1
	bell_moment = &""
	cooldown = 0.0
	_silence()

func _silence() -> void:
	if is_instance_valid(bubble) and not bubble.is_queued_for_deletion(): bubble.dismiss()
	bubble = null
	speaking = {}

func _start_day(sim) -> void:
	if day != sim.day:
		reset()
		day = sim.day

func bell(sim, midnight: bool) -> void:
	_start_day(sim)
	bell_moment = &"midnight" if midnight else &"closing"
	bell_tick = sim.tick
	pending.clear()

func enqueue(sim, id: int, moment: StringName) -> void:
	_start_day(sim)
	for i in range(pending.size() - 1, -1, -1):
		if pending[i].id == id: pending.remove_at(i)
	if pending.size() >= MAX_PENDING: pending.pop_front()
	pending.append({"id": id, "moment": moment, "tick": sim.tick})

func _current(sim, event: Dictionary) -> bool:
	var guest = sim.active_customers.get(event.id)
	if guest == null: return false
	if event.moment == &"midnight": return guest.terminal == "C"
	if event.moment == &"closing": return guest.terminal.is_empty()
	return guest.state in STATES[event.moment] and (event.moment != &"after_meal" or guest.terminal == "S")

func _pick_line(moment: StringName) -> String:
	var pool: Array = LINES[moment]
	var previous = int(last_line.get(moment, -1))
	var pick = rng.randi_range(0, pool.size() - 1 if previous < 0 else pool.size() - 2)
	if previous >= 0 and pick >= previous: pick += 1
	last_line[moment] = pick
	return pool[pick]

func advance(world, delta: float, muted: bool) -> void:
	var sim = world.sim
	if sim.phase != "DAY":
		if day >= 0: reset()
		return
	if muted:
		pending.clear()
		bell_moment = &""
		_silence()
		return
	cooldown = maxf(0, cooldown - delta)
	var visible_area = Rect2(Vector2(18, 70), world.size - Vector2(36, 140))
	if bell_moment != &"":
		if (sim.tick - bell_tick) * sim.tick_ms > 6500:
			bell_moment = &""
		else:
			var speakers: Array[int] = []
			for actor_id: String in world.actors:
				if not actor_id.begins_with("g_"): continue
				var id = actor_id.substr(2).to_int()
				var point = world._speech_anchor(actor_id)
				if point != null and visible_area.has_point(point) and _current(sim, {"id": id, "moment": bell_moment}):
					speakers.append(id)
			if not speakers.is_empty():
				_silence()
				_speak(world, {"id": speakers[rng.randi_range(0, speakers.size() - 1)], "moment": bell_moment})
				bell_moment = &""
				return
	if is_instance_valid(bubble) and not bubble.is_queued_for_deletion():
		if _current(sim, speaking): return
		_silence()
	if cooldown > 0: return
	var selected := -1
	var oldest := 2147483647
	for i in range(pending.size() - 1, -1, -1):
		var event = pending[i]
		if (sim.tick - event.tick) * sim.tick_ms > 6500 or not _current(sim, event):
			pending.remove_at(i)
			if selected > i: selected -= 1
			continue
		var point = world._speech_anchor("g_%d" % event.id)
		if point == null or not visible_area.has_point(point): continue
		var priority = int(last_shown.get(event.moment, -1))
		if priority <= oldest:
			selected = i
			oldest = priority
	if selected < 0: return
	_speak(world, pending.pop_at(selected))

func _speak(world, event: Dictionary) -> void:
	speaking = event
	var sim = world.sim
	var moment: StringName = speaking.moment
	var guest = sim.active_customers[speaking.id]
	var name = sim.guest_defs[guest.type].name
	bubble = world.say("g_%d" % guest.id, name, _pick_line(moment), REMARK_SECONDS, false, COLORS[moment])
	sequence += 1
	last_shown[moment] = sequence
	cooldown = rng.randf_range(MIN_GAP_SECONDS, MAX_GAP_SECONDS)
