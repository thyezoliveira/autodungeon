class_name PartyNavigationWorld
extends Node3D

@onready var party_controller: PartyFormationController = $PartyFormationController
@onready var waypoints_holder: Node3D = $WaypointsHolder
@onready var camera_rig: IsometricCameraRig = $IsometricCameraRig

var _waypoints: Array[Vector3] = []
var _current_wp_idx: int = 0


func _ready() -> void:
	if waypoints_holder != null:
		for child in waypoints_holder.get_children():
			if child is Marker3D or child is Node3D:
				_waypoints.append(child.global_position)

	# Se houver waypoints, ativa a marcha do líder
	if not _waypoints.is_empty() and party_controller != null:
		_current_wp_idx = 1 if _waypoints.size() > 1 else 0
		var leader: CharacterEntity = party_controller.get_leader()
		if leader != null and leader.movement_component != null:
			leader.movement_component.move_towards(_waypoints[_current_wp_idx])
			if leader.state_machine != null:
				leader.state_machine.change_state("MarchState")


func _physics_process(_delta: float) -> void:
	if _waypoints.is_empty() or party_controller == null:
		return

	var leader: CharacterEntity = party_controller.get_leader()
	if leader == null or leader.health_component == null or not leader.health_component.is_alive:
		return

	var target_pos: Vector3 = _waypoints[_current_wp_idx]
	var leader_pos: Vector3 = leader.global_position
	var dist_planar: float = Vector2(leader_pos.x - target_pos.x, leader_pos.z - target_pos.z).length()

	if dist_planar <= 0.6:
		# Avança para o próximo waypoint em loop contínuo
		_current_wp_idx = (_current_wp_idx + 1) % _waypoints.size()
		leader.movement_component.move_towards(_waypoints[_current_wp_idx])
