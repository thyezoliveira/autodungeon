extends SceneTree

# ==============================================================================
# Unit & Integration Test Suite: 3D Party Navigation & Traversal (Task M3.5)
# ==============================================================================

var _initialized: bool = false
var _phase: int = 0

var _scene_inst: Node3D = null
var _party_ctrl: PartyFormationController = null
var _camera_rig: IsometricCameraRig = null
var _nav_region: NavigationRegion3D = null
var _waypoints_holder: Node3D = null
var _leader: CharacterEntity = null
var _support: CharacterEntity = null
var _dps: CharacterEntity = null

var _waypoints: Array[Vector3] = []
var _target_wp_index: int = 0
var _frames_in_phase: int = 0
var _total_physics_frames: int = 0
var _max_frames_per_waypoint: int = 300
var _settling_frames: int = 0

var _max_support_dist_overall: float = 0.0
var _max_dps_dist_overall: float = 0.0
var _waypoints_reached: Array[int] = []


func _physics_process(_delta: float) -> bool:
	if not _initialized:
		_initialized = true
		_run_static_and_structural_tests()
		_start_dynamic_traversal()
		return false

	if _phase == 1:
		_total_physics_frames += 1
		_frames_in_phase += 1

		var leader_pos: Vector3 = _leader.global_position
		var supp_dist: float = Vector2(_support.global_position.x - leader_pos.x, _support.global_position.z - leader_pos.z).length()
		var dps_dist: float = Vector2(_dps.global_position.x - leader_pos.x, _dps.global_position.z - leader_pos.z).length()

		if supp_dist > _max_support_dist_overall:
			_max_support_dist_overall = supp_dist
		if dps_dist > _max_dps_dist_overall:
			_max_dps_dist_overall = dps_dist

		if _target_wp_index < _waypoints.size():
			var target_pos: Vector3 = _waypoints[_target_wp_index]
			var dist_to_wp: float = Vector2(leader_pos.x - target_pos.x, leader_pos.z - target_pos.z).length()

			if dist_to_wp <= 0.6:
				var reached_num: int = _target_wp_index + 1
				_waypoints_reached.append(reached_num)
				print("PASS: Group %d - Reached Waypoint_%d at %s (frame %d, supp_dist: %.2fm, dps_dist: %.2fm)" % [
					reached_num + 2,
					reached_num,
					str(leader_pos),
					_total_physics_frames,
					supp_dist,
					dps_dist
				])

				# Validate cohesion at this waypoint
				assert(supp_dist <= 3.0, "Support must be within 3.0m cohesion radius at Waypoint_%d" % reached_num)
				assert(dps_dist <= 3.0, "DPS must be within 3.0m cohesion radius at Waypoint_%d" % reached_num)

				_target_wp_index += 1
				_frames_in_phase = 0

				if _target_wp_index < _waypoints.size():
					_leader.movement_component.move_towards(_waypoints[_target_wp_index])
				else:
					# All waypoints reached, enter settling phase
					_phase = 2
					_leader.state_machine.change_state("IdleState")
					_support.state_machine.change_state("IdleState")
					_dps.state_machine.change_state("IdleState")
			elif _frames_in_phase >= _max_frames_per_waypoint:
				print("ERROR: Timeout attempting to reach Waypoint_%d at %s (current pos: %s)" % [_target_wp_index + 1, str(target_pos), str(leader_pos)])
				assert(false, "Timeout attempting to reach waypoint")
				quit(1)

		return false

	if _phase == 2:
		_total_physics_frames += 1
		_settling_frames += 1
		if _settling_frames >= 30:
			_phase = 3
			_run_final_assertions()

	return false


func _run_static_and_structural_tests() -> void:
	print("================================================================================")
	print("--- Starting 3D Party Navigation & Traversal Test Suite (Task M3.5) ---")
	print("================================================================================")

	# --------------------------------------------------------------------------
	# Test Group 1: Scene Hierarchy, Nodes & Resources Validation
	# --------------------------------------------------------------------------
	print("\n[Group 1: Scene Hierarchy, Nodes & Resources Validation]")
	var scene_res: PackedScene = load("res://tests/test_party_navigation_3d.tscn") as PackedScene
	assert(scene_res != null, "Scene res://tests/test_party_navigation_3d.tscn must exist and load")

	_scene_inst = scene_res.instantiate() as Node3D
	assert(_scene_inst != null, "test_party_navigation_3d.tscn must instantiate")
	root.add_child(_scene_inst)

	# 1.1 WorldEnvironment & Lighting
	var world_env: WorldEnvironment = _scene_inst.get_node_or_null("WorldEnvironment") as WorldEnvironment
	assert(world_env != null, "WorldEnvironment must exist in scene")
	assert(world_env.environment != null, "Environment resource must be assigned to WorldEnvironment")

	var dir_light: DirectionalLight3D = _scene_inst.get_node_or_null("DirectionalLight3D") as DirectionalLight3D
	assert(dir_light != null, "DirectionalLight3D must exist in scene")

	# 1.2 NavigationRegion3D & NavigationMesh configuration
	_nav_region = _scene_inst.get_node_or_null("NavigationRegion3D") as NavigationRegion3D
	assert(_nav_region != null, "NavigationRegion3D must exist in scene")
	assert(_nav_region.navigation_mesh != null, "NavigationMesh must be assigned to NavigationRegion3D")

	var nav_mesh: NavigationMesh = _nav_region.navigation_mesh
	assert(is_equal_approx(nav_mesh.agent_radius, 0.4), "NavigationMesh agent_radius configured to ~0.4 (got: %f)" % nav_mesh.agent_radius)
	assert(is_equal_approx(nav_mesh.agent_height, 1.8), "NavigationMesh agent_height configured to ~1.8 (got: %f)" % nav_mesh.agent_height)
	assert(nav_mesh.get_polygon_count() > 0, "NavigationMesh must have baked polygons (polygon count: %d)" % nav_mesh.get_polygon_count())
	assert(nav_mesh.get_vertices().size() > 0, "NavigationMesh must have baked vertices (vertex count: %d)" % nav_mesh.get_vertices().size())

	# 1.3 CorridorGeometry
	var corridor: StaticBody3D = _nav_region.get_node_or_null("CorridorGeometry") as StaticBody3D
	assert(corridor != null, "CorridorGeometry StaticBody3D must exist inside NavigationRegion3D")
	assert(corridor.get_child_count() > 0, "CorridorGeometry must contain collision shapes and mesh instances")

	# 1.4 WaypointsHolder & Waypoint Markers
	_waypoints_holder = _scene_inst.get_node_or_null("WaypointsHolder") as Node3D
	assert(_waypoints_holder != null, "WaypointsHolder Node3D must exist in scene")

	var wp0: Marker3D = _waypoints_holder.get_node_or_null("Waypoint_0") as Marker3D
	var wp1: Marker3D = _waypoints_holder.get_node_or_null("Waypoint_1") as Marker3D
	var wp2: Marker3D = _waypoints_holder.get_node_or_null("Waypoint_2") as Marker3D
	var wp3: Marker3D = _waypoints_holder.get_node_or_null("Waypoint_3") as Marker3D

	assert(wp0 != null, "Waypoint_0 Marker3D must exist")
	assert(wp1 != null, "Waypoint_1 Marker3D must exist")
	assert(wp2 != null, "Waypoint_2 Marker3D must exist")
	assert(wp3 != null, "Waypoint_3 Marker3D must exist")

	assert(wp0.position.is_equal_approx(Vector3(0.0, 0.0, 0.0)), "Waypoint_0 at start position (0, 0, 0)")
	assert(wp1.position.is_equal_approx(Vector3(0.0, 0.0, 12.0)), "Waypoint_1 at first turn (0, 0, 12)")
	assert(wp2.position.is_equal_approx(Vector3(12.0, 0.0, 12.0)), "Waypoint_2 at second turn (12, 0, 12)")
	assert(wp3.position.is_equal_approx(Vector3(12.0, 0.0, 0.0)), "Waypoint_3 at final destination (12, 0, 0)")

	# 1.5 PartyFormationController & 3 Hero Entities
	_party_ctrl = _scene_inst.get_node_or_null("PartyFormationController") as PartyFormationController
	assert(_party_ctrl != null, "PartyFormationController must exist in scene")

	_leader = _party_ctrl.get_leader()
	_support = _party_ctrl.get_support()
	_dps = _party_ctrl.get_dps()

	assert(_leader != null, "Hero_Bromm leader must be resolved")
	assert(_support != null, "Hero_Beatrice support must be resolved")
	assert(_dps != null, "Hero_Elysia DPS must be resolved")

	assert(_leader.hero_data != null, "Bromm hero_data must be injected")
	assert(_support.hero_data != null, "Beatrice hero_data must be injected")
	assert(_dps.hero_data != null, "Elysia hero_data must be injected")

	assert(_leader.hero_data.hero_id == "bromm", "Bromm hero_id is 'bromm'")
	assert(_support.hero_data.hero_id == "beatrice", "Beatrice hero_id is 'beatrice'")
	assert(_dps.hero_data.hero_id == "elysia", "Elysia hero_id is 'elysia'")

	# 1.6 IsometricCameraRig
	_camera_rig = _scene_inst.get_node_or_null("IsometricCameraRig") as IsometricCameraRig
	assert(_camera_rig != null, "IsometricCameraRig must exist in scene")
	assert(_camera_rig.target == _leader, "IsometricCameraRig target must be configured to follow leader Bromm")

	print("PASS: 1.1 Complete scene graph, NavMesh, geometry, waypoints, heroes and camera rig verified")

	# --------------------------------------------------------------------------
	# Test Group 2: Initial Tactical Wedge Formation & Tethering State
	# --------------------------------------------------------------------------
	print("\n[Group 2: Initial Tactical Wedge Formation & Tethering State]")
	assert(_leader.global_position.is_equal_approx(Vector3(0.0, 0.0, 0.0)), "Leader starts at origin (0, 0, 0)")
	assert(_support.global_position.is_equal_approx(Vector3(1.2, 0.0, 1.2)), "Support starts at right flank offset (1.2, 0, 1.2)")
	assert(_dps.global_position.is_equal_approx(Vector3(-1.2, 0.0, 1.8)), "DPS starts at rear left flank offset (-1.2, 0, 1.8)")

	var init_status: Dictionary = _party_ctrl.get_tether_status()
	assert(init_status["alive_followers_count"] == 2, "2 alive followers detected")
	assert(init_status["max_distance"] <= 3.0, "Initial follower distance is within 3.0m tether limit (dist: %.2fm)" % init_status["max_distance"])
	assert(init_status["leader_speed_multiplier"] == 1.0, "Leader starts at 1.0x standard speed")
	print("PASS: 2.1 Initial tactical wedge formation and tethering limits verified")


func _start_dynamic_traversal() -> void:
	print("\n[Group 3: Autonomous Traversal — Waypoint_0 -> Waypoint_1 (+Z Straight March)]")
	var wp1: Marker3D = _waypoints_holder.get_node("Waypoint_1") as Marker3D
	var wp2: Marker3D = _waypoints_holder.get_node("Waypoint_2") as Marker3D
	var wp3: Marker3D = _waypoints_holder.get_node("Waypoint_3") as Marker3D

	_waypoints = [wp1.global_position, wp2.global_position, wp3.global_position]
	_target_wp_index = 0
	_frames_in_phase = 0
	_total_physics_frames = 0
	_waypoints_reached.clear()
	_phase = 1

	# Transition trio to MarchState
	_leader.state_machine.change_state("MarchState")
	_support.state_machine.change_state("MarchState")
	_dps.state_machine.change_state("MarchState")

	assert(_leader.state_machine.get_current_state_name() == "MarchState", "Leader in MarchState")
	assert(_support.state_machine.get_current_state_name() == "MarchState", "Support in MarchState")
	assert(_dps.state_machine.get_current_state_name() == "MarchState", "DPS in MarchState")

	_leader.movement_component.move_towards(_waypoints[0])


func _run_final_assertions() -> void:
	# --------------------------------------------------------------------------
	# Test Group 6: Full Traversal Evaluation, Cohesion Bounds & Camera Convergence
	# --------------------------------------------------------------------------
	print("\n[Group 6: Full Traversal Evaluation, Cohesion Bounds & Camera Convergence]")
	print("Total Physics Frames: %d" % _total_physics_frames)
	print("Waypoints Successfully Reached: %s" % str(_waypoints_reached))
	print("Max Overall Support Distance: %.2fm (threshold <= 3.0m)" % _max_support_dist_overall)
	print("Max Overall DPS Distance: %.2fm (threshold <= 3.0m)" % _max_dps_dist_overall)
	print("Final Leader Pos: %s" % str(_leader.global_position))
	print("Final Support Pos: %s" % str(_support.global_position))
	print("Final DPS Pos: %s" % str(_dps.global_position))
	print("Final Camera Pos: %s" % str(_camera_rig.global_position))

	# 6.1 All waypoints reached
	assert(_waypoints_reached.size() == 3, "All 3 traversal waypoints (1, 2, 3) reached in sequence")
	assert(_waypoints_reached == [1, 2, 3], "Waypoints traversed in strict sequential order [1, 2, 3]")

	# 6.2 Formation cohesion preserved
	assert(_max_support_dist_overall <= 3.0, "Support maintained cohesion throughout entire route (max: %.2fm <= 3.0m)" % _max_support_dist_overall)
	assert(_max_dps_dist_overall <= 3.0, "DPS maintained cohesion throughout entire route (max: %.2fm <= 3.0m)" % _max_dps_dist_overall)

	# 6.3 Camera tracking and convergence
	var expected_cam_pos: Vector3 = Vector3(_leader.global_position.x, 0.0, _leader.global_position.z) + _camera_rig.camera_offset
	var cam_diff: float = (_camera_rig.global_position - expected_cam_pos).length()
	print("Camera tracking deviation after settling: %.3fm" % cam_diff)
	assert(cam_diff <= 0.2, "Camera rig smoothly converged to leader position + offset (diff: %.3fm <= 0.2m)" % cam_diff)

	# 6.4 Clean stop in IdleState
	assert(_leader.state_machine.get_current_state_name() == "IdleState", "Leader settled in IdleState")
	assert(_support.state_machine.get_current_state_name() == "IdleState", "Support settled in IdleState")
	assert(_dps.state_machine.get_current_state_name() == "IdleState", "DPS settled in IdleState")

	print("PASS: 6.1 Full sequential autonomous traversal, tactical formation cohesion, and camera tracking validated!")

	print("\n================================================================================")
	print("=== ALL 3D PARTY NAVIGATION & TRAVERSAL TESTS PASSED (6/6 GROUPS) ===")
	print("================================================================================")
	quit(0)
