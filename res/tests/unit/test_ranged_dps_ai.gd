extends SceneTree

# ==============================================================================
# Unit & Integration Test Suite: RangedDPSAIController.gd (Task M4.5)
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
	print("--- Starting RangedDPSAIController Unit & Integration Tests (Task M4.5) ---")
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
	var standalone_ai: RangedDPSAIController = RangedDPSAIController.new()
	root.add_child(standalone_ai)

	assert(standalone_ai != null, "RangedDPSAIController instance created")
	assert(standalone_ai.actor == null, "Initial standalone actor is null")
	assert(is_equal_approx(standalone_ai.safe_distance, 6.0), "Default safe_distance is 6.0")
	assert(is_equal_approx(standalone_ai.kiting_trigger_distance, 2.5), "Default kiting_trigger_distance is 2.5")
	assert(is_equal_approx(standalone_ai.kiting_speed_multiplier, 1.15), "Default kiting_speed_multiplier is 1.15")
	assert(not standalone_ai.is_kiting, "Initial is_kiting state is false")

	# Standalone execution on empty / null data without crashing
	standalone_ai.evaluate_combat_tactics(0.1, [])
	standalone_ai.evaluate_combat_tactics(0.1, [null])
	assert(standalone_ai.get_living_enemies([]).is_empty(), "get_living_enemies on empty returns empty")
	assert(standalone_ai.find_nearest_enemy([]) == null, "find_nearest_enemy on empty returns null")
	assert(standalone_ai.find_lowest_hp_enemy([]) == null, "find_lowest_hp_enemy on empty returns null")
	assert(standalone_ai.get_distance_to_target(null) == INF, "get_distance_to_target null returns INF")
	assert(not standalone_ai.execute_arrow_shot(null), "execute_arrow_shot null returns false")
	assert(not standalone_ai.execute_multishot([]), "execute_multishot empty returns false")

	standalone_ai.free()
	print("PASS: 1.1 Standalone RangedDPSAIController properties and null safety verified")

	# --------------------------------------------------------------------------
	# Group 2: Target Acquisition & Lowest HP Enemy Selection
	# --------------------------------------------------------------------------
	print("\n[Group 2: Target Acquisition & Lowest HP Selection]")
	var hero_char_2: CharacterEntity = CharacterEntity.new()
	hero_char_2.name = "Elysia_2"
	root.add_child(hero_char_2)
	hero_char_2.global_position = Vector3(0.0, 0.0, 0.0)

	var ai_2: RangedDPSAIController = RangedDPSAIController.new()
	ai_2.actor = hero_char_2
	hero_char_2.add_child(ai_2)

	# Mob A at 6.0m (HP 100)
	var mob_a: CharacterEntity = CharacterEntity.new()
	mob_a.name = "MobA_100hp"
	root.add_child(mob_a)
	mob_a.global_position = Vector3(6.0, 0.0, 0.0)
	var hp_a: HealthComponent = HealthComponent.new()
	hp_a.max_hp = 100
	hp_a.current_hp = 100
	hp_a.is_alive = true
	mob_a.add_child(hp_a)
	mob_a.health_component = hp_a

	# Mob B at 7.0m (HP 30 - Lowest HP)
	var mob_b: CharacterEntity = CharacterEntity.new()
	mob_b.name = "MobB_30hp"
	root.add_child(mob_b)
	mob_b.global_position = Vector3(7.0, 0.0, 0.0)
	var hp_b: HealthComponent = HealthComponent.new()
	hp_b.max_hp = 100
	hp_b.current_hp = 30
	hp_b.is_alive = true
	mob_b.add_child(hp_b)
	mob_b.health_component = hp_b

	# Mob C at 5.0m (HP 80 - Closest)
	var mob_c: CharacterEntity = CharacterEntity.new()
	mob_c.name = "MobC_80hp"
	root.add_child(mob_c)
	mob_c.global_position = Vector3(5.0, 0.0, 0.0)
	var hp_c: HealthComponent = HealthComponent.new()
	hp_c.max_hp = 100
	hp_c.current_hp = 80
	hp_c.is_alive = true
	mob_c.add_child(hp_c)
	mob_c.health_component = hp_c

	var pack_2: Array[CharacterEntity] = [mob_a, mob_b, mob_c]
	var living_2: Array[CharacterEntity] = ai_2.get_living_enemies(pack_2)
	assert(living_2.size() == 3, "All 3 mobs are living")

	var nearest_2: CharacterEntity = ai_2.find_nearest_enemy(living_2)
	assert(nearest_2 == mob_c, "Nearest enemy must be Mob C (5.0m away)")

	var lowest_hp_2: CharacterEntity = ai_2.find_lowest_hp_enemy(living_2)
	assert(lowest_hp_2 == mob_b, "Lowest HP enemy must be Mob B (30 HP)")

	# Kill Mob B -> lowest HP should become Mob C (80 HP)
	hp_b.current_hp = 0
	hp_b.is_alive = false
	var living_after_b: Array[CharacterEntity] = ai_2.get_living_enemies(pack_2)
	assert(living_after_b.size() == 2, "2 living mobs remaining")
	assert(ai_2.find_lowest_hp_enemy(living_after_b) == mob_c, "Lowest HP enemy switches to Mob C (80 HP)")

	print("PASS: 2.1 Lowest HP enemy selection and dead mob filtering verified")
	hero_char_2.free()
	mob_a.free()
	mob_b.free()
	mob_c.free()

	# --------------------------------------------------------------------------
	# Group 3: Kiting Activation (< 2.5m) and Flee Vector Direction
	# --------------------------------------------------------------------------
	print("\n[Group 3: Kiting Algorithm Activation & Flee Vector]")
	var dps_3: CharacterEntity = CharacterEntity.new()
	dps_3.name = "Elysia_Kiting"
	root.add_child(dps_3)
	dps_3.global_position = Vector3(0.0, 0.0, 0.0)

	var move_comp_3: MovementComponent = MovementComponent.new()
	move_comp_3.name = "MovementComponent"
	move_comp_3.character_body = dps_3
	dps_3.add_child(move_comp_3)
	dps_3.movement_component = move_comp_3

	var hp_dps_3: HealthComponent = HealthComponent.new()
	hp_dps_3.max_hp = 85
	hp_dps_3.current_hp = 85
	dps_3.add_child(hp_dps_3)
	dps_3.health_component = hp_dps_3

	var ai_3: RangedDPSAIController = RangedDPSAIController.new()
	ai_3.actor = dps_3
	dps_3.add_child(ai_3)

	# Monster positioned at (2.0, 0, 0) -> distance is 2.0m (< 2.5m trigger)
	var mob_threat: CharacterEntity = CharacterEntity.new()
	mob_threat.name = "Mob_Threat"
	root.add_child(mob_threat)
	mob_threat.global_position = Vector3(2.0, 0.0, 0.0)
	var hp_threat: HealthComponent = HealthComponent.new()
	hp_threat.max_hp = 60
	hp_threat.current_hp = 60
	hp_threat.is_alive = true
	mob_threat.add_child(hp_threat)
	mob_threat.health_component = hp_threat

	var tracker_3: Dictionary = {
		"kiting_started": false,
		"threat_enemy": null
	}
	ai_3.kiting_started.connect(func(threat: CharacterEntity) -> void:
		tracker_3["kiting_started"] = true
		tracker_3["threat_enemy"] = threat
	)

	# Flee direction calculation test: actor at (0,0,0), threat at (2,0,0) -> flee towards (-1, 0, 0)
	var flee_dir: Vector3 = ai_3.calculate_flee_direction(mob_threat)
	assert(is_equal_approx(flee_dir.x, -1.0) and is_equal_approx(flee_dir.z, 0.0), "Flee direction is Vector3(-1, 0, 0) away from threat")

	# Evaluate tactics: distance 2.0m < 2.5m -> triggers kiting
	ai_3.evaluate_combat_tactics(0.1, [mob_threat])

	assert(ai_3.is_kiting, "is_kiting state changed to true")
	assert(tracker_3["kiting_started"], "signal kiting_started emitted")
	assert(tracker_3["threat_enemy"] == mob_threat, "Threat enemy is mob_threat")
	assert(is_equal_approx(move_comp_3.speed_multiplier, 1.15), "Speed multiplier increased to 1.15x (15% kiting bonus)")
	assert(move_comp_3.is_moving, "MovementComponent is actively executing flee movement")
	assert(move_comp_3.current_target_position.x < 0.0, "Flee target position is negative X (opposite to enemy)")

	print("PASS: 3.1 Kiting activation (< 2.5m), speed multiplier 1.15x and opposite flee vector verified")
	dps_3.free()
	mob_threat.free()

	# --------------------------------------------------------------------------
	# Group 4: Opportunity Shot Execution During Kiting
	# --------------------------------------------------------------------------
	print("\n[Group 4: Opportunity Shot During Kiting]")
	var dps_4: CharacterEntity = CharacterEntity.new()
	dps_4.name = "Elysia_Opportunity"
	root.add_child(dps_4)
	dps_4.global_position = Vector3(0.0, 0.0, 0.0)

	var move_comp_4: MovementComponent = MovementComponent.new()
	move_comp_4.character_body = dps_4
	dps_4.add_child(move_comp_4)
	dps_4.movement_component = move_comp_4

	var hp_dps_4: HealthComponent = HealthComponent.new()
	hp_dps_4.max_hp = 85
	hp_dps_4.current_hp = 85
	hp_dps_4.max_mana = 60.0
	hp_dps_4.current_mana = 60.0
	dps_4.add_child(hp_dps_4)
	dps_4.health_component = hp_dps_4

	var holder_4: SkillHolderComponent = SkillHolderComponent.new()
	dps_4.add_child(holder_4)
	dps_4.skill_holder = holder_4
	holder_4.setup(dps_4)

	var ai_4: RangedDPSAIController = RangedDPSAIController.new()
	ai_4.actor = dps_4
	dps_4.add_child(ai_4)

	var mob_4: CharacterEntity = CharacterEntity.new()
	mob_4.name = "Mob_4"
	root.add_child(mob_4)
	mob_4.global_position = Vector3(2.0, 0.0, 0.0) # < 2.5m
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
		"shot_fired": false,
		"shot_target": null
	}
	ai_4.arrow_shot_executed.connect(func(target: CharacterEntity) -> void:
		tracker_4["shot_fired"] = true
		tracker_4["shot_target"] = target
	)

	# Execute tactics in kiting distance: kiting active AND opportunity shot fired
	ai_4.evaluate_combat_tactics(0.1, [mob_4])

	assert(ai_4.is_kiting, "is_kiting is true")
	assert(tracker_4["shot_fired"], "signal arrow_shot_executed fired as opportunity shot during kiting")
	assert(tracker_4["shot_target"] == mob_4, "Target of arrow shot was mob_4")
	assert(hp_mob_4.current_hp < 100, "Mob took arrow damage during kiting")
	assert(threat_4.get_threat(dps_4) > 0.0, "Threat generated in mob ThreatTable")

	print("PASS: 4.1 Opportunity shot executed during kiting when skill ready")
	dps_4.free()
	mob_4.free()

	# --------------------------------------------------------------------------
	# Group 5: Kiting Termination upon Reaching Safe Distance (6.0m)
	# --------------------------------------------------------------------------
	print("\n[Group 5: Kiting Termination at Safe Distance (6.0m)]")
	var dps_5: CharacterEntity = CharacterEntity.new()
	dps_5.name = "Elysia_EndKiting"
	root.add_child(dps_5)
	dps_5.global_position = Vector3(0.0, 0.0, 0.0)

	var move_comp_5: MovementComponent = MovementComponent.new()
	move_comp_5.character_body = dps_5
	move_comp_5.speed_multiplier = 1.15
	move_comp_5.is_moving = true
	dps_5.add_child(move_comp_5)
	dps_5.movement_component = move_comp_5

	var hp_dps_5: HealthComponent = HealthComponent.new()
	hp_dps_5.max_hp = 85
	hp_dps_5.current_hp = 85
	dps_5.add_child(hp_dps_5)
	dps_5.health_component = hp_dps_5

	var ai_5: RangedDPSAIController = RangedDPSAIController.new()
	ai_5.actor = dps_5
	ai_5.is_kiting = true # Start in kiting state
	dps_5.add_child(ai_5)

	# Monster positioned at 6.2m (>= safe_distance 6.0m)
	var mob_5: CharacterEntity = CharacterEntity.new()
	mob_5.name = "Mob_SafeDist"
	root.add_child(mob_5)
	mob_5.global_position = Vector3(6.2, 0.0, 0.0)
	var hp_mob_5: HealthComponent = HealthComponent.new()
	hp_mob_5.max_hp = 60
	hp_mob_5.current_hp = 60
	hp_mob_5.is_alive = true
	mob_5.add_child(hp_mob_5)
	mob_5.health_component = hp_mob_5

	var tracker_5: Dictionary = {
		"kiting_ended": false
	}
	ai_5.kiting_ended.connect(func() -> void:
		tracker_5["kiting_ended"] = true
	)

	# Evaluate tactics: enemy at 6.2m >= 6.0m -> kiting terminates
	ai_5.evaluate_combat_tactics(0.1, [mob_5])

	assert(not ai_5.is_kiting, "is_kiting state changed to false")
	assert(tracker_5["kiting_ended"], "signal kiting_ended emitted")
	assert(is_equal_approx(move_comp_5.speed_multiplier, 1.0), "Speed multiplier reset to 1.0x")
	assert(not move_comp_5.is_moving, "MovementComponent stopped")

	print("PASS: 5.1 Kiting termination, movement stop and speed reset at 6.0m verified")
	dps_5.free()
	mob_5.free()

	# --------------------------------------------------------------------------
	# Group 6: Safe Distance Combat & Focus on Lowest HP Mob
	# --------------------------------------------------------------------------
	print("\n[Group 6: Safe Distance Combat & Focus on Lowest HP]")
	var dps_6: CharacterEntity = CharacterEntity.new()
	dps_6.name = "Elysia_SafeCombat"
	root.add_child(dps_6)
	dps_6.global_position = Vector3(0.0, 0.0, 0.0)

	var hp_dps_6: HealthComponent = HealthComponent.new()
	hp_dps_6.max_hp = 85
	hp_dps_6.current_hp = 85
	hp_dps_6.max_mana = 60.0
	hp_dps_6.current_mana = 60.0
	dps_6.add_child(hp_dps_6)
	dps_6.health_component = hp_dps_6

	var holder_6: SkillHolderComponent = SkillHolderComponent.new()
	dps_6.add_child(holder_6)
	dps_6.skill_holder = holder_6
	holder_6.setup(dps_6)

	var ai_6: RangedDPSAIController = RangedDPSAIController.new()
	ai_6.actor = dps_6
	dps_6.add_child(ai_6)

	# Mob 1 at 6.0m (HP 100)
	var mob_6_tanky: CharacterEntity = CharacterEntity.new()
	mob_6_tanky.name = "Mob_100HP"
	root.add_child(mob_6_tanky)
	mob_6_tanky.global_position = Vector3(6.0, 0.0, 0.0)
	var hp_6_1: HealthComponent = HealthComponent.new()
	hp_6_1.max_hp = 100
	hp_6_1.current_hp = 100
	hp_6_1.is_alive = true
	mob_6_tanky.add_child(hp_6_1)
	mob_6_tanky.health_component = hp_6_1

	# Mob 2 at 6.5m (HP 25 - Lowest HP)
	var mob_6_weak: CharacterEntity = CharacterEntity.new()
	mob_6_weak.name = "Mob_25HP"
	root.add_child(mob_6_weak)
	mob_6_weak.global_position = Vector3(6.5, 0.0, 0.0)
	var hp_6_2: HealthComponent = HealthComponent.new()
	hp_6_2.max_hp = 100
	hp_6_2.current_hp = 25
	hp_6_2.is_alive = true
	mob_6_weak.add_child(hp_6_2)
	mob_6_weak.health_component = hp_6_2

	# Single target test: disable multishot by setting it to null for this subtest
	ai_6.multishot_skill = null

	var tracker_6: Dictionary = {
		"arrow_shot": false,
		"target": null
	}
	ai_6.arrow_shot_executed.connect(func(target: CharacterEntity) -> void:
		tracker_6["arrow_shot"] = true
		tracker_6["target"] = target
	)

	ai_6.evaluate_combat_tactics(0.1, [mob_6_tanky, mob_6_weak])

	assert(tracker_6["arrow_shot"], "signal arrow_shot_executed emitted at safe distance")
	assert(tracker_6["target"] == mob_6_weak, "Arrow shot targeted mob with lowest HP (Mob_25HP)")
	assert(hp_6_2.current_hp < 25, "Weak mob took arrow damage")
	assert(hp_6_1.current_hp == 100, "Tanky mob was untouched by single arrow")

	print("PASS: 6.1 Safe distance combat prioritized target with lowest HP")
	dps_6.free()
	mob_6_tanky.free()
	mob_6_weak.free()

	# --------------------------------------------------------------------------
	# Group 7: Multishot Execution on Multiple Targets
	# --------------------------------------------------------------------------
	print("\n[Group 7: Multishot Execution on Multiple Targets]")
	var dps_7: CharacterEntity = CharacterEntity.new()
	dps_7.name = "Elysia_Multishot"
	root.add_child(dps_7)
	dps_7.global_position = Vector3(0.0, 0.0, 0.0)

	var hp_dps_7: HealthComponent = HealthComponent.new()
	hp_dps_7.max_hp = 85
	hp_dps_7.current_hp = 85
	hp_dps_7.max_mana = 60.0
	hp_dps_7.current_mana = 60.0
	dps_7.add_child(hp_dps_7)
	dps_7.health_component = hp_dps_7

	var holder_7: SkillHolderComponent = SkillHolderComponent.new()
	dps_7.add_child(holder_7)
	dps_7.skill_holder = holder_7
	holder_7.setup(dps_7)

	var ai_7: RangedDPSAIController = RangedDPSAIController.new()
	ai_7.actor = dps_7
	dps_7.add_child(ai_7)

	var mob_m1: CharacterEntity = CharacterEntity.new()
	root.add_child(mob_m1)
	mob_m1.global_position = Vector3(6.0, 0.0, 0.0)
	var hp_m1: HealthComponent = HealthComponent.new()
	hp_m1.max_hp = 50
	hp_m1.current_hp = 50
	hp_m1.is_alive = true
	mob_m1.add_child(hp_m1)
	mob_m1.health_component = hp_m1

	var mob_m2: CharacterEntity = CharacterEntity.new()
	root.add_child(mob_m2)
	mob_m2.global_position = Vector3(6.5, 0.0, 1.0)
	var hp_m2: HealthComponent = HealthComponent.new()
	hp_m2.max_hp = 50
	hp_m2.current_hp = 50
	hp_m2.is_alive = true
	mob_m2.add_child(hp_m2)
	mob_m2.health_component = hp_m2

	var mob_m3: CharacterEntity = CharacterEntity.new()
	root.add_child(mob_m3)
	mob_m3.global_position = Vector3(7.0, 0.0, -1.0)
	var hp_m3: HealthComponent = HealthComponent.new()
	hp_m3.max_hp = 50
	hp_m3.current_hp = 50
	hp_m3.is_alive = true
	mob_m3.add_child(hp_m3)
	mob_m3.health_component = hp_m3

	var tracker_7: Dictionary = {
		"multishot_fired": false,
		"targets": []
	}
	ai_7.multishot_executed.connect(func(targets: Array[CharacterEntity]) -> void:
		tracker_7["multishot_fired"] = true
		tracker_7["targets"] = targets
	)

	var pack_7: Array[CharacterEntity] = [mob_m1, mob_m2, mob_m3]
	ai_7.evaluate_combat_tactics(0.1, pack_7)

	assert(tracker_7["multishot_fired"], "signal multishot_executed emitted for multiple targets")
	assert(tracker_7["targets"].size() == 3, "Multishot struck all 3 targets in pack")
	assert(hp_m1.current_hp < 50, "Mob 1 took multishot damage")
	assert(hp_m2.current_hp < 50, "Mob 2 took multishot damage")
	assert(hp_m3.current_hp < 50, "Mob 3 took multishot damage")
	assert(holder_7.is_skill_on_cooldown("elysia_multishot"), "elysia_multishot skill is on cooldown")

	print("PASS: 7.1 Multishot execution on multiple targets verified")
	dps_7.free()
	mob_m1.free()
	mob_m2.free()
	mob_m3.free()

	# --------------------------------------------------------------------------
	# Group 8: Empty Packs, Dead Entities & Robust Edge Cases
	# --------------------------------------------------------------------------
	print("\n[Group 8: Empty Packs, Dead Entities & Robust Edge Cases]")
	var dps_8: CharacterEntity = CharacterEntity.new()
	dps_8.name = "Elysia_Edge"
	root.add_child(dps_8)

	var ai_8: RangedDPSAIController = RangedDPSAIController.new()
	ai_8.actor = dps_8
	dps_8.add_child(ai_8)

	var dead_mob: CharacterEntity = CharacterEntity.new()
	root.add_child(dead_mob)
	var hp_dead: HealthComponent = HealthComponent.new()
	hp_dead.is_alive = false
	hp_dead.current_hp = 0
	dead_mob.add_child(hp_dead)
	dead_mob.health_component = hp_dead

	var tracker_8: Dictionary = {
		"arrow_count": 0,
		"multi_count": 0,
		"kiting_count": 0
	}
	ai_8.arrow_shot_executed.connect(func(_t: CharacterEntity) -> void: tracker_8["arrow_count"] += 1)
	ai_8.multishot_executed.connect(func(_t: Array[CharacterEntity]) -> void: tracker_8["multi_count"] += 1)
	ai_8.kiting_started.connect(func(_t: CharacterEntity) -> void: tracker_8["kiting_count"] += 1)

	# Pass mixed null and dead mobs
	ai_8.evaluate_combat_tactics(0.1, [null, dead_mob, null])
	assert(tracker_8["arrow_count"] == 0, "No arrow shot fired on dead/null pack")
	assert(tracker_8["multi_count"] == 0, "No multishot fired on dead/null pack")
	assert(tracker_8["kiting_count"] == 0, "No kiting started on dead/null pack")

	print("PASS: 8.1 Empty packs and dead entities handled safely without spurious triggers")
	dps_8.free()
	dead_mob.free()

	print("\n================================================================================")
	print("=== ALL RANGED DPS AI CONTROLLER UNIT TESTS PASSED (8/8 GROUPS) ===")
	print("================================================================================")
	quit(0)
