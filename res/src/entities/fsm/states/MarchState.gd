class_name MarchState
extends State

@export var movement_component: MovementComponent = null


func enter() -> void:
	_resolve_movement_component()


func physics_update(delta: float) -> void:
	if movement_component == null:
		_resolve_movement_component()

	if movement_component != null:
		movement_component.process_movement(delta)


func exit() -> void:
	if movement_component != null:
		movement_component.stop_movement()


func _resolve_movement_component() -> void:
	if movement_component != null:
		return

	if actor != null:
		if actor.movement_component != null:
			movement_component = actor.movement_component
		elif actor.has_node("Components/MovementComponent"):
			movement_component = actor.get_node("Components/MovementComponent") as MovementComponent
		elif actor.has_node("MovementComponent"):
			movement_component = actor.get_node("MovementComponent") as MovementComponent

	if movement_component == null and state_machine != null:
		var parent: Node = state_machine.get_parent()
		if parent is CharacterEntity and parent.movement_component != null:
			movement_component = parent.movement_component
		elif parent != null and parent.has_node("Components/MovementComponent"):
			movement_component = parent.get_node("Components/MovementComponent") as MovementComponent
		elif parent != null and parent.has_node("MovementComponent"):
			movement_component = parent.get_node("MovementComponent") as MovementComponent
