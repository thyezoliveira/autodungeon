class_name PartyNavigationWorld
extends Node3D

## Controlador de travessia autônoma do trio pela masmorra.
## Conduz o grupo pelos Waypoints ordenados, emite target_reached e room_cleared ao chegar no destino final,
## e finaliza a marcha no IdleState sem loops indesejados.

signal party_traversal_started()
signal party_traversal_completed()

@export var auto_start_march: bool = true
@export var loop_waypoints: bool = false

@onready var party_controller: PartyFormationController = $PartyFormationController
@onready var waypoints_holder: Node3D = $WaypointsHolder
@onready var camera_rig: IsometricCameraRig = $IsometricCameraRig

var _waypoints: Array[Vector3] = []
var _current_wp_idx: int = 0
var _leader_connected: CharacterEntity = null
var _traversal_finished: bool = false


func _ready() -> void:
	_collect_waypoints()
	if auto_start_march:
		# Aguarda um frame para que nós filhos e NavigationAgent3D inicializem completamente
		call_deferred("_start_traversal")


func _collect_waypoints() -> void:
	_waypoints.clear()
	if waypoints_holder != null:
		for child in waypoints_holder.get_children():
			if child is Marker3D or child is Node3D:
				_waypoints.append(child.global_position)


func _start_traversal() -> void:
	if _waypoints.is_empty() or party_controller == null:
		return

	_traversal_finished = false
	var leader: CharacterEntity = party_controller.get_leader()
	if leader == null:
		return

	_bind_leader_signals(leader)

	# Se houver mais de 1 waypoint, inicia rumo ao waypoint 1 (o 0 é o ponto de partida)
	_current_wp_idx = 1 if _waypoints.size() > 1 else 0
	party_traversal_started.emit()

	if leader.movement_component != null:
		leader.movement_component.move_towards(_waypoints[_current_wp_idx])
		if leader.state_machine != null:
			leader.state_machine.change_state("MarchState")


func _bind_leader_signals(leader: CharacterEntity) -> void:
	if _leader_connected != null and is_instance_valid(_leader_connected):
		if _leader_connected.movement_component != null and _leader_connected.movement_component.target_reached.is_connected(_on_leader_target_reached):
			_leader_connected.movement_component.target_reached.disconnect(_on_leader_target_reached)

	_leader_connected = leader
	if leader != null and leader.movement_component != null:
		if not leader.movement_component.target_reached.is_connected(_on_leader_target_reached):
			leader.movement_component.target_reached.connect(_on_leader_target_reached)


func _physics_process(_delta: float) -> void:
	if _traversal_finished or _waypoints.is_empty() or party_controller == null:
		return

	var leader: CharacterEntity = party_controller.get_leader()
	if leader == null or leader.health_component == null or not leader.health_component.is_alive:
		return

	# Garante que o líder atual esteja conectado caso ocorra reajuste por morte
	if leader != _leader_connected:
		_bind_leader_signals(leader)

	# Verificação de proximidade para avanço suave entre waypoints
	var target_pos: Vector3 = _waypoints[_current_wp_idx]
	var leader_pos: Vector3 = leader.global_position
	var dist_planar: float = Vector2(leader_pos.x - target_pos.x, leader_pos.z - target_pos.z).length()

	# Se estiver dentro da margem de chegada do waypoint intermediário
	if dist_planar <= 0.6:
		_advance_to_next_waypoint()


func _advance_to_next_waypoint() -> void:
	if _traversal_finished:
		return

	var leader: CharacterEntity = party_controller.get_leader()
	if leader == null:
		return

	# Se ainda há waypoints intermediários pela frente
	if _current_wp_idx < _waypoints.size() - 1:
		_current_wp_idx += 1
		if leader.movement_component != null:
			leader.movement_component.move_towards(_waypoints[_current_wp_idx])
	else:
		# Chegou ao destino final do percurso!
		if loop_waypoints:
			_current_wp_idx = 0
			if leader.movement_component != null:
				leader.movement_component.move_towards(_waypoints[_current_wp_idx])
		else:
			_complete_traversal()


func _on_leader_target_reached() -> void:
	_advance_to_next_waypoint()


func _complete_traversal() -> void:
	if _traversal_finished:
		return
	_traversal_finished = true

	# Coloca toda a equipe em postura de guarda / IdleState
	var all_heroes: Array[CharacterEntity] = party_controller.get_alive_heroes()
	for hero in all_heroes:
		if hero.movement_component != null:
			hero.movement_component.stop_movement()
		if hero.state_machine != null:
			hero.state_machine.change_state("IdleState")

	print("[PartyNavigationWorld] Destino final alcançado com sucesso! Emitindo sinais de conclusão.")
	party_traversal_completed.emit()

	# Emite os sinais globais de conclusão de masmorra e sala
	if EventBus != null:
		EventBus.room_cleared.emit(0)
