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
	print("--- Starting HealthComponent Unit Tests ---")
	print("========================================")

	# Ensure EventBus Autoload is present in SceneTree root for tests
	var bus: EventBusSingleton = null
	if root.has_node("EventBus"):
		bus = root.get_node("EventBus") as EventBusSingleton
		print("PASS: EventBus Autoload node found in SceneTree root")
	else:
		bus = EventBusSingleton.new()
		bus.name = "EventBus"
		root.add_child(bus)
		print("INFO: Instantiated EventBusSingleton manually for SceneTree test harness")

	# ----------------------------------------------------
	# Test Group 1: Default State & Exported Properties
	# ----------------------------------------------------
	print("\n[Group 1: Default State & Exported Properties]")
	var health: HealthComponent = HealthComponent.new()
	assert(health != null, "HealthComponent instance must be created")
	assert(health.current_hp == 100, "Default current_hp should be 100")
	assert(health.max_hp == 100, "Default max_hp should be 100")
	assert(is_equal_approx(health.current_mana, 50.0), "Default current_mana should be 50.0")
	assert(is_equal_approx(health.max_mana, 50.0), "Default max_mana should be 50.0")
	assert(health.is_alive == true, "Default is_alive should be true")
	assert(health.in_combat == false, "Default in_combat should be false")
	print("PASS: 1.1 HealthComponent default properties verified")
	health.free()

	# ----------------------------------------------------
	# Test Group 2: Linear Damage Mitigation & Armor Cap
	# Formula: Dano = max(1, raw_damage - min(80, max(0, armor_value)))
	# ----------------------------------------------------
	print("\n[Group 2: Linear Damage Mitigation & Armor Cap]")
	var h_mit: HealthComponent = HealthComponent.new()
	h_mit.max_hp = 200
	h_mit.current_hp = 200

	# 2.1 Normal damage: raw 50, armor 20 -> dmg = 50 - 20 = 30 -> HP = 170
	var dmg1: int = h_mit.take_damage(50, 20)
	assert(dmg1 == 30, "Raw 50 with 20 armor should deal 30 damage, got: " + str(dmg1))
	assert(h_mit.current_hp == 170, "Current HP should be 170, got: " + str(h_mit.current_hp))
	print("PASS: 2.1 Normal damage mitigation (50 raw - 20 armor = 30 dmg)")

	# 2.2 Armor Cap of 80: raw 100, armor 90 -> armor capped at 80 -> dmg = 100 - 80 = 20 -> HP = 150
	var dmg2: int = h_mit.take_damage(100, 90)
	assert(dmg2 == 20, "Raw 100 with 90 armor (capped at 80) should deal 20 damage, got: " + str(dmg2))
	assert(h_mit.current_hp == 150, "Current HP should be 150, got: " + str(h_mit.current_hp))
	print("PASS: 2.2 Armor cap of 80 applied (100 raw - 80 capped armor = 20 dmg)")

	# 2.3 Minimum damage of 1: raw 50, armor 90 -> 50 - 80 = -30 -> max(1, -30) = 1 -> HP = 149
	var dmg3: int = h_mit.take_damage(50, 90)
	assert(dmg3 == 1, "Raw 50 with 90 armor should deal minimum 1 damage, got: " + str(dmg3))
	assert(h_mit.current_hp == 149, "Current HP should be 149, got: " + str(h_mit.current_hp))
	print("PASS: 2.3 Minimum damage cap of 1 applied when armor exceeds raw damage")

	# 2.4 Zero armor: raw 40, armor 0 -> dmg = 40 -> HP = 109
	var dmg4: int = h_mit.take_damage(40, 0)
	assert(dmg4 == 40, "Raw 40 with 0 armor should deal 40 damage, got: " + str(dmg4))
	assert(h_mit.current_hp == 109, "Current HP should be 109, got: " + str(h_mit.current_hp))
	print("PASS: 2.4 Zero armor applies full raw damage")

	# 2.5 Negative armor safety: raw 30, armor -15 -> clamped to 0 -> dmg = 30 -> HP = 79
	var dmg5: int = h_mit.take_damage(30, -15)
	assert(dmg5 == 30, "Negative armor clamped to 0 should deal 30 damage, got: " + str(dmg5))
	assert(h_mit.current_hp == 79, "Current HP should be 79, got: " + str(h_mit.current_hp))
	print("PASS: 2.5 Negative armor clamped to 0 safely")

	# 2.6 Zero / negative raw damage minimum: raw 0, armor 0 -> max(1, 0) = 1 -> HP = 78
	var dmg6: int = h_mit.take_damage(0, 0)
	assert(dmg6 == 1, "Raw 0 damage should deal minimum 1 damage, got: " + str(dmg6))
	assert(h_mit.current_hp == 78, "Current HP should be 78, got: " + str(h_mit.current_hp))
	print("PASS: 2.6 Zero raw damage dealt minimum 1 damage")
	h_mit.free()

	# ----------------------------------------------------
	# Test Group 3: Signal Emissions on Damage & EventBus Integration
	# ----------------------------------------------------
	print("\n[Group 3: Signal Emissions on Damage & EventBus Integration]")
	var parent_entity: Node3D = Node3D.new()
	parent_entity.name = "TestEntity"
	root.add_child(parent_entity)

	var h_sig: HealthComponent = HealthComponent.new()
	parent_entity.add_child(h_sig)
	h_sig.max_hp = 100
	h_sig.current_hp = 100

	var attacker_node: Node3D = Node3D.new()
	attacker_node.name = "Attacker"
	root.add_child(attacker_node)

	var local_tracker: Dictionary = {
		"health_changed_called": false,
		"hp": 0,
		"max_hp": 0,
		"damage_taken_called": false,
		"amount": 0,
		"is_blocked": false,
		"source": null
	}

	var bus_tracker: Dictionary = {
		"damage_dealt_called": false,
		"target": null,
		"source": null,
		"amount": 0,
		"is_blocked": false,
		"health_changed_called": false,
		"bus_hp": 0,
		"bus_max_hp": 0
	}

	h_sig.health_changed.connect(func(c_hp: int, m_hp: int) -> void:
		local_tracker["health_changed_called"] = true
		local_tracker["hp"] = c_hp
		local_tracker["max_hp"] = m_hp
	)

	h_sig.damage_taken.connect(func(amt: int, blk: bool, src: Node3D) -> void:
		local_tracker["damage_taken_called"] = true
		local_tracker["amount"] = amt
		local_tracker["is_blocked"] = blk
		local_tracker["source"] = src
	)

	var on_bus_damage = func(target: Node3D, src: Node3D, amt: int, _crit: bool, blk: bool) -> void:
		bus_tracker["damage_dealt_called"] = true
		bus_tracker["target"] = target
		bus_tracker["source"] = src
		bus_tracker["amount"] = amt
		bus_tracker["is_blocked"] = blk

	var on_bus_hp = func(ent: Node3D, c_hp: int, m_hp: int) -> void:
		if ent == parent_entity:
			bus_tracker["health_changed_called"] = true
			bus_tracker["bus_hp"] = c_hp
			bus_tracker["bus_max_hp"] = m_hp

	bus.damage_dealt.connect(on_bus_damage)
	bus.health_changed.connect(on_bus_hp)

	# Apply damage: raw 40, armor 10 (mitigates 10 -> dmg 30, blocked=true)
	var taken: int = h_sig.take_damage(40, 10, attacker_node)
	assert(taken == 30, "Damage taken should be 30")
	assert(local_tracker["health_changed_called"], "local health_changed signal emitted")
	assert(local_tracker["hp"] == 70 and local_tracker["max_hp"] == 100, "local health_changed values accurate")
	assert(local_tracker["damage_taken_called"], "local damage_taken signal emitted")
	assert(local_tracker["amount"] == 30 and local_tracker["is_blocked"] == true and local_tracker["source"] == attacker_node, "damage_taken payload accurate")

	assert(bus_tracker["damage_dealt_called"], "EventBus damage_dealt signal emitted")
	assert(bus_tracker["target"] == parent_entity and bus_tracker["source"] == attacker_node and bus_tracker["amount"] == 30 and bus_tracker["is_blocked"] == true, "EventBus damage_dealt payload accurate")
	assert(bus_tracker["health_changed_called"], "EventBus health_changed signal emitted")
	assert(bus_tracker["bus_hp"] == 70 and bus_tracker["bus_max_hp"] == 100, "EventBus health_changed payload accurate")
	print("PASS: 3.1 Local and EventBus signals correctly emitted on damage")

	bus.damage_dealt.disconnect(on_bus_damage)
	bus.health_changed.disconnect(on_bus_hp)

	# ----------------------------------------------------
	# Test Group 4: Death Transition & Single-Died Signal Guard
	# ----------------------------------------------------
	print("\n[Group 4: Death Transition & Single-Died Signal Guard]")
	var death_tracker: Dictionary = {
		"died_count": 0,
		"killer": null,
		"bus_died_count": 0,
		"bus_entity": null,
		"bus_killer": null
	}

	h_sig.died.connect(func(killer: Node3D) -> void:
		death_tracker["died_count"] += 1
		death_tracker["killer"] = killer
	)

	var on_bus_died = func(ent: Node3D, kil: Node3D) -> void:
		if ent == parent_entity:
			death_tracker["bus_died_count"] += 1
			death_tracker["bus_entity"] = ent
			death_tracker["bus_killer"] = kil

	bus.entity_died.connect(on_bus_died)

	# Deal fatal damage (HP is 70, hit with 999 raw, 0 armor)
	var fatal_dmg: int = h_sig.take_damage(999, 0, attacker_node)
	assert(fatal_dmg == 999, "Fatal damage dealt is 999")
	assert(h_sig.current_hp == 0, "Current HP should be 0")
	assert(h_sig.is_alive == false, "is_alive should be false after lethal damage")
	assert(death_tracker["died_count"] == 1, "Local died signal must be emitted exactly once")
	assert(death_tracker["killer"] == attacker_node, "Killer reference must match attacker")
	assert(death_tracker["bus_died_count"] == 1, "EventBus entity_died must be emitted exactly once")
	assert(death_tracker["bus_entity"] == parent_entity and death_tracker["bus_killer"] == attacker_node, "EventBus entity_died payload accurate")
	print("PASS: 4.1 Fatal damage transitions is_alive to false and emits died signals")

	# Overkill / Post-mortem damage test: Calling take_damage on already dead entity must return 0 and NOT emit died again
	var post_dmg: int = h_sig.take_damage(50, 0, attacker_node)
	assert(post_dmg == 0, "Damage on dead entity must return 0")
	assert(death_tracker["died_count"] == 1, "died signal MUST NOT be emitted again on dead entity")
	assert(death_tracker["bus_died_count"] == 1, "EventBus entity_died MUST NOT be emitted again on dead entity")
	print("PASS: 4.2 Post-mortem damage safely ignored and no duplicate died signals fired")

	bus.entity_died.disconnect(on_bus_died)
	h_sig.queue_free()
	parent_entity.queue_free()
	attacker_node.queue_free()

	# ----------------------------------------------------
	# Test Group 5: Healing & Overhealing
	# ----------------------------------------------------
	print("\n[Group 5: Healing & Overhealing]")
	var h_heal: HealthComponent = HealthComponent.new()
	h_heal.max_hp = 100
	h_heal.current_hp = 40
	h_heal.is_alive = true

	var healer_node: Node3D = Node3D.new()
	healer_node.name = "Cleric"
	root.add_child(healer_node)

	var heal_tracker: Dictionary = {
		"healed_called": false,
		"amount": 0,
		"healer": null,
		"bus_healed_called": false,
		"bus_amount": 0
	}

	h_heal.healed.connect(func(amt: int, hlr: Node3D) -> void:
		heal_tracker["healed_called"] = true
		heal_tracker["amount"] = amt
		heal_tracker["healer"] = hlr
	)

	var on_bus_heal = func(_tgt: Node3D, _hlr: Node3D, amt: int) -> void:
		heal_tracker["bus_healed_called"] = true
		heal_tracker["bus_amount"] = amt

	bus.healing_applied.connect(on_bus_heal)

	# 5.1 Partial heal: 40 + 35 = 75
	var healed_amt: int = h_heal.heal(35, healer_node)
	assert(healed_amt == 35, "heal should return actual healed amount 35")
	assert(h_heal.current_hp == 75, "current_hp should be 75")
	assert(heal_tracker["healed_called"], "healed signal emitted")
	assert(heal_tracker["amount"] == 35 and heal_tracker["healer"] == healer_node, "healed signal payload accurate")
	print("PASS: 5.1 Partial heal restores HP and emits healed signal")

	# 5.2 Overheal capped at max_hp: 75 + 50 = 100 (healed 25)
	var overheal_amt: int = h_heal.heal(50, healer_node)
	assert(overheal_amt == 25, "Overheal should return effective restored HP (25)")
	assert(h_heal.current_hp == 100, "current_hp capped at max_hp 100")
	print("PASS: 5.2 Overhealing properly capped at max_hp")

	# 5.3 Heal when already full HP: returns 0, no signal
	heal_tracker["healed_called"] = false
	var full_heal: int = h_heal.heal(20, healer_node)
	assert(full_heal == 0, "Heal on full HP returns 0")
	assert(not heal_tracker["healed_called"], "No signal emitted when effective heal is 0")
	print("PASS: 5.3 Healing on full HP returns 0 without emitting signal")

	# 5.4 Heal on dead entity: returns 0, no HP change
	h_heal.is_alive = false
	h_heal.current_hp = 0
	var dead_heal: int = h_heal.heal(50, healer_node)
	assert(dead_heal == 0, "Cannot heal a dead entity")
	assert(h_heal.current_hp == 0, "Dead entity HP remains 0")
	print("PASS: 5.4 Healing dead entity rejected safely")

	bus.healing_applied.disconnect(on_bus_heal)
	h_heal.free()
	healer_node.free()

	# ----------------------------------------------------
	# Test Group 6: Mana Consumption & Restoration
	# ----------------------------------------------------
	print("\n[Group 6: Mana Consumption & Restoration]")
	var h_mana: HealthComponent = HealthComponent.new()
	h_mana.max_mana = 100.0
	h_mana.current_mana = 60.0
	h_mana.is_alive = true

	var mana_tracker: Dictionary = {
		"mana_changed_called": false,
		"current": 0.0,
		"max": 0.0
	}

	h_mana.mana_changed.connect(func(c_m: float, m_m: float) -> void:
		mana_tracker["mana_changed_called"] = true
		mana_tracker["current"] = c_m
		mana_tracker["max"] = m_m
	)

	# 6.1 Successful consumption: 60 - 25 = 35
	var success_consume: bool = h_mana.consume_mana(25.0)
	assert(success_consume == true, "consume_mana(25.0) should succeed")
	assert(is_equal_approx(h_mana.current_mana, 35.0), "current_mana should be 35.0")
	assert(mana_tracker["mana_changed_called"], "mana_changed emitted on consume")
	assert(is_equal_approx(mana_tracker["current"], 35.0) and is_equal_approx(mana_tracker["max"], 100.0), "mana_changed payload accurate")
	print("PASS: 6.1 Successful mana consumption")

	# 6.2 Insufficient mana: trying to consume 50 when only 35 available
	mana_tracker["mana_changed_called"] = false
	var fail_consume: bool = h_mana.consume_mana(50.0)
	assert(fail_consume == false, "consume_mana(50.0) should fail due to lack of mana")
	assert(is_equal_approx(h_mana.current_mana, 35.0), "current_mana remains 35.0 on failed consume")
	assert(not mana_tracker["mana_changed_called"], "mana_changed should NOT be emitted on failed consume")
	print("PASS: 6.2 Insufficient mana consumption handled properly")

	# 6.3 Restore mana: 35 + 20 = 55
	mana_tracker["mana_changed_called"] = false
	var restored: float = h_mana.restore_mana(20.0)
	assert(is_equal_approx(restored, 20.0), "restore_mana should return 20.0")
	assert(is_equal_approx(h_mana.current_mana, 55.0), "current_mana should be 55.0")
	assert(mana_tracker["mana_changed_called"], "mana_changed emitted on restore")
	print("PASS: 6.3 Mana restored successfully")

	# 6.4 Over-restoration capped at max_mana: 55 + 100 = 100 (restored 45)
	var over_restore: float = h_mana.restore_mana(100.0)
	assert(is_equal_approx(over_restore, 45.0), "restore_mana capped at max_mana returned effective 45.0")
	assert(is_equal_approx(h_mana.current_mana, 100.0), "current_mana capped at 100.0")
	print("PASS: 6.4 Mana restoration capped at max_mana")

	# 6.5 Consume and restore on dead entity
	h_mana.is_alive = false
	assert(h_mana.consume_mana(10.0) == false, "Dead entity cannot consume mana")
	assert(is_equal_approx(h_mana.restore_mana(10.0), 0.0), "Dead entity cannot restore mana")
	print("PASS: 6.5 Mana operations rejected on dead entity")
	h_mana.free()

	# ----------------------------------------------------
	# Test Group 7: Out-of-Combat (OOC) Mana Regeneration (5% every 2.0s)
	# ----------------------------------------------------
	print("\n[Group 7: Out-of-Combat (OOC) Mana Regeneration]")
	var h_ooc: HealthComponent = HealthComponent.new()
	h_ooc.max_mana = 100.0
	h_ooc.current_mana = 0.0
	h_ooc.is_alive = true
	h_ooc.in_combat = false

	# 7.1 Advancing delta < 2.0s should not tick regen
	h_ooc._process_ooc_mana_regen(1.0)
	assert(is_equal_approx(h_ooc.current_mana, 0.0), "Mana should remain 0.0 after 1.0s")
	h_ooc._process_ooc_mana_regen(0.5)
	assert(is_equal_approx(h_ooc.current_mana, 0.0), "Mana should remain 0.0 after 1.5s cumulative")
	print("PASS: 7.1 Mana does not regenerate before 2.0s threshold")

	# 7.2 Advancing remaining 0.5s (total 2.0s) triggers 5% of max_mana (5.0)
	h_ooc._process_ooc_mana_regen(0.5)
	assert(is_equal_approx(h_ooc.current_mana, 5.0), "Mana should be 5.0 after reaching 2.0s threshold, got: " + str(h_ooc.current_mana))
	print("PASS: 7.2 Mana regenerated by 5% (5.0) at 2.0s threshold")

	# 7.3 Another full 2.0s tick adds another 5% (5.0 -> 10.0)
	h_ooc._process_ooc_mana_regen(2.0)
	assert(is_equal_approx(h_ooc.current_mana, 10.0), "Mana should be 10.0 after second 2.0s tick, got: " + str(h_ooc.current_mana))
	print("PASS: 7.3 Subsequent 2.0s tick adds another 5%")

	# 7.4 In-combat halts regen and resets timer
	h_ooc.set_in_combat(true)
	assert(h_ooc.in_combat == true, "in_combat should be true")
	# Simulate _physics_process
	h_ooc._physics_process(2.0)
	assert(is_equal_approx(h_ooc.current_mana, 10.0), "Mana should NOT regenerate while in combat")
	print("PASS: 7.4 In-combat halts OOC mana regeneration")

	# 7.5 Leaving combat resumes timer from zero
	h_ooc.set_in_combat(false)
	h_ooc._physics_process(1.5)
	assert(is_equal_approx(h_ooc.current_mana, 10.0), "Timer restarted from 0; 1.5s not enough for tick")
	h_ooc._physics_process(0.5)
	assert(is_equal_approx(h_ooc.current_mana, 15.0), "Tick triggers at 2.0s after leaving combat")
	print("PASS: 7.5 Leaving combat resumes OOC mana regen cleanly")

	# 7.6 Dead entity does not regenerate mana
	h_ooc.is_alive = false
	h_ooc._physics_process(2.0)
	assert(is_equal_approx(h_ooc.current_mana, 15.0), "Dead entity does not regenerate mana")
	print("PASS: 7.6 Dead entity does not regenerate mana")

	# 7.7 Mana regen caps cleanly at max_mana
	h_ooc.is_alive = true
	h_ooc.current_mana = 98.0
	h_ooc._physics_process(2.0)
	assert(is_equal_approx(h_ooc.current_mana, 100.0), "Mana capped at max_mana 100.0 without exceeding")
	print("PASS: 7.7 OOC mana regen smoothly caps at max_mana")
	h_ooc.free()

	# ----------------------------------------------------
	# Test Group 8: setup(StatsComponent) Initialization
	# ----------------------------------------------------
	print("\n[Group 8: setup(StatsComponent) Initialization]")
	var stats: StatsComponent = StatsComponent.new()
	var bromm_res: HeroData = load("res://src/data/heroes/resources/hero_bromm.tres") as HeroData
	stats.initialize_from_hero_data(bromm_res)

	var h_setup: HealthComponent = HealthComponent.new()
	h_setup.setup(stats)

	assert(h_setup.max_hp == 160, "max_hp should be 160 from Bromm stats")
	assert(h_setup.current_hp == 160, "current_hp initialized to max_hp (160)")
	assert(is_equal_approx(h_setup.max_mana, 50.0), "max_mana should be 50.0 from Bromm stats")
	assert(is_equal_approx(h_setup.current_mana, 50.0), "current_mana initialized to max_mana (50.0)")
	assert(h_setup.is_alive == true, "is_alive initialized to true")
	print("PASS: 8.1 HealthComponent successfully populated via setup(StatsComponent)")

	h_setup.free()
	stats.free()

	print("\n========================================")
	print("=== ALL HEALTHCOMPONENT UNIT TESTS PASSED (8/8 GROUPS) ===")
	print("========================================")
	quit(0)
