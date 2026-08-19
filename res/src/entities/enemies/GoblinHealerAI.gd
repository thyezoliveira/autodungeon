class_name GoblinHealerAI
extends Node

## Controlador de Inteligência Artificial para o Goblin Curandeiro (M5.3)
## Suporte monstruoso que atua na retaguarda (~6.0m dos heróis).
## Monitora a vida dos aliados da sala (pack_allies) e conjura Bênção Tribal quando HP < 50%.
## Prioriza o aliado com menor percentual de vida e desempata favorecendo Capitão / Elites.
## Mantém distância recuada dos heróis (recua se heróis se aproximarem a < 4.0m).

signal heal_started(target: CharacterEntity, amount: int)
signal heal_executed(target: CharacterEntity, amount: int)

@export var actor: CharacterEntity = null
@export var heal_skill: SkillData = null
@export var heal_threshold: float = 0.50
@export var heal_amount: int = 25
@export var heal_cooldown: float = 4.0
@export var keep_distance: float = 6.0

const DEFAULT_HEAL_SKILL_PATH: String = "res://src/data/skills/resources/goblin_tribal_blessing.tres"

var _heal_timer: float = 0.0
var _skill_loaded: bool = false


func _ready() -> void:
	_resolve_actor()
	_load_default_skill_if_needed()


func _physics_process(delta: float) -> void:
	if _heal_timer > 0.0:
		_heal_timer = maxf(0.0, _heal_timer - delta)


## Ciclo principal de IA invocado a cada frame de combate da sala.
## Atualiza cooldowns, tenta curar aliados prioritários e mantém distância tática dos heróis.
func process_ai(delta: float, pack_allies: Array[CharacterEntity], party_heroes: Array[CharacterEntity]) -> void:
	if actor == null:
		_resolve_actor()
	if actor == null:
		return

	if actor.health_component != null and not actor.health_component.is_alive:
		if actor.movement_component != null and actor.movement_component.is_moving:
			actor.movement_component.stop_movement()
		return

	_load_default_skill_if_needed()

	if _heal_timer > 0.0:
		_heal_timer = maxf(0.0, _heal_timer - delta)

	# 1. Avalia e executa cura em aliados feridos prioritários (HP < 50%)
	evaluate_healing(pack_allies)

	# 2. Posicionamento tático e manutenção de distância em relação aos heróis
	var living_heroes: Array[CharacterEntity] = get_living_heroes(party_heroes)
	if living_heroes.is_empty():
		if actor.movement_component != null and actor.movement_component.is_moving:
			actor.movement_component.stop_movement()
		return

	var nearest_hero: CharacterEntity = find_nearest_hero(living_heroes)
	if nearest_hero == null:
		if actor.movement_component != null and actor.movement_component.is_moving:
			actor.movement_component.stop_movement()
		return

	var actor_pos: Vector3 = _get_entity_position(actor)
	var hero_pos: Vector3 = _get_entity_position(nearest_hero)
	var diff: Vector3 = Vector3(hero_pos.x - actor_pos.x, 0.0, hero_pos.z - actor_pos.z)
	var dist: float = diff.length()

	_orient_towards(hero_pos, delta)

	if dist < 4.0:
		# Heróis muito próximos (< 4.0m): curandeiro recua (kiting) para distância segura (~6.0m)
		var flee_dir: Vector3 = calculate_flee_direction(nearest_hero)
		var flee_step: float = maxf(keep_distance - dist + 1.0, 2.5)
		var flee_destination: Vector3 = actor_pos + (flee_dir * flee_step)

		if actor.movement_component != null:
			actor.movement_component.move_towards(flee_destination)
			actor.movement_component.process_movement(delta)
	elif dist > 8.0:
		# Fora do raio de suporte (> 8.0m): avança para alcançar a zona de combate
		if actor.movement_component != null:
			actor.movement_component.move_towards(hero_pos)
			actor.movement_component.process_movement(delta)
	else:
		# Distância ideal de retaguarda mantida (~4.0m a ~8.0m, meta 6.0m)
		if actor.movement_component != null and actor.movement_component.is_moving:
			actor.movement_component.stop_movement()


## Avalia a lista de monstros aliados e cura o alvo vivo com menor HP% abaixo do limiar (50%).
## Desempata priorizando Capitão / monstros de tier Elite/Boss.
func evaluate_healing(pack_allies: Array[CharacterEntity]) -> void:
	if not can_cast_heal():
		return

	var target: CharacterEntity = find_best_heal_target(pack_allies)
	if target != null:
		execute_heal(target)


## Encontra o melhor alvo para cura: aliado vivo com HP < heal_threshold (50%),
## menor razão de HP e preferência por Capitão/Elite em empates.
func find_best_heal_target(pack_allies: Array[CharacterEntity]) -> CharacterEntity:
	var living_allies: Array[CharacterEntity] = get_living_allies(pack_allies)
	if living_allies.is_empty():
		return null

	var best_target: CharacterEntity = null
	var lowest_ratio: float = 1.0

	for ally: CharacterEntity in living_allies:
		if ally == null or not is_instance_valid(ally):
			continue
		if ally.health_component == null:
			continue

		var ratio: float = get_hp_ratio(ally)
		if ratio >= heal_threshold:
			continue

		if best_target == null:
			best_target = ally
			lowest_ratio = ratio
		elif is_equal_approx(ratio, lowest_ratio):
			# Desempate: prioriza Capitão / Elite / Boss
			if is_elite_or_captain(ally) and not is_elite_or_captain(best_target):
				best_target = ally
				lowest_ratio = ratio
		elif ratio < lowest_ratio:
			best_target = ally
			lowest_ratio = ratio

	return best_target


## Executa o feitiço de cura no alvo especificado, consumindo cooldown e emitindo sinais.
func execute_heal(target: CharacterEntity) -> bool:
	if target == null or not is_instance_valid(target):
		return false
	if not can_cast_heal():
		return false

	var amount_to_heal: int = heal_amount
	if heal_skill != null and not heal_skill.effects.is_empty():
		amount_to_heal = heal_skill.effects[0].value_base

	_heal_timer = heal_cooldown

	if actor != null and actor.skill_holder != null and heal_skill != null:
		actor.skill_holder.execute_skill(heal_skill, target)

	heal_started.emit(target, amount_to_heal)

	if target.health_component != null:
		target.health_component.heal(amount_to_heal, actor)

	heal_executed.emit(target, amount_to_heal)
	return true


## Retorna true se a habilidade de cura puder ser conjurada.
func can_cast_heal() -> bool:
	if _heal_timer > 0.0:
		return false

	if actor != null and actor.health_component != null and not actor.health_component.is_alive:
		return false

	if actor != null and actor.skill_holder != null and heal_skill != null:
		return actor.skill_holder.can_cast_skill(heal_skill)

	return true


## Retorna a razão normalizada de HP (0.0 a 1.0) da entidade.
func get_hp_ratio(entity: CharacterEntity) -> float:
	if entity == null or not is_instance_valid(entity):
		return 1.0
	if entity.health_component == null:
		return 1.0
	var max_hp_val: float = float(entity.health_component.max_hp)
	if max_hp_val <= 0.0:
		return 0.0
	return clampf(float(entity.health_component.current_hp) / max_hp_val, 0.0, 1.0)


## Identifica se a entidade é um Capitão ou possui tier Elite/Boss.
func is_elite_or_captain(entity: CharacterEntity) -> bool:
	if entity == null or not is_instance_valid(entity):
		return false

	if entity.enemy_data != null and entity.enemy_data.tier != EnemyData.EnemyTier.MINION:
		return true

	var n: String = entity.name.to_lower()
	if n.contains("captain") or n.contains("capitao") or n.contains("elite") or n.contains("boss") or n.contains("chefe"):
		return true

	if entity.enemy_data != null:
		var id: String = entity.enemy_data.enemy_id.to_lower()
		if id.contains("captain") or id.contains("capitao") or id.contains("elite") or id.contains("boss"):
			return true

	return false


## Retorna array com heróis vivos e válidos.
func get_living_heroes(party_heroes: Array[CharacterEntity]) -> Array[CharacterEntity]:
	var result: Array[CharacterEntity] = []
	for hero: CharacterEntity in party_heroes:
		if hero != null and is_instance_valid(hero):
			if hero.health_component == null or (hero.health_component.is_alive and hero.health_component.current_hp > 0):
				result.append(hero)
	return result


## Retorna array com aliados monstros vivos e válidos.
func get_living_allies(pack_allies: Array[CharacterEntity]) -> Array[CharacterEntity]:
	var result: Array[CharacterEntity] = []
	for ally: CharacterEntity in pack_allies:
		if ally != null and is_instance_valid(ally):
			if ally.health_component == null or (ally.health_component.is_alive and ally.health_component.current_hp > 0):
				result.append(ally)
	return result


## Encontra o herói vivo mais próximo no plano horizontal XZ.
func find_nearest_hero(living_heroes: Array[CharacterEntity]) -> CharacterEntity:
	if living_heroes.is_empty() or actor == null:
		return null

	var nearest: CharacterEntity = null
	var min_dist_sq: float = INF
	var actor_pos: Vector3 = _get_entity_position(actor)

	for hero: CharacterEntity in living_heroes:
		if hero == null or not is_instance_valid(hero):
			continue
		var hero_pos: Vector3 = _get_entity_position(hero)
		var diff: Vector3 = Vector3(hero_pos.x - actor_pos.x, 0.0, hero_pos.z - actor_pos.z)
		var dist_sq: float = diff.length_squared()
		if dist_sq < min_dist_sq:
			min_dist_sq = dist_sq
			nearest = hero

	return nearest


## Calcula vetor normalizado de fuga apontando em direção oposta à ameaça.
func calculate_flee_direction(threat: CharacterEntity) -> Vector3:
	if actor == null or threat == null or not is_instance_valid(threat):
		return Vector3(0.0, 0.0, 1.0)
	var actor_pos: Vector3 = _get_entity_position(actor)
	var threat_pos: Vector3 = _get_entity_position(threat)
	var flee_vec: Vector3 = Vector3(actor_pos.x - threat_pos.x, 0.0, actor_pos.z - threat_pos.z)
	if flee_vec.length_squared() < 0.0001:
		return Vector3(0.0, 0.0, 1.0)
	return flee_vec.normalized()


## Retorna distância horizontal planar XZ entre o ator e o alvo.
func get_distance_to_target(target: CharacterEntity) -> float:
	if actor == null or target == null or not is_instance_valid(target):
		return INF
	var actor_pos: Vector3 = _get_entity_position(actor)
	var target_pos: Vector3 = _get_entity_position(target)
	var diff: Vector3 = Vector3(target_pos.x - actor_pos.x, 0.0, target_pos.z - actor_pos.z)
	return diff.length()


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


func _load_default_skill_if_needed() -> void:
	if _skill_loaded:
		_ensure_skill_equipped()
		return
	_skill_loaded = true

	if heal_skill == null:
		if ResourceLoader.exists(DEFAULT_HEAL_SKILL_PATH):
			heal_skill = ResourceLoader.load(DEFAULT_HEAL_SKILL_PATH) as SkillData

	_ensure_skill_equipped()


func _ensure_skill_equipped() -> void:
	if actor != null and actor.skill_holder != null and heal_skill != null:
		if not actor.skill_holder.has_skill(heal_skill.id):
			actor.skill_holder.equip_skill(heal_skill)
