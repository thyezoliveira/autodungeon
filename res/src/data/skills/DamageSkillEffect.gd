class_name DamageSkillEffect
extends SkillEffect

@export var is_physical: bool = true
@export var threat_multiplier: float = 1.0


func apply_effect(caster: Node3D, target: Node3D) -> void:
	# Lógica de despacho de dano desacoplado via EventBus
	pass
