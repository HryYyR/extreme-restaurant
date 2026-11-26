extends RefCounted

static func summarize(stats: Dictionary, thresholds: Dictionary) -> Dictionary:
	var queue_wait = _wait_summary(stats.queue_waits)
	var diagnosis = _diagnosis(stats, float(thresholds.loss_ratio))
	return {
		"queue_wait_summary": queue_wait,
		"food_wait_summary": _wait_summary(stats.food_waits),
		"order_wait_summary": _wait_summary(stats.order_waits),
		"diagnosis": diagnosis,
		"tips": _tips(stats, thresholds, diagnosis.focus, queue_wait.average),
	}

static func _wait_summary(samples: Array) -> Dictionary:
	var values = []
	var sum_values = 0.0
	var success_sum = 0.0
	var success_count = 0
	var lost_sum = 0.0
	var lost_count = 0
	for sample in samples:
		var seconds = float(sample.seconds)
		values.append(seconds)
		sum_values += seconds
		if sample.success:
			success_sum += seconds
			success_count += 1
		else:
			lost_sum += seconds
			lost_count += 1
	values.sort()
	return {
		"average": sum_values / maxi(1, values.size()),
		"p90": values[ceili(values.size() * 0.9) - 1] if not values.is_empty() else 0.0,
		"success_average": success_sum / maxi(1, success_count),
		"lost_average": lost_sum / maxi(1, lost_count),
		"count": values.size(),
	}

static func _report_stage(samples: Array, field: String) -> Dictionary:
	var total = 0.0
	var count = 0
	var tables = {}
	for sample in samples:
		if not sample.has(field): continue
		var seconds = float(sample[field])
		total += seconds
		count += 1
		if seconds > 0 and not str(sample.table).is_empty():
			tables[sample.table] = float(tables.get(sample.table, 0.0)) + seconds
	var ranked = tables.keys()
	ranked.sort_custom(func(a, b): return str(a) < str(b) if tables[a] == tables[b] else tables[a] > tables[b])
	return {"average": total / maxi(1, count), "count": count, "tables": ranked.slice(0, 3)}

static func _diagnosis(stats: Dictionary, loss_ratio: float) -> Dictionary:
	var ordering = _report_stage(stats.order_waits, "seconds")
	var kitchen = _report_stage(stats.food_waits, "before_pass")
	var delivery = _report_stage(stats.food_waits, "after_pass")
	var no_seat = int(stats.refused) - int(stats.get("refused_no_table", 0)) + int(stats.closing_stages.get("QUEUE", 0))
	var queue = {"average": 100.0 * no_seat / maxi(1, int(stats.arrived)), "count": int(stats.arrived), "tables": []}
	var order_losses = int(stats.funnel.O) + int(stats.closing_stages.get("READY", 0)) + int(stats.closing_stages.get("TAKING", 0))
	var food_losses = int(stats.funnel.F) + int(stats.closing_stages.get("FOOD", 0))
	var focus = ""
	if order_losses >= maxi(1, ceili(int(stats.arrived) * loss_ratio)):
		focus = "ordering"
	elif food_losses > 0 or int(stats.wait_penalty_raw) > 0:
		focus = "delivery" if float(delivery.average) * int(delivery.count) > float(kitchen.average) * int(kitchen.count) else "kitchen"
	elif no_seat > 0:
		focus = "queue"
	return {"focus": focus, "stages": {"ordering": ordering, "kitchen": kitchen, "delivery": delivery, "queue": queue}}

static func _tips(stats: Dictionary, thresholds: Dictionary, focus: String, average_queue_wait: float) -> Array:
	var tips = []
	var funnel = stats.funnel
	var issue_threshold = maxi(1, ceili(int(stats.arrived) * float(thresholds.loss_ratio)))
	var missing_table = int(stats.get("refused_no_table", 0))
	if missing_table > 0: tips.append("有客人组找不到匹配的桌位。夜晚可把同规格餐桌拖到一起合成。")
	if focus != "ordering" and int(funnel.O) + int(stats.closing_stages.get("READY", 0)) >= issue_threshold:
		tips.append("待点单流失偏多：考虑加服务员，或缩短餐桌到订单口的路线。")
	if focus not in ["kitchen", "delivery"] and (int(funnel.F) > 0 or int(stats.wait_penalty_raw) >= issue_threshold):
		tips.append("等餐链路偏慢：先看订单积压还是出餐口堆积，再决定加厨师还是服务员。")
	if focus != "queue":
		if int(funnel.R) - missing_table >= issue_threshold:
			tips.append("队列满额拒客较多：可在收银台扩大队列，同时检查餐桌和出餐速度。")
		elif average_queue_wait >= float(thresholds.get("queue_wait_hint_seconds", 30)):
			tips.append("排队时间偏长：更多桌位或更短的用餐周转能改善接待。")
	if int(stats.quality_penalty_raw) > 0:
		tips.append("品质低于预期：品质 Buff 可改善声望与客单，但不能解决配送等待。")
	if int(stats.completed) - int(stats.get("completed_before_midnight", stats.completed)) >= issue_threshold:
		tips.append("有客人午夜后才完餐。更快的上菜和配送能让更多人赶上完餐目标。")
	if tips.is_empty() and focus.is_empty():
		tips.append("流水线较稳定：根据明日事件调整菜单，并保留下一笔房租现金。")
	return tips.slice(0, 2 if focus.is_empty() else 1)
