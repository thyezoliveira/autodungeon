class_name SupportAIController
extends Node

## Controlador de IA Tática da Suporte — Beatrice & Árvore de Decisão de 4 Níveis (M4.6)
## Executa uma árvore estrita de 4 prioridades sequenciais:
## 1. Prioridade 1 (Proteção do Tanque): Se Tanque HP < 80% e cura disponível -> Cura Rápida no Tanque.
## 2. Prioridade 2 (Emergência da Equipe): Se qualquer aliado HP < 40% -> Escudo de Fé / Cura no aliado crítico.
## 3. Prioridade 3 (Autoconservação): Se seu próprio HP < 50% e cura disponível -> Autocura.
## 4. Prioridade 4 (Suporte Ofensivo): Se todos os aliados saudáveis -> Dispara Punição Sagrada (Smite) no alvo focado pelo tanque ou monstro mais próximo.
## Regra Vital: Beatrice nunca gasta mana ofensiva quando um aliado precisa de cura vital.

signal quick_heal_cast(target: CharacterEntity, amount: int)
signal faith_shield_cast(target: CharacterEntity, shield_amount: int)
signal self_heal_cast(amount: int)
signal smite_cast(target: CharacterEntity, damage: int)

@export var actor: CharacterEntity = null
@export var quick_heal_skill: SkillData = null
@export var faith_shield_skill: SkillData = null
@export var smite_skill: SkillData = null

@export var tank_heal_threshold: float = 0.80      ## P1: Tanque HP < 80%
@export var emergency_heal_threshold: float = 0.40 ## P2: Aliado HP < 40%
@export var self_heal_threshold: float = 0.50      ## P3: Auto HP < 50%
@export var cast_range: float = 6.0

const DEFAULT_QUICK_HEAL_PATH: String = "res://src/data/skills/resources/beatrice_quick_heal.tres"
const DEFAULT_FAITH_SHIELD_PATH: String = "res://src/data/skills/resources/beatrice_faith_shield.tres"
const DEFAULT_SMITE_PATH: String = "res://src/data/skills/resources/beatrice_smite.tres"

var _skills_loaded: bool = false


func _ready() -> void:
	_resolve_actor()
	_load_default_skills_if_needed()


## Avalia o ciclo tático de combate em tempo real para a suporte Beatrice.
## Executa rigorosamente a árvore sequencial de 4 níveis de prioridade.
func evaluate_combat_tactics(delta: float, party_heroes: Array[CharacterEntity], enemies: Array[CharacterEntity]) -> void:
	if actor == null:
		_resolve_actor()
	if actor == null:
		return

	if actor.health_component != null and not actor.health_component.is_alive:
		return

	_load_default_skills_if_needed()

	var living_heroes: Array[CharacterEntity] = get_living_heroes(party_heroes)
	var living_enemies: Array[CharacterEntity] = get_living_enemies(enemies)
	var tank: CharacterEntity = find_tank_hero(living_heroes)

	# -------------------------------------------------------------------------
	# Prioridade 1 (Proteção do Tanque):
	# Se Tanque com HP < 80% e cura disponível -> cura o Tanque e retorna.
	# -------------------------------------------------------------------------
	if tank != null and is_tank_critical(tank):
		if can_cast_quick_heal():
			_orient_towards(_get_entity_position(tank), delta)
			execute_quick_heal(tank)
			return
		elif can_cast_faith_shield():
			_orient_towards(_get_entity_position(tank), delta)
			execute_faith_shield(tank)
			return
		# Tanque ferido (< 80%) mas habilidades de cura em recarga:
		# Bloqueia gasto ofensivo de mana para preservar recursos vitais.
		return

	# -------------------------------------------------------------------------
	# Prioridade 2 (Emergência da Equipe):
	# Se qualquer aliado com HP < 40% -> lança Escudo de Fé / Cura no aliado crítico e retorna.
	# -------------------------------------------------------------------------
	var critical_ally: CharacterEntity = find_critical_ally(living_heroes)
	if critical_ally != null:
		_orient_towards(_get_entity_position(critical_ally), delta)
		if can_cast_faith_shield():
			execute_faith_shield(critical_ally)
			return
		elif can_cast_quick_heal():
			execute_quick_heal(critical_ally)
			return
		# Aliado crítico (< 40%) mas curas em recarga: bloqueia gasto ofensivo.
		return

	# -------------------------------------------------------------------------
	# Prioridade 3 (Autoconservação):
	# Se seu próprio HP < 50% e cura disponível -> cura a si mesma e retorna.
	# -------------------------------------------------------------------------
	if is_self_critical():
		if can_cast_quick_heal() or can_cast_faith_shield():
			_orient_towards(_get_entity_position(actor), delta)
			execute_self_heal()
			return
		# Auto HP crítico (< 50%): bloqueia gasto ofensivo.
		return

	# -------------------------------------------------------------------------
	# Prioridade 4 (Suporte Ofensivo):
	# Se todos aliados saudáveis -> dispara Smite/ataque no alvo focado pelo tanque ou monstro mais próximo.
	# -------------------------------------------------------------------------
	if living_enemies.is_empty():
		return

	# Confirmação de que nenhum membro necessita de cura vital
	if not are_all_allies_healthy(living_heroes):
		return

	if can_cast_smite():
		var target: CharacterEntity = find_offensive_target(tank, living_enemies)
		if target != null:
			_orient_towards(_get_entity_position(target), delta)
			execute_smite(target)


## Retorna array apenas com heróis válidos e vivos no grupo.
func get_living_heroes(party_heroes: Array[CharacterEntity]) -> Array[CharacterEntity]:
	var result: Array[CharacterEntity] = []
	for hero: CharacterEntity in party_heroes:
		if hero != null and is_instance_valid(hero):
			if hero.health_component == null or (hero.health_component.is_alive and hero.health_component.current_hp > 0):
				result.append(hero)
	return result


## Retorna array apenas com inimigos válidos e vivos.
func get_living_enemies(enemies: Array[CharacterEntity]) -> Array[CharacterEntity]:
	var result: Array[CharacterEntity] = []
	for enemy: CharacterEntity in enemies:
		if enemy != null and is_instance_valid(enemy):
			if enemy.health_component == null or (enemy.health_component.is_alive and enemy.health_component.current_hp > 0):
				result.append(enemy)
	return result


## Identifica o herói com função de tanque no grupo.
func find_tank_hero(party_heroes: Array[CharacterEntity]) -> CharacterEntity:
	for hero: CharacterEntity in party_heroes:
		if hero == null or not is_instance_valid(hero):
			continue
		if hero.hero_data != null and hero.hero_data.hero_class != null:
			if hero.hero_data.hero_class.role == ClassData.Role.TANK_MELEE:
				return hero
		var n: String = hero.name.to_lower()
		if n.contains("tank") or n.contains("bromm") or n.contains("guardian") or n.contains("guardiao") or n.contains("leader"):
			return hero

	# Fallback: primeiro herói que não seja o próprio ator
	for hero: CharacterEntity in party_heroes:
		if hero != null and is_instance_valid(hero) and hero != actor:
			return hero

	return null


## Retorna a razão normalizada de HP (0.0 a 1.0) da entidade.
func get_hp_ratio(entity: CharacterEntity) -> float:
	if entity == null or not is_instance_valid(entity):
		return 1.0
	if entity.health_component == null:
		return 1.0
	var max_hp: float = float(entity.health_component.max_hp)
	if max_hp <= 0.0:
		return 0.0
	var current_hp: float = float(entity.health_component.current_hp)
	return clampf(current_hp / max_hp, 0.0, 1.0)


## Retorna se o Tanque está em condição de cura prioritária (HP < 80%).
func is_tank_critical(tank: CharacterEntity) -> bool:
	if tank == null or not is_instance_valid(tank):
		return false
	if tank.health_component != null and (not tank.health_component.is_alive or tank.health_component.current_hp <= 0):
		return false
	return get_hp_ratio(tank) < tank_heal_threshold


## Encontra o aliado mais crítico com HP estritamente abaixo do limiar de emergência (< 40%).
func find_critical_ally(party_heroes: Array[CharacterEntity]) -> CharacterEntity:
	var lowest_ally: CharacterEntity = null
	var lowest_ratio: float = 1.0

	for hero: CharacterEntity in party_heroes:
		if hero == null or not is_instance_valid(hero):
			continue
		if hero.health_component != null and (not hero.health_component.is_alive or hero.health_component.current_hp <= 0):
			continue
		var ratio: float = get_hp_ratio(hero)
		if ratio < emergency_heal_threshold and ratio < lowest_ratio:
			lowest_ratio = ratio
			lowest_ally = hero

	return lowest_ally


## Retorna se a própria Beatrice está abaixo do limiar de autoconservação (< 50%).
func is_self_critical() -> bool:
	if actor == null or not is_instance_valid(actor):
		return false
	if actor.health_component != null and (not actor.health_component.is_alive or actor.health_component.current_hp <= 0):
		return false
	return get_hp_ratio(actor) < self_heal_threshold


## Retorna se todos os aliados (e o próprio suporte) estão em estado de saúde seguro.
func are_all_allies_healthy(party_heroes: Array[CharacterEntity]) -> bool:
	var tank: CharacterEntity = find_tank_hero(party_heroes)
	if tank != null and is_tank_critical(tank):
		return false
	if find_critical_ally(party_heroes) != null:
		return false
	if is_self_critical():
		return false
	return true


## Retorna se existe necessidade vital de cura no grupo.
func has_vital_healing_need(party_heroes: Array[CharacterEntity]) -> bool:
	return not are_all_allies_healthy(party_heroes)


## Encontra o alvo ofensivo prioritário: o focado pelo tanque ou o inimigo mais próximo.
func find_offensive_target(tank: CharacterEntity, living_enemies: Array[CharacterEntity]) -> CharacterEntity:
	if living_enemies.is_empty():
		return null

	# 1. Alvo engajado pelo tanque através da ThreatTable
	if tank != null and is_instance_valid(tank):
		for enemy: CharacterEntity in living_enemies:
			if enemy != null and is_instance_valid(enemy):
				if enemy.threat_table != null and enemy.threat_table.primary_target == tank:
					return enemy

	# 2. Inimigo mais próximo à Beatrice
	return find_nearest_enemy(living_enemies)


## Encontra o monstro mais próximo no plano horizontal XZ.
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


## Retorna a distância planar XZ entre o ator e o alvo.
func get_distance_to_target(target: CharacterEntity) -> float:
	if actor == null or target == null or not is_instance_valid(target):
		return INF
	var actor_pos: Vector3 = _get_entity_position(actor)
	var target_pos: Vector3 = _get_entity_position(target)
	var diff: Vector3 = Vector3(target_pos.x - actor_pos.x, 0.0, target_pos.z - actor_pos.z)
	return diff.length()


## Retorna se a Cura Rápida pode ser conjurada.
func can_cast_quick_heal() -> bool:
	if quick_heal_skill == null:
		return false
	if actor != null and actor.skill_holder != null:
		return actor.skill_holder.can_cast_skill(quick_heal_skill)
	if actor != null and actor.health_component != null:
		return actor.health_component.current_mana >= quick_heal_skill.mana_cost
	return true


## Retorna se o Escudo de Fé pode ser conjurado.
func can_cast_faith_shield() -> bool:
	if faith_shield_skill == null:
		return false
	if actor != null and actor.skill_holder != null:
		return actor.skill_holder.can_cast_skill(faith_shield_skill)
	if actor != null and actor.health_component != null:
		return actor.health_component.current_mana >= faith_shield_skill.mana_cost
	return true


## Retorna se a Punição Sagrada (Smite) pode ser conjurada.
func can_cast_smite() -> bool:
	if smite_skill == null:
		return false
	if actor != null and actor.skill_holder != null:
		return actor.skill_holder.can_cast_skill(smite_skill)
	if actor != null and actor.health_component != null:
		return actor.health_component.current_mana >= smite_skill.mana_cost
	return true


## Executa a Cura Rápida em um aliado alvo.
func execute_quick_heal(target: CharacterEntity) -> bool:
	if target == null or not is_instance_valid(target):
		return false
	if not can_cast_quick_heal():
		return false

	var heal_amount: int = 35
	if quick_heal_skill != null and not quick_heal_skill.effects.is_empty():
		heal_amount = quick_heal_skill.effects[0].value_base

	if actor != null and actor.skill_holder != null and quick_heal_skill != null:
		actor.skill_holder.execute_skill(quick_heal_skill, target)

	if target.health_component != null:
		target.health_component.heal(heal_amount, actor)

	quick_heal_cast.emit(target, heal_amount)
	return true


## Executa o Escudo de Fé em um aliado crítico.
func execute_faith_shield(target: CharacterEntity) -> bool:
	if target == null or not is_instance_valid(target):
		return false
	if not can_cast_faith_shield():
		return false

	var shield_amount: int = 40
	if faith_shield_skill != null and not faith_shield_skill.effects.is_empty():
		shield_amount = faith_shield_skill.effects[0].value_base

	if actor != null and actor.skill_holder != null and faith_shield_skill != null:
		actor.skill_holder.execute_skill(faith_shield_skill, target)

	if target.stats_component != null:
		target.stats_component.add_flat_modifier("armor", "beatrice_faith_shield", 15.0)
		var duration: float = 5.0
		if faith_shield_skill != null and not faith_shield_skill.effects.is_empty() and faith_shield_skill.effects[0].duration > 0.0:
			duration = faith_shield_skill.effects[0].duration
		var tree: SceneTree = actor.get_tree() if actor.is_inside_tree() else Engine.get_main_loop() as SceneTree
		if tree != null:
			tree.create_timer(duration).timeout.connect(func() -> void:
				if target != null and is_instance_valid(target) and target.stats_component != null:
					target.stats_component.remove_modifier("armor", "beatrice_faith_shield")
			)

	faith_shield_cast.emit(target, shield_amount)
	return true


## Executa a autoconservação: cura ou concede escudo a si mesma.
func execute_self_heal() -> bool:
	if actor == null or not is_instance_valid(actor):
		return false

	if can_cast_quick_heal():
		var heal_amount: int = 35
		if quick_heal_skill != null and not quick_heal_skill.effects.is_empty():
			heal_amount = quick_heal_skill.effects[0].value_base

		if actor.skill_holder != null and quick_heal_skill != null:
			actor.skill_holder.execute_skill(quick_heal_skill, actor)

		if actor.health_component != null:
			actor.health_component.heal(heal_amount, actor)

		self_heal_cast.emit(heal_amount)
		quick_heal_cast.emit(actor, heal_amount)
		return true
	elif can_cast_faith_shield():
		var shield_amount: int = 40
		if faith_shield_skill != null and not faith_shield_skill.effects.is_empty():
			shield_amount = faith_shield_skill.effects[0].value_base

		if actor.skill_holder != null and faith_shield_skill != null:
			actor.skill_holder.execute_skill(faith_shield_skill, actor)

		self_heal_cast.emit(shield_amount)
		faith_shield_cast.emit(actor, shield_amount)
		return true

	return false


## Executa a Punição Sagrada (Smite) no inimigo alvo.
func execute_smite(target: CharacterEntity) -> bool:
	if target == null or not is_instance_valid(target):
		return false
	if not can_cast_smite():
		return false

	var base_dmg: float = 20.0
	var threat_mult: float = 1.0
	if smite_skill != null and not smite_skill.effects.is_empty():
		var eff: SkillEffect = smite_skill.effects[0]
		base_dmg = float(eff.value_base)
		if eff is DamageSkillEffect:
			threat_mult = (eff as DamageSkillEffect).threat_multiplier

	if actor != null and actor.skill_holder != null and smite_skill != null:
		actor.skill_holder.execute_skill(smite_skill, target)

	if target.threat_table != null and actor != null:
		target.threat_table.add_threat(actor, base_dmg, threat_mult)

	if target.health_component != null and actor != null:
		target.health_component.take_damage(int(base_dmg), 0, actor)

	smite_cast.emit(target, int(base_dmg))
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
	if _skills_loaded:
		_ensure_skills_equipped()
		return
	_skills_loaded = true

	if quick_heal_skill == null:
		if ResourceLoader.exists(DEFAULT_QUICK_HEAL_PATH):
			quick_heal_skill = ResourceLoader.load(DEFAULT_QUICK_HEAL_PATH) as SkillData
	if faith_shield_skill == null:
		if ResourceLoader.exists(DEFAULT_FAITH_SHIELD_PATH):
			faith_shield_skill = ResourceLoader.load(DEFAULT_FAITH_SHIELD_PATH) as SkillData
	if smite_skill == null:
		if ResourceLoader.exists(DEFAULT_SMITE_PATH):
			smite_skill = ResourceLoader.load(DEFAULT_SMITE_PATH) as SkillData

	_ensure_skills_equipped()


func _ensure_skills_equipped() -> void:
	if actor != null and actor.skill_holder != null:
		if quick_heal_skill != null and not actor.skill_holder.has_skill(quick_heal_skill.id):
			actor.skill_holder.equip_skill(quick_heal_skill)
		if faith_shield_skill != null and not actor.skill_holder.has_skill(faith_shield_skill.id):
			actor.skill_holder.equip_skill(faith_shield_skill)
		if smite_skill != null and not actor.skill_holder.has_skill(smite_skill.id):
			actor.skill_holder.equip_skill(smite_skill)
