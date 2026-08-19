extends SceneTree

# ==============================================================================
# Integration Test Suite: CharacterEntity 3D + Components + FSM + EventBus
# ==============================================================================

var _executed: bool = false


func _process(_delta: float) -> bool:
	if _executed:
		return false
	_executed = true
	_run_all_tests()
	return false


func _run_all_tests() -> void:
	print("================================================================================")
	print("--- Starting CharacterEntity 3D Full Integration Test Suite ---")
	print("================================================================================")

	# --------------------------------------------------------------------------
	# Test Group 1: Scene Resource & Complete Node Hierarchy Composition
	# --------------------------------------------------------------------------
	print("\n[Group 1: Scene Resource & Complete Node Hierarchy Composition]")
	var scene_path: String = "res://src/entities/base/CharacterEntity.tscn"
	assert(ResourceLoader.exists(scene_path), "CharacterEntity.tscn must exist at %s" % scene_path)

	var packed_scene: PackedScene = load(scene_path) as PackedScene
	assert(packed_scene != null, "CharacterEntity.tscn must load as PackedScene")

	var entity: CharacterEntity = packed_scene.instantiate() as CharacterEntity
	assert(entity != null, "Instantiating CharacterEntity.tscn must produce a CharacterEntity")
	root.add_child(entity)

	# Verify Node Hierarchy
	assert(entity.body_collider != null, "BodyCollider must exist")
	assert(entity.body_collider is CollisionShape3D, "BodyCollider must be a CollisionShape3D")
	assert(entity.body_collider.shape is CapsuleShape3D, "BodyCollider shape must be CapsuleShape3D")
	assert(not entity.body_collider.disabled, "BodyCollider must start enabled")

	assert(entity.visuals != null, "Visuals node must exist")
	assert(entity.visuals.get_node_or_null("ModelMesh") != null, "Visuals/ModelMesh must exist")

	assert(entity.components != null, "Components container node must exist")
	assert(entity.stats_component != null, "StatsComponent must exist under Components")
	assert(entity.health_component != null, "HealthComponent must exist under Components")
	assert(entity.hurtbox != null, "Hurtbox3D must exist under Components")
	assert(entity.hurtbox.collision_layer == 16, "Hurtbox3D must be on Layer 5 (Hero_Hurtboxes, mask value 16)")
	assert(entity.hurtbox.collision_mask == 0, "Hurtbox3D collision_mask should be 0")

	assert(entity.state_machine != null, "StateMachine must exist")
	assert(entity.state_machine.initial_state != null, "StateMachine initial_state must be configured")
	assert(entity.state_machine.initial_state is IdleState, "StateMachine initial_state must be IdleState")
	assert(entity.state_machine.has_state("IdleState"), "StateMachine must have IdleState registered")
	assert(entity.state_machine.has_state("DeadState"), "StateMachine must have DeadState registered")
	assert(entity.state_machine.current_state is IdleState, "StateMachine current_state must be active in IdleState")

	print("PASS: 1.1 Complete node hierarchy and component bindings verified in CharacterEntity.tscn")

	# --------------------------------------------------------------------------
	# Test Group 2: HeroData Injection & Initialization (hero_bromm.tres)
	# --------------------------------------------------------------------------
	print("\n[Group 2: HeroData Injection & Initialization (hero_bromm.tres)]")
	var bromm_res: HeroData = load("res://src/data/heroes/resources/hero_bromm.tres") as HeroData
	assert(bromm_res != null, "hero_bromm.tres must load successfully")

	entity.hero_data = bromm_res
	entity.setup_entity_data()

	var expected_max_hp: int = bromm_res.get_total_max_hp()
	var expected_armor: int = bromm_res.get_total_armor()
	var expected_magic_resist: int = bromm_res.get_total_magic_resist()
	var expected_attack_power: int = bromm_res.get_total_attack_power()

	assert(int(entity.stats_component.get_stat("max_hp")) == expected_max_hp, "StatsComponent max_hp should match HeroData total max HP")
	assert(int(entity.stats_component.get_stat("armor")) == expected_armor, "StatsComponent armor should match HeroData total armor")
	assert(int(entity.stats_component.get_stat("magic_resist")) == expected_magic_resist, "StatsComponent magic_resist should match HeroData")
	assert(int(entity.stats_component.get_stat("attack_power")) == expected_attack_power, "StatsComponent attack_power should match HeroData")

	assert(entity.health_component.max_hp == expected_max_hp, "HealthComponent max_hp should match StatsComponent")
	assert(entity.health_component.current_hp == expected_max_hp, "HealthComponent current_hp should initialize to max_hp")
	assert(entity.health_component.is_alive == true, "HealthComponent is_alive should be true")

	assert(entity.hurtbox.health_component == entity.health_component, "Hurtbox3D health_component reference must match entity")
	assert(entity.hurtbox.stats_component == entity.stats_component, "Hurtbox3D stats_component reference must match entity")
	assert(entity.hurtbox.source_entity == entity, "Hurtbox3D source_entity reference must match entity")

	print("PASS: 2.1 HeroData (Bromm: HP=%d, Armor=%d, MR=%d) injected and synchronized across components" % [expected_max_hp, expected_armor, expected_magic_resist])

	# --------------------------------------------------------------------------
	# Test Group 3: Consecutive Damage Simulation & Linear Mitigation
	# --------------------------------------------------------------------------
	print("\n[Group 3: Consecutive Damage Simulation & Linear Mitigation]")
	var attacker: Node3D = Node3D.new()
	attacker.name = "EnemyAttacker"
	root.add_child(attacker)

	var enemy_hitbox: Hitbox3D = Hitbox3D.new()
	enemy_hitbox.name = "EnemyHitbox3D"
	enemy_hitbox.collision_layer = 32
	enemy_hitbox.collision_mask = 16
	enemy_hitbox.source_entity = attacker
	attacker.add_child(enemy_hitbox)

	var event_bus: EventBusSingleton = null
	if root.has_node("EventBus"):
		event_bus = root.get_node("EventBus") as EventBusSingleton

	var damage_events: Array[Dictionary] = []
	if event_bus != null:
		event_bus.damage_dealt.connect(func(target: Node3D, src: Node3D, amt: int, crit: bool, blocked: bool) -> void:
			damage_events.append({
				"target": target,
				"source": src,
				"amount": amt,
				"is_critical": crit,
				"is_blocked": blocked
			})
		)

	# Hit 1: Physical hit with 45 raw damage (45 - 25 armor = 20 damage)
	enemy_hitbox.damage = 45
	enemy_hitbox.is_physical = true
	var hp_before_hit1: int = entity.health_component.current_hp
	entity.hurtbox.receive_hit(enemy_hitbox)

	var expected_hit1_damage: int = maxi(1, 45 - expected_armor)
	assert(entity.health_component.current_hp == hp_before_hit1 - expected_hit1_damage, "Hit 1: HP should be %d, got %d" % [hp_before_hit1 - expected_hit1_damage, entity.health_component.current_hp])
	assert(entity.health_component.is_alive, "Entity should remain alive after Hit 1")
	assert(entity.state_machine.get_current_state_name() == "IdleState", "Entity FSM should remain in IdleState")
	assert(damage_events.size() == 1, "EventBus should have received 1 damage event")
	assert(damage_events[0]["amount"] == expected_hit1_damage, "EventBus damage amount should be %d" % expected_hit1_damage)
	assert(damage_events[0]["is_blocked"] == true, "EventBus is_blocked should be true due to armor mitigation")
	print("PASS: 3.1 Hit 1 (Physical 45 - %d armor = %d dmg) verified. Current HP: %d/%d" % [expected_armor, expected_hit1_damage, entity.health_component.current_hp, entity.health_component.max_hp])

	# Hit 2: Physical hit with 65 raw damage (65 - 25 armor = 40 damage)
	enemy_hitbox.damage = 65
	enemy_hitbox.is_physical = true
	var hp_before_hit2: int = entity.health_component.current_hp
	entity.hurtbox.receive_hit(enemy_hitbox)

	var expected_hit2_damage: int = maxi(1, 65 - expected_armor)
	assert(entity.health_component.current_hp == hp_before_hit2 - expected_hit2_damage, "Hit 2: HP should be %d, got %d" % [hp_before_hit2 - expected_hit2_damage, entity.health_component.current_hp])
	assert(entity.health_component.is_alive, "Entity should remain alive after Hit 2")
	print("PASS: 3.2 Hit 2 (Physical 65 - %d armor = %d dmg) verified. Current HP: %d/%d" % [expected_armor, expected_hit2_damage, entity.health_component.current_hp, entity.health_component.max_hp])

	# Hit 3: Magical hit with 38 raw damage (38 - 8 magic resist = 30 damage)
	enemy_hitbox.damage = 38
	enemy_hitbox.is_physical = false
	var hp_before_hit3: int = entity.health_component.current_hp
	entity.hurtbox.receive_hit(enemy_hitbox)

	var expected_hit3_damage: int = maxi(1, 38 - expected_magic_resist)
	assert(entity.health_component.current_hp == hp_before_hit3 - expected_hit3_damage, "Hit 3: HP should be %d, got %d" % [hp_before_hit3 - expected_hit3_damage, entity.health_component.current_hp])
	assert(entity.health_component.is_alive, "Entity should remain alive after Hit 3")
	print("PASS: 3.3 Hit 3 (Magic 38 - %d MR = %d dmg) verified. Current HP: %d/%d" % [expected_magic_resist, expected_hit3_damage, entity.health_component.current_hp, entity.health_component.max_hp])

	# --------------------------------------------------------------------------
	# Test Group 4: Lethal Blow, Atomic DeadState Transition & Collision Disabling
	# --------------------------------------------------------------------------
	print("\n[Group 4: Lethal Blow, Atomic DeadState Transition & Collision Disabling]")
	var death_events: Array[Dictionary] = []
	if event_bus != null:
		event_bus.entity_died.connect(func(dead_ent: Node3D, killer: Node3D) -> void:
			death_events.append({
				"entity": dead_ent,
				"killer": killer
			})
		)

	var fsm_transitions: Array[Dictionary] = []
	entity.state_machine.state_changed.connect(func(from_s: String, to_s: String) -> void:
		fsm_transitions.append({"from": from_s, "to": to_s})
	)

	# Deliver lethal blow
	enemy_hitbox.damage = 999
	enemy_hitbox.is_physical = true
	entity.hurtbox.receive_hit(enemy_hitbox)

	# Validate HealthComponent state
	assert(entity.health_component.current_hp == 0, "HP must drop to exactly 0")
	assert(entity.health_component.is_alive == false, "is_alive must be false")

	# Validate FSM state
	assert(entity.state_machine.get_current_state_name() == "DeadState", "StateMachine must transition to DeadState")
	assert(entity.state_machine.current_state is DeadState, "Current state instance must be DeadState")
	assert(fsm_transitions.size() == 1, "Exactly 1 state transition should occur")
	assert(fsm_transitions[0]["from"] == "IdleState", "Transitioned from IdleState")
	assert(fsm_transitions[0]["to"] == "DeadState", "Transitioned to DeadState")

	# Validate EventBus and local death signals
	assert(death_events.size() == 1, "EventBus.entity_died must be emitted exactly once")
	assert(death_events[0]["entity"] == entity, "EventBus dead entity should be CharacterEntity")
	assert(death_events[0]["killer"] == attacker, "EventBus killer should be Attacker")

	# Validate Physical and Hurtbox Collision Disabling
	assert(entity.body_collider.disabled == true, "Root BodyCollider must be disabled upon entering DeadState")
	assert(entity.hurtbox.monitoring == false, "Hurtbox3D monitoring must be false upon entering DeadState")
	assert(entity.hurtbox.monitorable == false, "Hurtbox3D monitorable must be false upon entering DeadState")
	for child in entity.hurtbox.get_children():
		if child is CollisionShape3D:
			assert(child.disabled == true, "Hurtbox3D child CollisionShape3D must be disabled")

	# Validate Post-Mortem Hit Immunity / Idempotency
	var prev_damage_event_count: int = damage_events.size()
	entity.hurtbox.receive_hit(enemy_hitbox)
	assert(entity.health_component.current_hp == 0, "HP remains 0 on subsequent hits")
	assert(damage_events.size() == prev_damage_event_count, "No new damage events emitted after death")
	assert(death_events.size() == 1, "No duplicate death events emitted")

	print("PASS: 4.1 Lethal blow cleanly transitioned FSM to DeadState, disabled collisions, and emitted death signals")

	# --------------------------------------------------------------------------
	# Test Group 5: EnemyData Injection & Enemy Integration
	# --------------------------------------------------------------------------
	print("\n[Group 5: EnemyData Injection & Enemy Integration]")
	var enemy_entity: CharacterEntity = packed_scene.instantiate() as CharacterEntity
	root.add_child(enemy_entity)

	var goblin_res: EnemyData = load("res://src/data/enemies/enemy_goblin_warrior.tres") as EnemyData
	assert(goblin_res != null, "enemy_goblin_warrior.tres must load successfully")

	enemy_entity.enemy_data = goblin_res
	enemy_entity.setup_entity_data()

	assert(int(enemy_entity.stats_component.get_stat("max_hp")) == goblin_res.max_hp, "Goblin max_hp matches EnemyData")
	assert(int(enemy_entity.stats_component.get_stat("armor")) == goblin_res.armor, "Goblin armor matches EnemyData")
	assert(int(enemy_entity.stats_component.get_stat("attack_power")) == goblin_res.attack_power, "Goblin attack_power matches EnemyData")
	assert(enemy_entity.health_component.current_hp == goblin_res.max_hp, "Goblin current_hp initialized to max_hp")
	assert(enemy_entity.state_machine.get_current_state_name() == "IdleState", "Goblin begins in IdleState")

	# Attack goblin to death
	var hero_hitbox: Hitbox3D = Hitbox3D.new()
	hero_hitbox.damage = 100
	hero_hitbox.is_physical = true
	hero_hitbox.source_entity = entity
	root.add_child(hero_hitbox)

	enemy_entity.hurtbox.receive_hit(hero_hitbox)
	assert(enemy_entity.health_component.current_hp == 0, "Goblin HP reduced to 0")
	assert(enemy_entity.health_component.is_alive == false, "Goblin is_alive is false")
	assert(enemy_entity.state_machine.get_current_state_name() == "DeadState", "Goblin FSM transitioned to DeadState")
	assert(enemy_entity.body_collider.disabled == true, "Goblin BodyCollider is disabled")

	print("PASS: 5.1 EnemyData injection and enemy combat lifecycle verified")

	# --------------------------------------------------------------------------
	# Test Group 6: Full Scene Instantiation from test_character_entity.tscn
	# --------------------------------------------------------------------------
	print("\n[Group 6: Full Scene Instantiation from test_character_entity.tscn]")
	var test_scene_res: PackedScene = load("res://tests/test_character_entity.tscn") as PackedScene
	assert(test_scene_res != null, "test_character_entity.tscn must load as PackedScene")

	var test_scene: Node3D = test_scene_res.instantiate() as Node3D
	assert(test_scene != null, "test_character_entity.tscn instantiated")
	root.add_child(test_scene)

	var scene_char: CharacterEntity = test_scene.get_node_or_null("CharacterEntity") as CharacterEntity
	assert(scene_char != null, "CharacterEntity instance found in test_character_entity.tscn")
	assert(scene_char.body_collider != null, "scene_char.body_collider exists")
	assert(scene_char.health_component != null, "scene_char.health_component exists")
	assert(scene_char.stats_component != null, "scene_char.stats_component exists")
	assert(scene_char.state_machine != null, "scene_char.state_machine exists")
	assert(scene_char.state_machine.get_current_state_name() == "IdleState", "scene_char starts in IdleState")

	var scene_attacker: Node3D = test_scene.get_node_or_null("Attacker") as Node3D
	assert(scene_attacker != null, "Attacker found in test_character_entity.tscn")
	var scene_hitbox: Hitbox3D = scene_attacker.get_node_or_null("Hitbox3D") as Hitbox3D
	assert(scene_hitbox != null, "Hitbox3D found on Attacker")

	# Apply hit from scene attacker
	var hp_before: int = scene_char.health_component.current_hp
	scene_char.hurtbox.receive_hit(scene_hitbox)
	assert(scene_char.health_component.current_hp < hp_before, "HP deducted via scene hitbox impact")

	print("PASS: 6.1 test_character_entity.tscn pre-configured scene validated")

	# Clean up
	entity.queue_free()
	attacker.queue_free()
	enemy_entity.queue_free()
	hero_hitbox.queue_free()
	test_scene.queue_free()

	print("\n================================================================================")
	print("=== ALL CHARACTER ENTITY INTEGRATION TESTS PASSED (6/6 GROUPS) ===")
	print("================================================================================")
	quit(0)
