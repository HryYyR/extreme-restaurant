extends SceneTree
const Sim = preload("res://scripts/core/simulation.gd")
func _initialize() -> void:
	var results = []
	for i in range(4):
		var s = Sim.new()
		s.new_run(123456+i*997)
		while true:
			s.start_day()
			while s.phase=="DAY": s.step()
			if s.last_report.result!="CONTINUE": break
			s.continue_night()
		results.append({"seed":s.seed_value,"day":s.day,"result":s.last_report.result,"cash":s.gold})
		print("PASSIVE: seed=",s.seed_value," day=",s.day," result=",s.last_report.result)
	var file = FileAccess.open("res://.local/passive_probe.json",FileAccess.WRITE)
	file.store_string(JSON.stringify({"description":"完全不买、不升级、不改布局的对照，不代表所有保守策略", "results":results},"\t"))
	file.close()
	quit()
