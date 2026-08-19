extends SceneTree

# ==============================================================================
# Mock & Tracked State Helper Class
# ==============================================================================
class MockTrackedState:
	extends State

	var enter_count: int = 0
	var exit_count: int = 0
	var physics_update_count: int = 0
	var update_count: int = 0
	var last_physics_delta: float = 0.0
	var last_update_delta: float = 0.0
	var event_log: Array[String] = []

	func _init(p_name: String, p_log: Array[String] = []) -> void:
		name = p_name
		event_log = p_log

	func enter() -> void:
		enter_count += 1
		if event_log != null:
			event_log.append(name + ".enter")

	func exit() -> void:
		exit_count += 1
		if event_log != null:
			event_log.append(name + ".exit")

	func physics_update(delta: float) -> void:
		physics_update_count += 1
		last_physics_delta = delta

	func update(delta: float) -> void:
		update_count += 1
		last_update_delta = delta


var _executed: bool = false


func _process(_delta: float) -> bool:
	if _executed:
		return false
	_executed = true
	_run_all_tests()
	return false


func _run_all_tests() -> void:
	print("========================================")
	print("--- Starting StateMachine & State Unit Tests ---")
	print("========================================")

	# ----------------------------------------------------
	# Test Group 1: Default StateMachine Properties & API
	# ----------------------------------------------------
	print("\n[Group 1: Default Properties & API]")
	var standalone_fsm: StateMachine = StateMachine.new()
	assert(standalone_fsm != null, "StateMachine instance must be created")
	assert(standalone_fsm.initial_state == null, "Default initial_state should be null")
	assert(standalone_fsm.current_state == null, "Default current_state should be null")
	assert(standalone_fsm.get_current_state_name() == "", "get_current_state_name() should return empty string when current_state is null")
	assert(standalone_fsm.has_state("invalid") == false, "has_state('invalid') should return false on empty FSM")
	assert(standalone_fsm.has_state("") == false, "has_state('') should return false on empty string")
	assert(standalone_fsm.get_state("invalid") == null, "get_state('invalid') should return null on empty FSM")
	assert(standalone_fsm.get_state("") == null, "get_state('') should return null on empty string")
	print("PASS: 1.1 StateMachine default properties and null-safety verified")

	var standalone_state: State = State.new()
	assert(standalone_state != null, "State instance must be created")
	assert(standalone_state.state_machine == null, "Default State state_machine should be null")
	assert(standalone_state.actor == null, "Default State actor should be null")
	standalone_state.enter()
	standalone_state.exit()
	standalone_state.physics_update(0.016)
	standalone_state.update(0.016)
	print("PASS: 1.2 State base class virtual methods callable without error")
	standalone_state.free()
	standalone_fsm.free()

	# ----------------------------------------------------
	# Test Group 2: Automatic Child State Discovery & Dependency Injection
	# ----------------------------------------------------
	print("\n[Group 2: Automatic Child State Discovery & Dependency Injection]")
	var dummy_actor: CharacterEntity = CharacterEntity.new()
	dummy_actor.name = "DummyActor"
	root.add_child(dummy_actor)

	var fsm: StateMachine = StateMachine.new()
	fsm.name = "StateMachine"
	dummy_actor.add_child(fsm)

	var shared_log: Array[String] = []
	var idle_state: MockTrackedState = MockTrackedState.new("Idle", shared_log)
	var walk_state: MockTrackedState = MockTrackedState.new("Walk", shared_log)
	var attack_state: MockTrackedState = MockTrackedState.new("Attack", shared_log)

	fsm.add_child(idle_state)
	fsm.add_child(walk_state)
	fsm.add_child(attack_state)

	# Calling register_states to simulate _ready initialization
	fsm.register_states()

	assert(fsm.has_state("Idle"), "has_state('Idle') should return true")
	assert(fsm.has_state("idle"), "has_state('idle') should return true (case-insensitive)")
	assert(fsm.has_state("IDLE"), "has_state('IDLE') should return true (all-caps)")
	assert(fsm.has_state("Walk"), "has_state('Walk') should return true")
	assert(fsm.has_state("Attack"), "has_state('Attack') should return true")
	assert(fsm.has_state("NonExistent") == false, "has_state('NonExistent') should return false")

	assert(idle_state.state_machine == fsm, "idle_state.state_machine should point to FSM")
	assert(walk_state.state_machine == fsm, "walk_state.state_machine should point to FSM")
	assert(attack_state.state_machine == fsm, "attack_state.state_machine should point to FSM")

	assert(idle_state.actor == dummy_actor, "idle_state.actor should point to CharacterEntity dummy_actor")
	assert(walk_state.actor == dummy_actor, "walk_state.actor should point to CharacterEntity dummy_actor")
	assert(attack_state.actor == dummy_actor, "attack_state.actor should point to CharacterEntity dummy_actor")
	print("PASS: 2.1 Child states automatically registered with state_machine and actor references")

	# ----------------------------------------------------
	# Test Group 3: Initial State Configuration in _ready()
	# ----------------------------------------------------
	print("\n[Group 3: Initial State Configuration in _ready()]")
	var init_actor: CharacterEntity = CharacterEntity.new()
	init_actor.name = "InitActor"
	root.add_child(init_actor)

	var init_fsm: StateMachine = StateMachine.new()
	init_fsm.name = "InitStateMachine"
	init_actor.add_child(init_fsm)

	var init_log: Array[String] = []
	var patrol_state: MockTrackedState = MockTrackedState.new("Patrol", init_log)
	var alert_state: MockTrackedState = MockTrackedState.new("Alert", init_log)
	init_fsm.add_child(patrol_state)
	init_fsm.add_child(alert_state)

	# Set initial_state before _ready()
	init_fsm.initial_state = patrol_state

	# Trigger _ready()
	init_fsm._ready()

	assert(init_fsm.current_state == patrol_state, "current_state should equal initial_state patrol_state")
	assert(init_fsm.get_current_state_name() == "Patrol", "get_current_state_name() should return 'Patrol'")
	assert(patrol_state.enter_count == 1, "patrol_state enter_count should be 1 after _ready()")
	assert(patrol_state.exit_count == 0, "patrol_state exit_count should be 0")
	assert(init_log == ["Patrol.enter"], "init_log should record Patrol.enter")
	print("PASS: 3.1 initial_state entered automatically on _ready()")

	# ----------------------------------------------------
	# Test Group 4: State Transitions & Strict Execution Order
	# ----------------------------------------------------
	print("\n[Group 4: State Transitions & Strict Execution Order (exit -> enter -> state_changed)]")
	var signal_tracker: Dictionary = {
		"emitted": false,
		"from_state": "",
		"to_state": "",
		"emit_count": 0
	}

	init_fsm.state_changed.connect(func(from_s: String, to_s: String) -> void:
		signal_tracker["emitted"] = true
		signal_tracker["from_state"] = from_s
		signal_tracker["to_state"] = to_s
		signal_tracker["emit_count"] += 1
		init_log.append("signal(%s -> %s)" % [from_s, to_s])
	)

	init_log.clear()
	signal_tracker["emitted"] = false

	# Transition Patrol -> Alert
	init_fsm.change_state("Alert")

	assert(init_fsm.current_state == alert_state, "current_state should now be alert_state")
	assert(init_fsm.get_current_state_name() == "Alert", "get_current_state_name() should return 'Alert'")
	assert(patrol_state.exit_count == 1, "Patrol exit_count should be 1")
	assert(alert_state.enter_count == 1, "Alert enter_count should be 1")

	# Verify strict order: Patrol.exit -> Alert.enter -> signal(Patrol -> Alert)
	assert(init_log.size() == 3, "Transition log should contain 3 entries, got: " + str(init_log))
	assert(init_log[0] == "Patrol.exit", "1st action must be Patrol.exit, got: " + init_log[0])
	assert(init_log[1] == "Alert.enter", "2nd action must be Alert.enter, got: " + init_log[1])
	assert(init_log[2] == "signal(Patrol -> Alert)", "3rd action must be signal emission, got: " + init_log[2])

	assert(signal_tracker["emitted"], "state_changed signal must be emitted")
	assert(signal_tracker["from_state"] == "Patrol", "from_state parameter must be 'Patrol'")
	assert(signal_tracker["to_state"] == "Alert", "to_state parameter must be 'Alert'")
	print("PASS: 4.1 Strict transition sequence (exit -> enter -> state_changed signal) verified")

	# ----------------------------------------------------
	# Test Group 5: Same-State Transition (Idempotency)
	# ----------------------------------------------------
	print("\n[Group 5: Same-State Transition / Idempotency]")
	init_log.clear()
	signal_tracker["emitted"] = false
	var prev_alert_enter_count: int = alert_state.enter_count
	var prev_alert_exit_count: int = alert_state.exit_count

	# Attempt transition to current active state "Alert"
	init_fsm.change_state("Alert")

	assert(init_fsm.current_state == alert_state, "current_state remains alert_state")
	assert(alert_state.enter_count == prev_alert_enter_count, "Alert enter_count must not increment on same-state transition")
	assert(alert_state.exit_count == prev_alert_exit_count, "Alert exit_count must not increment on same-state transition")
	assert(not signal_tracker["emitted"], "state_changed signal must NOT be emitted on same-state transition")
	assert(init_log.is_empty(), "No events logged during same-state transition")
	print("PASS: 5.1 Redundant transition to current active state is safely ignored")

	# ----------------------------------------------------
	# Test Group 6: Defensive Handling of Invalid State Names
	# ----------------------------------------------------
	print("\n[Group 6: Defensive Handling of Invalid State Names]")
	init_log.clear()
	signal_tracker["emitted"] = false

	# Change to non-existent state
	init_fsm.change_state("NonExistentState_XYZ")
	assert(init_fsm.current_state == alert_state, "current_state should remain alert_state on invalid state name")
	assert(not signal_tracker["emitted"], "state_changed signal must NOT be emitted on invalid state")
	assert(init_log.is_empty(), "No exit/enter events on invalid state name")

	# Change with empty string
	init_fsm.change_state("")
	assert(init_fsm.current_state == alert_state, "current_state should remain alert_state on empty state name")
	assert(not signal_tracker["emitted"], "state_changed signal must NOT be emitted on empty state name")
	assert(init_log.is_empty(), "No exit/enter events on empty state name")
	print("PASS: 6.1 Invalid and empty state names handled defensively without crashing or changing state")

	# ----------------------------------------------------
	# Test Group 7: Physics & Process Update Execution
	# ----------------------------------------------------
	print("\n[Group 7: Physics & Process Update Execution]")
	# Currently in Alert state
	assert(alert_state.physics_update_count == 0, "Alert initial physics_update_count is 0")
	assert(alert_state.update_count == 0, "Alert initial update_count is 0")
	assert(patrol_state.physics_update_count == 0, "Patrol initial physics_update_count is 0")
	assert(patrol_state.update_count == 0, "Patrol initial update_count is 0")

	init_fsm._physics_process(0.0166)
	assert(alert_state.physics_update_count == 1, "Alert physics_update called during _physics_process")
	assert(is_equal_approx(alert_state.last_physics_delta, 0.0166), "Alert received correct delta in physics_update")
	assert(patrol_state.physics_update_count == 0, "Inactive Patrol state did NOT receive physics_update")

	init_fsm._process(0.0333)
	assert(alert_state.update_count == 1, "Alert update called during _process")
	assert(is_equal_approx(alert_state.last_update_delta, 0.0333), "Alert received correct delta in update")
	assert(patrol_state.update_count == 0, "Inactive Patrol state did NOT receive update")

	# Switch active state to Patrol and verify updates route to Patrol only
	init_fsm.change_state("Patrol")
	init_fsm._physics_process(0.02)
	assert(patrol_state.physics_update_count == 1, "Newly active Patrol state received physics_update")
	assert(is_equal_approx(patrol_state.last_physics_delta, 0.02), "Patrol received delta 0.02")
	assert(alert_state.physics_update_count == 1, "Inactive Alert state physics_update count unchanged")

	init_fsm._process(0.04)
	assert(patrol_state.update_count == 1, "Newly active Patrol state received update")
	assert(is_equal_approx(patrol_state.last_update_delta, 0.04), "Patrol received delta 0.04")
	assert(alert_state.update_count == 1, "Inactive Alert state update count unchanged")
	print("PASS: 7.1 _physics_process and _process correctly delegated only to the active state")

	# ----------------------------------------------------
	# Test Group 8: Case-Insensitive State Transition
	# ----------------------------------------------------
	print("\n[Group 8: Case-Insensitive State Transition]")
	init_log.clear()
	# Transition back to Alert using lowercase "alert"
	init_fsm.change_state("alert")
	assert(init_fsm.current_state == alert_state, "Transition with 'alert' (lowercase) found Alert state")
	assert(init_fsm.get_current_state_name() == "Alert", "Current state name remains 'Alert'")

	# Transition back to Patrol using mixed case "PaTrOl"
	init_fsm.change_state("PaTrOl")
	assert(init_fsm.current_state == patrol_state, "Transition with 'PaTrOl' (mixed-case) found Patrol state")
	assert(init_fsm.get_current_state_name() == "Patrol", "Current state name remains 'Patrol'")
	print("PASS: 8.1 Case-insensitive state lookup verified for change_state")

	# ----------------------------------------------------
	# Test Group 9: Dynamic Programmatic State Addition
	# ----------------------------------------------------
	print("\n[Group 9: Dynamic Programmatic State Addition]")
	var dead_state: MockTrackedState = MockTrackedState.new("Dead", init_log)
	init_fsm.add_child(dead_state)
	init_fsm.register_state(dead_state)

	assert(init_fsm.has_state("Dead"), "has_state('Dead') is true after register_state")
	assert(init_fsm.get_state("Dead") == dead_state, "get_state('Dead') returns dead_state")
	assert(dead_state.state_machine == init_fsm, "dead_state.state_machine is set")
	assert(dead_state.actor == init_actor, "dead_state.actor is set")

	init_log.clear()
	init_fsm.change_state("Dead")
	assert(init_fsm.current_state == dead_state, "Transitioned to dynamically added state 'Dead'")
	assert(dead_state.enter_count == 1, "dead_state enter_count is 1")
	assert(init_fsm.get_current_state_name() == "Dead", "get_current_state_name() is 'Dead'")
	print("PASS: 9.1 Dynamically registered states participate fully in FSM lifecycle")

	# Clean up
	dummy_actor.queue_free()
	init_actor.queue_free()

	print("\n========================================")
	print("=== ALL STATEMACHINE & STATE UNIT TESTS PASSED (9/9 GROUPS) ===")
	print("========================================")
	quit(0)
