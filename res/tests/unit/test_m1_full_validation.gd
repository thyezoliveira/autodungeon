extends SceneTree

var _executed: bool = false


func _process(_delta: float) -> bool:
	if _executed:
		return false
	_executed = true
	_run_all_tests()
	return false


func _run_all_tests() -> void:
	print("================================================================")
	print("--- Starting M1 Full Validation Suite (Trio MVP & Data Layer) ---")
	print("================================================================")

	# ----------------------------------------------------
	# Test Group 1: Races Validation (Anão, Elfo, Humano)
	# ----------------------------------------------------
	print("\n[Group 1: Races Resource Integrity & Stats]")
	var races_to_test: Dictionary = {
		"res://src/data/heroes/races/race_anao.tres": {
			"name": "Anão",
			"hp": 20,
			"armor": 5,
			"mr": 0,
			"phys_atk": 0,
			"mag_pow": 0,
			"trait": "Resistência Pétrea"
		},
		"res://src/data/heroes/races/race_elfo.tres": {
			"name": "Elfo",
			"hp": 0,
			"armor": 0,
			"mr": 0,
			"phys_atk": 10,
			"mag_pow": 5,
			"trait": "Precisão Élfica"
		},
		"res://src/data/heroes/races/race_humano.tres": {
			"name": "Humano",
			"hp": 10,
			"armor": 0,
			"mr": 5,
			"phys_atk": 0,
			"mag_pow": 0,
			"trait": "Versatilidade"
		}
	}

	for path in races_to_test.keys():
		assert(ResourceLoader.exists(path), "Race resource file must exist: " + path)
		var race_res: Resource = ResourceLoader.load(path)
		assert(race_res != null and race_res is RaceData, "Failed to load RaceData from: " + path)
		var race: RaceData = race_res as RaceData
		var expected: Dictionary = races_to_test[path]
		assert(race.race_name == expected["name"], "Race name mismatch for " + path)
		assert(race.bonus_max_hp == expected["hp"], "Bonus HP mismatch for " + path)
		assert(race.bonus_armor == expected["armor"], "Bonus Armor mismatch for " + path)
		assert(race.bonus_magic_resist == expected["mr"], "Bonus MR mismatch for " + path)
		assert(race.bonus_physical_attack == expected["phys_atk"], "Bonus Phys Atk mismatch for " + path)
		assert(race.bonus_magic_power == expected["mag_pow"], "Bonus Mag Power mismatch for " + path)
		assert(race.racial_trait_description.contains(expected["trait"]), "Trait description mismatch for " + path)
		print("PASS: Race validated -> " + race.race_name)

	# ----------------------------------------------------
	# Test Group 2: Skills Validation (7 MVP Skills)
	# ----------------------------------------------------
	print("\n[Group 2: Skills Resource Integrity (7 Skills)]")
	var skills_to_test: Dictionary = {
		"res://src/data/skills/resources/bromm_shield_slam.tres": {
			"id": "bromm_shield_slam",
			"name": "Golpe de Escudo",
			"mana": 10.0,
			"cd": 5.0,
			"effects_count": 1,
			"is_dmg": true,
			"threat": 3.0,
			"is_phys": true
		},
		"res://src/data/skills/resources/bromm_defensive_stance.tres": {
			"id": "bromm_defensive_stance",
			"name": "Postura Defensiva",
			"mana": 15.0,
			"cd": 12.0,
			"effects_count": 1,
			"is_dmg": false,
			"target": SkillEffect.TargetType.SELF,
			"duration": 6.0
		},
		"res://src/data/skills/resources/bromm_charge.tres": {
			"id": "bromm_charge",
			"name": "Investida",
			"mana": 12.0,
			"cd": 8.0,
			"effects_count": 1,
			"is_dmg": true,
			"threat": 2.0,
			"is_phys": true
		},
		"res://src/data/skills/resources/elysia_aimed_shot.tres": {
			"id": "elysia_aimed_shot",
			"name": "Tiro Certeiro",
			"mana": 12.0,
			"cd": 4.0,
			"effects_count": 1,
			"is_dmg": true,
			"threat": 1.0,
			"is_phys": true,
			"target": SkillEffect.TargetType.ENEMY_SINGLE
		},
		"res://src/data/skills/resources/elysia_arrow_rain.tres": {
			"id": "elysia_arrow_rain",
			"name": "Chuva de Flechas",
			"mana": 25.0,
			"cd": 10.0,
			"effects_count": 1,
			"is_dmg": true,
			"threat": 1.0,
			"is_phys": true,
			"target": SkillEffect.TargetType.ENEMY_AREA
		},
		"res://src/data/skills/resources/beatrice_quick_heal.tres": {
			"id": "beatrice_quick_heal",
			"name": "Cura Rápida",
			"mana": 20.0,
			"cd": 5.0,
			"effects_count": 1,
			"is_dmg": false,
			"target": SkillEffect.TargetType.ALLY_LOWEST_HP
		},
		"res://src/data/skills/resources/beatrice_faith_shield.tres": {
			"id": "beatrice_faith_shield",
			"name": "Escudo de Fé",
			"mana": 25.0,
			"cd": 12.0,
			"effects_count": 1,
			"is_dmg": false,
			"target": SkillEffect.TargetType.ALLY_SINGLE,
			"duration": 5.0
		}
	}

	for path in skills_to_test.keys():
		assert(ResourceLoader.exists(path), "Skill resource file must exist: " + path)
		var skill_res: Resource = ResourceLoader.load(path)
		assert(skill_res != null and skill_res is SkillData, "Failed to load SkillData from: " + path)
		var skill: SkillData = skill_res as SkillData
		var exp_skill: Dictionary = skills_to_test[path]

		assert(skill.id == exp_skill["id"], "Skill ID mismatch for " + path)
		assert(skill.display_name == exp_skill["name"], "Skill name mismatch for " + path)
		assert(is_equal_approx(skill.mana_cost, exp_skill["mana"]), "Skill mana cost mismatch for " + path)
		assert(is_equal_approx(skill.cooldown, exp_skill["cd"]), "Skill cooldown mismatch for " + path)
		assert(skill.effects.size() == exp_skill["effects_count"], "Skill effects count mismatch for " + path)

		var effect: SkillEffect = skill.effects[0]
		assert(effect != null, "Skill effect must not be null for " + path)

		if exp_skill["is_dmg"]:
			assert(effect is DamageSkillEffect, "Effect must be DamageSkillEffect for " + path)
			var dmg_eff: DamageSkillEffect = effect as DamageSkillEffect
			assert(dmg_eff.is_physical == exp_skill["is_phys"], "Physical flag mismatch for " + path)
			assert(is_equal_approx(dmg_eff.threat_multiplier, exp_skill["threat"]), "Threat multiplier mismatch for " + path)
		if exp_skill.has("target"):
			assert(effect.target_type == exp_skill["target"], "Target type mismatch for " + path)
		if exp_skill.has("duration"):
			assert(is_equal_approx(effect.duration, exp_skill["duration"]), "Duration mismatch for " + path)

		print("PASS: Skill validated -> " + skill.display_name + " (" + skill.id + ")")

	# ----------------------------------------------------
	# Test Group 3: Classes Validation (Guardião, Patrulheiro, Clérigo)
	# ----------------------------------------------------
	print("\n[Group 3: Classes Resource Integrity]")
	var classes_to_test: Dictionary = {
		"res://src/data/heroes/classes/class_guardiao.tres": {
			"name": "Guardião",
			"role": ClassData.Role.TANK_MELEE,
			"range": 2.0,
			"speed": 3.8,
			"min_skills": 3
		},
		"res://src/data/heroes/classes/class_patrulheiro.tres": {
			"name": "Patrulheiro",
			"role": ClassData.Role.DPS_RANGED,
			"range": 8.0,
			"speed": 4.2,
			"min_skills": 2
		},
		"res://src/data/heroes/classes/class_clerigo.tres": {
			"name": "Clérigo",
			"role": ClassData.Role.SUPPORT_HEALER,
			"range": 5.0,
			"speed": 4.0,
			"min_skills": 2
		}
	}

	for path in classes_to_test.keys():
		assert(ResourceLoader.exists(path), "Class resource file must exist: " + path)
		var cls_res: Resource = ResourceLoader.load(path)
		assert(cls_res != null and cls_res is ClassData, "Failed to load ClassData from: " + path)
		var cls: ClassData = cls_res as ClassData
		var exp_cls: Dictionary = classes_to_test[path]

		assert(cls.class_name_str == exp_cls["name"], "Class name mismatch for " + path)
		assert(cls.role == exp_cls["role"], "Class role mismatch for " + path)
		assert(is_equal_approx(cls.default_attack_range, exp_cls["range"]), "Class attack range mismatch for " + path)
		assert(is_equal_approx(cls.base_move_speed, exp_cls["speed"]), "Class move speed mismatch for " + path)
		assert(cls.class_skills.size() >= exp_cls["min_skills"], "Class skills count mismatch for " + path)
		print("PASS: Class validated -> " + cls.class_name_str + " (Role: " + str(cls.role) + ")")

	# ----------------------------------------------------
	# Test Group 4: Trio MVP Heroes Validation (Bromm, Elysia, Beatrice)
	# ----------------------------------------------------
	print("\n[Group 4: Trio MVP Heroes Resource Validation]")

	# 4.1 Bromm (Anão Guardião - Tank Melee)
	var bromm_path: String = "res://src/data/heroes/resources/hero_bromm.tres"
	assert(ResourceLoader.exists(bromm_path), "hero_bromm.tres must exist")
	var bromm: HeroData = ResourceLoader.load(bromm_path) as HeroData
	assert(bromm != null, "hero_bromm.tres must load")
	assert(bromm.hero_id == "bromm", "Bromm hero_id is 'bromm'")
	assert(bromm.hero_name == "Bromm Barba-de-Ferro", "Bromm hero_name is 'Bromm Barba-de-Ferro'")
	assert(bromm.race != null and bromm.race.race_name == "Anão", "Bromm race must be Anão")
	assert(bromm.hero_class != null and bromm.hero_class.class_name_str == "Guardião", "Bromm class must be Guardião")
	assert(bromm.hero_class.role == ClassData.Role.TANK_MELEE, "Bromm role must be TANK_MELEE")
	assert(bromm.get_total_max_hp() >= 150, "Bromm total HP (" + str(bromm.get_total_max_hp()) + ") must be >= 150")
	assert(bromm.get_total_armor() >= 25, "Bromm total Armor (" + str(bromm.get_total_armor()) + ") must be >= 25")
	assert(bromm.hero_class.default_attack_range <= 2.5, "Bromm attack range should be melee (2.0m)")
	assert(bromm.innate_skills.size() == 3, "Bromm must have 3 equipped skills")
	print("PASS: 4.1 Bromm validated (HP: " + str(bromm.get_total_max_hp()) + ", Armor: " + str(bromm.get_total_armor()) + ", Role: TANK_MELEE)")

	# 4.2 Elysia (Elfa Patrulheira - DPS Ranged)
	var elysia_path: String = "res://src/data/heroes/resources/hero_elysia.tres"
	assert(ResourceLoader.exists(elysia_path), "hero_elysia.tres must exist")
	var elysia: HeroData = ResourceLoader.load(elysia_path) as HeroData
	assert(elysia != null, "hero_elysia.tres must load")
	assert(elysia.hero_id == "elysia", "Elysia hero_id is 'elysia'")
	assert(elysia.hero_name == "Elysia Ventoveloz", "Elysia hero_name is 'Elysia Ventoveloz'")
	assert(elysia.race != null and elysia.race.race_name == "Elfo", "Elysia race must be Elfo")
	assert(elysia.hero_class != null and elysia.hero_class.class_name_str == "Patrulheiro", "Elysia class must be Patrulheiro")
	assert(elysia.hero_class.role == ClassData.Role.DPS_RANGED, "Elysia role must be DPS_RANGED")
	assert(elysia.get_total_max_hp() >= 80 and elysia.get_total_max_hp() <= 90, "Elysia total HP (" + str(elysia.get_total_max_hp()) + ") must be ~ 85")
	assert(elysia.hero_class.default_attack_range >= 8.0, "Elysia attack range (" + str(elysia.hero_class.default_attack_range) + ") must be >= 8.0")
	assert(elysia.get_total_attack_power() >= 30, "Elysia total Attack Power (" + str(elysia.get_total_attack_power()) + ") must be >= 30")
	assert(elysia.innate_skills.size() == 2, "Elysia must have 2 equipped skills")
	print("PASS: 4.2 Elysia validated (HP: " + str(elysia.get_total_max_hp()) + ", Range: " + str(elysia.hero_class.default_attack_range) + "m, Role: DPS_RANGED)")

	# 4.3 Beatrice (Humana Clériga - Support Healer)
	var beatrice_path: String = "res://src/data/heroes/resources/hero_beatrice.tres"
	assert(ResourceLoader.exists(beatrice_path), "hero_beatrice.tres must exist")
	var beatrice: HeroData = ResourceLoader.load(beatrice_path) as HeroData
	assert(beatrice != null, "hero_beatrice.tres must load")
	assert(beatrice.hero_id == "beatrice", "Beatrice hero_id is 'beatrice'")
	assert(beatrice.hero_name == "Beatrice Alvorada", "Beatrice hero_name is 'Beatrice Alvorada'")
	assert(beatrice.race != null and beatrice.race.race_name == "Humano", "Beatrice race must be Humano")
	assert(beatrice.hero_class != null and beatrice.hero_class.class_name_str == "Clérigo", "Beatrice class must be Clérigo")
	assert(beatrice.hero_class.role == ClassData.Role.SUPPORT_HEALER, "Beatrice role must be SUPPORT_HEALER")
	assert(beatrice.get_total_max_hp() >= 90 and beatrice.get_total_max_hp() <= 100, "Beatrice total HP (" + str(beatrice.get_total_max_hp()) + ") must be ~ 95")
	assert(beatrice.base_max_mana >= 100.0, "Beatrice base Mana (" + str(beatrice.base_max_mana) + ") must be >= 100")
	assert(beatrice.get_total_magic_resist() >= 15, "Beatrice total MR (" + str(beatrice.get_total_magic_resist()) + ") must be >= 15")
	assert(beatrice.innate_skills.size() == 2, "Beatrice must have 2 equipped skills")
	print("PASS: 4.3 Beatrice validated (HP: " + str(beatrice.get_total_max_hp()) + ", Mana: " + str(beatrice.base_max_mana) + ", Role: SUPPORT_HEALER)")

	# ----------------------------------------------------
	# Test Group 5: Polymorphic Invocation & Zero Leaks
	# ----------------------------------------------------
	print("\n[Group 5: Polymorphic Effect Invocation & Resource Links]")
	var test_caster: Node3D = Node3D.new()
	var test_target: Node3D = Node3D.new()
	root.add_child(test_caster)
	root.add_child(test_target)

	var all_heroes: Array[HeroData] = [bromm, elysia, beatrice]
	var total_effects_executed: int = 0
	for h in all_heroes:
		for s in h.innate_skills:
			assert(s != null, "Hero " + h.hero_id + " has valid skill instance")
			for eff in s.effects:
				assert(eff != null, "Skill " + s.id + " has valid effect instance")
				eff.apply_effect(test_caster, test_target)
				total_effects_executed += 1

	assert(total_effects_executed == 7, "Total polymorphic effects executed should be 7")
	print("PASS: 5.1 Successfully executed all 7 hero skill effects polymorphically")

	test_caster.queue_free()
	test_target.queue_free()

	print("\n================================================================")
	print("=== ALL M1 FULL VALIDATION TESTS PASSED SUCCESSFULLY! ===")
	print("================================================================")
	quit(0)
