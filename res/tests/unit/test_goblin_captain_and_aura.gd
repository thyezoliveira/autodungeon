extends SceneTree

# ==============================================================================
# Unit & Integration Test Suite: Goblin Captain and Tribal Fury Aura (Task M5.4)
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
	print("--- Starting Goblin Captain & Tribal Fury Aura Unit Tests (Task M5.4) ---")
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
	# Group 1: Enemy Data Resource (enemy_goblin_captain.tres)
	# --------------------------------------------------------------------------
	print("\n[Group 1: Enemy Data Resource (enemy_goblin_captain.tres)]")
	var captain_res: EnemyData = load("res://src/data/enemies/enemy_goblin_captain.tres") as EnemyData
	assert(captain_res != null, "enemy_goblin_captain.tres exists and is EnemyData")
	assert(captain_res.enemy_id == "goblin_captain", "captain enemy_id is 'goblin_captain'")
	assert(captain_res.enemy_name == "Capitão Goblin", "captain enemy_name is 'Capitão Goblin'")
	assert(captain_res.tier == EnemyData.EnemyTier.ELITE, "captain tier is ELITE (1)")
	assert(captain_res.max_hp == 140, "captain max_hp is 140")
	assert(captain_res.armor == 5, "captain armor is 5")
	assert(captain_res.attack_power == 16, "captain attack_power is 16")
	assert(is_equal_approx(captain_res.attack_range, 2.0), "captain attack_range is 2.0")
	assert(is_equal_approx(captain_res.move_speed, 3.6), "captain move_speed is 3.6")
	assert(captain_res.loot_table != null, "captain has valid loot_table")

	print("PASS: 1.1 Enemy Data resource for Goblin Captain verified")

	# --------------------------------------------------------------------------
	# Group 2: Prefab Instantiation & Components Verification (GoblinCaptain.tscn)
	# --------------------------------------------------------------------------
	print("\n[Group 2: Prefab Instantiation & Components Verification]")
	var captain_scene: PackedScene = load("res://src/entities/enemies/GoblinCaptain.tscn") as PackedScene
	assert(captain_scene != null, "GoblinCaptain.tscn loaded")
	var captain: CharacterEntity = captain_scene.instantiate() as CharacterEntity
	root.add_child(captain)

	assert(captain.stats_component != null, "GoblinCaptain has StatsComponent")
	assert(captain.health_component != null, "GoblinCaptain has HealthComponent")
	assert(captain.hurtbox != null, "GoblinCaptain has Hurtbox3D")
	assert(captain.movement_component != null, "GoblinCaptain has MovementComponent")
	assert(captain.threat_table != null, "GoblinCaptain has ThreatTable")
	assert(captain.navigation_agent != null, "GoblinCaptain has NavigationAgent3D")
	assert(captain.collision_layer == 4, "GoblinCaptain collision_layer is Enemy_Bodies (4)")
	assert(captain.hurtbox.collision_layer == 64, "GoblinCaptain hurtbox collision_layer is Enemy_Hurtboxes (64)")

	var captain_ai: GoblinAIController = captain.get_node_or_null("Components/GoblinAIController") as GoblinAIController
	assert(captain_ai != null, "GoblinCaptain has GoblinAIController")
	assert(not captain_ai.is_ranged, "GoblinCaptain AI is_ranged is false")
	assert(is_equal_approx(captain_ai.attack_range, 2.0), "GoblinCaptain AI attack_range is 2.0")

	var aura: AuraDeFuriaTribal = captain.get_node_or_null("Components/AuraDeFuriaTribal") as AuraDeFuriaTribal
	assert(aura != null, "GoblinCaptain has AuraDeFuriaTribal attached")
	assert(is_equal_approx(aura.damage_multiplier_bonus, 0.25), "Aura damage_multiplier_bonus is 0.25 (+25%)")
	assert(is_equal_approx(aura.aura_radius, 6.0), "Aura aura_radius is 6.0m")
	assert(aura.source_captain == captain, "Aura source_captain references the captain entity")

	assert(captain.health_component.max_hp == 140, "GoblinCaptain health initialized to 140")
	assert(captain.health_component.current_hp == 140, "GoblinCaptain current_hp initialized to 140")
	assert(int(captain.stats_component.get_stat("armor")) == 5, "GoblinCaptain armor is 5")
	assert(int(captain.stats_component.get_stat("attack_power")) == 16, "GoblinCaptain attack_power is 16")
	assert(is_equal_approx(captain.stats_component.get_stat("move_speed"), 3.6), "GoblinCaptain move_speed is 3.6")

	captain.free()
	print("PASS: 2.1 Prefab GoblinCaptain.tscn components, wiring, aura and stats verified")

	# --------------------------------------------------------------------------
	# Group 3: Aura Buff Mechanics on Ally Goblins (+25% Damage & Removal on Exit)
	# --------------------------------------------------------------------------
	print("\n[Group 3: Aura Buff Mechanics on Ally Goblins]")
	var capt3: CharacterEntity = captain_scene.instantiate() as CharacterEntity
	root.add_child(capt3)
	var aura3: AuraDeFuriaTribal = capt3.get_node_or_null("Components/AuraDeFuriaTribal") as AuraDeFuriaTribal

	var warrior_scene: PackedScene = load("res://src/entities/enemies/GoblinWarrior.tscn") as PackedScene
	var warrior3: CharacterEntity = warrior_scene.instantiate() as CharacterEntity
	root.add_child(warrior3)

	# 1. Base damage outside aura: 8
	var initial_atk: float = warrior3.stats_component.get_stat("attack_power")
	assert(int(initial_atk) == 8, "Warrior base attack_power outside aura is 8")

	var tracker_buff: Dictionary = {
		"buffed": false,
		"unbuffed": false
	}
	aura3.ally_buffed.connect(func(ally: CharacterEntity) -> void:
		if ally == warrior3:
			tracker_buff["buffed"] = true
	)
	aura3.ally_unbuffed.connect(func(ally: CharacterEntity) -> void:
		if ally == warrior3:
			tracker_buff["unbuffed"] = true
	)

	# 2. Enter Aura (within 6.0m): +25% attack_power (8 -> 10)
	var buff_success: bool = aura3.apply_buff_to_entity(warrior3)
	assert(buff_success, "Aura buff successfully applied to ally warrior")
	assert(aura3.is_entity_buffed(warrior3), "Warrior registered in aura's _buffed_allies list")
	assert(tracker_buff["buffed"], "Aura emitted ally_buffed signal")

	var buffed_atk: float = warrior3.stats_component.get_stat("attack_power")
	assert(int(buffed_atk) == 10, "Warrior attack_power increased by +25% (8 -> 10)")
	assert(is_equal_approx(buffed_atk, 10.0), "Warrior attack_power is exact 10.0")

	# Duplicate apply attempt should be rejected
	assert(not aura3.apply_buff_to_entity(warrior3), "Duplicate apply_buff_to_entity is safely rejected")

	# 3. Exit Aura: attack_power returns to base (10 -> 8)
	var unbuff_success: bool = aura3.remove_buff_from_entity(warrior3)
	assert(unbuff_success, "Aura buff successfully removed from exiting ally warrior")
	assert(not aura3.is_entity_buffed(warrior3), "Warrior removed from aura's _buffed_allies list")
	assert(tracker_buff["unbuffed"], "Aura emitted ally_unbuffed signal")

	var restored_atk: float = warrior3.stats_component.get_stat("attack_power")
	assert(int(restored_atk) == 8, "Warrior attack_power restored to original value (8)")

	capt3.free()
	warrior3.free()
	print("PASS: 3.1 Aura buff application (+25%, 8 -> 10) and exit removal (10 -> 8) verified")

	# --------------------------------------------------------------------------
	# Group 4: Automatic Aura Deactivation on Captain Death
	# --------------------------------------------------------------------------
	print("\n[Group 4: Aura Deactivation on Captain Death]")
	var capt4: CharacterEntity = captain_scene.instantiate() as CharacterEntity
	root.add_child(capt4)
	var aura4: AuraDeFuriaTribal = capt4.get_node_or_null("Components/AuraDeFuriaTribal") as AuraDeFuriaTribal

	var warrior4: CharacterEntity = warrior_scene.instantiate() as CharacterEntity
	root.add_child(warrior4)

	var archer_scene: PackedScene = load("res://src/entities/enemies/GoblinArcher.tscn") as PackedScene
	var archer4: CharacterEntity = archer_scene.instantiate() as CharacterEntity
	root.add_child(archer4)

	# Buff both allies
	aura4.apply_buff_to_entity(warrior4)
	aura4.apply_buff_to_entity(archer4)

	assert(int(warrior4.stats_component.get_stat("attack_power")) == 10, "Warrior buffed to 10 attack power")
	# Archer base = 7, +25% = 8.75
	assert(is_equal_approx(archer4.stats_component.get_stat("attack_power"), 8.75), "Archer buffed to 8.75 attack power")
	assert(aura4.get_buffed_allies().size() == 2, "Aura currently tracking 2 buffed allies")

	var tracker_deact: Dictionary = {
		"deactivated": false
	}
	aura4.aura_deactivated.connect(func() -> void:
		tracker_deact["deactivated"] = true
	)

	# Kill the captain (140 HP -> fatal damage 200)
	capt4.health_component.take_damage(200, 0)
	assert(not capt4.health_component.is_alive, "Captain health_component is dead")
	assert(tracker_deact["deactivated"], "Aura automatically deactivated on captain death")
	assert(aura4.get_buffed_allies().is_empty(), "Buffed allies list cleared upon captain death")

	# All allies must revert to unbuffed base values immediately
	assert(int(warrior4.stats_component.get_stat("attack_power")) == 8, "Warrior attack_power immediately reverted to 8 upon captain death")
	assert(int(archer4.stats_component.get_stat("attack_power")) == 7, "Archer attack_power immediately reverted to 7 upon captain death")

	# Subsequent entry attempts into dead captain's aura are rejected
	var new_warrior: CharacterEntity = warrior_scene.instantiate() as CharacterEntity
	root.add_child(new_warrior)
	assert(not aura4.apply_buff_to_entity(new_warrior), "Cannot buff allies when aura is deactivated")
	assert(int(new_warrior.stats_component.get_stat("attack_power")) == 8, "New warrior remains at base attack power 8")

	capt4.free()
	warrior4.free()
	archer4.free()
	new_warrior.free()
	print("PASS: 4.1 Instantaneous aura deactivation and stat reversion upon Captain death verified")

	# --------------------------------------------------------------------------
	# Group 5: Manual deactivate_aura() Method Invocation
	# --------------------------------------------------------------------------
	print("\n[Group 5: Manual deactivate_aura() Invocation]")
	var capt5: CharacterEntity = captain_scene.instantiate() as CharacterEntity
	root.add_child(capt5)
	var aura5: AuraDeFuriaTribal = capt5.get_node_or_null("Components/AuraDeFuriaTribal") as AuraDeFuriaTribal

	var warrior5: CharacterEntity = warrior_scene.instantiate() as CharacterEntity
	root.add_child(warrior5)

	aura5.apply_buff_to_entity(warrior5)
	assert(int(warrior5.stats_component.get_stat("attack_power")) == 10, "Warrior buffed to 10")

	# Manually deactivate
	aura5.deactivate_aura()
	assert(int(warrior5.stats_component.get_stat("attack_power")) == 8, "Warrior reverted to 8 on manual deactivate_aura()")
	assert(aura5.get_buffed_allies().is_empty(), "Aura ally list empty after manual deactivation")

	capt5.free()
	warrior5.free()
	print("PASS: 5.1 Manual deactivate_aura() method invocation verified")

	# --------------------------------------------------------------------------
	# Group 6: Exemption of Heroes and Captain Self
	# --------------------------------------------------------------------------
	print("\n[Group 6: Exemption of Heroes and Captain Self]")
	var capt6: CharacterEntity = captain_scene.instantiate() as CharacterEntity
	root.add_child(capt6)
	var aura6: AuraDeFuriaTribal = capt6.get_node_or_null("Components/AuraDeFuriaTribal") as AuraDeFuriaTribal

	# 1. Hero Entity (Hero_Bodies / layer 2)
	var hero_entity: CharacterEntity = CharacterEntity.new()
	root.add_child(hero_entity)
	hero_entity.collision_layer = 2 # Hero_Bodies
	var hero_stats: StatsComponent = StatsComponent.new()
	hero_stats.attack_power = 20
	hero_entity.add_child(hero_stats)
	hero_entity.stats_component = hero_stats

	var hero_buff_res: bool = aura6.apply_buff_to_entity(hero_entity)
	assert(not hero_buff_res, "Hero entity cannot receive Tribal Fury aura buff")
	assert(not aura6.is_entity_buffed(hero_entity), "Hero not in buffed allies list")
	assert(int(hero_stats.get_stat("attack_power")) == 20, "Hero attack_power remains unmodified at 20")

	# Test _on_body_entered with Hero
	aura6._on_body_entered(hero_entity)
	assert(not aura6.is_entity_buffed(hero_entity), "Hero body entering aura is ignored")
	assert(int(hero_stats.get_stat("attack_power")) == 20, "Hero attack_power remains 20 after body_entered")

	# 2. Captain self exemption from ally buff
	var captain_buff_res: bool = aura6.apply_buff_to_entity(capt6)
	assert(not captain_buff_res, "Captain cannot buff itself as an ally")
	assert(int(capt6.stats_component.get_stat("attack_power")) == 16, "Captain base attack_power remains 16")

	capt6.free()
	hero_entity.free()
	print("PASS: 6.1 Hero entity exemption and Captain self-buff exemption verified")

	# --------------------------------------------------------------------------
	# Group 7: Captain AI Combat & Melee Range Execution
	# --------------------------------------------------------------------------
	print("\n[Group 7: Captain AI Combat & Melee Range Execution]")
	var capt7: CharacterEntity = captain_scene.instantiate() as CharacterEntity
	root.add_child(capt7)
	capt7.global_position = Vector3(0.0, 0.0, 0.0)
	var ai7: GoblinAIController = capt7.get_node_or_null("Components/GoblinAIController") as GoblinAIController

	var target_hero: CharacterEntity = CharacterEntity.new()
	root.add_child(target_hero)
	target_hero.global_position = Vector3(1.8, 0.0, 0.0) # within 2.0m attack range
	var th_stats: StatsComponent = StatsComponent.new()
	th_stats.max_hp = 100
	th_stats.armor = 4
	target_hero.add_child(th_stats)
	target_hero.stats_component = th_stats
	var th_hp: HealthComponent = HealthComponent.new()
	th_hp.max_hp = 100
	th_hp.current_hp = 100
	th_hp.is_alive = true
	target_hero.add_child(th_hp)
	target_hero.health_component = th_hp

	var tracker_capt_atk: Dictionary = {
		"attacked": false,
		"target": null
	}
	ai7.melee_attack_executed.connect(func(t: CharacterEntity) -> void:
		tracker_capt_atk["attacked"] = true
		tracker_capt_atk["target"] = t
	)

	ai7.process_ai(0.1, [target_hero])
	assert(tracker_capt_atk["attacked"], "Captain executed melee attack on hero in 2.0m range")
	assert(tracker_capt_atk["target"] == target_hero, "Target attacked was target_hero")
	# Damage calculation: 16 attack_power - 4 armor = 12 damage -> HP: 100 - 12 = 88
	assert(th_hp.current_hp == 88, "Hero took 12 mitigated damage from Captain (16 raw - 4 armor -> 88 HP)")

	capt7.free()
	target_hero.free()
	print("PASS: 7.1 Captain melee combat (16 attack power, 2.0m attack range) verified")

	# --------------------------------------------------------------------------
	# Group 8: Edge Cases, Killed Ally in Aura & Null Safety
	# --------------------------------------------------------------------------
	print("\n[Group 8: Edge Cases, Killed Ally & Null Safety]")
	var standalone_aura: AuraDeFuriaTribal = AuraDeFuriaTribal.new()
	root.add_child(standalone_aura)

	# Null safety
	assert(not standalone_aura.apply_buff_to_entity(null), "apply_buff_to_entity(null) returns false")
	assert(not standalone_aura.remove_buff_from_entity(null), "remove_buff_from_entity(null) returns false")
	standalone_aura._on_body_entered(null)
	standalone_aura._on_body_exited(null)

	# Dead ally cannot be buffed
	var dead_warrior: CharacterEntity = warrior_scene.instantiate() as CharacterEntity
	root.add_child(dead_warrior)
	dead_warrior.health_component.current_hp = 0
	dead_warrior.health_component.is_alive = false

	assert(not standalone_aura.apply_buff_to_entity(dead_warrior), "Dead ally cannot be buffed")

	# Ally dies while buffed inside aura: removed via EventBus entity_died
	var live_warrior: CharacterEntity = warrior_scene.instantiate() as CharacterEntity
	root.add_child(live_warrior)
	standalone_aura.apply_buff_to_entity(live_warrior)
	assert(standalone_aura.is_entity_buffed(live_warrior), "Live warrior buffed")

	var bus: EventBusSingleton = root.get_node("EventBus") as EventBusSingleton
	bus.entity_died.emit(live_warrior, null)
	assert(not standalone_aura.is_entity_buffed(live_warrior), "Killed ally removed from buffed list via EventBus.entity_died")

	standalone_aura.free()
	dead_warrior.free()
	live_warrior.free()
	print("PASS: 8.1 Dead ally rejection, buff removal on ally death and null safety verified")

	print("\n================================================================================")
	print("=== ALL GOBLIN CAPTAIN & TRIBAL FURY AURA UNIT TESTS PASSED (8/8 GROUPS) ===")
	print("================================================================================")
	quit(0)
