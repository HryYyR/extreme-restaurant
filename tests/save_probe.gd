extends SceneTree
const Sim = preload("res://scripts/core/simulation.gd")
const Store = preload("res://scripts/core/save_store.gd")
func _initialize() -> void:
	var s = Sim.new()
	var saved = Store.read_checkpoint("res://.local/unit_checkpoint.json")
	print("READ fields=",saved.keys())
	print("RESTORE=",s.restore_state(saved))
	print("SHOP original=",saved.shop," restored=",s.shop," eq=",saved.shop==s.shop)
	var a = Sim.new()
	a.start_day()
	while a.phase=="DAY": a.step()
	var b = Sim.new()
	print("ROUNDTRIP=",b.restore_state(JSON.parse_string(JSON.stringify(a.export_state()))))
	for key in a.last_report:
		if a.last_report[key]!=b.last_report.get(key): print("DIFF ",key,": ",a.last_report[key]," -> ",b.last_report.get(key))
	print("REPORT canonical=",JSON.stringify(a.last_report,"",true)==JSON.stringify(b.last_report,"",true))
	print("PATH=",Store.default_path())
	quit()
