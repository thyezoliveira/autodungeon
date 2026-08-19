extends SceneTree

# ==============================================================================
# Unit & Integration Test Suite: TankAIController.gd (Task M4.4)
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
	print("--- Starting TankAIController Unit & Integration Tests (Task M4.4) ---")
	print("================================================================================")

	# Ensure EventBus Autoload node is present in SceneTree root
	var bus_node: Node = root.get_node_or_null("EventBus")
	if bus_node == null:
		var bus_script: Script = load("res://src/core/EventBus.gd")
		bus_node = Node.new()
		bus_node.name = "EventBus"
		bus_node.set_script(bus_script)
		root.add_child(bus_node)
	print("PASS: EventBus Autoload node found in SceneTree root")

	# --------------------------------------------------------------------------
	# Group 1: Default Properties, Auto-Resolution & Null Safety
	# --------------------------------------------------------------------------
	print("\n[Group 1: Default Properties, Auto-Resolution & Null Safety]")
	var standalone_ai: TankAIController = TankAIController.new()
	root.add_child(standalone_ai)

	assert(standalone_ai != null, "TankAIController instance created")
	assert(standalone_ai.actor == null, "Initial standalone actor is null")
	assert(is_equal_approx(standalone_ai.melee_attack_range, 2.0), "Default melee_attack_range is 2.0")
	assert(is_equal_approx(standalone_ai.defensive_hp_threshold, 0.60), "Default defensive_hp_threshold is 0.60")
	assert(is_equal_approx(standalone_ai.charge_min_distance, 3.0), "Default charge_min_distance is 3.0")

	# Standalone execution on empty / null data without crashing
	standalone_ai.evaluate_combat_tactics(0.1, [])
	standalone_ai.evaluate_combat_tactics(0.1, [null])
	assert(standalone_ai.get_living_enemies([]).is_empty(), "get_living_enemies on empty returns empty")
	assert(standalone_ai.find_nearest_enemy([]) == null, "find_nearest_enemy on empty returns null")
	assert(standalone_ai.get_distance_to_target(null) == INF, "get_distance_to_target null returns INF")
	assert(not standalone_ai.execute_charge(null), "execute_charge null returns false")
	assert(not standalone_ai.execute_shield_slam(null), "execute_shield_slam null returns false")

	standalone_ai.free()
	print("PASS: 1.1 Standalone TankAIController properties and null safety verified")

	# --------------------------------------------------------------------------
	# Group 2: Target Acquisition & Nearest Living Enemy Selection
	# --------------------------------------------------------------------------
	print("\n[Group 2: Target Acquisition & Nearest Enemy Selection]")
	var tank_entity_2: CharacterEntity = CharacterEntity.new()
	tank_entity_2.name = "BrommTank_2"
	root.add_child(tank_entity_2)
	tank_entity_2.global_position = Vector3(0.0, 0.0, 0.0)

	var ai_2: TankAIController = TankAIController.new()
	ai_2.actor = tank_entity_2
	tank_entity_2.add_child(ai_2)

	# Mob A at 10m
	var mob_a: CharacterEntity = CharacterEntity.new()
	mob_a.name = "MobA_10m"
	root.add_child(mob_a)
	mob_a.global_position = Vector3(10.0, 0.0, 0.0)
	var hp_a: HealthComponent = HealthComponent.new()
	hp_a.max_hp = 50
	hp_a.current_hp = 50
	hp_a.is_alive = true
	mob_a.add_child(hp_a)
	mob_a.health_component = hp_a

	# Mob B at 4m (Closest)
	var mob_b: CharacterEntity = CharacterEntity.new()
	mob_b.name = "MobB_4m"
	root.add_child(mob_b)
	mob_b.global_position = Vector3(4.0, 0.0, 0.0)
	var hp_b: HealthComponent = HealthComponent.new()
	hp_b.max_hp = 50
	hp_b.current_hp = 50
	hp_b.is_alive = true
	mob_b.add_child(hp_b)
	mob_b.health_component = hp_b

	# Mob C at 7m
	var mob_c: CharacterEntity = CharacterEntity.new()
	mob_c.name = "MobC_7m"
	root.add_child(mob_c)
	mob_c.global_position = Vector3(7.0, 0.0, 0.0)
	var hp_c: HealthComponent = HealthComponent.new()
	hp_c.max_hp = 50
	hp_c.current_hp = 50
	hp_c.is_alive = true
	mob_c.add_child(hp_c)
	mob_c.health_component = hp_c

	var pack_2: Array[CharacterEntity] = [mob_a, mob_b, mob_c]
	var living_2: Array[CharacterEntity] = ai_2.get_living_enemies(pack_2)
	assert(living_2.size() == 3, "All 3 mobs are living")

	var nearest_2: CharacterEntity = ai_2.find_nearest_enemy(living_2)
	assert(nearest_2 == mob_b, "Nearest enemy must be Mob B (4m away)")
	assert(is_equal_approx(ai_2.get_distance_to_target(nearest_2), 4.0), "Distance to Mob B is 4.0m")

	# Kill Mob B -> nearest should become Mob C (7m)
	hp_b.current_hp = 0
	hp_b.is_alive = false
	var living_after_b: Array[CharacterEntity] = ai_2.get_living_enemies(pack_2)
	assert(living_after_b.size() == 2, "2 living mobs remaining")
	assert(ai_2.find_nearest_enemy(living_after_b) == mob_c, "Nearest enemy switches to Mob C (7m away)")

	# Kill Mob C -> nearest should become Mob A (10m)
	hp_c.current_hp = 0
	hp_c.is_alive = false
	var living_after_c: Array[CharacterEntity] = ai_2.get_living_enemies(pack_2)
	assert(living_after_c.size() == 1, "1 living mob remaining")
	assert(ai_2.find_nearest_enemy(living_after_c) == mob_a, "Nearest enemy switches to Mob A (10m away)")

	# Kill Mob A -> nearest should become null
	hp_a.current_hp = 0
	hp_a.is_alive = false
	var living_after_a: Array[CharacterEntity] = ai_2.get_living_enemies(pack_2)
	assert(living_after_a.is_empty(), "0 living mobs remaining")
	assert(ai_2.find_nearest_enemy(living_after_a) == null, "No nearest enemy when all mobs are dead")

	print("PASS: 2.1 Nearest enemy selection and dead mob filtering verified")
	tank_entity_2.free()
	mob_a.free()
	mob_b.free()
	mob_c.free()

	# --------------------------------------------------------------------------
	# Group 3: Locomotion Advance on Out-of-Range Target
	# --------------------------------------------------------------------------
	print("\n[Group 3: Locomotion Advance on Out-of-Range Target]")
	var tank_3: CharacterEntity = CharacterEntity.new()
	tank_3.name = "Bromm_Advance"
	root.add_child(tank_3)
	tank_3.global_position = Vector3(0.0, 0.0, 0.0)

	var move_comp_3: MovementComponent = MovementComponent.new()
	move_comp_3.name = "MovementComponent"
	move_comp_3.character_body = tank_3
	tank_3.add_child(move_comp_3)
	tank_3.movement_component = move_comp_3

	var hp_tank_3: HealthComponent = HealthComponent.new()
	hp_tank_3.max_hp = 100
	hp_tank_3.current_hp = 100
	tank_3.add_child(hp_tank_3)
	tank_3.health_component = hp_tank_3

	var ai_3: TankAIController = TankAIController.new()
	ai_3.actor = tank_3
	tank_3.add_child(ai_3)

	# Target at 2.8m (between melee_attack_range 2.0m and charge_min_distance 3.0m)
	var mob_3: CharacterEntity = CharacterEntity.new()
	mob_3.name = "Mob_2.8m"
	root.add_child(mob_3)
	mob_3.global_position = Vector3(2.8, 0.0, 0.0)

	var hp_mob_3: HealthComponent = HealthComponent.new()
	hp_mob_3.max_hp = 40
	hp_mob_3.current_hp = 40
	hp_mob_3.is_alive = true
	mob_3.add_child(hp_mob_3)
	mob_3.health_component = hp_mob_3

	# Evaluate tactics: dist is 2.8m (> 2.0m and < 3.0m) -> locomotion advance
	ai_3.evaluate_combat_tactics(0.1, [mob_3])
	assert(move_comp_3.is_moving, "MovementComponent is active and advancing towards target")
	assert(is_equal_approx(move_comp_3.current_target_position.x, 2.8), "Target position set to Mob position")

	print("PASS: 3.1 Immediate advance towards mob outside melee range verified")
	tank_3.free()
	mob_3.free()

	# --------------------------------------------------------------------------
	# Group 4: Charge Execution (Investida) & Threat Generation (> 3.0m)
	# --------------------------------------------------------------------------
	print("\n[Group 4: Charge Execution & Threat Generation (> 3.0m)]")
	var tank_4: CharacterEntity = CharacterEntity.new()
	tank_4.name = "Bromm_Charge"
	root.add_child(tank_4)
	tank_4.global_position = Vector3(0.0, 0.0, 0.0)

	var hp_tank_4: HealthComponent = HealthComponent.new()
	hp_tank_4.max_hp = 140
	hp_tank_4.current_hp = 140
	hp_tank_4.max_mana = 50.0
	hp_tank_4.current_mana = 50.0
	tank_4.add_child(hp_tank_4)
	tank_4.health_component = hp_tank_4

	var holder_4: SkillHolderComponent = SkillHolderComponent.new()
	tank_4.add_child(holder_4)
	tank_4.skill_holder = holder_4
	holder_4.setup(tank_4)

	var ai_4: TankAIController = TankAIController.new()
	ai_4.actor = tank_4
	tank_4.add_child(ai_4)

	var mob_4: CharacterEntity = CharacterEntity.new()
	mob_4.name = "Mob_ChargeTarget"
	root.add_child(mob_4)
	mob_4.global_position = Vector3(5.0, 0.0, 0.0)

	var hp_mob_4: HealthComponent = HealthComponent.new()
	hp_mob_4.max_hp = 100
	hp_mob_4.current_hp = 100
	hp_mob_4.is_alive = true
	mob_4.add_child(hp_mob_4)
	mob_4.health_component = hp_mob_4

	var threat_4: ThreatTable = ThreatTable.new()
	mob_4.add_child(threat_4)
	mob_4.threat_table = threat_4

	var tracker_4: Dictionary = {
		"charge_fired": false,
		"charged_target": null
	}
	ai_4.charge_executed.connect(func(target: CharacterEntity) -> void:
		tracker_4["charge_fired"] = true
		tracker_4["charged_target"] = target
	)

	# Execute tactics at distance 5.0m
	ai_4.evaluate_combat_tactics(0.1, [mob_4])

	assert(tracker_4["charge_fired"], "signal charge_executed emitted")
	assert(tracker_4["charged_target"] == mob_4, "Target of charge was mob_4")
	assert(ai_4.get_distance_to_target(mob_4) <= 2.0, "Tank displaced into melee proximity of target")
	assert(threat_4.get_threat(tank_4) > 0.0, "Threat registered in mob's ThreatTable from charge")
	# 18 base dmg * 2.0 multiplier = 36.0 threat
	assert(is_equal_approx(threat_4.get_threat(tank_4), 36.0), "Investida generated 36.0 threat (18 base * 2.0x)")
	assert(hp_mob_4.current_hp < 100, "Mob took damage from charge")
	assert(holder_4.is_skill_on_cooldown("bromm_charge"), "bromm_charge is on cooldown after execution")

	print("PASS: 4.1 Charge execution, rapid displacement, and ThreatTable aggro generation verified")
	tank_4.free()
	mob_4.free()

	# --------------------------------------------------------------------------
	# Group 5: Shield Slam (Golpe de Escudo) & Threat Generation (<= 2.0m)
	# --------------------------------------------------------------------------
	print("\n[Group 5: Shield Slam & High Threat Generation (<= 2.0m)]")
	var tank_5: CharacterEntity = CharacterEntity.new()
	tank_5.name = "Bromm_ShieldSlam"
	root.add_child(tank_5)
	tank_5.global_position = Vector3(0.0, 0.0, 0.0)

	var hp_tank_5: HealthComponent = HealthComponent.new()
	hp_tank_5.max_hp = 140
	hp_tank_5.current_hp = 140
	hp_tank_5.max_mana = 50.0
	hp_tank_5.current_mana = 50.0
	tank_5.add_child(hp_tank_5)
	tank_5.health_component = hp_tank_5

	var holder_5: SkillHolderComponent = SkillHolderComponent.new()
	tank_5.add_child(holder_5)
	tank_5.skill_holder = holder_5
	holder_5.setup(tank_5)

	var ai_5: TankAIController = TankAIController.new()
	ai_5.actor = tank_5
	tank_5.add_child(ai_5)

	var mob_5: CharacterEntity = CharacterEntity.new()
	mob_5.name = "Mob_SlamTarget"
	root.add_child(mob_5)
	mob_5.global_position = Vector3(1.5, 0.0, 0.0) # Within 2.0m

	var hp_mob_5: HealthComponent = HealthComponent.new()
	hp_mob_5.max_hp = 100
	hp_mob_5.current_hp = 100
	hp_mob_5.is_alive = true
	mob_5.add_child(hp_mob_5)
	mob_5.health_component = hp_mob_5

	var threat_5: ThreatTable = ThreatTable.new()
	mob_5.add_child(threat_5)
	mob_5.threat_table = threat_5

	var tracker_5: Dictionary = {
		"slam_fired": false,
		"slam_target": null
	}
	ai_5.shield_slam_executed.connect(func(target: CharacterEntity) -> void:
		tracker_5["slam_fired"] = true
		tracker_5["slam_target"] = target
	)

	# Execute tactics at distance 1.5m <= 2.0m
	ai_5.evaluate_combat_tactics(0.1, [mob_5])

	assert(tracker_5["slam_fired"], "signal shield_slam_executed emitted")
	assert(tracker_5["slam_target"] == mob_5, "Target of shield slam was mob_5")
	# 25 base dmg * 3.0 threat multiplier = 75.0 threat
	assert(is_equal_approx(threat_5.get_threat(tank_5), 75.0), "Golpe de Escudo generated 75.0 threat (25 base * 3.0x)")
	assert(threat_5.primary_target == tank_5, "Mob primary target is Bromm")
	assert(hp_mob_5.current_hp <= 75, "Mob took shield slam damage")
	assert(holder_5.is_skill_on_cooldown("bromm_shield_slam"), "bromm_shield_slam is on cooldown")

	print("PASS: 5.1 Shield Slam execution and 3.0x threat generation in ThreatTable verified")
	tank_5.free()
	mob_5.free()

	# --------------------------------------------------------------------------
	# Group 6: Reactive Defensive Stance Activation when HP < 60%
	# --------------------------------------------------------------------------
	print("\n[Group 6: Reactive Defensive Stance (HP < 60%)]")
	var tank_6: CharacterEntity = CharacterEntity.new()
	tank_6.name = "Bromm_Defensive"
	root.add_child(tank_6)
	tank_6.global_position = Vector3(0.0, 0.0, 0.0)

	var stats_6: StatsComponent = StatsComponent.new()
	stats_6.armor = 20
	tank_6.add_child(stats_6)
	tank_6.stats_component = stats_6

	var hp_tank_6: HealthComponent = HealthComponent.new()
	hp_tank_6.max_hp = 100
	hp_tank_6.current_hp = 100 # 100% HP initially
	hp_tank_6.max_mana = 50.0
	hp_tank_6.current_mana = 50.0
	tank_6.add_child(hp_tank_6)
	tank_6.health_component = hp_tank_6

	var holder_6: SkillHolderComponent = SkillHolderComponent.new()
	tank_6.add_child(holder_6)
	tank_6.skill_holder = holder_6
	holder_6.setup(tank_6)

	var ai_6: TankAIController = TankAIController.new()
	ai_6.actor = tank_6
	tank_6.add_child(ai_6)

	var mob_6: CharacterEntity = CharacterEntity.new()
	mob_6.name = "Mob_6"
	root.add_child(mob_6)
	mob_6.global_position = Vector3(1.0, 0.0, 0.0)
	var hp_mob_6: HealthComponent = HealthComponent.new()
	hp_mob_6.max_hp = 50
	hp_mob_6.current_hp = 50
	hp_mob_6.is_alive = true
	mob_6.add_child(hp_mob_6)
	mob_6.health_component = hp_mob_6

	var tracker_6: Dictionary = {
		"stance_activated": false
	}
	ai_6.defensive_stance_activated.connect(func() -> void:
		tracker_6["stance_activated"] = true
	)

	# 6.1 HP at 100% (>= 60%) -> defensive stance should NOT trigger
	ai_6.evaluate_combat_tactics(0.1, [mob_6])
	assert(not tracker_6["stance_activated"], "Defensive stance NOT activated when HP is 100%")
	assert(is_equal_approx(stats_6.get_stat("armor"), 20.0), "Armor remains 20 at full HP")

	# 6.2 Reduce HP to 55/100 (55% < 60%) -> defensive stance MUST trigger
	hp_tank_6.current_hp = 55
	assert(ai_6.is_defensive_hp_critical(), "is_defensive_hp_critical is true at 55% HP")

	ai_6.evaluate_combat_tactics(0.1, [mob_6])
	assert(tracker_6["stance_activated"], "defensive_stance_activated signal emitted")
	assert(is_equal_approx(stats_6.get_stat("armor"), 40.0), "Armor increased by +20 (20 base + 20 stance = 40)")
	assert(holder_6.is_skill_on_cooldown("bromm_defensive_stance"), "Defensive stance skill placed on cooldown")

	print("PASS: 6.1 Reactive defensive stance activation and armor buff application at HP < 60% verified")
	tank_6.free()
	mob_6.free()

	# --------------------------------------------------------------------------
	# Group 7: Empty Packs, Dead Entities & Robust Edge Cases
	# --------------------------------------------------------------------------
	print("\n[Group 7: Empty Packs, Dead Entities & Robust Edge Cases]")
	var tank_7: CharacterEntity = CharacterEntity.new()
	tank_7.name = "Bromm_Edge"
	root.add_child(tank_7)

	var ai_7: TankAIController = TankAIController.new()
	ai_7.actor = tank_7
	tank_7.add_child(ai_7)

	var dead_mob: CharacterEntity = CharacterEntity.new()
	root.add_child(dead_mob)
	var hp_dead: HealthComponent = HealthComponent.new()
	hp_dead.is_alive = false
	hp_dead.current_hp = 0
	dead_mob.add_child(hp_dead)
	dead_mob.health_component = hp_dead

	var tracker_7: Dictionary = {
		"charge_count": 0,
		"slam_count": 0,
		"stance_count": 0
	}
	ai_7.charge_executed.connect(func(_t: CharacterEntity) -> void: tracker_7["charge_count"] += 1)
	ai_7.shield_slam_executed.connect(func(_t: CharacterEntity) -> void: tracker_7["slam_count"] += 1)
	ai_7.defensive_stance_activated.connect(func() -> void: tracker_7["stance_count"] += 1)

	# Pass mixed null and dead mobs
	ai_7.evaluate_combat_tactics(0.1, [null, dead_mob, null])
	assert(tracker_7["charge_count"] == 0, "No charge fired on dead/null pack")
	assert(tracker_7["slam_count"] == 0, "No shield slam fired on dead/null pack")
	assert(tracker_7["stance_count"] == 0, "No stance fired on dead/null pack")

	print("PASS: 7.1 Empty packs and dead entities handled safely without spurious triggers")
	tank_7.free()
	dead_mob.free()

	print("\n================================================================================")
	print("=== ALL TANK AI CONTROLLER UNIT TESTS PASSED (7/7 GROUPS) ===")
	print("================================================================================")
	quit(0)
