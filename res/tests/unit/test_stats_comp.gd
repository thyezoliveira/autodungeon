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
	print("--- Starting StatsComponent Unit Tests ---")
	print("========================================")

	# ----------------------------------------------------
	# Test Group 1: Default State & Property Values
	# ----------------------------------------------------
	print("\n[Group 1: Default State & Exported Properties]")
	var stats: StatsComponent = StatsComponent.new()
	assert(stats != null, "StatsComponent instance must be created")
	assert(stats.max_hp == 100, "Default max_hp should be 100")
	assert(is_equal_approx(stats.max_mana, 50.0), "Default max_mana should be 50.0")
	assert(stats.attack_power == 15, "Default attack_power should be 15")
	assert(stats.magic_power == 10, "Default magic_power should be 10")
	assert(stats.armor == 10, "Default armor should be 10")
	assert(stats.magic_resist == 5, "Default magic_resist should be 5")
	assert(is_equal_approx(stats.move_speed, 4.0), "Default move_speed should be 4.0")
	assert(is_equal_approx(stats.critical_chance, 0.05), "Default critical_chance should be 0.05")

	# get_stat with defaults (no modifiers)
	assert(is_equal_approx(stats.get_stat("max_hp"), 100.0), "get_stat('max_hp') should equal base 100")
	assert(is_equal_approx(stats.get_stat("max_mana"), 50.0), "get_stat('max_mana') should equal base 50.0")
	assert(is_equal_approx(stats.get_stat("attack_power"), 15.0), "get_stat('attack_power') should equal base 15")
	assert(is_equal_approx(stats.get_stat("magic_power"), 10.0), "get_stat('magic_power') should equal base 10")
	assert(is_equal_approx(stats.get_stat("armor"), 10.0), "get_stat('armor') should equal base 10")
	assert(is_equal_approx(stats.get_stat("magic_resist"), 5.0), "get_stat('magic_resist') should equal base 5")
	assert(is_equal_approx(stats.get_stat("move_speed"), 4.0), "get_stat('move_speed') should equal base 4.0")
	assert(is_equal_approx(stats.get_stat("critical_chance"), 0.05), "get_stat('critical_chance') should equal base 0.05")
	print("PASS: 1.1 StatsComponent default properties and initial get_stat calls")

	# ----------------------------------------------------
	# Test Group 2: Initialization from HeroData
	# ----------------------------------------------------
	print("\n[Group 2: Initialization from HeroData]")
	var bromm_res: HeroData = load("res://src/data/heroes/resources/hero_bromm.tres") as HeroData
	assert(bromm_res != null, "hero_bromm.tres must load successfully")
	
	stats.initialize_from_hero_data(bromm_res)
	assert(stats.max_hp == 160, "Bromm max_hp should be 160 (140 base + 20 anao)")
	assert(stats.armor == 25, "Bromm armor should be 25 (20 base + 5 anao)")
	assert(stats.magic_resist == 8, "Bromm magic_resist should be 8 (8 base + 0 anao)")
	assert(stats.attack_power == 16, "Bromm attack_power should be 16 (16 base + 0 anao)")
	assert(stats.magic_power == 5, "Bromm magic_power should be 5 (5 base + 0 anao)")
	assert(is_equal_approx(stats.move_speed, 3.8), "Bromm move_speed should be 3.8 from class_guardiao")
	assert(is_equal_approx(stats.get_stat("max_hp"), 160.0), "get_stat max_hp matches Bromm HP")
	assert(is_equal_approx(stats.get_stat("armor"), 25.0), "get_stat armor matches Bromm armor")
	print("PASS: 2.1 StatsComponent initialized correctly from Bromm HeroData")

	# Safety test with null HeroData
	stats.initialize_from_hero_data(null)
	assert(stats.max_hp == 160, "Null HeroData does not modify existing stats")
	print("PASS: 2.2 Null HeroData handled safely")

	# ----------------------------------------------------
	# Test Group 3: Initialization from EnemyData
	# ----------------------------------------------------
	print("\n[Group 3: Initialization from EnemyData]")
	var goblin_res: EnemyData = load("res://src/data/enemies/enemy_goblin_warrior.tres") as EnemyData
	assert(goblin_res != null, "enemy_goblin_warrior.tres must load successfully")

	var enemy_stats: StatsComponent = StatsComponent.new()
	enemy_stats.initialize_from_enemy_data(goblin_res)
	assert(enemy_stats.max_hp == 45, "Goblin max_hp should be 45")
	assert(enemy_stats.armor == 2, "Goblin armor should be 2")
	assert(enemy_stats.attack_power == 8, "Goblin attack_power should be 8")
	assert(is_equal_approx(enemy_stats.move_speed, 3.5), "Goblin move_speed should be 3.5")
	assert(is_equal_approx(enemy_stats.get_stat("max_hp"), 45.0), "get_stat max_hp matches Goblin HP")
	print("PASS: 3.1 StatsComponent initialized correctly from Goblin EnemyData")

	# Safety test with null EnemyData
	enemy_stats.initialize_from_enemy_data(null)
	assert(enemy_stats.max_hp == 45, "Null EnemyData does not modify existing stats")
	print("PASS: 3.2 Null EnemyData handled safely")
	enemy_stats.free()

	# ----------------------------------------------------
	# Test Group 4: Flat Modifiers & Signal Emission
	# ----------------------------------------------------
	print("\n[Group 4: Flat Modifiers & Signal Emission]")
	var tracker: Dictionary = {
		"emitted": false,
		"stat": "",
		"val": 0.0
	}

	var on_stat_modified = func(stat_name: String, new_value: float) -> void:
		tracker["emitted"] = true
		tracker["stat"] = stat_name
		tracker["val"] = new_value

	# Reset Bromm stats to default test node for clean modifier testing
	var test_comp: StatsComponent = StatsComponent.new()
	test_comp.stat_modified.connect(on_stat_modified)

	# Add flat modifier +10 armor (base is 10 -> 20)
	tracker["emitted"] = false
	test_comp.add_flat_modifier("armor", "shield_buff", 10.0)
	assert(tracker["emitted"], "stat_modified signal must be emitted on add_flat_modifier")
	assert(tracker["stat"] == "armor", "Emitted stat name must be 'armor'")
	assert(is_equal_approx(tracker["val"], 20.0), "Emitted value should be 20.0")
	assert(is_equal_approx(test_comp.get_stat("armor"), 20.0), "get_stat('armor') should be 20.0")
	print("PASS: 4.1 Single flat modifier added and signal emitted")

	# Add second flat modifier +5 armor from ring (10 + 10 + 5 = 25)
	tracker["emitted"] = false
	test_comp.add_flat_modifier("armor", "iron_ring", 5.0)
	assert(tracker["emitted"], "stat_modified signal emitted on second modifier")
	assert(is_equal_approx(test_comp.get_stat("armor"), 25.0), "get_stat('armor') should be 25.0")
	print("PASS: 4.2 Multiple flat modifiers stacked on the same stat")

	# Update existing flat modifier (shield_buff changed from +10 to +15 -> 10 + 15 + 5 = 30)
	test_comp.add_flat_modifier("armor", "shield_buff", 15.0)
	assert(is_equal_approx(test_comp.get_stat("armor"), 30.0), "Modifier overwritten by same ID")
	print("PASS: 4.3 Flat modifier overwritten by same ID")

	# Remove one flat modifier (remove shield_buff -> 10 + 5 = 15)
	tracker["emitted"] = false
	test_comp.remove_modifier("armor", "shield_buff")
	assert(tracker["emitted"], "stat_modified signal emitted on remove_modifier")
	assert(is_equal_approx(test_comp.get_stat("armor"), 15.0), "get_stat('armor') returns to 15.0")
	print("PASS: 4.4 Flat modifier removed and stat restored")

	# Remove remaining flat modifier -> returns to base 10
	test_comp.remove_modifier("armor", "iron_ring")
	assert(is_equal_approx(test_comp.get_stat("armor"), 10.0), "get_stat('armor') returns to base 10.0")
	print("PASS: 4.5 All flat modifiers removed, stat returned to base")

	# Remove non-existent modifier (should be a no-op, no signal)
	tracker["emitted"] = false
	test_comp.remove_modifier("armor", "non_existent")
	assert(not tracker["emitted"], "Removing non-existent modifier should not emit signal")
	print("PASS: 4.6 Non-existent modifier removal handled gracefully")

	# ----------------------------------------------------
	# Test Group 5: Percent Modifiers & Signal Emission
	# ----------------------------------------------------
	print("\n[Group 5: Percent Modifiers & Signal Emission]")
	# attack_power base = 15. Add +50% (+0.50) -> 15 * 1.5 = 22.5
	tracker["emitted"] = false
	test_comp.add_percent_modifier("attack_power", "berserk", 0.50)
	assert(tracker["emitted"], "stat_modified signal emitted on add_percent_modifier")
	assert(tracker["stat"] == "attack_power", "Emitted stat name is 'attack_power'")
	assert(is_equal_approx(tracker["val"], 22.5), "Emitted value should be 22.5")
	assert(is_equal_approx(test_comp.get_stat("attack_power"), 22.5), "get_stat('attack_power') is 22.5")
	print("PASS: 5.1 Single percent modifier added (+50%)")

	# Add second percent modifier (+20% -> total +70%) -> 15 * 1.7 = 25.5
	test_comp.add_percent_modifier("attack_power", "aura", 0.20)
	assert(is_equal_approx(test_comp.get_stat("attack_power"), 25.5), "Multiple percent modifiers stacked (+70% -> 25.5)")
	print("PASS: 5.2 Multiple percent modifiers stacked additively")

	# Remove percent modifier
	test_comp.remove_modifier("attack_power", "berserk")
	assert(is_equal_approx(test_comp.get_stat("attack_power"), 18.0), "get_stat with +20% remaining is 18.0 (15 * 1.2)")
	test_comp.remove_modifier("attack_power", "aura")
	assert(is_equal_approx(test_comp.get_stat("attack_power"), 15.0), "attack_power restored to base 15.0")
	print("PASS: 5.3 Percent modifiers removed and stat restored")

	# ----------------------------------------------------
	# Test Group 6: Combined Flat & Percent Modifiers (Order of Operations)
	# ----------------------------------------------------
	print("\n[Group 6: Combined Flat & Percent Modifiers Formula: (base + sum_flats) * (1 + sum_percents)]")
	# max_hp base = 100. Flat = +50. Percent = +0.20 (+20%).
	# Formula: (100 + 50) * (1.0 + 0.20) = 150 * 1.2 = 180.0
	test_comp.add_flat_modifier("max_hp", "vitality_gear", 50.0)
	test_comp.add_percent_modifier("max_hp", "giant_buff", 0.20)
	assert(is_equal_approx(test_comp.get_stat("max_hp"), 180.0), "Combined (100 + 50) * 1.20 == 180.0")
	print("PASS: 6.1 Combined flat (+50) and percent (+20%) on max_hp")

	# Add negative flat debuff (-30) and negative percent debuff (-10%):
	# Flats: 50 - 30 = 20. Percents: 0.20 - 0.10 = 0.10.
	# (100 + 20) * (1.0 + 0.10) = 120 * 1.10 = 132.0
	test_comp.add_flat_modifier("max_hp", "curse_flat", -30.0)
	test_comp.add_percent_modifier("max_hp", "curse_pct", -0.10)
	assert(is_equal_approx(test_comp.get_stat("max_hp"), 132.0), "Combined positive and negative modifiers == 132.0")
	print("PASS: 6.2 Positive and negative flat/percent modifiers combined accurately")

	# ----------------------------------------------------
	# Test Group 7: Logical Minimum Value Clamping
	# ----------------------------------------------------
	print("\n[Group 7: Logical Minimum Value Clamping]")
	var clamp_comp: StatsComponent = StatsComponent.new()

	# max_hp must never fall below 1.0 even with catastrophic debuffs
	clamp_comp.add_flat_modifier("max_hp", "death_curse", -9999.0)
	assert(clamp_comp.get_stat("max_hp") >= 1.0, "max_hp must be >= 1.0")
	assert(is_equal_approx(clamp_comp.get_stat("max_hp"), 1.0), "max_hp clamped to 1.0 minimum")
	print("PASS: 7.1 max_hp minimum clamped to 1.0")

	# armor and magic_resist must not fall below 0.0
	clamp_comp.add_flat_modifier("armor", "sunder_armor", -50.0)
	assert(is_equal_approx(clamp_comp.get_stat("armor"), 0.0), "armor clamped to 0.0 minimum")
	clamp_comp.add_percent_modifier("magic_resist", "antimagic_null", -2.0)
	assert(is_equal_approx(clamp_comp.get_stat("magic_resist"), 0.0), "magic_resist clamped to 0.0 minimum")
	print("PASS: 7.2 armor and magic_resist clamped to 0.0 minimum")

	# move_speed and mana clamped to 0.0
	clamp_comp.add_flat_modifier("move_speed", "freeze_slow", -10.0)
	assert(is_equal_approx(clamp_comp.get_stat("move_speed"), 0.0), "move_speed clamped to 0.0 minimum")
	clamp_comp.add_flat_modifier("max_mana", "mana_burn", -200.0)
	assert(is_equal_approx(clamp_comp.get_stat("max_mana"), 0.0), "max_mana clamped to 0.0 minimum")
	print("PASS: 7.3 move_speed and max_mana clamped to 0.0 minimum")

	# critical_chance must be clamped in [0.0, 1.0]
	clamp_comp.add_flat_modifier("critical_chance", "overcrit", 2.0)
	assert(is_equal_approx(clamp_comp.get_stat("critical_chance"), 1.0), "critical_chance clamped to 1.0 (100%) maximum")
	clamp_comp.add_flat_modifier("critical_chance", "overcrit", -5.0)
	assert(is_equal_approx(clamp_comp.get_stat("critical_chance"), 0.0), "critical_chance clamped to 0.0 minimum")
	print("PASS: 7.4 critical_chance clamped within [0.0, 1.0] bounds")
	clamp_comp.free()

	# ----------------------------------------------------
	# Test Group 8: clear_all_modifiers()
	# ----------------------------------------------------
	print("\n[Group 8: clear_all_modifiers()]")
	var clear_comp: StatsComponent = StatsComponent.new()
	var modified_records: Array[String] = []
	clear_comp.stat_modified.connect(func(s_name: String, _val: float): modified_records.append(s_name))

	clear_comp.add_flat_modifier("armor", "m1", 10.0)
	clear_comp.add_percent_modifier("attack_power", "m2", 0.5)
	clear_comp.add_flat_modifier("max_hp", "m3", 25.0)
	assert(clear_comp.has_modifier("armor", "m1"), "has_modifier returns true for armor m1")
	assert(clear_comp.has_modifier("attack_power", "m2"), "has_modifier returns true for attack_power m2")
	assert(not clear_comp.has_modifier("armor", "unknown"), "has_modifier returns false for unknown")

	modified_records.clear()
	clear_comp.clear_all_modifiers()
	assert(not clear_comp.has_modifier("armor", "m1"), "m1 cleared")
	assert(not clear_comp.has_modifier("attack_power", "m2"), "m2 cleared")
	assert(is_equal_approx(clear_comp.get_stat("armor"), 10.0), "armor returned to base 10")
	assert(is_equal_approx(clear_comp.get_stat("attack_power"), 15.0), "attack_power returned to base 15")
	assert(is_equal_approx(clear_comp.get_stat("max_hp"), 100.0), "max_hp returned to base 100")
	assert(modified_records.has("armor"), "stat_modified emitted for armor on clear")
	assert(modified_records.has("attack_power"), "stat_modified emitted for attack_power on clear")
	assert(modified_records.has("max_hp"), "stat_modified emitted for max_hp on clear")
	print("PASS: 8.1 clear_all_modifiers completely resets modifiers and emits signals")
	clear_comp.free()

	# ----------------------------------------------------
	# Test Group 9: test_stats_comp.tscn Scene Instantiation
	# ----------------------------------------------------
	print("\n[Group 9: test_stats_comp.tscn Scene Instantiation]")
	var scene_path: String = "res://tests/test_stats_comp.tscn"
	assert(ResourceLoader.exists(scene_path), "test_stats_comp.tscn must exist on disk")

	var scene_res: PackedScene = load(scene_path) as PackedScene
	assert(scene_res != null, "test_stats_comp.tscn must load as PackedScene")

	var scene_instance: Node = scene_res.instantiate()
	assert(scene_instance != null, "Instantiating test_stats_comp.tscn succeeded")
	root.add_child(scene_instance)

	var node_stats: StatsComponent = scene_instance.get_node_or_null("StatsComponent") as StatsComponent
	assert(node_stats != null, "StatsComponent child node found in test scene")

	node_stats.initialize_from_hero_data(bromm_res)
	assert(node_stats.max_hp == 160, "Scene StatsComponent initialized with Bromm HP")
	assert(node_stats.armor == 25, "Scene StatsComponent initialized with Bromm Armor")

	node_stats.add_flat_modifier("armor", "test_bonus", 10.0)
	assert(is_equal_approx(node_stats.get_stat("armor"), 35.0), "Scene StatsComponent modified armor is 35.0")

	node_stats.remove_modifier("armor", "test_bonus")
	assert(is_equal_approx(node_stats.get_stat("armor"), 25.0), "Scene StatsComponent restored armor is 25.0")
	print("PASS: 9.1 test_stats_comp.tscn scene instantiated, initialized and verified")

	scene_instance.queue_free()
	test_comp.free()
	stats.free()

	print("\n========================================")
	print("=== ALL STATSCOMPONENT UNIT TESTS PASSED (9/9 GROUPS) ===")
	print("========================================")
	quit(0)
