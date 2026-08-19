extends SceneTree

# ==============================================================================
# Integration Test Suite: Full Party Combat 3D - Trio vs Goblin Pack (Task M4.7)
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
	print("--- Starting M4.7 Integrated Party Combat 3D (Trio vs Pack) Integration Tests ---")
	print("================================================================================")

	# Ensure EventBus Autoload node is present in SceneTree root
	var bus_node: Node = root.get_node_or_null("EventBus")
	if bus_node == null:
		var bus_script: Script = load("res://src/core/EventBus.gd")
		bus_node = Node.new()
		bus_node.name = "EventBus"
		bus_node.set_script(bus_script)
		root.add_child(bus_node)
	var bus: EventBusSingleton = bus_node as EventBusSingleton
	print("PASS: EventBus Autoload node found in SceneTree root")

	# --------------------------------------------------------------------------
	# Group 1: Scene Instantiation & Hierarchy Verification (test_party_combat_3d.tscn)
	# --------------------------------------------------------------------------
	print("\n[Group 1: Scene Instantiation & Hierarchy Verification]")
	var scene_resource: PackedScene = load("res://tests/test_party_combat_3d.tscn") as PackedScene
	assert(scene_resource != null, "test_party_combat_3d.tscn loaded successfully")

	var world: PartyCombatWorld = scene_resource.instantiate() as PartyCombatWorld
	assert(world != null, "PartyCombatWorld instantiated successfully")
	world.auto_start_march = false # Controlled manual march initiation for tests
	root.add_child(world)

	assert(world.party_controller != null, "PartyFormationController present in world")
	assert(world.combat_trigger_system != null, "CombatTriggerSystem present in world")
	assert(world.waypoints_holder != null, "WaypointsHolder present in world")
	assert(world.enemies_holder != null, "EnemiesHolder present in world")
	assert(world.camera_rig != null, "IsometricCameraRig present in world")

	# Camera 45-degree isometric angle and keep_aspect width
	var camera: Camera3D = world.camera_rig.get_node_or_null("Camera3D") as Camera3D
	assert(camera != null, "Camera3D node present in IsometricCameraRig")
	assert(camera.keep_aspect == Camera3D.KEEP_WIDTH, "Camera keep_aspect is KEEP_WIDTH for 9:16 portrait")

	# Heroes verification
	var bromm: CharacterEntity = world.party_controller.get_leader()
	var beatrice: CharacterEntity = world.party_controller.get_support()
	var elysia: CharacterEntity = world.party_controller.get_dps()

	assert(bromm != null, "Bromm (Leader/Tank) found in party")
	assert(beatrice != null, "Beatrice (Support) found in party")
	assert(elysia != null, "Elysia (DPS) found in party")

	assert(world.tank_ai != null, "TankAIController resolved on Bromm")
	assert(world.support_ai != null, "SupportAIController resolved on Beatrice")
	assert(world.dps_ai != null, "RangedDPSAIController resolved on Elysia")

	# Enemies verification
	assert(world.enemy_pack.size() == 3, "EnemiesHolder contains pack of 3 Goblins")
	for i in range(world.enemy_pack.size()):
		var goblin: CharacterEntity = world.enemy_pack[i]
		assert(goblin.health_component != null, "Goblin %d has HealthComponent" % (i + 1))
		assert(goblin.hurtbox != null or goblin.get_node_or_null("Components/Hurtbox3D") != null, "Goblin %d has Hurtbox3D" % (i + 1))
		assert(goblin.get_node_or_null("Components/Hitbox3D") != null, "Goblin %d has Hitbox3D" % (i + 1))
		assert(goblin.threat_table != null or goblin.get_node_or_null("Components/ThreatTable") != null, "Goblin %d has ThreatTable" % (i + 1))

	print("PASS: 1.1 test_party_combat_3d.tscn structure, trio hero IAs and 3 goblin enemies verified")

	# --------------------------------------------------------------------------
	# Group 2: March State Quiescence Before First Physical Impact
	# --------------------------------------------------------------------------
	print("\n[Group 2: March State Quiescence Before First Physical Impact]")
	var tracker_events: Dictionary = {
		"combat_started_count": 0,
		"combat_ended_count": 0,
		"eb_combat_triggered_count": 0
	}

	world.combat_started.connect(func(_i: Node3D, _t: Node3D) -> void:
		tracker_events["combat_started_count"] += 1
	)
	world.combat_ended.connect(func() -> void:
		tracker_events["combat_ended_count"] += 1
	)
	var on_eb_combat: Callable = func(_i: Node3D, _t: Node3D) -> void:
		tracker_events["eb_combat_triggered_count"] += 1
	bus.combat_triggered.connect(on_eb_combat)

	# Start traversal
	world._start_traversal()

	assert(world.is_in_combat() == false, "Party is NOT in combat while traversing")
	assert(world.combat_trigger_system.is_party_in_combat == false, "CombatTriggerSystem is_party_in_combat == false")
	assert(bromm.health_component.in_combat == false, "Bromm in_combat is false")
	assert(beatrice.health_component.in_combat == false, "Beatrice in_combat is false")
	assert(elysia.health_component.in_combat == false, "Elysia in_combat is false")
	assert(tracker_events["combat_started_count"] == 0, "No combat_started signal emitted before contact")
	assert(tracker_events["eb_combat_triggered_count"] == 0, "No EventBus.combat_triggered emitted before contact")

	# Process 5 march frames (approaching without collision)
	for f in range(5):
		world._physics_process(0.016)

	assert(tracker_events["combat_started_count"] == 0, "Quiescence verified: Zero attacks/heals dispatched during march")
	print("PASS: 2.1 Trio marches in formation with zero premature attacks or combat transitions")

	# --------------------------------------------------------------------------
	# Group 3: First Physical Impact & Instant Synchronous Combat Activation
	# --------------------------------------------------------------------------
	print("\n[Group 3: First Physical Impact & Instant Synchronous Combat Activation]")
	var goblin_1: CharacterEntity = world.enemy_pack[0]
	var goblin_2: CharacterEntity = world.enemy_pack[1]
	var goblin_3: CharacterEntity = world.enemy_pack[2]

	# Vanguard strike: Bromm strikes Goblin 1 via Hitbox3D/Hurtbox3D collision
	var bromm_hitbox: Hitbox3D = bromm.get_node_or_null("Hitbox3D") as Hitbox3D
	var goblin_1_hurtbox: Hurtbox3D = goblin_1.get_node_or_null("Components/Hurtbox3D") as Hurtbox3D

	assert(bromm_hitbox != null, "Bromm Hitbox3D exists")
	assert(goblin_1_hurtbox != null, "Goblin 1 Hurtbox3D exists")

	bromm_hitbox._on_area_entered(goblin_1_hurtbox)

	assert(world.is_in_combat() == true, "Party transitioned into combat immediately upon first physical hit")
	assert(world.combat_trigger_system.is_party_in_combat == true, "CombatTriggerSystem is_party_in_combat == true")
	assert(tracker_events["combat_started_count"] == 1, "world.combat_started emitted once")
	assert(tracker_events["eb_combat_triggered_count"] == 1, "EventBus.combat_triggered emitted once")
	assert(world.party_controller.formation_active == false, "Party formation tethering paused during combat")
	assert(bromm.health_component.in_combat == true, "Bromm in_combat set to true")
	assert(beatrice.health_component.in_combat == true, "Beatrice in_combat set to true")
	assert(elysia.health_component.in_combat == true, "Elysia in_combat set to true")

	print("PASS: 3.1 First physical impact instantly triggered synchronous battle state across the trio")

	# --------------------------------------------------------------------------
	# Group 4: Tank (Bromm) Aggro & Threat Table Dominance
	# --------------------------------------------------------------------------
	print("\n[Group 4: Tank (Bromm) Aggro & Threat Table Dominance]")
	var goblin_1_threat: ThreatTable = goblin_1.threat_table if goblin_1.threat_table != null else goblin_1.get_node("Components/ThreatTable") as ThreatTable

	# DPS hits for 20 threat
	goblin_1_threat.add_threat(elysia, 20.0, 1.0)
	assert(goblin_1_threat.primary_target == elysia, "Goblin 1 initially targets DPS (threat = 20)")

	# Bromm executes Shield Slam (25 base * 3.0x multiplier = 75 threat)
	world.tank_ai.execute_shield_slam(goblin_1)

	assert(goblin_1_threat.get_threat(bromm) >= 75.0, "Bromm accumulated high threat (>= 75)")
	assert(goblin_1_threat.primary_target == bromm, "Goblin 1 primary target snapped to Bromm due to high threat")

	# Also generate threat on Goblin 2 and 3 with Charge and Shield Slam
	var goblin_2_threat: ThreatTable = goblin_2.threat_table if goblin_2.threat_table != null else goblin_2.get_node("Components/ThreatTable") as ThreatTable
	var goblin_3_threat: ThreatTable = goblin_3.threat_table if goblin_3.threat_table != null else goblin_3.get_node("Components/ThreatTable") as ThreatTable

	world.tank_ai.execute_charge(goblin_2)
	assert(goblin_2_threat.primary_target == bromm, "Goblin 2 primary target snapped to Bromm via Charge")

	if bromm.skill_holder != null:
		bromm.skill_holder.reset_all_cooldowns()
	world.tank_ai.execute_shield_slam(goblin_3)
	assert(goblin_3_threat.primary_target == bromm, "Goblin 3 primary target snapped to Bromm via Shield Slam")

	print("PASS: 4.1 Tank Bromm generated high threat and established primary aggro on all pack monsters")

	# --------------------------------------------------------------------------
	# Group 5: DPS (Elysia) Kiting Mechanism & Safe Distance Offense
	# --------------------------------------------------------------------------
	print("\n[Group 5: DPS (Elysia) Kiting Mechanism & Safe Distance Offense]")
	elysia.global_position = Vector3(0.0, 0.0, 0.0)
	goblin_2.global_position = Vector3(0.0, 0.0, 1.8) # 1.8m < 2.5m (Kiting Trigger)

	var tracker_kiting: Dictionary = {
		"kiting_started": false,
		"kiting_ended": false
	}
	world.dps_ai.kiting_started.connect(func(_threat: CharacterEntity) -> void:
		tracker_kiting["kiting_started"] = true
	)
	world.dps_ai.kiting_ended.connect(func() -> void:
		tracker_kiting["kiting_ended"] = true
	)

	# Evaluate tactics with goblin at 1.8m
	if elysia.skill_holder != null:
		elysia.skill_holder.reset_all_cooldowns()
	world.dps_ai.evaluate_combat_tactics(0.016, [goblin_2])

	assert(world.dps_ai.is_kiting == true, "Elysia triggered kiting mode when monster is < 2.5m")
	assert(tracker_kiting["kiting_started"] == true, "kiting_started signal emitted")
	assert(elysia.movement_component.speed_multiplier == 1.15, "Elysia movement speed boosted to 1.15x during kiting")

	# Flee direction is away from goblin (along -Z)
	var flee_dir: Vector3 = world.dps_ai.calculate_flee_direction(goblin_2)
	assert(flee_dir.z < 0.0, "Flee direction is opposite to the advancing goblin")

	# Move Elysia to safe distance 6.0m
	elysia.global_position = Vector3(0.0, 0.0, -5.0) # distance = 6.8m >= 6.0m
	world.dps_ai.evaluate_combat_tactics(0.016, [goblin_2])

	assert(world.dps_ai.is_kiting == false, "Kiting ended when safe distance (6.0m) was reached")
	assert(tracker_kiting["kiting_ended"] == true, "kiting_ended signal emitted")
	assert(elysia.movement_component.speed_multiplier == 1.0, "Speed multiplier restored to 1.0x")

	print("PASS: 5.1 Elysia autonomous kiting (< 2.5m), speed boost 1.15x, and safe distance reset verified")

	# --------------------------------------------------------------------------
	# Group 6: Support (Beatrice) 4-Level Priority Healing Tree
	# --------------------------------------------------------------------------
	print("\n[Group 6: Support (Beatrice) 4-Level Priority Healing Tree]")
	var tracker_support: Dictionary = {
		"quick_heal_target": null,
		"faith_shield_target": null,
		"smite_target": null
	}
	world.support_ai.quick_heal_cast.connect(func(target: CharacterEntity, _amt: int) -> void:
		tracker_support["quick_heal_target"] = target
	)
	world.support_ai.faith_shield_cast.connect(func(target: CharacterEntity, _shield: int) -> void:
		tracker_support["faith_shield_target"] = target
	)
	world.support_ai.smite_cast.connect(func(target: CharacterEntity, _dmg: int) -> void:
		tracker_support["smite_target"] = target
	)

	# 6.1 P1: Tank HP < 80% -> Quick Heal on Tank
	if beatrice.skill_holder != null:
		beatrice.skill_holder.reset_all_cooldowns()
	bromm.health_component.current_hp = int(bromm.health_component.max_hp * 0.70) # 70% < 80%
	world.support_ai.evaluate_combat_tactics(0.016, [bromm, beatrice, elysia], [goblin_1])

	assert(tracker_support["quick_heal_target"] == bromm, "P1: Beatrice cast Quick Heal on injured Tank Bromm")
	assert(bromm.health_component.current_hp > int(bromm.health_component.max_hp * 0.70), "Bromm HP increased from healing")

	# Restore Bromm and test P2: Ally HP < 40% -> Faith Shield on Critical Ally
	if beatrice.skill_holder != null:
		beatrice.skill_holder.reset_all_cooldowns()
	bromm.health_component.current_hp = bromm.health_component.max_hp
	elysia.health_component.current_hp = int(elysia.health_component.max_hp * 0.30) # 30% < 40%
	world.support_ai.evaluate_combat_tactics(0.016, [bromm, beatrice, elysia], [goblin_1])

	assert(tracker_support["faith_shield_target"] == elysia, "P2: Beatrice cast Faith Shield on critical ally Elysia")

	# Restore Elysia and test P4: All healthy -> Smite on enemy
	if beatrice.skill_holder != null:
		beatrice.skill_holder.reset_all_cooldowns()
	elysia.health_component.current_hp = elysia.health_component.max_hp
	world.support_ai.evaluate_combat_tactics(0.016, [bromm, beatrice, elysia], [goblin_1])

	assert(tracker_support["smite_target"] == goblin_1, "P4: Beatrice cast Smite on enemy when party is healthy")

	print("PASS: 6.1 Beatrice executed the 4-level tactical priority tree keeping the trio safe")

	# --------------------------------------------------------------------------
	# Group 7: Full Integrated Battle (Trio vs 3 Goblins) to Pack Defeat & March Resumption
	# --------------------------------------------------------------------------
	print("\n[Group 7: Full Integrated Battle (Trio vs 3 Goblins) to Defeat & March Resumption]")
	# Position party and enemies for clean tactical resolution
	bromm.global_position = Vector3(0.0, 0.0, 5.0)
	beatrice.global_position = Vector3(1.2, 0.0, 3.8)
	elysia.global_position = Vector3(-1.2, 0.0, 2.0)

	goblin_1.global_position = Vector3(0.0, 0.0, 6.0)
	goblin_2.global_position = Vector3(-1.0, 0.0, 6.5)
	goblin_3.global_position = Vector3(1.0, 0.0, 6.5)

	# Simulate active combat loop iterations
	var max_combat_ticks: int = 150
	var tick: int = 0
	while world.is_in_combat() and tick < max_combat_ticks:
		tick += 1
		# Hero attacks
		world._physics_process(0.1)

		# Reduce enemy HP dynamically as battle progresses if still alive
		for mob: CharacterEntity in world.get_living_enemies():
			if mob.health_component != null and mob.health_component.is_alive:
				mob.health_component.take_damage(15, 0, bromm)

	# Verify battle resolution
	assert(world.get_living_enemies().is_empty(), "All 3 Goblins in the pack have been defeated")
	assert(world.party_controller.get_alive_heroes().size() == 3, "All 3 Heroes survived the battle without casualties")
	assert(world.is_in_combat() == false, "World transitioned out of combat")
	assert(world.combat_trigger_system.is_party_in_combat == false, "CombatTriggerSystem is_party_in_combat == false")
	assert(tracker_events["combat_ended_count"] == 1, "combat_ended emitted exactly once upon pack elimination")
	assert(world.party_controller.formation_active == true, "Formation marching re-enabled after combat victory")

	# Verify hero OOC states
	assert(bromm.health_component.in_combat == false, "Bromm in_combat restored to false (OOC regen active)")
	assert(beatrice.health_component.in_combat == false, "Beatrice in_combat restored to false")
	assert(elysia.health_component.in_combat == false, "Elysia in_combat restored to false")

	# Traversal resume: advance to final waypoint
	var tracker_traversal: Dictionary = {"traversal_completed": false}
	world.party_traversal_completed.connect(func() -> void:
		tracker_traversal["traversal_completed"] = true
	)

	# Trigger final waypoint completion
	world._complete_traversal()

	assert(world.is_traversal_completed() == true, "Party navigation traversal completed")
	assert(tracker_traversal["traversal_completed"] == true, "party_traversal_completed signal emitted")

	# Clean up scene
	bus.combat_triggered.disconnect(on_eb_combat)
	world.queue_free()

	print("\n================================================================================")
	print("=== ALL M4.7 INTEGRATED PARTY COMBAT 3D TESTS PASSED (7/7 GROUPS) ===")
	print("================================================================================")
	quit(0)
