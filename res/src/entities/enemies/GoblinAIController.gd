class_name GoblinAIController
extends Node

## Controlador de Inteligência Artificial para Goblins Comuns (M5.2)
## Suporta comportamentos Melee (Goblin Guerreiro) e Ranged (Goblin Arqueiro).
## Melee: persegue o alvo prioritário da ThreatTable até attack_range (1.8m) e desfere ataques físicos.
## Ranged: mantém distância de combate (~5.0m), recua se < 3.5m, avança se > 6.5m e dispara flechas físicas com ArrowProjectile.

signal attack_executed(target: CharacterEntity)
signal melee_attack_executed(target: CharacterEntity)
signal ranged_shot_executed(target: CharacterEntity)
signal arrow_spawned(projectile: ArrowProjectile)

@export var actor: CharacterEntity = null
@export var is_ranged: bool = false
@export var attack_range: float = 1.8
@export var attack_cooldown: float = 1.5
@export var arrow_scene: PackedScene = null

var _attack_timer: float = 0.0

const DEFAULT_ARROW_SCENE_PATH: String = "res://src/entities/projectiles/ArrowProjectile.tscn"


func _ready() -> void:
	_resolve_actor()
	if is_ranged and attack_range <= 1.8:
		attack_range = 5.0
	if is_ranged and arrow_scene == null:
		if ResourceLoader.exists(DEFAULT_ARROW_SCENE_PATH):
			arrow_scene = ResourceLoader.load(DEFAULT_ARROW_SCENE_PATH) as PackedScene


func process_ai(delta: float, party_heroes: Array[CharacterEntity]) -> void:
	if actor == null:
		_resolve_actor()
	if actor == null:
		return

	if actor.health_component != null and not actor.health_component.is_alive:
		if actor.movement_component != null and actor.movement_component.is_moving:
			actor.movement_component.stop_movement()
		return

	if _attack_timer > 0.0:
		_attack_timer = maxf(0.0, _attack_timer - delta)

	var living_heroes: Array[CharacterEntity] = get_living_heroes(party_heroes)
	if living_heroes.is_empty():
		if actor.movement_component != null and actor.movement_component.is_moving:
			actor.movement_component.stop_movement()
		return

	# 1. Consulta o alvo primário na ThreatTable do ator ou herói vivo mais próximo
	var target: CharacterEntity = null
	if actor.threat_table != null and actor.threat_table.primary_target != null:
		var candidate: CharacterEntity = actor.threat_table.primary_target
		if is_instance_valid(candidate) and (candidate.health_component == null or candidate.health_component.is_alive):
			target = candidate

	if target == null:
		target = find_nearest_hero(living_heroes)

	if target == null:
		if actor.movement_component != null and actor.movement_component.is_moving:
			actor.movement_component.stop_movement()
		return

	var actor_pos: Vector3 = _get_entity_position(actor)
	var target_pos: Vector3 = _get_entity_position(target)
	var diff: Vector3 = Vector3(target_pos.x - actor_pos.x, 0.0, target_pos.z - actor_pos.z)
	var dist: float = diff.length()

	# 2. Comportamento Ranged (Goblin Arqueiro)
	if is_ranged:
		_orient_towards(target_pos, delta)

		if dist < 3.5:
			# Recua / kiting se o herói se aproximar demais
			var flee_dir: Vector3 = calculate_flee_direction(target)
			var flee_step: float = maxf(5.0 - dist + 1.0, 2.0)
			var flee_destination: Vector3 = actor_pos + (flee_dir * flee_step)

			if actor.movement_component != null:
				actor.movement_component.move_towards(flee_destination)
				actor.movement_component.process_movement(delta)
		elif dist > 6.5:
			# Avança se o herói estiver fora do alcance de tiro
			if actor.movement_component != null:
				actor.movement_component.move_towards(target_pos)
				actor.movement_component.process_movement(delta)
		else:
			# Distância ideal de combate mantida (~5.0m)
			if actor.movement_component != null and actor.movement_component.is_moving:
				actor.movement_component.stop_movement()

		# Dispara flecha quando o cooldown estiver pronto
		if _attack_timer <= 0.0 and dist <= 8.0:
			execute_ranged_attack(target)
			_attack_timer = attack_cooldown

	# 3. Comportamento Melee (Goblin Guerreiro)
	else:
		if dist > attack_range:
			# Persegue o alvo até distância <= attack_range
			if actor.movement_component != null:
				actor.movement_component.move_towards(target_pos)
				actor.movement_component.process_movement(delta)
		else:
			# Para locomoção e golpeia
			if actor.movement_component != null and actor.movement_component.is_moving:
				actor.movement_component.stop_movement()

			_orient_towards(target_pos, delta)

			if _attack_timer <= 0.0:
				execute_melee_attack(target)
				_attack_timer = attack_cooldown


func execute_melee_attack(target: CharacterEntity) -> bool:
	if target == null or not is_instance_valid(target):
		return false

	var base_dmg: int = 8
	if actor != null:
		if actor.stats_component != null:
			base_dmg = int(actor.stats_component.get_stat("attack_power"))
		elif actor.enemy_data != null:
			base_dmg = actor.enemy_data.attack_power

	var target_armor: int = 0
	if target.stats_component != null:
		target_armor = int(target.stats_component.get_stat("armor"))

	if target.health_component != null:
		target.health_component.take_damage(base_dmg, target_armor, actor)

	melee_attack_executed.emit(target)
	attack_executed.emit(target)
	return true


func execute_ranged_attack(target: CharacterEntity) -> bool:
	if target == null or not is_instance_valid(target):
		return false

	var base_dmg: int = 7
	if actor != null:
		if actor.stats_component != null:
			base_dmg = int(actor.stats_component.get_stat("attack_power"))
		elif actor.enemy_data != null:
			base_dmg = actor.enemy_data.attack_power

	_spawn_arrow_projectile(target, base_dmg)

	ranged_shot_executed.emit(target)
	attack_executed.emit(target)
	return true


func _spawn_arrow_projectile(target: CharacterEntity, dmg: int) -> void:
	if arrow_scene == null:
		if ResourceLoader.exists(DEFAULT_ARROW_SCENE_PATH):
			arrow_scene = ResourceLoader.load(DEFAULT_ARROW_SCENE_PATH) as PackedScene

	if arrow_scene == null:
		# Fallback direto caso cena de projétil não esteja presente
		var target_armor: int = 0
		if target.stats_component != null:
			target_armor = int(target.stats_component.get_stat("armor"))
		if target.health_component != null:
			target.health_component.take_damage(dmg, target_armor, actor)
		return

	var proj_inst: Node = arrow_scene.instantiate()
	if proj_inst == null:
		return

	var projectile: ArrowProjectile = proj_inst as ArrowProjectile
	var actor_pos: Vector3 = _get_entity_position(actor)
	var target_pos: Vector3 = _get_entity_position(target)

	var spawn_pos: Vector3 = actor_pos + Vector3(0.0, 0.9, 0.0)
	var aim_pos: Vector3 = target_pos + Vector3(0.0, 0.9, 0.0)
	var shoot_dir: Vector3 = aim_pos - spawn_pos
	shoot_dir.y = 0.0
	if shoot_dir.length_squared() < 0.0001:
		shoot_dir = Vector3.FORWARD
	else:
		shoot_dir = shoot_dir.normalized()

	# Adiciona à árvore da cena
	var spawn_parent: Node = null
	if actor != null and actor.is_inside_tree() and actor.get_parent() != null:
		spawn_parent = actor.get_parent()
	elif is_inside_tree() and get_tree() != null and get_tree().root != null:
		spawn_parent = get_tree().root

	if spawn_parent != null:
		spawn_parent.add_child(proj_inst)

	if projectile != null:
		projectile.global_position = spawn_pos
		projectile.setup(dmg, 14.0, actor, 3.0)
		projectile.launch(shoot_dir)
		arrow_spawned.emit(projectile)
	elif proj_inst is Node3D:
		(proj_inst as Node3D).global_position = spawn_pos


func get_living_heroes(party_heroes: Array[CharacterEntity]) -> Array[CharacterEntity]:
	var result: Array[CharacterEntity] = []
	for hero in party_heroes:
		if hero != null and is_instance_valid(hero):
			if hero.health_component == null or (hero.health_component.is_alive and hero.health_component.current_hp > 0):
				result.append(hero)
	return result


func find_nearest_hero(living_heroes: Array[CharacterEntity]) -> CharacterEntity:
	if living_heroes.is_empty() or actor == null:
		return null

	var nearest: CharacterEntity = null
	var min_dist_sq: float = INF
	var actor_pos: Vector3 = _get_entity_position(actor)

	for hero in living_heroes:
		if hero == null or not is_instance_valid(hero):
			continue
		var hero_pos: Vector3 = _get_entity_position(hero)
		var diff: Vector3 = Vector3(hero_pos.x - actor_pos.x, 0.0, hero_pos.z - actor_pos.z)
		var dist_sq: float = diff.length_squared()
		if dist_sq < min_dist_sq:
			min_dist_sq = dist_sq
			nearest = hero

	return nearest


func get_distance_to_target(target: CharacterEntity) -> float:
	if actor == null or target == null or not is_instance_valid(target):
		return INF
	var actor_pos: Vector3 = _get_entity_position(actor)
	var target_pos: Vector3 = _get_entity_position(target)
	var diff: Vector3 = Vector3(target_pos.x - actor_pos.x, 0.0, target_pos.z - actor_pos.z)
	return diff.length()


func calculate_flee_direction(threat: CharacterEntity) -> Vector3:
	if actor == null or threat == null or not is_instance_valid(threat):
		return Vector3(0.0, 0.0, 1.0)
	var actor_pos: Vector3 = _get_entity_position(actor)
	var threat_pos: Vector3 = _get_entity_position(threat)
	var flee_vec: Vector3 = Vector3(actor_pos.x - threat_pos.x, 0.0, actor_pos.z - threat_pos.z)
	if flee_vec.length_squared() < 0.0001:
		return Vector3(0.0, 0.0, 1.0)
	return flee_vec.normalized()


func _orient_towards(target_pos: Vector3, delta: float) -> void:
	if actor == null:
		return
	var actor_pos: Vector3 = _get_entity_position(actor)
	var diff: Vector3 = Vector3(target_pos.x - actor_pos.x, 0.0, target_pos.z - actor_pos.z)
	if diff.length_squared() > 0.001:
		var target_angle: float = atan2(diff.x, diff.z)
		actor.rotation.y = lerp_angle(actor.rotation.y, target_angle, clampf(8.0 * delta, 0.0, 1.0))


func _get_entity_position(entity: Node3D) -> Vector3:
	if entity == null:
		return Vector3.ZERO
	if entity.is_inside_tree():
		return entity.global_position
	return entity.position


func _resolve_actor() -> void:
	if actor != null:
		return
	var parent: Node = get_parent()
	if parent is CharacterEntity:
		actor = parent as CharacterEntity
	elif parent != null and parent.name == "Components" and parent.get_parent() is CharacterEntity:
		actor = parent.get_parent() as CharacterEntity
	elif owner is CharacterEntity:
		actor = owner as CharacterEntity
