extends SceneTree

var _executed: bool = false


func _process(_delta: float) -> bool:
	if _executed:
		return false
	_executed = true
	_run_tests()
	return false


func _run_tests() -> void:
	print("--- Starting IsometricCameraRig Unit Tests ---")
	var rig: IsometricCameraRig = IsometricCameraRig.new()
	root.add_child(rig)

	# Test 1: Initial position with null target
	rig._ready()
	assert(rig.global_position == rig.camera_offset, "Rig should initialize at camera_offset if target is null")
	print("PASS: Test 1 - Initial position default")

	# Test 2: Custom camera offset and follow speed
	rig.camera_offset = Vector3(0.0, 20.0, 20.0)
	rig.follow_speed = 10.0
	assert(rig.camera_offset == Vector3(0.0, 20.0, 20.0), "Custom camera_offset applied")
	assert(rig.follow_speed == 10.0, "Custom follow_speed applied")
	print("PASS: Test 2 - Custom export properties")

	# Test 3: Tracking target in XZ plane
	var target_node: Node3D = Node3D.new()
	root.add_child(target_node)
	target_node.global_position = Vector3(100.0, 5.0, -50.0)
	rig.set_target(target_node)
	assert(rig.target == target_node, "set_target should assign target")

	# Step physics process
	var prev_pos: Vector3 = rig.global_position
	rig._physics_process(0.1) # 10.0 * 0.1 = 1.0 (clamped lerp ratio) -> should reach target + offset
	var expected_pos: Vector3 = Vector3(100.0, 0.0, -50.0) + rig.camera_offset
	assert(rig.global_position.is_equal_approx(expected_pos), "Rig should reach target XZ + offset")
	print("PASS: Test 3 - Tracking target in XZ plane: ", rig.global_position)

	# Test 4: Target freed / invalid handled safely
	target_node.free()
	rig._physics_process(0.1) # should not crash or error
	print("PASS: Test 4 - Target freed handled safely without crash")

	# Test 5: Target set to null
	rig.set_target(null)
	rig._physics_process(0.1)
	print("PASS: Test 5 - Target null handled safely")

	rig.free()
	print("=== ALL ISOMETRIC CAMERA RIG UNIT TESTS PASSED ===")
	quit(0)
