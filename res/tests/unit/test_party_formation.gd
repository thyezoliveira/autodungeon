extends SceneTree

# ==============================================================================
# Unit & Integration Test Suite: PartyFormationController (Task M3.3)
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
	print("--- Starting PartyFormationController Unit Tests (Task M3.3) ---")
	print("================================================================================")

	# --------------------------------------------------------------------------
	# Test Group 1: Configuration, Default Offsets & Getters
	# --------------------------------------------------------------------------
	print("\n[Group 1: Configuration, Default Offsets & Getters]")
	var controller: PartyFormationController = PartyFormationController.new()
	root.add_child(controller)

	assert(controller != null, "PartyFormationController instance must exist")
	assert(controller.support_offset == Vector3(1.2, 0.0, 1.2), "Default support_offset must be (1.2, 0.0, 1.2)")
	assert(controller.dps_offset == Vector3(-1.2, 0.0, 1.8), "Default dps_offset must be (-1.2, 0.0, 1.8)")
	assert(controller.get_leader() == null, "Default leader is null")
	assert(controller.get_support() == null, "Default support is null")
	assert(controller.get_dps() == null, "Default dps is null")
	assert(controller.get_all_heroes().is_empty(), "get_all_heroes() is empty when none set")
	assert(controller.get_alive_heroes().is_empty(), "get_alive_heroes() is empty when none set")

	var leader_1: CharacterEntity = CharacterEntity.new()
	var support_1: CharacterEntity = CharacterEntity.new()
	var dps_1: CharacterEntity = CharacterEntity.new()
	root.add_child(leader_1)
	root.add_child(support_1)
	root.add_child(dps_1)

	controller.set_party_members(leader_1, support_1, dps_1)
	assert(controller.get_leader() == leader_1, "get_leader() returns leader_1")
	assert(controller.get_support() == support_1, "get_support() returns support_1")
	assert(controller.get_dps() == dps_1, "get_dps() returns dps_1")
	assert(controller.get_all_heroes().size() == 3, "get_all_heroes() returns 3 members")
	assert(controller.get_alive_heroes().size() == 3, "get_alive_heroes() returns 3 alive members")

	print("PASS: 1.1 Configuration, default offsets and member getters verified")

	controller.queue_free()
	leader_1.queue_free()
	support_1.queue_free()
	dps_1.queue_free()

	# --------------------------------------------------------------------------
	# Test Group 2: Straight-Line Formation Calculation (Rotation Y = 0)
	# --------------------------------------------------------------------------
	print("\n[Group 2: Straight-Line Formation Calculation (Rotation Y = 0)]")
	var ctrl_2: PartyFormationController = PartyFormationController.new()
	root.add_child(ctrl_2)

	var leader_2: CharacterEntity = CharacterEntity.new()
	root.add_child(leader_2)
	ctrl_2.leader_hero = leader_2

	# Leader at Origin (0, 0, 0)
	leader_2.global_position = Vector3.ZERO
	leader_2.rotation = Vector3.ZERO

	var supp_pos_0: Vector3 = ctrl_2.calculate_formation_position(ctrl_2.support_offset)
	var dps_pos_0: Vector3 = ctrl_2.calculate_formation_position(ctrl_2.dps_offset)

	assert(supp_pos_0.is_equal_approx(Vector3(1.2, 0.0, 1.2)), "Support at origin: Vector3(1.2, 0.0, 1.2)")
	assert(dps_pos_0.is_equal_approx(Vector3(-1.2, 0.0, 1.8)), "DPS at origin: Vector3(-1.2, 0.0, 1.8)")

	# Leader translated to (10.0, 2.0, -5.0) with zero rotation
	leader_2.global_position = Vector3(10.0, 2.0, -5.0)
	var supp_pos_trans: Vector3 = ctrl_2.calculate_formation_position(ctrl_2.support_offset)
	var dps_pos_trans: Vector3 = ctrl_2.calculate_formation_position(ctrl_2.dps_offset)

	assert(supp_pos_trans.is_equal_approx(Vector3(11.2, 2.0, -3.8)), "Support translated: Vector3(11.2, 2.0, -3.8)")
	assert(dps_pos_trans.is_equal_approx(Vector3(8.8, 2.0, -3.2)), "DPS translated: Vector3(8.8, 2.0, -3.2)")

	print("PASS: 2.1 Straight-line projection at origin and translated coordinates verified")

	ctrl_2.queue_free()
	leader_2.queue_free()

	# --------------------------------------------------------------------------
	# Test Group 3: Formation Calculation with 90° and 180° Rotations / Turns
	# --------------------------------------------------------------------------
	print("\n[Group 3: Formation Calculation with 90° and 180° Rotations / Turns]")
	var ctrl_3: PartyFormationController = PartyFormationController.new()
	root.add_child(ctrl_3)

	var leader_3: CharacterEntity = CharacterEntity.new()
	root.add_child(leader_3)
	ctrl_3.leader_hero = leader_3
	leader_3.global_position = Vector3(5.0, 0.0, 5.0)

	# 90 degrees rotation around Y (facing +X in standard Godot coordinate transform)
	leader_3.rotation = Vector3(0.0, deg_to_rad(90.0), 0.0)

	var supp_pos_90: Vector3 = ctrl_3.calculate_formation_position(ctrl_3.support_offset)
	var dps_pos_90: Vector3 = ctrl_3.calculate_formation_position(ctrl_3.dps_offset)

	# For Y-rotation 90 deg:
	# Local offset (1.2, 0.0, 1.2) rotates around Y:
	# expected_x = 5.0 + 1.2
	# expected_z = 5.0 - 1.2 = 3.8
	var expected_supp_90: Vector3 = leader_3.global_position + (leader_3.global_transform.basis * ctrl_3.support_offset)
	var expected_dps_90: Vector3 = leader_3.global_position + (leader_3.global_transform.basis * ctrl_3.dps_offset)

	assert(supp_pos_90.is_equal_approx(expected_supp_90), "Support position matches 90 deg basis transform")
	assert(dps_pos_90.is_equal_approx(expected_dps_90), "DPS position matches 90 deg basis transform")
	assert(is_equal_approx(supp_pos_90.x, 6.2), "Support X rotated 90 deg is 6.2")
	assert(is_equal_approx(supp_pos_90.z, 3.8), "Support Z rotated 90 deg is 3.8")
	assert(is_equal_approx(dps_pos_90.x, 6.8), "DPS X rotated 90 deg is 6.8")
	assert(is_equal_approx(dps_pos_90.z, 6.2), "DPS Z rotated 90 deg is 6.2")

	# 180 degrees rotation around Y (facing -Z / reverse)
	leader_3.rotation = Vector3(0.0, deg_to_rad(180.0), 0.0)

	var supp_pos_180: Vector3 = ctrl_3.calculate_formation_position(ctrl_3.support_offset)
	var dps_pos_180: Vector3 = ctrl_3.calculate_formation_position(ctrl_3.dps_offset)

	var expected_supp_180: Vector3 = leader_3.global_position + (leader_3.global_transform.basis * ctrl_3.support_offset)
	var expected_dps_180: Vector3 = leader_3.global_position + (leader_3.global_transform.basis * ctrl_3.dps_offset)

	assert(supp_pos_180.is_equal_approx(expected_supp_180), "Support position matches 180 deg basis transform")
	assert(dps_pos_180.is_equal_approx(expected_dps_180), "DPS position matches 180 deg basis transform")
	assert(is_equal_approx(supp_pos_180.x, 5.0 - 1.2), "Support X rotated 180 deg is 3.8")
	assert(is_equal_approx(supp_pos_180.z, 5.0 - 1.2), "Support Z rotated 180 deg is 3.8")
	assert(is_equal_approx(dps_pos_180.x, 5.0 + 1.2), "DPS X rotated 180 deg is 6.2")
	assert(is_equal_approx(dps_pos_180.z, 5.0 - 1.8), "DPS Z rotated 180 deg is 3.2")

	print("PASS: 3.1 90° and 180° tactical rotation transformations validated")

	ctrl_3.queue_free()
	leader_3.queue_free()

	# --------------------------------------------------------------------------
	# Test Group 4: Physics Process & MovementComponent Integration
	# --------------------------------------------------------------------------
	print("\n[Group 4: Physics Process & MovementComponent Integration]")
	var ctrl_4: PartyFormationController = PartyFormationController.new()
	root.add_child(ctrl_4)

	var leader_4: CharacterEntity = CharacterEntity.new()
	var support_4: CharacterEntity = CharacterEntity.new()
	var dps_4: CharacterEntity = CharacterEntity.new()
	root.add_child(leader_4)
	root.add_child(support_4)
	root.add_child(dps_4)

	var supp_move: MovementComponent = MovementComponent.new()
	support_4.add_child(supp_move)
	support_4.movement_component = supp_move
	supp_move._ready()

	var dps_move: MovementComponent = MovementComponent.new()
	dps_4.add_child(dps_move)
	dps_4.movement_component = dps_move
	dps_move._ready()

	ctrl_4.set_party_members(leader_4, support_4, dps_4)

	leader_4.global_position = Vector3(10.0, 0.0, 20.0)
	leader_4.rotation = Vector3.ZERO

	# Trigger _physics_process
	ctrl_4._physics_process(0.016)

	var expected_supp_target: Vector3 = Vector3(11.2, 0.0, 21.2)
	var expected_dps_target: Vector3 = Vector3(8.8, 0.0, 21.8)

	assert(supp_move.current_target_position.is_equal_approx(expected_supp_target), "Support move_towards set to expected formation target")
	assert(supp_move.is_moving == true, "Support movement_component is marked moving")
	assert(dps_move.current_target_position.is_equal_approx(expected_dps_target), "DPS move_towards set to expected formation target")
	assert(dps_move.is_moving == true, "DPS movement_component is marked moving")

	print("PASS: 4.1 Follower movement components successfully updated during _physics_process")

	ctrl_4.queue_free()
	leader_4.queue_free()
	support_4.queue_free()
	dps_4.queue_free()

	# --------------------------------------------------------------------------
	# Test Group 5: Tolerance to Null, Dead and Invalid Entities
	# --------------------------------------------------------------------------
	print("\n[Group 5: Tolerance to Null, Dead and Invalid Entities]")
	var ctrl_5: PartyFormationController = PartyFormationController.new()
	root.add_child(ctrl_5)

	# 5.1 All null
	ctrl_5._physics_process(0.016)
	var default_pos: Vector3 = ctrl_5.calculate_formation_position(Vector3(1.0, 0.0, 1.0))
	assert(default_pos.is_equal_approx(ctrl_5.global_position + Vector3(1.0, 0.0, 1.0)), "Null leader returns controller position + offset")
	print("PASS: 5.1 Null entities handled safely without errors")

	# 5.2 Dead followers do not receive movement orders
	var leader_5: CharacterEntity = CharacterEntity.new()
	var support_5: CharacterEntity = CharacterEntity.new()
	var dps_5: CharacterEntity = CharacterEntity.new()
	root.add_child(leader_5)
	root.add_child(support_5)
	root.add_child(dps_5)

	var supp_move_5: MovementComponent = MovementComponent.new()
	support_5.add_child(supp_move_5)
	support_5.movement_component = supp_move_5
	supp_move_5._ready()

	var supp_health_5: HealthComponent = HealthComponent.new()
	support_5.add_child(supp_health_5)
	support_5.health_component = supp_health_5

	var dps_move_5: MovementComponent = MovementComponent.new()
	dps_5.add_child(dps_move_5)
	dps_5.movement_component = dps_move_5
	dps_move_5._ready()

	var dps_health_5: HealthComponent = HealthComponent.new()
	dps_5.add_child(dps_health_5)
	dps_5.health_component = dps_health_5

	ctrl_5.set_party_members(leader_5, support_5, dps_5)

	# Kill support
	supp_health_5.current_hp = 0
	supp_health_5.is_alive = false

	assert(ctrl_5.is_hero_alive(support_5) == false, "Dead support recognized by is_hero_alive()")
	assert(ctrl_5.is_hero_alive(dps_5) == true, "Alive DPS recognized by is_hero_alive()")

	var alive_list: Array[CharacterEntity] = ctrl_5.get_alive_heroes()
	assert(alive_list.size() == 2, "Only 2 heroes alive (leader and dps)")
	assert(alive_list.has(leader_5), "Leader is in alive list")
	assert(alive_list.has(dps_5), "DPS is in alive list")
	assert(not alive_list.has(support_5), "Dead support is NOT in alive list")

	supp_move_5.current_target_position = Vector3.ZERO
	supp_move_5.is_moving = false

	ctrl_5._physics_process(0.016)

	assert(supp_move_5.is_moving == false, "Dead support was not given new move orders")
	assert(supp_move_5.current_target_position == Vector3.ZERO, "Dead support target was not modified")
	assert(dps_move_5.is_moving == true, "Alive DPS was given move orders")

	print("PASS: 5.2 Dead followers properly excluded from movement updates")

	ctrl_5.queue_free()
	leader_5.queue_free()
	support_5.queue_free()
	dps_5.queue_free()

	# --------------------------------------------------------------------------
	# Test Group 6: Role Reassignment on Leader Death
	# --------------------------------------------------------------------------
	print("\n[Group 6: Role Reassignment on Leader Death]")
	var ctrl_6: PartyFormationController = PartyFormationController.new()
	root.add_child(ctrl_6)

	var leader_6: CharacterEntity = CharacterEntity.new()
	var support_6: CharacterEntity = CharacterEntity.new()
	var dps_6: CharacterEntity = CharacterEntity.new()
	root.add_child(leader_6)
	root.add_child(support_6)
	root.add_child(dps_6)

	var lead_health_6: HealthComponent = HealthComponent.new()
	leader_6.add_child(lead_health_6)
	leader_6.health_component = lead_health_6

	var supp_health_6: HealthComponent = HealthComponent.new()
	support_6.add_child(supp_health_6)
	support_6.health_component = supp_health_6

	var dps_health_6: HealthComponent = HealthComponent.new()
	dps_6.add_child(dps_health_6)
	dps_6.health_component = dps_health_6

	ctrl_6.set_party_members(leader_6, support_6, dps_6)

	var leader_change_detected: Array[CharacterEntity] = []
	ctrl_6.leader_changed.connect(func(new_lead: CharacterEntity) -> void:
		leader_change_detected.append(new_lead)
	)

	# Case 1: Leader dies -> Support is promoted to leader
	lead_health_6.current_hp = 0
	lead_health_6.is_alive = false
	ctrl_6.reassign_roles_on_hero_death(leader_6)

	assert(ctrl_6.get_leader() == support_6, "Support promoted to leader after leader dies")
	assert(ctrl_6.get_support() == null, "Support slot cleared after promotion")
	assert(ctrl_6.get_dps() == dps_6, "DPS remains in DPS slot")
	assert(leader_change_detected.size() == 1, "leader_changed signal emitted")
	assert(leader_change_detected[0] == support_6, "leader_changed signal carried support_6")

	# Case 2: New leader (Support) dies -> DPS is promoted to leader
	supp_health_6.current_hp = 0
	supp_health_6.is_alive = false
	ctrl_6.reassign_roles_on_hero_death(support_6)

	assert(ctrl_6.get_leader() == dps_6, "DPS promoted to leader after second leader dies")
	assert(ctrl_6.get_dps() == null, "DPS slot cleared after promotion")
	assert(leader_change_detected.size() == 2, "leader_changed signal emitted second time")

	print("PASS: 6.1 Dynamic role reassignment on hero death validated")

	ctrl_6.queue_free()
	leader_6.queue_free()
	support_6.queue_free()
	dps_6.queue_free()

	# --------------------------------------------------------------------------
	# Test Group 7: Hierarchy Auto-Detection of Party Members
	# --------------------------------------------------------------------------
	print("\n[Group 7: Hierarchy Auto-Detection of Party Members]")
	var ctrl_7: PartyFormationController = PartyFormationController.new()

	var bromm_child: CharacterEntity = CharacterEntity.new()
	bromm_child.name = "Hero_Bromm_Leader"
	ctrl_7.add_child(bromm_child)

	var beatrice_child: CharacterEntity = CharacterEntity.new()
	beatrice_child.name = "Hero_Beatrice_Support"
	ctrl_7.add_child(beatrice_child)

	var elysia_child: CharacterEntity = CharacterEntity.new()
	elysia_child.name = "Hero_Elysia_DPS"
	ctrl_7.add_child(elysia_child)

	root.add_child(ctrl_7) # triggers _ready() and _auto_detect_members_if_needed()

	assert(ctrl_7.get_leader() == bromm_child, "Bromm auto-detected as leader")
	assert(ctrl_7.get_support() == beatrice_child, "Beatrice auto-detected as support")
	assert(ctrl_7.get_dps() == elysia_child, "Elysia auto-detected as dps")

	print("PASS: 7.1 Automatic member hierarchy detection validated")

	ctrl_7.queue_free()
	bromm_child.queue_free()
	beatrice_child.queue_free()
	elysia_child.queue_free()

	print("\n================================================================================")
	print("=== ALL PARTYFORMATIONCONTROLLER UNIT TESTS PASSED (7/7 GROUPS) ===")
	print("================================================================================")
	quit(0)
