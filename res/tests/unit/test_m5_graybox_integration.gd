extends SceneTree

# ==============================================================================
# End-to-End Integration Test Suite: Graybox Dungeon Full Flow (Task M5.6)
# ==============================================================================
# Validates the complete cycle:
# 1. Sala 0: Trio spawn (Bromm, Beatrice, Elysia), camera rig, and formation readiness.
# 2. Autonomous March Sala 0 -> Sala 1.
# 3. Sala 1 Encounter: Room1_Controller engages 2 Warriors + 1 Archer with coordinated IAs.
# 4. Sala 1 Clear: EventBus.room_cleared(1), formation resumes, march into Corridor 1_2.
# 5. Corridor 1_2 Traversal: Out-of-Combat (OOC) mana regeneration ticks during passage.
# 6. Sala 2 Encounter: Room2_Controller engages Captain (Mini-Boss + Aura) + Healer (Blessing).
# 7. Sala 2 Clear: EventBus.room_cleared(2), formation resumes, march to Arena 3 Gate.
# 8. Arrival at Arena 3 Gate: Traversal completed, IdleState, dungeon_completed signal.
# ==============================================================================

const GrayboxDungeonScene = preload("res://src/world/dungeons/GrayboxDungeon.tscn")
const DungeonLevel = preload("res://src/world/dungeons/DungeonLevel.gd")
const CharacterEntity = preload("res://src/entities/base/CharacterEntity.gd")
const RoomEncounterController = preload("res://src/systems/RoomEncounterController.gd")
const AuraDeFuriaTribal = preload("res://src/entities/enemies/AuraDeFuriaTribal.gd")
const GoblinHealerAI = preload("res://src/entities/enemies/GoblinHealerAI.gd")

var _executed: bool = false


func _process(_delta: float) -> bool:
	if _executed:
		return false
	_executed = true
	_run_all_integration_tests()
	return false


func _run_all_integration_tests() -> void:
	print("================================================================================")
	print("--- Starting M5.6 Graybox Dungeon Full Integration Test Suite ---")
	print("================================================================================")

	# --------------------------------------------------------------------------
	# Ensure EventBus Autoload is present
	# --------------------------------------------------------------------------
	var bus_node: Node = root.get_node_or_null("EventBus")
	if bus_node == null:
		var bus_script: Script = load("res://src/core/EventBus.gd")
		bus_node = Node.new()
		bus_node.name = "EventBus"
		bus_node.set_script(bus_script)
		root.add_child(bus_node)
	var bus: EventBusSingleton = bus_node as EventBusSingleton
	print("PASS: EventBus Autoload singleton verified in SceneTree root")

	# --------------------------------------------------------------------------
	# Test Group 1: Scene Instantiation & Complete Hierarchy Inspection (Sala 0)
	# --------------------------------------------------------------------------
	print("\n[Group 1: Scene Instantiation, Hierarchy & Sala 0 Setup]")
	var dungeon_inst: Node = GrayboxDungeonScene.instantiate()
	assert(dungeon_inst != null, "GrayboxDungeon.tscn must instantiate successfully")
	assert(dungeon_inst is DungeonLevel, "Root node must be an instance of DungeonLevel")

	var dungeon: DungeonLevel = dungeon_inst as DungeonLevel
	dungeon.auto_start_traversal = false # Controlled manual driver
	root.add_child(dungeon)

	# 1.1 Architecture & Navigation
	assert(dungeon.navigation_region != null, "NavigationRegion3D must be resolved")
	assert(dungeon.architecture != null, "Architecture StaticBody3D must be resolved")
	assert(dungeon.architecture.collision_layer == 1, "Architecture on Physics Layer 1")

	# 1.2 Hero Party Formation
	assert(dungeon.party_controller != null, "PartyFormationController must be resolved")
	var bromm: CharacterEntity = dungeon.party_controller.get_leader()
	var beatrice: CharacterEntity = dungeon.party_controller.get_support()
	var elysia: CharacterEntity = dungeon.party_controller.get_dps()

	assert(bromm != null and is_instance_valid(bromm), "Leader hero Bromm present")
	assert(beatrice != null and is_instance_valid(beatrice), "Support hero Beatrice present")
	assert(elysia != null and is_instance_valid(elysia), "DPS hero Elysia present")

	assert(bromm.hero_data != null and bromm.hero_data.hero_id == "bromm", "Bromm HeroData loaded")
	assert(beatrice.hero_data != null and beatrice.hero_data.hero_id == "beatrice", "Beatrice HeroData loaded")
	assert(elysia.hero_data != null and elysia.hero_data.hero_id == "elysia", "Elysia HeroData loaded")

	# 1.3 Hero AI Controllers
	assert(dungeon.tank_ai != null, "TankAIController resolved for Bromm")
	assert(dungeon.support_ai != null, "SupportAIController resolved for Beatrice")
	assert(dungeon.dps_ai != null, "RangedDPSAIController resolved for Elysia")

	# 1.4 Camera Rig
	assert(dungeon.camera_rig != null, "IsometricCameraRig resolved")
	assert(dungeon.camera_rig.target == bromm, "Camera target is leader Bromm")

	# 1.5 Enemy Spawning & Setup
	var room1_pack: Array[CharacterEntity] = dungeon.get_spawned_enemies_for_room(1)
	var room2_pack: Array[CharacterEntity] = dungeon.get_spawned_enemies_for_room(2)

	assert(room1_pack.size() == 3, "Room 1 spawned 3 enemies (2 Warriors + 1 Archer)")
	assert(room2_pack.size() == 2, "Room 2 spawned 2 enemies (Captain + Healer)")

	var r1_ctrl: RoomEncounterController = dungeon.get_encounter_controller(1) as RoomEncounterController
	var r2_ctrl: RoomEncounterController = dungeon.get_encounter_controller(2) as RoomEncounterController

	assert(r1_ctrl != null, "Room1_Controller resolved")
	assert(r2_ctrl != null, "Room2_Controller resolved")
	assert(r1_ctrl.get_alive_enemies_count() == 3, "Room1_Controller has 3 living enemies")
	assert(r2_ctrl.get_alive_enemies_count() == 2, "Room2_Controller has 2 living enemies")

	# 1.6 Mini-Boss Mechanics (Captain Aura + Healer AI)
	var captain: CharacterEntity = room2_pack[0]
	var healer: CharacterEntity = room2_pack[1]
	var captain_aura: AuraDeFuriaTribal = captain.get_node_or_null("Components/AuraDeFuriaTribal") as AuraDeFuriaTribal
	var healer_ai: GoblinHealerAI = healer.get_node_or_null("Components/GoblinHealerAI") as GoblinHealerAI

	assert(captain_aura != null, "Goblin Captain has AuraDeFuriaTribal component")
	assert(healer_ai != null, "Goblin Healer has GoblinHealerAI component")
	assert(is_equal_approx(captain_aura.damage_multiplier_bonus, 0.25), "Aura bonus is +25%")

	# 1.7 Initial State at Sala 0
	dungeon.initialize_party_at_spawn()
	assert(bromm.health_component.current_hp == bromm.health_component.max_hp, "Bromm at full HP")
	assert(beatrice.health_component.current_hp == beatrice.health_component.max_hp, "Beatrice at full HP")
	assert(elysia.health_component.current_hp == elysia.health_component.max_hp, "Elysia at full HP")
	assert(bromm.health_component.in_combat == false, "Bromm in_combat is false initially")
	assert(dungeon.is_in_combat() == false, "Dungeon is not in combat initially")

	print("PASS: 1.1 Complete scene hierarchy, heroes, enemies, IAs and Room controllers verified at Sala 0")

	# --------------------------------------------------------------------------
	# Test Group 2: Autonomous March from Sala 0 to Sala 1
	# --------------------------------------------------------------------------
	print("\n[Group 2: Autonomous March Sala 0 -> Sala 1]")
	var event_tracker: Dictionary = {
		"r1_entered": false,
		"r1_cleared": false,
		"r2_entered": false,
		"r2_cleared": false,
		"combat_started_count": 0,
		"combat_ended_count": 0,
		"dungeon_completed": false
	}

	dungeon.room_entered.connect(func(idx: int, _name: String) -> void:
		if idx == 1: event_tracker["r1_entered"] = true
		elif idx == 2: event_tracker["r2_entered"] = true
	)
	dungeon.room_cleared.connect(func(idx: int) -> void:
		if idx == 1: event_tracker["r1_cleared"] = true
		elif idx == 2: event_tracker["r2_cleared"] = true
	)
	dungeon.combat_started.connect(func(_i: Node3D, _t: Node3D) -> void:
		event_tracker["combat_started_count"] += 1
	)
	dungeon.combat_ended.connect(func() -> void:
		event_tracker["combat_ended_count"] += 1
	)
	dungeon.dungeon_completed.connect(func() -> void:
		event_tracker["dungeon_completed"] = true
	)

	# Start traversal
	dungeon.start_traversal()
	assert(dungeon.is_traversing() == true, "dungeon.is_traversing() is true")
	assert(dungeon.get_current_waypoint_index() == 1, "Party targeting Waypoint 1 in Corridor 0_1")
	assert(dungeon.party_controller.formation_active == true, "Formation active during march")

	# March through Corridor 0_1 towards Sala 1 (simulate 10 physics ticks)
	for _i in range(10):
		dungeon._physics_process(0.1)

	assert(event_tracker["combat_started_count"] == 0, "No combat triggered prematurely during Corridor 0_1 march")
	print("PASS: 2.1 Trio marches in formation through Corridor 0_1 without premature combat")

	# --------------------------------------------------------------------------
	# Test Group 3: Sala 1 Combat Encounter (Trio vs 2 Warriors + 1 Archer)
	# --------------------------------------------------------------------------
	print("\n[Group 3: Sala 1 Combat Encounter & Resolution]")
	# Position leader in Sala 1
	bromm.global_position = Vector3(0.0, 0.0, 24.5)
	r1_ctrl._on_body_entered(bromm)

	assert(r1_ctrl.is_encounter_active() == true, "Room 1 encounter is active")
	assert(dungeon.is_in_combat() == true, "dungeon.is_in_combat() is true")
	assert(event_tracker["r1_entered"] == true, "EventBus / DungeonLevel room_entered(1) emitted")
	assert(dungeon.party_controller.formation_active == false, "Formation paused during combat")
	assert(bromm.health_component.in_combat == true, "Bromm in_combat is true")
	assert(beatrice.health_component.in_combat == true, "Beatrice in_combat is true")
	assert(elysia.health_component.in_combat == true, "Elysia in_combat is true")

	# Spend mana on heroes to test OOC regeneration later
	beatrice.health_component.consume_mana(35.0) # 100 -> 65
	elysia.health_component.consume_mana(20.0)   # 60 -> 40
	var beatrice_mana_after_combat: float = beatrice.health_component.current_mana
	var elysia_mana_after_combat: float = elysia.health_component.current_mana

	assert(beatrice_mana_after_combat < 100.0, "Beatrice spent mana in Sala 1")
	assert(elysia_mana_after_combat < 60.0, "Elysia spent mana in Sala 1")

	# Run combat ticks with active hero/monster AI execution
	for _f in range(5):
		dungeon._physics_process(0.1)

	# Eliminate any remaining monsters from Sala 1 pack
	for mob: CharacterEntity in room1_pack:
		if mob != null and is_instance_valid(mob) and mob.health_component != null and mob.health_component.is_alive:
			mob.health_component.take_damage(100, 0, bromm)
			bus.entity_died.emit(mob, bromm)

	# Verify Sala 1 Clear
	assert(r1_ctrl.get_alive_enemies_count() == 0, "Room 1 pack wiped")
	assert(r1_ctrl.is_encounter_cleared() == true, "Room 1 encounter cleared")
	assert(event_tracker["r1_cleared"] == true, "room_cleared(1) signal emitted")
	assert(dungeon.is_in_combat() == false, "dungeon.is_in_combat() restored to false")
	assert(dungeon.party_controller.formation_active == true, "Formation marching resumed")
	assert(bromm.health_component.in_combat == false, "Bromm in_combat is false")
	assert(beatrice.health_component.in_combat == false, "Beatrice in_combat is false")
	assert(elysia.health_component.in_combat == false, "Elysia in_combat is false")

	print("PASS: 3.1 Sala 1 combat encounter executed, 3 Goblins defeated, room_cleared(1) emitted and march resumed")

	# --------------------------------------------------------------------------
	# Test Group 4: Corridor 1_2 Traversal & Out-of-Combat (OOC) Mana Regeneration
	# --------------------------------------------------------------------------
	print("\n[Group 4: Corridor 1_2 Traversal & OOC Mana Regeneration]")
	# In Corridor 1_2, the trio marches between Waypoint 2 and Waypoint 5.
	# With in_combat == false, HealthComponent._process_ooc_mana_regen ticks every 2.0s (+5% max_mana).
	var initial_b_mana: float = beatrice.health_component.current_mana
	var initial_e_mana: float = elysia.health_component.current_mana

	# Simulate 30 frames with dt=0.1 (3.0 seconds elapsed, > 2.0s OOC_MANA_REGEN_INTERVAL)
	for _f in range(30):
		beatrice.health_component._physics_process(0.1)
		elysia.health_component._physics_process(0.1)
		bromm.health_component._physics_process(0.1)
		dungeon._physics_process(0.1)

	var regenerated_b_mana: float = beatrice.health_component.current_mana
	var regenerated_e_mana: float = elysia.health_component.current_mana

	assert(regenerated_b_mana > initial_b_mana, "Beatrice regenerated mana in Corridor 1_2 (from %.1f to %.1f)" % [initial_b_mana, regenerated_b_mana])
	assert(regenerated_e_mana > initial_e_mana, "Elysia regenerated mana in Corridor 1_2 (from %.1f to %.1f)" % [initial_e_mana, regenerated_e_mana])

	print("PASS: 4.1 OOC Mana Regeneration validated along Corridor 1_2 (Beatrice: +%.1f mana, Elysia: +%.1f mana)" % [
		regenerated_b_mana - initial_b_mana,
		regenerated_e_mana - initial_e_mana
	])

	# --------------------------------------------------------------------------
	# Test Group 5: Sala 2 Mini-Boss Encounter (Captain + Healer)
	# --------------------------------------------------------------------------
	print("\n[Group 5: Sala 2 Mini-Boss Encounter (Captain + Healer)]")
	# Position leader in Sala 2
	bromm.global_position = Vector3(16.0, 0.0, 58.0)
	r2_ctrl._on_body_entered(bromm)

	assert(r2_ctrl.is_encounter_active() == true, "Room 2 encounter is active")
	assert(dungeon.is_in_combat() == true, "dungeon.is_in_combat() is true")
	assert(event_tracker["r2_entered"] == true, "room_entered(2) signal emitted")
	assert(dungeon.party_controller.formation_active == false, "Formation paused in Sala 2")

	# Test Captain's Aura of Tribal Fury buffing Healer
	captain.global_position = Vector3(16.0, 0.0, 60.0)
	healer.global_position = Vector3(16.0, 0.0, 62.0) # 2.0m < 6.0m radius
	captain_aura.apply_buff_to_entity(healer)

	assert(captain_aura.is_entity_buffed(healer) == true, "Healer buffed by Captain's Aura (+25% attack power)")

	# Test Goblin Healer AI healing Captain when HP < 50%
	captain.health_component.current_hp = int(captain.health_component.max_hp * 0.35) # 35% < 50%
	var hp_before_heal: int = captain.health_component.current_hp
	healer_ai.evaluate_healing([captain, healer])

	assert(captain.health_component.current_hp > hp_before_heal, "Healer cast Tribal Blessing on damaged Captain (HP: %d -> %d)" % [hp_before_heal, captain.health_component.current_hp])

	# Kill Captain first: verify Aura deactivates immediately
	captain.health_component.take_damage(200, 0, bromm)
	bus.entity_died.emit(captain, bromm)

	assert(captain_aura.is_entity_buffed(healer) == false, "Aura deactivated immediately upon Captain death, Healer unbuffed")
	assert(r2_ctrl.get_alive_enemies_count() == 1, "Room 2 has 1 enemy remaining (Healer)")
	assert(r2_ctrl.is_encounter_cleared() == false, "Room 2 not cleared while Healer lives")

	# Kill Healer
	healer.health_component.take_damage(200, 0, elysia)
	bus.entity_died.emit(healer, elysia)

	assert(r2_ctrl.get_alive_enemies_count() == 0, "Room 2 pack wiped")
	assert(r2_ctrl.is_encounter_cleared() == true, "Room 2 encounter cleared")
	assert(event_tracker["r2_cleared"] == true, "room_cleared(2) signal emitted")
	assert(dungeon.is_in_combat() == false, "Combat ended after Room 2 mini-boss")
	assert(dungeon.party_controller.formation_active == true, "Formation resumed after Room 2")

	print("PASS: 5.1 Sala 2 Mini-Boss (Captain + Aura) and Healer (Tribal Blessing) mechanics, defeat and room_cleared(2) verified")

	# --------------------------------------------------------------------------
	# Test Group 6: March to Arena 3 Boss Gate & Full Dungeon Completion
	# --------------------------------------------------------------------------
	print("\n[Group 6: March to Arena 3 Gate & Dungeon Completion]")
	assert(dungeon.get_current_waypoint_index() == 6, "Party targeting Waypoint 6 (Arena 3 Gate at (16, 0, 74))")

	# Move leader towards Waypoint 6 and tick physics
	bromm.global_position = Vector3(16.0, 0.0, 73.5) # Planar dist to (16, 0, 74) is 0.5m <= 0.8m
	dungeon._physics_process(0.1)

	assert(dungeon.is_dungeon_completed() == true, "dungeon.is_dungeon_completed() is true")
	assert(event_tracker["dungeon_completed"] == true, "dungeon_completed signal emitted")

	for hero in dungeon.party_controller.get_alive_heroes():
		assert(hero.movement_component.is_moving == false, "%s stopped movement at Arena 3 gate" % hero.name)
		assert(hero.state_machine.get_current_state_name() == "IdleState", "%s transitioned to IdleState" % hero.name)

	print("PASS: 6.1 Party arrived at Arena 3 Boss Gate, stopped in IdleState, and dungeon_completed emitted")

	print("\n================================================================================")
	print("=== ALL M5.6 GRAYBOX DUNGEON INTEGRATION TESTS PASSED (6/6 GROUPS) ===")
	print("================================================================================")
	quit(0)
