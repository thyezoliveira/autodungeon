extends SceneTree

# ==============================================================================
# Unit & Integration Test Suite: RoomEncounterController.gd (Task M5.5)
# ==============================================================================

const RoomEncounterController = preload("res://src/systems/RoomEncounterController.gd")
const PartyFormationController = preload("res://src/systems/PartyFormationController.gd")
const CombatTriggerSystem = preload("res://src/systems/CombatTriggerSystem.gd")
const CharacterEntity = preload("res://src/entities/base/CharacterEntity.gd")
const HealthComponent = preload("res://src/entities/components/HealthComponent.gd")
const Hurtbox3D = preload("res://src/entities/components/Hurtbox3D.gd")
const HeroData = preload("res://src/data/heroes/HeroData.gd")

var _executed: bool = false


func _process(_delta: float) -> bool:
	if _executed:
		return false
	_executed = true
	_run_all_tests()
	return false


func _run_all_tests() -> void:
	print("================================================================================")
	print("--- Starting RoomEncounterController Unit & Integration Tests (Task M5.5) ---")
	print("================================================================================")

	# Ensure EventBus Autoload node is present in SceneTree root
	var bus: EventBusSingleton = null
	if root.has_node("EventBus"):
		bus = root.get_node("EventBus") as EventBusSingleton
		print("PASS: EventBus Autoload node found in SceneTree root")
	else:
		var bus_script: Script = load("res://src/core/EventBus.gd")
		bus = Node.new() as EventBusSingleton
		bus.name = "EventBus"
		bus.set_script(bus_script)
		root.add_child(bus)
		print("INFO: Instantiated EventBusSingleton manually for SceneTree test harness")

	# --------------------------------------------------------------------------
	# Group 1: Default Properties, Exports & Null-Safety
	# --------------------------------------------------------------------------
	print("\n[Group 1: Default Properties, Exports & Null-Safety]")
	var ctrl_1: RoomEncounterController = RoomEncounterController.new()
	assert(ctrl_1 != null, "RoomEncounterController instance must be created")
	assert(ctrl_1.room_index == 1, "Default room_index is 1")
	assert(ctrl_1.room_name == "Sala 1", "Default room_name is 'Sala 1'")
	assert(ctrl_1.enemy_pack.is_empty(), "Default enemy_pack is empty")
	assert(ctrl_1.party_controller == null, "Default party_controller is null")
	assert(ctrl_1.combat_trigger_system == null, "Default combat_trigger_system is null")
	assert(ctrl_1.auto_start_combat == true, "Default auto_start_combat is true")
	assert(ctrl_1.get_alive_enemies_count() == 0, "Initial alive count is 0")
	assert(not ctrl_1.is_encounter_active(), "Encounter is not active initially")
	assert(not ctrl_1.is_encounter_cleared(), "Encounter is not cleared initially")

	# Null-safe calls
	ctrl_1._on_body_entered(null)
	ctrl_1._on_area_entered(null)
	ctrl_1._on_entity_died(null, null)
	ctrl_1.reset_encounter()
	print("PASS: 1.1 Default properties, initial flags and null-safety verified")
	ctrl_1.free()

	# --------------------------------------------------------------------------
	# Group 2: Enemy Pack Setup and Alive Count Tracking
	# --------------------------------------------------------------------------
	print("\n[Group 2: Enemy Pack Setup & Living Monster Count]")
	var ctrl_2: RoomEncounterController = RoomEncounterController.new()
	root.add_child(ctrl_2)

	var warrior_scene: PackedScene = load("res://src/entities/enemies/GoblinWarrior.tscn") as PackedScene
	var archer_scene: PackedScene = load("res://src/entities/enemies/GoblinArcher.tscn") as PackedScene

	var mob_w1: CharacterEntity = warrior_scene.instantiate() as CharacterEntity
	root.add_child(mob_w1)
	var mob_w2: CharacterEntity = warrior_scene.instantiate() as CharacterEntity
	root.add_child(mob_w2)
	var mob_arc: CharacterEntity = archer_scene.instantiate() as CharacterEntity
	root.add_child(mob_arc)

	var pack_3: Array[CharacterEntity] = [mob_w1, mob_w2, mob_arc]
	ctrl_2.setup_enemy_pack(pack_3)

	assert(ctrl_2.enemy_pack.size() == 3, "Enemy pack contains 3 entities")
	assert(ctrl_2.get_alive_enemies_count() == 3, "get_alive_enemies_count() returns 3")
	assert(ctrl_2.get_living_enemies().size() == 3, "get_living_enemies() returns 3 items")

	ctrl_2.free()
	mob_w1.free()
	mob_w2.free()
	mob_arc.free()
	print("PASS: 2.1 Enemy pack initialization with 3 mobs (2 Warriors + 1 Archer) verified")

	# --------------------------------------------------------------------------
	# Group 3: Hero Entry Detection & Encounter Start (Sala 1)
	# --------------------------------------------------------------------------
	print("\n[Group 3: Hero Entry Detection & Encounter Start]")
	var ctrl_3: RoomEncounterController = RoomEncounterController.new()
	ctrl_3.room_index = 1
	ctrl_3.room_name = "Sala 1 (Encontro Basico)"
	root.add_child(ctrl_3)

	var hero_bromm: CharacterEntity = CharacterEntity.new()
	hero_bromm.name = "Hero_Bromm"
	hero_bromm.hero_data = load("res://src/data/heroes/resources/hero_bromm.tres") as HeroData
	hero_bromm.collision_layer = 2 # Hero_Bodies
	root.add_child(hero_bromm)

	var party_ctrl_3: PartyFormationController = PartyFormationController.new()
	party_ctrl_3.set_party_members(hero_bromm, null, null)
	root.add_child(party_ctrl_3)
	ctrl_3.party_controller = party_ctrl_3

	var cts_3: CombatTriggerSystem = CombatTriggerSystem.new()
	cts_3.party_controller = party_ctrl_3
	root.add_child(cts_3)
	ctrl_3.combat_trigger_system = cts_3

	var mob_g1: CharacterEntity = warrior_scene.instantiate() as CharacterEntity
	root.add_child(mob_g1)
	var mob_g2: CharacterEntity = warrior_scene.instantiate() as CharacterEntity
	root.add_child(mob_g2)
	var mob_g3: CharacterEntity = archer_scene.instantiate() as CharacterEntity
	root.add_child(mob_g3)

	ctrl_3.setup_enemy_pack([mob_g1, mob_g2, mob_g3])

	var tracker_3: Dictionary = {
		"encounter_started_fired": false,
		"started_room_idx": -1,
		"eb_room_entered_fired": false,
		"eb_room_idx": -1,
		"eb_room_name": ""
	}

	ctrl_3.encounter_started.connect(func(r_idx: int) -> void:
		tracker_3["encounter_started_fired"] = true
		tracker_3["started_room_idx"] = r_idx
	)

	var on_eb_room_entered_3: Callable = func(r_idx: int, r_name: String) -> void:
		tracker_3["eb_room_entered_fired"] = true
		tracker_3["eb_room_idx"] = r_idx
		tracker_3["eb_room_name"] = r_name

	bus.room_entered.connect(on_eb_room_entered_3)

	# Simulate hero entry via _on_body_entered
	ctrl_3._on_body_entered(hero_bromm)

	assert(ctrl_3.is_encounter_active(), "Encounter is now active")
	assert(tracker_3["encounter_started_fired"], "encounter_started signal fired")
	assert(tracker_3["started_room_idx"] == 1, "encounter_started room_idx is 1")
	assert(tracker_3["eb_room_entered_fired"], "EventBus.room_entered signal fired")
	assert(tracker_3["eb_room_idx"] == 1, "EventBus room_index is 1")
	assert(tracker_3["eb_room_name"] == "Sala 1 (Encontro Basico)", "EventBus room_name is 'Sala 1 (Encontro Basico)'")
	assert(cts_3.active_enemy_pack.size() == 3, "CombatTriggerSystem active_enemy_pack registered 3 enemies")

	# Duplicate entry does not restart encounter
	tracker_3["encounter_started_fired"] = false
	tracker_3["eb_room_entered_fired"] = false
	ctrl_3._on_body_entered(hero_bromm)
	assert(not tracker_3["encounter_started_fired"], "Duplicate entry does not re-trigger encounter_started")
	assert(not tracker_3["eb_room_entered_fired"], "Duplicate entry does not re-trigger EventBus.room_entered")

	bus.room_entered.disconnect(on_eb_room_entered_3)
	ctrl_3.free()
	party_ctrl_3.free()
	cts_3.free()
	hero_bromm.free()
	mob_g1.free()
	mob_g2.free()
	mob_g3.free()
	print("PASS: 3.1 Hero entry detection, encounter_started and EventBus.room_entered verified")

	# --------------------------------------------------------------------------
	# Group 4 & 5: Sequential Enemy Elimination & Room Cleared (Sala 1 Scenario)
	# --------------------------------------------------------------------------
	print("\n[Group 4 & 5: Sequential Elimination & Room Cleared (Sala 1)]")
	var ctrl_4: RoomEncounterController = RoomEncounterController.new()
	ctrl_4.room_index = 1
	ctrl_4.room_name = "Sala 1"
	root.add_child(ctrl_4)

	var hero_lead_4: CharacterEntity = CharacterEntity.new()
	hero_lead_4.name = "Hero_Bromm_Leader"
	hero_lead_4.hero_data = load("res://src/data/heroes/resources/hero_bromm.tres") as HeroData
	root.add_child(hero_lead_4)

	var party_ctrl_4: PartyFormationController = PartyFormationController.new()
	party_ctrl_4.set_party_members(hero_lead_4, null, null)
	party_ctrl_4.formation_active = false # In combat, formation was paused
	root.add_child(party_ctrl_4)
	ctrl_4.party_controller = party_ctrl_4

	var w1: CharacterEntity = warrior_scene.instantiate() as CharacterEntity
	root.add_child(w1)
	var w2: CharacterEntity = warrior_scene.instantiate() as CharacterEntity
	root.add_child(w2)
	var a1: CharacterEntity = archer_scene.instantiate() as CharacterEntity
	root.add_child(a1)

	ctrl_4.setup_enemy_pack([w1, w2, a1])
	ctrl_4.start_encounter()

	assert(ctrl_4.get_alive_enemies_count() == 3, "Initial alive count is 3")

	var tracker_4: Dictionary = {
		"cleared_fired": false,
		"cleared_room_idx": -1,
		"eb_cleared_fired": false,
		"eb_cleared_room_idx": -1
	}

	ctrl_4.encounter_cleared.connect(func(r_idx: int) -> void:
		tracker_4["cleared_fired"] = true
		tracker_4["cleared_room_idx"] = r_idx
	)

	var on_eb_cleared_4: Callable = func(r_idx: int) -> void:
		tracker_4["eb_cleared_fired"] = true
		tracker_4["eb_cleared_room_idx"] = r_idx

	bus.room_cleared.connect(on_eb_cleared_4)

	# 1. Kill Warrior 1
	w1.health_component.current_hp = 0
	w1.health_component.is_alive = false
	bus.entity_died.emit(w1, hero_lead_4)

	assert(ctrl_4.get_alive_enemies_count() == 2, "Alive count reduced to 2 after w1 death")
	assert(ctrl_4.is_encounter_active(), "Encounter still active")
	assert(not tracker_4["cleared_fired"], "Room not cleared yet")

	# 2. Kill Warrior 2
	w2.health_component.current_hp = 0
	w2.health_component.is_alive = false
	bus.entity_died.emit(w2, hero_lead_4)

	assert(ctrl_4.get_alive_enemies_count() == 1, "Alive count reduced to 1 after w2 death")
	assert(ctrl_4.is_encounter_active(), "Encounter still active")
	assert(not tracker_4["cleared_fired"], "Room not cleared yet")

	# 3. Kill Archer (Last Enemy in Sala 1)
	a1.health_component.current_hp = 0
	a1.health_component.is_alive = false
	bus.entity_died.emit(a1, hero_lead_4)

	assert(ctrl_4.get_alive_enemies_count() == 0, "Alive count is 0")
	assert(not ctrl_4.is_encounter_active(), "Encounter is no longer active")
	assert(ctrl_4.is_encounter_cleared(), "is_encounter_cleared() is true")
	assert(tracker_4["cleared_fired"], "encounter_cleared signal emitted")
	assert(tracker_4["cleared_room_idx"] == 1, "encounter_cleared emitted room_index 1")
	assert(tracker_4["eb_cleared_fired"], "EventBus.room_cleared signal emitted")
	assert(tracker_4["eb_cleared_room_idx"] == 1, "EventBus.room_cleared emitted room_index 1")
	assert(party_ctrl_4.formation_active == true, "Party march formation reactivated upon room clear")

	bus.room_cleared.disconnect(on_eb_cleared_4)
	ctrl_4.free()
	party_ctrl_4.free()
	hero_lead_4.free()
	w1.free()
	w2.free()
	a1.free()
	print("PASS: 4.1 & 5.1 Sequential elimination (3 -> 2 -> 1 -> 0), encounter_cleared, EventBus.room_cleared and march resumption verified")

	# --------------------------------------------------------------------------
	# Group 6: Room 2 Scenario (Mini-Boss Captain + Healer)
	# --------------------------------------------------------------------------
	print("\n[Group 6: Room 2 Scenario (Captain Mini-Boss + Goblin Healer)]")
	var captain_scene: PackedScene = load("res://src/entities/enemies/GoblinCaptain.tscn") as PackedScene
	var healer_scene: PackedScene = load("res://src/entities/enemies/GoblinHealer.tscn") as PackedScene

	var ctrl_r2: RoomEncounterController = RoomEncounterController.new()
	ctrl_r2.room_index = 2
	ctrl_r2.room_name = "Sala 2 (Mini-Chefe Capitao)"
	root.add_child(ctrl_r2)

	var hero_lead_r2: CharacterEntity = CharacterEntity.new()
	hero_lead_r2.name = "Hero_Bromm_R2"
	hero_lead_r2.hero_data = load("res://src/data/heroes/resources/hero_bromm.tres") as HeroData
	root.add_child(hero_lead_r2)

	var party_ctrl_r2: PartyFormationController = PartyFormationController.new()
	party_ctrl_r2.set_party_members(hero_lead_r2, null, null)
	party_ctrl_r2.formation_active = false
	root.add_child(party_ctrl_r2)
	ctrl_r2.party_controller = party_ctrl_r2

	var captain: CharacterEntity = captain_scene.instantiate() as CharacterEntity
	root.add_child(captain)
	var healer: CharacterEntity = healer_scene.instantiate() as CharacterEntity
	root.add_child(healer)

	ctrl_r2.setup_enemy_pack([captain, healer])
	assert(ctrl_r2.get_alive_enemies_count() == 2, "Room 2 has 2 enemies (Captain + Healer)")

	var tracker_r2: Dictionary = {
		"started_idx": -1,
		"cleared_idx": -1,
		"eb_entered_idx": -1,
		"eb_cleared_idx": -1
	}

	ctrl_r2.encounter_started.connect(func(idx: int) -> void: tracker_r2["started_idx"] = idx)
	ctrl_r2.encounter_cleared.connect(func(idx: int) -> void: tracker_r2["cleared_idx"] = idx)

	var on_eb_entered_r2: Callable = func(idx: int, _name: String) -> void: tracker_r2["eb_entered_idx"] = idx
	var on_eb_cleared_r2: Callable = func(idx: int) -> void: tracker_r2["eb_cleared_idx"] = idx

	bus.room_entered.connect(on_eb_entered_r2)
	bus.room_cleared.connect(on_eb_cleared_r2)

	# Enter Room 2
	ctrl_r2._on_body_entered(hero_lead_r2)
	assert(tracker_r2["started_idx"] == 2, "Room 2 encounter started")
	assert(tracker_r2["eb_entered_idx"] == 2, "EventBus.room_entered for Room 2")

	# Kill Healer first
	healer.health_component.current_hp = 0
	healer.health_component.is_alive = false
	bus.entity_died.emit(healer, hero_lead_r2)
	assert(ctrl_r2.get_alive_enemies_count() == 1, "Captain remains alive in Room 2")
	assert(not ctrl_r2.is_encounter_cleared(), "Room 2 not cleared while Captain lives")

	# Kill Captain (Mini-Boss)
	captain.health_component.current_hp = 0
	captain.health_component.is_alive = false
	bus.entity_died.emit(captain, hero_lead_r2)

	assert(ctrl_r2.get_alive_enemies_count() == 0, "Room 2 pack wiped")
	assert(ctrl_r2.is_encounter_cleared(), "Room 2 encounter cleared")
	assert(tracker_r2["cleared_idx"] == 2, "encounter_cleared emitted index 2")
	assert(tracker_r2["eb_cleared_idx"] == 2, "EventBus.room_cleared emitted index 2")
	assert(party_ctrl_r2.formation_active == true, "Party formation resumed after Room 2 mini-boss")

	bus.room_entered.disconnect(on_eb_entered_r2)
	bus.room_cleared.disconnect(on_eb_cleared_r2)
	ctrl_r2.free()
	party_ctrl_r2.free()
	hero_lead_r2.free()
	captain.free()
	healer.free()
	print("PASS: 6.1 Room 2 scenario (Captain Mini-Boss + Healer) fully validated with index 2 events")

	# --------------------------------------------------------------------------
	# Group 7: Foreign Entity Deaths & Edge Cases
	# --------------------------------------------------------------------------
	print("\n[Group 7: Foreign Entity Deaths & Edge Cases]")
	var ctrl_7: RoomEncounterController = RoomEncounterController.new()
	ctrl_7.room_index = 1
	root.add_child(ctrl_7)

	var my_mob: CharacterEntity = warrior_scene.instantiate() as CharacterEntity
	root.add_child(my_mob)
	ctrl_7.setup_enemy_pack([my_mob])
	ctrl_7.start_encounter()
	assert(ctrl_7.get_alive_enemies_count() == 1, "ctrl_7 alive count is 1")

	# An external mob (from another room) dies
	var foreign_mob: CharacterEntity = warrior_scene.instantiate() as CharacterEntity
	root.add_child(foreign_mob)
	foreign_mob.health_component.current_hp = 0
	foreign_mob.health_component.is_alive = false
	bus.entity_died.emit(foreign_mob, null)

	assert(ctrl_7.get_alive_enemies_count() == 1, "Foreign mob death does NOT decrement ctrl_7 count")
	assert(not ctrl_7.is_encounter_cleared(), "ctrl_7 is not cleared by foreign death")

	# Non-CharacterEntity node died
	var dummy_node: Node3D = Node3D.new()
	root.add_child(dummy_node)
	bus.entity_died.emit(dummy_node, null)
	assert(ctrl_7.get_alive_enemies_count() == 1, "Non-CharacterEntity death safely ignored")

	# Now kill my_mob -> cleared
	my_mob.health_component.current_hp = 0
	my_mob.health_component.is_alive = false
	bus.entity_died.emit(my_mob, null)
	assert(ctrl_7.is_encounter_cleared(), "ctrl_7 cleared when my_mob dies")

	# Reset encounter
	ctrl_7.reset_encounter()
	assert(not ctrl_7.is_encounter_active(), "reset_encounter resets active flag")
	assert(not ctrl_7.is_encounter_cleared(), "reset_encounter resets cleared flag")

	ctrl_7.free()
	my_mob.free()
	foreign_mob.free()
	dummy_node.free()
	print("PASS: 7.1 Foreign entity deaths ignored, edge cases and reset_encounter verified")

	# --------------------------------------------------------------------------
	# Group 8: Area Collision (Hurtbox3D) & Hero Subnode Detection
	# --------------------------------------------------------------------------
	print("\n[Group 8: Area Collision (Hurtbox3D) & Hero Subnode Detection]")
	var ctrl_8: RoomEncounterController = RoomEncounterController.new()
	ctrl_8.room_index = 1
	root.add_child(ctrl_8)

	var hero_parent: CharacterEntity = CharacterEntity.new()
	hero_parent.name = "Hero_Elysia_Ranger"
	hero_parent.hero_data = load("res://src/data/heroes/resources/hero_elysia.tres") as HeroData
	root.add_child(hero_parent)

	var hurtbox: Hurtbox3D = Hurtbox3D.new()
	hurtbox.name = "Hurtbox3D"
	hurtbox.collision_layer = 16 # Hero_Hurtboxes
	hero_parent.add_child(hurtbox)

	var mob_test: CharacterEntity = warrior_scene.instantiate() as CharacterEntity
	root.add_child(mob_test)
	ctrl_8.setup_enemy_pack([mob_test])

	# Trigger entry via hero hurtbox
	ctrl_8._on_area_entered(hurtbox)
	assert(ctrl_8.is_encounter_active(), "Hero detected via Hurtbox3D area_entered")

	ctrl_8.free()
	hero_parent.free()
	mob_test.free()
	print("PASS: 8.1 Area3D area_entered with Hurtbox3D properly detects hero and triggers encounter")

	print("\n================================================================================")
	print("=== ALL ROOM ENCOUNTER CONTROLLER UNIT TESTS PASSED (8/8 GROUPS) ===")
	print("================================================================================")
	quit(0)
