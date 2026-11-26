extends SceneTree

const Sim = preload("res://scripts/core/simulation.gd")
const Grid = preload("res://scripts/core/layout.gd")
const Store = preload("res://scripts/core/save_store.gd")
var passed := 0
var failed := 0

func check(condition: bool, description: String) -> void:
	if condition:
		passed += 1
	else:
		failed += 1
		push_error(description)

func _initialize() -> void:
	call_deferred("run")

func preview(name: String) -> void:
	if DisplayServer.get_name() == "headless": return
	await RenderingServer.frame_post_draw
	var filename = "res://.local/%s-%dx%d.png" % [name, root.size.x, root.size.y]
	check(root.get_texture().get_image().save_png(filename) == OK, "生成街区截图 " + name)

func _render_image() -> Image:
	await process_frame
	await RenderingServer.frame_post_draw
	return root.get_texture().get_image()

func _layer_draws_at(visible: Image, hidden: Image, at: Vector2i) -> bool:
	var sample := Rect2i(at - Vector2i(5, 5), Vector2i(11, 11))
	if not Rect2i(Vector2i.ZERO, visible.get_size()).encloses(sample): return false
	var changed = 0
	for y in range(sample.position.y, sample.end.y):
		for x in range(sample.position.x, sample.end.x):
			if visible.get_pixel(x, y) != hidden.get_pixel(x, y): changed += 1
	return changed > 55

func _check_zoomed_map(world) -> void:
	if DisplayServer.get_name() == "headless": return
	world.focus_restaurant()
	world.set_process(false)
	var zoom_in := InputEventMouseButton.new()
	zoom_in.button_index = MOUSE_BUTTON_WHEEL_UP
	zoom_in.pressed = true
	for step in range(8): world._gui_input(zoom_in)
	check(is_equal_approx(world.zoom, 1.8), "滚轮放大到镜头上限")
	var press := InputEventMouseButton.new()
	press.button_index = MOUSE_BUTTON_RIGHT
	press.pressed = true
	world._gui_input(press)
	var drag := InputEventMouseMotion.new()
	drag.position = world.size * .5
	drag.button_mask = MOUSE_BUTTON_MASK_RIGHT
	var views = [
		[Vector2(.30, -.08), Vector2(1.25, 7.4), Vector2(-4.8, 6.65)],
		[Vector2(-.33, -.26), Vector2(10.25, 7.4), Vector2(32.8, 6.65)],
		[Vector2(1.03, .19), null, Vector2(-4.8, 6.65)],
		[Vector2(.40, 1.08), null, Vector2(-4.8, -5.36)],
		[Vector2(.28, -.29), Vector2(1.25, 9.4), Vector2(-4.8, 10.65)],
	]
	for view in views:
		drag.relative = world.size * Vector2(view[0]) - world._origin()
		world._gui_input(drag)
		world._process(0.0)
		var draw_origin: Vector2 = world._origin()
		var unit: float = world._unit()
		var with_map = await _render_image()
		world.floor_canvas.hide()
		world.street_canvas.hide()
		var without_map = await _render_image()
		world.street_canvas.show()
		world.floor_canvas.show()
		if view[1] != null:
			check(_layer_draws_at(with_map, without_map, Vector2i(draw_origin + Vector2(view[1]) * unit)), "拖动后可见的餐厅地板仍有像素")
		check(_layer_draws_at(with_map, without_map, Vector2i(draw_origin + Vector2(view[2]) * unit)), "拖动后可见的街道仍有像素")
	press.pressed = false
	world._gui_input(press)
	world.focus_restaurant()
	world.set_process(true)

func run() -> void:
	if "--ui-test" not in OS.get_cmdline_user_args():
		quit(1)
		return
	Store.write_checkpoint(Sim.new().export_state(), Store.default_path("street_corner", true))
	var game = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	await process_frame
	# The fixture advances simulation ticks itself.
	root.focus_exited.disconnect(game._on_focus_lost)
	game.guide.skip()
	game.set_process(false)
	var world = game.world
	world._process(.05)
	var street = world.street
	var buildings = street.buildings
	var silhouettes = {}
	for lot in buildings: silhouettes[lot.kind] = true
	check(buildings.size() >= 20 and silhouettes.size() >= 4 and buildings.all(func(b): return street.bounds.encloses(b.box)), "实体街区使用多种屋顶和成组地块，店铺都在地图内")
	check(world.city_geometry.get_child_count() == buildings.size(), "每栋外景建筑与自己的阴影相连")
	game.ui.district.pressed.emit()
	world._process(.05)
	var district = Rect2(world._origin() + street.bounds.position * world._unit(), street.bounds.size * world._unit())
	check(Rect2(Vector2.ZERO, world.size).encloses(district.grow(8)), "街区全景能看到有限地图的四边和余量")
	await preview("district-night")
	world.focus_restaurant()
	world._process(.05)
	await preview("district-frontage")
	await _check_zoomed_map(world)
	game._open_day()
	var sim = game.sim
	var arrival_tick = 790
	sim.arrival_plan = [{"id": 1, "type": "normal", "tick": arrival_tick}]
	var entrance = Grid.vec(sim.layout.entrance)
	var portal = street.gate_route(0, entrance)
	check(portal.x < street.bounds.position.x - .4 and street.threshold_alpha(portal) == 0.0 and street.gate_route(1, entrance).is_equal_approx(entrance), "入场路径从铺装端点外延伸到餐厅入口")
	while sim.tick < arrival_tick - 45: sim.step()
	game.ui.district.pressed.emit()
	game._update_hud()
	world._process(1.4)
	var approach = Vector2(world.actor_cells["g_1"])
	check(approach.x < -4.0 and approach.x > portal.x and sim.customers.is_empty(), "营业客人沿接入道走来，到店结算使用原计划时刻")
	var before_pan = world.actors["g_1"].position
	world.camera_pan += Vector2(190, -55)
	world._sync_actors()
	check(world.actor_cells["g_1"] == approach and world.actors["g_1"].position.is_equal_approx(before_pan + Vector2(190, -55)), "平移视图不会改变客人的街道坐标")
	world.focus_district()
	world._process(0.0)
	await preview("district-day")
	world.focus_restaurant()
	world.camera_pan = Vector2(225, -18)
	world._process(0.0)
	await preview("district-day-detail")
	world.focus_district()
	while sim.tick < arrival_tick: sim.step()
	world._sync_actors()
	check(sim.stats.arrived == 1 and sim.customers.has(1) and world.actors.has("g_1"), "街区步行动画与到店客户只交接一次")
	var last = Vector2.ZERO
	while sim.phase == "DAY" and sim.tick < sim.day_ticks:
		sim.step()
		if not sim.active_customers.has(1): break
		if sim.customers[1].state == "EXITING":
			world._sync_actors()
			last = world.actor_cells["g_1"]
	world._sync_actors()
	check(last.x < street.bounds.position.x + .28 and not world.actors.has("g_1") and sim.stats.completed == 1, "离店客人走回地图断面，随后淡出并从场景移除")
	check(sim.invariant_errors().is_empty(), "街区动画未改变经营结果")
	game.queue_free()
	await process_frame
	print("DISTRICT RESULT: %d passed / %d failed" % [passed, failed])
	quit(1 if failed else 0)
