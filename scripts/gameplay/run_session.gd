extends Node

var selected_level_index: int = 0
var _best_distances: Dictionary = {}

var checkpoint_level_index: int = -1
var checkpoint_position: Vector2 = Vector2.ZERO

var best_distance: float:
	get:
		return float(_best_distances.get(selected_level_index, 0.0))
	set(value):
		_best_distances[selected_level_index] = maxf(value, 0.0)

func record_best_distance(distance: float) -> void:
	best_distance = maxf(best_distance, distance)

func record_checkpoint(level_index: int, position: Vector2) -> void:
	checkpoint_level_index = level_index
	checkpoint_position = position

func has_checkpoint(level_index: int) -> bool:
	return checkpoint_level_index == level_index

func get_resume_position(level_index: int, spawn_position: Vector2) -> Vector2:
	if has_checkpoint(level_index):
		return checkpoint_position
	return spawn_position

func clear_checkpoint() -> void:
	checkpoint_level_index = -1
	checkpoint_position = Vector2.ZERO
