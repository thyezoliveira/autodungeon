extends SceneTree

var _executed: bool = false


func _process(_delta: float) -> bool:
	if _executed:
		return false
	_executed = true
	_run_validation()
	return false


func _run_validation() -> void:
	print("--- Starting M0 Baseline Validation ---")
	var scene_path: String = "res://src/world/TestEnvironment3D.tscn"
	var packed_scene: PackedScene = load(scene_path) as PackedScene
	if packed_scene == null:
		printerr("FAIL: Could not load scene: ", scene_path)
		quit(1)
		return

	var root_node: Node3D = packed_scene.instantiate() as Node3D
	if root_node == null:
		printerr("FAIL: Could not instantiate scene: ", scene_path)
		quit(1)
		return

	root.add_child(root_node)
	print("PASS: Scene instantiated and added to root tree: ", root_node.name)

	# Validate WorldEnvironment
	var world_env: WorldEnvironment = root_node.get_node_or_null("WorldEnvironment") as WorldEnvironment
	if world_env == null:
		printerr("FAIL: WorldEnvironment node missing")
		quit(1)
		return
	if world_env.environment == null:
		printerr("FAIL: WorldEnvironment has no Environment resource")
		quit(1)
		return
	print("PASS: WorldEnvironment configured with Environment resource")

	# Validate DirectionalLight3D
	var dir_light: DirectionalLight3D = root_node.get_node_or_null("DirectionalLight3D") as DirectionalLight3D
	if dir_light == null:
		printerr("FAIL: DirectionalLight3D node missing")
		quit(1)
		return
	if not dir_light.shadow_enabled:
		printerr("FAIL: DirectionalLight3D shadow_enabled should be true")
		quit(1)
		return
	print("PASS: DirectionalLight3D configured with shadows enabled")

	# Validate GroundPlane
	var ground: StaticBody3D = root_node.get_node_or_null("GroundPlane") as StaticBody3D
	if ground == null:
		printerr("FAIL: GroundPlane node missing or not StaticBody3D")
		quit(1)
		return
	if ground.collision_layer != 1:
		printerr("FAIL: GroundPlane collision_layer should be 1 (World_Environment), got: ", ground.collision_layer)
		quit(1)
		return

	var col_shape: CollisionShape3D = ground.get_node_or_null("CollisionShape3D") as CollisionShape3D
	if col_shape == null or not (col_shape.shape is BoxShape3D):
		printerr("FAIL: GroundPlane CollisionShape3D missing or not BoxShape3D")
		quit(1)
		return
	var box_shape: BoxShape3D = col_shape.shape as BoxShape3D
	if box_shape.size != Vector3(50, 1, 50):
		printerr("FAIL: GroundPlane BoxShape3D size should be Vector3(50, 1, 50), got: ", box_shape.size)
		quit(1)
		return

	var mesh_inst: MeshInstance3D = ground.get_node_or_null("MeshInstance3D") as MeshInstance3D
	if mesh_inst == null or not (mesh_inst.mesh is BoxMesh):
		printerr("FAIL: GroundPlane MeshInstance3D missing or not BoxMesh")
		quit(1)
		return
	var box_mesh: BoxMesh = mesh_inst.mesh as BoxMesh
	if box_mesh.size != Vector3(50, 1, 50):
		printerr("FAIL: GroundPlane BoxMesh size should be Vector3(50, 1, 50), got: ", box_mesh.size)
		quit(1)
		return
	print("PASS: GroundPlane with BoxShape3D and BoxMesh 50x1x50 validated")

	# Validate IsometricCameraRig
	var camera_rig: IsometricCameraRig = root_node.get_node_or_null("IsometricCameraRig") as IsometricCameraRig
	if camera_rig == null:
		printerr("FAIL: IsometricCameraRig node missing or not IsometricCameraRig class")
		quit(1)
		return
	if camera_rig.follow_speed <= 0.0:
		printerr("FAIL: IsometricCameraRig follow_speed should be > 0")
		quit(1)
		return

	var camera: Camera3D = camera_rig.get_node_or_null("Camera3D") as Camera3D
	if camera == null:
		printerr("FAIL: Camera3D missing under IsometricCameraRig")
		quit(1)
		return
	if not camera.current:
		printerr("FAIL: Camera3D current should be true")
		quit(1)
		return

	var rot_deg_x: float = camera.rotation_degrees.x
	if not is_equal_approx(rot_deg_x, -45.0):
		printerr("FAIL: Camera3D rotation_degrees.x should be -45.0, got: ", rot_deg_x)
		quit(1)
		return
	print("PASS: IsometricCameraRig and Camera3D with -45 deg rotation validated (rotation_degrees: ", camera.rotation_degrees, ")")

	# Test smooth follow logic in IsometricCameraRig
	var mock_target: Node3D = Node3D.new()
	root_node.add_child(mock_target)
	mock_target.global_position = Vector3(10.0, 0.0, -10.0)
	camera_rig.set_target(mock_target)
	var initial_pos: Vector3 = camera_rig.global_position
	camera_rig._physics_process(0.1)
	var moved_pos: Vector3 = camera_rig.global_position
	if moved_pos == initial_pos:
		printerr("FAIL: IsometricCameraRig did not move towards target")
		quit(1)
		return
	print("PASS: IsometricCameraRig _physics_process smoothly moved from ", initial_pos, " to ", moved_pos)

	mock_target.free()
	root_node.free()
	print("=== ALL M0.3 VALIDATION CHECKS PASSED ===")
	quit(0)
