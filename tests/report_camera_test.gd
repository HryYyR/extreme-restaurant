extends SceneTree

const Grid = preload("res://scripts/core/layout.gd")
const Store = preload("res://scripts/core/save_store.gd")
const Sim = preload("res://scripts/core/simulation.gd")
var checks := 0
var failures := 0

func check(ok: bool, description: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		push_error(description)

func _initialize() -> void:
	call_deferred("run")

func shot(name: String) -> void:
	if DisplayServer.get_name() == "headless": return
	await RenderingServer.frame_post_draw
	check(root.get_texture().get_image().save_png("res://.local/%s-%dx%d.png" % [name, root.size.x, root.size.y]) == OK, "保存截图 " + name)

func run() -> void:
	if "--ui-test" not in OS.get_cmdline_user_args():
		quit(1)
		return
	Store.write_checkpoint(Sim.new().export_state(), Store.default_path("street_corner", true))
	var scene = load("res://scenes/main.tscn").instantiate()
	root.add_child(scene)
	await process_frame
	scene.guide.skip()
	# This fixture advances ticks explicitly, independent of desktop window focus.
	scene.get_window().focus_exited.disconnect(scene._on_focus_lost)
	scene.set_process(false)
	scene.sim.day = 11
	scene.sim.stars = 20
	for id in ["purchase_annex", "trophy_gallery", "decor_studio"]:
		check(scene.sim.unlock_land_plot(id).ok, "解锁 " + id)
	scene._refresh_all()
	scene._show_decoration_shop()
	var bag = scene.modal_layer.find_children("*", "Button", true, false).filter(func(btn): return btn.text == "打开建造背包")
	bag[0].pressed.emit()
	check(scene.modal_layer == null and scene.world.camera_input_enabled and scene.ui.build_catalog.visible and scene.ui.build_catalog.active_category == "decoration", "打开装饰背包时关闭商店，场景立即恢复输入")
	scene._close_build_page()
	scene._discard_fading_modal()
	scene.world._process(0.0)
	scene._inspect("preview", "preview_waiter_0")
	scene.ui.info_follow.pressed.emit()
	scene.world._advance_follow(.5)
	check(scene.world.follow_actor_id == "preview_waiter_0" and scene.world.zoom > 1.4, "备班员工可点击图标放大并跟随")
	var action = InputEventMouseButton.new()
	action.button_index = MOUSE_BUTTON_WHEEL_DOWN
	action.pressed = true
	scene._input(action)
	check(scene.world.follow_actor_id.is_empty(), "滚轮动作取消跟随")
	scene.world.focus_restaurant()

	check(scene.sim.move_facility("table_6", Vector2i(7, 10)).ok, "测试布局包含双人桌")
	scene._open_day()
	scene.sim.arrival_plan = scene.sim.arrival_plan.filter(func(plan): return plan.type == "thug")
	var visits = scene.sim.arrival_plan
	check(visits.size() == 1, "首日只安排单人地痞")
	var first_id = int(visits[0].id)
	while scene.sim.tick < int(visits[0].tick): scene.sim.step()
	check(scene.ui.special_notice.visible and scene.ui.special_caption.text == "地痞 到店" and scene.world.follow_actor_id == "g_%d" % first_id, "单人特殊客到店时触发通知和自动跟随")
	scene.special_notice_motion.custom_step(.26)
	scene.world._process(.6)
	await shot("special-guest")
	while scene.sim.tick < int(visits[0].tick) + 400 and scene.sim.customers[first_id].state != "FOOD": scene.sim.step()
	scene.world._sync_actors()
	scene._inspect("customer", str(first_id))
	var profile = scene.ui.guest_profile
	check(profile.visible and profile.phase_label.text == "等待上菜" and profile.meter.visible and profile.meter_title.text == "距下次扣声望" and profile.dish.text.contains("家常饭"), "特殊客资料显示状态、已点菜和惩罚倒计时")
	await create_timer(.30).timeout
	await shot("guest-profile")
	scene.ui.info_follow.pressed.emit()
	check(scene.world.follow_actor_id == "g_%d" % first_id and scene.world.follow_seconds < 0, "手动跟随不使用自动倒计时")
	var key = InputEventKey.new()
	key.pressed = true
	key.physical_keycode = KEY_ESCAPE
	scene._input(key)
	check(scene.world.follow_actor_id.is_empty(), "键盘动作能取消客人跟随")
	scene._clear_inspector()
	scene.special_notice_motion.custom_step(5.0)
	check(not scene.ui.special_notice.visible, "通知固定时长后消失")
	while scene.sim.phase == "DAY" and scene.sim.tick < 10000: scene.sim.step()
	check(scene.sim.phase == "REPORT", "完成第 11 天营业")
	scene._show_report()
	scene._continue_night()
	check(not scene.ui.diagnostic_card.visible, "下一晚无需手动清除复盘定位")
	scene._discard_fading_modal()
	scene._open_day()
	scene.sim.arrival_plan = scene.sim.arrival_plan.filter(func(plan): return plan.type == "thug")
	visits = scene.sim.arrival_plan
	check(visits.size() == 2, "次日只安排双人地痞")
	while scene.sim.tick < int(visits[0].tick): scene.sim.step()
	check(scene.ui.special_caption.text.contains("2 位地痞") and scene.world.follow_actor_id == "g_%d" % int(visits[0].id), "次日双人组只触发组长一次跟随和通知")
	scene.world._advance_follow(scene.SPECIAL_NOTICE_SECONDS + .1)
	check(scene.world.follow_actor_id.is_empty() and scene.world.return_camera.is_valid(), "自动跟随到时平滑返回")
	while scene.sim.phase == "DAY" and scene.sim.tick < 10000: scene.sim.step()
	check(scene.sim.phase == "REPORT", "完成第 12 天营业")
	scene._show_report()
	var current = scene.sim.last_report.duplicate(true)
	scene._show_report_history()
	var archive = scene.modal_frame.body.get_child(0)
	check(archive.reports.size() == 2 and int(archive.reports[archive.day_index].day) == 12, "历史页默认展示最近完成的一天")
	archive.previous_button.pressed.emit()
	check(archive.day_index == 0 and archive.day_picker.get_item_text(0).contains("第 11 天"), "历史页切到前一天")
	archive.tabs[1].pressed.emit()
	check(archive.graph.metric == 1 and archive.value.text.ends_with("%") and scene.sim.last_report == current, "切换趋势指标并保留实时报告")
	var archived_panel = archive.find_child("ArchivedReport", true, false)
	check(archived_panel.find_children("*", "Button", true, false).all(func(button): return not button.text.contains("定位") and not button.text.contains("夜晚")), "归档日报可浏览历史结算信息")
	await create_timer(.5).timeout
	await shot("report-history")
	scene._dismiss_modal()
	check(scene.modal_kind == "report", "从结算打开历史后可返回当日日报")
	scene._continue_night()
	scene._discard_fading_modal()
	scene._open_day()
	scene._show_report_history()
	var frozen = scene.sim.tick
	scene._process(.5)
	check(scene.sim.tick == frozen, "营业中翻阅历史时暂停模拟推进")
	scene._dismiss_modal()
	scene._process(.2)
	check(scene.sim.tick > frozen, "关闭历史后继续营业")
	scene.queue_free()
	await process_frame
	print("REPORT CAMERA RESULT: %d passed / %d failed" % [checks - failures, failures])
	quit(1 if failures else 0)
