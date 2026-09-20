class_name RunUnitPlayerAction
extends RefCounted

var movement: float = 0.0
var jump_pressed: bool = false
var jump_held: bool = false
var jump_released: bool = false
var crouch_held: bool = false


func duplicate_action() -> RunUnitPlayerAction:
	var result: RunUnitPlayerAction = RunUnitPlayerAction.new()
	result.movement = movement
	result.jump_pressed = jump_pressed
	result.jump_held = jump_held
	result.jump_released = jump_released
	result.crouch_held = crouch_held
	return result
