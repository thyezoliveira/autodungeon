extends SceneTree

# ==============================================================================
# Unit Test Suite: MovementComponent.gd (Task M3.1)
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
	print("--- Starting MovementComponent 3D Unit Tests (Task M3.1) ---")
	print("================================================================================")

	# ----------------------------------------------------
	# Test Group 1: Default Properties & Standalone Null Safety
	# ----------------------------------------------------
	print("\n[Group 1: Default Properties & Standalone Null Safety]")
	var standalone: MovementComponent = MovementComponent.new()
	assert(standalone != null, "MovementComponent instance must be created")
	assert(is_equal_approx(standalone.base_speed, 4.0), "Default base_speed should be 4.0")
	assert(is_equal_approx(standalone.rotation_speed, 10.0), "Default rotation_speed should be 10.0")
	assert(is_equal_approx(standalone.speed_multiplier, 1.0), "Default speed_multiplier should be 1.0")
	assert(standalone.current_target_position == Vector3.ZERO, "Default current_target_position should be Vector3.ZERO")
	assert(standalone.navigation_agent == null, "Default navigation_agent should be null")
	assert(standalone.character_body == null, "Default character_body should be null")
	assert(standalone.is_moving == false, "Default is_moving should be false")

	# Safe execution without crash when character_body is null
	standalone.move_towards(Vector3(10.0, 0.0, 10.0))
	assert(standalone.current_target_position == Vector3(10.0, 0.0, 10.0), "Target position set correctly")
	assert(standalone.is_moving == true, "is_moving is true after move_towards")
	standalone.process_movement(0.016)
	standalone.stop_movement()
	assert(standalone.is_moving == false, "is_moving is false after stop_movement")
	print("PASS: 1.1 Default properties and null-safe standalone execution verified")
	standalone.free()

	# ----------------------------------------------------
	# Test Group 2: Defensive Dependency Auto-Resolution
	# ----------------------------------------------------
	print("\n[Group 2: Defensive Dependency Auto-Resolution]")

	# 2.1 Parent resolution (CharacterBody3D -> MovementComponent)
	var parent_body: CharacterBody3D = CharacterBody3D.new()
	parent_body.name = "ParentBody"
	root.add_child(parent_body)

	var move_child: MovementComponent = MovementComponent.new()
	parent_body.add_child(move_child)
	move_child._ready()

	assert(move_child.character_body == parent_body, "Auto-resolved character_body from parent")
	print("PASS: 2.1 Auto-resolved CharacterBody3D from parent node")

	# 2.2 Grandparent resolution (CharacterBody3D -> Components -> MovementComponent)
	var root_body: CharacterBody3D = CharacterBody3D.new()
	root_body.name = "RootBody"
	root.add_child(root_body)

	var comps_container: Node3D = Node3D.new()
	comps_container.name = "Components"
	root_body.add_child(comps_container)

	var nav_sibling: NavigationAgent3D = NavigationAgent3D.new()
	nav_sibling.name = "NavigationAgent3D"
	comps_container.add_child(nav_sibling)

	var move_grandchild: MovementComponent = MovementComponent.new()
	comps_container.add_child(move_grandchild)
	move_grandchild._ready()

	assert(move_grandchild.character_body == root_body, "Auto-resolved character_body from grandparent")
	assert(move_grandchild.navigation_agent == nav_sibling, "Auto-resolved navigation_agent from sibling in Components")
	print("PASS: 2.2 Auto-resolved CharacterBody3D and NavigationAgent3D from modular Components container")

	# Clean up Group 2 nodes
	parent_body.queue_free()
	root_body.queue_free()

	# ----------------------------------------------------
	# Test Group 3: Directional Velocity Calculation in XZ Plane
	# ----------------------------------------------------
	print("\n[Group 3: Directional Velocity Calculation in XZ Plane]")
	var test_body: CharacterBody3D = CharacterBody3D.new()
	test_body.name = "TestBody"
	root.add_child(test_body)

	var movement: MovementComponent = MovementComponent.new()
	test_body.add_child(movement)
	movement._ready()
	movement.base_speed = 4.0
	movement.speed_multiplier = 1.0

	# 3.1 Movement towards +X (Vector3(10, 0, 0))
	test_body.global_position = Vector3.ZERO
	test_body.velocity = Vector3.ZERO
	movement.move_towards(Vector3(10.0, 0.0, 0.0))
	movement.process_movement(0.016)

	assert(is_equal_approx(test_body.velocity.x, 4.0), "Velocity X should be 4.0, got: %f" % test_body.velocity.x)
	assert(is_equal_approx(test_body.velocity.z, 0.0), "Velocity Z should be 0.0, got: %f" % test_body.velocity.z)
	print("PASS: 3.1 Cardinal movement (+X) calculated accurately: velocity = %s" % str(test_body.velocity))

	# 3.2 Movement towards +Z (Vector3(0, 0, 10))
	test_body.global_position = Vector3.ZERO
	test_body.velocity = Vector3.ZERO
	movement.move_towards(Vector3(0.0, 0.0, 10.0))
	movement.process_movement(0.016)

	assert(is_equal_approx(test_body.velocity.x, 0.0), "Velocity X should be 0.0, got: %f" % test_body.velocity.x)
	assert(is_equal_approx(test_body.velocity.z, 4.0), "Velocity Z should be 4.0, got: %f" % test_body.velocity.z)
	print("PASS: 3.2 Cardinal movement (+Z) calculated accurately: velocity = %s" % str(test_body.velocity))

	# 3.3 Diagonal movement (Vector3(30, 0, 40) - 3:4:5 right triangle)
	test_body.global_position = Vector3.ZERO
	test_body.velocity = Vector3.ZERO
	movement.move_towards(Vector3(30.0, 0.0, 40.0))
	movement.process_movement(0.016)

	# Normalized dir is (0.6, 0, 0.8), speed = 4.0 -> vx = 2.4, vz = 3.2
	assert(is_equal_approx(test_body.velocity.x, 2.4), "Velocity X should be 2.4 (3/5 * 4.0), got: %f" % test_body.velocity.x)
	assert(is_equal_approx(test_body.velocity.z, 3.2), "Velocity Z should be 3.2 (4/5 * 4.0), got: %f" % test_body.velocity.z)
	var horizontal_speed: float = Vector2(test_body.velocity.x, test_body.velocity.z).length()
	assert(is_equal_approx(horizontal_speed, 4.0), "Total planar speed must equal base_speed (4.0), got: %f" % horizontal_speed)
	print("PASS: 3.3 Diagonal XZ movement normalized correctly (vx=%.2f, vz=%.2f, speed=%.2f)" % [test_body.velocity.x, test_body.velocity.z, horizontal_speed])

	# 3.4 Negative direction (-X)
	test_body.global_position = Vector3.ZERO
	test_body.velocity = Vector3.ZERO
	movement.move_towards(Vector3(-10.0, 0.0, 0.0))
	movement.process_movement(0.016)

	assert(is_equal_approx(test_body.velocity.x, -4.0), "Velocity X should be -4.0, got: %f" % test_body.velocity.x)
	assert(is_equal_approx(test_body.velocity.z, 0.0), "Velocity Z should be 0.0, got: %f" % test_body.velocity.z)
	print("PASS: 3.4 Negative direction movement (-X) verified")

	# ----------------------------------------------------
	# Test Group 4: Speed Multiplier (Tethering / Buffs / Slows)
	# ----------------------------------------------------
	print("\n[Group 4: Speed Multiplier (Tethering / Buffs / Slows)]")

	# 4.1 Sprint / Catch-up boost (1.25x) -> 4.0 * 1.25 = 5.0
	movement.set_speed_multiplier(1.25)
	assert(is_equal_approx(movement.speed_multiplier, 1.25), "speed_multiplier should be 1.25")
	test_body.global_position = Vector3.ZERO
	movement.move_towards(Vector3(10.0, 0.0, 0.0))
	movement.process_movement(0.016)
	assert(is_equal_approx(test_body.velocity.x, 5.0), "Velocity X should be 5.0 with 1.25x boost, got: %f" % test_body.velocity.x)
	print("PASS: 4.1 Tethering catch-up boost (1.25x -> 5.0 m/s) verified")

	# 4.2 Tethering deceleration / rupture slow (0.5x) -> 4.0 * 0.5 = 2.0
	movement.set_speed_multiplier(0.5)
	assert(is_equal_approx(movement.speed_multiplier, 0.5), "speed_multiplier should be 0.5")
	test_body.global_position = Vector3.ZERO
	movement.move_towards(Vector3(10.0, 0.0, 0.0))
	movement.process_movement(0.016)
	assert(is_equal_approx(test_body.velocity.x, 2.0), "Velocity X should be 2.0 with 0.5x slow, got: %f" % test_body.velocity.x)
	print("PASS: 4.2 Tethering rupture deceleration (0.5x -> 2.0 m/s) verified")

	# 4.3 Negative multiplier clamped to 0.0
	movement.set_speed_multiplier(-1.0)
	assert(is_equal_approx(movement.speed_multiplier, 0.0), "Negative speed_multiplier must clamp to 0.0")
	test_body.global_position = Vector3.ZERO
	movement.move_towards(Vector3(10.0, 0.0, 0.0))
	movement.process_movement(0.016)
	assert(is_equal_approx(test_body.velocity.x, 0.0), "Velocity X should be 0.0 when multiplier is 0.0")
	print("PASS: 4.3 Negative speed multiplier safely clamped to 0.0")

	# Reset multiplier
	movement.set_speed_multiplier(1.0)

	# ----------------------------------------------------
	# Test Group 5: Target Arrival & target_reached Signal Emission
	# ----------------------------------------------------
	print("\n[Group 5: Target Arrival & target_reached Signal Emission]")
	var signal_tracker: Dictionary = {
		"target_reached_count": 0
	}

	movement.target_reached.connect(func() -> void:
		signal_tracker["target_reached_count"] += 1
	)

	# 5.1 Target already within desired distance (distance <= 0.5m)
	test_body.global_position = Vector3.ZERO
	test_body.velocity = Vector3.ZERO
	movement.move_towards(Vector3(0.3, 0.0, 0.2)) # Distance approx 0.36m <= 0.5m
	movement.process_movement(0.016)

	assert(signal_tracker["target_reached_count"] == 1, "target_reached signal must be emitted upon arrival")
	assert(movement.is_moving == false, "is_moving should be false after arrival")
	assert(is_equal_approx(test_body.velocity.x, 0.0), "Velocity X zeroed upon arrival")
	assert(is_equal_approx(test_body.velocity.z, 0.0), "Velocity Z zeroed upon arrival")
	print("PASS: 5.1 target_reached emitted and velocity zeroed on destination arrival")

	# 5.2 Subsequent process_movement calls must not emit duplicate target_reached signals
	movement.process_movement(0.016)
	movement.process_movement(0.016)
	assert(signal_tracker["target_reached_count"] == 1, "target_reached must NOT be emitted repeatedly when stationary")
	print("PASS: 5.2 Signal emission idempotency verified (no duplicate emissions)")

	# ----------------------------------------------------
	# Test Group 6: stop_movement() & State Control
	# ----------------------------------------------------
	print("\n[Group 6: stop_movement() & State Control]")
	test_body.global_position = Vector3.ZERO
	movement.move_towards(Vector3(100.0, 0.0, 100.0))
	movement.process_movement(0.016)

	assert(movement.is_moving == true, "is_moving is true while traversing")
	assert(test_body.velocity.length_squared() > 0.0, "Velocity is active while moving")

	movement.stop_movement()
	assert(movement.is_moving == false, "is_moving is false after stop_movement()")
	assert(is_equal_approx(test_body.velocity.x, 0.0), "Velocity X immediately halted")
	assert(is_equal_approx(test_body.velocity.z, 0.0), "Velocity Z immediately halted")

	# Further process calls while stopped keep velocity at zero
	movement.process_movement(0.016)
	assert(is_equal_approx(test_body.velocity.x, 0.0), "Velocity X remains zero while stopped")
	assert(is_equal_approx(test_body.velocity.z, 0.0), "Velocity Z remains zero while stopped")
	print("PASS: 6.1 stop_movement halts physical motion and resets is_moving state cleanly")

	# ----------------------------------------------------
	# Test Group 7: Smooth Rotation Interpolation in XZ Plane
	# ----------------------------------------------------
	print("\n[Group 7: Smooth Rotation Interpolation in XZ Plane]")
	test_body.global_position = Vector3.ZERO
	test_body.rotation.y = 0.0
	movement.rotation_speed = 10.0

	# Moving towards +X (target angle atan2(1, 0) = PI / 2 approx 1.570796)
	movement.move_towards(Vector3(10.0, 0.0, 0.0))
	var initial_rot_y: float = test_body.rotation.y
	movement.process_movement(0.05) # 0.05s * 10.0 = 0.5 lerp weight

	assert(test_body.rotation.y > initial_rot_y, "rotation.y should interpolate towards target angle (PI/2)")
	assert(test_body.rotation.y <= (PI / 2.0) + 0.01, "rotation.y should not overshoot target angle")
	print("PASS: 7.1 CharacterBody3D rotation smoothly interpolated towards movement direction in XZ plane (current: %.3f rad)" % test_body.rotation.y)

	# ----------------------------------------------------
	# Test Group 8: Gravity Application in Y Axis
	# ----------------------------------------------------
	print("\n[Group 8: Gravity Application in Y Axis]")
	test_body.global_position = Vector3(0.0, 5.0, 0.0)
	test_body.velocity = Vector3.ZERO
	movement.stop_movement()

	# Process frame while in air (is_on_floor() is false)
	movement.process_movement(0.1)
	assert(test_body.velocity.y < 0.0, "Gravity should apply downward velocity when in air")
	var expected_fall_vy: float = -movement.gravity * 0.1
	assert(is_equal_approx(test_body.velocity.y, expected_fall_vy), "Downwards velocity should equal -gravity * delta (%f), got: %f" % [expected_fall_vy, test_body.velocity.y])
	print("PASS: 8.1 Gravity acceleration correctly applied to Y velocity in air (vy: %.2f m/s)" % test_body.velocity.y)

	test_body.queue_free()

	# ----------------------------------------------------
	# Test Group 9: Full Integration with CharacterEntity.tscn
	# ----------------------------------------------------
	print("\n[Group 9: Full Integration with CharacterEntity.tscn]")
	var char_scene: PackedScene = load("res://src/entities/base/CharacterEntity.tscn") as PackedScene
	assert(char_scene != null, "CharacterEntity.tscn must load successfully")

	var char_entity: CharacterEntity = char_scene.instantiate() as CharacterEntity
	assert(char_entity != null, "CharacterEntity must instantiate")
	root.add_child(char_entity)

	assert(char_entity.movement_component != null, "char_entity.movement_component reference must be populated")
	assert(char_entity.navigation_agent != null, "char_entity.navigation_agent reference must be populated")
	assert(char_entity.movement_component.character_body == char_entity, "movement_component.character_body bound to CharacterEntity")
	assert(char_entity.movement_component.navigation_agent == char_entity.navigation_agent, "movement_component.navigation_agent bound to NavigationAgent3D")

	# Test movement invocation through integrated scene
	char_entity.global_position = Vector3.ZERO
	char_entity.movement_component.move_towards(Vector3(10.0, 0.0, 5.0))
	char_entity.movement_component.process_movement(0.016)

	assert(char_entity.movement_component.is_moving == true, "Movement active on integrated entity")
	assert(char_entity.velocity.x > 0.0, "Integrated entity moving horizontally in X")
	assert(char_entity.velocity.z > 0.0, "Integrated entity moving horizontally in Z")

	char_entity.movement_component.stop_movement()
	assert(char_entity.movement_component.is_moving == false, "Integrated entity stopped successfully")
	print("PASS: 9.1 CharacterEntity.tscn modular MovementComponent & NavigationAgent3D integration verified")

	char_entity.queue_free()

	print("\n================================================================================")
	print("=== ALL MOVEMENTCOMPONENT UNIT TESTS PASSED (9/9 GROUPS) ===")
	print("================================================================================")
	quit(0)
