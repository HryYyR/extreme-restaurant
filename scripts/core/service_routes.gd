extends RefCounted

const Grid = preload("res://scripts/core/layout.gd")

var area := Rect2i()
var blocked := {}
var fields := {}
var neighbors: Array[PackedInt32Array] = []

func prepare(layout: Dictionary, solid: Dictionary) -> void:
	area = Rect2i(0, 0, int(layout.width), int(layout.height))
	blocked = solid
	fields.clear()
	neighbors.resize(area.get_area())
	for index in range(neighbors.size()):
		var cell = _cell(index)
		var links := PackedInt32Array()
		if not blocked.has(cell):
			for direction in Grid.DIRECTIONS:
				var next = cell + direction
				if area.has_point(next) and not blocked.has(next):
					links.append(_index(next))
		neighbors[index] = links

func distance(origin: Vector2, destination: Vector2i) -> int:
	var start = Vector2i(origin.round())
	if not area.has_point(start): return 0
	return maxi(0, _field([destination])[_index(start)])

func path(origin: Vector2, destination: Vector2i) -> Array:
	return _route(origin, [destination], false).get("path", [])

func approach(origin: Vector2, targets: Array) -> Dictionary:
	return _route(origin, targets, true)

func _route(origin: Vector2, targets: Array, align_origin: bool) -> Dictionary:
	var rounded = origin.round()
	var start = Vector2i(rounded)
	if not area.has_point(start) or targets.is_empty(): return {}
	var distances = _field(targets)
	var cursor = _index(start)
	var remaining = distances[cursor]
	if remaining < 0: return {}
	var steps = []
	if align_origin and not origin.is_equal_approx(rounded):
		steps.append(rounded)
	# Following decreasing distances in Grid order preserves the same ties as
	# a forward breadth-first search, including access from multiple sides.
	while remaining > 0:
		remaining -= 1
		for neighbor in neighbors[cursor]:
			if distances[neighbor] == remaining:
				cursor = neighbor
				steps.append(Vector2(_cell(cursor)))
				break
	return {"path": steps, "target": Vector2(_cell(cursor))}

func _field(targets: Array) -> PackedInt32Array:
	var key: Variant = targets[0] if targets.size() == 1 else targets
	if fields.has(key): return fields[key]
	var distances := PackedInt32Array()
	distances.resize(neighbors.size())
	distances.fill(-1)
	var pending := PackedInt32Array()
	for cell in targets:
		if not area.has_point(cell) or blocked.has(cell): continue
		var index = _index(cell)
		if distances[index] == 0: continue
		distances[index] = 0
		pending.append(index)
	var head = 0
	while head < pending.size():
		var current = pending[head]
		head += 1
		var step = distances[current] + 1
		for neighbor in neighbors[current]:
			if distances[neighbor] != -1: continue
			distances[neighbor] = step
			pending.append(neighbor)
	fields[key] = distances
	return distances

func _index(cell: Vector2i) -> int:
	return cell.y * area.size.x + cell.x

@warning_ignore("integer_division")
func _cell(index: int) -> Vector2i:
	return Vector2i(index % area.size.x, index / area.size.x)
