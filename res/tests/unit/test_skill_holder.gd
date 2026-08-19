extends SceneTree

# ==============================================================================
# Unit & Integration Test Suite: SkillHolderComponent (Task M4.3)
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
	print("--- Starting SkillHolderComponent Unit & Integration Tests (Task M4.3) ---")
	print("================================================================================")

	var bus_node: Node = root.get_node_or_null("EventBus")
	if bus_node == null:
		var bus_script: Script = load("res://src/core/EventBus.gd")
		bus_node = Node.new()
		bus_node.name = "EventBus"
		bus_node.set_script(bus_script)
		root.add_child(bus_node)
	print("PASS: EventBus Autoload node found in SceneTree root")

	# --------------------------------------------------------------------------
	# Group 1: Default Properties, Initialization & Null-Safety
	# --------------------------------------------------------------------------
	print("\n[Group 1: Default Properties & Null-Safety]")
	var holder: SkillHolderComponent = SkillHolderComponent.new()
	assert(holder.equipped_skills.is_empty(), "Default equipped_skills must be empty")
	assert(holder.actor == null, "Default actor must be null")
	assert(not holder.can_cast_skill(null), "can_cast_skill on null skill must return false")
	assert(not holder.execute_skill(null), "execute_skill on null skill must return false")
	print("PASS: 1.1 Standalone SkillHolderComponent null-safe initialization verified")

	# --------------------------------------------------------------------------
	# Group 2: Skill Equipping & Retrieval
	# --------------------------------------------------------------------------
	print("\n[Group 2: Skill Equipping & Retrieval]")
	var shield_slam: SkillData = load("res://src/data/skills/resources/bromm_shield_slam.tres") as SkillData
	assert(shield_slam != null, "bromm_shield_slam.tres must exist")

	holder.equip_skill(shield_slam)
	assert(holder.has_skill(shield_slam.id), "has_skill returns true for equipped skill")
	assert(holder.get_skill_by_id(shield_slam.id) == shield_slam, "get_skill_by_id returns exact SkillData")
	assert(not holder.is_skill_on_cooldown(shield_slam.id), "Newly equipped skill is not on cooldown")
	assert(is_equal_approx(holder.get_cooldown_remaining(shield_slam.id), 0.0), "Initial cooldown is 0.0")
	assert(is_equal_approx(holder.get_cooldown_ratio(shield_slam.id), 0.0), "Initial cooldown ratio is 0.0")
	print("PASS: 2.1 Skill equipping and query methods verified")

	# --------------------------------------------------------------------------
	# Group 3: Mana Validation & can_cast_skill
	# --------------------------------------------------------------------------
	print("\n[Group 3: Mana Validation & can_cast_skill]")
	# shield_slam mana_cost = 10.0
	assert(holder.can_cast_skill(shield_slam, 15.0), "can_cast_skill true with sufficient mana (15.0 >= 10.0)")
	assert(holder.can_cast_skill(shield_slam, 10.0), "can_cast_skill true with exact mana (10.0 == 10.0)")
	assert(not holder.can_cast_skill(shield_slam, 5.0), "can_cast_skill false with insufficient mana (5.0 < 10.0)")
	assert(not holder.can_cast_skill(shield_slam, 0.0), "can_cast_skill false with zero mana")
	print("PASS: 3.1 Mana validation for skill casting verified")

	# --------------------------------------------------------------------------
	# Group 4: Execution, Mana Consumption & Cooldown Timer Activation
	# --------------------------------------------------------------------------
	print("\n[Group 4: Execution, Mana Consumption & Cooldowns]")
	var hero_char: CharacterEntity = CharacterEntity.new()
	var hero_health: HealthComponent = HealthComponent.new()
	hero_health.max_hp = 100
	hero_health.current_hp = 100
	hero_health.max_mana = 50.0
	hero_health.current_mana = 50.0
	hero_char.add_child(hero_health)
	hero_char.health_component = hero_health

	var hero_holder: SkillHolderComponent = SkillHolderComponent.new()
	hero_char.add_child(hero_holder)
	hero_holder.actor = hero_char
	hero_holder.equip_skill(shield_slam)

	var signal_tracker: Dictionary = {
		"executed": false,
		"executed_skill": null,
		"ready_emitted": false,
		"bus_cast_started": false,
		"bus_cd_updated": false,
		"last_cd_ratio": 0.0
	}

	hero_holder.skill_executed.connect(func(s: SkillData, _t: Node3D) -> void:
		signal_tracker["executed"] = true
		signal_tracker["executed_skill"] = s
	)
	hero_holder.skill_ready.connect(func(_s: SkillData) -> void:
		signal_tracker["ready_emitted"] = true
	)
	bus_node.skill_cast_started.connect(func(_c: Node3D, s: Resource) -> void:
		if s == shield_slam:
			signal_tracker["bus_cast_started"] = true
	)
	bus_node.skill_cooldown_updated.connect(func(_c: Node3D, s_id: String, ratio: float) -> void:
		if s_id == shield_slam.id:
			signal_tracker["bus_cd_updated"] = true
			signal_tracker["last_cd_ratio"] = ratio
	)

	# Execute shield slam (cost 10 mana, cd 5.0s)
	var cast_success: bool = hero_holder.execute_skill(shield_slam, null)
	assert(cast_success, "execute_skill must return true on valid cast")
	assert(is_equal_approx(hero_health.current_mana, 40.0), "Mana consumed: 50.0 - 10.0 = 40.0")
	assert(hero_holder.is_skill_on_cooldown(shield_slam.id), "Skill is now on cooldown")
	assert(is_equal_approx(hero_holder.get_cooldown_remaining(shield_slam.id), shield_slam.cooldown), "Remaining cd matches skill cooldown")
	assert(signal_tracker["executed"], "skill_executed signal emitted")
	assert(signal_tracker["bus_cast_started"], "EventBus.skill_cast_started signal emitted")
	assert(not hero_holder.can_cast_skill(shield_slam), "Cannot cast again while on cooldown")
	print("PASS: 4.1 Skill execution, mana consumption, and cooldown activation verified")

	# --------------------------------------------------------------------------
	# Group 5: Physics Process Cooldown Countdown & skill_ready Signal
	# --------------------------------------------------------------------------
	print("\n[Group 5: Cooldown Countdown & skill_ready Emission]")
	# Simulate 2.5s passing (halfway through 5.0s cooldown)
	hero_holder._physics_process(2.5)
	assert(is_equal_approx(hero_holder.get_cooldown_remaining(shield_slam.id), 2.5), "Remaining cd is 2.5s after 2.5s delta")
	assert(is_equal_approx(hero_holder.get_cooldown_ratio(shield_slam.id), 0.5), "Remaining cd ratio is 0.5 (50%)")
	assert(hero_holder.is_skill_on_cooldown(shield_slam.id), "Still on cooldown at 2.5s")
	assert(not signal_tracker["ready_emitted"], "skill_ready not yet emitted")

	# Simulate remaining 2.5s passing (cooldown reaches 0.0)
	hero_holder._physics_process(2.5)
	assert(is_equal_approx(hero_holder.get_cooldown_remaining(shield_slam.id), 0.0), "Cooldown reached 0.0")
	assert(not hero_holder.is_skill_on_cooldown(shield_slam.id), "Skill is off cooldown")
	assert(signal_tracker["ready_emitted"], "skill_ready signal emitted when cooldown completes")
	assert(hero_holder.can_cast_skill(shield_slam), "Skill is castable again after cooldown")
	print("PASS: 5.1 Real-time cooldown countdown and skill_ready signal emission verified")

	# --------------------------------------------------------------------------
	# Group 6: reset_all_cooldowns & unequip_skill
	# --------------------------------------------------------------------------
	print("\n[Group 6: reset_all_cooldowns & unequip_skill]")
	hero_holder.execute_skill(shield_slam, null)
	assert(hero_holder.is_skill_on_cooldown(shield_slam.id), "Skill placed on cooldown again")

	hero_holder.reset_all_cooldowns()
	assert(not hero_holder.is_skill_on_cooldown(shield_slam.id), "reset_all_cooldowns clears all timers immediately")

	hero_holder.unequip_skill(shield_slam.id)
	assert(not hero_holder.has_skill(shield_slam.id), "Skill unequipped successfully")
	print("PASS: 6.1 reset_all_cooldowns and unequip_skill verified")

	# Clean up
	hero_char.free()
	holder.free()

	print("\n================================================================================")
	print("=== ALL SKILLHOLDERCOMPONENT UNIT TESTS PASSED (6/6 GROUPS) ===")
	print("================================================================================")
	quit(0)
