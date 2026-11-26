extends SceneTree

const Sim = preload("res://scripts/core/simulation.gd")

func _initialize() -> void:
	var sim = Sim.new()
	if not sim.catalog.errors.is_empty():
		push_error(str(sim.catalog.errors))
		quit(1)
		return
	var result = sim.start_day()
	if not result.ok:
		push_error(str(result))
		quit(1)
		return
	while sim.phase == "DAY":
		sim.step()
		var errors = sim.invariant_errors()
		if not errors.is_empty():
			push_error("tick %d: %s" % [sim.tick, errors])
			quit(1)
			return
	print("SMOKE PASS: ", JSON.stringify(sim.last_report))
	quit(0)
