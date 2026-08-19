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
	print("--- Starting EventBus Unit Tests ---")
	print("========================================")

	var bus: EventBusSingleton = null
	if root.has_node("EventBus"):
		bus = root.get_node("EventBus") as EventBusSingleton
		print("PASS: EventBus Autoload node found in SceneTree root")
	else:
		bus = EventBusSingleton.new()
		root.add_child(bus)
		print("INFO: Instantiated EventBusSingleton manually for SceneTree test harness")

	assert(bus != null, "EventBus instance must not be null")

	# Test 1: entity_spawned
	var entity_a: Node3D = Node3D.new()
	var state_spawned: Dictionary = {"received": false, "entity": null}
	var cb_spawned: Callable = func(ent: Node3D) -> void:
		state_spawned["received"] = true
		state_spawned["entity"] = ent

	bus.entity_spawned.connect(cb_spawned)
	bus.entity_spawned.emit(entity_a)
	assert(state_spawned["received"] == true, "entity_spawned signal was not received")
	assert(state_spawned["entity"] == entity_a, "entity_spawned param mismatch")
	bus.entity_spawned.disconnect(cb_spawned)
	print("PASS: 1. entity_spawned")

	# Test 2: entity_died
	var killer_node: Node3D = Node3D.new()
	var state_died: Dictionary = {"received": false, "entity": null, "killer": null}
	var cb_died: Callable = func(ent: Node3D, kil: Node3D) -> void:
		state_died["received"] = true
		state_died["entity"] = ent
		state_died["killer"] = kil

	bus.entity_died.connect(cb_died)
	bus.entity_died.emit(entity_a, killer_node)
	assert(state_died["received"] == true, "entity_died signal was not received")
	assert(state_died["entity"] == entity_a and state_died["killer"] == killer_node, "entity_died param mismatch")
	bus.entity_died.disconnect(cb_died)
	print("PASS: 2. entity_died")

	# Test 3: damage_dealt
	var state_damage: Dictionary = {
		"received": false,
		"target": null,
		"source": null,
		"amount": 0,
		"is_critical": false,
		"is_blocked": false
	}
	var cb_damage: Callable = func(target: Node3D, source: Node3D, amount: int, is_critical: bool, is_blocked: bool) -> void:
		state_damage["received"] = true
		state_damage["target"] = target
		state_damage["source"] = source
		state_damage["amount"] = amount
		state_damage["is_critical"] = is_critical
		state_damage["is_blocked"] = is_blocked

	bus.damage_dealt.connect(cb_damage)
	bus.damage_dealt.emit(entity_a, killer_node, 42, true, false)
	assert(state_damage["received"] == true, "damage_dealt signal was not received")
	assert(state_damage["target"] == entity_a and state_damage["source"] == killer_node and state_damage["amount"] == 42 and state_damage["is_critical"] == true and state_damage["is_blocked"] == false, "damage_dealt param mismatch")
	bus.damage_dealt.disconnect(cb_damage)
	print("PASS: 3. damage_dealt")

	# Test 4: healing_applied
	var state_heal: Dictionary = {"received": false, "target": null, "healer": null, "amount": 0}
	var cb_heal: Callable = func(target: Node3D, healer: Node3D, amount: int) -> void:
		state_heal["received"] = true
		state_heal["target"] = target
		state_heal["healer"] = healer
		state_heal["amount"] = amount

	bus.healing_applied.connect(cb_heal)
	bus.healing_applied.emit(entity_a, killer_node, 30)
	assert(state_heal["received"] == true, "healing_applied signal was not received")
	assert(state_heal["target"] == entity_a and state_heal["healer"] == killer_node and state_heal["amount"] == 30, "healing_applied param mismatch")
	bus.healing_applied.disconnect(cb_heal)
	print("PASS: 4. healing_applied")

	# Test 5: mana_changed
	var state_mana: Dictionary = {"received": false, "entity": null, "current_mana": 0.0, "max_mana": 0.0}
	var cb_mana: Callable = func(ent: Node3D, current_mana: float, max_mana: float) -> void:
		state_mana["received"] = true
		state_mana["entity"] = ent
		state_mana["current_mana"] = current_mana
		state_mana["max_mana"] = max_mana

	bus.mana_changed.connect(cb_mana)
	bus.mana_changed.emit(entity_a, 25.5, 100.0)
	assert(state_mana["received"] == true, "mana_changed signal was not received")
	assert(state_mana["entity"] == entity_a and is_equal_approx(state_mana["current_mana"], 25.5) and is_equal_approx(state_mana["max_mana"], 100.0), "mana_changed param mismatch")
	bus.mana_changed.disconnect(cb_mana)
	print("PASS: 5. mana_changed")

	# Test 6: health_changed
	var state_hp: Dictionary = {"received": false, "entity": null, "current_hp": 0, "max_hp": 0}
	var cb_hp: Callable = func(ent: Node3D, current_hp: int, max_hp: int) -> void:
		state_hp["received"] = true
		state_hp["entity"] = ent
		state_hp["current_hp"] = current_hp
		state_hp["max_hp"] = max_hp

	bus.health_changed.connect(cb_hp)
	bus.health_changed.emit(entity_a, 75, 120)
	assert(state_hp["received"] == true, "health_changed signal was not received")
	assert(state_hp["entity"] == entity_a and state_hp["current_hp"] == 75 and state_hp["max_hp"] == 120, "health_changed param mismatch")
	bus.health_changed.disconnect(cb_hp)
	print("PASS: 6. health_changed")

	# Test 7: skill_cast_started
	var dummy_res: Resource = Resource.new()
	var state_skill: Dictionary = {"received": false, "caster": null, "skill_data": null}
	var cb_skill: Callable = func(caster: Node3D, skill_data: Resource) -> void:
		state_skill["received"] = true
		state_skill["caster"] = caster
		state_skill["skill_data"] = skill_data

	bus.skill_cast_started.connect(cb_skill)
	bus.skill_cast_started.emit(entity_a, dummy_res)
	assert(state_skill["received"] == true and state_skill["caster"] == entity_a and state_skill["skill_data"] == dummy_res, "skill_cast_started signal mismatch")
	bus.skill_cast_started.disconnect(cb_skill)
	print("PASS: 7. skill_cast_started")

	# Test 8: skill_cooldown_updated
	var state_cd: Dictionary = {"received": false, "caster": null, "skill_id": "", "remaining_ratio": 0.0}
	var cb_cd: Callable = func(caster: Node3D, skill_id: String, remaining_ratio: float) -> void:
		state_cd["received"] = true
		state_cd["caster"] = caster
		state_cd["skill_id"] = skill_id
		state_cd["remaining_ratio"] = remaining_ratio

	bus.skill_cooldown_updated.connect(cb_cd)
	bus.skill_cooldown_updated.emit(entity_a, "slash", 0.5)
	assert(state_cd["received"] == true and state_cd["caster"] == entity_a and state_cd["skill_id"] == "slash" and is_equal_approx(state_cd["remaining_ratio"], 0.5), "skill_cooldown_updated mismatch")
	bus.skill_cooldown_updated.disconnect(cb_cd)
	print("PASS: 8. skill_cooldown_updated")

	# Test 9: combat_triggered
	var state_combat: Dictionary = {"received": false, "initiator": null, "target": null}
	var cb_combat: Callable = func(init: Node3D, targ: Node3D) -> void:
		state_combat["received"] = true
		state_combat["initiator"] = init
		state_combat["target"] = targ

	bus.combat_triggered.connect(cb_combat)
	bus.combat_triggered.emit(entity_a, killer_node)
	assert(state_combat["received"] == true and state_combat["initiator"] == entity_a and state_combat["target"] == killer_node, "combat_triggered param mismatch")
	bus.combat_triggered.disconnect(cb_combat)
	print("PASS: 9. combat_triggered")

	# Test 10: room_entered
	var state_room_enter: Dictionary = {"received": false, "index": -1, "name": ""}
	var cb_room_enter: Callable = func(idx: int, rname: String) -> void:
		state_room_enter["received"] = true
		state_room_enter["index"] = idx
		state_room_enter["name"] = rname

	bus.room_entered.connect(cb_room_enter)
	bus.room_entered.emit(1, "Antechamber")
	assert(state_room_enter["received"] == true and state_room_enter["index"] == 1 and state_room_enter["name"] == "Antechamber", "room_entered param mismatch")
	bus.room_entered.disconnect(cb_room_enter)
	print("PASS: 10. room_entered")

	# Test 11: room_cleared
	var state_room_clear: Dictionary = {"received": false, "index": -1}
	var cb_room_clear: Callable = func(idx: int) -> void:
		state_room_clear["received"] = true
		state_room_clear["index"] = idx

	bus.room_cleared.connect(cb_room_clear)
	bus.room_cleared.emit(1)
	assert(state_room_clear["received"] == true and state_room_clear["index"] == 1, "room_cleared param mismatch")
	bus.room_cleared.disconnect(cb_room_clear)
	print("PASS: 11. room_cleared")

	# Test 12: dungeon_path_changed
	var state_path: Dictionary = {"received": false, "state": -1}
	var cb_path: Callable = func(new_state: int) -> void:
		state_path["received"] = true
		state_path["state"] = new_state

	bus.dungeon_path_changed.connect(cb_path)
	bus.dungeon_path_changed.emit(2)
	assert(state_path["received"] == true and state_path["state"] == 2, "dungeon_path_changed param mismatch")
	bus.dungeon_path_changed.disconnect(cb_path)
	print("PASS: 12. dungeon_path_changed")

	# Test 13: boss_telegraph_started
	var state_telegraph: Dictionary = {"received": false, "position": Vector3.ZERO, "radius": 0.0, "duration": 0.0}
	var cb_telegraph: Callable = func(pos: Vector3, rad: float, dur: float) -> void:
		state_telegraph["received"] = true
		state_telegraph["position"] = pos
		state_telegraph["radius"] = rad
		state_telegraph["duration"] = dur

	bus.boss_telegraph_started.connect(cb_telegraph)
	bus.boss_telegraph_started.emit(Vector3(10, 0, 5), 4.5, 2.0)
	assert(state_telegraph["received"] == true and state_telegraph["position"] == Vector3(10, 0, 5) and is_equal_approx(state_telegraph["radius"], 4.5) and is_equal_approx(state_telegraph["duration"], 2.0), "boss_telegraph_started param mismatch")
	bus.boss_telegraph_started.disconnect(cb_telegraph)
	print("PASS: 13. boss_telegraph_started")

	# Test 14: potion_consumed
	var state_potion: Dictionary = {"received": false, "hero": null, "potion_data": null}
	var cb_potion: Callable = func(hero: Node3D, potion_data: Resource) -> void:
		state_potion["received"] = true
		state_potion["hero"] = hero
		state_potion["potion_data"] = potion_data

	bus.potion_consumed.connect(cb_potion)
	bus.potion_consumed.emit(entity_a, dummy_res)
	assert(state_potion["received"] == true and state_potion["hero"] == entity_a and state_potion["potion_data"] == dummy_res, "potion_consumed param mismatch")
	bus.potion_consumed.disconnect(cb_potion)
	print("PASS: 14. potion_consumed")

	# Test 15: loot_collected
	var state_loot: Dictionary = {"received": false, "item_data": null, "quantity": 0}
	var cb_loot: Callable = func(item_data: Resource, quantity: int) -> void:
		state_loot["received"] = true
		state_loot["item_data"] = item_data
		state_loot["quantity"] = quantity

	bus.loot_collected.connect(cb_loot)
	bus.loot_collected.emit(dummy_res, 5)
	assert(state_loot["received"] == true and state_loot["item_data"] == dummy_res and state_loot["quantity"] == 5, "loot_collected param mismatch")
	bus.loot_collected.disconnect(cb_loot)
	print("PASS: 15. loot_collected")

	# Test 16: match_ended
	var dummy_summary: Dictionary = {"gold": 100, "xp": 250}
	var state_match: Dictionary = {"received": false, "victory": false, "summary": {}}
	var cb_match: Callable = func(victory: bool, summary_data: Dictionary) -> void:
		state_match["received"] = true
		state_match["victory"] = victory
		state_match["summary"] = summary_data

	bus.match_ended.connect(cb_match)
	bus.match_ended.emit(true, dummy_summary)
	assert(state_match["received"] == true and state_match["victory"] == true and state_match["summary"]["gold"] == 100 and state_match["summary"]["xp"] == 250, "match_ended param mismatch")
	bus.match_ended.disconnect(cb_match)
	print("PASS: 16. match_ended")

	# Cleanup
	entity_a.free()
	killer_node.free()

	print("========================================")
	print("=== ALL EVENTBUS UNIT TESTS PASSED (16/16) ===")
	print("========================================")
	quit(0)
