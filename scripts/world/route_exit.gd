class_name RunUnitRouteExit
extends Node2D

signal transition_finished

@export_file("*.tscn") var next_scene_path: String = ""

var transition_started: bool = false

func _ready() -> void:
	reset_transition()

func reset_transition() -> void:
	transition_started = false

func begin_transition() -> void:
	if transition_started:
		return
	transition_started = true
	finish_transition()

func finish_transition() -> void:
	transition_finished.emit()
	if next_scene_path.is_empty():
		return
	var scene_loader: Node = get_node_or_null("/root/SceneLoader")
	if scene_loader != null and scene_loader.has_method("load_scene"):
		scene_loader.call("load_scene", next_scene_path)
	else:
		get_tree().change_scene_to_file(next_scene_path)
