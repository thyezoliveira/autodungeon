class_name IdleState
extends State


func enter() -> void:
	if actor != null:
		actor.velocity.x = 0.0
		actor.velocity.z = 0.0
		if actor.movement_component != null:
			actor.movement_component.stop_movement()


func physics_update(_delta: float) -> void:
	if actor != null:
		actor.velocity.x = 0.0
		actor.velocity.z = 0.0

