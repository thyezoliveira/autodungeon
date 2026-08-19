class_name ThreatTable
extends Node

## Componente de Gestão de Ameaça e Aggro (M4.2)
## Gerencia a pontuação de ameaça gerada por heróis/atacantes e determina o alvo primário de um monstro.

signal primary_target_changed(new_target: CharacterEntity)
signal threat_updated(source: CharacterEntity, new_threat: float)

var _threat_scores: Dictionary = {} # Chave: CharacterEntity, Valor: float (threat)
var _threat_multipliers: Dictionary = {} # Chave: CharacterEntity, Valor: float (multiplicador)
var primary_target: CharacterEntity = null


func _ready() -> void:
	_connect_event_bus()


func _exit_tree() -> void:
	_disconnect_event_bus()


## Adiciona pontuação de ameaça da fonte, aplicando multiplicadores persistentes e pontuais.
func add_threat(source: CharacterEntity, amount: float, multiplier: float = 1.0) -> void:
	if source == null or not is_instance_valid(source):
		return
	if source.health_component != null and not source.health_component.is_alive:
		return
	if amount <= 0.0:
		return

	var safe_multiplier: float = maxf(0.0, multiplier)
	var base_multiplier: float = get_threat_multiplier(source)
	var effective_threat: float = amount * safe_multiplier * base_multiplier

	var current_score: float = _threat_scores.get(source, 0.0) as float
	var new_score: float = current_score + effective_threat
	_threat_scores[source] = new_score

	threat_updated.emit(source, new_score)
	_recalculate_primary_target()


## Retorna a pontuação atual de ameaça de uma determinada entidade.
func get_threat(source: CharacterEntity) -> float:
	if source == null or not is_instance_valid(source):
		return 0.0
	return _threat_scores.get(source, 0.0) as float


## Configura um multiplicador de ameaça persistente para uma entidade específica (ex: Postura do Tanque).
func modify_threat_multiplier(source: CharacterEntity, multiplier: float) -> void:
	if source == null or not is_instance_valid(source):
		return
	_threat_multipliers[source] = maxf(0.0, multiplier)


## Retorna o multiplicador de ameaça configurado para a entidade (padrão 1.0).
func get_threat_multiplier(source: CharacterEntity) -> float:
	if source == null or not is_instance_valid(source):
		return 1.0
	return _threat_multipliers.get(source, 1.0) as float


## Remove uma entidade morta da tabela e recalcula o alvo primário imediatamente.
func clear_dead_target(dead_target: CharacterEntity) -> void:
	if dead_target == null:
		return

	var had_entry: bool = _threat_scores.has(dead_target)
	_threat_scores.erase(dead_target)
	_threat_multipliers.erase(dead_target)

	if had_entry or primary_target == dead_target:
		_recalculate_primary_target()


## Limpa toda a tabela de ameaça e redefine o alvo primário para nulo.
func reset_threat() -> void:
	_threat_scores.clear()
	_threat_multipliers.clear()
	var prev_target: CharacterEntity = primary_target
	primary_target = null
	if prev_target != null:
		primary_target_changed.emit(null)


## Retorna uma cópia do dicionário de pontuações de ameaça atuais.
func get_all_threats() -> Dictionary:
	return _threat_scores.duplicate()


## Retorna uma lista ordenada decrescente dos alvos vivos com maior pontuação de ameaça.
func get_sorted_threat_targets() -> Array[CharacterEntity]:
	var valid_entries: Array[Dictionary] = []
	for ent_variant: Variant in _threat_scores.keys():
		var entity: CharacterEntity = ent_variant as CharacterEntity
		if entity != null and is_instance_valid(entity):
			if entity.health_component == null or entity.health_component.is_alive:
				valid_entries.append({
					"entity": entity,
					"score": _threat_scores[entity] as float
				})

	valid_entries.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return (a["score"] as float) > (b["score"] as float)
	)

	var result: Array[CharacterEntity] = []
	for entry: Dictionary in valid_entries:
		result.append(entry["entity"] as CharacterEntity)
	return result


## Recalcula o alvo primário baseado no maior valor de ameaça acumulado.
func _recalculate_primary_target() -> void:
	var dead_or_invalid: Array[CharacterEntity] = []
	var highest_score: float = -1.0
	var best_target: CharacterEntity = null

	for ent_variant: Variant in _threat_scores.keys():
		var entity: CharacterEntity = ent_variant as CharacterEntity
		if entity == null or not is_instance_valid(entity):
			dead_or_invalid.append(entity)
			continue
		if entity.health_component != null and not entity.health_component.is_alive:
			dead_or_invalid.append(entity)
			continue

		var score: float = _threat_scores[entity] as float
		if score > highest_score and score > 0.0:
			highest_score = score
			best_target = entity

	for invalid_ent: CharacterEntity in dead_or_invalid:
		_threat_scores.erase(invalid_ent)
		_threat_multipliers.erase(invalid_ent)

	var new_target: CharacterEntity = best_target
	if new_target != primary_target:
		primary_target = new_target
		primary_target_changed.emit(primary_target)


func _on_entity_died(entity: Node3D, _killer: Node3D = null) -> void:
	if entity is CharacterEntity:
		clear_dead_target(entity as CharacterEntity)


func _connect_event_bus() -> void:
	var bus: EventBusSingleton = _get_event_bus()
	if bus != null:
		if not bus.entity_died.is_connected(_on_entity_died):
			bus.entity_died.connect(_on_entity_died)


func _disconnect_event_bus() -> void:
	var bus: EventBusSingleton = _get_event_bus()
	if bus != null:
		if bus.entity_died.is_connected(_on_entity_died):
			bus.entity_died.disconnect(_on_entity_died)


func _get_event_bus() -> EventBusSingleton:
	if is_inside_tree() and get_tree() != null and get_tree().root != null:
		if get_tree().root.has_node("EventBus"):
			return get_tree().root.get_node("EventBus") as EventBusSingleton
	var tree: SceneTree = Engine.get_main_loop() as SceneTree
	if tree != null and tree.root != null and tree.root.has_node("EventBus"):
		return tree.root.get_node("EventBus") as EventBusSingleton
	return null
