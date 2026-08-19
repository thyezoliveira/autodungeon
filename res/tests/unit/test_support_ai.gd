extends SceneTree

# ==============================================================================
# Unit & Integration Test Suite: SupportAIController.gd (Task M4.6)
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
	print("--- Starting SupportAIController Unit & Integration Tests (Task M4.6) ---")
	print("================================================================================")

	# Ensure EventBus Autoload node is present in SceneTree root
	var bus_node: Node = root.get_node_or_null("EventBus")
	if bus_node == null:
		var bus_script: Script = load("res://src/core/EventBus.gd")
		bus_node = Node.new()
		bus_node.name = "EventBus"
		bus_node.set_script(bus_script)
		root.add_child(bus_node)
	print("PASS: EventBus Autoload node found in SceneTree root")

	# --------------------------------------------------------------------------
	# Group 1: Default Properties, Auto-Resolution & Null Safety
	# --------------------------------------------------------------------------
	print("\n[Group 1: Default Properties, Auto-Resolution & Null Safety]")
	var standalone_ai: SupportAIController = SupportAIController.new()
	root.add_child(standalone_ai)

	assert(standalone_ai != null, "SupportAIController instance created")
	assert(standalone_ai.actor == null, "Initial standalone actor is null")
	assert(is_equal_approx(standalone_ai.tank_heal_threshold, 0.80), "Default tank_heal_threshold is 0.80 (80%)")
	assert(is_equal_approx(standalone_ai.emergency_heal_threshold, 0.40), "Default emergency_heal_threshold is 0.40 (40%)")
	assert(is_equal_approx(standalone_ai.self_heal_threshold, 0.50), "Default self_heal_threshold is 0.50 (50%)")
	assert(is_equal_approx(standalone_ai.cast_range, 6.0), "Default cast_range is 6.0m")

	# Standalone execution on empty / null data without crashing
	standalone_ai.evaluate_combat_tactics(0.1, [], [])
	standalone_ai.evaluate_combat_tactics(0.1, [null], [null])
	assert(standalone_ai.get_living_heroes([]).is_empty(), "get_living_heroes on empty returns empty")
	assert(standalone_ai.get_living_enemies([]).is_empty(), "get_living_enemies on empty returns empty")
	assert(standalone_ai.find_tank_hero([]) == null, "find_tank_hero on empty returns null")
	assert(standalone_ai.find_critical_ally([]) == null, "find_critical_ally on empty returns null")
	assert(standalone_ai.find_nearest_enemy([]) == null, "find_nearest_enemy on empty returns null")
	assert(standalone_ai.get_distance_to_target(null) == INF, "get_distance_to_target null returns INF")
	assert(not standalone_ai.execute_quick_heal(null), "execute_quick_heal null returns false")
	assert(not standalone_ai.execute_faith_shield(null), "execute_faith_shield null returns false")
	assert(not standalone_ai.execute_self_heal(), "execute_self_heal with null actor returns false")
	assert(not standalone_ai.execute_smite(null), "execute_smite null returns false")

	standalone_ai.free()
	print("PASS: 1.1 Standalone SupportAIController properties and null safety verified")

	# --------------------------------------------------------------------------
	# Group 2: Priority 1 (Proteção do Tanque: Tanque HP < 80%)
	# --------------------------------------------------------------------------
	print("\n[Group 2: Priority 1 — Tank Protection (Tank HP < 80%)]")
	var support_2: CharacterEntity = CharacterEntity.new()
	support_2.name = "Beatrice_P1"
	root.add_child(support_2)

	var hp_supp_2: HealthComponent = HealthComponent.new()
	hp_supp_2.max_hp = 85
	hp_supp_2.current_hp = 85
	hp_supp_2.max_mana = 100.0
	hp_supp_2.current_mana = 100.0
	support_2.add_child(hp_supp_2)
	support_2.health_component = hp_supp_2

	var holder_2: SkillHolderComponent = SkillHolderComponent.new()
	support_2.add_child(holder_2)
	support_2.skill_holder = holder_2
	holder_2.setup(support_2)

	var ai_2: SupportAIController = SupportAIController.new()
	ai_2.actor = support_2
	support_2.add_child(ai_2)

	# Tank Bromm at 70% HP (70/100) -> Critical (< 80%)
	var tank_2: CharacterEntity = CharacterEntity.new()
	tank_2.name = "Bromm_Tank"
	root.add_child(tank_2)
	var hp_tank_2: HealthComponent = HealthComponent.new()
	hp_tank_2.max_hp = 100
	hp_tank_2.current_hp = 70 # 70% HP
	tank_2.add_child(hp_tank_2)
	tank_2.health_component = hp_tank_2

	# Ally Elysia at 100% HP
	var dps_2: CharacterEntity = CharacterEntity.new()
	dps_2.name = "Elysia_DPS"
	root.add_child(dps_2)
	var hp_dps_2: HealthComponent = HealthComponent.new()
	hp_dps_2.max_hp = 85
	hp_dps_2.current_hp = 85
	dps_2.add_child(hp_dps_2)
	dps_2.health_component = hp_dps_2

	# Mob enemy
	var mob_2: CharacterEntity = CharacterEntity.new()
	mob_2.name = "Mob_2"
	root.add_child(mob_2)
	var hp_mob_2: HealthComponent = HealthComponent.new()
	hp_mob_2.max_hp = 50
	hp_mob_2.current_hp = 50
	mob_2.add_child(hp_mob_2)
	mob_2.health_component = hp_mob_2

	var tracker_2: Dictionary = {
		"quick_heal_cast": false,
		"heal_target": null,
		"heal_amount": 0,
		"smite_cast": false,
		"shield_cast": false
	}
	ai_2.quick_heal_cast.connect(func(target: CharacterEntity, amount: int) -> void:
		tracker_2["quick_heal_cast"] = true
		tracker_2["heal_target"] = target
		tracker_2["heal_amount"] = amount
	)
	ai_2.smite_cast.connect(func(_t: CharacterEntity, _d: int) -> void: tracker_2["smite_cast"] = true)
	ai_2.faith_shield_cast.connect(func(_t: CharacterEntity, _s: int) -> void: tracker_2["shield_cast"] = true)

	assert(ai_2.is_tank_critical(tank_2), "Tank at 70% HP is critical (ratio 0.70 < 0.80)")

	var party_2: Array[CharacterEntity] = [tank_2, dps_2, support_2]
	var enemies_2: Array[CharacterEntity] = [mob_2]

	ai_2.evaluate_combat_tactics(0.1, party_2, enemies_2)

	assert(tracker_2["quick_heal_cast"], "quick_heal_cast signal emitted for Tank")
	assert(tracker_2["heal_target"] == tank_2, "Heal target was Tank Bromm")
	assert(tracker_2["heal_amount"] > 0, "Heal amount was positive")
	assert(hp_tank_2.current_hp > 70, "Tank HP restored by Quick Heal")
	assert(not tracker_2["smite_cast"], "Smite was NOT cast when Tank needed healing")
	assert(not tracker_2["shield_cast"], "Faith Shield was NOT cast (P1 Quick Heal executed)")
	assert(holder_2.is_skill_on_cooldown("beatrice_quick_heal"), "Quick Heal skill is now on cooldown")

	print("PASS: 2.1 P1 Tank Protection (HP 70% < 80%) prioritizes Quick Heal on Tank")
	support_2.free()
	tank_2.free()
	dps_2.free()
	mob_2.free()

	# --------------------------------------------------------------------------
	# Group 3: Priority 2 (Emergência da Equipe: Aliado HP < 40%)
	# --------------------------------------------------------------------------
	print("\n[Group 3: Priority 2 — Team Emergency (Ally HP < 40%)]")
	var support_3: CharacterEntity = CharacterEntity.new()
	support_3.name = "Beatrice_P2"
	root.add_child(support_3)

	var hp_supp_3: HealthComponent = HealthComponent.new()
	hp_supp_3.max_hp = 85
	hp_supp_3.current_hp = 85
	hp_supp_3.max_mana = 100.0
	hp_supp_3.current_mana = 100.0
	support_3.add_child(hp_supp_3)
	support_3.health_component = hp_supp_3

	var holder_3: SkillHolderComponent = SkillHolderComponent.new()
	support_3.add_child(holder_3)
	support_3.skill_holder = holder_3
	holder_3.setup(support_3)

	var ai_3: SupportAIController = SupportAIController.new()
	ai_3.actor = support_3
	support_3.add_child(ai_3)

	# Tank Bromm is Healthy at 100% HP (100/100 >= 80%)
	var tank_3: CharacterEntity = CharacterEntity.new()
	tank_3.name = "Bromm_Tank"
	root.add_child(tank_3)
	var hp_tank_3: HealthComponent = HealthComponent.new()
	hp_tank_3.max_hp = 100
	hp_tank_3.current_hp = 100
	tank_3.add_child(hp_tank_3)
	tank_3.health_component = hp_tank_3

	# Ally Elysia in Critical State at 30% HP (30/100 < 40%)
	var dps_3: CharacterEntity = CharacterEntity.new()
	dps_3.name = "Elysia_DPS"
	root.add_child(dps_3)
	var hp_dps_3: HealthComponent = HealthComponent.new()
	hp_dps_3.max_hp = 100
	hp_dps_3.current_hp = 30 # 30% HP < 40%
	dps_3.add_child(hp_dps_3)
	dps_3.health_component = hp_dps_3

	var stats_dps_3: StatsComponent = StatsComponent.new()
	stats_dps_3.armor = 10
	dps_3.add_child(stats_dps_3)
	dps_3.stats_component = stats_dps_3

	var mob_3: CharacterEntity = CharacterEntity.new()
	mob_3.name = "Mob_3"
	root.add_child(mob_3)
	var hp_mob_3: HealthComponent = HealthComponent.new()
	hp_mob_3.max_hp = 50
	hp_mob_3.current_hp = 50
	mob_3.add_child(hp_mob_3)
	mob_3.health_component = hp_mob_3

	var tracker_3: Dictionary = {
		"shield_cast": false,
		"shield_target": null,
		"shield_amount": 0,
		"smite_cast": false
	}
	ai_3.faith_shield_cast.connect(func(target: CharacterEntity, amount: int) -> void:
		tracker_3["shield_cast"] = true
		tracker_3["shield_target"] = target
		tracker_3["shield_amount"] = amount
	)
	ai_3.smite_cast.connect(func(_t: CharacterEntity, _d: int) -> void: tracker_3["smite_cast"] = true)

	assert(not ai_3.is_tank_critical(tank_3), "Tank is not critical at 100% HP")
	assert(ai_3.find_critical_ally([tank_3, dps_3, support_3]) == dps_3, "Critical ally found is Elysia at 30% HP")

	var party_3: Array[CharacterEntity] = [tank_3, dps_3, support_3]
	var enemies_3: Array[CharacterEntity] = [mob_3]

	ai_3.evaluate_combat_tactics(0.1, party_3, enemies_3)

	assert(tracker_3["shield_cast"], "faith_shield_cast signal emitted for critical ally")
	assert(tracker_3["shield_target"] == dps_3, "Faith Shield target was Elysia")
	assert(tracker_3["shield_amount"] > 0, "Shield amount was positive")
	assert(not tracker_3["smite_cast"], "Smite was NOT cast when ally was in critical state")
	assert(holder_3.is_skill_on_cooldown("beatrice_faith_shield"), "Faith Shield is on cooldown")

	print("PASS: 3.1 P2 Team Emergency (Ally HP 30% < 40%) casts Faith Shield on critical ally")
	support_3.free()
	tank_3.free()
	dps_3.free()
	mob_3.free()

	# --------------------------------------------------------------------------
	# Group 4: Priority 3 (Autoconservação: Auto HP < 50%)
	# --------------------------------------------------------------------------
	print("\n[Group 4: Priority 3 — Self-Preservation (Self HP < 50%)]")
	var support_4: CharacterEntity = CharacterEntity.new()
	support_4.name = "Beatrice_P3"
	root.add_child(support_4)

	var hp_supp_4: HealthComponent = HealthComponent.new()
	hp_supp_4.max_hp = 100
	hp_supp_4.current_hp = 40 # 40% HP < 50%
	hp_supp_4.max_mana = 100.0
	hp_supp_4.current_mana = 100.0
	support_4.add_child(hp_supp_4)
	support_4.health_component = hp_supp_4

	var holder_4: SkillHolderComponent = SkillHolderComponent.new()
	support_4.add_child(holder_4)
	support_4.skill_holder = holder_4
	holder_4.setup(support_4)

	var ai_4: SupportAIController = SupportAIController.new()
	ai_4.actor = support_4
	support_4.add_child(ai_4)

	# Tank Bromm is Healthy at 100% HP
	var tank_4: CharacterEntity = CharacterEntity.new()
	tank_4.name = "Bromm_Tank"
	root.add_child(tank_4)
	var hp_tank_4: HealthComponent = HealthComponent.new()
	hp_tank_4.max_hp = 100
	hp_tank_4.current_hp = 100
	tank_4.add_child(hp_tank_4)
	tank_4.health_component = hp_tank_4

	# Ally Elysia is Healthy at 100% HP
	var dps_4: CharacterEntity = CharacterEntity.new()
	dps_4.name = "Elysia_DPS"
	root.add_child(dps_4)
	var hp_dps_4: HealthComponent = HealthComponent.new()
	hp_dps_4.max_hp = 100
	hp_dps_4.current_hp = 100
	dps_4.add_child(hp_dps_4)
	dps_4.health_component = hp_dps_4

	var mob_4: CharacterEntity = CharacterEntity.new()
	mob_4.name = "Mob_4"
	root.add_child(mob_4)
	var hp_mob_4: HealthComponent = HealthComponent.new()
	hp_mob_4.max_hp = 50
	hp_mob_4.current_hp = 50
	mob_4.add_child(hp_mob_4)
	mob_4.health_component = hp_mob_4

	var tracker_4: Dictionary = {
		"self_heal_cast": false,
		"self_amount": 0,
		"smite_cast": false
	}
	ai_4.self_heal_cast.connect(func(amount: int) -> void:
		tracker_4["self_heal_cast"] = true
		tracker_4["self_amount"] = amount
	)
	ai_4.smite_cast.connect(func(_t: CharacterEntity, _d: int) -> void: tracker_4["smite_cast"] = true)

	assert(ai_4.is_self_critical(), "Beatrice is self-critical at 40% HP (< 50%)")

	var party_4: Array[CharacterEntity] = [tank_4, dps_4, support_4]
	var enemies_4: Array[CharacterEntity] = [mob_4]

	ai_4.evaluate_combat_tactics(0.1, party_4, enemies_4)

	assert(tracker_4["self_heal_cast"], "self_heal_cast signal emitted")
	assert(tracker_4["self_amount"] > 0, "Self heal amount was positive")
	assert(hp_supp_4.current_hp > 40, "Beatrice current HP restored")
	assert(not tracker_4["smite_cast"], "Smite was NOT cast during self-preservation")

	print("PASS: 4.1 P3 Self-Preservation (Self HP 40% < 50%) heals herself successfully")
	support_4.free()
	tank_4.free()
	dps_4.free()
	mob_4.free()

	# --------------------------------------------------------------------------
	# Group 5: Priority 4 (Suporte Ofensivo: Todos Aliados Saudáveis)
	# --------------------------------------------------------------------------
	print("\n[Group 5: Priority 4 — Offensive Support (All Allies Healthy)]")
	var support_5: CharacterEntity = CharacterEntity.new()
	support_5.name = "Beatrice_P4"
	root.add_child(support_5)
	support_5.global_position = Vector3(0.0, 0.0, 0.0)

	var hp_supp_5: HealthComponent = HealthComponent.new()
	hp_supp_5.max_hp = 100
	hp_supp_5.current_hp = 100
	hp_supp_5.max_mana = 100.0
	hp_supp_5.current_mana = 100.0
	support_5.add_child(hp_supp_5)
	support_5.health_component = hp_supp_5

	var holder_5: SkillHolderComponent = SkillHolderComponent.new()
	support_5.add_child(holder_5)
	support_5.skill_holder = holder_5
	holder_5.setup(support_5)

	var ai_5: SupportAIController = SupportAIController.new()
	ai_5.actor = support_5
	support_5.add_child(ai_5)

	# Tank Bromm at 100% HP
	var tank_5: CharacterEntity = CharacterEntity.new()
	tank_5.name = "Bromm_Tank"
	root.add_child(tank_5)
	var hp_tank_5: HealthComponent = HealthComponent.new()
	hp_tank_5.max_hp = 100
	hp_tank_5.current_hp = 100
	tank_5.add_child(hp_tank_5)
	tank_5.health_component = hp_tank_5

	# Ally Elysia at 100% HP
	var dps_5: CharacterEntity = CharacterEntity.new()
	dps_5.name = "Elysia_DPS"
	root.add_child(dps_5)
	var hp_dps_5: HealthComponent = HealthComponent.new()
	hp_dps_5.max_hp = 100
	hp_dps_5.current_hp = 100
	dps_5.add_child(hp_dps_5)
	dps_5.health_component = hp_dps_5

	# Target Mob at 4.0m
	var mob_5: CharacterEntity = CharacterEntity.new()
	mob_5.name = "Mob_Target"
	root.add_child(mob_5)
	mob_5.global_position = Vector3(4.0, 0.0, 0.0)
	var hp_mob_5: HealthComponent = HealthComponent.new()
	hp_mob_5.max_hp = 80
	hp_mob_5.current_hp = 80
	mob_5.add_child(hp_mob_5)
	mob_5.health_component = hp_mob_5

	var tracker_5: Dictionary = {
		"smite_cast": false,
		"smite_target": null,
		"smite_damage": 0,
		"quick_heal": false,
		"faith_shield": false
	}
	ai_5.smite_cast.connect(func(target: CharacterEntity, damage: int) -> void:
		tracker_5["smite_cast"] = true
		tracker_5["smite_target"] = target
		tracker_5["smite_damage"] = damage
	)
	ai_5.quick_heal_cast.connect(func(_t: CharacterEntity, _a: int) -> void: tracker_5["quick_heal"] = true)
	ai_5.faith_shield_cast.connect(func(_t: CharacterEntity, _a: int) -> void: tracker_5["faith_shield"] = true)

	assert(ai_5.are_all_allies_healthy([tank_5, dps_5, support_5]), "All allies are 100% healthy")

	var party_5: Array[CharacterEntity] = [tank_5, dps_5, support_5]
	var enemies_5: Array[CharacterEntity] = [mob_5]

	ai_5.evaluate_combat_tactics(0.1, party_5, enemies_5)

	assert(tracker_5["smite_cast"], "smite_cast signal emitted for enemy mob")
	assert(tracker_5["smite_target"] == mob_5, "Smite targeted mob_5")
	assert(tracker_5["smite_damage"] > 0, "Smite damage was positive")
	assert(hp_mob_5.current_hp < 80, "Mob took damage from Smite")
	assert(not tracker_5["quick_heal"], "No quick heal cast when party is healthy")
	assert(not tracker_5["faith_shield"], "No faith shield cast when party is healthy")
	assert(holder_5.is_skill_on_cooldown("beatrice_smite"), "beatrice_smite is now on cooldown")

	print("PASS: 5.1 P4 Offensive Support (All Allies Healthy) casts Smite on enemy")
	support_5.free()
	tank_5.free()
	dps_5.free()
	mob_5.free()

	# --------------------------------------------------------------------------
	# Group 6: Priority 4 — Focus on Tank Target vs Nearest Mob
	# --------------------------------------------------------------------------
	print("\n[Group 6: Priority 4 — Focus Target Selection (Tank Target vs Nearest)]")
	var support_6: CharacterEntity = CharacterEntity.new()
	support_6.name = "Beatrice_P6"
	root.add_child(support_6)
	support_6.global_position = Vector3(0.0, 0.0, 0.0)

	var hp_supp_6: HealthComponent = HealthComponent.new()
	hp_supp_6.max_hp = 100
	hp_supp_6.current_hp = 100
	hp_supp_6.max_mana = 100.0
	hp_supp_6.current_mana = 100.0
	support_6.add_child(hp_supp_6)
	support_6.health_component = hp_supp_6

	var holder_6: SkillHolderComponent = SkillHolderComponent.new()
	support_6.add_child(holder_6)
	support_6.skill_holder = holder_6
	holder_6.setup(support_6)

	var ai_6: SupportAIController = SupportAIController.new()
	ai_6.actor = support_6
	support_6.add_child(ai_6)

	var tank_6: CharacterEntity = CharacterEntity.new()
	tank_6.name = "Bromm_Tank"
	root.add_child(tank_6)
	var hp_tank_6: HealthComponent = HealthComponent.new()
	hp_tank_6.max_hp = 100
	hp_tank_6.current_hp = 100
	tank_6.add_child(hp_tank_6)
	tank_6.health_component = hp_tank_6

	# Mob A at 6.0m — has ThreatTable focusing on tank_6
	var mob_a: CharacterEntity = CharacterEntity.new()
	mob_a.name = "MobA_TankFocused"
	root.add_child(mob_a)
	mob_a.global_position = Vector3(6.0, 0.0, 0.0)
	var hp_a: HealthComponent = HealthComponent.new()
	hp_a.max_hp = 100
	hp_a.current_hp = 100
	mob_a.add_child(hp_a)
	mob_a.health_component = hp_a
	var threat_a: ThreatTable = ThreatTable.new()
	mob_a.add_child(threat_a)
	mob_a.threat_table = threat_a
	threat_a.add_threat(tank_6, 50.0, 1.0) # Primary target is tank_6

	# Mob B at 3.0m (Closer to Beatrice, but not tank-focused)
	var mob_b: CharacterEntity = CharacterEntity.new()
	mob_b.name = "MobB_Closer"
	root.add_child(mob_b)
	mob_b.global_position = Vector3(3.0, 0.0, 0.0)
	var hp_b: HealthComponent = HealthComponent.new()
	hp_b.max_hp = 100
	hp_b.current_hp = 100
	mob_b.add_child(hp_b)
	mob_b.health_component = hp_b

	var target_selected: CharacterEntity = ai_6.find_offensive_target(tank_6, [mob_a, mob_b])
	assert(target_selected == mob_a, "Offensive target prioritizes tank's engaged target (Mob A)")

	var tracker_6: Dictionary = {
		"smite_target": null
	}
	ai_6.smite_cast.connect(func(target: CharacterEntity, _d: int) -> void:
		tracker_6["smite_target"] = target
	)

	ai_6.evaluate_combat_tactics(0.1, [tank_6, support_6], [mob_a, mob_b])
	assert(tracker_6["smite_target"] == mob_a, "Smite was cast on tank-focused mob (Mob A)")

	print("PASS: 6.1 Offensive target prioritizes tank-engaged enemy over unengaged nearest enemy")
	support_6.free()
	tank_6.free()
	mob_a.free()
	mob_b.free()

	# --------------------------------------------------------------------------
	# Group 7: Strict Priority Hierarchy Resolution (P1 > P2 > P3 > P4)
	# --------------------------------------------------------------------------
	print("\n[Group 7: Strict Priority Hierarchy Resolution (P1 > P2 > P3 > P4)]")
	var support_7: CharacterEntity = CharacterEntity.new()
	support_7.name = "Beatrice_P7"
	root.add_child(support_7)

	var hp_supp_7: HealthComponent = HealthComponent.new()
	hp_supp_7.max_hp = 100
	hp_supp_7.current_hp = 40 # Self is wounded (< 50%)
	hp_supp_7.max_mana = 100.0
	hp_supp_7.current_mana = 100.0
	support_7.add_child(hp_supp_7)
	support_7.health_component = hp_supp_7

	var holder_7: SkillHolderComponent = SkillHolderComponent.new()
	support_7.add_child(holder_7)
	support_7.skill_holder = holder_7
	holder_7.setup(support_7)

	var ai_7: SupportAIController = SupportAIController.new()
	ai_7.actor = support_7
	support_7.add_child(ai_7)

	# Tank is at 70% HP (< 80%) -> P1
	var tank_7: CharacterEntity = CharacterEntity.new()
	tank_7.name = "Bromm_Tank"
	root.add_child(tank_7)
	var hp_tank_7: HealthComponent = HealthComponent.new()
	hp_tank_7.max_hp = 100
	hp_tank_7.current_hp = 70 # 70% HP
	tank_7.add_child(hp_tank_7)
	tank_7.health_component = hp_tank_7

	# Ally is at 30% HP (< 40%) -> P2
	var dps_7: CharacterEntity = CharacterEntity.new()
	dps_7.name = "Elysia_DPS"
	root.add_child(dps_7)
	var hp_dps_7: HealthComponent = HealthComponent.new()
	hp_dps_7.max_hp = 100
	hp_dps_7.current_hp = 30 # 30% HP
	dps_7.add_child(hp_dps_7)
	dps_7.health_component = hp_dps_7

	var mob_7: CharacterEntity = CharacterEntity.new()
	mob_7.name = "Mob_7"
	root.add_child(mob_7)
	var hp_mob_7: HealthComponent = HealthComponent.new()
	hp_mob_7.max_hp = 50
	hp_mob_7.current_hp = 50
	mob_7.add_child(hp_mob_7)
	mob_7.health_component = hp_mob_7

	var tracker_7: Dictionary = {
		"action": ""
	}
	ai_7.quick_heal_cast.connect(func(target: CharacterEntity, _a: int) -> void:
		if target == tank_7:
			tracker_7["action"] = "heal_tank"
		elif target == support_7:
			tracker_7["action"] = "self_heal"
		else:
			tracker_7["action"] = "heal_ally"
	)
	ai_7.faith_shield_cast.connect(func(_t: CharacterEntity, _s: int) -> void: tracker_7["action"] = "shield_ally")
	ai_7.smite_cast.connect(func(_t: CharacterEntity, _d: int) -> void: tracker_7["action"] = "smite")

	# Even though Ally is critical (30%) and Self is wounded (40%), P1 Tank Protection MUST execute first!
	ai_7.evaluate_combat_tactics(0.1, [tank_7, dps_7, support_7], [mob_7])
	assert(tracker_7["action"] == "heal_tank", "P1 Tank Protection takes precedence over P2, P3, and P4")

	print("PASS: 7.1 Strict priority hierarchy P1 > P2 > P3 > P4 verified under competing demands")
	support_7.free()
	tank_7.free()
	dps_7.free()
	mob_7.free()

	# --------------------------------------------------------------------------
	# Group 8: Offensive Mana Block When Allies Need Vital Healing
	# --------------------------------------------------------------------------
	print("\n[Group 8: Offensive Mana Block When Allies Need Vital Healing]")
	var support_8: CharacterEntity = CharacterEntity.new()
	support_8.name = "Beatrice_P8"
	root.add_child(support_8)

	var hp_supp_8: HealthComponent = HealthComponent.new()
	hp_supp_8.max_hp = 100
	hp_supp_8.current_hp = 100
	hp_supp_8.max_mana = 100.0
	hp_supp_8.current_mana = 100.0
	support_8.add_child(hp_supp_8)
	support_8.health_component = hp_supp_8

	var holder_8: SkillHolderComponent = SkillHolderComponent.new()
	support_8.add_child(holder_8)
	support_8.skill_holder = holder_8
	holder_8.setup(support_8)

	var ai_8: SupportAIController = SupportAIController.new()
	ai_8.actor = support_8
	support_8.add_child(ai_8)

	# Tank is wounded at 60% HP (< 80%), needing vital healing
	var tank_8: CharacterEntity = CharacterEntity.new()
	tank_8.name = "Bromm_Tank"
	root.add_child(tank_8)
	var hp_tank_8: HealthComponent = HealthComponent.new()
	hp_tank_8.max_hp = 100
	hp_tank_8.current_hp = 60
	tank_8.add_child(hp_tank_8)
	tank_8.health_component = hp_tank_8

	var mob_8: CharacterEntity = CharacterEntity.new()
	mob_8.name = "Mob_8"
	root.add_child(mob_8)
	var hp_mob_8: HealthComponent = HealthComponent.new()
	hp_mob_8.max_hp = 50
	hp_mob_8.current_hp = 50
	mob_8.add_child(hp_mob_8)
	mob_8.health_component = hp_mob_8

	var tracker_8: Dictionary = {
		"smite_fired": false,
		"heal_fired": false
	}
	ai_8.smite_cast.connect(func(_t: CharacterEntity, _d: int) -> void: tracker_8["smite_fired"] = true)
	ai_8.quick_heal_cast.connect(func(_t: CharacterEntity, _a: int) -> void: tracker_8["heal_fired"] = true)

	# Put healing skills on cooldown manually to simulate cooldown waiting state
	ai_8._load_default_skills_if_needed()
	holder_8._cooldown_timers["beatrice_quick_heal"] = 5.0
	holder_8._cooldown_timers["beatrice_faith_shield"] = 10.0

	assert(not ai_8.can_cast_quick_heal(), "Quick Heal is on cooldown")
	assert(not ai_8.can_cast_faith_shield(), "Faith Shield is on cooldown")
	assert(ai_8.can_cast_smite(), "Smite skill is theoretically ready")
	assert(ai_8.has_vital_healing_need([tank_8, support_8]), "Vital healing need is TRUE")

	# Evaluate tactics: Tank is wounded, healing is on CD -> Beatrice must NOT waste mana on Smite!
	ai_8.evaluate_combat_tactics(0.1, [tank_8, support_8], [mob_8])

	assert(not tracker_8["smite_fired"], "Beatrice blocked offensive Smite because Tank needs vital healing")
	assert(not tracker_8["heal_fired"], "No heal fired (skills on CD)")

	print("PASS: 8.1 Offensive mana block prevents spending mana on offense when allies need vital healing")
	support_8.free()
	tank_8.free()
	mob_8.free()

	# --------------------------------------------------------------------------
	# Group 9: Dead Entities, Empty Packs & Robust Edge Cases
	# --------------------------------------------------------------------------
	print("\n[Group 9: Dead Entities, Empty Packs & Robust Edge Cases]")
	var support_9: CharacterEntity = CharacterEntity.new()
	support_9.name = "Beatrice_P9"
	root.add_child(support_9)

	var ai_9: SupportAIController = SupportAIController.new()
	ai_9.actor = support_9
	support_9.add_child(ai_9)

	var dead_tank: CharacterEntity = CharacterEntity.new()
	root.add_child(dead_tank)
	var hp_dead_tank: HealthComponent = HealthComponent.new()
	hp_dead_tank.is_alive = false
	hp_dead_tank.current_hp = 0
	dead_tank.add_child(hp_dead_tank)
	dead_tank.health_component = hp_dead_tank

	var dead_mob: CharacterEntity = CharacterEntity.new()
	root.add_child(dead_mob)
	var hp_dead_mob: HealthComponent = HealthComponent.new()
	hp_dead_mob.is_alive = false
	hp_dead_mob.current_hp = 0
	dead_mob.add_child(hp_dead_mob)
	dead_mob.health_component = hp_dead_mob

	var tracker_9: Dictionary = {
		"heal_count": 0,
		"shield_count": 0,
		"smite_count": 0
	}
	ai_9.quick_heal_cast.connect(func(_t: CharacterEntity, _a: int) -> void: tracker_9["heal_count"] += 1)
	ai_9.faith_shield_cast.connect(func(_t: CharacterEntity, _s: int) -> void: tracker_9["shield_count"] += 1)
	ai_9.smite_cast.connect(func(_t: CharacterEntity, _d: int) -> void: tracker_9["smite_count"] += 1)

	# Evaluate with dead/null entities
	ai_9.evaluate_combat_tactics(0.1, [null, dead_tank, null], [null, dead_mob, null])

	assert(tracker_9["heal_count"] == 0, "No heal fired on dead entities")
	assert(tracker_9["shield_count"] == 0, "No shield fired on dead entities")
	assert(tracker_9["smite_count"] == 0, "No smite fired on dead entities")

	print("PASS: 9.1 Dead entities and null arrays handled safely without erroneous actions")
	support_9.free()
	dead_tank.free()
	dead_mob.free()

	print("\n================================================================================")
	print("=== ALL SUPPORT AI CONTROLLER UNIT TESTS PASSED (9/9 GROUPS) ===")
	print("================================================================================")
	quit(0)
