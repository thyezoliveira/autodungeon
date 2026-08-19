class_name MovementComponent
extends Node

## Componente modular de movimentação 3D com suporte a NavigationAgent3D.
## Responsável pelo cálculo de vetores no plano XZ, interpolação de rotação e aplicação de velocidade física.

signal target_reached()
signal path_blocked()

@export var navigation_agent: NavigationAgent3D = null
@export var character_body: CharacterBody3D = null
@export var base_speed: float = 4.0
@export var rotation_speed: float = 10.0

var current_target_position: Vector3 = Vector3.ZERO
var speed_multiplier: float = 1.0
var is_moving: bool = false
var gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity", 9.8) as float


func _ready() -> void:
	_resolve_dependencies()
	_setup_navigation_agent()


func _resolve_dependencies() -> void:
	if character_body == null:
		if get_parent() is CharacterBody3D:
			character_body = get_parent() as CharacterBody3D
		elif get_parent() != null and get_parent().get_parent() is CharacterBody3D:
			character_body = get_parent().get_parent() as CharacterBody3D
		elif owner is CharacterBody3D:
			character_body = owner as CharacterBody3D

	if navigation_agent == null:
		if get_parent() != null:
			navigation_agent = get_parent().get_node_or_null("NavigationAgent3D") as NavigationAgent3D
			if navigation_agent == null and get_parent().get_parent() != null:
				navigation_agent = get_parent().get_parent().get_node_or_null("NavigationAgent3D") as NavigationAgent3D
				if navigation_agent == null:
					navigation_agent = get_parent().get_parent().get_node_or_null("Components/NavigationAgent3D") as NavigationAgent3D
		if navigation_agent == null and character_body != null:
			navigation_agent = character_body.get_node_or_null("NavigationAgent3D") as NavigationAgent3D
			if navigation_agent == null:
				navigation_agent = character_body.get_node_or_null("Components/NavigationAgent3D") as NavigationAgent3D

	if navigation_agent != null:
		_setup_navigation_agent()


func _setup_navigation_agent() -> void:
	if navigation_agent == null:
		return
	if navigation_agent.target_desired_distance <= 0.0:
		navigation_agent.target_desired_distance = 0.5
	if not navigation_agent.target_reached.is_connected(_on_nav_target_reached):
		navigation_agent.target_reached.connect(_on_nav_target_reached)
	if navigation_agent.has_signal("navigation_finished") and not navigation_agent.navigation_finished.is_connected(_on_nav_finished):
		navigation_agent.navigation_finished.connect(_on_nav_finished)


func move_towards(target_pos: Vector3) -> void:
	_resolve_dependencies()
	current_target_position = target_pos
	is_moving = true
	if navigation_agent != null:
		navigation_agent.target_position = target_pos


func process_movement(delta: float) -> void:
	_resolve_dependencies()
	if character_body == null:
		return

	# Aplica gravidade no eixo Y
	if not character_body.is_on_floor():
		character_body.velocity.y -= gravity * delta
	else:
		if character_body.velocity.y < 0.0:
			character_body.velocity.y = 0.0

	if not is_moving:
		character_body.velocity.x = 0.0
		character_body.velocity.z = 0.0
		character_body.move_and_slide()
		return

	var current_pos: Vector3 = character_body.global_position
	var desired_distance: float = 0.5
	if navigation_agent != null:
		desired_distance = navigation_agent.target_desired_distance

	# Distância no plano XZ até o alvo final
	var diff_to_final: Vector3 = Vector3(current_target_position.x - current_pos.x, 0.0, current_target_position.z - current_pos.z)
	var dist_to_final: float = diff_to_final.length()

	# Checagem de chegada ao alvo final
	if dist_to_final <= desired_distance:
		_on_target_reached()
		character_body.move_and_slide()
		return

	var next_waypoint: Vector3 = current_target_position
	if navigation_agent != null:
		if navigation_agent.is_navigation_finished():
			_on_target_reached()
			character_body.move_and_slide()
			return
		var next_nav_pos: Vector3 = navigation_agent.get_next_path_position()
		var nav_step_diff: Vector3 = Vector3(next_nav_pos.x - current_pos.x, 0.0, next_nav_pos.z - current_pos.z)
		if nav_step_diff.length_squared() > 0.0001:
			next_waypoint = next_nav_pos

	var move_diff: Vector3 = Vector3(next_waypoint.x - current_pos.x, 0.0, next_waypoint.z - current_pos.z)
	if move_diff.length_squared() < 0.0001:
		move_diff = diff_to_final

	if move_diff.length_squared() < 0.0001:
		_on_target_reached()
		character_body.move_and_slide()
		return

	var move_dir: Vector3 = move_diff.normalized()
	var effective_speed: float = base_speed * speed_multiplier

	character_body.velocity.x = move_dir.x * effective_speed
	character_body.velocity.z = move_dir.z * effective_speed

	# Rotação suave interpolada orientada ao vetor de movimento no plano XZ
	if move_dir.length_squared() > 0.001:
		var target_angle: float = atan2(move_dir.x, move_dir.z)
		character_body.rotation.y = lerp_angle(character_body.rotation.y, target_angle, clampf(rotation_speed * delta, 0.0, 1.0))

	character_body.move_and_slide()


func stop_movement() -> void:
	is_moving = false
	if character_body != null:
		character_body.velocity.x = 0.0
		character_body.velocity.z = 0.0


func set_speed_multiplier(mult: float) -> void:
	speed_multiplier = maxf(0.0, mult)


func _on_target_reached() -> void:
	if not is_moving:
		return
	is_moving = false
	stop_movement()
	target_reached.emit()


func _on_nav_target_reached() -> void:
	_on_target_reached()


func _on_nav_finished() -> void:
	if is_moving:
		_on_target_reached()
