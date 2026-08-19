class_name StateMachine
extends Node

signal state_changed(from_state: String, to_state: String)

@export var initial_state: State = null

var current_state: State = null
var _states: Dictionary = {}


func _ready() -> void:
	register_states()
	if initial_state != null:
		change_state(initial_state.name)


func _physics_process(delta: float) -> void:
	if current_state != null:
		current_state.physics_update(delta)


func _process(delta: float) -> void:
	if current_state != null:
		current_state.update(delta)


func change_state(new_state_name: String) -> void:
	var target_state: State = get_state(new_state_name)
	if target_state == null:
		push_error("StateMachine: Cannot change to state '%s' - state not found on %s." % [new_state_name, name])
		return

	if current_state == target_state:
		return

	var from_state_name: String = current_state.name if current_state != null else ""
	if current_state != null:
		current_state.exit()

	current_state = target_state
	current_state.enter()
	state_changed.emit(from_state_name, current_state.name)


func get_current_state_name() -> String:
	return current_state.name if current_state != null else ""


func has_state(state_name: String) -> bool:
	if state_name.is_empty():
		return false
	return _states.has(state_name) or _states.has(state_name.to_lower())


func get_state(state_name: String) -> State:
	if state_name.is_empty():
		return null
	if _states.has(state_name):
		return _states[state_name] as State
	if _states.has(state_name.to_lower()):
		return _states[state_name.to_lower()] as State
	return null


func register_state(state: State, custom_actor: CharacterEntity = null) -> void:
	if state == null:
		return
	var actor_to_set: CharacterEntity = custom_actor if custom_actor != null else _find_actor()
	_states[state.name] = state
	_states[state.name.to_lower()] = state
	state.state_machine = self
	if state.actor == null and actor_to_set != null:
		state.actor = actor_to_set


func register_states(custom_actor: CharacterEntity = null) -> void:
	_states.clear()
	var actor_to_set: CharacterEntity = custom_actor if custom_actor != null else _find_actor()
	for child in get_children():
		if child is State:
			register_state(child, actor_to_set)


func _find_actor() -> CharacterEntity:
	if owner is CharacterEntity:
		return owner as CharacterEntity
	var p: Node = get_parent()
	while p != null:
		if p is CharacterEntity:
			return p as CharacterEntity
		p = p.get_parent()
	return null
