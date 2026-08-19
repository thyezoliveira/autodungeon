extends SceneTree

var _executed: bool = false


func _process(_delta: float) -> bool:
	if _executed:
		return false
	_executed = true
	_run_all_tests()
	return false


func _run_all_tests() -> void:
	print("========================================")
	print("--- Starting NodePool Unit Tests ---")
	print("========================================")

	var dummy_scene: PackedScene = load("res://tests/fixtures/dummy_pool_item.tscn")
	assert(dummy_scene != null, "Fixture dummy_pool_item.tscn must load successfully")

	# ----------------------------------------------------
	# Test Group 1: Default State & Initialization
	# ----------------------------------------------------
	print("\n[Group 1: Default State & Initialization]")
	var pool: NodePool = NodePool.new()
	assert(pool.prefab_scene == null, "Default prefab_scene should be null")
	assert(pool.initial_pool_size == 20, "Default initial_pool_size should be 20")
	assert(pool.max_pool_size == 50, "Default max_pool_size should be 50")
	assert(pool.get_available_count() == 0, "Default available count should be 0")
	assert(pool.get_active_count() == 0, "Default active count should be 0")
	assert(pool.get_total_count() == 0, "Default total count should be 0")
	print("PASS: 1.1 NodePool default properties")

	# Initialize via SceneTree _ready with prefab_scene
	pool.prefab_scene = dummy_scene
	pool.initial_pool_size = 20
	pool.max_pool_size = 50
	root.add_child(pool)

	assert(pool.get_available_count() == 20, "Available count should be 20 after ready")
	assert(pool.get_active_count() == 0, "Active count should be 0 after ready")
	assert(pool.get_total_count() == 20, "Total count should be 20 after ready")
	assert(pool.get_child_count() == 20, "Pool should have 20 child nodes instantiated")

	# Verify all initial instances are deactivated
	for child in pool.get_children():
		var dummy: DummyPoolItem = child as DummyPoolItem
		assert(dummy != null, "Pool children should be DummyPoolItem instances")
		assert(dummy.process_mode == Node.PROCESS_MODE_DISABLED, "Inactive node process_mode must be DISABLED")
		assert(dummy.visible == false, "Inactive node visibility must be false")
		assert(dummy.acquire_count == 0, "Inactive node acquire_count should be 0")
	print("PASS: 1.2 NodePool pre-allocation and deactivation in _ready")

	# ----------------------------------------------------
	# Test Group 2: Acquire & Release Lifecycle & Hooks
	# ----------------------------------------------------
	print("\n[Group 2: Acquire & Release Lifecycle & Hooks]")
	var node1: DummyPoolItem = pool.acquire_node() as DummyPoolItem
	assert(node1 != null, "acquire_node() must return a valid node")
	assert(node1.process_mode == Node.PROCESS_MODE_INHERIT, "Acquired node process_mode must be INHERIT")
	assert(node1.visible == true, "Acquired node must be visible")
	assert(node1.acquire_count == 1, "on_pool_acquire hook should have been called once")
	assert(node1.release_count == 0, "on_pool_release hook should not have been called yet")
	assert(pool.get_available_count() == 19, "Available count should be 19")
	assert(pool.get_active_count() == 1, "Active count should be 1")
	assert(pool.get_total_count() == 20, "Total count should remain 20")
	print("PASS: 2.1 Single node acquire and activation")

	# Acquire 4 more nodes (total 5 active)
	var batch: Array[DummyPoolItem] = []
	for i in range(4):
		var n: DummyPoolItem = pool.acquire_node() as DummyPoolItem
		assert(n != null, "Acquired node in batch must not be null")
		batch.append(n)

	assert(pool.get_available_count() == 15, "Available count should be 15")
	assert(pool.get_active_count() == 5, "Active count should be 5")
	assert(pool.get_total_count() == 20, "Total count should be 20")
	print("PASS: 2.2 Batch acquisition (5 active, 15 available)")

	# Release 3 nodes
	pool.release_node(batch[0])
	pool.release_node(batch[1])
	pool.release_node(batch[2])

	assert(batch[0].process_mode == Node.PROCESS_MODE_DISABLED, "Released node process_mode must be DISABLED")
	assert(batch[0].visible == false, "Released node must be invisible")
	assert(batch[0].release_count == 1, "on_pool_release hook should have been called once")
	assert(pool.get_available_count() == 18, "Available count should be 18")
	assert(pool.get_active_count() == 2, "Active count should be 2")
	assert(pool.get_total_count() == 20, "Total count should remain 20")
	print("PASS: 2.3 Batch release (3 nodes released -> 2 active, 18 available)")

	# Release remaining 2 nodes
	pool.release_node(node1)
	pool.release_node(batch[3])
	assert(pool.get_available_count() == 20, "Available count should return to 20")
	assert(pool.get_active_count() == 0, "Active count should return to 0")
	assert(pool.get_total_count() == 20, "Total count should be 20")
	print("PASS: 2.4 All nodes returned to available pool")

	# ----------------------------------------------------
	# Test Group 3: Dynamic Growth & Max Limit Constraints
	# ----------------------------------------------------
	print("\n[Group 3: Dynamic Growth & Max Limit Constraints]")
	var small_pool: NodePool = NodePool.new()
	small_pool.prefab_scene = dummy_scene
	small_pool.initial_pool_size = 3
	small_pool.max_pool_size = 6
	root.add_child(small_pool)

	assert(small_pool.get_available_count() == 3, "small_pool should start with 3 available")
	assert(small_pool.get_total_count() == 3, "small_pool total count should be 3")

	var acquired_list: Array[Node] = []
	# Acquire initial 3
	for i in range(3):
		acquired_list.append(small_pool.acquire_node())
	assert(small_pool.get_available_count() == 0, "0 available after acquiring initial 3")
	assert(small_pool.get_active_count() == 3, "3 active")
	assert(small_pool.get_total_count() == 3, "3 total")

	# Acquire 3 more (should dynamically grow up to max_pool_size 6)
	for i in range(3):
		var dyn_node: Node = small_pool.acquire_node()
		assert(dyn_node != null, "Dynamically expanded node should not be null")
		acquired_list.append(dyn_node)

	assert(small_pool.get_available_count() == 0, "0 available when full")
	assert(small_pool.get_active_count() == 6, "6 active (at max limit)")
	assert(small_pool.get_total_count() == 6, "6 total (at max limit)")
	print("PASS: 3.1 Dynamic growth up to max_pool_size")

	# Attempt to acquire beyond max_pool_size (should return null safely)
	var overflow_node: Node = small_pool.acquire_node()
	assert(overflow_node == null, "acquire_node() must return null when max_pool_size is reached")
	assert(small_pool.get_active_count() == 6, "Active count must remain 6")
	assert(small_pool.get_total_count() == 6, "Total count must remain 6")
	print("PASS: 3.2 Max pool size limit rejection")

	# Release 1 and re-acquire
	var released_item: Node = acquired_list.pop_back()
	small_pool.release_node(released_item)
	assert(small_pool.get_available_count() == 1, "Available count should be 1 after release")
	assert(small_pool.get_active_count() == 5, "Active count should be 5")

	var reacquired_item: Node = small_pool.acquire_node()
	assert(reacquired_item == released_item, "Reacquired node should be the previously released node")
	assert(small_pool.get_available_count() == 0, "Available count should be 0")
	assert(small_pool.get_active_count() == 6, "Active count back to 6")
	print("PASS: 3.3 Recycling recycled node at maximum capacity")

	# Clean up small pool
	small_pool.clear_pool()
	small_pool.queue_free()

	# ----------------------------------------------------
	# Test Group 4: Edge Cases, Safety & Reparenting Handling
	# ----------------------------------------------------
	print("\n[Group 4: Edge Cases, Safety & Reparenting Handling]")
	# Safety with null
	pool.release_node(null)
	assert(pool.get_active_count() == 0, "Releasing null should not alter active count")

	# Safety with alien node
	var alien_node: Node3D = Node3D.new()
	root.add_child(alien_node)
	pool.release_node(alien_node)
	assert(pool.get_available_count() == 20, "Releasing non-pool node should be ignored")
	alien_node.free()
	print("PASS: 4.1 Safe handling of null and non-pool nodes")

	# Reparenting active node into another scene tree branch
	var reparented_node: DummyPoolItem = pool.acquire_node() as DummyPoolItem
	assert(reparented_node.get_parent() == pool, "Node should initially be child of pool")

	var external_parent: Node3D = Node3D.new()
	root.add_child(external_parent)
	pool.remove_child(reparented_node)
	external_parent.add_child(reparented_node)
	assert(reparented_node.get_parent() == external_parent, "Node reparented to external parent")

	pool.release_node(reparented_node)
	assert(reparented_node.get_parent() == pool, "Released node must automatically reparent back to pool")
	assert(reparented_node.process_mode == Node.PROCESS_MODE_DISABLED, "Reparented node deactivated")
	assert(reparented_node.visible == false, "Reparented node hidden")
	external_parent.free()
	print("PASS: 4.2 Reparenting recovery on release")

	# Double release protection
	pool.release_node(reparented_node)
	assert(pool.get_available_count() == 20, "Double releasing node does not duplicate available pool")
	print("PASS: 4.3 Double release protection")

	# ----------------------------------------------------
	# Test Group 5: Stress Test (50 Operations Cycle)
	# ----------------------------------------------------
	print("\n[Group 5: Stress Test (50 Acquire/Release Operations)]")
	var stress_pool: NodePool = NodePool.new()
	stress_pool.initialize(dummy_scene, 10, 50)
	root.add_child(stress_pool)

	var active_pile: Array[Node] = []
	for cycle in range(50):
		# Randomly acquire or release
		var should_acquire: bool = active_pile.size() == 0 or (randf() > 0.4 and stress_pool.get_total_count() < 50)
		if should_acquire and stress_pool.get_total_count() < 50:
			var n: Node = stress_pool.acquire_node()
			if n != null:
				active_pile.append(n)
		elif active_pile.size() > 0:
			var n: Node = active_pile.pop_at(randi() % active_pile.size())
			stress_pool.release_node(n)

		# State invariance checks
		assert(stress_pool.get_active_count() == active_pile.size(), "Active count matches active pile size")
		assert(stress_pool.get_total_count() <= 50, "Total count never exceeds max_pool_size")
		assert(stress_pool.get_total_count() == stress_pool.get_available_count() + stress_pool.get_active_count(), "Count invariance holds")

	# Clean release of all remaining active
	while active_pile.size() > 0:
		var n: Node = active_pile.pop_back()
		stress_pool.release_node(n)

	assert(stress_pool.get_active_count() == 0, "Stress pool has 0 active nodes after full release")
	assert(stress_pool.get_available_count() == stress_pool.get_total_count(), "All total nodes are available")
	print("PASS: 5.1 50-cycle stress test completed with 100% count consistency")

	stress_pool.clear_pool()
	stress_pool.queue_free()
	pool.clear_pool()
	pool.queue_free()

	# ----------------------------------------------------
	# Test Group 6: Scene File Loading (res://tests/test_nodepool.tscn)
	# ----------------------------------------------------
	print("\n[Group 6: test_nodepool.tscn Scene Loading]")
	var scene_path: String = "res://tests/test_nodepool.tscn"
	assert(ResourceLoader.exists(scene_path), "test_nodepool.tscn must exist on disk")

	var scene_res: PackedScene = ResourceLoader.load(scene_path) as PackedScene
	assert(scene_res != null, "test_nodepool.tscn must load as PackedScene")

	var scene_instance: Node = scene_res.instantiate()
	root.add_child(scene_instance)

	var scene_pool: NodePool = scene_instance.get_node("NodePool") as NodePool
	assert(scene_pool != null, "Scene must contain child NodePool")
	assert(scene_pool.prefab_scene != null, "Scene NodePool must have prefab_scene configured")
	assert(scene_pool.initial_pool_size == 20, "Scene NodePool initial_pool_size == 20")
	assert(scene_pool.max_pool_size == 50, "Scene NodePool max_pool_size == 50")
	assert(scene_pool.get_available_count() == 20, "Scene NodePool ready initialized 20 nodes")

	var test_node: Node = scene_pool.acquire_node()
	assert(test_node != null, "Acquire from scene NodePool succeeded")
	assert(scene_pool.get_active_count() == 1, "Scene NodePool active count is 1")
	assert(scene_pool.get_available_count() == 19, "Scene NodePool available count is 19")

	scene_pool.release_node(test_node)
	assert(scene_pool.get_active_count() == 0, "Scene NodePool active count is 0")
	assert(scene_pool.get_available_count() == 20, "Scene NodePool available count is 20")
	print("PASS: 6.1 test_nodepool.tscn instantiated and exercised successfully")

	scene_instance.queue_free()

	print("\n========================================")
	print("=== ALL NODEPOOL UNIT TESTS PASSED (6/6 GROUPS) ===")
	print("========================================")
	quit(0)
