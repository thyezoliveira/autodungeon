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
	print("--- Starting Item & Enemy Resources Unit Tests ---")
	print("========================================")

	# ----------------------------------------------------
	# Test Group 1: ItemData Resource Structure, Defaults & Enums
	# ----------------------------------------------------
	print("\n[Group 1: ItemData Structure, Defaults & Enums]")
	var item: ItemData = ItemData.new()
	assert(item != null, "ItemData instance must be created")
	assert(item.item_id == "", "Default item_id should be empty")
	assert(item.item_name == "", "Default item_name should be empty")
	assert(item.description == "", "Default description should be empty")
	assert(item.icon == null, "Default icon should be null")
	assert(item.item_type == ItemData.ItemType.CONSUMABLE, "Default item_type should be CONSUMABLE")
	assert(item.gold_value == 10, "Default gold_value should be 10")
	assert(item.heal_amount == 0, "Default heal_amount should be 0")
	assert(is_equal_approx(item.auto_trigger_hp_threshold, 0.30), "Default auto_trigger_hp_threshold should be 0.30")
	print("PASS: 1.1 ItemData default values")

	# Enum values validation
	assert(ItemData.ItemType.WEAPON == 0, "ItemType.WEAPON enum mismatch")
	assert(ItemData.ItemType.ARMOR == 1, "ItemType.ARMOR enum mismatch")
	assert(ItemData.ItemType.CONSUMABLE == 2, "ItemType.CONSUMABLE enum mismatch")
	assert(ItemData.ItemType.MATERIAL == 3, "ItemType.MATERIAL enum mismatch")
	assert(ItemData.ItemType.GOLD == 4, "ItemType.GOLD enum mismatch")
	print("PASS: 1.2 ItemData ItemType enum values")

	# Custom mutation
	item.item_id = "test_sword"
	item.item_name = "Espada de Aço"
	item.description = "Uma lâmina afiada."
	item.item_type = ItemData.ItemType.WEAPON
	item.gold_value = 120
	item.heal_amount = 0
	item.auto_trigger_hp_threshold = 0.0
	assert(item.item_id == "test_sword", "Custom item_id applied")
	assert(item.item_name == "Espada de Aço", "Custom item_name applied")
	assert(item.description == "Uma lâmina afiada.", "Custom description applied")
	assert(item.item_type == ItemData.ItemType.WEAPON, "Custom item_type applied")
	assert(item.gold_value == 120, "Custom gold_value applied")
	assert(item.heal_amount == 0, "Custom heal_amount applied")
	assert(is_equal_approx(item.auto_trigger_hp_threshold, 0.0), "Custom auto_trigger_hp_threshold applied")
	print("PASS: 1.3 ItemData custom mutation")

	# ----------------------------------------------------
	# Test Group 2: LootTableResource Structure, Gold & Loot Rolling
	# ----------------------------------------------------
	print("\n[Group 2: LootTableResource Structure, Gold & Loot Rolling]")
	var loot_table: LootTableResource = LootTableResource.new()
	assert(loot_table != null, "LootTableResource instance must be created")
	assert(loot_table.possible_items is Array[ItemData], "possible_items must be typed Array[ItemData]")
	assert(loot_table.possible_items.size() == 0, "Default possible_items should be empty")
	assert(loot_table.drop_chances is Array[float], "drop_chances must be typed Array[float]")
	assert(loot_table.drop_chances.size() == 0, "Default drop_chances should be empty")
	assert(loot_table.min_gold == 5, "Default min_gold should be 5")
	assert(loot_table.max_gold == 20, "Default max_gold should be 20")
	print("PASS: 2.1 LootTableResource default values")

	# Empty table roll tests
	var empty_roll: Array[ItemData] = loot_table.roll_loot()
	assert(empty_roll.size() == 0, "Empty loot table must return empty array")
	print("PASS: 2.2 Empty loot table roll")

	# Gold rolling test
	loot_table.min_gold = 10
	loot_table.max_gold = 30
	for i in range(100):
		var gold: int = loot_table.roll_gold()
		assert(gold >= 10 and gold <= 30, "Gold rolled (%d) must be within [10, 30]" % gold)
	print("PASS: 2.3 Gold roll range distribution (100 rolls)")

	# Inverted / equal gold bounds safety
	loot_table.min_gold = 50
	loot_table.max_gold = 50
	assert(loot_table.roll_gold() == 50, "Equal gold bounds should return min_gold")
	loot_table.min_gold = 100
	loot_table.max_gold = 50
	assert(loot_table.roll_gold() == 100, "min_gold > max_gold should safely return min_gold")
	print("PASS: 2.4 Gold roll boundary safety")

	# Deterministic loot roll tests (Guaranteed & Zero drop)
	var item_guaranteed: ItemData = ItemData.new()
	item_guaranteed.item_id = "guaranteed_gem"
	var item_never: ItemData = ItemData.new()
	item_never.item_id = "never_gem"

	loot_table.possible_items = [item_guaranteed, item_never]
	loot_table.drop_chances = [1.0, 0.0]

	for i in range(50):
		var drops: Array[ItemData] = loot_table.roll_loot()
		assert(drops.size() == 1, "Guaranteed item should drop exactly 1 item per roll")
		assert(drops[0].item_id == "guaranteed_gem", "Dropped item must be guaranteed_gem")
	print("PASS: 2.5 Deterministic loot roll (1.0 vs 0.0 chances)")

	# Probabilistic drop validation (25% chance over 1000 rolls)
	var item_chance: ItemData = ItemData.new()
	item_chance.item_id = "chance_item"
	loot_table.possible_items = [item_chance]
	loot_table.drop_chances = [0.25]

	var total_dropped_count: int = 0
	var sample_size: int = 1000
	for i in range(sample_size):
		var drops: Array[ItemData] = loot_table.roll_loot()
		if drops.size() > 0:
			total_dropped_count += 1

	var drop_ratio: float = float(total_dropped_count) / float(sample_size)
	print("    [Info] 25 percent drop test: %d/%d (ratio: %.3f)" % [total_dropped_count, sample_size, drop_ratio])
	# Statistical confidence interval: 0.25 +/- 0.08
	assert(drop_ratio >= 0.17 and drop_ratio <= 0.33, "Drop ratio (" + str(drop_ratio) + ") should be around 0.25")
	print("PASS: 2.6 Probabilistic loot roll distribution (1000 rolls)")

	# ----------------------------------------------------
	# Test Group 3: EnemyData Resource Structure, Defaults & Enums
	# ----------------------------------------------------
	print("\n[Group 3: EnemyData Structure, Defaults & Enums]")
	var enemy: EnemyData = EnemyData.new()
	assert(enemy != null, "EnemyData instance must be created")
	assert(enemy.enemy_id == "", "Default enemy_id should be empty")
	assert(enemy.enemy_name == "", "Default enemy_name should be empty")
	assert(enemy.tier == EnemyData.EnemyTier.MINION, "Default tier should be MINION")
	assert(enemy.max_hp == 50, "Default max_hp should be 50")
	assert(enemy.armor == 2, "Default armor should be 2")
	assert(enemy.attack_power == 8, "Default attack_power should be 8")
	assert(is_equal_approx(enemy.attack_range, 1.8), "Default attack_range should be 1.8")
	assert(is_equal_approx(enemy.move_speed, 3.5), "Default move_speed should be 3.5")
	assert(enemy.loot_table == null, "Default loot_table should be null")
	assert(enemy.skills is Array[SkillData], "skills must be typed Array[SkillData]")
	assert(enemy.skills.size() == 0, "Default skills should be empty")
	print("PASS: 3.1 EnemyData default values")

	# EnemyTier enum validation
	assert(EnemyData.EnemyTier.MINION == 0, "EnemyTier.MINION enum mismatch")
	assert(EnemyData.EnemyTier.ELITE == 1, "EnemyTier.ELITE enum mismatch")
	assert(EnemyData.EnemyTier.BOSS == 2, "EnemyTier.BOSS enum mismatch")
	print("PASS: 3.2 EnemyData EnemyTier enum values")

	# Custom mutation
	enemy.enemy_id = "dragon_boss"
	enemy.enemy_name = "Dragão Rubro"
	enemy.tier = EnemyData.EnemyTier.BOSS
	enemy.max_hp = 2500
	enemy.armor = 40
	enemy.attack_power = 95
	enemy.attack_range = 4.5
	enemy.move_speed = 2.8

	var fire_skill: SkillData = SkillData.new()
	fire_skill.id = "fire_breath"
	fire_skill.display_name = "Sopro de Fogo"
	enemy.skills.append(fire_skill)

	assert(enemy.enemy_id == "dragon_boss", "Custom enemy_id applied")
	assert(enemy.enemy_name == "Dragão Rubro", "Custom enemy_name applied")
	assert(enemy.tier == EnemyData.EnemyTier.BOSS, "Custom tier applied")
	assert(enemy.max_hp == 2500, "Custom max_hp applied")
	assert(enemy.armor == 40, "Custom armor applied")
	assert(enemy.attack_power == 95, "Custom attack_power applied")
	assert(is_equal_approx(enemy.attack_range, 4.5), "Custom attack_range applied")
	assert(is_equal_approx(enemy.move_speed, 2.8), "Custom move_speed applied")
	assert(enemy.skills.size() == 1, "Enemy skills size verified")
	assert(enemy.skills[0].id == "fire_breath", "Enemy skill id verified")
	print("PASS: 3.3 EnemyData custom mutation and skills association")

	# ----------------------------------------------------
	# Test Group 4: item_potion_minor_hp.tres Resource Loading & Integrity
	# ----------------------------------------------------
	print("\n[Group 4: item_potion_minor_hp.tres Resource File]")
	var potion_path: String = "res://src/data/items/consumables/item_potion_minor_hp.tres"
	assert(ResourceLoader.exists(potion_path), "Resource file item_potion_minor_hp.tres must exist on disk")

	var loaded_potion_res: Resource = ResourceLoader.load(potion_path)
	assert(loaded_potion_res != null, "item_potion_minor_hp.tres must load successfully")
	assert(loaded_potion_res is ItemData, "Loaded resource must be an instance of ItemData")

	var potion: ItemData = loaded_potion_res as ItemData
	assert(potion.item_id == "potion_minor_hp", "Item ID must be 'potion_minor_hp'")
	assert(potion.item_name == "Poção de Vida Menor", "Item name must be 'Poção de Vida Menor'")
	assert(potion.item_type == ItemData.ItemType.CONSUMABLE, "Item type must be CONSUMABLE")
	assert(potion.heal_amount == 35, "heal_amount must be 35")
	assert(is_equal_approx(potion.auto_trigger_hp_threshold, 0.30), "auto_trigger_hp_threshold must be 0.30")
	assert(potion.gold_value == 15, "gold_value must be 15")
	print("PASS: 4.1 item_potion_minor_hp.tres loaded and validated successfully")

	# ----------------------------------------------------
	# Test Group 5: enemy_goblin_warrior.tres Resource Loading & Composition
	# ----------------------------------------------------
	print("\n[Group 5: enemy_goblin_warrior.tres Resource File & Composition]")
	var goblin_path: String = "res://src/data/enemies/enemy_goblin_warrior.tres"
	assert(ResourceLoader.exists(goblin_path), "Resource file enemy_goblin_warrior.tres must exist on disk")

	var loaded_goblin_res: Resource = ResourceLoader.load(goblin_path)
	assert(loaded_goblin_res != null, "enemy_goblin_warrior.tres must load successfully")
	assert(loaded_goblin_res is EnemyData, "Loaded resource must be an instance of EnemyData")

	var goblin: EnemyData = loaded_goblin_res as EnemyData
	assert(goblin.enemy_id == "goblin_warrior", "Enemy ID must be 'goblin_warrior'")
	assert(goblin.enemy_name == "Goblin Guerreiro", "Enemy name must be 'Goblin Guerreiro'")
	assert(goblin.tier == EnemyData.EnemyTier.MINION, "Goblin tier must be MINION")
	assert(goblin.max_hp == 45, "Goblin max_hp must be 45")
	assert(goblin.armor == 2, "Goblin armor must be 2")
	assert(goblin.attack_power == 8, "Goblin attack_power must be 8")
	assert(is_equal_approx(goblin.attack_range, 1.8), "Goblin attack_range must be 1.8")
	assert(is_equal_approx(goblin.move_speed, 3.5), "Goblin move_speed must be 3.5")
	assert(goblin.loot_table != null, "Goblin must have a configured loot_table")
	assert(goblin.loot_table is LootTableResource, "Goblin loot_table must be LootTableResource")
	assert(goblin.loot_table.min_gold == 3, "Goblin loot min_gold must be 3")
	assert(goblin.loot_table.max_gold == 12, "Goblin loot max_gold must be 12")
	assert(goblin.loot_table.possible_items.size() == 1, "Goblin loot table has 1 possible item")
	assert(goblin.loot_table.possible_items[0].item_id == "potion_minor_hp", "Goblin drops minor HP potion")

	# Test loot roll on goblin's configured loot table
	var goblin_gold_drop: int = goblin.loot_table.roll_gold()
	assert(goblin_gold_drop >= 3 and goblin_gold_drop <= 12, "Goblin gold drop within range [3, 12]")
	print("PASS: 5.1 enemy_goblin_warrior.tres loaded, composed and validated successfully")

	print("\n========================================")
	print("=== ALL ITEM & ENEMY RESOURCES UNIT TESTS PASSED ===")
	print("========================================")
	quit(0)
