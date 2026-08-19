class_name AuraDeFuriaTribal
extends Area3D

## Aura de Fúria Tribal do Capitão Goblin (M5.4)
## Concede +25% de dano físico (attack_power) a todos os aliados goblins num raio de 6.0m.
## Ao morrer o Capitão ou ao invocar deactivate_aura(), desativa imediatamente o buff de todos os aliados.
## Garante que heróis (Hero_Bodies / layer 2) NUNCA recebam o buff.

signal ally_buffed(ally: CharacterEntity)
signal ally_unbuffed(ally: CharacterEntity)
signal aura_deactivated

@export var damage_multiplier_bonus: float = 0.25
@export var aura_radius: float = 6.0
@export var source_captain: CharacterEntity = null

var _buffed_allies: Array[CharacterEntity] = []
var _is_active: bool = true

const MODIFIER_ID: String = "tribal_fury"
const STAT_NAME: String = "attack_power"


func _ready() -> void:
	_resolve_source_captain()
	_setup_collision()
	_connect_signals()


func _setup_collision() -> void:
	# Camada 3 é Enemy_Bodies (valor de máscara de bits = 4)
	monitoring = true
	monitorable = false
	if collision_mask == 0:
		collision_mask = 4

	# Sincroniza o raio de qualquer CollisionShape3D com SphereShape3D existente
	for child in get_children():
		if child is CollisionShape3D:
			var shape_3d: Shape3D = (child as CollisionShape3D).shape
			if shape_3d is SphereShape3D:
				(shape_3d as SphereShape3D).radius = aura_radius


func _resolve_source_captain() -> void:
	if source_captain != null:
		return
	var parent: Node = get_parent()
	if parent is CharacterEntity:
		source_captain = parent as CharacterEntity
	elif parent != null and parent.name == "Components" and parent.get_parent() is CharacterEntity:
		source_captain = parent.get_parent() as CharacterEntity
	elif owner is CharacterEntity:
		source_captain = owner as CharacterEntity


func _connect_signals() -> void:
	if not body_entered.is_connected(_on_body_entered):
		body_entered.connect(_on_body_entered)
	if not body_exited.is_connected(_on_body_exited):
		body_exited.connect(_on_body_exited)

	_connect_captain_death_signal()

	var bus: EventBusSingleton = _get_event_bus()
	if bus != null and not bus.entity_died.is_connected(_on_event_bus_entity_died):
		bus.entity_died.connect(_on_event_bus_entity_died)


func _connect_captain_death_signal() -> void:
	if source_captain != null and source_captain.health_component != null:
		if not source_captain.health_component.died.is_connected(_on_captain_died):
			source_captain.health_component.died.connect(_on_captain_died)


func set_source_captain(captain: CharacterEntity) -> void:
	if source_captain != null and source_captain.health_component != null:
		if source_captain.health_component.died.is_connected(_on_captain_died):
			source_captain.health_component.died.disconnect(_on_captain_died)
	source_captain = captain
	_connect_captain_death_signal()


func _on_body_entered(body: Node3D) -> void:
	if not _is_active:
		return
	var entity: CharacterEntity = _resolve_character_entity(body)
	if entity != null:
		apply_buff_to_entity(entity)


func _on_body_exited(body: Node3D) -> void:
	var entity: CharacterEntity = _resolve_character_entity(body)
	if entity != null:
		remove_buff_from_entity(entity)


func _on_captain_died(_killer: Node3D = null) -> void:
	deactivate_aura()


func _on_event_bus_entity_died(entity: Node3D, _killer: Node3D = null) -> void:
	if entity == source_captain:
		deactivate_aura()
	elif entity is CharacterEntity and _buffed_allies.has(entity as CharacterEntity):
		remove_buff_from_entity(entity as CharacterEntity)


func apply_buff_to_entity(entity: CharacterEntity) -> bool:
	if not _is_active:
		return false
	if entity == null or not is_instance_valid(entity):
		return false
	# O capitão emissor não se auto-buffa como aliado
	if entity == source_captain:
		return false
	# Garante que heróis NUNCA recebam o buff
	if entity.hero_data != null or (entity.collision_layer & 2) != 0:
		return false
	# Deve ser monstro aliado (EnemyData ou camada Enemy_Bodies)
	if entity.enemy_data == null and (entity.collision_layer & 4) == 0:
		return false
	# Entidades mortas não recebem buff
	if entity.health_component != null and not entity.health_component.is_alive:
		return false
	if _buffed_allies.has(entity):
		return false

	_buffed_allies.append(entity)

	if entity.stats_component != null:
		if entity.stats_component.has_method("add_percentage_modifier"):
			entity.stats_component.add_percentage_modifier(STAT_NAME, MODIFIER_ID, damage_multiplier_bonus)
		else:
			entity.stats_component.add_percent_modifier(STAT_NAME, MODIFIER_ID, damage_multiplier_bonus)

	ally_buffed.emit(entity)
	return true


func remove_buff_from_entity(entity: CharacterEntity) -> bool:
	if entity == null or not is_instance_valid(entity):
		return false
	if not _buffed_allies.has(entity):
		return false

	_buffed_allies.erase(entity)

	if entity.stats_component != null:
		entity.stats_component.remove_modifier(STAT_NAME, MODIFIER_ID)

	ally_unbuffed.emit(entity)
	return true


func deactivate_aura() -> void:
	if not _is_active and _buffed_allies.is_empty():
		return
	_is_active = false
	for ally in _buffed_allies:
		if is_instance_valid(ally) and ally.stats_component != null:
			ally.stats_component.remove_modifier(STAT_NAME, MODIFIER_ID)
			ally_unbuffed.emit(ally)
	_buffed_allies.clear()
	monitoring = false
	monitorable = false
	aura_deactivated.emit()


func get_buffed_allies() -> Array[CharacterEntity]:
	return _buffed_allies


func is_entity_buffed(entity: CharacterEntity) -> bool:
	return _buffed_allies.has(entity)


func _resolve_character_entity(node: Node) -> CharacterEntity:
	if node == null:
		return null
	if node is CharacterEntity:
		return node as CharacterEntity
	if node.owner is CharacterEntity:
		return node.owner as CharacterEntity
	var p: Node = node.get_parent()
	if p is CharacterEntity:
		return p as CharacterEntity
	if p != null and p.get_parent() is CharacterEntity:
		return p.get_parent() as CharacterEntity
	return null


func _get_event_bus() -> EventBusSingleton:
	var tree: SceneTree = Engine.get_main_loop() as SceneTree
	if tree != null and tree.root != null and tree.root.has_node("EventBus"):
		return tree.root.get_node("EventBus") as EventBusSingleton
	return null
