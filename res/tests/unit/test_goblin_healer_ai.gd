extends SceneTree

# ==============================================================================
# Unit & Integration Test Suite: Goblin Healer AI and Prefab (Task M5.3)
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
	print("--- Starting Goblin Healer AI and Prefab Unit Tests (Task M5.3) ---")
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
	# Group 1: EnemyData and SkillData Resources
	# --------------------------------------------------------------------------
	print("\n[Group 1: EnemyData & SkillData Resources]")
	var healer_res: EnemyData = load("res://src/data/enemies/enemy_goblin_healer.tres") as EnemyData
	assert(healer_res != null, "enemy_goblin_healer.tres exists and is EnemyData")
	assert(healer_res.enemy_id == "goblin_healer", "healer enemy_id is 'goblin_healer'")
	assert(healer_res.enemy_name == "Goblin Curandeiro", "healer enemy_name is 'Goblin Curandeiro'")
	assert(healer_res.tier == EnemyData.EnemyTier.MINION, "healer tier is MINION (0)")
	assert(healer_res.max_hp == 35, "healer max_hp is 35")
	assert(healer_res.armor == 1, "healer armor is 1")
	assert(healer_res.attack_power == 5, "healer attack_power is 5")
	assert(is_equal_approx(healer_res.attack_range, 6.0), "healer attack_range is 6.0")
	assert(is_equal_approx(healer_res.move_speed, 3.2), "healer move_speed is 3.2")
	assert(healer_res.loot_table != null, "healer has valid loot_table")
	assert(healer_res.skills.size() >= 1, "healer has at least 1 equipped skill in data")

	var skill_res: SkillData = load("res://src/data/skills/resources/goblin_tribal_blessing.tres") as SkillData
	assert(skill_res != null, "goblin_tribal_blessing.tres exists and is SkillData")
	assert(skill_res.id == "goblin_tribal_blessing", "skill id is 'goblin_tribal_blessing'")
	assert(skill_res.display_name == "Bênção Tribal", "skill display_name is 'Bênção Tribal'")
	assert(is_equal_approx(skill_res.cooldown, 4.0), "skill cooldown is 4.0s")
	assert(skill_res.effects.size() >= 1, "skill contains at least 1 effect")
	assert(skill_res.effects[0].value_base == 25, "skill base heal value is 25")
	assert(skill_res.effects[0].target_type == SkillEffect.TargetType.ALLY_LOWEST_HP, "skill target_type is ALLY_LOWEST_HP (3)")

	print("PASS: 1.1 EnemyData (enemy_goblin_healer.tres) and SkillData (goblin_tribal_blessing.tres) verified")

	# --------------------------------------------------------------------------
	# Group 2: Prefab Instantiation & Components Verification
	# --------------------------------------------------------------------------
	print("\n[Group 2: Prefab Instantiation & Components Verification]")
	var healer_scene: PackedScene = load("res://src/entities/enemies/GoblinHealer.tscn") as PackedScene
	assert(healer_scene != null, "GoblinHealer.tscn loaded")
	var healer: CharacterEntity = healer_scene.instantiate() as CharacterEntity
	root.add_child(healer)

	assert(healer.stats_component != null, "GoblinHealer has StatsComponent")
	assert(healer.health_component != null, "GoblinHealer has HealthComponent")
	assert(healer.hurtbox != null, "GoblinHealer has Hurtbox3D")
	assert(healer.movement_component != null, "GoblinHealer has MovementComponent")
	assert(healer.threat_table != null, "GoblinHealer has ThreatTable")
	assert(healer.navigation_agent != null, "GoblinHealer has NavigationAgent3D")
	assert(healer.skill_holder != null, "GoblinHealer has SkillHolderComponent")
	assert(healer.collision_layer == 4, "GoblinHealer collision_layer is Enemy_Bodies (4)")
	assert(healer.hurtbox.collision_layer == 64, "GoblinHealer hurtbox collision_layer is Enemy_Hurtboxes (64)")

	var healer_ai: GoblinHealerAI = healer.get_node_or_null("Components/GoblinHealerAI") as GoblinHealerAI
	assert(healer_ai != null, "GoblinHealer has GoblinHealerAI attached")
	assert(is_equal_approx(healer_ai.heal_threshold, 0.50), "GoblinHealerAI heal_threshold is 0.50 (50%)")
	assert(healer_ai.heal_amount == 25, "GoblinHealerAI heal_amount is 25")
	assert(is_equal_approx(healer_ai.heal_cooldown, 4.0), "GoblinHealerAI heal_cooldown is 4.0")
	assert(is_equal_approx(healer_ai.keep_distance, 6.0), "GoblinHealerAI keep_distance is 6.0m")

	assert(healer.health_component.max_hp == 35, "GoblinHealer health initialized to 35")
	assert(healer.health_component.current_hp == 35, "GoblinHealer current_hp initialized to 35")
	assert(int(healer.stats_component.get_stat("armor")) == 1, "GoblinHealer armor initialized to 1")
	assert(int(healer.stats_component.get_stat("attack_power")) == 5, "GoblinHealer attack_power initialized to 5")
	assert(is_equal_approx(healer.stats_component.get_stat("move_speed"), 3.2), "GoblinHealer move_speed initialized to 3.2")

	healer.free()
	print("PASS: 2.1 Prefab GoblinHealer.tscn instantiation, components wiring and stats verified")

	# --------------------------------------------------------------------------
	# Group 3: Healing When Ally HP < 50% & EventBus Signal Emission
	# --------------------------------------------------------------------------
	print("\n[Group 3: Healing Under 50% HP & EventBus Emission]")
	var healer_inst: CharacterEntity = healer_scene.instantiate() as CharacterEntity
	root.add_child(healer_inst)
	var ai: GoblinHealerAI = healer_inst.get_node_or_null("Components/GoblinHealerAI") as GoblinHealerAI

	var warrior_scene: PackedScene = load("res://src/entities/enemies/GoblinWarrior.tscn") as PackedScene
	var warrior_ally: CharacterEntity = warrior_scene.instantiate() as CharacterEntity
	root.add_child(warrior_ally)

	# Damage warrior down to ~28.8% HP (13/45 < 50%)
	warrior_ally.health_component.current_hp = 13
	assert(warrior_ally.health_component.current_hp == 13, "Warrior HP set to 13/45 (28.8% < 50%)")

	var eventbus_signal_received: Dictionary = {
		"received": false,
		"target": null,
		"healer": null,
		"amount": 0
	}

	var bus: EventBusSingleton = root.get_node("EventBus") as EventBusSingleton
	var connection_callable: Callable = func(t: Node3D, h: Node3D, a: int) -> void:
		eventbus_signal_received["received"] = true
		eventbus_signal_received["target"] = t
		eventbus_signal_received["healer"] = h
		eventbus_signal_received["amount"] = a

	bus.healing_applied.connect(connection_callable)

	var ai_heal_executed: Dictionary = {
		"executed": false,
		"target": null,
		"amount": 0
	}
	ai.heal_executed.connect(func(t: CharacterEntity, a: int) -> void:
		ai_heal_executed["executed"] = true
		ai_heal_executed["target"] = t
		ai_heal_executed["amount"] = a
	)

	# Trigger evaluation of healing
	ai.evaluate_healing([warrior_ally])

	assert(ai_heal_executed["executed"], "GoblinHealerAI executed heal on damaged ally")
	assert(ai_heal_executed["target"] == warrior_ally, "Healed target is warrior_ally")
	assert(ai_heal_executed["amount"] == 25, "Heal amount is 25 HP")

	assert(eventbus_signal_received["received"], "EventBus.healing_applied was emitted")
	assert(eventbus_signal_received["target"] == warrior_ally, "EventBus target is warrior_ally")
	assert(eventbus_signal_received["healer"] == healer_inst, "EventBus healer is healer_inst")
	assert(eventbus_signal_received["amount"] == 25, "EventBus heal amount is 25")

	assert(warrior_ally.health_component.current_hp == 38, "Warrior HP restored by 25 (13 -> 38 HP)")
	assert(not ai.can_cast_heal(), "Healer AI is on cooldown after casting heal")
	assert(ai._heal_timer > 3.5, "Heal cooldown timer initialized to ~4.0s")

	bus.healing_applied.disconnect(connection_callable)
	healer_inst.free()
	warrior_ally.free()
	print("PASS: 3.1 Healing when ally HP < 50% (25 HP restore and EventBus.healing_applied emission) verified")

	# --------------------------------------------------------------------------
	# Group 4: No Healing When All Allies Have HP >= 50%
	# --------------------------------------------------------------------------
	print("\n[Group 4: No Healing When All Allies HP >= 50%]")
	var healer_inst2: CharacterEntity = healer_scene.instantiate() as CharacterEntity
	root.add_child(healer_inst2)
	var ai2: GoblinHealerAI = healer_inst2.get_node_or_null("Components/GoblinHealerAI") as GoblinHealerAI

	var healthy_warrior: CharacterEntity = warrior_scene.instantiate() as CharacterEntity
	root.add_child(healthy_warrior)
	healthy_warrior.health_component.current_hp = 25 # 25/45 = ~55.5% (>= 50%)

	var no_heal_tracker: Dictionary = {
		"received": false
	}
	var bus_callable2: Callable = func(_t: Node3D, _h: Node3D, _a: int) -> void:
		no_heal_tracker["received"] = true
	bus.healing_applied.connect(bus_callable2)

	ai2.evaluate_healing([healthy_warrior])

	assert(not no_heal_tracker["received"], "No heal signal emitted when ally is above 50% HP")
	assert(healthy_warrior.health_component.current_hp == 25, "Ally HP remains unchanged at 25")
	assert(ai2.can_cast_heal(), "Healer AI did not consume its cooldown")

	bus.healing_applied.disconnect(bus_callable2)
	healer_inst2.free()
	healthy_warrior.free()
	print("PASS: 4.1 No heal triggered when ally HP >= 50% verified")

	# --------------------------------------------------------------------------
	# Group 5: Target Prioritization (Lowest HP% and Elite/Captain Tie-Breaking)
	# --------------------------------------------------------------------------
	print("\n[Group 5: Target Prioritization (Lowest HP% & Elite/Captain Priority)]")
	var healer_inst3: CharacterEntity = healer_scene.instantiate() as CharacterEntity
	root.add_child(healer_inst3)
	var ai3: GoblinHealerAI = healer_inst3.get_node_or_null("Components/GoblinHealerAI") as GoblinHealerAI

	# Scenario A: Lowest HP percentage
	var ally_a: CharacterEntity = warrior_scene.instantiate() as CharacterEntity
	var ally_b: CharacterEntity = warrior_scene.instantiate() as CharacterEntity
	root.add_child(ally_a)
	root.add_child(ally_b)

	ally_a.health_component.current_hp = 20 # 20/45 = 44.4% (< 50%)
	ally_b.health_component.current_hp = 9  # 9/45 = 20.0% (< 50%)

	var target_selected: CharacterEntity = ai3.find_best_heal_target([ally_a, ally_b])
	assert(target_selected == ally_b, "Healer AI prioritized ally_b with lower HP% (20% vs 44%)")

	ai3.evaluate_healing([ally_a, ally_b])
	assert(ally_b.health_component.current_hp == 34, "Ally B received 25 HP heal (9 -> 34 HP)")
	assert(ally_a.health_component.current_hp == 20, "Ally A HP remained 20")

	ally_a.free()
	ally_b.free()

	# Scenario B: Tie-breaking favoring Elite/Captain
	ai3._heal_timer = 0.0 # reset cooldown

	var minion_c: CharacterEntity = CharacterEntity.new()
	root.add_child(minion_c)
	minion_c.name = "GoblinMinion"
	var minion_enemy_data: EnemyData = EnemyData.new()
	minion_enemy_data.tier = EnemyData.EnemyTier.MINION
	minion_enemy_data.enemy_id = "goblin_warrior"
	minion_c.enemy_data = minion_enemy_data
	var minion_hp: HealthComponent = HealthComponent.new()
	minion_hp.max_hp = 50
	minion_hp.current_hp = 15 # 15/50 = 30.0%
	minion_hp.is_alive = true
	minion_c.add_child(minion_hp)
	minion_c.health_component = minion_hp

	var captain_ally: CharacterEntity = CharacterEntity.new()
	root.add_child(captain_ally)
	captain_ally.name = "GoblinCaptain"
	var captain_enemy_data: EnemyData = EnemyData.new()
	captain_enemy_data.tier = EnemyData.EnemyTier.ELITE
	captain_enemy_data.enemy_id = "goblin_captain"
	captain_ally.enemy_data = captain_enemy_data
	var captain_hp: HealthComponent = HealthComponent.new()
	captain_hp.max_hp = 100
	captain_hp.current_hp = 30 # 30/100 = 30.0% (Exact tie with minion_c)
	captain_hp.is_alive = true
	captain_ally.add_child(captain_hp)
	captain_ally.health_component = captain_hp

	var tie_target: CharacterEntity = ai3.find_best_heal_target([minion_c, captain_ally])
	assert(tie_target == captain_ally, "Healer AI prioritized Captain/Elite in HP% tie (30% vs 30%)")

	ai3.evaluate_healing([minion_c, captain_ally])
	assert(captain_hp.current_hp == 55, "Captain received 25 HP heal (30 -> 55 HP)")
	assert(minion_hp.current_hp == 15, "Minion HP remained 15")

	minion_c.free()
	captain_ally.free()
	healer_inst3.free()
	print("PASS: 5.1 Lowest HP% prioritization and Elite/Captain tie-breaking verified")

	# --------------------------------------------------------------------------
	# Group 6: Distance Maintenance & Tactical Retreat (Kiting)
	# --------------------------------------------------------------------------
	print("\n[Group 6: Distance Maintenance & Tactical Retreat]")
	var healer_inst4: CharacterEntity = healer_scene.instantiate() as CharacterEntity
	root.add_child(healer_inst4)
	healer_inst4.global_position = Vector3(0.0, 0.0, 0.0)
	var ai4: GoblinHealerAI = healer_inst4.get_node_or_null("Components/GoblinHealerAI") as GoblinHealerAI

	var dummy_hero: CharacterEntity = CharacterEntity.new()
	root.add_child(dummy_hero)
	var dhero_hp: HealthComponent = HealthComponent.new()
	dhero_hp.max_hp = 100
	dhero_hp.current_hp = 100
	dhero_hp.is_alive = true
	dummy_hero.add_child(dhero_hp)
	dummy_hero.health_component = dhero_hp

	# 1. Hero too close (< 4.0m, e.g. at 2.0m): Healer retreats (kiting)
	dummy_hero.global_position = Vector3(2.0, 0.0, 0.0)
	ai4.process_ai(0.1, [], [dummy_hero])
	assert(healer_inst4.movement_component.is_moving, "Healer retreats when hero approaches < 4.0m (at 2.0m)")
	assert(healer_inst4.movement_component.current_target_position.x < 0.0, "Healer retreat vector moves opposite to hero (+X hero -> -X destination)")

	# 2. Hero in comfort zone (~6.0m, between 4.0m and 8.0m): Healer stops movement
	dummy_hero.global_position = Vector3(6.0, 0.0, 0.0)
	ai4.process_ai(0.1, [], [dummy_hero])
	assert(not healer_inst4.movement_component.is_moving, "Healer stops movement in comfortable backline zone (6.0m)")

	# 3. Hero too far (> 8.0m, e.g. at 12.0m): Healer advances to keep within support range
	dummy_hero.global_position = Vector3(12.0, 0.0, 0.0)
	ai4.process_ai(0.1, [], [dummy_hero])
	assert(healer_inst4.movement_component.is_moving, "Healer advances when battle moves too far away (> 8.0m)")

	dummy_hero.free()
	healer_inst4.free()
	print("PASS: 6.1 Distance maintenance (~6m), retreat (<4m) and advance (>8m) verified")

	# --------------------------------------------------------------------------
	# Group 7: Cooldown Lifecycle & Process AI Integration
	# --------------------------------------------------------------------------
	print("\n[Group 7: Cooldown Lifecycle & Process AI Integration]")
	var healer_inst5: CharacterEntity = healer_scene.instantiate() as CharacterEntity
	root.add_child(healer_inst5)
	var ai5: GoblinHealerAI = healer_inst5.get_node_or_null("Components/GoblinHealerAI") as GoblinHealerAI

	var wounded_ally: CharacterEntity = warrior_scene.instantiate() as CharacterEntity
	root.add_child(wounded_ally)
	wounded_ally.health_component.current_hp = 10 # 10/45 < 50%

	var hero_for_combat: CharacterEntity = CharacterEntity.new()
	root.add_child(hero_for_combat)
	hero_for_combat.global_position = Vector3(6.0, 0.0, 0.0)
	var hfc_hp: HealthComponent = HealthComponent.new()
	hfc_hp.max_hp = 100
	hfc_hp.current_hp = 100
	hfc_hp.is_alive = true
	hero_for_combat.add_child(hfc_hp)
	hero_for_combat.health_component = hfc_hp

	# First cycle: casts heal (10 -> 35 HP) and starts cooldown
	ai5.process_ai(0.1, [wounded_ally], [hero_for_combat])
	assert(wounded_ally.health_component.current_hp == 35, "Ally healed to 35 HP on first process_ai")
	assert(not ai5.can_cast_heal(), "Cannot cast heal immediately due to cooldown")

	# Subsequent cycle: damage ally again, but healer is on cooldown
	wounded_ally.health_component.current_hp = 5
	ai5.process_ai(0.1, [wounded_ally], [hero_for_combat])
	assert(wounded_ally.health_component.current_hp == 5, "Ally not healed while cooldown is active")

	# Advance time past cooldown duration (4.0s)
	ai5.process_ai(4.0, [wounded_ally], [hero_for_combat])
	assert(wounded_ally.health_component.current_hp == 30, "Ally healed (5 -> 30 HP) after 4.0s cooldown elapsed")

	wounded_ally.free()
	hero_for_combat.free()
	healer_inst5.free()
	print("PASS: 7.1 Cooldown lifecycle and process_ai integration verified")

	# --------------------------------------------------------------------------
	# Group 8: Edge Cases, Dead Entities and Null Safety
	# --------------------------------------------------------------------------
	print("\n[Group 8: Edge Cases, Dead Entities & Null Safety]")
	var standalone_ai: GoblinHealerAI = GoblinHealerAI.new()
	root.add_child(standalone_ai)

	# Null and empty safety
	standalone_ai.process_ai(0.1, [], [])
	standalone_ai.process_ai(0.1, [null], [null])
	standalone_ai.evaluate_healing([])
	standalone_ai.evaluate_healing([null])

	# Dead ally filtering
	var dead_ally: CharacterEntity = CharacterEntity.new()
	root.add_child(dead_ally)
	var dead_hp: HealthComponent = HealthComponent.new()
	dead_hp.max_hp = 50
	dead_hp.current_hp = 0
	dead_hp.is_alive = false
	dead_ally.add_child(dead_hp)
	dead_ally.health_component = dead_hp

	assert(standalone_ai.get_living_allies([dead_ally]).is_empty(), "Dead ally filtered from living allies list")
	assert(standalone_ai.find_best_heal_target([dead_ally]) == null, "Dead ally is not selected for healing")

	# Dead healer safety
	var dead_healer: CharacterEntity = healer_scene.instantiate() as CharacterEntity
	root.add_child(dead_healer)
	dead_healer.health_component.current_hp = 0
	dead_healer.health_component.is_alive = false
	var dead_healer_ai: GoblinHealerAI = dead_healer.get_node_or_null("Components/GoblinHealerAI") as GoblinHealerAI

	var live_wounded: CharacterEntity = CharacterEntity.new()
	root.add_child(live_wounded)
	var lw_hp: HealthComponent = HealthComponent.new()
	lw_hp.max_hp = 50
	lw_hp.current_hp = 10
	lw_hp.is_alive = true
	live_wounded.add_child(lw_hp)
	live_wounded.health_component = lw_hp

	dead_healer_ai.evaluate_healing([live_wounded])
	assert(lw_hp.current_hp == 10, "Dead healer cannot cast healing")

	standalone_ai.free()
	dead_ally.free()
	dead_healer.free()
	live_wounded.free()
	print("PASS: 8.1 Dead entities filtering, dead healer checks and null safety verified")

	print("\n================================================================================")
	print("=== ALL GOBLIN HEALER AI & PREFAB UNIT TESTS PASSED (8/8 GROUPS) ===")
	print("================================================================================")
	quit(0)
