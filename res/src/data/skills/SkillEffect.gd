class_name SkillEffect
extends Resource

enum TargetType { ENEMY_SINGLE, ENEMY_AREA, ALLY_SINGLE, ALLY_LOWEST_HP, ALLY_ALL, SELF }

@export var target_type: TargetType = TargetType.ENEMY_SINGLE
@export var value_base: int = 10
@export var stat_scaling_factor: float = 0.5
@export var duration: float = 0.0


func apply_effect(caster: Node3D, target: Node3D) -> void:
	# Método virtual a ser sobrescrito por efeitos concretos (Damage, Heal, Buff, etc.)
	pass
