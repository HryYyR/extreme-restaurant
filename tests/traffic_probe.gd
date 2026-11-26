extends SceneTree
const Sim = preload("res://scripts/core/simulation.gd")
func _initialize() -> void:
	var s = Sim.new()
	s.day = 22
	# Keep a separate high-load fixture as normal chapter demand is tuned for play.
	s.chapter.demand_curve[-1].normal = 680
	s.chapter.demand_curve[-1].rare = 20
	s.chapter.guest_groups = []
	var max_queue = "--max-queue" in OS.get_cmdline_user_args()
	if max_queue: s.attributes.queue_capacity = int(s.chapter.attribute_caps.queue_capacity)
	s.grant_buff("crowd_magnet", 2)
	var result = s.start_day()
	if not result.ok: push_error(str(result)); quit(1); return
	var start = Time.get_ticks_msec()
	while s.phase == "DAY" and s.tick < (s.day_ticks if max_queue else 30000):
		s.step()
		if s.tick % 200 == 0 and not s.invariant_errors().is_empty():
			push_error(str(s.invariant_errors())); quit(1); return
	if max_queue:
		var ok = s.stats.arrived >= 1000 and s.stats.admitted >= 1000 and s.stats.refused == 0 and s._queue_count() <= int(s.attributes.queue_capacity) and s.phase == "DAY"
		print("TRAFFIC CAP: arrived=",s.stats.arrived," admitted=",s.stats.admitted," refused=",s.stats.refused," queue=",s._queue_count()," run_ms=",Time.get_ticks_msec()-start)
		quit(0 if ok else 1)
		return
	if s.phase != "REPORT": push_error("清场未能完成"); quit(1); return
	if not s.invariant_errors().is_empty(): push_error(str(s.invariant_errors())); quit(1); return
	print("TRAFFIC: planned=",s.last_report.planned," arrived=",s.last_report.arrived," refused=",s.last_report.refused," admitted=",s.last_report.admitted," queue_peak=",s.last_report.peak_queue," elapsed_ticks=",s.tick," run_ms=",Time.get_ticks_msec()-start)
	quit(0 if s.last_report.arrived >= 1000 and s.last_report.arrived == s.last_report.refused + s.last_report.admitted else 1)
