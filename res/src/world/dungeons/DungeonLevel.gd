class_name DungeonLevel
extends Node3D

## Controlador central do nível de masmorra 3D (Graybox Dungeon).
## Gerencia a arquitetura de salas e corredores, o NavigationRegion3D, os Spawners de heróis/inimigos,
## os controladores de encontro (EncounterControllers) e os waypoints de travessia autônoma.

signal dungeon_started()
signal party_spawned(leader: CharacterEntity)
signal room_entered(room_index: int, room_name: String)
signal room_cleared(room_index: int)
signal dungeon_completed()

@export var auto_spawn_party: bool = true
@export var auto_start_traversal: bool = false

@export_group("Internal References")
@export var navigation_region: NavigationRegion3D = null
@export var architecture: StaticBody3D = null
@export var party_controller: PartyFormationController = null
@export var camera_rig: IsometricCameraRig = null
@export var spawners_holder: Node3D = null
@export var encounter_controllers_holder: Node3D = null
@export var waypoints_holder: Node3D = null

var _cached_waypoints: Array[Vector3] = []


func _ready() -> void:
	_resolve_references()
	_collect_waypoints()
	_connect_event_bus()

	if auto_spawn_party:
		call_deferred("initialize_party_at_spawn")


func _exit_tree() -> void:
	_disconnect_event_bus()


## Resolve referências internas procurando na árvore de nós se não tiverem sido exportadas.
func _resolve_references() -> void:
	if navigation_region == null:
		navigation_region = get_node_or_null("NavigationRegion3D") as NavigationRegion3D

	if architecture == null and navigation_region != null:
		architecture = navigation_region.get_node_or_null("Architecture") as StaticBody3D
	if architecture == null:
		architecture = get_node_or_null("Architecture") as StaticBody3D

	if party_controller == null:
		party_controller = get_node_or_null("PartyFormationController") as PartyFormationController

	if camera_rig == null:
		camera_rig = get_node_or_null("IsometricCameraRig") as IsometricCameraRig

	if spawners_holder == null:
		spawners_holder = get_node_or_null("Spawners") as Node3D

	if encounter_controllers_holder == null:
		encounter_controllers_holder = get_node_or_null("EncounterControllers") as Node3D

	if waypoints_holder == null:
		waypoints_holder = get_node_or_null("WaypointsHolder") as Node3D
		if waypoints_holder == null:
			waypoints_holder = get_node_or_null("Waypoints") as Node3D


## Conecta os sinais globais do EventBus para rastreamento de salas.
func _connect_event_bus() -> void:
	var bus: EventBusSingleton = _get_event_bus()
	if bus != null:
		if not bus.room_entered.is_connected(_on_event_bus_room_entered):
			bus.room_entered.connect(_on_event_bus_room_entered)
		if not bus.room_cleared.is_connected(_on_event_bus_room_cleared):
			bus.room_cleared.connect(_on_event_bus_room_cleared)


func _disconnect_event_bus() -> void:
	var bus: EventBusSingleton = _get_event_bus()
	if bus != null:
		if bus.room_entered.is_connected(_on_event_bus_room_entered):
			bus.room_entered.disconnect(_on_event_bus_room_entered)
		if bus.room_cleared.is_connected(_on_event_bus_room_cleared):
			bus.room_cleared.disconnect(_on_event_bus_room_cleared)


func _on_event_bus_room_entered(r_idx: int, r_name: String) -> void:
	room_entered.emit(r_idx, r_name)


func _on_event_bus_room_cleared(r_idx: int) -> void:
	room_cleared.emit(r_idx)


func _get_event_bus() -> EventBusSingleton:
	var tree: SceneTree = Engine.get_main_loop() as SceneTree
	if tree != null and tree.root != null and tree.root.has_node("EventBus"):
		return tree.root.get_node("EventBus") as EventBusSingleton
	return null


## Coleta todos os waypoints registrados em waypoints_holder.
func _collect_waypoints() -> void:
	_cached_waypoints.clear()
	if waypoints_holder != null:
		for child in waypoints_holder.get_children():
			if child is Marker3D or child is Node3D:
				_cached_waypoints.append(child.global_position)


## Retorna o ponto global do SpawnPoint da Party.
func get_spawn_point() -> Vector3:
	var marker: Marker3D = get_party_spawn_marker()
	if marker != null:
		return marker.global_position
	return global_position


## Retorna o Marker3D de spawn da Party.
func get_party_spawn_marker() -> Marker3D:
	if spawners_holder != null:
		var p_spawn: Marker3D = spawners_holder.get_node_or_null("PartySpawnPoint") as Marker3D
		if p_spawn != null:
			return p_spawn
	return null


## Inicializa a posição do trio de heróis no ponto de spawn da masmorra.
func initialize_party_at_spawn() -> void:
	if party_controller == null:
		return

	var spawn_pos: Vector3 = get_spawn_point()
	var leader: CharacterEntity = party_controller.get_leader()
	var support: CharacterEntity = party_controller.get_support()
	var dps: CharacterEntity = party_controller.get_dps()

	if leader != null and is_instance_valid(leader):
		leader.global_position = spawn_pos
		if leader.movement_component != null:
			leader.movement_component.stop_movement()

	if support != null and is_instance_valid(support):
		var supp_offset: Vector3 = party_controller.support_offset
		support.global_position = spawn_pos + supp_offset
		if support.movement_component != null:
			support.movement_component.stop_movement()

	if dps != null and is_instance_valid(dps):
		var d_offset: Vector3 = party_controller.dps_offset
		dps.global_position = spawn_pos + d_offset
		if dps.movement_component != null:
			dps.movement_component.stop_movement()

	if camera_rig != null and is_instance_valid(camera_rig) and leader != null:
		camera_rig.set_target(leader)
		camera_rig.global_position = Vector3(spawn_pos.x, 0.0, spawn_pos.z) + camera_rig.camera_offset

	party_spawned.emit(leader)


## Retorna o nó de uma sala específica dentro de Architecture pelo nome.
func get_room(room_name: String) -> Node3D:
	if architecture != null:
		return architecture.get_node_or_null(room_name) as Node3D
	return null


## Retorna a lista de todas as salas presentes na geometria.
func get_rooms() -> Array[Node3D]:
	var rooms: Array[Node3D] = []
	if architecture != null:
		for child in architecture.get_children():
			if child.name.begins_with("Room") or child.name.begins_with("Arena"):
				rooms.append(child)
	return rooms


## Retorna a lista de todos os corredores presentes na geometria.
func get_corridors() -> Array[Node3D]:
	var corridors: Array[Node3D] = []
	if architecture != null:
		for child in architecture.get_children():
			if child.name.begins_with("Corridor"):
				corridors.append(child)
	return corridors


## Retorna os Marker3D de inimigos para uma determinada sala.
func get_enemy_spawners_for_room(room_index: int) -> Array[Marker3D]:
	var spawners: Array[Marker3D] = []
	if spawners_holder == null:
		return spawners

	var pack_name: String = ""
	match room_index:
		1:
			pack_name = "Room1_EnemyPack"
		2:
			pack_name = "Room2_MiniBossPack"
		3:
			pack_name = "Arena3_BossPack"

	if not pack_name.is_empty():
		var pack_node: Node3D = spawners_holder.get_node_or_null(pack_name) as Node3D
		if pack_node != null:
			for child in pack_node.get_children():
				if child is Marker3D:
					spawners.append(child)

	return spawners


## Retorna o controlador de encontro da sala informada.
func get_encounter_controller(room_index: int) -> Node:
	if encounter_controllers_holder == null:
		return null
	var node_name: String = "Room%d_Controller" % room_index
	return encounter_controllers_holder.get_node_or_null(node_name)


## Retorna todos os waypoints (coordenadas Vector3) da masmorra.
func get_waypoints() -> Array[Vector3]:
	if _cached_waypoints.is_empty():
		_collect_waypoints()
	return _cached_waypoints


## Retorna todos os nós Marker3D de waypoint.
func get_waypoint_markers() -> Array[Marker3D]:
	var markers: Array[Marker3D] = []
	if waypoints_holder != null:
		for child in waypoints_holder.get_children():
			if child is Marker3D:
				markers.append(child)
	return markers


## Retorna a NavigationRegion3D da masmorra.
func get_navigation_region() -> NavigationRegion3D:
	return navigation_region


## Retorna o nó StaticBody3D Architecture.
func get_architecture() -> StaticBody3D:
	return architecture
