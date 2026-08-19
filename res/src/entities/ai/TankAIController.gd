class_name TankAIController
extends Node

## Controlador de IA Tática do Tanque — Bromm (M4.4)
## Gerencia o engajamento tático, avanço agressivo no inimigo mais próximo,
## lançamento de Investida e Golpe de Escudo com geração de alta ameaça (threat/aggro)
## e ativação reativa de Postura Defensiva (+20 armadura) quando HP < 60%.

signal charge_executed(target: CharacterEntity)
signal defensive_stance_activated()
signal shield_slam_executed(target: CharacterEntity)

@export var actor: CharacterEntity = null
@export var charge_skill: SkillData = null
@export var defensive_skill: SkillData = null
@export var shield_slam_skill: SkillData = null
@export var melee_attack_range: float = 2.0
@export var defensive_hp_threshold: float = 0.60
@export var charge_min_distance: float = 3.0

const DEFAULT_CHARGE_SKILL_PATH: String = "res://src/data/skills/resources/bromm_charge.tres"
const DEFAULT_DEFENSIVE_SKILL_PATH: String = "res://src/data/skills/resources/bromm_defensive_stance.tres"
const DEFAULT_SHIELD_SLAM_SKILL_PATH: String = "res://src/data/skills/resources/bromm_shield_slam.tres"
const FALLBACK_SHIELD_SLAM_PATH: String = "res://src/data/skills/bromm_shield_slam.tres"


func _ready() -> void:
	_resolve_actor()
	_load_default_skills_if_needed()


## Avalia o ciclo tático de combate em tempo real para o tanque.
## 1. Filtra inimigos vivos no pack. Se nenhum, encerra.
## 2. Encontra o inimigo mais próximo.
## 3. Se HP < 60% e postura defensiva disponível, ativa defensive_skill.
## 4. Se fora de alcance de combate físico (> 2.0m): se investida disponível (> 3.0m), executa charge_skill; caso contrário, move-se até o alvo.
## 5. Se em alcance de combate físico (<= 2.0m): interrompe locomoção e lança shield_slam_skill gerando alto aggro no alvo.
func evaluate_combat_tactics(delta: float, enemy_pack: Array[CharacterEntity]) -> void:
	if actor == null:
		_resolve_actor()
	if actor == null:
		return

	if actor.health_component != null and not actor.health_component.is_alive:
		return

	_load_default_skills_if_needed()

	# 1. Filtra inimigos vivos no pack
	var living_enemies: Array[CharacterEntity] = get_living_enemies(enemy_pack)
	if living_enemies.is_empty():
		if actor.movement_component != null and actor.movement_component.is_moving:
			actor.movement_component.stop_movement()
		return

	# 2. Encontra o inimigo mais próximo
	var target: CharacterEntity = find_nearest_enemy(living_enemies)
	if target == null:
		return

	var dist: float = get_distance_to_target(target)

	# 3. Avaliação reativa de Postura Defensiva (HP < 60%)
	if is_defensive_hp_critical():
		execute_defensive_stance()

	# 4 & 5. Avaliação de distância e combate
	if dist > melee_attack_range:
		# Fora do alcance corpo-a-corpo
		if dist >= charge_min_distance and can_cast_charge():
			execute_charge(target)
		else:
			# Move-se até o alvo
			if actor.movement_component != null:
				actor.movement_component.move_towards(_get_entity_position(target))
				actor.movement_component.process_movement(delta)
	else:
		# Em alcance de combate físico (<= melee_attack_range)
		if actor.movement_component != null and actor.movement_component.is_moving:
			actor.movement_component.stop_movement()

		# Orientação em direção ao alvo no plano XZ
		_orient_towards(_get_entity_position(target), delta)

		# Executa Golpe de Escudo com alto aggro se disponível
		if can_cast_shield_slam():
			execute_shield_slam(target)


## Retorna array apenas com os inimigos válidos e vivos.
func get_living_enemies(enemy_pack: Array[CharacterEntity]) -> Array[CharacterEntity]:
	var result: Array[CharacterEntity] = []
	for enemy: CharacterEntity in enemy_pack:
		if enemy != null and is_instance_valid(enemy):
			if enemy.health_component == null or (enemy.health_component.is_alive and enemy.health_component.current_hp > 0):
				result.append(enemy)
	return result


## Encontra o inimigo mais próximo da posição do ator no plano XZ.
func find_nearest_enemy(living_enemies: Array[CharacterEntity]) -> CharacterEntity:
	if living_enemies.is_empty() or actor == null:
		return null

	var nearest: CharacterEntity = null
	var min_dist_sq: float = INF
	var actor_pos: Vector3 = _get_entity_position(actor)

	for enemy: CharacterEntity in living_enemies:
		if enemy == null or not is_instance_valid(enemy):
			continue
		var enemy_pos: Vector3 = _get_entity_position(enemy)
		var diff: Vector3 = Vector3(enemy_pos.x - actor_pos.x, 0.0, enemy_pos.z - actor_pos.z)
		var dist_sq: float = diff.length_squared()
		if dist_sq < min_dist_sq:
			min_dist_sq = dist_sq
			nearest = enemy

	return nearest


## Retorna a distância euclidiana no plano XZ entre o ator e o alvo.
func get_distance_to_target(target: CharacterEntity) -> float:
	if actor == null or target == null or not is_instance_valid(target):
		return INF
	var actor_pos: Vector3 = _get_entity_position(actor)
	var target_pos: Vector3 = _get_entity_position(target)
	var diff: Vector3 = Vector3(target_pos.x - actor_pos.x, 0.0, target_pos.z - actor_pos.z)
	return diff.length()


## Retorna se o HP do tanque está abaixo do limiar crítico (padrão 60%).
func is_defensive_hp_critical() -> bool:
	if actor == null or actor.health_component == null:
		return false
	var max_hp: float = float(actor.health_component.max_hp)
	if max_hp <= 0.0:
		return false
	var current_hp: float = float(actor.health_component.current_hp)
	var hp_ratio: float = current_hp / max_hp
	return hp_ratio < defensive_hp_threshold


## Retorna se a habilidade de Investida pode ser conjurada.
func can_cast_charge() -> bool:
	if charge_skill == null:
		return false
	if actor != null and actor.skill_holder != null:
		return actor.skill_holder.can_cast_skill(charge_skill)
	return true


## Retorna se a Postura Defensiva pode ser ativada.
func can_cast_defensive_stance() -> bool:
	if defensive_skill == null:
		return false
	if actor != null and actor.skill_holder != null:
		return actor.skill_holder.can_cast_skill(defensive_skill)
	return true


## Retorna se o Golpe de Escudo pode ser desferido.
func can_cast_shield_slam() -> bool:
	if shield_slam_skill == null:
		return false
	if actor != null and actor.skill_holder != null:
		return actor.skill_holder.can_cast_skill(shield_slam_skill)
	return true


## Executa a habilidade Investida: desloca o ator para junto do alvo, aplica dano e gera threat.
func execute_charge(target: CharacterEntity) -> bool:
	if target == null or not is_instance_valid(target):
		return false
	if not can_cast_charge():
		return false

	if actor != null and actor.skill_holder != null and charge_skill != null:
		actor.skill_holder.execute_skill(charge_skill, target)

	# Deslocamento rápido / investida até a proximidade do alvo
	if actor != null:
		var target_pos: Vector3 = _get_entity_position(target)
		var actor_pos: Vector3 = _get_entity_position(actor)
		var diff: Vector3 = target_pos - actor_pos
		diff.y = 0.0
		var dir: Vector3 = diff.normalized()
		if dir.length_squared() < 0.0001:
			dir = Vector3.FORWARD

		# Posiciona o ator a 1.2m do alvo no vetor de aproximação
		var dest_pos: Vector3 = target_pos - (dir * 1.2)
		_set_entity_position(actor, dest_pos)

		if actor.movement_component != null:
			actor.movement_component.stop_movement()

	# Aplica dano e gera threat de investida (threat_multiplier 2.0x)
	var base_dmg: float = 18.0
	var threat_mult: float = 2.0
	if charge_skill != null and not charge_skill.effects.is_empty():
		var eff: SkillEffect = charge_skill.effects[0]
		base_dmg = float(eff.value_base)
		if eff is DamageSkillEffect:
			threat_mult = (eff as DamageSkillEffect).threat_multiplier

	if target.threat_table != null and actor != null:
		target.threat_table.add_threat(actor, base_dmg, threat_mult)

	if target.health_component != null and actor != null:
		target.health_component.take_damage(int(base_dmg), 0, actor)

	charge_executed.emit(target)
	return true


## Ativa a Postura Defensiva: concede +20 armadura temporária e emite sinal.
func execute_defensive_stance() -> bool:
	if not can_cast_defensive_stance():
		return false

	if actor != null and actor.skill_holder != null and defensive_skill != null:
		actor.skill_holder.execute_skill(defensive_skill, actor)

	# Aplica bônus de armadura no StatsComponent (+20 Armadura temporária por 6s)
	if actor != null and actor.stats_component != null:
		actor.stats_component.add_flat_modifier("armor", "bromm_defensive_stance", 20.0)
		var duration: float = 6.0
		if defensive_skill != null and not defensive_skill.effects.is_empty():
			if defensive_skill.effects[0].duration > 0.0:
				duration = defensive_skill.effects[0].duration

		var tree: SceneTree = actor.get_tree() if actor.is_inside_tree() else Engine.get_main_loop() as SceneTree
		if tree != null:
			tree.create_timer(duration).timeout.connect(func() -> void:
				if actor != null and is_instance_valid(actor) and actor.stats_component != null:
					actor.stats_component.remove_modifier("armor", "bromm_defensive_stance")
					actor.stats_component.remove_modifier("armor", "defensive_stance")
			)

	defensive_stance_activated.emit()
	return true


## Executa o Golpe de Escudo: aplica alto dano físico e gera alto valor de aggro (3.0x).
func execute_shield_slam(target: CharacterEntity) -> bool:
	if target == null or not is_instance_valid(target):
		return false
	if not can_cast_shield_slam():
		return false

	if actor != null and actor.skill_holder != null and shield_slam_skill != null:
		actor.skill_holder.execute_skill(shield_slam_skill, target)

	var base_dmg: float = 25.0
	var threat_mult: float = 3.0
	if shield_slam_skill != null and not shield_slam_skill.effects.is_empty():
		var eff: SkillEffect = shield_slam_skill.effects[0]
		base_dmg = float(eff.value_base)
		if eff is DamageSkillEffect:
			threat_mult = (eff as DamageSkillEffect).threat_multiplier

	if target.threat_table != null and actor != null:
		target.threat_table.add_threat(actor, base_dmg, threat_mult)

	if target.health_component != null and actor != null:
		target.health_component.take_damage(int(base_dmg), 0, actor)

	shield_slam_executed.emit(target)
	return true


func _orient_towards(target_pos: Vector3, delta: float) -> void:
	if actor == null:
		return
	var actor_pos: Vector3 = _get_entity_position(actor)
	var diff: Vector3 = Vector3(target_pos.x - actor_pos.x, 0.0, target_pos.z - actor_pos.z)
	if diff.length_squared() > 0.001:
		var target_angle: float = atan2(diff.x, diff.z)
		actor.rotation.y = lerp_angle(actor.rotation.y, target_angle, clampf(10.0 * delta, 0.0, 1.0))


func _get_entity_position(entity: Node3D) -> Vector3:
	if entity == null:
		return Vector3.ZERO
	if entity.is_inside_tree():
		return entity.global_position
	return entity.position


func _set_entity_position(entity: Node3D, new_pos: Vector3) -> void:
	if entity == null:
		return
	if entity.is_inside_tree():
		entity.global_position = new_pos
	else:
		entity.position = new_pos


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


func _load_default_skills_if_needed() -> void:
	if charge_skill == null:
		if ResourceLoader.exists(DEFAULT_CHARGE_SKILL_PATH):
			charge_skill = ResourceLoader.load(DEFAULT_CHARGE_SKILL_PATH) as SkillData
	if defensive_skill == null:
		if ResourceLoader.exists(DEFAULT_DEFENSIVE_SKILL_PATH):
			defensive_skill = ResourceLoader.load(DEFAULT_DEFENSIVE_SKILL_PATH) as SkillData
	if shield_slam_skill == null:
		if ResourceLoader.exists(DEFAULT_SHIELD_SLAM_SKILL_PATH):
			shield_slam_skill = ResourceLoader.load(DEFAULT_SHIELD_SLAM_SKILL_PATH) as SkillData
		elif ResourceLoader.exists(FALLBACK_SHIELD_SLAM_PATH):
			shield_slam_skill = ResourceLoader.load(FALLBACK_SHIELD_SLAM_PATH) as SkillData

	_ensure_skills_equipped()


func _ensure_skills_equipped() -> void:
	if actor != null and actor.skill_holder != null:
		if charge_skill != null and not actor.skill_holder.has_skill(charge_skill.id):
			actor.skill_holder.equip_skill(charge_skill)
		if defensive_skill != null and not actor.skill_holder.has_skill(defensive_skill.id):
			actor.skill_holder.equip_skill(defensive_skill)
		if shield_slam_skill != null and not actor.skill_holder.has_skill(shield_slam_skill.id):
			actor.skill_holder.equip_skill(shield_slam_skill)
