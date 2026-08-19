extends SceneTree

# ==============================================================================
# Unit & Integration Test Suite: ThreatTable.gd (Task M4.2)
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
	print("--- Starting ThreatTable Unit & Integration Tests (Task M4.2) ---")
	print("================================================================================")

	# Ensure EventBus Autoload node is present in SceneTree root
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
	# Test Group 1: Default Properties & Null-Safety
	# --------------------------------------------------------------------------
	print("\n[Group 1: Default Properties & Null-Safety]")
	var tt_1: ThreatTable = ThreatTable.new()
	assert(tt_1 != null, "ThreatTable instance must be created")
	assert(tt_1.primary_target == null, "Initial primary_target must be null")
	assert(tt_1.get_all_threats().is_empty(), "Initial threat table dictionary must be empty")
	assert(tt_1.get_threat(null) == 0.0, "get_threat(null) must return 0.0")
	assert(tt_1.get_threat_multiplier(null) == 1.0, "get_threat_multiplier(null) must return 1.0")

	# Safe null operations
	tt_1.add_threat(null, 100.0, 2.0)
	tt_1.add_threat(null, -10.0, 1.0)
	tt_1.modify_threat_multiplier(null, 3.0)
	tt_1.clear_dead_target(null)
	tt_1.reset_threat()
	assert(tt_1.primary_target == null, "primary_target must still be null after null ops")
	assert(tt_1.get_all_threats().is_empty(), "threat table must remain empty after null ops")

	print("PASS: 1.1 Standalone ThreatTable default properties and null-safety verified")
	tt_1.free()

	# --------------------------------------------------------------------------
	# Test Group 2: Threat Accumulation with Normal Damage (1.0x)
	# --------------------------------------------------------------------------
	print("\n[Group 2: Threat Accumulation with Normal Damage (1.0x)]")
	var tt_2: ThreatTable = ThreatTable.new()
	root.add_child(tt_2)

	var hero_dps: CharacterEntity = CharacterEntity.new()
	hero_dps.name = "HeroDPS_Elysia"
	root.add_child(hero_dps)

	var tracker_2: Dictionary = {
		"target_changed_count": 0,
		"last_target": null,
		"threat_updated_count": 0,
		"last_threat_source": null,
		"last_threat_amount": 0.0
	}

	tt_2.primary_target_changed.connect(func(target: CharacterEntity) -> void:
		tracker_2["target_changed_count"] += 1
		tracker_2["last_target"] = target
	)

	tt_2.threat_updated.connect(func(source: CharacterEntity, amount: float) -> void:
		tracker_2["threat_updated_count"] += 1
		tracker_2["last_threat_source"] = source
		tracker_2["last_threat_amount"] = amount
	)

	# 2.1 First hit: 20 normal damage
	tt_2.add_threat(hero_dps, 20.0)
	assert(tt_2.get_threat(hero_dps) == 20.0, "Threat for Elysia must be exactly 20.0")
	assert(tt_2.primary_target == hero_dps, "Primary target must be Elysia")
	assert(tracker_2["target_changed_count"] == 1, "primary_target_changed should emit once")
	assert(tracker_2["last_target"] == hero_dps, "Changed target must be Elysia")
	assert(tracker_2["threat_updated_count"] == 1, "threat_updated should emit once")
	assert(tracker_2["last_threat_source"] == hero_dps, "threat_updated source must be Elysia")
	assert(tracker_2["last_threat_amount"] == 20.0, "threat_updated amount must be 20.0")

	# 2.2 Second hit: 15 normal damage (Cumulative threat = 35.0)
	tt_2.add_threat(hero_dps, 15.0)
	assert(tt_2.get_threat(hero_dps) == 35.0, "Cumulative threat for Elysia must be 35.0")
	assert(tt_2.primary_target == hero_dps, "Primary target must still be Elysia")
	assert(tracker_2["target_changed_count"] == 1, "primary_target_changed must NOT emit if target didn't change")
	assert(tracker_2["threat_updated_count"] == 2, "threat_updated should emit for second hit")
	assert(tracker_2["last_threat_amount"] == 35.0, "threat_updated amount must be 35.0")

	print("PASS: 2.1 Proportional 1.0x threat accumulation and signal emission verified")
	tt_2.free()
	hero_dps.free()

	# --------------------------------------------------------------------------
	# Test Group 3: Tank Multipliers & Aggro Swapping (3.0x to 5.0x)
	# --------------------------------------------------------------------------
	print("\n[Group 3: Tank Multipliers & Aggro Swapping (3.0x to 5.0x)]")
	var tt_3: ThreatTable = ThreatTable.new()
	root.add_child(tt_3)

	var hero_dps_3: CharacterEntity = CharacterEntity.new()
	hero_dps_3.name = "Elysia_DPS"
	root.add_child(hero_dps_3)

	var hero_tank_3: CharacterEntity = CharacterEntity.new()
	hero_tank_3.name = "Bromm_Tank"
	root.add_child(hero_tank_3)

	var tracker_3: Dictionary = {
		"changes": [],
		"threat_updates": []
	}

	tt_3.primary_target_changed.connect(func(target: CharacterEntity) -> void:
		tracker_3["changes"].append(target)
	)

	tt_3.threat_updated.connect(func(source: CharacterEntity, amount: float) -> void:
		tracker_3["threat_updates"].append({"source": source, "amount": amount})
	)

	# 3.1 DPS deals 50 damage (Threat = 50.0) -> Focus Elysia
	tt_3.add_threat(hero_dps_3, 50.0, 1.0)
	assert(tt_3.primary_target == hero_dps_3, "Focus must be Elysia initially")
	assert(tracker_3["changes"].size() == 1, "1 target change so far")

	# 3.2 Tank strikes with Shield Slam: 20 base damage with 3.5x multiplier -> 70 threat
	tt_3.add_threat(hero_tank_3, 20.0, 3.5)
	assert(tt_3.get_threat(hero_tank_3) == 70.0, "Tank threat must be 20 * 3.5 = 70.0")
	assert(tt_3.get_threat(hero_dps_3) == 50.0, "DPS threat must remain 50.0")
	assert(tt_3.primary_target == hero_tank_3, "Focus must switch immediately to Tank (Aggro Swap)")
	assert(tracker_3["changes"].size() == 2, "2 target changes (Elysia -> Bromm)")
	assert(tracker_3["changes"][1] == hero_tank_3, "Second target change must be Bromm")

	# 3.3 Test persistent threat multiplier on Tank (Taunt Stance 4.0x)
	tt_3.modify_threat_multiplier(hero_tank_3, 4.0)
	assert(tt_3.get_threat_multiplier(hero_tank_3) == 4.0, "Tank threat multiplier must be 4.0")

	# Tank deals 10 normal damage (10 * 1.0 * 4.0 = +40 threat -> total 110.0)
	tt_3.add_threat(hero_tank_3, 10.0)
	assert(tt_3.get_threat(hero_tank_3) == 110.0, "Tank threat must be 70 + (10 * 4.0) = 110.0")
	assert(tt_3.primary_target == hero_tank_3, "Focus remains on Tank")
	assert(tracker_3["changes"].size() == 2, "No spurious target change emitted")

	# 3.4 DPS deals massive burst: 80 damage (50 + 80 = 130 threat) -> Aggro Swap back to DPS
	tt_3.add_threat(hero_dps_3, 80.0, 1.0)
	assert(tt_3.get_threat(hero_dps_3) == 130.0, "DPS threat must be 130.0")
	assert(tt_3.primary_target == hero_dps_3, "Focus must switch back to DPS upon surpassing Tank threat")
	assert(tracker_3["changes"].size() == 3, "3 target changes (Bromm -> Elysia)")
	assert(tracker_3["changes"][2] == hero_dps_3, "Third target change must be Elysia")

	# 3.5 Tank executes Taunt / High Threat Skill (20 dmg with 5.0x multiplier * 4.0 base = +400 threat -> total 510.0)
	tt_3.add_threat(hero_tank_3, 20.0, 5.0)
	assert(tt_3.get_threat(hero_tank_3) == 510.0, "Tank threat must be 110 + (20 * 5.0 * 4.0) = 510.0")
	assert(tt_3.primary_target == hero_tank_3, "Focus snaps back to Tank")
	assert(tracker_3["changes"].size() == 4, "4 target changes (Elysia -> Bromm)")

	print("PASS: 3.1 Tank multipliers (3.0x to 5.0x) and dynamic aggro swapping verified")
	tt_3.free()
	hero_dps_3.free()
	hero_tank_3.free()

	# --------------------------------------------------------------------------
	# Test Group 4: Automatic Cleanup & Recalculation on Target Death
	# --------------------------------------------------------------------------
	print("\n[Group 4: Automatic Cleanup & Recalculation on Target Death]")
	var tt_4: ThreatTable = ThreatTable.new()
	root.add_child(tt_4)

	var tank_4: CharacterEntity = CharacterEntity.new()
	tank_4.name = "Tank_Bromm"
	root.add_child(tank_4)
	var tank_hp_4: HealthComponent = HealthComponent.new()
	tank_hp_4.is_alive = true
	tank_hp_4.current_hp = 100
	tank_4.add_child(tank_hp_4)
	tank_4.health_component = tank_hp_4

	var dps_4: CharacterEntity = CharacterEntity.new()
	dps_4.name = "DPS_Elysia"
	root.add_child(dps_4)
	var dps_hp_4: HealthComponent = HealthComponent.new()
	dps_hp_4.is_alive = true
	dps_hp_4.current_hp = 60
	dps_4.add_child(dps_hp_4)
	dps_4.health_component = dps_hp_4

	var supp_4: CharacterEntity = CharacterEntity.new()
	supp_4.name = "Support_Beatrice"
	root.add_child(supp_4)
	var supp_hp_4: HealthComponent = HealthComponent.new()
	supp_hp_4.is_alive = true
	supp_hp_4.current_hp = 50
	supp_4.add_child(supp_hp_4)
	supp_4.health_component = supp_hp_4

	var monster_4: CharacterEntity = CharacterEntity.new()
	monster_4.name = "Enemy_Boss"
	root.add_child(monster_4)

	# Establish initial threat ladder: Tank (200), DPS (100), Support (30)
	tt_4.add_threat(tank_4, 200.0)
	tt_4.add_threat(dps_4, 100.0)
	tt_4.add_threat(supp_4, 30.0)

	assert(tt_4.primary_target == tank_4, "Primary target must be Tank (200 threat)")

	var sorted_targets: Array[CharacterEntity] = tt_4.get_sorted_threat_targets()
	assert(sorted_targets.size() == 3, "Sorted targets must contain 3 heroes")
	assert(sorted_targets[0] == tank_4, "First sorted target must be Tank")
	assert(sorted_targets[1] == dps_4, "Second sorted target must be DPS")
	assert(sorted_targets[2] == supp_4, "Third sorted target must be Support")

	var tracker_4: Dictionary = {
		"target_changed_count": 0,
		"new_target": null
	}
	tt_4.primary_target_changed.connect(func(t: CharacterEntity) -> void:
		tracker_4["target_changed_count"] += 1
		tracker_4["new_target"] = t
	)

	# 4.1 Tank dies -> EventBus.entity_died fires
	tank_hp_4.is_alive = false
	tank_hp_4.current_hp = 0
	bus.entity_died.emit(tank_4, monster_4)

	assert(tt_4.get_threat(tank_4) == 0.0, "Tank threat should be cleared from table")
	assert(tt_4.primary_target == dps_4, "Primary target must automatically transfer to next highest threat (DPS)")
	assert(tracker_4["target_changed_count"] == 1, "primary_target_changed should fire once on Tank death")
	assert(tracker_4["new_target"] == dps_4, "New target must be DPS")

	# 4.2 DPS dies -> direct clear_dead_target
	dps_hp_4.is_alive = false
	dps_hp_4.current_hp = 0
	tt_4.clear_dead_target(dps_4)

	assert(tt_4.get_threat(dps_4) == 0.0, "DPS threat should be cleared")
	assert(tt_4.primary_target == supp_4, "Primary target must automatically transfer to Support")
	assert(tracker_4["target_changed_count"] == 2, "primary_target_changed fired for Support")
	assert(tracker_4["new_target"] == supp_4, "New target must be Support")

	# 4.3 Support dies -> EventBus.entity_died fires -> Table is empty
	supp_hp_4.is_alive = false
	supp_hp_4.current_hp = 0
	bus.entity_died.emit(supp_4, monster_4)

	assert(tt_4.primary_target == null, "Primary target must become null when all targets die")
	assert(tracker_4["target_changed_count"] == 3, "primary_target_changed fired with null")
	assert(tracker_4["new_target"] == null, "New target must be null")

	print("PASS: 4.1 Automatic cleanup and target handover upon entity death verified")
	tt_4.free()
	tank_4.free()
	dps_4.free()
	supp_4.free()
	monster_4.free()

	# --------------------------------------------------------------------------
	# Test Group 5: Reset Threat & Dead Entity Filtering on Add
	# --------------------------------------------------------------------------
	print("\n[Group 5: Reset Threat & Dead Entity Filtering on Add]")
	var tt_5: ThreatTable = ThreatTable.new()
	root.add_child(tt_5)

	var hero_5: CharacterEntity = CharacterEntity.new()
	hero_5.name = "Hero_Alive"
	root.add_child(hero_5)
	var hero_hp_5: HealthComponent = HealthComponent.new()
	hero_hp_5.is_alive = true
	hero_5.add_child(hero_hp_5)
	hero_5.health_component = hero_hp_5

	var dead_hero_5: CharacterEntity = CharacterEntity.new()
	dead_hero_5.name = "Hero_Dead"
	root.add_child(dead_hero_5)
	var dead_hp_5: HealthComponent = HealthComponent.new()
	dead_hp_5.is_alive = false
	dead_hero_5.add_child(dead_hp_5)
	dead_hero_5.health_component = dead_hp_5

	# 5.1 Attempt to add threat from dead entity -> Must be ignored
	tt_5.add_threat(dead_hero_5, 100.0)
	assert(tt_5.get_threat(dead_hero_5) == 0.0, "Dead entity threat must not be added")
	assert(tt_5.primary_target == null, "Primary target remains null")

	# 5.2 Add threat from alive entity
	tt_5.add_threat(hero_5, 75.0)
	assert(tt_5.get_threat(hero_5) == 75.0, "Alive entity threat added")
	assert(tt_5.primary_target == hero_5, "Primary target set to hero_5")

	var tracker_5: Dictionary = {"reset_emitted": false, "reset_target": null}
	tt_5.primary_target_changed.connect(func(target: CharacterEntity) -> void:
		tracker_5["reset_emitted"] = true
		tracker_5["reset_target"] = target
	)

	# 5.3 Reset threat
	tt_5.reset_threat()
	assert(tt_5.primary_target == null, "primary_target must be null after reset_threat()")
	assert(tt_5.get_threat(hero_5) == 0.0, "hero_5 threat must be 0.0 after reset")
	assert(tt_5.get_all_threats().is_empty(), "all threats must be empty")
	assert(tracker_5["reset_emitted"] == true, "primary_target_changed must emit on reset")
	assert(tracker_5["reset_target"] == null, "primary_target_changed emitted with null")

	print("PASS: 5.1 Dead entity rejection and full threat reset verified")
	tt_5.free()
	hero_5.free()
	dead_hero_5.free()

	print("\n================================================================================")
	print("=== ALL THREAT TABLE UNIT TESTS PASSED (5/5 GROUPS) ===")
	print("================================================================================")
	quit(0)
