class_name DungeonLevel
extends Node3D

## Controlador central do nível de masmorra 3D (Graybox Dungeon).
## Gerencia a arquitetura de salas e corredores, o NavigationRegion3D, os Spawners de heróis/inimigos,
## os controladores de encontro (EncounterControllers), o sistema de combate (CombatTriggerSystem),
## as IAs dos heróis e monstros, e a travessia autônoma com regeneração de mana fora de combate (OOC).

signal dungeon_started()
signal party_spawned(leader: CharacterEntity)
signal room_entered(room_index: int, room_name: String)
signal room_cleared(room_index: int)
signal combat_started(initiator: Node3D, target: Node3D)
signal combat_ended()
signal dungeon_completed()

const WARRIOR_SCENE_PATH: String = "res://src/entities/enemies/GoblinWarrior.tscn"
const ARCHER_SCENE_PATH: String = "res://src/entities/enemies/GoblinArcher.tscn"
const CAPTAIN_SCENE_PATH: String = "res://src/entities/enemies/GoblinCaptain.tscn"
const HEALER_SCENE_PATH: String = "res://src/entities/enemies/GoblinHealer.tscn"

const TankAIControllerScript = preload("res://src/entities/ai/TankAIController.gd")
const SupportAIControllerScript = preload("res://src/entities/ai/SupportAIController.gd")
const RangedDPSAIControllerScript = preload("res://src/entities/ai/RangedDPSAIController.gd")
const Hitbox3DScript = preload("res://src/entities/components/Hitbox3D.gd")

@export var auto_spawn_party: bool = true
@export var auto_spawn_enemies: bool = true
@export var auto_start_traversal: bool = true

@export_group("Internal References")
@export var navigation_region: NavigationRegion3D = null
@export var architecture: StaticBody3D = null
@export var party_controller: PartyFormationController = null
@export var camera_rig: IsometricCameraRig = null
@export var spawners_holder: Node3D = null
@export var encounter_controllers_holder: Node3D = null
@export var waypoints_holder: Node3D = null
@export var combat_trigger_system: CombatTriggerSystem = null

var tank_ai: TankAIController = null
var support_ai: SupportAIController = null
var dps_ai: RangedDPSAIController = null

var _cached_waypoints: Array[Vector3] = []
var _current_wp_idx: int = 0
var _traversing: bool = false
var _traversal_finished: bool = false
var _in_combat: bool = false
var _leader_connected: CharacterEntity = null
var _spawned_room_enemies: Dictionary = {} # int -> Array[CharacterEntity]


func _ready() -> void:
	_resolve_references()
	_collect_waypoints()
	_connect_event_bus()
	_resolve_hero_ai_controllers()
	_setup_combat_trigger_listeners()

	if auto_spawn_enemies:
		spawn_all_enemies()

	if auto_spawn_party:
		call_deferred("initialize_party_at_spawn")

	if auto_start_traversal:
		call_deferred("start_traversal")


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

	if combat_trigger_system == null:
		combat_trigger_system = get_node_or_null("CombatTriggerSystem") as CombatTriggerSystem
		if combat_trigger_system == null:
			combat_trigger_system = CombatTriggerSystem.new()
			combat_trigger_system.name = "CombatTriggerSystem"
			add_child(combat_trigger_system)

	if combat_trigger_system != null and party_controller != null:
		combat_trigger_system.party_controller = party_controller

	_link_encounter_controllers()


func _link_encounter_controllers() -> void:
	if encounter_controllers_holder != null:
		for child in encounter_controllers_holder.get_children():
			if child is RoomEncounterController:
				var rec: RoomEncounterController = child as RoomEncounterController
				if rec.party_controller == null and party_controller != null:
					rec.party_controller = party_controller
				if rec.combat_trigger_system == null and combat_trigger_system != null:
					rec.combat_trigger_system = combat_trigger_system


## Resolve e instancia (caso ausentes) os controladores de IA para os 3 heróis.
func _resolve_hero_ai_controllers() -> void:
	if party_controller == null:
		return

	var leader: CharacterEntity = party_controller.get_leader()
	if leader != null and is_instance_valid(leader):
		tank_ai = leader.get_node_or_null("TankAIController") as TankAIController
		if tank_ai == null:
			tank_ai = leader.get_node_or_null("Components/TankAIController") as TankAIController
		if tank_ai == null:
			tank_ai = TankAIControllerScript.new()
			tank_ai.name = "TankAIController"
			tank_ai.actor = leader
			leader.add_child(tank_ai)

		# Garante Hitbox3D em Bromm para detecção física de colisão
		var bromm_hitbox: Hitbox3D = leader.get_node_or_null("Hitbox3D") as Hitbox3D
		if bromm_hitbox == null:
			bromm_hitbox = leader.get_node_or_null("Components/Hitbox3D") as Hitbox3D
		if bromm_hitbox == null:
			bromm_hitbox = Hitbox3DScript.new()
			bromm_hitbox.name = "Hitbox3D"
			bromm_hitbox.collision_layer = 8
			bromm_hitbox.collision_mask = 64
			bromm_hitbox.damage = 16
			bromm_hitbox.is_physical = true
			bromm_hitbox.source_entity = leader

			var hit_col: CollisionShape3D = CollisionShape3D.new()
			var hit_shape: SphereShape3D = SphereShape3D.new()
			hit_shape.radius = 0.8
			hit_col.shape = hit_shape
			hit_col.position = Vector3(0.0, 0.9, 0.5)
			bromm_hitbox.add_child(hit_col)
			leader.add_child(bromm_hitbox)

	var support: CharacterEntity = party_controller.get_support()
	if support != null and is_instance_valid(support):
		support_ai = support.get_node_or_null("SupportAIController") as SupportAIController
		if support_ai == null:
			support_ai = support.get_node_or_null("Components/SupportAIController") as SupportAIController
		if support_ai == null:
			support_ai = SupportAIControllerScript.new()
			support_ai.name = "SupportAIController"
			support_ai.actor = support
			support.add_child(support_ai)

	var dps: CharacterEntity = party_controller.get_dps()
	if dps != null and is_instance_valid(dps):
		dps_ai = dps.get_node_or_null("RangedDPSAIController") as RangedDPSAIController
		if dps_ai == null:
			dps_ai = dps.get_node_or_null("Components/RangedDPSAIController") as RangedDPSAIController
		if dps_ai == null:
			dps_ai = RangedDPSAIControllerScript.new()
			dps_ai.name = "RangedDPSAIController"
			dps_ai.actor = dps
			dps.add_child(dps_ai)


func _setup_combat_trigger_listeners() -> void:
	if combat_trigger_system != null:
		if not combat_trigger_system.party_combat_started.is_connected(_on_combat_started):
			combat_trigger_system.party_combat_started.connect(_on_combat_started)
		if not combat_trigger_system.party_combat_ended.is_connected(_on_combat_ended):
			combat_trigger_system.party_combat_ended.connect(_on_combat_ended)


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
	_on_room_cleared_handler(r_idx)


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

	_resolve_hero_ai_controllers()

	var spawn_pos: Vector3 = get_spawn_point()
	var leader: CharacterEntity = party_controller.get_leader()
	var support: CharacterEntity = party_controller.get_support()
	var dps: CharacterEntity = party_controller.get_dps()

	if leader != null and is_instance_valid(leader):
		leader.global_position = spawn_pos
		if leader.movement_component != null:
			leader.movement_component.stop_movement()
		if leader.state_machine != null:
			leader.state_machine.change_state("IdleState")

	if support != null and is_instance_valid(support):
		var supp_offset: Vector3 = party_controller.support_offset
		support.global_position = spawn_pos + supp_offset
		if support.movement_component != null:
			support.movement_component.stop_movement()
		if support.state_machine != null:
			support.state_machine.change_state("IdleState")

	if dps != null and is_instance_valid(dps):
		var d_offset: Vector3 = party_controller.dps_offset
		dps.global_position = spawn_pos + d_offset
		if dps.movement_component != null:
			dps.movement_component.stop_movement()
		if dps.state_machine != null:
			dps.state_machine.change_state("IdleState")

	if camera_rig != null and is_instance_valid(camera_rig) and leader != null:
		camera_rig.set_target(leader)
		camera_rig.global_position = Vector3(spawn_pos.x, 0.0, spawn_pos.z) + camera_rig.camera_offset

	party_spawned.emit(leader)


## Spawna todos os monstros das salas 1 e 2.
func spawn_all_enemies() -> void:
	spawn_room_enemies(1)
	spawn_room_enemies(2)


## Spawna os monstros de uma sala específica e os associa ao RoomEncounterController.
func spawn_room_enemies(room_index: int) -> Array[CharacterEntity]:
	if _spawned_room_enemies.has(room_index):
		var existing: Array[CharacterEntity] = []
		for e in _spawned_room_enemies[room_index]:
			if e != null and is_instance_valid(e):
				existing.append(e as CharacterEntity)
		if not existing.is_empty():
			return existing

	var pack: Array[CharacterEntity] = []

	match room_index:
		1:
			# Sala 1: 2 Goblin Guerreiros Melee + 1 Goblin Arqueiro Ranged
			var parent_node: Node3D = null
			if spawners_holder != null:
				parent_node = spawners_holder.get_node_or_null("Room1_EnemyPack") as Node3D
			if parent_node == null:
				parent_node = self

			# Coleta instâncias pré-existentes na cena se houver
			if parent_node != null:
				for child in parent_node.get_children():
					if child is CharacterEntity:
						pack.append(child as CharacterEntity)

			if pack.is_empty():
				var w_scene: PackedScene = load(WARRIOR_SCENE_PATH) as PackedScene
				var a_scene: PackedScene = load(ARCHER_SCENE_PATH) as PackedScene
				var spawners: Array[Marker3D] = get_enemy_spawners_for_room(1)

				var default_positions: Array[Vector3] = [
					Vector3(0.0, 0.0, 25.0),
					Vector3(-2.5, 0.0, 27.5),
					Vector3(2.5, 0.0, 27.5)
				]

				# Mob 1: Warrior
				if w_scene != null:
					var m1: CharacterEntity = w_scene.instantiate() as CharacterEntity
					m1.name = "Room1_GoblinWarrior_1"
					var pos1: Vector3 = spawners[0].global_position if spawners.size() > 0 else default_positions[0]
					parent_node.add_child(m1)
					m1.global_position = pos1
					pack.append(m1)

					# Mob 2: Warrior
					var m2: CharacterEntity = w_scene.instantiate() as CharacterEntity
					m2.name = "Room1_GoblinWarrior_2"
					var pos2: Vector3 = spawners[1].global_position if spawners.size() > 1 else default_positions[1]
					parent_node.add_child(m2)
					m2.global_position = pos2
					pack.append(m2)

				# Mob 3: Archer
				if a_scene != null:
					var m3: CharacterEntity = a_scene.instantiate() as CharacterEntity
					m3.name = "Room1_GoblinArcher"
					var pos3: Vector3 = spawners[2].global_position if spawners.size() > 2 else default_positions[2]
					parent_node.add_child(m3)
					m3.global_position = pos3
					pack.append(m3)

			var ctrl1: RoomEncounterController = get_encounter_controller(1) as RoomEncounterController
			if ctrl1 != null:
				ctrl1.setup_enemy_pack(pack)

		2:
			# Sala 2: 1 Capitão Goblin (Mini-Chefe com Aura de Fúria) + 1 Goblin Curandeiro (com Bênção)
			var parent_node2: Node3D = null
			if spawners_holder != null:
				parent_node2 = spawners_holder.get_node_or_null("Room2_MiniBossPack") as Node3D
			if parent_node2 == null:
				parent_node2 = self

			# Coleta instâncias pré-existentes na cena se houver
			if parent_node2 != null:
				for child in parent_node2.get_children():
					if child is CharacterEntity:
						pack.append(child as CharacterEntity)

			if pack.is_empty():
				var cap_scene: PackedScene = load(CAPTAIN_SCENE_PATH) as PackedScene
				var heal_scene: PackedScene = load(HEALER_SCENE_PATH) as PackedScene
				var spawners2: Array[Marker3D] = get_enemy_spawners_for_room(2)

				var default_positions2: Array[Vector3] = [
					Vector3(16.0, 0.0, 60.0),
					Vector3(16.0, 0.0, 63.5)
				]

				# Mob 1: Captain Mini-Boss
				if cap_scene != null:
					var c1: CharacterEntity = cap_scene.instantiate() as CharacterEntity
					c1.name = "Room2_GoblinCaptain"
					var pos_c: Vector3 = spawners2[0].global_position if spawners2.size() > 0 else default_positions2[0]
					parent_node2.add_child(c1)
					c1.global_position = pos_c
					pack.append(c1)

				# Mob 2: Healer
				if heal_scene != null:
					var h1: CharacterEntity = heal_scene.instantiate() as CharacterEntity
					h1.name = "Room2_GoblinHealer"
					var pos_h: Vector3 = spawners2[1].global_position if spawners2.size() > 1 else default_positions2[1]
					parent_node2.add_child(h1)
					h1.global_position = pos_h
					pack.append(h1)

			var ctrl2: RoomEncounterController = get_encounter_controller(2) as RoomEncounterController
			if ctrl2 != null:
				ctrl2.setup_enemy_pack(pack)

	_spawned_room_enemies[room_index] = pack
	return pack


## Inicia formalmente a marcha autônoma da equipe pela masmorra.
func start_traversal() -> void:
	if _cached_waypoints.is_empty() or party_controller == null:
		return

	_traversal_finished = false
	_traversing = true

	var leader: CharacterEntity = party_controller.get_leader()
	if leader == null:
		return

	_bind_leader_signals(leader)
	_current_wp_idx = 1 if _cached_waypoints.size() > 1 else 0

	party_controller.formation_active = true
	dungeon_started.emit()

	if leader.movement_component != null:
		leader.movement_component.move_towards(_cached_waypoints[_current_wp_idx])
		if leader.state_machine != null:
			leader.state_machine.change_state("MarchState")

	var support: CharacterEntity = party_controller.get_support()
	if support != null and is_instance_valid(support) and support.state_machine != null:
		support.state_machine.change_state("MarchState")

	var dps: CharacterEntity = party_controller.get_dps()
	if dps != null and is_instance_valid(dps) and dps.state_machine != null:
		dps.state_machine.change_state("MarchState")


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

	if not _traversing or _traversal_finished or _cached_waypoints.is_empty() or party_controller == null:
		return

	var leader: CharacterEntity = party_controller.get_leader()
	if leader == null or not is_instance_valid(leader) or leader.health_component == null or not leader.health_component.is_alive:
		return

	if leader != _leader_connected:
		_bind_leader_signals(leader)

	var target_pos: Vector3 = _cached_waypoints[_current_wp_idx]
	var leader_pos: Vector3 = leader.global_position
	var dist_planar: float = Vector2(leader_pos.x - target_pos.x, leader_pos.z - target_pos.z).length()

	# Checa proximidade com gatilhos de sala para ativação autônoma
	_check_room_encounter_triggers(leader_pos)

	if dist_planar <= 0.8:
		_advance_to_next_waypoint()


func _check_room_encounter_triggers(leader_pos: Vector3) -> void:
	# Sala 1: Z ~ 26 (raio 6m)
	if leader_pos.z >= 20.0 and leader_pos.z <= 32.0 and absf(leader_pos.x) <= 8.0:
		var ctrl1: RoomEncounterController = get_encounter_controller(1) as RoomEncounterController
		if ctrl1 != null and not ctrl1.is_encounter_cleared() and not ctrl1.is_encounter_active():
			ctrl1.start_encounter()

	# Sala 2: Z ~ 61, X ~ 16 (raio 8m)
	if leader_pos.z >= 52.0 and leader_pos.z <= 70.0 and leader_pos.x >= 7.0 and leader_pos.x <= 25.0:
		var ctrl2: RoomEncounterController = get_encounter_controller(2) as RoomEncounterController
		if ctrl2 != null and not ctrl2.is_encounter_cleared() and not ctrl2.is_encounter_active():
			ctrl2.start_encounter()


func _process_combat_loop(delta: float) -> void:
	var living_heroes: Array[CharacterEntity] = get_living_heroes()
	var living_enemies: Array[CharacterEntity] = get_current_living_enemies()

	if living_enemies.is_empty():
		return

	_resolve_hero_ai_controllers()

	# 1. IA Tanque Bromm
	if tank_ai != null and is_instance_valid(tank_ai):
		tank_ai.evaluate_combat_tactics(delta, living_enemies)

	# 2. IA DPS Ranged Elysia
	if dps_ai != null and is_instance_valid(dps_ai):
		dps_ai.evaluate_combat_tactics(delta, living_enemies)

	# 3. IA Suporte Beatrice
	if support_ai != null and is_instance_valid(support_ai):
		support_ai.evaluate_combat_tactics(delta, living_heroes, living_enemies)

	# 4. IA Monstros
	for enemy: CharacterEntity in living_enemies:
		if enemy == null or not is_instance_valid(enemy):
			continue

		var g_ai: GoblinAIController = enemy.get_node_or_null("GoblinAIController") as GoblinAIController
		if g_ai == null:
			g_ai = enemy.get_node_or_null("Components/GoblinAIController") as GoblinAIController
		if g_ai != null:
			g_ai.process_ai(delta, living_heroes)

		var h_ai: GoblinHealerAI = enemy.get_node_or_null("GoblinHealerAI") as GoblinHealerAI
		if h_ai == null:
			h_ai = enemy.get_node_or_null("Components/GoblinHealerAI") as GoblinHealerAI
		if h_ai != null:
			h_ai.process_ai(delta, living_enemies, living_heroes)


func _on_combat_started(initiator: Node3D, target: Node3D) -> void:
	_in_combat = true
	if party_controller != null:
		party_controller.formation_active = false
	_resolve_hero_ai_controllers()
	combat_started.emit(initiator, target)


func _on_combat_ended() -> void:
	_in_combat = false
	if party_controller != null:
		party_controller.formation_active = true
	combat_ended.emit()


func _on_room_cleared_handler(r_idx: int) -> void:
	_in_combat = false
	if combat_trigger_system != null:
		combat_trigger_system.end_combat()

	if party_controller != null:
		party_controller.formation_active = true
		for hero: CharacterEntity in party_controller.get_all_heroes():
			if hero != null and is_instance_valid(hero) and hero.health_component != null:
				hero.health_component.set_in_combat(false)

	room_cleared.emit(r_idx)

	# Retoma marcha em direção aos próximos waypoints
	var leader: CharacterEntity = party_controller.get_leader() if party_controller != null else null
	if leader != null and leader.movement_component != null and not _cached_waypoints.is_empty():
		match r_idx:
			1:
				# Sai da Sala 1 -> Avança para Corredor 1_2 (Waypoint 3: (0, 0, 41.5))
				_current_wp_idx = 3
			2:
				# Sai da Sala 2 -> Avança para Portão Arena 3 (Waypoint 6: (16, 0, 74))
				_current_wp_idx = 6

		leader.movement_component.move_towards(_cached_waypoints[_current_wp_idx])
		if leader.state_machine != null:
			leader.state_machine.change_state("MarchState")

		var support: CharacterEntity = party_controller.get_support()
		if support != null and is_instance_valid(support) and support.state_machine != null:
			support.state_machine.change_state("MarchState")

		var dps: CharacterEntity = party_controller.get_dps()
		if dps != null and is_instance_valid(dps) and dps.state_machine != null:
			dps.state_machine.change_state("MarchState")


func _advance_to_next_waypoint() -> void:
	if _traversal_finished or _in_combat:
		return

	var leader: CharacterEntity = party_controller.get_leader() if party_controller != null else null
	if leader == null:
		return

	# Checa se chegamos ao portão da Arena 3 (Waypoint 6)
	if _current_wp_idx >= 6:
		_complete_traversal()
		return

	if _current_wp_idx < _cached_waypoints.size() - 1:
		_current_wp_idx += 1
		if leader.movement_component != null:
			leader.movement_component.move_towards(_cached_waypoints[_current_wp_idx])
	else:
		_complete_traversal()


func _on_leader_target_reached() -> void:
	if not _in_combat:
		_advance_to_next_waypoint()


func _complete_traversal() -> void:
	if _traversal_finished:
		return
	_traversal_finished = true
	_traversing = false

	if party_controller != null:
		var all_heroes: Array[CharacterEntity] = party_controller.get_alive_heroes()
		for hero in all_heroes:
			if hero.movement_component != null:
				hero.movement_component.stop_movement()
			if hero.state_machine != null:
				hero.state_machine.change_state("IdleState")

	print("[DungeonLevel] Marcha autônoma concluída no portão da Arena 3!")
	dungeon_completed.emit()


## Retorna a lista de heróis vivos da equipe.
func get_living_heroes() -> Array[CharacterEntity]:
	if party_controller != null:
		return party_controller.get_alive_heroes()
	return []


## Retorna os monstros vivos de uma sala específica.
func get_living_enemies_for_room(room_index: int) -> Array[CharacterEntity]:
	var alive: Array[CharacterEntity] = []
	var pack: Array[CharacterEntity] = get_spawned_enemies_for_room(room_index)
	for enemy: CharacterEntity in pack:
		if enemy != null and is_instance_valid(enemy):
			if enemy.health_component == null or (enemy.health_component.is_alive and enemy.health_component.current_hp > 0):
				alive.append(enemy)
	return alive


## Retorna todos os monstros atualmente vivos registrados em combate ou nas salas ativas.
func get_current_living_enemies() -> Array[CharacterEntity]:
	if combat_trigger_system != null and not combat_trigger_system.active_enemy_pack.is_empty():
		var alive: Array[CharacterEntity] = []
		for e in combat_trigger_system.active_enemy_pack:
			if e != null and is_instance_valid(e):
				if e.health_component == null or (e.health_component.is_alive and e.health_component.current_hp > 0):
					alive.append(e)
		if not alive.is_empty():
			return alive

	var ctrl1: RoomEncounterController = get_encounter_controller(1) as RoomEncounterController
	if ctrl1 != null and ctrl1.is_encounter_active():
		return ctrl1.get_living_enemies()

	var ctrl2: RoomEncounterController = get_encounter_controller(2) as RoomEncounterController
	if ctrl2 != null and ctrl2.is_encounter_active():
		return ctrl2.get_living_enemies()

	return []


## Retorna os monstros spawnados para uma sala específica.
func get_spawned_enemies_for_room(room_index: int) -> Array[CharacterEntity]:
	if _spawned_room_enemies.has(room_index):
		var res: Array[CharacterEntity] = []
		for e in _spawned_room_enemies[room_index]:
			if e != null and is_instance_valid(e):
				res.append(e as CharacterEntity)
		return res
	return []


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


func is_in_combat() -> bool:
	return _in_combat or (combat_trigger_system != null and combat_trigger_system.is_party_in_combat)


func is_traversing() -> bool:
	return _traversing and not _traversal_finished


func is_dungeon_completed() -> bool:
	return _traversal_finished


func get_current_waypoint_index() -> int:
	return _current_wp_idx


func get_total_waypoints() -> int:
	return _cached_waypoints.size()
