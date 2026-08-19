extends SceneTree

# ==============================================================================
# Unit & Validation Test Suite: Graybox Dungeon 3D Mesh & Structure (Task M5.1)
# ==============================================================================

const DungeonLevel = preload("res://src/world/dungeons/DungeonLevel.gd")
const PartyFormationController = preload("res://src/systems/PartyFormationController.gd")
const IsometricCameraRig = preload("res://src/world/IsometricCameraRig.gd")
const CharacterEntity = preload("res://src/entities/base/CharacterEntity.gd")

var _initialized: bool = false
var _scene_inst: DungeonLevel = null
var _frames_waited: int = 0


func _physics_process(_delta: float) -> bool:
	if not _initialized:
		_initialized = true
		_run_all_mesh_and_structure_tests()
		return false

	# Wait a couple frames for NavigationServer3D to sync maps and test pathfinding
	_frames_waited += 1
	if _frames_waited >= 5:
		_run_navigation_pathfinding_test()
		_conclude_tests()

	return false


func _run_all_mesh_and_structure_tests() -> void:
	print("================================================================================")
	print("--- Starting Graybox Dungeon 3D Mesh & Level Test Suite (Task M5.1) ---")
	print("================================================================================")

	# --------------------------------------------------------------------------
	# Test Group 1: Scene Resource & Root Node
	# --------------------------------------------------------------------------
	print("\n[Group 1: Scene Resource & Root DungeonLevel Node]")
	var scene_res: PackedScene = load("res://src/world/dungeons/GrayboxDungeon.tscn") as PackedScene
	assert(scene_res != null, "Scene res://src/world/dungeons/GrayboxDungeon.tscn must exist and load")

	var raw_inst: Node = scene_res.instantiate()
	assert(raw_inst != null, "GrayboxDungeon.tscn must instantiate")
	assert(raw_inst is DungeonLevel, "Root node must extend DungeonLevel")
	_scene_inst = raw_inst as DungeonLevel
	root.add_child(_scene_inst)

	# 1.1 Environment & Lighting
	var world_env: WorldEnvironment = _scene_inst.get_node_or_null("WorldEnvironment") as WorldEnvironment
	assert(world_env != null, "WorldEnvironment must exist in GrayboxDungeon")
	assert(world_env.environment != null, "Environment resource must be set on WorldEnvironment")

	var dir_light: DirectionalLight3D = _scene_inst.get_node_or_null("DirectionalLight3D") as DirectionalLight3D
	assert(dir_light != null, "DirectionalLight3D must exist in GrayboxDungeon")
	assert(dir_light.shadow_enabled, "DirectionalLight3D shadow must be enabled")
	print("PASS: 1.1 Root node, WorldEnvironment and DirectionalLight3D verified")

	# --------------------------------------------------------------------------
	# Test Group 2: NavigationRegion3D & NavigationMesh
	# --------------------------------------------------------------------------
	print("\n[Group 2: NavigationRegion3D & Baked NavigationMesh]")
	var nav_region: NavigationRegion3D = _scene_inst.get_navigation_region()
	assert(nav_region != null, "NavigationRegion3D must exist and be resolved by DungeonLevel")
	assert(nav_region.navigation_mesh != null, "NavigationMesh resource must be assigned to NavigationRegion3D")

	var nav_mesh: NavigationMesh = nav_region.navigation_mesh
	assert(is_equal_approx(nav_mesh.agent_radius, 0.4), "NavigationMesh agent_radius is ~0.4 (got: %f)" % nav_mesh.agent_radius)
	assert(is_equal_approx(nav_mesh.agent_height, 1.8), "NavigationMesh agent_height is ~1.8 (got: %f)" % nav_mesh.agent_height)
	assert(nav_mesh.get_polygon_count() > 0, "NavigationMesh must have baked polygons (got: %d)" % nav_mesh.get_polygon_count())
	assert(nav_mesh.get_vertices().size() > 0, "NavigationMesh must have baked vertices (got: %d)" % nav_mesh.get_vertices().size())
	print("PASS: 2.1 NavigationRegion3D and baked NavigationMesh validated (polygons: %d, vertices: %d)" % [nav_mesh.get_polygon_count(), nav_mesh.get_vertices().size()])

	# --------------------------------------------------------------------------
	# Test Group 3: Architecture & Rooms/Corridors Geometry
	# --------------------------------------------------------------------------
	print("\n[Group 3: Architecture, Rooms, Corridors & Physics Colliders]")
	var arch: StaticBody3D = _scene_inst.get_architecture()
	assert(arch != null, "Architecture StaticBody3D must exist and be resolved")
	assert(arch.collision_layer == 1, "Architecture must be on Physics Layer 1 (got: %d)" % arch.collision_layer)

	# 3.1 Room 0 (Spawn Seguro: ~12x12)
	var r0: Node3D = _scene_inst.get_room("Room0_Spawn")
	assert(r0 != null, "Room0_Spawn must exist inside Architecture")
	var r0_floor_col: CollisionShape3D = r0.get_node_or_null("Floor_Col") as CollisionShape3D
	assert(r0_floor_col != null, "Room0_Spawn must have Floor_Col")
	var r0_box: BoxShape3D = r0_floor_col.shape as BoxShape3D
	assert(r0_box != null, "Floor_Col must have BoxShape3D")
	assert(is_equal_approx(r0_box.size.x, 12.0) and is_equal_approx(r0_box.size.z, 12.0), "Room0 floor size is ~12x12 (got: %s)" % str(r0_box.size))

	# 3.2 Corridor 0_1 (Width >= 4.0m, Length >= 10.0m)
	var c01: Node3D = arch.get_node_or_null("Corridor_0_1") as Node3D
	assert(c01 != null, "Corridor_0_1 must exist inside Architecture")
	var c01_floor_col: CollisionShape3D = c01.get_node_or_null("Floor_Col") as CollisionShape3D
	assert(c01_floor_col != null, "Corridor_0_1 must have Floor_Col")
	var c01_box: BoxShape3D = c01_floor_col.shape as BoxShape3D
	assert(c01_box != null, "Corridor_0_1 Floor_Col must have BoxShape3D")
	assert(c01_box.size.x >= 4.0, "Corridor_0_1 width must be >= 4.0m (got: %.2fm)" % c01_box.size.x)
	assert(c01_box.size.z >= 10.0, "Corridor_0_1 length must be >= 10.0m (got: %.2fm)" % c01_box.size.z)

	# 3.3 Room 1 (Encontro Básico: ~16x16)
	var r1: Node3D = _scene_inst.get_room("Room1_Encounter")
	assert(r1 != null, "Room1_Encounter must exist inside Architecture")
	var r1_floor_col: CollisionShape3D = r1.get_node_or_null("Floor_Col") as CollisionShape3D
	assert(r1_floor_col != null, "Room1_Encounter must have Floor_Col")
	var r1_box: BoxShape3D = r1_floor_col.shape as BoxShape3D
	assert(r1_box != null, "Room1 Floor_Col must have BoxShape3D")
	assert(is_equal_approx(r1_box.size.x, 16.0) and is_equal_approx(r1_box.size.z, 16.0), "Room1 floor size is ~16x16 (got: %s)" % str(r1_box.size))

	# 3.4 Corridor 1_2 (Curved/Sinuous, Width >= 4.0m)
	var c12: Node3D = arch.get_node_or_null("Corridor_1_2") as Node3D
	assert(c12 != null, "Corridor_1_2 must exist inside Architecture")
	var c12_f1: CollisionShape3D = c12.get_node_or_null("Floor_Leg1_Col") as CollisionShape3D
	var c12_f2: CollisionShape3D = c12.get_node_or_null("Floor_Leg2_Col") as CollisionShape3D
	var c12_f3: CollisionShape3D = c12.get_node_or_null("Floor_Leg3_Col") as CollisionShape3D
	assert(c12_f1 != null and c12_f2 != null and c12_f3 != null, "Corridor_1_2 must have all sinuous legs (Floor_Leg1, Floor_Leg2, Floor_Leg3)")
	var b1: BoxShape3D = c12_f1.shape as BoxShape3D
	var b2: BoxShape3D = c12_f2.shape as BoxShape3D
	var b3: BoxShape3D = c12_f3.shape as BoxShape3D
	assert(b1.size.x >= 4.0, "Corridor_1_2 Leg 1 width >= 4.0m (got: %.2fm)" % b1.size.x)
	assert(b2.size.z >= 4.0, "Corridor_1_2 Leg 2 width >= 4.0m (got: %.2fm)" % b2.size.z)
	assert(b3.size.x >= 4.0, "Corridor_1_2 Leg 3 width >= 4.0m (got: %.2fm)" % b3.size.x)

	# 3.5 Room 2 (Mini-Boss: ~18x18)
	var r2: Node3D = _scene_inst.get_room("Room2_MiniBoss")
	assert(r2 != null, "Room2_MiniBoss must exist inside Architecture")
	var r2_floor_col: CollisionShape3D = r2.get_node_or_null("Floor_Col") as CollisionShape3D
	assert(r2_floor_col != null, "Room2_MiniBoss must have Floor_Col")
	var r2_box: BoxShape3D = r2_floor_col.shape as BoxShape3D
	assert(r2_box != null, "Room2 Floor_Col must have BoxShape3D")
	assert(is_equal_approx(r2_box.size.x, 18.0) and is_equal_approx(r2_box.size.z, 18.0), "Room2 floor size is ~18x18 (got: %s)" % str(r2_box.size))

	# 3.6 Arena 3 (Boss Arena: ~22x22 with entrance gate)
	var a3: Node3D = _scene_inst.get_room("Arena3_Boss")
	assert(a3 != null, "Arena3_Boss must exist inside Architecture")
	var a3_floor_col: CollisionShape3D = a3.get_node_or_null("Floor_Arena_Col") as CollisionShape3D
	assert(a3_floor_col != null, "Arena3_Boss must have Floor_Arena_Col")
	var a3_box: BoxShape3D = a3_floor_col.shape as BoxShape3D
	assert(a3_box != null, "Arena3 Floor_Arena_Col must have BoxShape3D")
	assert(is_equal_approx(a3_box.size.x, 22.0) and is_equal_approx(a3_box.size.z, 22.0), "Arena3 floor size is ~22x22 (got: %s)" % str(a3_box.size))

	# Check entrance vestibule and gate pillars
	assert(a3.get_node_or_null("Floor_Vestibule_Col") != null, "Arena3 must have Floor_Vestibule_Col")
	assert(a3.get_node_or_null("Gate_Pillar_Left_Col") != null, "Arena3 must have Gate_Pillar_Left_Col")
	assert(a3.get_node_or_null("Gate_Pillar_Right_Col") != null, "Arena3 must have Gate_Pillar_Right_Col")

	# 3.7 Rooms and Corridors count validation via API
	var rooms_list: Array[Node3D] = _scene_inst.get_rooms()
	var corridors_list: Array[Node3D] = _scene_inst.get_corridors()
	assert(rooms_list.size() == 4, "get_rooms() must return 4 rooms (Room0, Room1, Room2, Arena3) (got: %d)" % rooms_list.size())
	assert(corridors_list.size() == 2, "get_corridors() must return 2 corridors (Corridor_0_1, Corridor_1_2) (got: %d)" % corridors_list.size())
	print("PASS: 3.1 All rooms (0, 1, 2, Arena 3) and corridors (0_1, 1_2) verified with correct dimensions, widths >= 4.0m and Physics Layer 1")

	# --------------------------------------------------------------------------
	# Test Group 4: Spawners & Marker3Ds
	# --------------------------------------------------------------------------
	print("\n[Group 4: Spawners & Marker3Ds]")
	var spawners: Node3D = _scene_inst.get_node_or_null("Spawners") as Node3D
	assert(spawners != null, "Spawners node must exist")

	var party_spawn: Marker3D = _scene_inst.get_party_spawn_marker()
	assert(party_spawn != null, "PartySpawnPoint Marker3D must exist")
	assert(_scene_inst.get_spawn_point().is_equal_approx(Vector3(0.0, 0.0, 0.0)), "Party spawn position is at origin")

	var r1_spawners: Array[Marker3D] = _scene_inst.get_enemy_spawners_for_room(1)
	assert(r1_spawners.size() == 3, "Room 1 must have 3 enemy spawn markers (got: %d)" % r1_spawners.size())

	var r2_spawners: Array[Marker3D] = _scene_inst.get_enemy_spawners_for_room(2)
	assert(r2_spawners.size() == 2, "Room 2 must have 2 enemy spawn markers (Captain + Healer) (got: %d)" % r2_spawners.size())

	var r3_spawners: Array[Marker3D] = _scene_inst.get_enemy_spawners_for_room(3)
	assert(r3_spawners.size() == 3, "Arena 3 must have 3 markers (Boss, Chest, Portal) (got: %d)" % r3_spawners.size())
	print("PASS: 4.1 All Spawners (Party, Room1 pack, Room2 miniboss pack, Arena3 boss pack) verified")

	# --------------------------------------------------------------------------
	# Test Group 5: EncounterControllers
	# --------------------------------------------------------------------------
	print("\n[Group 5: EncounterControllers]")
	var enc_holder: Node3D = _scene_inst.get_node_or_null("EncounterControllers") as Node3D
	assert(enc_holder != null, "EncounterControllers node must exist")

	var r1_ctrl: Node = _scene_inst.get_encounter_controller(1)
	assert(r1_ctrl != null, "Room1_Controller must exist")

	var r2_ctrl: Node = _scene_inst.get_encounter_controller(2)
	assert(r2_ctrl != null, "Room2_Controller must exist")
	print("PASS: 5.1 Room Encounter Controllers verified")

	# --------------------------------------------------------------------------
	# Test Group 6: Waypoints & Sequential Progression
	# --------------------------------------------------------------------------
	print("\n[Group 6: Waypoints & Sequential Path]")
	var waypoints: Array[Vector3] = _scene_inst.get_waypoints()
	assert(waypoints.size() == 8, "Waypoints must contain 8 markers along the full dungeon route (got: %d)" % waypoints.size())

	assert(waypoints[0].is_equal_approx(Vector3(0.0, 0.0, 0.0)), "Waypoint_0 at Room 0 Spawn")
	assert(waypoints[1].is_equal_approx(Vector3(0.0, 0.0, 12.0)), "Waypoint_1 in Corridor 0_1")
	assert(waypoints[2].is_equal_approx(Vector3(0.0, 0.0, 26.0)), "Waypoint_2 in Room 1")
	assert(waypoints[3].is_equal_approx(Vector3(0.0, 0.0, 41.5)), "Waypoint_3 at Corridor 1_2 Turn 1")
	assert(waypoints[4].is_equal_approx(Vector3(16.0, 0.0, 41.5)), "Waypoint_4 at Corridor 1_2 Turn 2")
	assert(waypoints[5].is_equal_approx(Vector3(16.0, 0.0, 61.0)), "Waypoint_5 in Room 2")
	assert(waypoints[6].is_equal_approx(Vector3(16.0, 0.0, 74.0)), "Waypoint_6 at Arena 3 Gate")
	assert(waypoints[7].is_equal_approx(Vector3(16.0, 0.0, 89.0)), "Waypoint_7 in Arena 3 Center")
	print("PASS: 6.1 All 8 traversal waypoints verified along the complete dungeon route")

	# --------------------------------------------------------------------------
	# Test Group 7: PartyFormationController & IsometricCameraRig
	# --------------------------------------------------------------------------
	print("\n[Group 7: PartyFormationController & IsometricCameraRig]")
	var party_ctrl: PartyFormationController = _scene_inst.party_controller
	assert(party_ctrl != null, "PartyFormationController must exist and be bound")

	var leader: CharacterEntity = party_ctrl.get_leader()
	var support: CharacterEntity = party_ctrl.get_support()
	var dps: CharacterEntity = party_ctrl.get_dps()

	assert(leader != null, "Leader hero must exist")
	assert(support != null, "Support hero must exist")
	assert(dps != null, "DPS hero must exist")

	assert(leader.hero_data != null and leader.hero_data.hero_id == "bromm", "Bromm hero_data injected")
	assert(support.hero_data != null and support.hero_data.hero_id == "beatrice", "Beatrice hero_data injected")
	assert(dps.hero_data != null and dps.hero_data.hero_id == "elysia", "Elysia hero_data injected")

	var cam_rig: IsometricCameraRig = _scene_inst.camera_rig
	assert(cam_rig != null, "IsometricCameraRig must exist and be bound")
	assert(cam_rig.target == leader, "CameraRig target must be leader hero")
	print("PASS: 7.1 PartyFormationController and IsometricCameraRig verified")


func _run_navigation_pathfinding_test() -> void:
	print("\n[Group 8: NavigationServer3D Continuous Pathfinding Query]")
	var nav_region: NavigationRegion3D = _scene_inst.get_navigation_region()
	var nav_map: RID = nav_region.get_navigation_map()

	var start_pt: Vector3 = Vector3(0.0, 0.0, 0.0)      # Room 0
	var room1_pt: Vector3 = Vector3(0.0, 0.0, 26.0)     # Room 1
	var room2_pt: Vector3 = Vector3(16.0, 0.0, 61.0)    # Room 2
	var arena3_pt: Vector3 = Vector3(16.0, 0.0, 89.0)   # Arena 3

	var path_0_to_1: PackedVector3Array = NavigationServer3D.map_get_path(nav_map, start_pt, room1_pt, true)
	var path_1_to_2: PackedVector3Array = NavigationServer3D.map_get_path(nav_map, room1_pt, room2_pt, true)
	var path_2_to_3: PackedVector3Array = NavigationServer3D.map_get_path(nav_map, room2_pt, arena3_pt, true)
	var path_full: PackedVector3Array = NavigationServer3D.map_get_path(nav_map, start_pt, arena3_pt, true)

	print("Path from Room0 to Room1 point count: %d" % path_0_to_1.size())
	print("Path from Room1 to Room2 point count: %d" % path_1_to_2.size())
	print("Path from Room2 to Arena3 point count: %d" % path_2_to_3.size())
	print("Full Path from Room0 to Arena3 point count: %d" % path_full.size())

	assert(path_0_to_1.size() >= 2, "Path from Room 0 to Room 1 must have at least 2 points")
	assert(path_1_to_2.size() >= 2, "Path from Room 1 to Room 2 must have at least 2 points")
	assert(path_2_to_3.size() >= 2, "Path from Room 2 to Arena 3 must have at least 2 points")
	assert(path_full.size() >= 4, "Full continuous path from Room 0 to Arena 3 must have at least 4 points")
	print("PASS: 8.1 Continuous 3D pathfinding verified from Room 0 through all corridors to Arena 3")


func _conclude_tests() -> void:
	print("\n================================================================================")
	print("=== ALL GRAYBOX DUNGEON 3D MESH & STRUCTURE TESTS PASSED (8/8 GROUPS) ===")
	print("================================================================================")
	quit(0)
