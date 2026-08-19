class_name IsometricCameraRig
extends Node3D

@export var target: Node3D = null
@export var follow_speed: float = 5.0
@export var camera_offset: Vector3 = Vector3(0.0, 15.0, 15.0)


func _ready() -> void:
	if target != null and is_instance_valid(target):
		global_position = _get_target_desired_position()
	elif global_position == Vector3.ZERO:
		global_position = camera_offset


func _physics_process(delta: float) -> void:
	if target == null or not is_instance_valid(target):
		return

	var desired_position: Vector3 = _get_target_desired_position()
	global_position = global_position.lerp(desired_position, clampf(follow_speed * delta, 0.0, 1.0))


func set_target(new_target: Node3D) -> void:
	target = new_target


func _get_target_desired_position() -> Vector3:
	if target == null or not is_instance_valid(target):
		return camera_offset
	return Vector3(target.global_position.x, 0.0, target.global_position.z) + camera_offset
