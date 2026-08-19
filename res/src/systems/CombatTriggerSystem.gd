class_name CombatTriggerSystem
extends Node

## Sistema de Gatilho de Batalha por Primeiro Impacto Físico (M4.1)
## Monitora impactos físicos e gerencia a transição de estado da equipe entre Marcha e Combate.

signal party_combat_started(initiator: Node3D, target: Node3D)
signal party_combat_ended()

var is_party_in_combat: bool = false
var active_enemy_pack: Array[CharacterEntity] = []

@export var party_controller: PartyFormationController = null


func _ready() -> void:
	_auto_detect_party_controller_if_needed()
	_connect_event_bus()


func _exit_tree() -> void:
	_disconnect_event_bus()


## Registra o conjunto de inimigos ativos para monitoramento de término de combate.
func register_enemy_pack(pack: Array[CharacterEntity]) -> void:
	active_enemy_pack.clear()
	for enemy: CharacterEntity in pack:
		if enemy != null and is_instance_valid(enemy):
			active_enemy_pack.append(enemy)


## Inicia formalmente o combate do grupo ao detectar o primeiro impacto.
func trigger_combat_start(initiator: Node3D, target: Node3D) -> void:
	if is_party_in_combat:
		return

	is_party_in_combat = true

	# Registra inimigo envolvido se o pack estiver vazio
	_register_participant_enemy_if_needed(initiator)
	_register_participant_enemy_if_needed(target)

	# Atualiza o estado de combate nos membros vivos da equipe
	if party_controller != null:
		for hero: CharacterEntity in party_controller.get_alive_heroes():
			var hc: HealthComponent = _get_health_component(hero)
			if hc != null:
				hc.set_in_combat(true)
	else:
		if initiator != null and _is_hero(initiator):
			var hc_init: HealthComponent = _get_health_component(initiator)
			if hc_init != null:
				hc_init.set_in_combat(true)
		if target != null and _is_hero(target):
			var hc_targ: HealthComponent = _get_health_component(target)
			if hc_targ != null:
				hc_targ.set_in_combat(true)

	var bus: EventBusSingleton = _get_event_bus()
	if bus != null:
		bus.combat_triggered.emit(initiator, target)

	party_combat_started.emit(initiator, target)


## Finaliza o combate do grupo e restaura o estado de marcha e regeneração fora de combate.
func end_combat() -> void:
	if not is_party_in_combat:
		return

	is_party_in_combat = false

	# Atualiza o estado de combate nos heróis da equipe
	if party_controller != null:
		for hero: CharacterEntity in party_controller.get_all_heroes():
			var hc: HealthComponent = _get_health_component(hero)
			if hc != null:
				hc.set_in_combat(false)

	active_enemy_pack.clear()
	party_combat_ended.emit()


## Callback acionado quando dano é desferido no jogo via EventBus.
func _on_damage_dealt(target: Node3D, source: Node3D, _amount: int, _is_critical: bool, _is_blocked: bool) -> void:
	if not is_party_in_combat and _is_combat_participant(source, target):
		trigger_combat_start(source, target)


## Callback acionado quando uma entidade morre via EventBus.
func _on_entity_died(entity: Node3D, _killer: Node3D = null) -> void:
	if not is_party_in_combat:
		return

	if entity is CharacterEntity:
		var char_ent: CharacterEntity = entity as CharacterEntity
		if active_enemy_pack.has(char_ent):
			active_enemy_pack.erase(char_ent)

	# Se todos os heróis da equipe morrerem, finaliza o combate
	if party_controller != null and party_controller.get_alive_heroes().is_empty():
		end_combat()
		return

	# Filtra inimigos mortos ou instâncias liberadas do pack
	var clean_pack: Array[CharacterEntity] = []
	for enemy: CharacterEntity in active_enemy_pack:
		if enemy != null and is_instance_valid(enemy):
			var hc: HealthComponent = _get_health_component(enemy)
			if hc == null or (hc.is_alive and hc.current_hp > 0):
				clean_pack.append(enemy)
	active_enemy_pack = clean_pack

	if active_enemy_pack.is_empty():
		end_combat()


## Determina se o evento de dano ocorreu entre facções opostas (Herói vs Inimigo).
func _is_combat_participant(a: Node3D, b: Node3D) -> bool:
	if a == null or b == null or a == b:
		return false

	var a_is_hero: bool = _is_hero(a)
	var b_is_hero: bool = _is_hero(b)
	var a_is_enemy: bool = _is_enemy(a)
	var b_is_enemy: bool = _is_enemy(b)

	# Fogo amigo entre heróis ou monstros não inicia combate
	if a_is_hero and b_is_hero:
		return false
	if a_is_enemy and b_is_enemy:
		return false

	if (a_is_hero and b_is_enemy) or (b_is_hero and a_is_enemy):
		return true

	# Verificação contextual via party_controller
	if party_controller != null:
		var heroes: Array[CharacterEntity] = party_controller.get_all_heroes()
		var a_in_party: bool = a is CharacterEntity and heroes.has(a as CharacterEntity)
		var b_in_party: bool = b is CharacterEntity and heroes.has(b as CharacterEntity)
		if (a_in_party and not b_in_party) or (b_in_party and not a_in_party):
			return true

	# Verificação contextual via active_enemy_pack
	if not active_enemy_pack.is_empty():
		var a_in_pack: bool = a is CharacterEntity and active_enemy_pack.has(a as CharacterEntity)
		var b_in_pack: bool = b is CharacterEntity and active_enemy_pack.has(b as CharacterEntity)
		if (a_in_pack and not b_in_pack) or (b_in_pack and not a_in_pack):
			return true

	return false


func _is_hero(node: Node3D) -> bool:
	if node == null:
		return false
	if party_controller != null and node is CharacterEntity:
		if party_controller.get_all_heroes().has(node as CharacterEntity):
			return true
	if node is CharacterEntity:
		var ce: CharacterEntity = node as CharacterEntity
		if ce.hero_data != null:
			return true
		if ce.enemy_data != null:
			return false
	if node.is_in_group("heroes") or node.is_in_group("hero") or node.is_in_group("party"):
		return true
	var name_lower: String = node.name.to_lower()
	if name_lower.contains("hero") or name_lower.contains("bromm") or name_lower.contains("elysia") or name_lower.contains("beatrice") or name_lower.contains("leader") or name_lower.contains("tank") or name_lower.contains("dps") or name_lower.contains("support"):
		return true
	return false


func _is_enemy(node: Node3D) -> bool:
	if node == null:
		return false
	if node is CharacterEntity and active_enemy_pack.has(node as CharacterEntity):
		return true
	if node is CharacterEntity:
		var ce: CharacterEntity = node as CharacterEntity
		if ce.enemy_data != null:
			return true
		if ce.hero_data != null:
			return false
	if node.is_in_group("enemies") or node.is_in_group("enemy") or node.is_in_group("monsters") or node.is_in_group("mobs"):
		return true
	var name_lower: String = node.name.to_lower()
	if name_lower.contains("enemy") or name_lower.contains("goblin") or name_lower.contains("monster") or name_lower.contains("mob") or name_lower.contains("boss") or name_lower.contains("target") or name_lower.contains("victim") or name_lower.contains("defender"):
		return true
	return false


func _get_health_component(entity: Node3D) -> HealthComponent:
	if entity == null:
		return null
	if entity is CharacterEntity:
		var ce: CharacterEntity = entity as CharacterEntity
		if ce.health_component != null:
			return ce.health_component
		var hc: HealthComponent = ce.get_node_or_null("Components/HealthComponent") as HealthComponent
		if hc == null:
			hc = ce.get_node_or_null("HealthComponent") as HealthComponent
		if hc != null:
			ce.health_component = hc
		return hc
	var comp: HealthComponent = entity.get_node_or_null("Components/HealthComponent") as HealthComponent
	if comp == null:
		comp = entity.get_node_or_null("HealthComponent") as HealthComponent
	return comp


func _register_participant_enemy_if_needed(node: Node3D) -> void:
	if node is CharacterEntity and _is_enemy(node):
		var enemy_ent: CharacterEntity = node as CharacterEntity
		if not active_enemy_pack.has(enemy_ent):
			active_enemy_pack.append(enemy_ent)


func _auto_detect_party_controller_if_needed() -> void:
	if party_controller != null:
		return
	if get_parent() is PartyFormationController:
		party_controller = get_parent() as PartyFormationController
		return
	var parent: Node = get_parent()
	if parent != null:
		party_controller = parent.get_node_or_null("PartyFormationController") as PartyFormationController


func _connect_event_bus() -> void:
	var bus: EventBusSingleton = _get_event_bus()
	if bus != null:
		if not bus.damage_dealt.is_connected(_on_damage_dealt):
			bus.damage_dealt.connect(_on_damage_dealt)
		if not bus.entity_died.is_connected(_on_entity_died):
			bus.entity_died.connect(_on_entity_died)


func _disconnect_event_bus() -> void:
	var bus: EventBusSingleton = _get_event_bus()
	if bus != null:
		if bus.damage_dealt.is_connected(_on_damage_dealt):
			bus.damage_dealt.disconnect(_on_damage_dealt)
		if bus.entity_died.is_connected(_on_entity_died):
			bus.entity_died.disconnect(_on_entity_died)


func _get_event_bus() -> EventBusSingleton:
	var tree: SceneTree = Engine.get_main_loop() as SceneTree
	if tree != null and tree.root != null and tree.root.has_node("EventBus"):
		return tree.root.get_node("EventBus") as EventBusSingleton
	return null
