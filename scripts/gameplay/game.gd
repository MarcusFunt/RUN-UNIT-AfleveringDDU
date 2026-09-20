class_name RunUnitGame
extends Node2D

@onready var world: RunUnitStaticWorld = $World
@onready var player: RunUnitPlayerMotor = $Player
@onready var player_health: RunUnitPlayerHealth = $Player/Health
@onready var player_feedback: RunUnitPlayerFeedback = $Player/Feedback
@onready var human_controller: RunUnitHumanController = $HumanController
@onready var score_manager: RunUnitScoreManager = $ScoreManager
@onready var hud: RunUnitHud = $HUD
@onready var death_menu: RunUnitDeathMenu = $DeathMenu
@onready var route_exit: RunUnitRouteExit = _find_route_exit()

enum RunState { ACTIVE, FAILED, COMPLETED }

# Current run state for the selected route.
var _state: int = RunState.ACTIVE
var _level_index: int = 0
var _checkpoints: Array[Vector2] = []
var _next_checkpoint: int = 0

func _enter_tree() -> void:
	_level_index = RunUnitSession.selected_level_index
	if not RunUnitCampaign.is_available(_level_index):
		_level_index = 0
	var wanted_scene: String = RunUnitCampaign.get_world_scene(_level_index)
	var old_world: Node = get_node_or_null("World")
	if old_world == null or old_world.scene_file_path == wanted_scene:
		return
	var new_world: Node = (load(wanted_scene) as PackedScene).instantiate()
	new_world.name = "World"
	var old_index: int = old_world.get_index()
	remove_child(old_world)
	old_world.free()
	add_child(new_world)
	move_child(new_world, old_index)

func _ready() -> void:
	RunUnitSession.selected_level_index = _level_index
	world.set_level_profile(_level_index)
	world.obstacle_triggered.connect(_on_obstacle_triggered)
	world.route_completed.connect(_on_route_completed)
	player_health.damaged.connect(_on_player_damaged)
	player_health.depleted.connect(_on_player_depleted)
	hud.set_level_length(world.get_traversal_length())
	_checkpoints = world.get_checkpoint_positions()
	reset_run()

func _physics_process(_delta: float) -> void:
	if _state != RunState.ACTIVE:
		return
	var distance := score_manager.record_position(player.global_position.x)
	RunUnitSession.record_best_distance(score_manager.best_distance)
	_record_passed_checkpoints()
	hud.set_scores(distance, score_manager.best_distance)
	if player.global_position.y > world.death_y:
		_finish_run(RunState.FAILED)
func reset_run() -> void:
	_state = RunState.ACTIVE
	human_controller.active = true
	var spawn := world.get_spawn_position()
	var start := RunUnitSession.get_resume_position(_level_index, spawn)
	score_manager.reset(spawn.x, RunUnitSession.best_distance)
	world.reset(0)
	player.global_position = start
	_next_checkpoint = 0
	_record_passed_checkpoints()
	player.reset_motor()
	player_health.reset_health()
	player.set_physics_process(true)
	death_menu.close()
	if route_exit != null:
		route_exit.reset_transition()
	hud.set_scores(score_manager.distance, score_manager.best_distance)
	hud.set_health(player_health.current_health, player_health.max_health)

func _finish_run(result: int) -> void:
	if _state != RunState.ACTIVE:
		return
	_state = result
	human_controller.active = false
	player.set_physics_process(false)

	var distance := score_manager.record_position(player.global_position.x)
	RunUnitSession.record_best_distance(score_manager.best_distance)
	hud.set_scores(distance, score_manager.best_distance)

	if result == RunState.FAILED:
		player_feedback.play_game_over_feedback()
		death_menu.open_with_scores(distance, score_manager.best_distance)
		return
	RunUnitSession.clear_checkpoint()
	if route_exit != null:
		if not route_exit.transition_finished.is_connected(_on_route_exit_finished):
			route_exit.transition_finished.connect(_on_route_exit_finished)
		route_exit.begin_transition()
	else:
		death_menu.open_completed_with_scores(distance, score_manager.best_distance)

func _record_passed_checkpoints() -> void:
	while _next_checkpoint < _checkpoints.size():
		var checkpoint := _checkpoints[_next_checkpoint]
		if player.global_position.x < checkpoint.x:
			break
		RunUnitSession.record_checkpoint(_level_index, checkpoint)
		_next_checkpoint += 1

func _on_player_damaged(current_health: int, max_health: int) -> void:
	hud.set_health(current_health, max_health)
	player_feedback.play_damage_feedback()

func _on_player_depleted() -> void:
	_finish_run(RunState.FAILED)

func _on_obstacle_triggered(_obstacle_type: String, _platform_id: int) -> void:
	_finish_run(RunState.FAILED)

func _on_route_completed() -> void:
	_finish_run(RunState.COMPLETED)
func _on_route_exit_finished() -> void:
	if route_exit.next_scene_path.is_empty():
		death_menu.open_completed_with_scores(score_manager.distance, score_manager.best_distance)
	elif route_exit.next_scene_path == scene_file_path:
		RunUnitSession.selected_level_index = RunUnitCampaign.get_next_route_index(_level_index)

func _find_route_exit() -> RunUnitRouteExit:
	for child in world.get_children():
		if child is RunUnitRouteExit:
			return child
	return null
