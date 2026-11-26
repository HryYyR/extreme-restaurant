extends SceneTree

const Sim = preload("res://scripts/core/simulation.gd")
const Store = preload("res://scripts/core/save_store.gd")
const Catalog = preload("res://scripts/core/catalog.gd")

var passed := 0
var failed := 0

func _initialize() -> void:
	call_deferred("run")

func check(condition: bool, description: String) -> void:
	if condition:
		passed += 1
	else:
		failed += 1
		push_error(description)

func _check_calendar() -> void:
	for chapter in ["street_corner", "market_lane"]:
		var data = Catalog.load_all(chapter)
		check(data.errors.is_empty(), "两章均可验证天气配置")
		var sim = Sim.new(data)
		for date in [10, 11, 12, 13, 15, 16, 20, 21, 22]:
			var expected = "clear"
			if date in [11, 12]: expected = "rain"
			if date >= 16 and date <= 21: expected = "thunderstorm"
			check(sim.weather_for(date).id == expected, "事件天气覆盖正确日期")
		sim.chapter.weather.calendar = [{"day": 4, "duration_days": 2, "weather": "thunderstorm"}, {"day": 10, "duration_days": 3, "weather": "clear"}]
		check(sim.weather_for(4).id == "thunderstorm" and sim.weather_for(5).id == "thunderstorm" and sim.weather_for(6).id == "clear", "仅配置天气日历也能安排连续降雨")
		check(sim.weather_for(11).id == "rain", "事件天气优先于普通天气日历")
		data.chapter.weather.calendar[0].weather = "unknown"
		check(not Catalog.validate(data).is_empty(), "无效天气引用能被发现")

	var clear = Sim.new()
	var wet = Sim.new()
	clear.day = 4
	wet.day = 4
	wet.chapter.weather.calendar = [{"day": 4, "weather": "thunderstorm"}]
	clear.start_day()
	wet.start_day()
	check(clear.arrival_plan == wet.arrival_plan, "单独配置雷雨不改变到店计划")
	while clear.phase == "DAY": clear.step()
	while wet.phase == "DAY": wet.step()
	check(wet.last_report == clear.last_report, "只改变天气时整个结算完全一致")

func _shot(name: String) -> void:
	if DisplayServer.get_name() == "headless": return
	await process_frame
	await RenderingServer.frame_post_draw
	var image = root.get_texture().get_image()
	check(image.save_png("res://.local/weather-%s.png" % name) == OK, "保存天气画面 " + name)

func run() -> void:
	if "--ui-test" not in OS.get_cmdline_user_args():
		quit(1)
		return
	_check_calendar()
	Store.write_checkpoint(Sim.new().export_state(), Store.default_path("street_corner", true))
	var game = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	await process_frame
	root.focus_exited.disconnect(game._on_focus_lost)
	game.guide.skip()
	game.set_process(false)
	var world = game.world
	world.set_process(false)
	var weather = world.weather
	game.sim.day = 11
	game._open_day()
	game.sim.tick = 720
	for i in range(8): world._process(.5)
	check(game.ui.badge.rainy and not game.ui.badge.storm and game.ui.badge.tooltip_text.contains("下雨"), "普通下雨显示图标与说明")
	check(weather.rain > .5 and weather.wetness > .3 and weather.next_strike == INF and weather.flash == 0.0, "普通雨会积水且没有闪电")
	check(weather.visible_drops.size() > 10 and weather.visible_drops.all(func(drop): return not weather.roof.has_point(Vector2(drop[0], drop[1]))), "雨滴只在室外接触地面，餐厅受屋顶遮挡")
	check(weather.rain_audio.stream != null and weather.rain_audio.playing, "雨声能加载并循环播放")
	await _shot("rain")

	game.sim.day = 12
	var before: float = weather.wetness
	world._process(.2)
	check(weather.wetness >= before, "连续两个雨天的积水不会重置")
	game.sim.day = 13
	world._process(2.2)
	check(weather.rain == 0.0 and weather.wetness > .0 and not weather.rain_audio.playing, "雨停后静音，路面积水逐渐消散")
	world._process(22.0)
	check(weather.wetness == 0.0, "放晴后路面恢复干燥")

	game.sim.day = 16
	game._update_hud()
	world._process(0.0)
	check(game.ui.badge.rainy and game.ui.badge.storm and game.ui.badge.tooltip_text.contains("雷雨"), "雷雨显示独立图标")
	check(weather.next_strike > weather.time + 2.9, "雷雨会先积云再触发首个雷击")
	world._process(weather.next_strike - weather.time + .002)
	check(weather.flash > .94 and weather.lamp_voltage == 1.0 and not weather.thunder_audio.playing, "先看到闪电，雷声延后")
	check(Array(weather.bolt).any(func(point): return weather.world_view.grow(-1.0).has_point(point)), "默认镜头能看到街区方向的闪电")
	await _shot("thunder-flash")
	var lamp_energy: float = world.lamps[0].energy
	for i in range(3):
		world._process([.18, .22, .11][i])
		check(weather.lamp_voltage < .65 and world.lamps[0].energy < lamp_energy, "打雷后有三次室内灯光变暗")
		if i < 2:
			world._process(.11 if i == 0 else .09)
			check(weather.lamp_voltage == 1.0, "每次灯闪之间恢复亮度")
	world._process(1.0)
	check(weather.lamp_voltage == 1.0 and weather.thunder_audio.stream != null and weather.thunder_audio.playing, "雷声延迟播放，室内灯恢复")
	var held: float = weather.time
	game.sim.paused = true
	world._process(1.0)
	check(weather.time == held and weather.rain_audio.stream_paused and weather.thunder_audio.stream_paused, "暂停时天气和声音同步冻结")
	game.sim.paused = false
	world._process(.1)
	check(weather.time > held and not weather.rain_audio.stream_paused, "恢复营业时天气继续推进")
	await _shot("thunder")

	game.queue_free()
	await process_frame
	print("WEATHER RESULT: %d passed / %d failed" % [passed, failed])
	quit(1 if failed else 0)
