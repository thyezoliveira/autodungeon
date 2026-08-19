extends SceneTree

# ==============================================================================
# Unit & Integration Test Suite: Elastic Tethering & Speed Cohesion (Task M3.4)
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
	print("--- Starting Party Tethering & Elastic Spring Unit Tests (Task M3.4) ---")
	print("================================================================================")

	_test_default_properties()
	_test_ideal_zone()
	_test_tension_zone()
	_test_rupture_zone()
	_test_continuous_recovery_and_transitions()
	_test_dead_follower_tolerance()
	_test_planar_xz_height_invariance()
	_test_custom_tether_configuration()

	print("\n================================================================================")
	print("=== ALL PARTY TETHERING UNIT TESTS PASSED (8/8 TEST SUITES) ===")
	print("================================================================================")
	quit(0)


## Helper para instanciar herói com MovementComponent e HealthComponent
func _create_hero(hero_name: String, initial_pos: Vector3 = Vector3.ZERO) -> CharacterEntity:
	var hero: CharacterEntity = CharacterEntity.new()
	hero.name = hero_name
	root.add_child(hero)
	hero.global_position = initial_pos

	var move_comp: MovementComponent = MovementComponent.new()
	move_comp.name = "MovementComponent"
	hero.add_child(move_comp)
	hero.movement_component = move_comp

	var health_comp: HealthComponent = HealthComponent.new()
	health_comp.name = "HealthComponent"
	health_comp.max_hp = 100
	health_comp.current_hp = 100
	health_comp.is_alive = true
	hero.add_child(health_comp)
	hero.health_component = health_comp

	return hero


# ------------------------------------------------------------------------------
# Test 1: Exported Properties & Default Configuration
# ------------------------------------------------------------------------------
func _test_default_properties() -> void:
	print("\n[Test 1: Exported Properties & Default Configuration]")
	var ctrl: PartyFormationController = PartyFormationController.new()
	root.add_child(ctrl)

	assert(ctrl.tether_ideal_distance == 2.0, "Default tether_ideal_distance must be 2.0m")
	assert(ctrl.tether_max_distance == 3.0, "Default tether_max_distance must be 3.0m")
	assert(ctrl.follower_catchup_multiplier == 1.25, "Default follower_catchup_multiplier must be 1.25x")
	assert(ctrl.leader_slow_multiplier == 0.5, "Default leader_slow_multiplier must be 0.5x")

	var empty_status: Dictionary = ctrl.get_tether_status()
	assert(empty_status["zone"] == "ideal", "Empty controller reports ideal zone")
	assert(empty_status["leader_speed_multiplier"] == 1.0, "Default leader speed multiplier is 1.0")
	assert(empty_status["max_distance"] == 0.0, "Default max distance is 0.0")
	assert(empty_status["alive_followers_count"] == 0, "Default alive followers count is 0")

	print("PASS: 1.1 Default tether properties and initial status verified")
	ctrl.queue_free()


# ------------------------------------------------------------------------------
# Test 2: Ideal Zone (< 2.0m) Response
# ------------------------------------------------------------------------------
func _test_ideal_zone() -> void:
	print("\n[Test 2: Ideal Zone (< 2.0m) Response]")
	var ctrl: PartyFormationController = PartyFormationController.new()
	root.add_child(ctrl)

	var leader: CharacterEntity = _create_hero("Leader", Vector3(0.0, 0.0, 0.0))
	var support: CharacterEntity = _create_hero("Support", Vector3(1.0, 0.0, 1.0)) # dist ~ 1.414m (< 2.0m)
	var dps: CharacterEntity = _create_hero("DPS", Vector3(-1.0, 0.0, 1.0)) # dist ~ 1.414m (< 2.0m)

	ctrl.set_party_members(leader, support, dps)

	var status: Dictionary = ctrl.get_tether_status()
	assert(status["zone"] == "ideal", "Zone must be 'ideal'")
	assert(status["leader_speed_multiplier"] == 1.0, "Leader speed multiplier must be 1.0 in ideal zone")
	assert(status["support_multiplier"] == 1.0, "Support speed multiplier must be 1.0 in ideal zone")
	assert(status["dps_multiplier"] == 1.0, "DPS speed multiplier must be 1.0 in ideal zone")
	assert(status["alive_followers_count"] == 2, "Alive followers count is 2")
	assert(is_equal_approx(status["support_distance"], sqrt(2.0)), "Support planar distance ~1.414m")
	assert(is_equal_approx(status["dps_distance"], sqrt(2.0)), "DPS planar distance ~1.414m")

	# Physics tick integration
	ctrl._physics_process(0.016)
	assert(leader.movement_component.speed_multiplier == 1.0, "Leader movement speed_multiplier applied as 1.0")
	assert(support.movement_component.speed_multiplier == 1.0, "Support movement speed_multiplier applied as 1.0")
	assert(dps.movement_component.speed_multiplier == 1.0, "DPS movement speed_multiplier applied as 1.0")

	print("PASS: 2.1 Ideal zone keeps all heroes at 1.0x normal speed")
	ctrl.queue_free()
	leader.queue_free()
	support.queue_free()
	dps.queue_free()


# ------------------------------------------------------------------------------
# Test 3: Tension Zone (2.0m - 3.0m) Response
# ------------------------------------------------------------------------------
func _test_tension_zone() -> void:
	print("\n[Test 3: Tension Zone (2.0m - 3.0m) Response]")
	var ctrl: PartyFormationController = PartyFormationController.new()
	root.add_child(ctrl)

	var leader: CharacterEntity = _create_hero("Leader", Vector3(0.0, 0.0, 0.0))
	var support: CharacterEntity = _create_hero("Support", Vector3(0.0, 0.0, 2.5)) # 2.5m -> Tension
	var dps: CharacterEntity = _create_hero("DPS", Vector3(0.0, 0.0, 1.2)) # 1.2m -> Ideal

	ctrl.set_party_members(leader, support, dps)

	var status: Dictionary = ctrl.get_tether_status()
	assert(status["zone"] == "tension", "Zone must be 'tension'")
	assert(status["leader_speed_multiplier"] == 1.0, "Leader maintains 1.0x in tension zone")
	assert(status["support_multiplier"] == 1.25, "Lagging Support accelerated to 1.25x")
	assert(status["dps_multiplier"] == 1.0, "Non-lagging DPS maintains 1.0x")
	assert(is_equal_approx(status["max_distance"], 2.5), "Max distance is 2.5m")

	ctrl._physics_process(0.016)
	assert(leader.movement_component.speed_multiplier == 1.0, "Leader movement component is 1.0x")
	assert(support.movement_component.speed_multiplier == 1.25, "Support movement component is 1.25x")
	assert(dps.movement_component.speed_multiplier == 1.0, "DPS movement component is 1.0x")

	# Case B: Both followers in tension (Support 2.2m, DPS 2.8m)
	support.global_position = Vector3(0.0, 0.0, 2.2)
	dps.global_position = Vector3(0.0, 0.0, 2.8)
	ctrl._physics_process(0.016)

	var status_b: Dictionary = ctrl.get_tether_status()
	assert(status_b["zone"] == "tension", "Zone is 'tension' when both followers in 2.0-3.0m")
	assert(status_b["leader_speed_multiplier"] == 1.0, "Leader maintains 1.0x")
	assert(status_b["support_multiplier"] == 1.25, "Support accelerated to 1.25x")
	assert(status_b["dps_multiplier"] == 1.25, "DPS accelerated to 1.25x")
	assert(leader.movement_component.speed_multiplier == 1.0, "Leader movement is 1.0x")
	assert(support.movement_component.speed_multiplier == 1.25, "Support movement is 1.25x")
	assert(dps.movement_component.speed_multiplier == 1.25, "DPS movement is 1.25x")

	print("PASS: 3.1 Tension zone accelerates lagging followers to 1.25x while leader maintains 1.0x")
	ctrl.queue_free()
	leader.queue_free()
	support.queue_free()
	dps.queue_free()


# ------------------------------------------------------------------------------
# Test 4: Rupture Zone (> 3.0m) Response
# ------------------------------------------------------------------------------
func _test_rupture_zone() -> void:
	print("\n[Test 4: Rupture Zone (> 3.0m) Response]")
	var ctrl: PartyFormationController = PartyFormationController.new()
	root.add_child(ctrl)

	var leader: CharacterEntity = _create_hero("Leader", Vector3(0.0, 0.0, 0.0))
	var support: CharacterEntity = _create_hero("Support", Vector3(0.0, 0.0, 1.5)) # 1.5m -> Ideal
	var dps: CharacterEntity = _create_hero("DPS", Vector3(0.0, 0.0, 4.2)) # 4.2m -> Rupture

	ctrl.set_party_members(leader, support, dps)

	var status: Dictionary = ctrl.get_tether_status()
	assert(status["zone"] == "rupture", "Zone must be 'rupture'")
	assert(status["leader_speed_multiplier"] == 0.5, "Leader slows down to 0.5x in rupture zone")
	assert(status["support_multiplier"] == 1.0, "Close support stays at 1.0x")
	assert(status["dps_multiplier"] == 1.25, "Lagged DPS boosted to 1.25x catchup speed")
	assert(is_equal_approx(status["max_distance"], 4.2), "Max distance is 4.2m")

	ctrl._physics_process(0.016)
	assert(leader.movement_component.speed_multiplier == 0.5, "Leader movement component slowed to 0.5x")
	assert(support.movement_component.speed_multiplier == 1.0, "Support movement component is 1.0x")
	assert(dps.movement_component.speed_multiplier == 1.25, "DPS movement component is 1.25x")

	# Case B: Both followers severely lagged in rupture (Support 3.5m, DPS 5.0m)
	support.global_position = Vector3(0.0, 0.0, 3.5)
	dps.global_position = Vector3(0.0, 0.0, 5.0)
	ctrl._physics_process(0.016)

	var status_b: Dictionary = ctrl.get_tether_status()
	assert(status_b["zone"] == "rupture", "Zone is 'rupture'")
	assert(status_b["leader_speed_multiplier"] == 0.5, "Leader slowed to 0.5x")
	assert(status_b["support_multiplier"] == 1.25, "Support boosted to 1.25x")
	assert(status_b["dps_multiplier"] == 1.25, "DPS boosted to 1.25x")
	assert(leader.movement_component.speed_multiplier == 0.5, "Leader speed multiplier applied as 0.5")

	print("PASS: 4.1 Rupture zone decelerates leader to 0.5x and keeps lagging followers at 1.25x")
	ctrl.queue_free()
	leader.queue_free()
	support.queue_free()
	dps.queue_free()


# ------------------------------------------------------------------------------
# Test 5: Continuous Recovery and Smooth Multi-Step Transitions
# ------------------------------------------------------------------------------
func _test_continuous_recovery_and_transitions() -> void:
	print("\n[Test 5: Continuous Recovery and Smooth Multi-Step Transitions]")
	var ctrl: PartyFormationController = PartyFormationController.new()
	root.add_child(ctrl)

	var leader: CharacterEntity = _create_hero("Leader", Vector3(0.0, 0.0, 0.0))
	var support: CharacterEntity = _create_hero("Support", Vector3(0.0, 0.0, 1.2)) # always close
	var dps: CharacterEntity = _create_hero("DPS", Vector3(0.0, 0.0, 4.5)) # starts far away

	ctrl.set_party_members(leader, support, dps)

	# Phase 1: Rupture (4.5m)
	ctrl._physics_process(0.016)
	assert(ctrl.get_tether_status()["zone"] == "rupture", "Phase 1: Rupture zone")
	assert(leader.movement_component.speed_multiplier == 0.5, "Phase 1: Leader is 0.5x")
	assert(dps.movement_component.speed_multiplier == 1.25, "Phase 1: DPS is 1.25x")

	# Phase 2: Follower catches up to Tension zone (2.6m)
	dps.global_position = Vector3(0.0, 0.0, 2.6)
	ctrl._physics_process(0.016)
	assert(ctrl.get_tether_status()["zone"] == "tension", "Phase 2: Transitioned to Tension zone")
	assert(leader.movement_component.speed_multiplier == 1.0, "Phase 2: Leader recovers full 1.0x speed")
	assert(dps.movement_component.speed_multiplier == 1.25, "Phase 2: DPS still receives 1.25x catchup")

	# Phase 3: Follower reaches Ideal zone (1.5m)
	dps.global_position = Vector3(0.0, 0.0, 1.5)
	ctrl._physics_process(0.016)
	assert(ctrl.get_tether_status()["zone"] == "ideal", "Phase 3: Transitioned to Ideal zone")
	assert(leader.movement_component.speed_multiplier == 1.0, "Phase 3: Leader maintains 1.0x")
	assert(dps.movement_component.speed_multiplier == 1.0, "Phase 3: DPS returns to normal 1.0x")

	print("PASS: 5.1 Dynamic multi-phase recovery (Rupture -> Tension -> Ideal) smoothly verified")
	ctrl.queue_free()
	leader.queue_free()
	support.queue_free()
	dps.queue_free()


# ------------------------------------------------------------------------------
# Test 6: Tolerance with Dead Followers
# ------------------------------------------------------------------------------
func _test_dead_follower_tolerance() -> void:
	print("\n[Test 6: Tolerance with Dead Followers]")
	var ctrl: PartyFormationController = PartyFormationController.new()
	root.add_child(ctrl)

	var leader: CharacterEntity = _create_hero("Leader", Vector3(0.0, 0.0, 0.0))
	var support: CharacterEntity = _create_hero("Support", Vector3(0.0, 0.0, 1.5)) # Alive, close
	var dead_dps: CharacterEntity = _create_hero("Dead_DPS", Vector3(0.0, 0.0, 15.0)) # 15m away, dead!

	dead_dps.health_component.current_hp = 0
	dead_dps.health_component.is_alive = false

	ctrl.set_party_members(leader, support, dead_dps)

	var status: Dictionary = ctrl.get_tether_status()
	assert(status["zone"] == "ideal", "Dead follower 15m away must NOT trigger rupture; zone remains 'ideal'")
	assert(status["leader_speed_multiplier"] == 1.0, "Leader not slowed down by dead follower")
	assert(status["alive_followers_count"] == 1, "Only 1 alive follower counted")
	assert(is_equal_approx(status["max_distance"], 1.5), "Max distance is calculated only from alive followers (1.5m)")

	ctrl._physics_process(0.016)
	assert(leader.movement_component.speed_multiplier == 1.0, "Leader movement remains at 1.0x")

	# Case B: All followers dead
	support.health_component.current_hp = 0
	support.health_component.is_alive = false
	support.global_position = Vector3(0.0, 0.0, 20.0)

	var status_all_dead: Dictionary = ctrl.get_tether_status()
	assert(status_all_dead["zone"] == "ideal", "When all followers are dead, zone is 'ideal'")
	assert(status_all_dead["leader_speed_multiplier"] == 1.0, "Leader speed remains 1.0x")
	assert(status_all_dead["alive_followers_count"] == 0, "0 alive followers")

	ctrl._physics_process(0.016)
	assert(leader.movement_component.speed_multiplier == 1.0, "Leader moves at 1.0x normally when alone")

	print("PASS: 6.1 Dead followers are safely ignored and do not slow down the leader")
	ctrl.queue_free()
	leader.queue_free()
	support.queue_free()
	dead_dps.queue_free()


# ------------------------------------------------------------------------------
# Test 7: Planar XZ Height Invariance
# ------------------------------------------------------------------------------
func _test_planar_xz_height_invariance() -> void:
	print("\n[Test 7: Planar XZ Height Invariance]")
	var ctrl: PartyFormationController = PartyFormationController.new()
	root.add_child(ctrl)

	# Leader on ground (Y = 0), Follower on a high ledge/ramp (Y = 20.0), but horizontal XZ distance is 1.5m
	var leader: CharacterEntity = _create_hero("Leader", Vector3(0.0, 0.0, 0.0))
	var support: CharacterEntity = _create_hero("Support", Vector3(1.5, 20.0, 0.0))

	ctrl.set_party_members(leader, support, null)

	var status: Dictionary = ctrl.get_tether_status()
	assert(is_equal_approx(status["support_distance"], 1.5), "Planar distance ignores Y height (distance is 1.5m, not ~20.05m)")
	assert(status["zone"] == "ideal", "Zone is 'ideal' because planar distance < 2.0m")
	assert(status["leader_speed_multiplier"] == 1.0, "Leader remains 1.0x")

	print("PASS: 7.1 Planar XZ calculations correctly ignore vertical Y offsets (slopes/ramps)")
	ctrl.queue_free()
	leader.queue_free()
	support.queue_free()


# ------------------------------------------------------------------------------
# Test 8: Custom Tether Thresholds & Multipliers
# ------------------------------------------------------------------------------
func _test_custom_tether_configuration() -> void:
	print("\n[Test 8: Custom Tether Thresholds & Multipliers]")
	var ctrl: PartyFormationController = PartyFormationController.new()
	root.add_child(ctrl)

	# Custom parameters: tighter leash
	ctrl.tether_ideal_distance = 1.0
	ctrl.tether_max_distance = 1.8
	ctrl.follower_catchup_multiplier = 1.5
	ctrl.leader_slow_multiplier = 0.25

	var leader: CharacterEntity = _create_hero("Leader", Vector3(0.0, 0.0, 0.0))
	var support: CharacterEntity = _create_hero("Support", Vector3(0.0, 0.0, 1.4)) # 1.4m -> Tension in custom (1.0 to 1.8)
	var dps: CharacterEntity = _create_hero("DPS", Vector3(0.0, 0.0, 2.0)) # 2.0m -> Rupture in custom (> 1.8)

	ctrl.set_party_members(leader, support, dps)

	var status: Dictionary = ctrl.get_tether_status()
	assert(status["zone"] == "rupture", "Custom rupture triggered at > 1.8m")
	assert(status["leader_speed_multiplier"] == 0.25, "Custom leader slow multiplier applied (0.25x)")
	assert(status["support_multiplier"] == 1.5, "Custom follower catchup multiplier applied (1.5x)")
	assert(status["dps_multiplier"] == 1.5, "Custom follower catchup multiplier applied (1.5x)")

	ctrl._physics_process(0.016)
	assert(leader.movement_component.speed_multiplier == 0.25, "Leader movement speed_multiplier is 0.25")
	assert(support.movement_component.speed_multiplier == 1.5, "Support movement speed_multiplier is 1.5")
	assert(dps.movement_component.speed_multiplier == 1.5, "DPS movement speed_multiplier is 1.5")

	print("PASS: 8.1 Custom tethering thresholds and multipliers fully operational")
	ctrl.queue_free()
	leader.queue_free()
	support.queue_free()
	dps.queue_free()
