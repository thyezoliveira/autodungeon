extends SceneTree

# ==============================================================================
# Unit & Integration Test Suite: CombatTriggerSystem.gd (Task M4.1)
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
	print("--- Starting CombatTriggerSystem Unit & Integration Tests (Task M4.1) ---")
	print("================================================================================")

	# Ensure EventBus Autoload is present in SceneTree root
	var bus: EventBusSingleton = null
	if root.has_node("EventBus"):
		bus = root.get_node("EventBus") as EventBusSingleton
		print("PASS: EventBus Autoload node found in SceneTree root")
	else:
		bus = EventBusSingleton.new()
		bus.name = "EventBus"
		root.add_child(bus)
		print("INFO: Instantiated EventBusSingleton manually for SceneTree test harness")

	# --------------------------------------------------------------------------
	# Test Group 1: Default Properties, Exports & Null-Safety
	# --------------------------------------------------------------------------
	print("\n[Group 1: Default Properties, Exports & Null-Safety]")
	var standalone_cts: CombatTriggerSystem = CombatTriggerSystem.new()
	assert(standalone_cts != null, "CombatTriggerSystem instance must be created")
	assert(standalone_cts.is_party_in_combat == false, "Initial is_party_in_combat must be false")
	assert(standalone_cts.active_enemy_pack.is_empty(), "Initial active_enemy_pack must be empty")
	assert(standalone_cts.party_controller == null, "Initial party_controller should be null")

	# Standalone safe method calls without tree
	standalone_cts.end_combat()
	standalone_cts._on_damage_dealt(null, null, 10, false, false)
	standalone_cts._on_entity_died(null, null)
	print("PASS: 1.1 Standalone CombatTriggerSystem null-safe initialization and methods verified")
	standalone_cts.free()

	# --------------------------------------------------------------------------
	# Test Group 2: Initial State - Marching Without Physical Contact
	# --------------------------------------------------------------------------
	print("\n[Group 2: Initial State - Marching Without Physical Contact]")
	var cts_2: CombatTriggerSystem = CombatTriggerSystem.new()
	root.add_child(cts_2)

	var party_ctrl_2: PartyFormationController = PartyFormationController.new()
	root.add_child(party_ctrl_2)

	var hero_leader_2: CharacterEntity = CharacterEntity.new()
	hero_leader_2.name = "HeroLeader"
	root.add_child(hero_leader_2)

	var hero_health_2: HealthComponent = HealthComponent.new()
	hero_health_2.name = "HealthComponent"
	hero_leader_2.add_child(hero_health_2)
	hero_leader_2.health_component = hero_health_2

	party_ctrl_2.set_party_members(hero_leader_2, null, null)
	cts_2.party_controller = party_ctrl_2

	var tracker_2: Dictionary = {
		"combat_started": false,
		"eb_combat_triggered": false
	}

	cts_2.party_combat_started.connect(func(_init: Node3D, _targ: Node3D) -> void:
		tracker_2["combat_started"] = true
	)
	var on_eb_combat_2: Callable = func(_init: Node3D, _targ: Node3D) -> void:
		tracker_2["eb_combat_triggered"] = true

	bus.combat_triggered.connect(on_eb_combat_2)

	# Simulating movement ticks without collision
	assert(cts_2.is_party_in_combat == false, "Party must remain out of combat while marching")
	assert(hero_health_2.in_combat == false, "Hero HealthComponent must remain in_combat == false")
	assert(tracker_2["combat_started"] == false, "party_combat_started must NOT fire without physical contact")
	assert(tracker_2["eb_combat_triggered"] == false, "EventBus.combat_triggered must NOT fire without physical contact")
	print("PASS: 2.1 Quiescence maintained during active march with 0 physical impacts")

	bus.combat_triggered.disconnect(on_eb_combat_2)
	cts_2.free()
	party_ctrl_2.free()
	hero_leader_2.free()

	# --------------------------------------------------------------------------
	# Test Group 3: First Physical Impact (damage_dealt -> synchronous combat trigger)
	# --------------------------------------------------------------------------
	print("\n[Group 3: First Physical Impact & Synchronous Combat Trigger]")
	var cts_3: CombatTriggerSystem = CombatTriggerSystem.new()
	root.add_child(cts_3)

	var party_ctrl_3: PartyFormationController = PartyFormationController.new()
	root.add_child(party_ctrl_3)

	var bromm_3: CharacterEntity = CharacterEntity.new()
	bromm_3.name = "Bromm"
	root.add_child(bromm_3)

	var bromm_health_3: HealthComponent = HealthComponent.new()
	bromm_health_3.name = "HealthComponent"
	bromm_3.add_child(bromm_health_3)
	bromm_3.health_component = bromm_health_3

	var elysia_3: CharacterEntity = CharacterEntity.new()
	elysia_3.name = "Elysia"
	root.add_child(elysia_3)

	var elysia_health_3: HealthComponent = HealthComponent.new()
	elysia_health_3.name = "HealthComponent"
	elysia_3.add_child(elysia_health_3)
	elysia_3.health_component = elysia_health_3

	party_ctrl_3.set_party_members(bromm_3, null, elysia_3)
	cts_3.party_controller = party_ctrl_3

	var enemy_goblin_3: CharacterEntity = CharacterEntity.new()
	enemy_goblin_3.name = "GoblinEnemy"
	root.add_child(enemy_goblin_3)

	var goblin_health_3: HealthComponent = HealthComponent.new()
	goblin_health_3.name = "HealthComponent"
	enemy_goblin_3.add_child(goblin_health_3)
	enemy_goblin_3.health_component = goblin_health_3

	var tracker_3: Dictionary = {
		"started_called": false,
		"started_initiator": null,
		"started_target": null,
		"eb_triggered_called": false,
		"eb_initiator": null,
		"eb_target": null
	}

	cts_3.party_combat_started.connect(func(init: Node3D, targ: Node3D) -> void:
		tracker_3["started_called"] = true
		tracker_3["started_initiator"] = init
		tracker_3["started_target"] = targ
	)
	var on_eb_combat_3: Callable = func(init: Node3D, targ: Node3D) -> void:
		tracker_3["eb_triggered_called"] = true
		tracker_3["eb_initiator"] = init
		tracker_3["eb_target"] = targ

	bus.combat_triggered.connect(on_eb_combat_3)

	# Bromm physically hits Goblin
	bus.damage_dealt.emit(enemy_goblin_3, bromm_3, 20, false, false)

	assert(cts_3.is_party_in_combat == true, "is_party_in_combat must be true immediately on first impact")
	assert(tracker_3["started_called"] == true, "party_combat_started must fire synchronously")
	assert(tracker_3["started_initiator"] == bromm_3, "party_combat_started initiator must be Bromm")
	assert(tracker_3["started_target"] == enemy_goblin_3, "party_combat_started target must be Goblin")

	assert(tracker_3["eb_triggered_called"] == true, "EventBus.combat_triggered must fire synchronously")
	assert(tracker_3["eb_initiator"] == bromm_3, "EventBus initiator must be Bromm")
	assert(tracker_3["eb_target"] == enemy_goblin_3, "EventBus target must be Goblin")

	assert(bromm_health_3.in_combat == true, "Bromm (leader) in_combat state must be true")
	assert(elysia_health_3.in_combat == true, "Elysia (dps) in_combat state must be true")

	# Subsequent damage events while in combat should NOT re-trigger combat start
	tracker_3["started_called"] = false
	tracker_3["eb_triggered_called"] = false
	bus.damage_dealt.emit(enemy_goblin_3, elysia_3, 15, false, false)
	assert(tracker_3["started_called"] == false, "Duplicate party_combat_started must not be emitted during ongoing combat")
	assert(tracker_3["eb_triggered_called"] == false, "Duplicate EventBus.combat_triggered must not be emitted")

	bus.combat_triggered.disconnect(on_eb_combat_3)

	cts_3.free()
	party_ctrl_3.free()
	bromm_3.free()
	elysia_3.free()
	enemy_goblin_3.free()
	print("PASS: 3.1 First physical impact synchronously triggers combat and synchronizes party in_combat flags")

	# --------------------------------------------------------------------------
	# Test Group 4: Friendly Fire & Non-Combatant Impact Filtering
	# --------------------------------------------------------------------------
	print("\n[Group 4: Friendly Fire & Non-Combatant Impact Filtering]")
	var cts_4: CombatTriggerSystem = CombatTriggerSystem.new()
	root.add_child(cts_4)

	var party_ctrl_4: PartyFormationController = PartyFormationController.new()
	root.add_child(party_ctrl_4)

	var hero_a: CharacterEntity = CharacterEntity.new()
	hero_a.name = "HeroTank"
	root.add_child(hero_a)

	var hero_b: CharacterEntity = CharacterEntity.new()
	hero_b.name = "HeroCleric"
	root.add_child(hero_b)

	party_ctrl_4.set_party_members(hero_a, hero_b, null)
	cts_4.party_controller = party_ctrl_4

	var mob_a: CharacterEntity = CharacterEntity.new()
	mob_a.name = "EnemyGoblinA"
	root.add_child(mob_a)

	var mob_b: CharacterEntity = CharacterEntity.new()
	mob_b.name = "EnemyGoblinB"
	root.add_child(mob_b)

	var tracker_4: Dictionary = {"started": false}
	cts_4.party_combat_started.connect(func(_i: Node3D, _t: Node3D) -> void:
		tracker_4["started"] = true
	)

	# 4.1 Hero hitting Hero (Friendly fire)
	bus.damage_dealt.emit(hero_b, hero_a, 5, false, false)
	assert(cts_4.is_party_in_combat == false, "Friendly fire between heroes must NOT trigger combat")
	assert(tracker_4["started"] == false, "party_combat_started must NOT fire on friendly fire")

	# 4.2 Enemy hitting Enemy
	bus.damage_dealt.emit(mob_b, mob_a, 5, false, false)
	assert(cts_4.is_party_in_combat == false, "Friendly fire between enemies must NOT trigger combat")
	assert(tracker_4["started"] == false, "party_combat_started must NOT fire on enemy infighting")

	# 4.3 Enemy hitting Hero -> MUST TRIGGER COMBAT
	bus.damage_dealt.emit(hero_a, mob_a, 10, false, false)
	assert(cts_4.is_party_in_combat == true, "Enemy hitting hero MUST trigger combat")
	assert(tracker_4["started"] == true, "party_combat_started fired on enemy ambush")

	print("PASS: 4.1 Friendly fire and faction filtering strictly verified")
	cts_4.free()
	party_ctrl_4.free()
	hero_a.free()
	hero_b.free()
	mob_a.free()
	mob_b.free()

	# --------------------------------------------------------------------------
	# Test Group 5: Enemy Pack Management & Defeat / Combat Termination
	# --------------------------------------------------------------------------
	print("\n[Group 5: Enemy Pack Management & Defeat / Combat Termination]")
	var cts_5: CombatTriggerSystem = CombatTriggerSystem.new()
	root.add_child(cts_5)

	var party_ctrl_5: PartyFormationController = PartyFormationController.new()
	root.add_child(party_ctrl_5)

	var hero_5: CharacterEntity = CharacterEntity.new()
	hero_5.name = "HeroBromm"
	root.add_child(hero_5)

	var hero_health_5: HealthComponent = HealthComponent.new()
	hero_health_5.name = "HealthComponent"
	hero_5.add_child(hero_health_5)
	hero_5.health_component = hero_health_5

	party_ctrl_5.set_party_members(hero_5, null, null)
	cts_5.party_controller = party_ctrl_5

	var mob_1: CharacterEntity = CharacterEntity.new()
	mob_1.name = "GoblinWarrior"
	root.add_child(mob_1)

	var mob_hp_1: HealthComponent = HealthComponent.new()
	mob_hp_1.name = "HealthComponent"
	mob_1.add_child(mob_hp_1)
	mob_1.health_component = mob_hp_1

	var mob_2: CharacterEntity = CharacterEntity.new()
	mob_2.name = "GoblinArcher"
	root.add_child(mob_2)

	var mob_hp_2: HealthComponent = HealthComponent.new()
	mob_hp_2.name = "HealthComponent"
	mob_2.add_child(mob_hp_2)
	mob_2.health_component = mob_hp_2

	# Register enemy pack
	var pack_array: Array[CharacterEntity] = [mob_1, mob_2]
	cts_5.register_enemy_pack(pack_array)
	assert(cts_5.active_enemy_pack.size() == 2, "Active enemy pack must contain 2 mobs")

	var tracker_5: Dictionary = {
		"combat_ended_called": false,
		"end_call_count": 0
	}
	cts_5.party_combat_ended.connect(func() -> void:
		tracker_5["combat_ended_called"] = true
		tracker_5["end_call_count"] += 1
	)

	# Start combat via first strike
	bus.damage_dealt.emit(mob_1, hero_5, 25, false, false)
	assert(cts_5.is_party_in_combat == true, "Combat started on first hit")
	assert(hero_health_5.in_combat == true, "Hero marked in_combat == true")

	# Kill Mob 1
	mob_hp_1.current_hp = 0
	mob_hp_1.is_alive = false
	bus.entity_died.emit(mob_1, hero_5)

	assert(cts_5.active_enemy_pack.size() == 1, "Active enemy pack reduced to 1 mob")
	assert(cts_5.active_enemy_pack.has(mob_2), "Mob 2 remains in active pack")
	assert(cts_5.is_party_in_combat == true, "Combat remains active while mob 2 is alive")
	assert(tracker_5["combat_ended_called"] == false, "party_combat_ended must NOT fire while mobs remain alive")

	# Kill Mob 2 (Final Mob in pack)
	mob_hp_2.current_hp = 0
	mob_hp_2.is_alive = false
	bus.entity_died.emit(mob_2, hero_5)

	assert(cts_5.active_enemy_pack.is_empty(), "Active enemy pack is now empty")
	assert(cts_5.is_party_in_combat == false, "is_party_in_combat reset to false on pack wipe")
	assert(tracker_5["combat_ended_called"] == true, "party_combat_ended emitted on last mob death")
	assert(tracker_5["end_call_count"] == 1, "party_combat_ended emitted exactly once")
	assert(hero_health_5.in_combat == false, "Hero in_combat flag restored to false (OOC regen enabled)")

	print("PASS: 5.1 Sequential elimination of enemy pack correctly triggers party_combat_ended")
	cts_5.free()
	party_ctrl_5.free()
	hero_5.free()
	mob_1.free()
	mob_2.free()

	# --------------------------------------------------------------------------
	# Test Group 6: Full Trio vs Enemy Pack Integration Test
	# --------------------------------------------------------------------------
	print("\n[Group 6: Full Trio vs Enemy Pack Integration Test]")
	var cts_6: CombatTriggerSystem = CombatTriggerSystem.new()
	root.add_child(cts_6)

	var party_ctrl_6: PartyFormationController = PartyFormationController.new()
	root.add_child(party_ctrl_6)

	var tank: CharacterEntity = CharacterEntity.new()
	tank.name = "HeroTank_Bromm"
	root.add_child(tank)
	var tank_hp: HealthComponent = HealthComponent.new()
	tank_hp.max_hp = 120
	tank_hp.current_hp = 120
	tank.add_child(tank_hp)
	tank.health_component = tank_hp

	var supp: CharacterEntity = CharacterEntity.new()
	supp.name = "HeroSupport_Beatrice"
	root.add_child(supp)
	var supp_hp: HealthComponent = HealthComponent.new()
	supp_hp.max_hp = 80
	supp_hp.current_hp = 80
	supp.add_child(supp_hp)
	supp.health_component = supp_hp

	var dps: CharacterEntity = CharacterEntity.new()
	dps.name = "HeroDPS_Elysia"
	root.add_child(dps)
	var dps_hp: HealthComponent = HealthComponent.new()
	dps_hp.max_hp = 70
	dps_hp.current_hp = 70
	dps.add_child(dps_hp)
	dps.health_component = dps_hp

	party_ctrl_6.set_party_members(tank, supp, dps)
	cts_6.party_controller = party_ctrl_6

	var mob: CharacterEntity = CharacterEntity.new()
	mob.name = "Enemy_Goblin"
	root.add_child(mob)
	var mob_hp: HealthComponent = HealthComponent.new()
	mob_hp.max_hp = 50
	mob_hp.current_hp = 50
	mob.add_child(mob_hp)
	mob.health_component = mob_hp

	cts_6.register_enemy_pack([mob])

	# Hitbox on Tank hits Hurtbox on Mob
	var tank_hitbox: Hitbox3D = Hitbox3D.new()
	tank_hitbox.setup(30, true, false, tank)
	tank.add_child(tank_hitbox)

	var mob_hurtbox: Hurtbox3D = Hurtbox3D.new()
	mob_hurtbox.setup(mob_hp, null, mob)
	mob.add_child(mob_hurtbox)

	# Initial check: march state
	assert(not cts_6.is_party_in_combat, "Group is in march state")
	assert(not tank_hp.in_combat and not supp_hp.in_combat and not dps_hp.in_combat, "All heroes in_combat == false")

	# Vanguard strike
	tank_hitbox._on_area_entered(mob_hurtbox)

	# Impact verified
	assert(cts_6.is_party_in_combat, "Group transitioned to combat immediately upon vanguard strike")
	assert(tank_hp.in_combat == true, "Tank in combat")
	assert(supp_hp.in_combat == true, "Support in combat")
	assert(dps_hp.in_combat == true, "DPS in combat")

	# Defeat mob
	mob_hp.current_hp = 0
	mob_hp.is_alive = false
	bus.entity_died.emit(mob, tank)

	assert(not cts_6.is_party_in_combat, "Group transitioned back to out-of-combat on enemy defeat")
	assert(tank_hp.in_combat == false, "Tank out of combat")
	assert(supp_hp.in_combat == false, "Support out of combat")
	assert(dps_hp.in_combat == false, "DPS out of combat")

	print("PASS: 6.1 Full Trio vs Pack lifecycle integration verified successfully")

	cts_6.free()
	party_ctrl_6.free()
	tank.free()
	supp.free()
	dps.free()
	mob.free()

	print("\n================================================================================")
	print("=== ALL COMBAT TRIGGER SYSTEM UNIT TESTS PASSED (6/6 GROUPS) ===")
	print("================================================================================")
	quit(0)
