class_name RunUnitStaticWorld
extends Node2D

@warning_ignore("unused_signal")
signal obstacle_triggered(obstacle_type: String, platform_id: int)
signal route_completed

const TILE_SIZE: float = 32.0
const SEMANTIC_EMPTY: int = 0
const SEMANTIC_SOLID: int = 1
const SEMANTIC_ONE_WAY: int = 2
const SEMANTIC_HAZARD: int = 3

const FALLBACK_SPAWN_POSITION: Vector2 = Vector2(128.0, 385.0)
const COMPLETION_TRIGGER_SIZE: Vector2 = Vector2(64.0, 128.0)
const CHECKPOINT_PREFIX: String = "Checkpoint"

@export var death_y: float = 900.0

var tile_size: float = TILE_SIZE
var _platforms: Array[Dictionary] = []
var _completion_triggered: bool = false
var _semantic_layer: TileMapLayer = null
var _spawn_marker: Marker2D = null
var _goal_marker: Marker2D = null
var _completion_trigger: Area2D = null
var _checkpoints: Array[Vector2] = []


func _ready() -> void:
	_semantic_layer = _find_layer(&"Semantic")
	if _semantic_layer == null:
		push_error("RunUnitStaticWorld: required 'Semantic' TileMapLayer is missing; the route will be empty.")
	_spawn_marker = _find_marker(&"Spawn")
	if _spawn_marker == null:
		push_warning("RunUnitStaticWorld: no 'Spawn' marker in the level; falling back to %s." % FALLBACK_SPAWN_POSITION)
	_goal_marker = _find_marker(&"Goal")
	_collect_checkpoints()
	_load_platforms_from_tilemap()
	_load_semantic_hazards_from_tilemap()
	_ensure_completion_trigger()


func set_level_profile(_level_index: int) -> void:
	pass


func reset(_run_seed: int = 0, _mode: String = "campaign") -> void:
	_completion_triggered = false
	propagate_call(&"reset_level_state")


func get_route_length() -> float:
	var route_end: float = 0.0
	for platform: Dictionary in _platforms:
		var platform_end: float = (float(platform.get("end_x", 0)) + 1.0) * tile_size
		route_end = maxf(route_end, platform_end)
	return route_end / tile_size


func get_traversal_length() -> float:
	if has_goal():
		return absf(get_goal_position().x - get_spawn_position().x) / tile_size
	return maxf(get_route_length() - to_local(get_spawn_position()).x / tile_size, 0.0)


func is_completion_triggered() -> bool:
	return _completion_triggered


func get_spawn_position() -> Vector2:
	if _spawn_marker == null:
		return FALLBACK_SPAWN_POSITION
	return _spawn_marker.global_position


func get_checkpoint_positions() -> Array[Vector2]:
	return _checkpoints.duplicate()


func _collect_checkpoints() -> void:
	_checkpoints.clear()
	var pending: Array[Node] = [self]
	while not pending.is_empty():
		var node: Node = pending.pop_back()
		pending.append_array(node.get_children())
		if node is Marker2D and String(node.name).begins_with(CHECKPOINT_PREFIX):
			_checkpoints.append((node as Marker2D).global_position)
	_checkpoints.sort_custom(func(a: Vector2, b: Vector2) -> bool: return a.x < b.x)


func has_goal() -> bool:
	return _goal_marker != null


func get_goal_position() -> Vector2:
	if _goal_marker == null:
		return Vector2.ZERO
	return _goal_marker.global_position


func _ensure_completion_trigger() -> void:
	_completion_trigger = get_node_or_null("CompletionTrigger") as Area2D
	if _completion_trigger == null and has_goal():
		var trigger: Area2D = Area2D.new()
		trigger.name = "CompletionTrigger"
		trigger.position = to_local(get_goal_position())
		trigger.collision_layer = 0
		trigger.collision_mask = 1
		var shape: CollisionShape2D = CollisionShape2D.new()
		var rectangle: RectangleShape2D = RectangleShape2D.new()
		rectangle.size = COMPLETION_TRIGGER_SIZE
		shape.shape = rectangle
		trigger.add_child(shape)
		add_child(trigger)
		_completion_trigger = trigger
	if _completion_trigger != null and not _completion_trigger.body_entered.is_connected(_on_completion_trigger_body_entered):
		_completion_trigger.body_entered.connect(_on_completion_trigger_body_entered)


func _find_layer(layer_name: StringName) -> TileMapLayer:
	return _find_node_of_type(self, layer_name, "TileMapLayer") as TileMapLayer


func _find_marker(marker_name: StringName) -> Marker2D:
	return _find_node_of_type(self, marker_name, "Marker2D") as Marker2D


func _find_node_of_type(node: Node, wanted_name: StringName, wanted_class: String) -> Node:
	for child: Node in node.get_children():
		if child.name == wanted_name and child.is_class(wanted_class):
			return child
		var found: Node = _find_node_of_type(child, wanted_name, wanted_class)
		if found != null:
			return found
	return null


func _cell_semantic(cell: Vector2i) -> int:
	var data: TileData = _semantic_layer.get_cell_tile_data(cell)
	if data == null:
		return SEMANTIC_EMPTY
	return int(data.get_custom_data("semantic"))


# The TileMap is just the level plan here; build the usable platform runs when the scene loads.
func _load_platforms_from_tilemap() -> void:
	_platforms.clear()
	if _semantic_layer == null:
		return

	var rows: Dictionary = {}
	for cell: Vector2i in _semantic_layer.get_used_cells():
		var value: int = _cell_semantic(cell)
		if value != SEMANTIC_SOLID and value != SEMANTIC_ONE_WAY:
			continue
		var above: int = _cell_semantic(Vector2i(cell.x, cell.y - 1))
		if above == SEMANTIC_SOLID or above == SEMANTIC_ONE_WAY:
			continue
		if not rows.has(cell.y):
			rows[cell.y] = [] as Array[Dictionary]
		(rows[cell.y] as Array[Dictionary]).append({"x": cell.x, "value": value})

	var found: Array[Dictionary] = []
	var row_keys: Array = rows.keys()
	row_keys.sort()
	for y: int in row_keys:
		var entries: Array[Dictionary] = rows[y]
		entries.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return int(a["x"]) < int(b["x"]))
		var i: int = 0
		while i < entries.size():
			var start_x: int = int(entries[i]["x"])
			var value: int = int(entries[i]["value"])
			var end_x: int = start_x
			var j: int = i + 1
			while j < entries.size() and int(entries[j]["x"]) == end_x + 1 and int(entries[j]["value"]) == value:
				end_x = int(entries[j]["x"])
				j += 1
			found.append({
				"platform_id": 0,
				"start_x": start_x,
				"end_x": end_x,
				"height": y,
				"width": end_x - start_x + 1,
				"challenge_type": "Authored",
				"surface_type": "solid" if value == SEMANTIC_SOLID else "one_way",
				"gap_before": 0,
				"obstacle_x": -1,
				"obstacle_type": "",
				"hazard_x": -1,
				"collectible": false,
			})
			i = j

	found.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return int(a["start_x"]) < int(b["start_x"]))
	for index: int in range(found.size()):
		found[index]["platform_id"] = index + 1
	_platforms = found


func _load_semantic_hazards_from_tilemap() -> void:
	if _semantic_layer == null:
		return

	var existing: Node = get_node_or_null("SemanticHazards")
	if existing != null:
		existing.free()

	var container: Node2D = Node2D.new()
	container.name = "SemanticHazards"
	add_child(container)
	container.global_transform = _semantic_layer.global_transform

	var rows: Dictionary = {}
	for cell: Vector2i in _semantic_layer.get_used_cells():
		if _cell_semantic(cell) != SEMANTIC_HAZARD:
			continue
		if not rows.has(cell.y):
			rows[cell.y] = []
		var x_values: Array = rows[cell.y]
		x_values.append(cell.x)

	var row_keys: Array = rows.keys()
	row_keys.sort()
	for y: int in row_keys:
		var x_values: Array = rows[y]
		x_values.sort()
		if x_values.is_empty():
			continue
		var start_x: int = int(x_values[0])
		var end_x: int = start_x
		for index: int in range(1, x_values.size()):
			var next_x: int = int(x_values[index])
			if next_x == end_x + 1:
				end_x = next_x
				continue
			_create_semantic_hazard_run(container, y, start_x, end_x)
			start_x = next_x
			end_x = next_x
		_create_semantic_hazard_run(container, y, start_x, end_x)


func _create_semantic_hazard_run(container: Node2D, y: int, start_x: int, end_x: int) -> void:
	var hazard: RunUnitHazardArea = RunUnitHazardArea.new()
	hazard.name = "Hazard_%d_%d_%d" % [y, start_x, end_x]
	hazard.lethal = true
	hazard.collision_layer = 0
	hazard.collision_mask = 1

	var collision: CollisionShape2D = CollisionShape2D.new()
	collision.name = "CollisionShape2D"
	var rectangle: RectangleShape2D = RectangleShape2D.new()
	var layer_tile_size: Vector2i = _semantic_layer.tile_set.tile_size
	rectangle.size = Vector2(float((end_x - start_x + 1) * layer_tile_size.x), float(layer_tile_size.y))
	collision.shape = rectangle
	hazard.add_child(collision)

	var first_center: Vector2 = _semantic_layer.map_to_local(Vector2i(start_x, y))
	var last_center: Vector2 = _semantic_layer.map_to_local(Vector2i(end_x, y))
	hazard.position = (first_center + last_center) * 0.5
	container.add_child(hazard)


func _on_completion_trigger_body_entered(body: Node2D) -> void:
	if _completion_triggered or not body is RunUnitPlayerMotor:
		return
	_completion_triggered = true
	route_completed.emit()
