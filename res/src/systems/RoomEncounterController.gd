class_name RoomEncounterController
extends Area3D

## Controlador de Encontros de Sala da Masmorra (M5.5)
## Gerencia o ciclo de ativação de combate em cada sala da masmorra:
## 1. Detecta a entrada dos heróis via colisão de Area3D (body_entered / area_entered).
## 2. Inicia o encontro, notificando EventBus e CombatTriggerSystem com o pacote de inimigos.
## 3. Monitora as mortes dos inimigos via EventBus.entity_died.
## 4. Quando todos os inimigos da sala são derrotados, emite encounter_cleared e room_cleared,
##    e reativa a marcha da equipe para prosseguir na masmorra.

signal encounter_cleared(room_index: int)
signal encounter_started(room_index: int)

@export var room_index: int = 1
@export var room_name: String = "Sala 1"
@export var enemy_pack: Array[CharacterEntity] = []
@export var party_controller: PartyFormationController = null
@export var combat_trigger_system: CombatTriggerSystem = null
@export var auto_start_combat: bool = true

var _alive_enemies_count: int = 0
var _encounter_active: bool = false
var _encounter_completed: bool = false


func _ready() -> void:
	_resolve_references_if_needed()
	_connect_collision_signals()
	_connect_event_bus()

	if not enemy_pack.is_empty():
		setup_enemy_pack(enemy_pack)


func _exit_tree() -> void:
	_disconnect_event_bus()


## Configura e inicializa o pacote de inimigos atribuído à sala.
func setup_enemy_pack(pack: Array[CharacterEntity]) -> void:
	enemy_pack.clear()
	for enemy: CharacterEntity in pack:
		if enemy != null and is_instance_valid(enemy):
			enemy_pack.append(enemy)
	_update_alive_enemies_count()


## Inicia formalmente o encontro da sala.
func start_encounter() -> void:
	if _encounter_completed or _encounter_active:
		return

	_encounter_active = true
	_update_alive_enemies_count()

	encounter_started.emit(room_index)

	var bus: EventBusSingleton = _get_event_bus()
	if bus != null:
		bus.room_entered.emit(room_index, room_name)

	if combat_trigger_system != null:
		combat_trigger_system.register_enemy_pack(enemy_pack)
		if auto_start_combat and _alive_enemies_count > 0:
			var hero_lead: CharacterEntity = _get_hero_participant()
			var first_enemy: CharacterEntity = _get_first_alive_enemy()
			if hero_lead != null and first_enemy != null:
				combat_trigger_system.trigger_combat_start(hero_lead, first_enemy)


## Callback de colisão com corpos físicos (CharacterBody3D dos heróis).
func _on_body_entered(body: Node3D) -> void:
	if _is_hero(body):
		_on_hero_entered(body)


## Callback de colisão com áreas (Hurtbox3D / Hitbox3D dos heróis).
func _on_area_entered(area: Area3D) -> void:
	if _is_hero(area):
		_on_hero_entered(area)


## Trata o evento de entrada do herói na área do encontro.
func _on_hero_entered(_hero_node: Node3D) -> void:
	if _encounter_completed or _encounter_active:
		return
	start_encounter()


## Callback acionado quando qualquer entidade morre via EventBus.
func _on_entity_died(entity: Node3D, _killer: Node3D = null) -> void:
	if not _encounter_active or _encounter_completed:
		return

	if entity is CharacterEntity and enemy_pack.has(entity as CharacterEntity):
		_update_alive_enemies_count()
		if _alive_enemies_count <= 0:
			_complete_encounter()


## Finaliza o encontro, emite sinais de vitória e restaura a formação de marcha.
func _complete_encounter() -> void:
	_encounter_active = false
	_encounter_completed = true

	encounter_cleared.emit(room_index)

	var bus: EventBusSingleton = _get_event_bus()
	if bus != null:
		bus.room_cleared.emit(room_index)

	print("[DUNGEON] Sala %d limpa! Retomando marcha." % room_index)

	if party_controller != null:
		party_controller.formation_active = true


## Recalcula e retorna o número de inimigos vivos no enemy_pack.
func _update_alive_enemies_count() -> int:
	var count: int = 0
	for enemy: CharacterEntity in enemy_pack:
		if enemy != null and is_instance_valid(enemy):
			if enemy.health_component == null:
				count += 1
			elif enemy.health_component.is_alive and enemy.health_component.current_hp > 0:
				count += 1
	_alive_enemies_count = count
	return count


## Retorna o total de monstros vivos na sala.
func get_alive_enemies_count() -> int:
	return _alive_enemies_count


## Retorna a lista de entidades de inimigos vivos no enemy_pack.
func get_living_enemies() -> Array[CharacterEntity]:
	var alive_list: Array[CharacterEntity] = []
	for enemy: CharacterEntity in enemy_pack:
		if enemy != null and is_instance_valid(enemy):
			if enemy.health_component == null or (enemy.health_component.is_alive and enemy.health_component.current_hp > 0):
				alive_list.append(enemy)
	return alive_list


## Retorna se o encontro está em andamento.
func is_encounter_active() -> bool:
	return _encounter_active


## Retorna se a sala já foi limpa e finalizada.
func is_encounter_cleared() -> bool:
	return _encounter_completed


## Reinicia o estado do encontro (útil para testes ou respawn).
func reset_encounter() -> void:
	_encounter_active = false
	_encounter_completed = false
	_update_alive_enemies_count()


## Busca o primeiro herói disponível para iniciar combate.
func _get_hero_participant() -> CharacterEntity:
	if party_controller != null:
		var leader: CharacterEntity = party_controller.get_leader()
		if leader != null and is_instance_valid(leader):
			return leader
		var alive_heroes: Array[CharacterEntity] = party_controller.get_alive_heroes()
		if not alive_heroes.is_empty():
			return alive_heroes.front()
	return null


## Busca o primeiro inimigo vivo no pacote da sala.
func _get_first_alive_enemy() -> CharacterEntity:
	for enemy: CharacterEntity in enemy_pack:
		if enemy != null and is_instance_valid(enemy):
			if enemy.health_component == null or (enemy.health_component.is_alive and enemy.health_component.current_hp > 0):
				return enemy
	return null


## Determina se um nó colidido pertence a um herói do grupo.
func _is_hero(node: Node) -> bool:
	if node == null:
		return false

	var target: Node = node
	if not (target is CharacterEntity) and target.get_parent() is CharacterEntity:
		target = target.get_parent()
	elif not (target is CharacterEntity) and target.owner is CharacterEntity:
		target = target.owner

	if party_controller != null and target is CharacterEntity:
		if party_controller.get_all_heroes().has(target as CharacterEntity):
			return true

	if target is CharacterEntity:
		var ce: CharacterEntity = target as CharacterEntity
		if ce.hero_data != null:
			return true
		if ce.enemy_data != null:
			return false

	if target.is_in_group("heroes") or target.is_in_group("hero") or target.is_in_group("party"):
		return true

	if target is CollisionObject3D:
		var co: CollisionObject3D = target as CollisionObject3D
		# Layer 2: Hero_Bodies (bit 2), Layer 5: Hero_Hurtboxes (bit 16)
		if (co.collision_layer & 2) != 0 or (co.collision_layer & 16) != 0:
			return true

	var name_lower: String = target.name.to_lower()
	if name_lower.contains("hero") or name_lower.contains("bromm") or name_lower.contains("elysia") or name_lower.contains("beatrice") or name_lower.contains("leader") or name_lower.contains("tank") or name_lower.contains("dps") or name_lower.contains("support"):
		return true

	return false


## Tenta resolver referências de party_controller e combat_trigger_system na árvore.
func _resolve_references_if_needed() -> void:
	if party_controller == null:
		party_controller = get_node_or_null("../PartyFormationController") as PartyFormationController
		if party_controller == null:
			party_controller = get_node_or_null("../../PartyFormationController") as PartyFormationController
		if party_controller == null and get_tree() != null and get_tree().current_scene != null:
			party_controller = get_tree().current_scene.get_node_or_null("PartyFormationController") as PartyFormationController

	if combat_trigger_system == null:
		combat_trigger_system = get_node_or_null("../CombatTriggerSystem") as CombatTriggerSystem
		if combat_trigger_system == null:
			combat_trigger_system = get_node_or_null("../../CombatTriggerSystem") as CombatTriggerSystem
		if combat_trigger_system == null and get_tree() != null and get_tree().current_scene != null:
			combat_trigger_system = get_tree().current_scene.get_node_or_null("CombatTriggerSystem") as CombatTriggerSystem


## Conecta os sinais de colisão de Area3D.
func _connect_collision_signals() -> void:
	if not body_entered.is_connected(_on_body_entered):
		body_entered.connect(_on_body_entered)
	if not area_entered.is_connected(_on_area_entered):
		area_entered.connect(_on_area_entered)


## Conecta ao EventBusSingleton.
func _connect_event_bus() -> void:
	var bus: EventBusSingleton = _get_event_bus()
	if bus != null and not bus.entity_died.is_connected(_on_entity_died):
		bus.entity_died.connect(_on_entity_died)


## Desconecta do EventBusSingleton.
func _disconnect_event_bus() -> void:
	var bus: EventBusSingleton = _get_event_bus()
	if bus != null and bus.entity_died.is_connected(_on_entity_died):
		bus.entity_died.disconnect(_on_entity_died)


## Obtém a instância global do EventBus.
func _get_event_bus() -> EventBusSingleton:
	var tree: SceneTree = Engine.get_main_loop() as SceneTree
	if tree != null and tree.root != null and tree.root.has_node("EventBus"):
		return tree.root.get_node("EventBus") as EventBusSingleton
	return null
