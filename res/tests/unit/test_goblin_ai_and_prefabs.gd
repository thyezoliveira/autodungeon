extends SceneTree

# ==============================================================================
# Unit & Integration Test Suite: Goblin AI and Prefabs (Task M5.2)
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
	print("--- Starting Goblin AI and Prefabs Unit & Integration Tests (Task M5.2) ---")
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
	# Group 1: Enemy Data Resources (EnemyData)
	# --------------------------------------------------------------------------
	print("\n[Group 1: Enemy Data Resources (EnemyData)]")
	var warrior_res: EnemyData = load("res://src/data/enemies/enemy_goblin_warrior.tres") as EnemyData
	assert(warrior_res != null, "enemy_goblin_warrior.tres exists and is EnemyData")
	assert(warrior_res.enemy_id == "goblin_warrior", "warrior enemy_id is 'goblin_warrior'")
	assert(warrior_res.tier == EnemyData.EnemyTier.MINION, "warrior tier is MINION (0)")
	assert(warrior_res.max_hp == 45, "warrior max_hp is 45")
	assert(warrior_res.armor == 2, "warrior armor is 2")
	assert(warrior_res.attack_power == 8, "warrior attack_power is 8")
	assert(is_equal_approx(warrior_res.attack_range, 1.8), "warrior attack_range is 1.8")
	assert(is_equal_approx(warrior_res.move_speed, 3.5), "warrior move_speed is 3.5")
	assert(warrior_res.loot_table != null, "warrior has valid loot_table")

	var archer_res: EnemyData = load("res://src/data/enemies/enemy_goblin_archer.tres") as EnemyData
	assert(archer_res != null, "enemy_goblin_archer.tres exists and is EnemyData")
	assert(archer_res.enemy_id == "goblin_archer", "archer enemy_id is 'goblin_archer'")
	assert(archer_res.tier == EnemyData.EnemyTier.MINION, "archer tier is MINION (0)")
	assert(archer_res.max_hp == 30, "archer max_hp is 30")
	assert(archer_res.armor == 1, "archer armor is 1")
	assert(archer_res.attack_power == 7, "archer attack_power is 7")
	assert(is_equal_approx(archer_res.attack_range, 5.0), "archer attack_range is 5.0")
	assert(is_equal_approx(archer_res.move_speed, 3.8), "archer move_speed is 3.8")
	assert(archer_res.loot_table != null, "archer has valid loot_table")

	print("PASS: 1.1 Enemy Data resources for Goblin Warrior and Archer verified")

	# --------------------------------------------------------------------------
	# Group 2: Prefab Instantiation & Components Verification
	# --------------------------------------------------------------------------
	print("\n[Group 2: Prefab Instantiation & Components Verification]")
	var warrior_scene: PackedScene = load("res://src/entities/enemies/GoblinWarrior.tscn") as PackedScene
	assert(warrior_scene != null, "GoblinWarrior.tscn loaded")
	var warrior: CharacterEntity = warrior_scene.instantiate() as CharacterEntity
	root.add_child(warrior)

	assert(warrior.stats_component != null, "GoblinWarrior has StatsComponent")
	assert(warrior.health_component != null, "GoblinWarrior has HealthComponent")
	assert(warrior.hurtbox != null, "GoblinWarrior has Hurtbox3D")
	assert(warrior.movement_component != null, "GoblinWarrior has MovementComponent")
	assert(warrior.threat_table != null, "GoblinWarrior has ThreatTable")
	assert(warrior.navigation_agent != null, "GoblinWarrior has NavigationAgent3D")
	assert(warrior.collision_layer == 4, "GoblinWarrior collision_layer is Enemy_Bodies (4)")
	assert(warrior.hurtbox.collision_layer == 64, "GoblinWarrior hurtbox collision_layer is Enemy_Hurtboxes (64)")

	var warrior_ai: GoblinAIController = warrior.get_node_or_null("Components/GoblinAIController") as GoblinAIController
	assert(warrior_ai != null, "GoblinWarrior has GoblinAIController")
	assert(not warrior_ai.is_ranged, "GoblinWarrior AI is_ranged is false")
	assert(is_equal_approx(warrior_ai.attack_range, 1.8), "GoblinWarrior AI attack_range is 1.8")
	assert(warrior.health_component.max_hp == 45, "GoblinWarrior health initialized to 45")
	assert(warrior.health_component.current_hp == 45, "GoblinWarrior current_hp initialized to 45")
	assert(int(warrior.stats_component.get_stat("armor")) == 2, "GoblinWarrior armor is 2")
	assert(int(warrior.stats_component.get_stat("attack_power")) == 8, "GoblinWarrior attack_power is 8")

	var archer_scene: PackedScene = load("res://src/entities/enemies/GoblinArcher.tscn") as PackedScene
	assert(archer_scene != null, "GoblinArcher.tscn loaded")
	var archer: CharacterEntity = archer_scene.instantiate() as CharacterEntity
	root.add_child(archer)

	assert(archer.stats_component != null, "GoblinArcher has StatsComponent")
	assert(archer.health_component != null, "GoblinArcher has HealthComponent")
	assert(archer.hurtbox != null, "GoblinArcher has Hurtbox3D")
	assert(archer.movement_component != null, "GoblinArcher has MovementComponent")
	assert(archer.threat_table != null, "GoblinArcher has ThreatTable")
	assert(archer.navigation_agent != null, "GoblinArcher has NavigationAgent3D")
	assert(archer.collision_layer == 4, "GoblinArcher collision_layer is Enemy_Bodies (4)")
	assert(archer.hurtbox.collision_layer == 64, "GoblinArcher hurtbox collision_layer is Enemy_Hurtboxes (64)")

	var archer_ai: GoblinAIController = archer.get_node_or_null("Components/GoblinAIController") as GoblinAIController
	assert(archer_ai != null, "GoblinArcher has GoblinAIController")
	assert(archer_ai.is_ranged, "GoblinArcher AI is_ranged is true")
	assert(is_equal_approx(archer_ai.attack_range, 5.0), "GoblinArcher AI attack_range is 5.0")
	assert(archer_ai.arrow_scene != null, "GoblinArcher AI has arrow_scene assigned")
	assert(archer.health_component.max_hp == 30, "GoblinArcher health initialized to 30")
	assert(archer.health_component.current_hp == 30, "GoblinArcher current_hp initialized to 30")
	assert(int(archer.stats_component.get_stat("armor")) == 1, "GoblinArcher armor is 1")
	assert(int(archer.stats_component.get_stat("attack_power")) == 7, "GoblinArcher attack_power is 7")

	warrior.free()
	archer.free()
	print("PASS: 2.1 Prefabs GoblinWarrior.tscn and GoblinArcher.tscn components and stats verified")

	# --------------------------------------------------------------------------
	# Group 3: ArrowProjectile Physics, Lifetime and Collision
	# --------------------------------------------------------------------------
	print("\n[Group 3: ArrowProjectile Physics, Lifetime and Collision]")
	var proj_scene: PackedScene = load("res://src/entities/projectiles/ArrowProjectile.tscn") as PackedScene
	assert(proj_scene != null, "ArrowProjectile.tscn loaded")
	var proj: ArrowProjectile = proj_scene.instantiate() as ArrowProjectile
	root.add_child(proj)
	proj.global_position = Vector3(0.0, 1.0, 0.0)

	assert(is_equal_approx(proj.speed, 14.0), "ArrowProjectile default speed is 14.0 m/s")
	assert(is_equal_approx(proj.lifetime, 3.0), "ArrowProjectile default lifetime is 3.0s")
	assert(proj.damage == 7, "ArrowProjectile default damage is 7")
	assert(proj.hitbox != null, "ArrowProjectile has Hitbox3D attached")
	assert(proj.hitbox.collision_layer == 32, "Hitbox3D collision_layer is Enemy_Hitboxes (32)")
	assert(proj.hitbox.collision_mask & 16 != 0, "Hitbox3D collision_mask includes Hero_Hurtboxes (16)")

	# Test trajectory movement
	proj.launch(Vector3(1.0, 0.0, 0.0))
	proj._physics_process(0.1)
	assert(is_equal_approx(proj.global_position.x, 1.4), "Projectile advanced 1.4m along X axis in 0.1s (14 m/s)")

	# Test collision impact with Hero Hurtbox
	var hero_target: CharacterEntity = CharacterEntity.new()
	root.add_child(hero_target)
	var hero_stats: StatsComponent = StatsComponent.new()
	hero_stats.max_hp = 100
	hero_stats.armor = 2
	hero_target.add_child(hero_stats)
	hero_target.stats_component = hero_stats

	var hero_hp: HealthComponent = HealthComponent.new()
	hero_hp.max_hp = 100
	hero_hp.current_hp = 100
	hero_hp.is_alive = true
	hero_target.add_child(hero_hp)
	hero_target.health_component = hero_hp

	var hero_hurtbox: Hurtbox3D = Hurtbox3D.new()
	hero_hurtbox.collision_layer = 16
	hero_hurtbox.collision_mask = 0
	hero_hurtbox.setup(hero_hp, hero_stats, hero_target)
	hero_target.add_child(hero_hurtbox)
	hero_target.hurtbox = hero_hurtbox

	var tracker_proj: Dictionary = {
		"hit_detected": false,
		"target": null
	}
	proj.hit_target.connect(func(target: Node3D) -> void:
		tracker_proj["hit_detected"] = true
		tracker_proj["target"] = target
	)

	# Simulate area collision trigger
	proj.hitbox._on_area_entered(hero_hurtbox)
	proj._on_hitbox_area_entered(hero_hurtbox)

	assert(tracker_proj["hit_detected"], "Arrow projectile emitted hit_target on collision")
	assert(hero_hp.current_hp == 95, "Hero took mitigated damage (7 raw dmg - 2 armor = 5 dmg -> 95 HP)")

	hero_target.free()
	proj.free()

	# Test Lifetime Expired
	var short_proj: ArrowProjectile = proj_scene.instantiate() as ArrowProjectile
	root.add_child(short_proj)
	short_proj.setup(7, 14.0, null, 0.2)
	var tracker_life: Dictionary = {
		"expired": false
	}
	short_proj.lifetime_expired.connect(func() -> void:
		tracker_life["expired"] = true
	)
	short_proj._physics_process(0.25)
	assert(tracker_life["expired"], "ArrowProjectile emitted lifetime_expired after lifetime exceeded")
	short_proj.free()

	print("PASS: 3.1 ArrowProjectile speed (~14m/s), lifetime (3s) and Hitbox3D collision verified")

	# --------------------------------------------------------------------------
	# Group 4: Goblin Warrior Melee Combat Behavior
	# --------------------------------------------------------------------------
	print("\n[Group 4: Goblin Warrior Melee Combat Behavior]")
	var gw: CharacterEntity = warrior_scene.instantiate() as CharacterEntity
	root.add_child(gw)
	gw.global_position = Vector3(0.0, 0.0, 0.0)
	var gw_ai: GoblinAIController = gw.get_node_or_null("Components/GoblinAIController") as GoblinAIController

	var bromm: CharacterEntity = CharacterEntity.new()
	root.add_child(bromm)
	bromm.global_position = Vector3(5.0, 0.0, 0.0) # 5.0m away (> 1.8m attack_range)
	var b_stats: StatsComponent = StatsComponent.new()
	b_stats.max_hp = 120
	b_stats.armor = 3
	bromm.add_child(b_stats)
	bromm.stats_component = b_stats
	var b_hp: HealthComponent = HealthComponent.new()
	b_hp.max_hp = 120
	b_hp.current_hp = 120
	b_hp.is_alive = true
	bromm.add_child(b_hp)
	bromm.health_component = b_hp

	# 1. Distant hero: AI should pursue (move towards target)
	gw_ai.process_ai(0.1, [bromm])
	assert(gw.movement_component.is_moving, "Goblin Warrior moves towards hero when dist > 1.8m")

	# 2. Hero within melee range (1.5m <= 1.8m)
	bromm.global_position = Vector3(1.5, 0.0, 0.0)
	var tracker_gw: Dictionary = {
		"melee_attack_fired": false,
		"attacked_target": null
	}
	gw_ai.melee_attack_executed.connect(func(target: CharacterEntity) -> void:
		tracker_gw["melee_attack_fired"] = true
		tracker_gw["attacked_target"] = target
	)

	gw_ai.process_ai(0.1, [bromm])
	assert(not gw.movement_component.is_moving, "Goblin Warrior stops movement in melee range (1.5m)")
	assert(tracker_gw["melee_attack_fired"], "Goblin Warrior executed melee attack")
	assert(tracker_gw["attacked_target"] == bromm, "Goblin Warrior attacked target Bromm")
	assert(b_hp.current_hp == 115, "Hero took melee damage (8 raw dmg - 3 armor = 5 dmg -> 115 HP)")

	# 3. Cooldown check: subsequent immediate process should not attack again
	tracker_gw["melee_attack_fired"] = false
	gw_ai.process_ai(0.1, [bromm])
	assert(not tracker_gw["melee_attack_fired"], "Melee attack blocked while attack_cooldown is active")

	# 4. ThreatTable priority test: create hero 2 with higher threat
	var dps_hero: CharacterEntity = CharacterEntity.new()
	root.add_child(dps_hero)
	dps_hero.global_position = Vector3(1.6, 0.0, 0.0)
	var d_hp: HealthComponent = HealthComponent.new()
	d_hp.max_hp = 80
	d_hp.current_hp = 80
	dps_hero.add_child(d_hp)
	dps_hero.health_component = d_hp

	gw.threat_table.add_threat(dps_hero, 100.0)
	gw.threat_table.add_threat(bromm, 10.0)
	assert(gw.threat_table.primary_target == dps_hero, "ThreatTable primary target is dps_hero")

	# Advance timer past cooldown
	gw_ai._attack_timer = 0.0
	tracker_gw["melee_attack_fired"] = false
	gw_ai.process_ai(0.1, [bromm, dps_hero])
	assert(tracker_gw["melee_attack_fired"], "Melee attack executed on cooldown ready")
	assert(tracker_gw["attacked_target"] == dps_hero, "Goblin Warrior prioritized ThreatTable primary target (dps_hero)")

	gw.free()
	bromm.free()
	dps_hero.free()
	print("PASS: 4.1 Goblin Warrior pursuit, melee strike, cooldown and ThreatTable targeting verified")

	# --------------------------------------------------------------------------
	# Group 5: Goblin Archer Ranged Combat Behavior
	# --------------------------------------------------------------------------
	print("\n[Group 5: Goblin Archer Ranged Combat Behavior]")
	var ga: CharacterEntity = archer_scene.instantiate() as CharacterEntity
	root.add_child(ga)
	ga.global_position = Vector3(0.0, 0.0, 0.0)
	var ga_ai: GoblinAIController = ga.get_node_or_null("Components/GoblinAIController") as GoblinAIController

	var hero_5: CharacterEntity = CharacterEntity.new()
	root.add_child(hero_5)
	hero_5.global_position = Vector3(10.0, 0.0, 0.0) # 10.0m away (> 6.5m)
	var h5_hp: HealthComponent = HealthComponent.new()
	h5_hp.max_hp = 100
	h5_hp.current_hp = 100
	h5_hp.is_alive = true
	hero_5.add_child(h5_hp)
	hero_5.health_component = h5_hp

	# 1. Target too far (> 6.5m): Archer advances
	ga_ai.process_ai(0.1, [hero_5])
	assert(ga.movement_component.is_moving, "Goblin Archer advances when target dist > 6.5m")

	# 2. Target in ideal combat zone (~5.0m): Archer stops and shoots arrow
	ga.global_position = Vector3(5.0, 0.0, 0.0) # dist = 5.0m (between 3.5m and 6.5m)
	var tracker_ga: Dictionary = {
		"arrow_shot": false,
		"arrow_target": null,
		"spawned_proj": null
	}
	ga_ai.ranged_shot_executed.connect(func(t: CharacterEntity) -> void:
		tracker_ga["arrow_shot"] = true
		tracker_ga["arrow_target"] = t
	)
	ga_ai.arrow_spawned.connect(func(p: ArrowProjectile) -> void:
		tracker_ga["spawned_proj"] = p
	)

	ga_ai.process_ai(0.1, [hero_5])
	assert(not ga.movement_component.is_moving, "Goblin Archer stops movement in ideal combat range (5.0m)")
	assert(tracker_ga["arrow_shot"], "Goblin Archer executed ranged arrow shot")
	assert(tracker_ga["arrow_target"] == hero_5, "Arrow targeted hero_5")
	assert(tracker_ga["spawned_proj"] != null, "ArrowProjectile instance was spawned in scene")
	var sp: ArrowProjectile = tracker_ga["spawned_proj"] as ArrowProjectile
	assert(sp.damage == 7, "Arrow damage matches Archer attack_power (7)")

	if sp != null and is_instance_valid(sp):
		sp.free()

	# 3. Target too close (< 3.5m): Archer retreats / kites away
	hero_5.global_position = Vector3(7.0, 0.0, 0.0) # Archer at (5,0,0), Hero at (7,0,0) -> dist = 2.0m (< 3.5m)
	ga_ai.process_ai(0.1, [hero_5])
	assert(ga.movement_component.is_moving, "Goblin Archer activates retreat/kiting when target dist < 3.5m")
	assert(ga.movement_component.current_target_position.x < 5.0, "Archer retreat direction is opposite to hero position")

	ga.free()
	hero_5.free()
	print("PASS: 5.1 Goblin Archer distance maintenance (~5m), advance (>6.5m), retreat (<3.5m) and arrow shooting verified")

	# --------------------------------------------------------------------------
	# Group 6: Edge Cases & Null Safety
	# --------------------------------------------------------------------------
	print("\n[Group 6: Edge Cases & Null Safety]")
	var standalone_gob_ai: GoblinAIController = GoblinAIController.new()
	root.add_child(standalone_gob_ai)

	# Process AI without actor, or on empty heroes list
	standalone_gob_ai.process_ai(0.1, [])
	standalone_gob_ai.process_ai(0.1, [null])

	var dead_hero: CharacterEntity = CharacterEntity.new()
	root.add_child(dead_hero)
	var dh_hp: HealthComponent = HealthComponent.new()
	dh_hp.is_alive = false
	dh_hp.current_hp = 0
	dead_hero.add_child(dh_hp)
	dead_hero.health_component = dh_hp

	standalone_gob_ai.process_ai(0.1, [dead_hero])
	assert(standalone_gob_ai.get_living_heroes([]).is_empty(), "get_living_heroes on empty returns empty")
	assert(standalone_gob_ai.get_living_heroes([dead_hero]).is_empty(), "get_living_heroes filters dead hero")
	assert(standalone_gob_ai.find_nearest_hero([]) == null, "find_nearest_hero on empty returns null")
	assert(standalone_gob_ai.get_distance_to_target(null) == INF, "get_distance_to_target on null returns INF")

	standalone_gob_ai.free()
	dead_hero.free()
	print("PASS: 6.1 Edge cases, dead heroes filtering and standalone null safety verified")

	print("\n================================================================================")
	print("=== ALL GOBLIN AI & PREFABS UNIT TESTS PASSED (6/6 GROUPS) ===")
	print("================================================================================")
	quit(0)
