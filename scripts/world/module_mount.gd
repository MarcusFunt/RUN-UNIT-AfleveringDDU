class_name RunUnitModuleMount
extends RefCounted

const MOUNT_PARENT: String = "RobotVisual/BodyPivot"
const MOUNT_NAME: StringName = &"MountedModule"
const MOUNT_OFFSET: Vector2 = Vector2(165.0, -30.0)
const MOUNT_SCALE: float = 4.4
const FALLBACK_OFFSET: Vector2 = Vector2(0.0, -40.0)

static func mount(player: RunUnitPlayerMotor, template: Node2D) -> Node2D:
	if player == null or template == null:
		return null
	var module: Node2D = template.duplicate() as Node2D
	module.name = MOUNT_NAME
	module.visible = true
	module.z_index = -1
	var mount_parent: Node2D = player.get_node_or_null(MOUNT_PARENT) as Node2D
	if mount_parent == null:
		mount_parent = player
		module.position = FALLBACK_OFFSET
		module.scale = Vector2.ONE
	else:
		module.position = MOUNT_OFFSET
		module.scale = Vector2.ONE * MOUNT_SCALE
	mount_parent.add_child(module)
	return module

static func clear(module: Node2D) -> void:
	if not is_instance_valid(module):
		return
	module.get_parent().remove_child(module)
	module.free()
