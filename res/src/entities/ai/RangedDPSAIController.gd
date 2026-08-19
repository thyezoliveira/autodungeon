class_name RangedDPSAIController
extends Node

## Controlador de IA Tática da DPS Ranged — Elysia & Algoritmo de Kiting (M4.5)
## Opera em longo alcance (safe_distance = 6.0m). Se um monstro se aproximar a menos de 2.5m,
## ativa o algoritmo de kiting autônomo, calcula o vetor de fuga oposto ao monstro,
## ajusta multiplicador de velocidade para 1.15x e recua disparando tiros de oportunidade.
## Ao restabelecer a distância segura (6.0m), desativa o kiting, para o movimento,
## foca no inimigo com menor HP e dispara Multishot ou Flecha Precisa.

signal kiting_started(threat_enemy: CharacterEntity)
signal kiting_ended()
signal arrow_shot_executed(target: CharacterEntity)
signal multishot_executed(targets: Array[CharacterEntity])

@export var actor: CharacterEntity = null
@export var arrow_shot_skill: SkillData = null
@export var multishot_skill: SkillData = null
@export var safe_distance: float = 6.0
@export var kiting_trigger_distance: float = 2.5
@export var kiting_speed_multiplier: float = 1.15

var is_kiting: bool = false

const DEFAULT_ARROW_SHOT_SKILL_PATH: String = "res://src/data/skills/resources/elysia_arrow_shot.tres"
const FALLBACK_ARROW_SHOT_PATH: String = "res://src/data/skills/resources/elysia_aimed_shot.tres"
const DEFAULT_MULTISHOT_SKILL_PATH: String = "res://src/data/skills/resources/elysia_multishot.tres"
const FALLBACK_MULTISHOT_PATH: String = "res://src/data/skills/resources/elysia_arrow_rain.tres"


func _ready() -> void:
	_resolve_actor()
	_load_default_skills_if_needed()


## Avalia o ciclo tático de combate em tempo real para a DPS Ranged.
## 1. Filtra inimigos vivos no pack. Se nenhum, encerra locomoção/kiting.
## 2. Encontra o inimigo mais próximo e a distância no plano XZ.
## 3. Algoritmo de Kiting: se dist < 2.5m, ativa kiting e recua a 1.15x de velocidade,
##    com tiros de oportunidade se prontos. Ao atingir >= 6.0m, desativa kiting e para.
## 4. Combate em Distância Segura: foca no inimigo com menor HP e dispara multishot ou arrow_shot.
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
		if is_kiting:
			is_kiting = false
			kiting_ended.emit()
		if actor.movement_component != null:
			actor.movement_component.set_speed_multiplier(1.0)
			if actor.movement_component.is_moving:
				actor.movement_component.stop_movement()
		return

	# 2. Encontra o inimigo mais próximo e calcula a distância euclidiana no plano XZ
	var closest_enemy: CharacterEntity = find_nearest_enemy(living_enemies)
	if closest_enemy == null:
		return

	var dist_to_closest: float = get_distance_to_target(closest_enemy)

	# 3. Algoritmo de Kiting
	if not is_kiting and dist_to_closest < kiting_trigger_distance:
		is_kiting = true
		kiting_started.emit(closest_enemy)

	if is_kiting:
		if dist_to_closest >= safe_distance:
			is_kiting = false
			if actor.movement_component != null:
				actor.movement_component.set_speed_multiplier(1.0)
				if actor.movement_component.is_moving:
					actor.movement_component.stop_movement()
			kiting_ended.emit()
		else:
			# Vetor de fuga na direção oposta ao monstro mais próximo
			var flee_dir: Vector3 = calculate_flee_direction(closest_enemy)
			var actor_pos: Vector3 = _get_entity_position(actor)
			var flee_step: float = maxf(safe_distance - dist_to_closest + 1.0, 2.0)
			var flee_destination: Vector3 = actor_pos + (flee_dir * flee_step)

			if actor.movement_component != null:
				actor.movement_component.set_speed_multiplier(kiting_speed_multiplier)
				actor.movement_component.move_towards(flee_destination)
				actor.movement_component.process_movement(delta)

			# Disparo de oportunidade durante kiting se skill estiver pronta
			if can_cast_arrow_shot():
				var opp_target: CharacterEntity = find_lowest_hp_enemy(living_enemies)
				if opp_target == null:
					opp_target = closest_enemy
				execute_arrow_shot(opp_target)

			return

	# 4. Combate em Distância Segura (ou fora do limiar de perigo de kiting)
	if actor.movement_component != null:
		actor.movement_component.set_speed_multiplier(1.0)
		if actor.movement_component.is_moving:
			actor.movement_component.stop_movement()

	# Foca no inimigo vivo com menor HP
	var target: CharacterEntity = find_lowest_hp_enemy(living_enemies)
	if target == null:
		target = closest_enemy

	# Orientação em direção ao alvo no plano XZ
	_orient_towards(_get_entity_position(target), delta)

	# Prioridade de habilidades: Multishot se múltiplos alvos e pronta; senão Flecha Simples
	if living_enemies.size() > 1 and can_cast_multishot():
		execute_multishot(living_enemies)
	elif can_cast_arrow_shot():
		execute_arrow_shot(target)


## Retorna array contendo apenas os inimigos válidos e vivos.
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


## Encontra o inimigo vivo com o menor valor de HP atual.
func find_lowest_hp_enemy(living_enemies: Array[CharacterEntity]) -> CharacterEntity:
	if living_enemies.is_empty():
		return null

	var lowest_enemy: CharacterEntity = null
	var min_hp: int = 999999999

	for enemy: CharacterEntity in living_enemies:
		if enemy == null or not is_instance_valid(enemy):
			continue
		var hp: int = 999999999
		if enemy.health_component != null:
			hp = enemy.health_component.current_hp
		if hp < min_hp:
			min_hp = hp
			lowest_enemy = enemy

	return lowest_enemy


## Retorna a distância euclidiana no plano XZ entre o ator e o alvo.
func get_distance_to_target(target: CharacterEntity) -> float:
	if actor == null or target == null or not is_instance_valid(target):
		return INF
	var actor_pos: Vector3 = _get_entity_position(actor)
	var target_pos: Vector3 = _get_entity_position(target)
	var diff: Vector3 = Vector3(target_pos.x - actor_pos.x, 0.0, target_pos.z - actor_pos.z)
	return diff.length()


## Calcula o vetor unitário de fuga oposto à posição do inimigo ameaçador no plano XZ.
func calculate_flee_direction(threat_enemy: CharacterEntity) -> Vector3:
	if actor == null or threat_enemy == null or not is_instance_valid(threat_enemy):
		return Vector3(0.0, 0.0, 1.0)
	var actor_pos: Vector3 = _get_entity_position(actor)
	var threat_pos: Vector3 = _get_entity_position(threat_enemy)
	var flee_vec: Vector3 = Vector3(actor_pos.x - threat_pos.x, 0.0, actor_pos.z - threat_pos.z)
	if flee_vec.length_squared() < 0.0001:
		return Vector3(0.0, 0.0, 1.0)
	return flee_vec.normalized()


## Retorna se o disparo de flecha pode ser conjurado.
func can_cast_arrow_shot() -> bool:
	if arrow_shot_skill == null:
		return false
	if actor != null and actor.skill_holder != null:
		return actor.skill_holder.can_cast_skill(arrow_shot_skill)
	return true


## Retorna se a habilidade multishot pode ser conjurada.
func can_cast_multishot() -> bool:
	if multishot_skill == null:
		return false
	if actor != null and actor.skill_holder != null:
		return actor.skill_holder.can_cast_skill(multishot_skill)
	return true


## Executa o disparo de flecha: aplica dano ao alvo, gera threat e emite sinal.
func execute_arrow_shot(target: CharacterEntity) -> bool:
	if target == null or not is_instance_valid(target):
		return false
	if not can_cast_arrow_shot():
		return false

	if actor != null and actor.skill_holder != null and arrow_shot_skill != null:
		actor.skill_holder.execute_skill(arrow_shot_skill, target)

	var base_dmg: float = 25.0
	var threat_mult: float = 1.0
	if arrow_shot_skill != null and not arrow_shot_skill.effects.is_empty():
		var eff: SkillEffect = arrow_shot_skill.effects[0]
		base_dmg = float(eff.value_base)
		if eff is DamageSkillEffect:
			threat_mult = (eff as DamageSkillEffect).threat_multiplier

	if target.threat_table != null and actor != null:
		target.threat_table.add_threat(actor, base_dmg, threat_mult)

	if target.health_component != null and actor != null:
		target.health_component.take_damage(int(base_dmg), 0, actor)

	arrow_shot_executed.emit(target)
	return true


## Executa a habilidade Multishot atingindo múltiplos inimigos no pack.
func execute_multishot(targets: Array[CharacterEntity]) -> bool:
	if targets.is_empty():
		return false
	if not can_cast_multishot():
		return false

	var primary: CharacterEntity = targets[0]
	if actor != null and actor.skill_holder != null and multishot_skill != null:
		actor.skill_holder.execute_skill(multishot_skill, primary)

	var base_dmg: float = 20.0
	var threat_mult: float = 1.0
	if multishot_skill != null and not multishot_skill.effects.is_empty():
		var eff: SkillEffect = multishot_skill.effects[0]
		base_dmg = float(eff.value_base)
		if eff is DamageSkillEffect:
			threat_mult = (eff as DamageSkillEffect).threat_multiplier

	var affected_targets: Array[CharacterEntity] = []
	for enemy: CharacterEntity in targets:
		if enemy != null and is_instance_valid(enemy):
			if enemy.health_component == null or enemy.health_component.is_alive:
				if enemy.threat_table != null and actor != null:
					enemy.threat_table.add_threat(actor, base_dmg, threat_mult)
				if enemy.health_component != null and actor != null:
					enemy.health_component.take_damage(int(base_dmg), 0, actor)
				affected_targets.append(enemy)

	multishot_executed.emit(affected_targets)
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


var _skills_loaded: bool = false


func _load_default_skills_if_needed() -> void:
	if _skills_loaded:
		_ensure_skills_equipped()
		return
	_skills_loaded = true

	if arrow_shot_skill == null:
		if ResourceLoader.exists(DEFAULT_ARROW_SHOT_SKILL_PATH):
			arrow_shot_skill = ResourceLoader.load(DEFAULT_ARROW_SHOT_SKILL_PATH) as SkillData
		elif ResourceLoader.exists(FALLBACK_ARROW_SHOT_PATH):
			arrow_shot_skill = ResourceLoader.load(FALLBACK_ARROW_SHOT_PATH) as SkillData

	if multishot_skill == null:
		if ResourceLoader.exists(DEFAULT_MULTISHOT_SKILL_PATH):
			multishot_skill = ResourceLoader.load(DEFAULT_MULTISHOT_SKILL_PATH) as SkillData
		elif ResourceLoader.exists(FALLBACK_MULTISHOT_PATH):
			multishot_skill = ResourceLoader.load(FALLBACK_MULTISHOT_PATH) as SkillData

	_ensure_skills_equipped()


func _ensure_skills_equipped() -> void:
	if actor != null and actor.skill_holder != null:
		if arrow_shot_skill != null and not actor.skill_holder.has_skill(arrow_shot_skill.id):
			actor.skill_holder.equip_skill(arrow_shot_skill)
		if multishot_skill != null and not actor.skill_holder.has_skill(multishot_skill.id):
			actor.skill_holder.equip_skill(multishot_skill)
