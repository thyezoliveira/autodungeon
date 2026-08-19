extends SceneTree

# ==============================================================================
# Unit & Integration Test Suite: MarchState.gd & IdleState.gd (Task M3.2)
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
	print("--- Starting MarchState & IdleState Unit & Integration Tests (Task M3.2) ---")
	print("================================================================================")

	# --------------------------------------------------------------------------
	# Test Group 1: Standalone Default Properties & Null-Safety
	# --------------------------------------------------------------------------
	print("\n[Group 1: Standalone Default Properties & Null-Safety]")
	var standalone_march: MarchState = MarchState.new()
	assert(standalone_march != null, "MarchState instance must be created")
	assert(standalone_march.movement_component == null, "Default movement_component should be null")
	assert(standalone_march.actor == null, "Default actor should be null")
	assert(standalone_march.state_machine == null, "Default state_machine should be null")

	# Safe method calls when unattached/null
	standalone_march.enter()
	standalone_march.physics_update(0.016)
	standalone_march.exit()
	print("PASS: 1.1 MarchState standalone null-safe method calls verified")
	standalone_march.free()

	var standalone_idle: IdleState = IdleState.new()
	assert(standalone_idle != null, "IdleState instance must be created")
	assert(standalone_idle.actor == null, "Default actor should be null")
	assert(standalone_idle.state_machine == null, "Default state_machine should be null")

	standalone_idle.enter()
	standalone_idle.physics_update(0.016)
	standalone_idle.exit()
	print("PASS: 1.2 IdleState standalone null-safe method calls verified")
	standalone_idle.free()

	# --------------------------------------------------------------------------
	# Test Group 2: Dependency Auto-Resolution in MarchState
	# --------------------------------------------------------------------------
	print("\n[Group 2: Dependency Auto-Resolution in MarchState]")
	# 2.1 Resolution from actor.movement_component
	var entity_actor: CharacterEntity = CharacterEntity.new()
	root.add_child(entity_actor)

	var move_comp_actor: MovementComponent = MovementComponent.new()
	move_comp_actor.name = "MovementComponent"
	entity_actor.add_child(move_comp_actor)
	entity_actor.movement_component = move_comp_actor

	var fsm_actor: StateMachine = StateMachine.new()
	fsm_actor.name = "StateMachine"
	entity_actor.add_child(fsm_actor)

	var march_test: MarchState = MarchState.new()
	march_test.name = "MarchState"
	fsm_actor.add_child(march_test)
	fsm_actor.register_states()

	assert(march_test.movement_component == null, "movement_component not yet resolved before enter()")
	march_test.enter()
	assert(march_test.movement_component == move_comp_actor, "Auto-resolved movement_component from actor.movement_component")
	print("PASS: 2.1 Auto-resolved movement_component from actor reference in enter()")

	entity_actor.queue_free()

	# 2.2 Resolution from parent container node hierarchy
	var container_entity: CharacterEntity = CharacterEntity.new()
	root.add_child(container_entity)

	var comp_node: Node3D = Node3D.new()
	comp_node.name = "Components"
	container_entity.add_child(comp_node)

	var move_comp_container: MovementComponent = MovementComponent.new()
	move_comp_container.name = "MovementComponent"
	comp_node.add_child(move_comp_container)

	var fsm_container: StateMachine = StateMachine.new()
	fsm_container.name = "StateMachine"
	container_entity.add_child(fsm_container)

	var march_unassigned: MarchState = MarchState.new()
	march_unassigned.name = "MarchState"
	fsm_container.add_child(march_unassigned)
	fsm_container.register_states()

	march_unassigned.physics_update(0.016)
	assert(march_unassigned.movement_component == move_comp_container, "Auto-resolved movement_component from Components node hierarchy")
	print("PASS: 2.2 Auto-resolved movement_component during physics_update() from Components container")

	container_entity.queue_free()

	# --------------------------------------------------------------------------
	# Test Group 3: MarchState Locomotion Lifecycle (enter, physics_update, exit)
	# --------------------------------------------------------------------------
	print("\n[Group 3: MarchState Locomotion Lifecycle (enter, physics_update, exit)]")
	var body_3: CharacterBody3D = CharacterBody3D.new()
	root.add_child(body_3)

	var move_comp_3: MovementComponent = MovementComponent.new()
	body_3.add_child(move_comp_3)
	move_comp_3._ready()

	var march_3: MarchState = MarchState.new()
	body_3.add_child(march_3)
	march_3.movement_component = move_comp_3

	# Set target and start locomotion
	move_comp_3.move_towards(Vector3(10.0, 0.0, 0.0))
	assert(move_comp_3.is_moving == true, "MovementComponent is_moving is true")

	march_3.enter()
	march_3.physics_update(0.016)

	assert(body_3.velocity.x > 0.0, "Velocity X is active during MarchState physics_update")
	assert(move_comp_3.is_moving == true, "MovementComponent remains moving during MarchState")
	print("PASS: 3.1 MarchState processes movement and updates physical velocity")

	# Exiting MarchState must halt physical movement immediately
	march_3.exit()
	assert(move_comp_3.is_moving == false, "MovementComponent is_moving reset to false on MarchState exit")
	assert(is_equal_approx(body_3.velocity.x, 0.0), "Body velocity X zeroed immediately on MarchState exit")
	assert(is_equal_approx(body_3.velocity.z, 0.0), "Body velocity Z zeroed immediately on MarchState exit")
	print("PASS: 3.2 MarchState exit() calls stop_movement() and immediately stops physical movement")

	body_3.queue_free()

	# --------------------------------------------------------------------------
	# Test Group 4: IdleState Velocity Reset & Quiescence
	# --------------------------------------------------------------------------
	print("\n[Group 4: IdleState Velocity Reset & Quiescence]")
	var entity_4: CharacterEntity = CharacterEntity.new()
	root.add_child(entity_4)

	var move_comp_4: MovementComponent = MovementComponent.new()
	entity_4.add_child(move_comp_4)
	entity_4.movement_component = move_comp_4
	move_comp_4._ready()

	var idle_4: IdleState = IdleState.new()
	entity_4.add_child(idle_4)
	idle_4.actor = entity_4

	# Artificially assign residual velocities and moving flag
	entity_4.velocity = Vector3(5.0, 0.0, -3.5)
	move_comp_4.is_moving = true

	# IdleState.enter() should zero residual velocity and stop movement_component
	idle_4.enter()
	assert(is_equal_approx(entity_4.velocity.x, 0.0), "Residual velocity X cleared to 0.0 on IdleState.enter()")
	assert(is_equal_approx(entity_4.velocity.z, 0.0), "Residual velocity Z cleared to 0.0 on IdleState.enter()")
	assert(move_comp_4.is_moving == false, "Active movement halted on IdleState.enter()")
	print("PASS: 4.1 IdleState.enter() cleanly zeroes residual velocity and halts movement")

	# physics_update maintains zero velocity
	entity_4.velocity.x = 2.0
	idle_4.physics_update(0.016)
	assert(is_equal_approx(entity_4.velocity.x, 0.0), "IdleState physics_update keeps planar velocity at zero")
	print("PASS: 4.2 IdleState physics_update maintains stationary guard state")

	entity_4.queue_free()

	# --------------------------------------------------------------------------
	# Test Group 5: FSM Transitions (IdleState -> MarchState -> IdleState)
	# --------------------------------------------------------------------------
	print("\n[Group 5: FSM Transitions (IdleState -> MarchState -> IdleState)]")
	var entity_5: CharacterEntity = CharacterEntity.new()
	entity_5.name = "FSMEntity"
	root.add_child(entity_5)

	var move_comp_5: MovementComponent = MovementComponent.new()
	move_comp_5.name = "MovementComponent"
	entity_5.add_child(move_comp_5)
	entity_5.movement_component = move_comp_5
	move_comp_5._ready()

	var fsm_5: StateMachine = StateMachine.new()
	fsm_5.name = "StateMachine"
	entity_5.add_child(fsm_5)

	var idle_5: IdleState = IdleState.new()
	idle_5.name = "IdleState"
	fsm_5.add_child(idle_5)

	var march_5: MarchState = MarchState.new()
	march_5.name = "MarchState"
	march_5.movement_component = move_comp_5
	fsm_5.add_child(march_5)

	var transition_tracker: Dictionary = {
		"events": []
	}

	fsm_5.initial_state = idle_5
	fsm_5._ready()

	# Conectar após _ready() para rastrear apenas as transições intencionais
	fsm_5.state_changed.connect(func(from_s: String, to_s: String) -> void:
		transition_tracker["events"].append("%s->%s" % [from_s, to_s])
	)

	assert(fsm_5.current_state == idle_5, "FSM starts in IdleState")
	assert(is_equal_approx(entity_5.velocity.x, 0.0), "Stationary in IdleState")

	# Set destination target and transition to MarchState
	move_comp_5.move_towards(Vector3(20.0, 0.0, 0.0))
	fsm_5.change_state("MarchState")

	assert(fsm_5.current_state == march_5, "FSM active state is now MarchState")
	assert(transition_tracker["events"].size() == 1, "1 transition recorded")
	assert(transition_tracker["events"][0] == "IdleState->MarchState", "Transitioned from IdleState to MarchState")

	# Process physical frame while in MarchState
	fsm_5._physics_process(0.016)
	assert(entity_5.velocity.x > 0.0, "Physical movement active during MarchState")
	print("PASS: 5.1 FSM transitioned from IdleState to MarchState; motion active")

	# Transition back to IdleState
	fsm_5.change_state("IdleState")
	assert(fsm_5.current_state == idle_5, "FSM active state is back to IdleState")
	assert(transition_tracker["events"].size() == 2, "2 transitions recorded")
	assert(transition_tracker["events"][1] == "MarchState->IdleState", "Transitioned from MarchState to IdleState")
	assert(move_comp_5.is_moving == false, "movement_component halted immediately on transition to IdleState")
	assert(is_equal_approx(entity_5.velocity.x, 0.0), "Velocity X halted immediately on transition to IdleState")

	# Further physics processes while in IdleState keep velocity at zero
	fsm_5._physics_process(0.016)
	assert(is_equal_approx(entity_5.velocity.x, 0.0), "Entity remains stationary in IdleState")
	print("PASS: 5.2 FSM transitioned from MarchState to IdleState; movement stopped immediately")

	entity_5.queue_free()

	# --------------------------------------------------------------------------
	# Test Group 6: Full Integration with CharacterEntity.tscn Prefab
	# --------------------------------------------------------------------------
	print("\n[Group 6: Full Integration with CharacterEntity.tscn Prefab]")
	var char_scene: PackedScene = load("res://src/entities/base/CharacterEntity.tscn") as PackedScene
	assert(char_scene != null, "CharacterEntity.tscn loaded successfully")

	var char_inst: CharacterEntity = char_scene.instantiate() as CharacterEntity
	assert(char_inst != null, "CharacterEntity instantiated successfully")
	root.add_child(char_inst)

	# Validate complete FSM states in prefab
	assert(char_inst.state_machine != null, "StateMachine exists in CharacterEntity.tscn")
	assert(char_inst.state_machine.has_state("IdleState"), "IdleState is registered in StateMachine")
	assert(char_inst.state_machine.has_state("MarchState"), "MarchState is registered in StateMachine")
	assert(char_inst.state_machine.has_state("DeadState"), "DeadState is registered in StateMachine")

	var march_in_prefab: MarchState = char_inst.state_machine.get_state("MarchState") as MarchState
	assert(march_in_prefab != null, "MarchState retrieved from StateMachine")
	assert(march_in_prefab.movement_component == char_inst.movement_component, "MarchState movement_component bound to CharacterEntity movement_component")

	assert(char_inst.state_machine.current_state is IdleState, "Entity starts in IdleState by default")

	# Start movement and switch to MarchState
	char_inst.movement_component.move_towards(Vector3(15.0, 0.0, 15.0))
	char_inst.state_machine.change_state("MarchState")
	assert(char_inst.state_machine.get_current_state_name() == "MarchState", "Entity transitioned to MarchState")

	# Physics tick
	char_inst.state_machine._physics_process(0.016)
	assert(char_inst.velocity.x > 0.0, "Entity moves along X axis in MarchState")
	assert(char_inst.velocity.z > 0.0, "Entity moves along Z axis in MarchState")

	# Return to IdleState
	char_inst.state_machine.change_state("IdleState")
	assert(char_inst.state_machine.get_current_state_name() == "IdleState", "Entity returned to IdleState")
	assert(char_inst.movement_component.is_moving == false, "movement_component is_moving is false")
	assert(is_equal_approx(char_inst.velocity.x, 0.0), "Velocity X is zeroed in IdleState")
	assert(is_equal_approx(char_inst.velocity.z, 0.0), "Velocity Z is zeroed in IdleState")

	# Transition to DeadState and verify complete shutdown
	char_inst.state_machine.change_state("MarchState")
	char_inst.movement_component.move_towards(Vector3(10.0, 0.0, 0.0))
	char_inst.state_machine._physics_process(0.016)
	assert(char_inst.velocity.x > 0.0, "Entity moving before death")

	# Trigger death
	char_inst.health_component.current_hp = 0
	char_inst.health_component.is_alive = false
	char_inst.health_component.died.emit(null)

	assert(char_inst.state_machine.get_current_state_name() == "DeadState", "Entity transitioned to DeadState on death")
	assert(is_equal_approx(char_inst.velocity.x, 0.0), "Velocity zeroed in DeadState")
	assert(char_inst.body_collider.disabled == true, "BodyCollider disabled in DeadState")
	print("PASS: 6.1 CharacterEntity.tscn full FSM integration verified (IdleState, MarchState, DeadState)")

	char_inst.queue_free()

	print("\n================================================================================")
	print("=== ALL MARCHSTATE & IDLESTATE UNIT TESTS PASSED (6/6 GROUPS) ===")
	print("================================================================================")
	quit(0)
