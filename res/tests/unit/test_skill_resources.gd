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
	print("--- Starting Skill Resources Unit Tests ---")
	print("========================================")

	# ----------------------------------------------------
	# Test Group 1: SkillEffect base class & TargetType enum
	# ----------------------------------------------------
	print("\n[Group 1: SkillEffect Base Class & Enums]")
	var base_effect: SkillEffect = SkillEffect.new()
	assert(base_effect != null, "SkillEffect instance must be created")
	assert(base_effect.target_type == SkillEffect.TargetType.ENEMY_SINGLE, "Default target_type should be ENEMY_SINGLE")
	assert(base_effect.value_base == 10, "Default value_base should be 10")
	assert(is_equal_approx(base_effect.stat_scaling_factor, 0.5), "Default stat_scaling_factor should be 0.5")
	assert(is_equal_approx(base_effect.duration, 0.0), "Default duration should be 0.0")
	print("PASS: 1.1 SkillEffect default values")

	# Enum values check
	assert(SkillEffect.TargetType.ENEMY_SINGLE == 0, "TargetType.ENEMY_SINGLE enum index mismatch")
	assert(SkillEffect.TargetType.ENEMY_AREA == 1, "TargetType.ENEMY_AREA enum index mismatch")
	assert(SkillEffect.TargetType.ALLY_SINGLE == 2, "TargetType.ALLY_SINGLE enum index mismatch")
	assert(SkillEffect.TargetType.ALLY_LOWEST_HP == 3, "TargetType.ALLY_LOWEST_HP enum index mismatch")
	assert(SkillEffect.TargetType.ALLY_ALL == 4, "TargetType.ALLY_ALL enum index mismatch")
	assert(SkillEffect.TargetType.SELF == 5, "TargetType.SELF enum index mismatch")
	print("PASS: 1.2 SkillEffect TargetType enum complete")

	# Custom properties assignment & virtual method invocation
	base_effect.target_type = SkillEffect.TargetType.ALLY_LOWEST_HP
	base_effect.value_base = 45
	base_effect.stat_scaling_factor = 1.25
	base_effect.duration = 6.0
	assert(base_effect.target_type == SkillEffect.TargetType.ALLY_LOWEST_HP, "Custom target_type applied")
	assert(base_effect.value_base == 45, "Custom value_base applied")
	assert(is_equal_approx(base_effect.stat_scaling_factor, 1.25), "Custom stat_scaling_factor applied")
	assert(is_equal_approx(base_effect.duration, 6.0), "Custom duration applied")

	var dummy_caster: Node3D = Node3D.new()
	var dummy_target: Node3D = Node3D.new()
	base_effect.apply_effect(dummy_caster, dummy_target)
	print("PASS: 1.3 SkillEffect custom properties and virtual apply_effect")

	# ----------------------------------------------------
	# Test Group 2: DamageSkillEffect inheritance & specialization
	# ----------------------------------------------------
	print("\n[Group 2: DamageSkillEffect Subclass]")
	var dmg_effect: DamageSkillEffect = DamageSkillEffect.new()
	assert(dmg_effect != null, "DamageSkillEffect instance must be created")
	assert(dmg_effect is SkillEffect, "DamageSkillEffect must inherit from SkillEffect")
	assert(dmg_effect.is_physical == true, "Default is_physical should be true")
	assert(is_equal_approx(dmg_effect.threat_multiplier, 1.0), "Default threat_multiplier should be 1.0")
	assert(dmg_effect.target_type == SkillEffect.TargetType.ENEMY_SINGLE, "Inherited target_type should be ENEMY_SINGLE")
	assert(dmg_effect.value_base == 10, "Inherited default value_base should be 10")
	print("PASS: 2.1 DamageSkillEffect inheritance and defaults")

	dmg_effect.is_physical = false
	dmg_effect.threat_multiplier = 2.5
	dmg_effect.value_base = 80
	dmg_effect.stat_scaling_factor = 0.85
	assert(dmg_effect.is_physical == false, "Custom is_physical applied")
	assert(is_equal_approx(dmg_effect.threat_multiplier, 2.5), "Custom threat_multiplier applied")
	assert(dmg_effect.value_base == 80, "Custom value_base applied")
	assert(is_equal_approx(dmg_effect.stat_scaling_factor, 0.85), "Custom stat_scaling_factor applied")

	dmg_effect.apply_effect(dummy_caster, dummy_target)
	print("PASS: 2.2 DamageSkillEffect custom properties and apply_effect")

	# ----------------------------------------------------
	# Test Group 3: SkillData resource definition & effects array
	# ----------------------------------------------------
	print("\n[Group 3: SkillData Resource Structure]")
	var skill: SkillData = SkillData.new()
	assert(skill != null, "SkillData instance must be created")
	assert(skill.id == "", "Default id should be empty")
	assert(skill.display_name == "", "Default display_name should be empty")
	assert(skill.description == "", "Default description should be empty")
	assert(skill.icon == null, "Default icon should be null")
	assert(is_equal_approx(skill.mana_cost, 15.0), "Default mana_cost should be 15.0")
	assert(is_equal_approx(skill.cooldown, 6.0), "Default cooldown should be 6.0")
	assert(is_equal_approx(skill.cast_time, 0.0), "Default cast_time should be 0.0")
	assert(is_equal_approx(skill.range_meters, 4.0), "Default range_meters should be 4.0")
	assert(skill.effects is Array[SkillEffect], "effects must be typed Array[SkillEffect]")
	assert(skill.effects.size() == 0, "Default effects array should be empty")
	print("PASS: 3.1 SkillData default properties")

	skill.id = "fireball"
	skill.display_name = "Bola de Fogo"
	skill.description = "Lança uma esfera flamejante contra o alvo."
	skill.mana_cost = 25.0
	skill.cooldown = 4.5
	skill.cast_time = 0.8
	skill.range_meters = 12.0

	var effect1: DamageSkillEffect = DamageSkillEffect.new()
	effect1.value_base = 50
	effect1.is_physical = false

	var effect2: SkillEffect = SkillEffect.new()
	effect2.target_type = SkillEffect.TargetType.ENEMY_AREA
	effect2.duration = 3.0
	effect2.value_base = 15

	skill.effects.append(effect1)
	skill.effects.append(effect2)

	assert(skill.id == "fireball", "Custom id applied")
	assert(skill.display_name == "Bola de Fogo", "Custom display_name applied")
	assert(skill.description == "Lança uma esfera flamejante contra o alvo.", "Custom description applied")
	assert(is_equal_approx(skill.mana_cost, 25.0), "Custom mana_cost applied")
	assert(is_equal_approx(skill.cooldown, 4.5), "Custom cooldown applied")
	assert(is_equal_approx(skill.cast_time, 0.8), "Custom cast_time applied")
	assert(is_equal_approx(skill.range_meters, 12.0), "Custom range_meters applied")
	assert(skill.effects.size() == 2, "Multiple effects successfully assigned")
	assert(skill.effects[0] is DamageSkillEffect, "First effect is DamageSkillEffect")
	assert(skill.effects[1] is SkillEffect, "Second effect is SkillEffect")
	print("PASS: 3.2 SkillData custom properties and polymorphic effects array")

	# ----------------------------------------------------
	# Test Group 4: bromm_shield_slam.tres Resource file loading & integrity
	# ----------------------------------------------------
	print("\n[Group 4: bromm_shield_slam.tres Verification]")
	var tres_path: String = "res://src/data/skills/bromm_shield_slam.tres"
	assert(ResourceLoader.exists(tres_path), "Resource file bromm_shield_slam.tres must exist on disk")

	var loaded_res: Resource = ResourceLoader.load(tres_path)
	assert(loaded_res != null, "bromm_shield_slam.tres must load successfully")
	assert(loaded_res is SkillData, "Loaded resource must be an instance of SkillData")

	var shield_slam: SkillData = loaded_res as SkillData
	assert(shield_slam.id == "bromm_shield_slam", "Skill ID must be 'bromm_shield_slam'")
	assert(shield_slam.display_name == "Golpe de Escudo", "Display name must be 'Golpe de Escudo'")
	assert(is_equal_approx(shield_slam.mana_cost, 10.0), "Mana cost must be 10.0")
	assert(is_equal_approx(shield_slam.cooldown, 5.0), "Cooldown must be 5.0")
	assert(is_equal_approx(shield_slam.range_meters, 4.0), "Range meters must be 4.0")
	assert(shield_slam.effects.size() == 1, "Must contain exactly 1 effect")

	var slam_effect: SkillEffect = shield_slam.effects[0]
	assert(slam_effect is DamageSkillEffect, "Associated effect must be DamageSkillEffect")
	var dmg_slam: DamageSkillEffect = slam_effect as DamageSkillEffect
	assert(dmg_slam.value_base == 20, "DamageSkillEffect value_base must be 20")
	assert(dmg_slam.target_type == SkillEffect.TargetType.ENEMY_SINGLE, "TargetType must be ENEMY_SINGLE")
	assert(dmg_slam.is_physical == true, "is_physical must be true")
	assert(is_equal_approx(dmg_slam.threat_multiplier, 1.0), "threat_multiplier must be 1.0")
	assert(is_equal_approx(dmg_slam.stat_scaling_factor, 0.5), "stat_scaling_factor must be 0.5")
	print("PASS: 4.1 bromm_shield_slam.tres loaded and validated successfully")

	# ----------------------------------------------------
	# Test Group 5: Polymorphic iteration and execution test
	# ----------------------------------------------------
	print("\n[Group 5: Polymorphic Execution]")
	var execution_count: int = 0
	for eff in shield_slam.effects:
		eff.apply_effect(dummy_caster, dummy_target)
		execution_count += 1
	assert(execution_count == 1, "Polymorphic effect iteration count mismatch")
	print("PASS: 5.1 Polymorphic iteration and execution verified")

	# Cleanup dummy nodes
	dummy_caster.free()
	dummy_target.free()

	print("\n========================================")
	print("=== ALL SKILL RESOURCES UNIT TESTS PASSED (10/10) ===")
	print("========================================")
	quit(0)
