class_name Hitbox3D
extends Area3D

@export var damage: int = 10
@export var is_physical: bool = true
@export var is_critical: bool = false
@export var source_entity: Node3D = null


func _ready() -> void:
	if not area_entered.is_connected(_on_area_entered):
		area_entered.connect(_on_area_entered)
	if source_entity == null:
		source_entity = _get_source_entity()


func setup(dmg: int = 10, physical: bool = true, crit: bool = false, source: Node3D = null) -> void:
	damage = dmg
	is_physical = physical
	is_critical = crit
	if source != null:
		source_entity = source


func _on_area_entered(area: Area3D) -> void:
	if not (area is Hurtbox3D):
		return

	var hurtbox: Hurtbox3D = area as Hurtbox3D
	if _is_same_entity(hurtbox):
		return

	hurtbox.receive_hit(self)


func _is_same_entity(hurtbox: Hurtbox3D) -> bool:
	if hurtbox == self:
		return true

	var my_source: Node3D = source_entity if source_entity != null else _get_source_entity()
	var target_source: Node3D = hurtbox.source_entity if hurtbox.source_entity != null else hurtbox._get_source_entity()

	if my_source != null and target_source != null:
		return my_source == target_source

	if my_source != null:
		if hurtbox == my_source or hurtbox.owner == my_source or hurtbox.get_parent() == my_source:
			return true
		if hurtbox.get_parent() != null and hurtbox.get_parent().get_parent() == my_source:
			return true

	if target_source != null:
		if self == target_source or owner == target_source or get_parent() == target_source:
			return true
		if get_parent() != null and get_parent().get_parent() == target_source:
			return true

	return false


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
