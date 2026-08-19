class_name HealthComponent
extends Node

signal health_changed(current_hp: int, max_hp: int)
signal mana_changed(current_mana: float, max_mana: float)
signal damage_taken(amount: int, is_blocked: bool, source: Node3D)
signal healed(amount: int, healer: Node3D)
signal died(killer: Node3D)

const ARMOR_CAP: int = 80
const MIN_DAMAGE: int = 1
const OOC_MANA_REGEN_INTERVAL: float = 2.0
const OOC_MANA_REGEN_PERCENT: float = 0.05

@export var current_hp: int = 100
@export var max_hp: int = 100
@export var current_mana: float = 50.0
@export var max_mana: float = 50.0
@export var is_alive: bool = true
@export var in_combat: bool = false

var _ooc_mana_timer: float = 0.0


func _physics_process(delta: float) -> void:
	if not in_combat and is_alive:
		_process_ooc_mana_regen(delta)


func setup(stats: StatsComponent) -> void:
	if stats == null:
		return
	max_hp = int(stats.get_stat("max_hp"))
	current_hp = max_hp
	max_mana = stats.get_stat("max_mana")
	current_mana = max_mana
	is_alive = current_hp > 0
	health_changed.emit(current_hp, max_hp)
	mana_changed.emit(current_mana, max_mana)


func take_damage(raw_damage: int, armor_value: int = 0, source: Node3D = null) -> int:
	if not is_alive or current_hp <= 0:
		return 0

	var effective_armor: int = mini(ARMOR_CAP, maxi(0, armor_value))
	var mitigated_damage: int = raw_damage - effective_armor
	var final_damage: int = maxi(MIN_DAMAGE, mitigated_damage)

	current_hp = maxi(0, current_hp - final_damage)
	var is_blocked: bool = effective_armor > 0 and final_damage < raw_damage

	health_changed.emit(current_hp, max_hp)
	damage_taken.emit(final_damage, is_blocked, source)

	var entity_node: Node3D = _get_entity()
	_emit_event_bus_damage(entity_node, source, final_damage, is_blocked)
	_emit_event_bus_health_changed(entity_node, current_hp, max_hp)

	if current_hp <= 0 and is_alive:
		is_alive = false
		died.emit(source)
		_emit_event_bus_died(entity_node, source)

	return final_damage


func heal(amount: int, healer: Node3D = null) -> int:
	if not is_alive or current_hp <= 0 or amount <= 0:
		return 0

	var prev_hp: int = current_hp
	current_hp = mini(max_hp, current_hp + amount)
	var actual_healed: int = current_hp - prev_hp

	if actual_healed > 0:
		health_changed.emit(current_hp, max_hp)
		healed.emit(actual_healed, healer)
		var entity_node: Node3D = _get_entity()
		_emit_event_bus_healing(entity_node, healer, actual_healed)
		_emit_event_bus_health_changed(entity_node, current_hp, max_hp)

	return actual_healed


func consume_mana(amount: float) -> bool:
	if not is_alive or amount <= 0.0:
		return false

	if current_mana >= amount:
		current_mana -= amount
		mana_changed.emit(current_mana, max_mana)
		var entity_node: Node3D = _get_entity()
		_emit_event_bus_mana_changed(entity_node, current_mana, max_mana)
		return true

	return false


func restore_mana(amount: float) -> float:
	if not is_alive or amount <= 0.0 or current_mana >= max_mana:
		return 0.0

	var prev_mana: float = current_mana
	current_mana = minf(max_mana, current_mana + amount)
	var actual_restored: float = current_mana - prev_mana

	if actual_restored > 0.0:
		mana_changed.emit(current_mana, max_mana)
		var entity_node: Node3D = _get_entity()
		_emit_event_bus_mana_changed(entity_node, current_mana, max_mana)

	return actual_restored


func set_in_combat(value: bool) -> void:
	in_combat = value
	if in_combat:
		_ooc_mana_timer = 0.0


func _process_ooc_mana_regen(delta: float) -> void:
	if current_mana >= max_mana or max_mana <= 0.0:
		_ooc_mana_timer = 0.0
		return

	_ooc_mana_timer += delta
	while _ooc_mana_timer >= OOC_MANA_REGEN_INTERVAL:
		_ooc_mana_timer -= OOC_MANA_REGEN_INTERVAL
		var regen_amount: float = max_mana * OOC_MANA_REGEN_PERCENT
		restore_mana(regen_amount)
		if current_mana >= max_mana:
			_ooc_mana_timer = 0.0
			break


func _get_entity() -> Node3D:
	var parent: Node = get_parent()
	if parent is Node3D:
		if parent.name == "Components" and parent.get_parent() is Node3D:
			return parent.get_parent() as Node3D
		return parent as Node3D
	if owner is Node3D:
		return owner as Node3D
	return null


func _get_event_bus() -> EventBusSingleton:
	var tree: SceneTree = Engine.get_main_loop() as SceneTree
	if tree != null and tree.root != null and tree.root.has_node("EventBus"):
		return tree.root.get_node("EventBus") as EventBusSingleton
	return null


func _emit_event_bus_damage(target: Node3D, source: Node3D, amount: int, is_blocked: bool) -> void:
	var bus: EventBusSingleton = _get_event_bus()
	if bus != null:
		bus.damage_dealt.emit(target, source, amount, false, is_blocked)


func _emit_event_bus_healing(target: Node3D, healer: Node3D, amount: int) -> void:
	var bus: EventBusSingleton = _get_event_bus()
	if bus != null:
		bus.healing_applied.emit(target, healer, amount)


func _emit_event_bus_died(entity: Node3D, killer: Node3D) -> void:
	var bus: EventBusSingleton = _get_event_bus()
	if bus != null:
		bus.entity_died.emit(entity, killer)


func _emit_event_bus_health_changed(entity: Node3D, hp: int, max_hp_val: int) -> void:
	var bus: EventBusSingleton = _get_event_bus()
	if bus != null:
		bus.health_changed.emit(entity, hp, max_hp_val)


func _emit_event_bus_mana_changed(entity: Node3D, mana: float, max_mana_val: float) -> void:
	var bus: EventBusSingleton = _get_event_bus()
	if bus != null:
		bus.mana_changed.emit(entity, mana, max_mana_val)
