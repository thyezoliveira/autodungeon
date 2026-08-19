class_name PartyCombatWorld
extends Node3D

## Controlador de Mundo de Combate Integrado 3D (M4.7)
## Gerencia o percurso autônomo do trio de heróis, a colisão física inicial com o pack de monstros,
## o engajamento tático coordenado das IAs dos 3 heróis (Bromm/Tanque, Elysia/DPS, Beatrice/Suporte),
## o gerenciamento de aggro via ThreatTable e a retomada fluida da marcha após a vitória.

signal party_traversal_started()
signal combat_started(initiator: Node3D, target: Node3D)
signal combat_ended()
signal party_traversal_completed()

@export var auto_start_march: bool = true
@export var loop_waypoints: bool = false
@export var party_controller: PartyFormationController = null
@export var combat_trigger_system: CombatTriggerSystem = null
@export var waypoints_holder: Node3D = null
@export var enemies_holder: Node3D = null
@export var camera_rig: IsometricCameraRig = null

var enemy_pack: Array[CharacterEntity] = []
var tank_ai: TankAIController = null
var dps_ai: RangedDPSAIController = null
var support_ai: SupportAIController = null

var _waypoints: Array[Vector3] = []
var _current_wp_idx: int = 0
var _leader_connected: CharacterEntity = null
var _traversal_finished: bool = false
var _in_combat: bool = false
var _enemy_attack_cooldowns: Dictionary = {} # Chave: CharacterEntity, Valor: float


func _ready() -> void:
	_resolve_scene_nodes()
	_collect_waypoints()
	_collect_and_register_enemies()
	_resolve_hero_ai_controllers()
	_setup_combat_trigger_listeners()

	if auto_start_march:
		call_deferred("_start_traversal")


func _resolve_scene_nodes() -> void:
	if party_controller == null:
		party_controller = get_node_or_null("PartyFormationController") as PartyFormationController
	if combat_trigger_system == null:
		combat_trigger_system = get_node_or_null("CombatTriggerSystem") as CombatTriggerSystem
	if waypoints_holder == null:
		waypoints_holder = get_node_or_null("WaypointsHolder") as Node3D
	if enemies_holder == null:
		enemies_holder = get_node_or_null("EnemiesHolder") as Node3D
	if camera_rig == null:
		camera_rig = get_node_or_null("IsometricCameraRig") as IsometricCameraRig


func _collect_waypoints() -> void:
	_waypoints.clear()
	if waypoints_holder != null:
		for child in waypoints_holder.get_children():
			if child is Marker3D or child is Node3D:
				_waypoints.append(child.global_position)


func _collect_and_register_enemies() -> void:
	enemy_pack.clear()
	if enemies_holder != null:
		for child in enemies_holder.get_children():
			if child is CharacterEntity:
				enemy_pack.append(child as CharacterEntity)

	if combat_trigger_system != null and not enemy_pack.is_empty():
		combat_trigger_system.register_enemy_pack(enemy_pack)


func _resolve_hero_ai_controllers() -> void:
	if party_controller == null:
		return

	var leader: CharacterEntity = party_controller.get_leader()
	if leader != null:
		tank_ai = leader.get_node_or_null("TankAIController") as TankAIController
		if tank_ai == null:
			tank_ai = leader.get_node_or_null("Components/TankAIController") as TankAIController
		if tank_ai == null:
			tank_ai = get_node_or_null("TankAIController") as TankAIController

	var dps: CharacterEntity = party_controller.get_dps()
	if dps != null:
		dps_ai = dps.get_node_or_null("RangedDPSAIController") as RangedDPSAIController
		if dps_ai == null:
			dps_ai = dps.get_node_or_null("Components/RangedDPSAIController") as RangedDPSAIController
		if dps_ai == null:
			dps_ai = get_node_or_null("RangedDPSAIController") as RangedDPSAIController

	var support: CharacterEntity = party_controller.get_support()
	if support != null:
		support_ai = support.get_node_or_null("SupportAIController") as SupportAIController
		if support_ai == null:
			support_ai = support.get_node_or_null("Components/SupportAIController") as SupportAIController
		if support_ai == null:
			support_ai = get_node_or_null("SupportAIController") as SupportAIController


func _setup_combat_trigger_listeners() -> void:
	if combat_trigger_system != null:
		if not combat_trigger_system.party_combat_started.is_connected(_on_combat_started):
			combat_trigger_system.party_combat_started.connect(_on_combat_started)
		if not combat_trigger_system.party_combat_ended.is_connected(_on_combat_ended):
			combat_trigger_system.party_combat_ended.connect(_on_combat_ended)


func _start_traversal() -> void:
	if _waypoints.is_empty() or party_controller == null:
		return

	_traversal_finished = false
	var leader: CharacterEntity = party_controller.get_leader()
	if leader == null:
		return

	_bind_leader_signals(leader)

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


func _physics_process(delta: float) -> void:
	if _in_combat or (combat_trigger_system != null and combat_trigger_system.is_party_in_combat):
		_process_combat_loop(delta)
		return

	if _traversal_finished or _waypoints.is_empty() or party_controller == null:
		return

	var leader: CharacterEntity = party_controller.get_leader()
	if leader == null or leader.health_component == null or not leader.health_component.is_alive:
		return

	if leader != _leader_connected:
		_bind_leader_signals(leader)

	var target_pos: Vector3 = _waypoints[_current_wp_idx]
	var leader_pos: Vector3 = leader.global_position
	var dist_planar: float = Vector2(leader_pos.x - target_pos.x, leader_pos.z - target_pos.z).length()

	if dist_planar <= 0.6:
		_advance_to_next_waypoint()


func _process_combat_loop(delta: float) -> void:
	var living_enemies: Array[CharacterEntity] = get_living_enemies()
	var living_heroes: Array[CharacterEntity] = get_living_heroes()

	if living_enemies.is_empty():
		return

	# 1. Executa IA Tática do Tanque (Bromm)
	if tank_ai != null and is_instance_valid(tank_ai):
		tank_ai.evaluate_combat_tactics(delta, living_enemies)

	# 2. Executa IA Tática da DPS Ranged (Elysia - Kiting & Longo Alcance)
	if dps_ai != null and is_instance_valid(dps_ai):
		dps_ai.evaluate_combat_tactics(delta, living_enemies)

	# 3. Executa IA Tática da Suporte (Beatrice - Árvore de 4 Níveis de Prioridade)
	if support_ai != null and is_instance_valid(support_ai):
		support_ai.evaluate_combat_tactics(delta, living_heroes, living_enemies)

	# 4. Executa IA de Combate dos Monstros / Goblins
	_process_enemy_pack_combat(delta, living_enemies, living_heroes)


func _process_enemy_pack_combat(delta: float, living_enemies: Array[CharacterEntity], living_heroes: Array[CharacterEntity]) -> void:
	var default_target: CharacterEntity = party_controller.get_leader() if party_controller != null else null
	if default_target == null or not default_target.health_component.is_alive:
		default_target = living_heroes.front() if not living_heroes.is_empty() else null

	for enemy: CharacterEntity in living_enemies:
		if enemy == null or not is_instance_valid(enemy):
			continue

		# Seleciona o alvo primário definido na ThreatTable do monstro
		var target: CharacterEntity = null
		if enemy.threat_table != null and enemy.threat_table.primary_target != null:
			target = enemy.threat_table.primary_target
		elif default_target != null:
			target = default_target

		if target == null or not is_instance_valid(target) or target.health_component == null or not target.health_component.is_alive:
			continue

		var enemy_pos: Vector3 = enemy.global_position
		var target_pos: Vector3 = target.global_position
		var diff: Vector3 = Vector3(target_pos.x - enemy_pos.x, 0.0, target_pos.z - enemy_pos.z)
		var dist: float = diff.length()

		# Orientação em direção ao alvo
		if diff.length_squared() > 0.001:
			var target_angle: float = atan2(diff.x, diff.z)
			enemy.rotation.y = lerp_angle(enemy.rotation.y, target_angle, clampf(8.0 * delta, 0.0, 1.0))

		# Se fora de alcance corpo a corpo (> 1.8m), aproxima-se do alvo
		if dist > 1.8:
			if enemy.movement_component != null:
				enemy.movement_component.move_towards(target_pos)
				enemy.movement_component.process_movement(delta)
		else:
			# Em alcance corpo a corpo: para e golpeia
			if enemy.movement_component != null and enemy.movement_component.is_moving:
				enemy.movement_component.stop_movement()

			# Ciclo de ataque do monstro (1 golpe a cada 1.5s)
			var cd: float = _enemy_attack_cooldowns.get(enemy, 0.0) as float
			cd -= delta
			if cd <= 0.0:
				cd = 1.5
				_enemy_attack_cooldowns[enemy] = cd

				var attack_dmg: int = 12
				var armor_val: int = 0
				if target.stats_component != null:
					armor_val = int(target.stats_component.get_stat("armor"))
				if target.health_component != null:
					target.health_component.take_damage(attack_dmg, armor_val, enemy)
			else:
				_enemy_attack_cooldowns[enemy] = cd


func _on_combat_started(initiator: Node3D, target: Node3D) -> void:
	_in_combat = true

	# Pausa a formação de marcha para dar autonomia tática aos heróis
	if party_controller != null:
		party_controller.formation_active = false

	# Garante que referências de IA estejam resolvidas
	_resolve_hero_ai_controllers()

	print("[PartyCombatWorld] Batalha iniciada entre %s e %s! IAs ativadas." % [
		initiator.name if initiator != null else "Desconhecido",
		target.name if target != null else "Desconhecido"
	])
	combat_started.emit(initiator, target)


func _on_combat_ended() -> void:
	_in_combat = false

	# Reativa a formação de marcha tática
	if party_controller != null:
		party_controller.formation_active = true

	print("[PartyCombatWorld] Batalha concluída com vitória! Retomando marcha autônoma.")
	combat_ended.emit()

	# Retoma a marcha em direção ao waypoint atual ou seguinte
	var leader: CharacterEntity = party_controller.get_leader() if party_controller != null else null
	if leader != null and leader.movement_component != null and not _waypoints.is_empty():
		leader.movement_component.move_towards(_waypoints[_current_wp_idx])
		if leader.state_machine != null:
			leader.state_machine.change_state("MarchState")


func _advance_to_next_waypoint() -> void:
	if _traversal_finished or _in_combat:
		return

	var leader: CharacterEntity = party_controller.get_leader() if party_controller != null else null
	if leader == null:
		return

	if _current_wp_idx < _waypoints.size() - 1:
		_current_wp_idx += 1
		if leader.movement_component != null:
			leader.movement_component.move_towards(_waypoints[_current_wp_idx])
	else:
		if loop_waypoints:
			_current_wp_idx = 0
			if leader.movement_component != null:
				leader.movement_component.move_towards(_waypoints[_current_wp_idx])
		else:
			_complete_traversal()


func _on_leader_target_reached() -> void:
	if not _in_combat:
		_advance_to_next_waypoint()


func _complete_traversal() -> void:
	if _traversal_finished:
		return
	_traversal_finished = true

	if party_controller != null:
		var all_heroes: Array[CharacterEntity] = party_controller.get_alive_heroes()
		for hero in all_heroes:
			if hero.movement_component != null:
				hero.movement_component.stop_movement()
			if hero.state_machine != null:
				hero.state_machine.change_state("IdleState")

	print("[PartyCombatWorld] Destino final da masmorra alcançado com sucesso!")
	party_traversal_completed.emit()

	var bus: EventBusSingleton = _get_event_bus()
	if bus != null:
		bus.room_cleared.emit(0)


func get_living_enemies() -> Array[CharacterEntity]:
	var living: Array[CharacterEntity] = []
	for enemy: CharacterEntity in enemy_pack:
		if enemy != null and is_instance_valid(enemy):
			if enemy.health_component == null or (enemy.health_component.is_alive and enemy.health_component.current_hp > 0):
				living.append(enemy)
	return living


func get_living_heroes() -> Array[CharacterEntity]:
	if party_controller != null:
		return party_controller.get_alive_heroes()
	return []


func is_in_combat() -> bool:
	return _in_combat or (combat_trigger_system != null and combat_trigger_system.is_party_in_combat)


func get_current_waypoint_index() -> int:
	return _current_wp_idx


func get_total_waypoints() -> int:
	return _waypoints.size()


func is_traversal_completed() -> bool:
	return _traversal_finished


func _get_event_bus() -> EventBusSingleton:
	var tree: SceneTree = Engine.get_main_loop() as SceneTree
	if tree != null and tree.root != null and tree.root.has_node("EventBus"):
		return tree.root.get_node("EventBus") as EventBusSingleton
	return null
