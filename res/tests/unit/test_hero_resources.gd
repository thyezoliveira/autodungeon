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
	print("--- Starting Hero Resources Unit Tests ---")
	print("========================================")

	# ----------------------------------------------------
	# Test Group 1: RaceData Resource Structure & Defaults
	# ----------------------------------------------------
	print("\n[Group 1: RaceData Structure & Defaults]")
	var race: RaceData = RaceData.new()
	assert(race != null, "RaceData instance must be created")
	assert(race.race_name == "", "Default race_name should be empty")
	assert(race.bonus_max_hp == 0, "Default bonus_max_hp should be 0")
	assert(race.bonus_armor == 0, "Default bonus_armor should be 0")
	assert(race.bonus_magic_resist == 0, "Default bonus_magic_resist should be 0")
	assert(race.bonus_physical_attack == 0, "Default bonus_physical_attack should be 0")
	assert(race.bonus_magic_power == 0, "Default bonus_magic_power should be 0")
	assert(race.racial_trait_description == "", "Default racial_trait_description should be empty")
	print("PASS: 1.1 RaceData default values")

	race.race_name = "Elfo"
	race.bonus_max_hp = -10
	race.bonus_armor = -2
	race.bonus_magic_resist = 8
	race.bonus_physical_attack = 2
	race.bonus_magic_power = 12
	race.racial_trait_description = "Afinidade Arcana: +12 Poder Mágico e +8 Resistência Mágica."
	assert(race.race_name == "Elfo", "Custom race_name applied")
	assert(race.bonus_max_hp == -10, "Custom bonus_max_hp applied")
	assert(race.bonus_armor == -2, "Custom bonus_armor applied")
	assert(race.bonus_magic_resist == 8, "Custom bonus_magic_resist applied")
	assert(race.bonus_physical_attack == 2, "Custom bonus_physical_attack applied")
	assert(race.bonus_magic_power == 12, "Custom bonus_magic_power applied")
	assert(race.racial_trait_description == "Afinidade Arcana: +12 Poder Mágico e +8 Resistência Mágica.", "Custom description applied")
	print("PASS: 1.2 RaceData custom property mutation")

	# ----------------------------------------------------
	# Test Group 2: ClassData Resource Structure, Enums & Skills
	# ----------------------------------------------------
	print("\n[Group 2: ClassData Structure, Role Enum & Skills]")
	var hero_cls: ClassData = ClassData.new()
	assert(hero_cls != null, "ClassData instance must be created")
	assert(hero_cls.class_name_str == "", "Default class_name_str should be empty")
	assert(hero_cls.role == ClassData.Role.TANK_MELEE, "Default role should be TANK_MELEE")
	assert(is_equal_approx(hero_cls.default_attack_range, 2.0), "Default default_attack_range should be 2.0")
	assert(is_equal_approx(hero_cls.base_move_speed, 4.0), "Default base_move_speed should be 4.0")
	assert(hero_cls.class_skills is Array[SkillData], "class_skills must be typed Array[SkillData]")
	assert(hero_cls.class_skills.size() == 0, "Default class_skills should be empty")
	print("PASS: 2.1 ClassData default values")

	# Enum values validation
	assert(ClassData.Role.TANK_MELEE == 0, "Role.TANK_MELEE enum index mismatch")
	assert(ClassData.Role.DPS_RANGED == 1, "Role.DPS_RANGED enum index mismatch")
	assert(ClassData.Role.DPS_MELEE == 2, "Role.DPS_MELEE enum index mismatch")
	assert(ClassData.Role.SUPPORT_HEALER == 3, "Role.SUPPORT_HEALER enum index mismatch")
	print("PASS: 2.2 ClassData Role enum values")

	hero_cls.class_name_str = "Arqueiro"
	hero_cls.role = ClassData.Role.DPS_RANGED
	hero_cls.default_attack_range = 10.0
	hero_cls.base_move_speed = 4.8
	var dummy_skill: SkillData = SkillData.new()
	dummy_skill.id = "arrow_shot"
	dummy_skill.display_name = "Tiro Preciso"
	hero_cls.class_skills.append(dummy_skill)
	assert(hero_cls.class_name_str == "Arqueiro", "Custom class_name_str applied")
	assert(hero_cls.role == ClassData.Role.DPS_RANGED, "Custom role applied")
	assert(is_equal_approx(hero_cls.default_attack_range, 10.0), "Custom default_attack_range applied")
	assert(is_equal_approx(hero_cls.base_move_speed, 4.8), "Custom base_move_speed applied")
	assert(hero_cls.class_skills.size() == 1, "Class skills size verified")
	assert(hero_cls.class_skills[0].id == "arrow_shot", "Class skill reference verified")
	print("PASS: 2.3 ClassData custom properties and skills array")

	# ----------------------------------------------------
	# Test Group 3: HeroData Resource Structure & Defaults
	# ----------------------------------------------------
	print("\n[Group 3: HeroData Structure & Defaults]")
	var hero: HeroData = HeroData.new()
	assert(hero != null, "HeroData instance must be created")
	assert(hero.hero_id == "", "Default hero_id should be empty")
	assert(hero.hero_name == "", "Default hero_name should be empty")
	assert(hero.portrait == null, "Default portrait should be null")
	assert(hero.race == null, "Default race should be null")
	assert(hero.hero_class == null, "Default hero_class should be null")
	assert(hero.base_max_hp == 100, "Default base_max_hp should be 100")
	assert(is_equal_approx(hero.base_max_mana, 50.0), "Default base_max_mana should be 50.0")
	assert(hero.base_armor == 10, "Default base_armor should be 10")
	assert(hero.base_magic_resist == 5, "Default base_magic_resist should be 5")
	assert(hero.base_attack_power == 15, "Default base_attack_power should be 15")
	assert(hero.base_magic_power == 10, "Default base_magic_power should be 10")
	assert(hero.innate_skills is Array[SkillData], "innate_skills must be typed Array[SkillData]")
	assert(hero.innate_skills.size() == 0, "Default innate_skills should be empty")
	print("PASS: 3.1 HeroData default values")

	# ----------------------------------------------------
	# Test Group 4: Attribute Aggregation Logic
	# ----------------------------------------------------
	print("\n[Group 4: Attribute Aggregation Logic]")
	# Test without race (should return base attributes)
	assert(hero.get_total_max_hp() == 100, "get_total_max_hp without race should equal base_max_hp")
	assert(hero.get_total_armor() == 10, "get_total_armor without race should equal base_armor")
	assert(hero.get_total_magic_resist() == 5, "get_total_magic_resist without race should equal base_magic_resist")
	assert(hero.get_total_attack_power() == 15, "get_total_attack_power without race should equal base_attack_power")
	assert(hero.get_total_magic_power() == 10, "get_total_magic_power without race should equal base_magic_power")
	print("PASS: 4.1 Aggregated attributes without race attached")

	# Attach race with modifiers
	var test_race: RaceData = RaceData.new()
	test_race.race_name = "Orc"
	test_race.bonus_max_hp = 35
	test_race.bonus_armor = 8
	test_race.bonus_magic_resist = -3
	test_race.bonus_physical_attack = 10
	test_race.bonus_magic_power = -5
	hero.race = test_race

	assert(hero.get_total_max_hp() == 135, "get_total_max_hp with race (100 + 35 = 135)")
	assert(hero.get_total_armor() == 18, "get_total_armor with race (10 + 8 = 18)")
	assert(hero.get_total_magic_resist() == 2, "get_total_magic_resist with race (5 - 3 = 2)")
	assert(hero.get_total_attack_power() == 25, "get_total_attack_power with race (15 + 10 = 25)")
	assert(hero.get_total_magic_power() == 5, "get_total_magic_power with race (10 - 5 = 5)")
	print("PASS: 4.2 Aggregated attributes with race bonuses and penalties")

	# ----------------------------------------------------
	# Test Group 5: race_anao.tres Resource Loading & Integrity
	# ----------------------------------------------------
	print("\n[Group 5: race_anao.tres Resource File]")
	var race_path: String = "res://src/data/heroes/races/race_anao.tres"
	assert(ResourceLoader.exists(race_path), "Resource file race_anao.tres must exist on disk")

	var loaded_race_res: Resource = ResourceLoader.load(race_path)
	assert(loaded_race_res != null, "race_anao.tres must load successfully")
	assert(loaded_race_res is RaceData, "Loaded resource must be an instance of RaceData")

	var anao_race: RaceData = loaded_race_res as RaceData
	assert(anao_race.race_name == "Anão", "Race name must be 'Anão'")
	assert(anao_race.bonus_max_hp == 20, "Anão bonus_max_hp must be 20")
	assert(anao_race.bonus_armor == 5, "Anão bonus_armor must be 5")
	assert(anao_race.bonus_magic_resist == 0, "Anão bonus_magic_resist must be 0")
	assert(anao_race.bonus_physical_attack == 0, "Anão bonus_physical_attack must be 0")
	assert(anao_race.bonus_magic_power == 0, "Anão bonus_magic_power must be 0")
	assert(anao_race.racial_trait_description.length() > 0, "Racial trait description must not be empty")
	print("PASS: 5.1 race_anao.tres loaded and validated successfully")

	# ----------------------------------------------------
	# Test Group 6: class_guardiao.tres Resource Loading & Integrity
	# ----------------------------------------------------
	print("\n[Group 6: class_guardiao.tres Resource File]")
	var class_path: String = "res://src/data/heroes/classes/class_guardiao.tres"
	assert(ResourceLoader.exists(class_path), "Resource file class_guardiao.tres must exist on disk")

	var loaded_class_res: Resource = ResourceLoader.load(class_path)
	assert(loaded_class_res != null, "class_guardiao.tres must load successfully")
	assert(loaded_class_res is ClassData, "Loaded resource must be an instance of ClassData")

	var guardiao_cls: ClassData = loaded_class_res as ClassData
	assert(guardiao_cls.class_name_str == "Guardião", "Class name must be 'Guardião'")
	assert(guardiao_cls.role == ClassData.Role.TANK_MELEE, "Guardião role must be TANK_MELEE")
	assert(is_equal_approx(guardiao_cls.default_attack_range, 2.0), "Attack range must be 2.0")
	assert(is_equal_approx(guardiao_cls.base_move_speed, 4.0), "Move speed must be 4.0")
	assert(guardiao_cls.class_skills.size() >= 1, "Guardião must have at least 1 class skill")
	assert(guardiao_cls.class_skills[0].id == "bromm_shield_slam", "First class skill should be 'bromm_shield_slam'")
	print("PASS: 6.1 class_guardiao.tres loaded and validated successfully")

	# ----------------------------------------------------
	# Test Group 7: hero_bromm.tres Resource Loading, Composition & Aggregation
	# ----------------------------------------------------
	print("\n[Group 7: hero_bromm.tres Resource File & Composition]")
	var bromm_path: String = "res://src/data/heroes/hero_bromm.tres"
	assert(ResourceLoader.exists(bromm_path), "Resource file hero_bromm.tres must exist on disk")

	var loaded_bromm_res: Resource = ResourceLoader.load(bromm_path)
	assert(loaded_bromm_res != null, "hero_bromm.tres must load successfully")
	assert(loaded_bromm_res is HeroData, "Loaded resource must be an instance of HeroData")

	var bromm: HeroData = loaded_bromm_res as HeroData
	assert(bromm.hero_id == "bromm", "Hero ID must be 'bromm'")
	assert(bromm.hero_name == "Bromm Barba-de-Ferro", "Hero name must be 'Bromm Barba-de-Ferro'")
	assert(bromm.race != null, "Bromm must have a RaceData assigned")
	assert(bromm.race.race_name == "Anão", "Bromm race must be 'Anão'")
	assert(bromm.hero_class != null, "Bromm must have a ClassData assigned")
	assert(bromm.hero_class.class_name_str == "Guardião", "Bromm class must be 'Guardião'")
	assert(bromm.hero_class.role == ClassData.Role.TANK_MELEE, "Bromm class role must be TANK_MELEE")

	# Attribute calculations verification for Bromm
	assert(bromm.base_max_hp == 100, "Bromm base HP is 100")
	assert(bromm.base_armor == 10, "Bromm base armor is 10")
	assert(bromm.get_total_max_hp() == 120, "Bromm total HP (100 base + 20 anao = 120)")
	assert(bromm.get_total_armor() == 15, "Bromm total armor (10 base + 5 anao = 15)")
	assert(bromm.get_total_magic_resist() == 5, "Bromm total magic resist (5 base + 0 anao = 5)")
	assert(bromm.get_total_attack_power() == 15, "Bromm total attack power (15 base + 0 anao = 15)")
	assert(bromm.get_total_magic_power() == 10, "Bromm total magic power (10 base + 0 anao = 10)")

	# Innate skills verification
	assert(bromm.innate_skills.size() == 1, "Bromm has 1 innate skill configured")
	assert(bromm.innate_skills[0].id == "bromm_shield_slam", "Innate skill is 'bromm_shield_slam'")
	print("PASS: 7.1 hero_bromm.tres loaded, composed and aggregated stats validated successfully")

	print("\n========================================")
	print("=== ALL HERO RESOURCES UNIT TESTS PASSED (14/14) ===")
	print("========================================")
	quit(0)
