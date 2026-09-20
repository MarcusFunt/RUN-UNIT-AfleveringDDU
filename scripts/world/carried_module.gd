class_name RunUnitCarriedModule
extends Node2D

@onready var module_template: Node2D = $ModuleTemplate

var _mounted_module: Node2D = null


func _ready() -> void:
	module_template.visible = false
	reset_level_state()


func reset_level_state() -> void:
	RunUnitModuleMount.clear(_mounted_module)
	_mounted_module = null
	var player: RunUnitPlayerMotor = _find_player()
	if player != null:
		_mounted_module = RunUnitModuleMount.mount(player, module_template)


func get_mounted_module() -> Node2D:
	return _mounted_module if is_instance_valid(_mounted_module) else null


func stow() -> void:
	RunUnitModuleMount.clear(_mounted_module)
	_mounted_module = null


func _find_player() -> RunUnitPlayerMotor:
	var host: Node = get_parent()
	while host != null:
		for child: Node in host.get_children():
			if child is RunUnitPlayerMotor:
				return child as RunUnitPlayerMotor
		host = host.get_parent()
	return null
