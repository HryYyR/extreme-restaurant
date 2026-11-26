extends SceneTree
const Sim = preload("res://scripts/core/simulation.gd")
var summaries: Array = []

func _initialize() -> void:
	call_deferred("execute")

func buy_capacity(s, key: String) -> void:
	var result = s.upgrade(key)
	if not result.ok or result.facility_id.is_empty(): return
	var target = result.facility_id
	var positions = [Vector2i(6,1),Vector2i(8,1),Vector2i(9,1)] if key=="chefs" else [Vector2i(7,4),Vector2i(7,6),Vector2i(3,8),Vector2i(5,8),Vector2i(8,4),Vector2i(8,6)]
	for cell in positions:
		var copy = s.layout.duplicate(true)
		if not s.move_facility(target,cell).ok: continue
		if s.opening_errors().is_empty(): return
		s.layout = copy

func night_policy(s) -> void:
	var prior = s.last_report
	# Simple reference strategy, not an optimal solver.
	var priority = []
	if s.attributes.waiters<2: priority.append("waiters")
	elif s.attributes.tables<6: priority.append("tables")
	elif s.attributes.chefs<2: priority.append("chefs")
	elif s.attributes.waiters<3: priority.append("waiters")
	elif s.attributes.tables<8: priority.append("tables")
	elif s.attributes.chefs<3: priority.append("chefs")
	if not priority.is_empty() and s.reputation>=s.upgrade_cost(priority[0]): buy_capacity(s,priority[0])
	var rent = s.next_rent()
	var estimate = float(prior.get("income",360))
	var remaining = int(rent.day)-s.day+1 if not rent.is_empty() else 0
	var reserve = maxi(0,int(rent.get("amount",0))-int(estimate*remaining))
	var recipe = s.shop[0]
	if recipe.type=="recipe":
		var current = s.recipes[s.menu[0]]
		var proposed = s.recipes[recipe.id]
		var throughput_ok = proposed.batch_yield / proposed.cook_seconds >= current.batch_yield / current.cook_seconds * .65
		if proposed.base_value>current.base_value and throughput_ok and s.gold-int(recipe.price)>=reserve:
			s.buy_offer(0,0)
	var order = [1,2]
	order.sort_custom(func(a,b): return (s.shop[a].id=="great_value") and (s.shop[b].id!="great_value"))
	for slot in order:
		var offer = s.shop[slot]
		if offer.type!="buff": continue
		var useful = offer.id=="great_value" or offer.id=="high_heat" or offer.id=="swift_steps" or (offer.id=="rising_fame" and s.attributes.waiters<2)
		if useful and s.gold-int(offer.price)>=reserve: s.buy_offer(slot)

func execute() -> void:
	var count = 4 if "--quick" in OS.get_cmdline_user_args() else 12
	if "--many-seeds" in OS.get_cmdline_user_args(): count=30
	for index in range(count):
		var s = Sim.new()
		s.new_run(123456+index*997)
		var valid = true
		while true:
			night_policy(s)
			var opened = s.start_day()
			if not opened.ok:
				push_error(str(opened)); valid=false; break
			while s.phase=="DAY":
				s.step()
				if not s.invariant_errors().is_empty():
					push_error(str(s.invariant_errors())); valid=false; break
			if not valid or s.last_report.result!="CONTINUE": break
			s.continue_night()
		var summary = {"seed":s.seed_value,"day":s.day,"result":s.last_report.get("result","ERROR"),"cash":s.gold,"valid":valid,"reports":s.reports}
		summaries.append(summary)
		print("CHAPTER seed=",s.seed_value," day=",s.day," result=",summary.result," cash=",s.gold)
	var wins = summaries.filter(func(s): return s.result=="WIN").size()
	var file = FileAccess.open("res://.local/chapter_probe.json",FileAccess.WRITE)
	file.store_string(JSON.stringify({"strategy":"固定参考策略，非最优求解；不代表最终通关率", "runs":count,"wins":wins,"summaries":summaries},"\t"))
	file.close()
	print("CHAPTER RESULT: ",wins," / ",count," wins")
	quit(0 if summaries.all(func(s): return s.valid) else 1)
