class_name DeadState
extends State


func enter() -> void:
	if actor != null:
		actor.velocity = Vector3.ZERO

		# Desativa colisão física do colisor raiz
		if actor.body_collider != null:
			actor.body_collider.set_deferred("disabled", true)
			actor.body_collider.disabled = true
		elif actor.has_node("BodyCollider"):
			var col: CollisionShape3D = actor.get_node("BodyCollider") as CollisionShape3D
			if col != null:
				col.set_deferred("disabled", true)
				col.disabled = true

		# Desativa detecção e colisão da Hurtbox3D
		if actor.hurtbox != null:
			actor.hurtbox.set_deferred("monitoring", false)
			actor.hurtbox.set_deferred("monitorable", false)
			actor.hurtbox.monitoring = false
			actor.hurtbox.monitorable = false
			for child in actor.hurtbox.get_children():
				if child is CollisionShape3D:
					child.set_deferred("disabled", true)
					child.disabled = true
		elif actor.has_node("Components/Hurtbox3D"):
			var hurtbox: Hurtbox3D = actor.get_node("Components/Hurtbox3D") as Hurtbox3D
			if hurtbox != null:
				hurtbox.set_deferred("monitoring", false)
				hurtbox.set_deferred("monitorable", false)
				hurtbox.monitoring = false
				hurtbox.monitorable = false
				for child in hurtbox.get_children():
					if child is CollisionShape3D:
						child.set_deferred("disabled", true)
						child.disabled = true


func physics_update(_delta: float) -> void:
	if actor != null:
		actor.velocity = Vector3.ZERO
