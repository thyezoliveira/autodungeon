extends SceneTree

# ==============================================================================
# Unit & Integration Test Suite: Party Role Reassignment on Hero Death (Task M3.6)
# ==============================================================================

var _initialized: bool = false
var _sim_phase: int = 0 # 0: unstarted, 1: march with Bromm, 2: march with Beatrice, 3: march with Elysia, 4: settling, 5: finished

var _scene_inst: Node3D = null
var _party_ctrl: PartyFormationController = null
var _camera_rig: IsometricCameraRig = null
var _nav_region: NavigationRegion3D = null
var _waypoints_holder: Node3D = null

var _bromm: CharacterEntity = null
var _beatrice: CharacterEntity = null
var _elysia: CharacterEntity = null

var _waypoints: Array[Vector3] = []
var _target_wp_index: int = 0
var _frames_in_phase: int = 0
var _total_physics_frames: int = 0
var _settling_frames: int = 0
var _max_frames_per_segment: int = 400

var _bromm_death_pos: Vector3 = Vector3.ZERO
var _beatrice_death_pos: Vector3 = Vector3.ZERO
var _waypoints_reached_by_alive_leaders: Array[Dictionary] = []


func _physics_process(_delta: float) -> bool:
	if not _initialized:
		_initialized = true
		_run_unit_and_logic_tests()
		_setup_live_navigation_scene()
		return false

	if _sim_phase == 1:
		# ----------------------------------------------------------------------
		# Live Sim Phase 1: Bromm leads trio towards WP1 (0, 0, 12).
		# Partway through (+Z march, frame 40), Bromm suffers lethal damage.
		# ----------------------------------------------------------------------
		_total_physics_frames += 1
		_frames_in_phase += 1

		if _frames_in_phase == 40:
			print("\n--- Triggering Lethal Damage on Leader Bromm (Frame %d) ---" % _total_physics_frames)
			_bromm_death_pos = _bromm.global_position
			_bromm.health_component.take_damage(999)

			# Assertions immediately after death
			assert(_bromm.health_component.current_hp == 0, "Bromm HP reduced to 0")
			assert(_bromm.health_component.is_alive == false, "Bromm marked not alive")
			assert(_bromm.state_machine.get_current_state_name() == "DeadState", "Bromm transitioned to DeadState")
			assert(_bromm.velocity.length() < 0.001, "Bromm velocity zeroed in DeadState")

			# PartyFormationController updates
			assert(_party_ctrl.get_leader() == _beatrice, "Beatrice automatically promoted to Leader")
			assert(_party_ctrl.get_support() == null, "Support slot cleared")
			assert(_party_ctrl.get_dps() == _elysia, "Elysia remains as DPS follower")
			assert(_party_ctrl.get_alive_heroes().size() == 2, "2 alive heroes remaining")

			# IsometricCameraRig update
			assert(_camera_rig.target == _beatrice, "Camera rig target automatically refocused on new leader Beatrice")

			# Direct Beatrice towards pending Waypoint_1
			_beatrice.movement_component.move_towards(_waypoints[_target_wp_index])
			_sim_phase = 2
			_frames_in_phase = 0
			print("PASS: Phase 1 -> Bromm dead in DeadState, Beatrice promoted to Leader, Camera target updated")
			return false

		return false

	if _sim_phase == 2:
		# ----------------------------------------------------------------------
		# Live Sim Phase 2: Beatrice leads duo (Beatrice + Elysia).
		# Traverses to WP1, turns to WP2 (12, 0, 12).
		# Partway to WP2 (after reaching WP1, frame 35), Beatrice suffers lethal damage.
		# ----------------------------------------------------------------------
		_total_physics_frames += 1
		_frames_in_phase += 1

		# Verify Bromm stays stationary at death position
		assert((_bromm.global_position - _bromm_death_pos).length() < 0.05, "Bromm remains static at death coordinates")
		assert(_bromm.velocity.length() < 0.001, "Bromm remains at zero velocity")

		var leader_pos: Vector3 = _beatrice.global_position
		var target_pos: Vector3 = _waypoints[_target_wp_index]
		var dist_to_wp: float = Vector2(leader_pos.x - target_pos.x, leader_pos.z - target_pos.z).length()

		# Check Elysia follower offset to Beatrice
		var elysia_dist_to_beatrice: float = Vector2(_elysia.global_position.x - leader_pos.x, _elysia.global_position.z - leader_pos.z).length()
		assert(elysia_dist_to_beatrice <= 3.0, "Elysia maintains cohesion with Beatrice (dist: %.2fm <= 3.0m)" % elysia_dist_to_beatrice)

		if _target_wp_index == 0 and dist_to_wp <= 0.6:
			# WP1 reached by Beatrice!
			print("PASS: Beatrice reached Waypoint_1 at %s (frame %d, Elysia dist: %.2fm)" % [str(leader_pos), _total_physics_frames, elysia_dist_to_beatrice])
			_waypoints_reached_by_alive_leaders.append({"wp": 1, "leader": "beatrice", "frame": _total_physics_frames})
			_target_wp_index = 1
			_beatrice.movement_component.move_towards(_waypoints[_target_wp_index])
			_frames_in_phase = 0
			return false

		if _target_wp_index == 1 and _frames_in_phase >= 35:
			# Partway to WP2, Beatrice takes lethal damage
			print("\n--- Triggering Lethal Damage on Second Leader Beatrice (Frame %d) ---" % _total_physics_frames)
			_beatrice_death_pos = _beatrice.global_position
			_beatrice.health_component.take_damage(999)

			# Assertions immediately after second leader death
			assert(_beatrice.health_component.current_hp == 0, "Beatrice HP reduced to 0")
			assert(_beatrice.health_component.is_alive == false, "Beatrice marked not alive")
			assert(_beatrice.state_machine.get_current_state_name() == "DeadState", "Beatrice transitioned to DeadState")
			assert(_beatrice.velocity.length() < 0.001, "Beatrice velocity zeroed in DeadState")

			# PartyFormationController updates
			assert(_party_ctrl.get_leader() == _elysia, "Elysia automatically promoted to Leader")
			assert(_party_ctrl.get_support() == null, "Support slot remains null")
			assert(_party_ctrl.get_dps() == null, "DPS slot cleared after promotion")
			assert(_party_ctrl.get_alive_heroes().size() == 1, "Only 1 alive hero remaining (Elysia)")

			var tether_stat: Dictionary = _party_ctrl.get_tether_status()
			assert(tether_stat["alive_followers_count"] == 0, "0 alive followers for solo leader")
			assert(tether_stat["zone"] == "ideal", "Solo leader is in ideal tether zone")
			assert(tether_stat["leader_speed_multiplier"] == 1.0, "Solo leader marches at 1.0x speed")

			# IsometricCameraRig update
			assert(_camera_rig.target == _elysia, "Camera rig target automatically refocused on solo leader Elysia")

			# Direct Elysia towards pending Waypoint_2
			_elysia.movement_component.move_towards(_waypoints[_target_wp_index])
			_sim_phase = 3
			_frames_in_phase = 0
			print("PASS: Phase 2 -> Beatrice dead in DeadState, Elysia promoted to Solo Leader, Camera target updated")
			return false

		if _frames_in_phase >= _max_frames_per_segment:
			print("ERROR: Timeout during Beatrice leadership segment")
			assert(false, "Timeout during Beatrice leadership segment")
			quit(1)

		return false

	if _sim_phase == 3:
		# ----------------------------------------------------------------------
		# Live Sim Phase 3: Elysia marches solo towards WP2 then WP3 (12, 0, 0).
		# ----------------------------------------------------------------------
		_total_physics_frames += 1
		_frames_in_phase += 1

		# Verify Bromm and Beatrice stay stationary at their death positions
		assert((_bromm.global_position - _bromm_death_pos).length() < 0.05, "Bromm remains static at death coordinates")
		assert((_beatrice.global_position - _beatrice_death_pos).length() < 0.05, "Beatrice remains static at death coordinates")

		var elysia_pos: Vector3 = _elysia.global_position
		var target_pos: Vector3 = _waypoints[_target_wp_index]
		var dist_to_wp: float = Vector2(elysia_pos.x - target_pos.x, elysia_pos.z - target_pos.z).length()

		if dist_to_wp <= 0.6:
			var wp_num: int = _target_wp_index + 1
			print("PASS: Solo Elysia reached Waypoint_%d at %s (frame %d)" % [wp_num, str(elysia_pos), _total_physics_frames])
			_waypoints_reached_by_alive_leaders.append({"wp": wp_num, "leader": "elysia", "frame": _total_physics_frames})

			_target_wp_index += 1
			_frames_in_phase = 0

			if _target_wp_index < _waypoints.size():
				_elysia.movement_component.move_towards(_waypoints[_target_wp_index])
			else:
				# Final destination reached!
				print("\n--- Final Destination Reached by Solo Survivor Elysia! ---")
				_elysia.state_machine.change_state("IdleState")
				_sim_phase = 4
				_settling_frames = 0

		elif _frames_in_phase >= _max_frames_per_segment:
			print("ERROR: Timeout during Elysia solo segment for WP%d" % (_target_wp_index + 1))
			assert(false, "Timeout during Elysia solo segment")
			quit(1)

		return false

	if _sim_phase == 4:
		# ----------------------------------------------------------------------
		# Live Sim Phase 4: Settling & Camera Rig Smooth Convergence
		# ----------------------------------------------------------------------
		_total_physics_frames += 1
		_settling_frames += 1

		if _settling_frames >= 30:
			_sim_phase = 5
			_run_live_sim_final_assertions()

		return false

	return false


# ==============================================================================
# Unit & Logical Tests (Group 1 - 4)
# ==============================================================================

func _run_unit_and_logic_tests() -> void:
	print("================================================================================")
	print("--- Starting Party Role Reassignment Unit Tests (Task M3.6) ---")
	print("================================================================================")

	# --------------------------------------------------------------------------
	# Test Group 1: Priority Promotion Order & EventBus Integration
	# --------------------------------------------------------------------------
	print("\n[Group 1: Priority Promotion Order & EventBus Integration]")
	var ctrl: PartyFormationController = PartyFormationController.new()
	root.add_child(ctrl)

	var h_bromm: CharacterEntity = CharacterEntity.new()
	var h_beatrice: CharacterEntity = CharacterEntity.new()
	var h_elysia: CharacterEntity = CharacterEntity.new()
	root.add_child(h_bromm)
	root.add_child(h_beatrice)
	root.add_child(h_elysia)

	var hp_bromm: HealthComponent = HealthComponent.new()
	var hp_beatrice: HealthComponent = HealthComponent.new()
	var hp_comp_elysia: HealthComponent = HealthComponent.new()

	h_bromm.add_child(hp_bromm)
	h_bromm.health_component = hp_bromm
	h_beatrice.add_child(hp_beatrice)
	h_beatrice.health_component = hp_beatrice
	h_elysia.add_child(hp_comp_elysia)
	h_elysia.health_component = hp_comp_elysia

	ctrl.set_party_members(h_bromm, h_beatrice, h_elysia)

	var leader_history: Array[CharacterEntity] = []
	ctrl.leader_changed.connect(func(new_l: CharacterEntity) -> void:
		leader_history.append(new_l)
	)

	# 1.1 Initial check
	assert(ctrl.get_leader() == h_bromm, "Initial leader is Bromm")
	assert(ctrl.get_support() == h_beatrice, "Initial support is Beatrice")
	assert(ctrl.get_dps() == h_elysia, "Initial DPS is Elysia")

	# 1.2 Bromm dies -> Beatrice promoted to Leader
	hp_bromm.is_alive = false
	hp_bromm.current_hp = 0
	ctrl.reassign_roles_on_hero_death(h_bromm)

	assert(ctrl.get_leader() == h_beatrice, "Beatrice promoted to leader")
	assert(ctrl.get_support() == null, "Support slot is null after promotion")
	assert(ctrl.get_dps() == h_elysia, "DPS slot remains Elysia")
	assert(leader_history.size() == 1, "leader_changed emitted once")
	assert(leader_history[0] == h_beatrice, "leader_changed payload is Beatrice")

	# 1.3 Beatrice dies -> Elysia promoted to Leader
	hp_beatrice.is_alive = false
	hp_beatrice.current_hp = 0
	ctrl.reassign_roles_on_hero_death(h_beatrice)

	assert(ctrl.get_leader() == h_elysia, "Elysia promoted to leader")
	assert(ctrl.get_support() == null, "Support slot is null")
	assert(ctrl.get_dps() == null, "DPS slot cleared after Elysia promotion")
	assert(leader_history.size() == 2, "leader_changed emitted twice")
	assert(leader_history[1] == h_elysia, "leader_changed payload is Elysia")

	# 1.4 Elysia dies -> All dead, leader is null
	hp_comp_elysia.is_alive = false
	hp_comp_elysia.current_hp = 0
	ctrl.reassign_roles_on_hero_death(h_elysia)

	assert(ctrl.get_leader() == null, "Leader is null when all members dead")
	assert(leader_history.size() == 3, "leader_changed emitted third time")
	assert(leader_history[2] == null, "leader_changed payload is null")

	print("PASS: 1.1 Full sequential leadership promotion chain (Bromm -> Beatrice -> Elysia -> null) validated")

	ctrl.queue_free()
	h_bromm.queue_free()
	h_beatrice.queue_free()
	h_elysia.queue_free()

	# --------------------------------------------------------------------------
	# Test Group 2: Dead Follower Handled Before Leader Death
	# --------------------------------------------------------------------------
	print("\n[Group 2: Dead Follower Handled Before Leader Death]")
	var ctrl_2: PartyFormationController = PartyFormationController.new()
	root.add_child(ctrl_2)

	var lead_2: CharacterEntity = CharacterEntity.new()
	var supp_2: CharacterEntity = CharacterEntity.new()
	var dps_2: CharacterEntity = CharacterEntity.new()
	root.add_child(lead_2)
	root.add_child(supp_2)
	root.add_child(dps_2)

	var hp_lead_2: HealthComponent = HealthComponent.new()
	var hp_supp_2: HealthComponent = HealthComponent.new()
	var hp_dps_2: HealthComponent = HealthComponent.new()
	lead_2.add_child(hp_lead_2)
	lead_2.health_component = hp_lead_2
	supp_2.add_child(hp_supp_2)
	supp_2.health_component = hp_supp_2
	dps_2.add_child(hp_dps_2)
	dps_2.health_component = hp_dps_2

	ctrl_2.set_party_members(lead_2, supp_2, dps_2)

	# 2.1 Support dies first
	hp_supp_2.is_alive = false
	hp_supp_2.current_hp = 0
	ctrl_2.reassign_roles_on_hero_death(supp_2)

	assert(ctrl_2.get_leader() == lead_2, "Leader unaffected by support death")
	assert(ctrl_2.get_support() == null, "Support cleared on death")
	assert(ctrl_2.get_dps() == dps_2, "DPS remains in position")

	# 2.2 Leader dies next -> DPS is directly promoted skipping dead support
	hp_lead_2.is_alive = false
	hp_lead_2.current_hp = 0
	ctrl_2.reassign_roles_on_hero_death(lead_2)

	assert(ctrl_2.get_leader() == dps_2, "DPS directly promoted to leader when support is already dead")
	assert(ctrl_2.get_support() == null, "Support remains null")
	assert(ctrl_2.get_dps() == null, "DPS slot cleared")

	print("PASS: 2.1 Skip-promotion directly to DPS when support dies first validated")

	ctrl_2.queue_free()
	lead_2.queue_free()
	supp_2.queue_free()
	dps_2.queue_free()

	# --------------------------------------------------------------------------
	# Test Group 3: Camera Rig Auto-Refocus on Leader Changed
	# --------------------------------------------------------------------------
	print("\n[Group 3: Camera Rig Auto-Refocus on Leader Changed]")
	var ctrl_3: PartyFormationController = PartyFormationController.new()
	var cam_3: IsometricCameraRig = IsometricCameraRig.new()
	root.add_child(ctrl_3)
	root.add_child(cam_3)

	var lead_3: CharacterEntity = CharacterEntity.new()
	var supp_3: CharacterEntity = CharacterEntity.new()
	root.add_child(lead_3)
	root.add_child(supp_3)

	var hp_lead_3: HealthComponent = HealthComponent.new()
	lead_3.add_child(hp_lead_3)
	lead_3.health_component = hp_lead_3

	ctrl_3.set_party_members(lead_3, supp_3, null)
	cam_3.set_target(lead_3)
	cam_3.party_controller = ctrl_3
	cam_3._setup_party_controller_listener()

	assert(cam_3.target == lead_3, "Camera initially targeting lead_3")

	# Trigger leader death and reassignment
	hp_lead_3.is_alive = false
	hp_lead_3.current_hp = 0
	ctrl_3.reassign_roles_on_hero_death(lead_3)

	assert(ctrl_3.get_leader() == supp_3, "Support promoted to leader")
	assert(cam_3.target == supp_3, "Camera target automatically switched to new leader supp_3")

	print("PASS: 3.1 IsometricCameraRig automatic refocussing on leader changed verified")

	ctrl_3.queue_free()
	cam_3.queue_free()
	lead_3.queue_free()
	supp_3.queue_free()


# ==============================================================================
# Live 3D NavMesh Simulation Setup
# ==============================================================================

func _setup_live_navigation_scene() -> void:
	print("\n================================================================================")
	print("--- Setting up Live 3D Navigation Scene for Dynamic Role Reassignment ---")
	print("================================================================================")

	var scene_res: PackedScene = load("res://tests/test_party_navigation_3d.tscn") as PackedScene
	assert(scene_res != null, "Scene res://tests/test_party_navigation_3d.tscn must exist and load")

	_scene_inst = scene_res.instantiate() as Node3D
	assert(_scene_inst != null, "test_party_navigation_3d.tscn must instantiate")
	root.add_child(_scene_inst)

	_nav_region = _scene_inst.get_node("NavigationRegion3D") as NavigationRegion3D
	_waypoints_holder = _scene_inst.get_node("WaypointsHolder") as Node3D
	_party_ctrl = _scene_inst.get_node("PartyFormationController") as PartyFormationController
	_camera_rig = _scene_inst.get_node("IsometricCameraRig") as IsometricCameraRig

	var wp1: Marker3D = _waypoints_holder.get_node("Waypoint_1") as Marker3D
	var wp2: Marker3D = _waypoints_holder.get_node("Waypoint_2") as Marker3D
	var wp3: Marker3D = _waypoints_holder.get_node("Waypoint_3") as Marker3D

	_waypoints = [wp1.global_position, wp2.global_position, wp3.global_position]

	_bromm = _party_ctrl.get_leader()
	_beatrice = _party_ctrl.get_support()
	_elysia = _party_ctrl.get_dps()

	assert(_bromm != null, "Bromm leader resolved")
	assert(_beatrice != null, "Beatrice support resolved")
	assert(_elysia != null, "Elysia DPS resolved")

	# Ensure CameraRig listens to leader_changed
	if not _party_ctrl.leader_changed.is_connected(_camera_rig.set_target):
		_party_ctrl.leader_changed.connect(_camera_rig.set_target)

	# Start initial trio march
	_bromm.state_machine.change_state("MarchState")
	_beatrice.state_machine.change_state("MarchState")
	_elysia.state_machine.change_state("MarchState")

	_target_wp_index = 0
	_total_physics_frames = 0
	_frames_in_phase = 0
	_waypoints_reached_by_alive_leaders.clear()

	_bromm.movement_component.move_towards(_waypoints[0])
	_sim_phase = 1

	print("Live simulation started: Trio marching towards Waypoint_1 (0, 0, 12)")


# ==============================================================================
# Live Sim Final Assertions (Group 5)
# ==============================================================================

func _run_live_sim_final_assertions() -> void:
	print("\n================================================================================")
	print("[Group 5: Full Live Dynamic Role Reassignment & Solo Traversal Summary]")
	print("================================================================================")
	print("Total Simulation Physics Frames: %d" % _total_physics_frames)
	print("Waypoints Reached Record: %s" % str(_waypoints_reached_by_alive_leaders))
	print("Bromm Death Position: %s" % str(_bromm_death_pos))
	print("Beatrice Death Position: %s" % str(_beatrice_death_pos))
	print("Final Solo Elysia Position: %s" % str(_elysia.global_position))
	print("Final Camera Rig Position: %s" % str(_camera_rig.global_position))

	# 5.1 Dead heroes verification
	assert(_bromm.state_machine.get_current_state_name() == "DeadState", "Bromm ended in DeadState")
	assert(_bromm.health_component.is_alive == false, "Bromm health is not alive")
	assert(_bromm.velocity.length() < 0.001, "Bromm velocity zeroed")

	assert(_beatrice.state_machine.get_current_state_name() == "DeadState", "Beatrice ended in DeadState")
	assert(_beatrice.health_component.is_alive == false, "Beatrice health is not alive")
	assert(_beatrice.velocity.length() < 0.001, "Beatrice velocity zeroed")

	# 5.2 Solo survivor Elysia verification
	assert(_elysia.health_component.is_alive == true, "Elysia is alive")
	assert(_elysia.state_machine.get_current_state_name() == "IdleState", "Elysia settled in IdleState at destination")
	assert(_party_ctrl.get_leader() == _elysia, "Elysia is current party leader")
	assert(_party_ctrl.get_support() == null, "Support slot is null")
	assert(_party_ctrl.get_dps() == null, "DPS slot is null")

	# 5.3 Waypoint arrival
	var final_target_wp3: Vector3 = _waypoints[2]
	var dist_to_final_wp3: float = Vector2(_elysia.global_position.x - final_target_wp3.x, _elysia.global_position.z - final_target_wp3.z).length()
	print("Elysia distance to final Waypoint_3: %.3fm" % dist_to_final_wp3)
	assert(dist_to_final_wp3 <= 0.6, "Solo survivor Elysia successfully reached final Waypoint_3 (dist: %.3fm <= 0.6m)" % dist_to_final_wp3)

	# 5.4 Camera tracking convergence to solo survivor
	var expected_cam_pos: Vector3 = Vector3(_elysia.global_position.x, 0.0, _elysia.global_position.z) + _camera_rig.camera_offset
	var cam_diff: float = (_camera_rig.global_position - expected_cam_pos).length()
	print("Camera tracking deviation from solo survivor: %.3fm" % cam_diff)
	assert(cam_diff <= 0.2, "Camera rig smoothly converged to final solo leader Elysia (diff: %.3fm <= 0.2m)" % cam_diff)

	print("\nPASS: 5.1 Full dynamic leadership promotion, successive deaths, follower offset tracking, solo march completion, and camera refocus validated!")

	print("\n================================================================================")
	print("=== ALL PARTY ROLE REASSIGNMENT UNIT & INTEGRATION TESTS PASSED (5/5) ===")
	print("================================================================================")
	quit(0)
