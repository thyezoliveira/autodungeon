class_name Hurtbox3D
extends Area3D

signal damage_received(hitbox: Hitbox3D)

@export var health_component: HealthComponent = null
@export var stats_component: StatsComponent = null
@export var source_entity: Node3D = null


func _ready() -> void:
	if health_component == null and get_parent() != null:
		health_component = get_parent().get_node_or_null("HealthComponent") as HealthComponent
	if stats_component == null and get_parent() != null:
		stats_component = get_parent().get_node_or_null("StatsComponent") as StatsComponent
	if source_entity == null:
		source_entity = _get_source_entity()


func setup(health: HealthComponent, stats: StatsComponent = null, source: Node3D = null) -> void:
	health_component = health
	stats_component = stats
	if source != null:
		source_entity = source


func receive_hit(hitbox: Hitbox3D) -> void:
	if hitbox == null:
		return

	var defense_value: int = 0
	if stats_component != null:
		if hitbox.is_physical:
			defense_value = int(stats_component.get_stat("armor"))
		else:
			defense_value = int(stats_component.get_stat("magic_resist"))

	if health_component != null:
		health_component.take_damage(hitbox.damage, defense_value, hitbox.source_entity)

	damage_received.emit(hitbox)


func _get_source_entity() -> Node3D:
	if source_entity != null:
		return source_entity
	var parent: Node = get_parent()
	if parent is Node3D:
		if parent.name == "Components" and parent.get_parent() is Node3D:
			return parent.get_parent() as Node3D
		return parent as Node3D
	if owner is Node3D:
		return owner as Node3D
	return null
