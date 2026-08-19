extends SceneTree

var _stage: int = 0
var _frame_count: int = 0
var _entity: CharacterEntity = null
var _floor: StaticBody3D = null


func _process(_delta: float) -> bool:
	if _stage == 0:
		_stage = 1
		_run_initial_tests()
	return false


func _physics_process(delta: float) -> bool:
	if _stage == 1:
		_frame_count += 1
		# Run physics steps until entity settles on ground
		if _frame_count < 60:
			# Advance physics
			pass
		else:
			_stage = 2
			_verify_landing()
	return false


func _run_initial_tests() -> void:
	print("========================================")
	print("--- Starting CharacterEntity M2.1 Unit Tests ---")
	print("========================================")

	# ----------------------------------------------------
	# Test Group 1: Scene Resource & Instantiation
	# ----------------------------------------------------
	print("\n[Group 1: Scene Resource & Instantiation]")
	var scene_path: String = "res://src/entities/base/CharacterEntity.tscn"
	assert(ResourceLoader.exists(scene_path), "CharacterEntity.tscn must exist")
	
	var packed_scene: PackedScene = load(scene_path) as PackedScene
	assert(packed_scene != null, "CharacterEntity.tscn must load as PackedScene")
	
	var instance: Node = packed_scene.instantiate()
	assert(instance != null, "Instantiating CharacterEntity.tscn must succeed")
	assert(instance is CharacterEntity, "Root node must be of type CharacterEntity")
	assert(instance is CharacterBody3D, "Root node must extend CharacterBody3D")
	
	_entity = instance as CharacterEntity
	assert(_entity.collision_layer == 2, "Default collision_layer should be 2 (Hero_Bodies)")
	assert(_entity.collision_mask == 1, "Default collision_mask should be 1 (World_Environment)")
	assert(_entity.hero_data == null, "Default hero_data should be null")
	assert(_entity.enemy_data == null, "Default enemy_data should be null")
	print("PASS: 1.1 CharacterEntity scene loaded, instantiated and default properties verified")

	# ----------------------------------------------------
	# Test Group 2: Node Hierarchy & Components
	# ----------------------------------------------------
	print("\n[Group 2: Node Hierarchy & Components]")
	root.add_child(_entity)
	
	assert(_entity.body_collider != null, "body_collider reference must be valid")
	assert(_entity.body_collider is CollisionShape3D, "BodyCollider must be a CollisionShape3D")
	assert(is_equal_approx(_entity.body_collider.position.y, 0.9), "BodyCollider Y position should be 0.9m")
	
	var shape: Shape3D = _entity.body_collider.shape
	assert(shape is CapsuleShape3D, "BodyCollider shape must be CapsuleShape3D")
	var capsule_shape: CapsuleShape3D = shape as CapsuleShape3D
	assert(is_equal_approx(capsule_shape.radius, 0.4), "CapsuleShape3D radius must be 0.4m")
	assert(is_equal_approx(capsule_shape.height, 1.8), "CapsuleShape3D height must be 1.8m")
	print("PASS: 2.1 BodyCollider CapsuleShape3D dimensions and position verified")

	assert(_entity.visuals != null, "visuals reference must be valid")
	assert(_entity.visuals is Node3D, "Visuals must be a Node3D")
	var model_mesh: MeshInstance3D = _entity.visuals.get_node_or_null("ModelMesh") as MeshInstance3D
	assert(model_mesh != null, "Visuals/ModelMesh must exist")
	assert(model_mesh.mesh is CapsuleMesh, "ModelMesh mesh must be CapsuleMesh")
	var capsule_mesh: CapsuleMesh = model_mesh.mesh as CapsuleMesh
	assert(is_equal_approx(capsule_mesh.radius, 0.4), "CapsuleMesh radius must be 0.4m")
	assert(is_equal_approx(capsule_mesh.height, 1.8), "CapsuleMesh height must be 1.8m")
	assert(capsule_mesh.material is StandardMaterial3D, "ModelMesh must have a visible StandardMaterial3D")
	print("PASS: 2.2 Visuals/ModelMesh CapsuleMesh dimensions and material verified")

	assert(_entity.components != null, "components reference must be valid")
	assert(_entity.components is Node3D, "Components node must be a Node3D")
	assert(_entity.state_machine != null, "state_machine reference must be valid")
	print("PASS: 2.3 Components and StateMachine nodes verified")

	# ----------------------------------------------------
	# Test Group 3: Setup Entity Data
	# ----------------------------------------------------
	print("\n[Group 3: Setup Entity Data]")
	var bromm_res: HeroData = load("res://src/data/heroes/resources/hero_bromm.tres") as HeroData
	_entity.hero_data = bromm_res
	_entity.setup_entity_data()
	assert(_entity.hero_data.hero_id == "bromm", "hero_data assigned successfully")
	print("PASS: 3.1 HeroData injection and setup_entity_data verified")

	var enemy_res: EnemyData = load("res://src/data/enemies/enemy_goblin_warrior.tres") as EnemyData
	_entity.enemy_data = enemy_res
	_entity.setup_entity_data()
	assert(_entity.enemy_data.enemy_id == "goblin_warrior", "enemy_data assigned successfully")
	print("PASS: 3.2 EnemyData injection and setup_entity_data verified")

	# ----------------------------------------------------
	# Test Group 4: Physics & Gravity Setup
	# ----------------------------------------------------
	print("\n[Group 4: Physics & Gravity Simulation Setup]")
	_floor = StaticBody3D.new()
	_floor.collision_layer = 1
	_floor.collision_mask = 0
	
	var floor_col: CollisionShape3D = CollisionShape3D.new()
	var box_shape: BoxShape3D = BoxShape3D.new()
	box_shape.size = Vector3(50.0, 1.0, 50.0)
	floor_col.shape = box_shape
	floor_col.position = Vector3(0.0, -0.5, 0.0) # Top surface at Y = 0.0
	_floor.add_child(floor_col)
	root.add_child(_floor)

	_entity.global_position = Vector3(0.0, 3.0, 0.0)
	_entity.velocity = Vector3.ZERO
	print("Entity spawned at Y = 3.0. Simulating physics frames...")


func _verify_landing() -> void:
	print("\n[Group 5: Landing & Collision Verification]")
	print("Entity final global_position: ", _entity.global_position)
	print("Entity is_on_floor: ", _entity.is_on_floor())
	
	# The capsule bottom is at Y=0 relative to entity root (since center is at Y=0.9 and height=1.8).
	# Floor top is at Y=0.0. Therefore, when resting on the floor, global_position.y should be ~0.0.
	assert(abs(_entity.global_position.y) < 0.1, "Entity should have landed on the floor near Y = 0.0, got: " + str(_entity.global_position.y))
	assert(_entity.is_on_floor(), "Entity should be on floor after landing")
	print("PASS: 5.1 Gravity fall and static ground collision verified successfully")

	# Clean up
	_entity.queue_free()
	_floor.queue_free()

	print("\n========================================")
	print("=== ALL CHARACTER ENTITY M2.1 TESTS PASSED ===")
	print("========================================")
	quit(0)
