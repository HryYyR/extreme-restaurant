extends SceneTree
const Catalog = preload("res://scripts/core/catalog.gd")
const Sim = preload("res://scripts/core/simulation.gd")
func _initialize() -> void:
	for speed in [2.5,3.5,4.0,4.5]:
		for cycle in [15,20]:
			var data = Catalog.load_all()
			data.chapter.movement.waiter_speed = speed
			data.chapter.common_guest_template.food_penalty_cycle_seconds = cycle
			data.chapter.common_guest_template.food_max_wait_seconds = 80 if cycle==20 else 60
			data.chapter.initial_layout.waiter_spawn = [3,3]
			var coords = [[3,4],[5,4],[3,6],[5,6]]
			for i in range(4): data.chapter.initial_layout.facilities[i+3].pos=coords[i]
			var sim = Sim.new(data)
			sim.start_day()
			while sim.phase=="DAY": sim.step()
			print("speed=",speed," cycle=",cycle," income=",sim.last_report.income," reputation=",sim.reputation," completed=",sim.last_report.completed," funnel=",sim.last_report.funnel)
	quit()
