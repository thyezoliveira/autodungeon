class_name IsometricCameraRig
extends Node3D

@export var target: Node3D = null
@export var follow_speed: float = 5.0
@export var camera_offset: Vector3 = Vector3(0.0, 15.0, 15.0)
@export var party_controller: PartyFormationController = null


func _ready() -> void:
	_setup_party_controller_listener()
	if target != null and is_instance_valid(target):
		global_position = _get_target_desired_position()
	elif global_position == Vector3.ZERO:
		global_position = camera_offset


func _setup_party_controller_listener() -> void:
	if party_controller == null:
		if get_parent() != null:
			party_controller = get_parent().get_node_or_null("PartyFormationController") as PartyFormationController
		if party_controller == null and owner != null:
			party_controller = owner.get_node_or_null("PartyFormationController") as PartyFormationController

	if party_controller != null and not party_controller.leader_changed.is_connected(set_target):
		party_controller.leader_changed.connect(set_target)


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

