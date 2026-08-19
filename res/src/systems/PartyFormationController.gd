class_name PartyFormationController
extends Node3D

## Controlador de Formação Tática do Trio de Heróis (M3.3)
## Responsável pelo cálculo e projeção das posições de vanguarda (líder), suporte e DPS
## no espaço 3D usando a orientação (Transform3D/basis) do líder.

signal leader_changed(new_leader: CharacterEntity)

@export var leader_hero: CharacterEntity = null
@export var support_hero: CharacterEntity = null
@export var dps_hero: CharacterEntity = null

# Offsets relativos ao líder (em coordenadas locais de rotação)
# Suporte: Flanco direito recuado (Vector3(1.2, 0.0, 1.2))
# DPS: Flanco esquerdo mais recuado (Vector3(-1.2, 0.0, 1.8))
@export var support_offset: Vector3 = Vector3(1.2, 0.0, 1.2)
@export var dps_offset: Vector3 = Vector3(-1.2, 0.0, 1.8)


func _ready() -> void:
	_auto_detect_members_if_needed()
	_connect_event_bus()


func _exit_tree() -> void:
	_disconnect_event_bus()


func _physics_process(_delta: float) -> void:
	_update_follower_targets()


## Atualiza as posições de destino dos seguidores baseando-se no transform global do líder.
func _update_follower_targets() -> void:
	if leader_hero == null or not is_instance_valid(leader_hero) or not is_hero_alive(leader_hero):
		return

	if support_hero != null and is_instance_valid(support_hero) and is_hero_alive(support_hero):
		var target_pos: Vector3 = calculate_formation_position(support_offset)
		var move_comp: MovementComponent = _get_hero_movement_component(support_hero)
		if move_comp != null:
			move_comp.move_towards(target_pos)

	if dps_hero != null and is_instance_valid(dps_hero) and is_hero_alive(dps_hero):
		var target_pos: Vector3 = calculate_formation_position(dps_offset)
		var move_comp: MovementComponent = _get_hero_movement_component(dps_hero)
		if move_comp != null:
			move_comp.move_towards(target_pos)


## Calcula a coordenada global no espaço 3D para um dado offset relativo à orientação do líder.
func calculate_formation_position(offset: Vector3) -> Vector3:
	if leader_hero == null or not is_instance_valid(leader_hero):
		return global_position + offset
	return leader_hero.global_position + (leader_hero.global_transform.basis.orthonormalized() * offset)


## Retorna a entidade líder da formação.
func get_leader() -> CharacterEntity:
	return leader_hero


## Retorna a entidade de suporte da formação.
func get_support() -> CharacterEntity:
	return support_hero


## Retorna a entidade de DPS da formação.
func get_dps() -> CharacterEntity:
	return dps_hero


## Configura manualmente os membros do grupo.
func set_party_members(leader: CharacterEntity, support: CharacterEntity, dps: CharacterEntity) -> void:
	var old_leader: CharacterEntity = leader_hero
	leader_hero = leader
	support_hero = support
	dps_hero = dps
	if leader_hero != old_leader:
		leader_changed.emit(leader_hero)


## Retorna todos os heróis válidos atualmente configurados (não nulos).
func get_all_heroes() -> Array[CharacterEntity]:
	var heroes: Array[CharacterEntity] = []
	if leader_hero != null and is_instance_valid(leader_hero):
		heroes.append(leader_hero)
	if support_hero != null and is_instance_valid(support_hero):
		heroes.append(support_hero)
	if dps_hero != null and is_instance_valid(dps_hero):
		heroes.append(dps_hero)
	return heroes


## Retorna apenas os heróis vivos da formação.
func get_alive_heroes() -> Array[CharacterEntity]:
	var alive: Array[CharacterEntity] = []
	for hero: CharacterEntity in get_all_heroes():
		if is_hero_alive(hero):
			alive.append(hero)
	return alive


## Checa se o herói está vivo e válido.
func is_hero_alive(hero: CharacterEntity) -> bool:
	if hero == null or not is_instance_valid(hero):
		return false
	if hero.health_component != null:
		if not hero.health_component.is_alive or hero.health_component.current_hp <= 0:
			return false
	if hero.state_machine != null:
		var state_name: String = hero.state_machine.get_current_state_name()
		if state_name == "DeadState" or state_name == "Dead":
			return false
	return true


## Reajusta papéis táticos caso o líder venha a falecer.
func reassign_roles_on_hero_death(dead_hero: CharacterEntity) -> void:
	if dead_hero == null or dead_hero != leader_hero:
		return

	var new_leader: CharacterEntity = null
	if support_hero != null and is_hero_alive(support_hero):
		new_leader = support_hero
		support_hero = null
	elif dps_hero != null and is_hero_alive(dps_hero):
		new_leader = dps_hero
		dps_hero = null

	leader_hero = new_leader
	leader_changed.emit(leader_hero)


func _get_hero_movement_component(hero: CharacterEntity) -> MovementComponent:
	if hero == null:
		return null
	if hero.movement_component != null:
		return hero.movement_component
	var move_comp: MovementComponent = hero.get_node_or_null("Components/MovementComponent") as MovementComponent
	if move_comp == null:
		move_comp = hero.get_node_or_null("MovementComponent") as MovementComponent
	if move_comp != null:
		hero.movement_component = move_comp
	return move_comp


func _auto_detect_members_if_needed() -> void:
	if leader_hero != null or support_hero != null or dps_hero != null:
		return

	for child: Node in get_children():
		if child is CharacterEntity:
			var hero_child: CharacterEntity = child as CharacterEntity
			var name_lower: String = hero_child.name.to_lower()
			if leader_hero == null and (name_lower.contains("leader") or name_lower.contains("bromm") or name_lower.contains("tank") or name_lower.contains("guardian")):
				leader_hero = hero_child
			elif support_hero == null and (name_lower.contains("support") or name_lower.contains("beatrice") or name_lower.contains("cleric") or name_lower.contains("healer")):
				support_hero = hero_child
			elif dps_hero == null and (name_lower.contains("dps") or name_lower.contains("elysia") or name_lower.contains("ranger") or name_lower.contains("rogue")):
				dps_hero = hero_child

	# Fallback se algum ainda não foi associado
	var unassigned: Array[CharacterEntity] = []
	for child: Node in get_children():
		if child is CharacterEntity:
			var hero_child: CharacterEntity = child as CharacterEntity
			if hero_child != leader_hero and hero_child != support_hero and hero_child != dps_hero:
				unassigned.append(hero_child)

	if leader_hero == null and unassigned.size() > 0:
		leader_hero = unassigned.pop_front()
	if support_hero == null and unassigned.size() > 0:
		support_hero = unassigned.pop_front()
	if dps_hero == null and unassigned.size() > 0:
		dps_hero = unassigned.pop_front()


func _connect_event_bus() -> void:
	var bus: EventBusSingleton = _get_event_bus()
	if bus != null and not bus.entity_died.is_connected(_on_entity_died):
		bus.entity_died.connect(_on_entity_died)


func _disconnect_event_bus() -> void:
	var bus: EventBusSingleton = _get_event_bus()
	if bus != null and bus.entity_died.is_connected(_on_entity_died):
		bus.entity_died.disconnect(_on_entity_died)


func _on_entity_died(entity: Node3D, _killer: Node3D = null) -> void:
	if entity is CharacterEntity:
		reassign_roles_on_hero_death(entity as CharacterEntity)


func _get_event_bus() -> EventBusSingleton:
	var tree: SceneTree = Engine.get_main_loop() as SceneTree
	if tree != null and tree.root != null and tree.root.has_node("EventBus"):
		return tree.root.get_node("EventBus") as EventBusSingleton
	return null
