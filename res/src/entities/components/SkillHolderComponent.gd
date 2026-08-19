class_name SkillHolderComponent
extends Node

## Componente de Gestão de Habilidades e Cooldowns (M4.3)
## Gerencia as habilidades equipadas pela entidade, o consumo de mana,
## o rastreamento em tempo real de recargas (cooldowns) e a execução de efeitos polimórficos.

signal skill_ready(skill_data: SkillData)
signal skill_executed(skill_data: SkillData, target: Node3D)

@export var equipped_skills: Array[SkillData] = []
@export var actor: CharacterEntity = null

var _cooldown_timers: Dictionary = {} # Chave: skill_id (String), Valor: float (tempo restante)
var _max_cooldowns: Dictionary = {}   # Chave: skill_id (String), Valor: float (duração total da recarga)


func _ready() -> void:
	_resolve_actor()
	setup(actor)


func _physics_process(delta: float) -> void:
	if _cooldown_timers.is_empty():
		return

	var bus: EventBusSingleton = _get_event_bus()
	for skill_id: String in _cooldown_timers.keys():
		var current_cd: float = _cooldown_timers.get(skill_id, 0.0) as float
		if current_cd > 0.0:
			var new_cd: float = maxf(0.0, current_cd - delta)
			_cooldown_timers[skill_id] = new_cd

			var max_cd: float = _max_cooldowns.get(skill_id, 0.0) as float
			var ratio: float = (new_cd / max_cd) if max_cd > 0.0 else 0.0

			if bus != null:
				bus.skill_cooldown_updated.emit(actor, skill_id, ratio)

			if new_cd == 0.0:
				var skill: SkillData = get_skill_by_id(skill_id)
				if skill != null:
					skill_ready.emit(skill)


## Inicializa o componente com referência ao ator e equipa habilidades a partir de HeroData ou EnemyData.
func setup(p_actor: CharacterEntity = null) -> void:
	if p_actor != null:
		actor = p_actor
	if actor == null:
		_resolve_actor()

	if equipped_skills.is_empty() and actor != null:
		if actor.hero_data != null:
			if actor.hero_data.innate_skills != null:
				for skill: SkillData in actor.hero_data.innate_skills:
					equip_skill(skill)
			if actor.hero_data.hero_class != null and actor.hero_data.hero_class.class_skills != null:
				for skill: SkillData in actor.hero_data.hero_class.class_skills:
					equip_skill(skill)
		elif actor.enemy_data != null:
			if actor.enemy_data.skills != null:
				for skill: SkillData in actor.enemy_data.skills:
					equip_skill(skill)
	else:
		for skill: SkillData in equipped_skills:
			if skill != null:
				if not _cooldown_timers.has(skill.id):
					_cooldown_timers[skill.id] = 0.0
				_max_cooldowns[skill.id] = skill.cooldown


## Valida se a habilidade pode ser conjurada (cooldown zerado e mana suficiente).
func can_cast_skill(skill_data: SkillData, current_mana: float = -1.0) -> bool:
	if skill_data == null:
		return false

	if actor != null and actor.health_component != null and not actor.health_component.is_alive:
		return false

	if is_skill_on_cooldown(skill_data.id):
		return false

	var mana_to_check: float = current_mana
	if mana_to_check < 0.0:
		if actor != null and actor.health_component != null:
			mana_to_check = actor.health_component.current_mana
		else:
			mana_to_check = 0.0

	if mana_to_check < skill_data.mana_cost:
		return false

	return true


## Executa uma habilidade: consome mana, ativa cooldown, dispara EventBus e aplica efeitos.
func execute_skill(skill_data: SkillData, target: Node3D = null) -> bool:
	if skill_data == null:
		return false

	if actor == null:
		_resolve_actor()

	if actor != null and actor.health_component != null and not actor.health_component.is_alive:
		return false

	if is_skill_on_cooldown(skill_data.id):
		return false

	if actor != null and actor.health_component != null:
		if actor.health_component.current_mana < skill_data.mana_cost:
			return false
		var consumed: bool = actor.health_component.consume_mana(skill_data.mana_cost)
		if not consumed:
			return false

	# Inicia o timer de recarga
	_cooldown_timers[skill_data.id] = skill_data.cooldown
	_max_cooldowns[skill_data.id] = skill_data.cooldown

	# Emite sinais no EventBus
	var bus: EventBusSingleton = _get_event_bus()
	if bus != null:
		bus.skill_cast_started.emit(actor, skill_data)
		var initial_ratio: float = 1.0 if skill_data.cooldown > 0.0 else 0.0
		bus.skill_cooldown_updated.emit(actor, skill_data.id, initial_ratio)

	# Aplica todos os efeitos associados à habilidade
	if skill_data.effects != null:
		for effect: SkillEffect in skill_data.effects:
			if effect != null:
				effect.apply_effect(actor, target)

	# Emite sinal local de conclusão de execução
	skill_executed.emit(skill_data, target)
	return true


## Retorna o tempo restante de recarga em segundos para uma habilidade específica.
func get_cooldown_remaining(skill_id: String) -> float:
	return _cooldown_timers.get(skill_id, 0.0) as float


## Retorna a fração normalizada (0.0 a 1.0) do cooldown restante.
func get_cooldown_ratio(skill_id: String) -> float:
	var remaining: float = get_cooldown_remaining(skill_id)
	var max_cd: float = _max_cooldowns.get(skill_id, 0.0) as float
	if max_cd <= 0.0:
		return 0.0
	return clampf(remaining / max_cd, 0.0, 1.0)


## Retorna true se a habilidade estiver em tempo de recarga ativo.
func is_skill_on_cooldown(skill_id: String) -> bool:
	return get_cooldown_remaining(skill_id) > 0.0


## Redefine imediatamente todas as recargas para zero e emite notificações de prontidão.
func reset_all_cooldowns() -> void:
	var bus: EventBusSingleton = _get_event_bus()
	for skill_id: String in _cooldown_timers.keys():
		var was_on_cooldown: bool = (_cooldown_timers.get(skill_id, 0.0) as float) > 0.0
		_cooldown_timers[skill_id] = 0.0

		if was_on_cooldown:
			if bus != null:
				bus.skill_cooldown_updated.emit(actor, skill_id, 0.0)
			var skill_data: SkillData = get_skill_by_id(skill_id)
			if skill_data != null:
				skill_ready.emit(skill_data)


## Equipa uma nova habilidade no componente e prepara seu registro de cooldown.
func equip_skill(skill_data: SkillData) -> void:
	if skill_data == null:
		return
	if not equipped_skills.has(skill_data):
		equipped_skills.append(skill_data)
	if not _cooldown_timers.has(skill_data.id):
		_cooldown_timers[skill_data.id] = 0.0
	_max_cooldowns[skill_data.id] = skill_data.cooldown


## Remove uma habilidade equipada pelo ID.
func unequip_skill(skill_id: String) -> void:
	var skill_data: SkillData = get_skill_by_id(skill_id)
	if skill_data != null:
		equipped_skills.erase(skill_data)
	_cooldown_timers.erase(skill_id)
	_max_cooldowns.erase(skill_id)


## Busca uma habilidade equipada pelo identificador textual (id).
func get_skill_by_id(skill_id: String) -> SkillData:
	for skill: SkillData in equipped_skills:
		if skill != null and skill.id == skill_id:
			return skill
	return null


## Retorna se uma determinada habilidade está equipada.
func has_skill(skill_id: String) -> bool:
	return get_skill_by_id(skill_id) != null


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


func _get_event_bus() -> EventBusSingleton:
	if is_inside_tree() and get_tree() != null and get_tree().root != null:
		if get_tree().root.has_node("EventBus"):
			return get_tree().root.get_node("EventBus") as EventBusSingleton
	var tree: SceneTree = Engine.get_main_loop() as SceneTree
	if tree != null and tree.root != null and tree.root.has_node("EventBus"):
		return tree.root.get_node("EventBus") as EventBusSingleton
	return null
