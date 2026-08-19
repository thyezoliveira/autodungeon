class_name StatsComponent
extends Node

signal stat_modified(stat_name: String, new_value: float)

@export var max_hp: int = 100
@export var max_mana: float = 50.0
@export var attack_power: int = 15
@export var magic_power: int = 10
@export var armor: int = 10
@export var magic_resist: int = 5
@export var move_speed: float = 4.0
@export var critical_chance: float = 0.05

var _flat_modifiers: Dictionary = {}
var _percent_modifiers: Dictionary = {}


func initialize_from_hero_data(data: HeroData) -> void:
	if data == null:
		return
	max_hp = data.get_total_max_hp()
	max_mana = data.base_max_mana
	attack_power = data.get_total_attack_power()
	magic_power = data.get_total_magic_power()
	armor = data.get_total_armor()
	magic_resist = data.get_total_magic_resist()
	if data.hero_class != null:
		move_speed = data.hero_class.base_move_speed


func initialize_from_enemy_data(data: EnemyData) -> void:
	if data == null:
		return
	max_hp = data.max_hp
	armor = data.armor
	attack_power = data.attack_power
	move_speed = data.move_speed


func get_stat(stat_name: String) -> float:
	var base_val: float = 0.0
	match stat_name:
		"max_hp":
			base_val = float(max_hp)
		"max_mana":
			base_val = float(max_mana)
		"attack_power":
			base_val = float(attack_power)
		"magic_power":
			base_val = float(magic_power)
		"armor":
			base_val = float(armor)
		"magic_resist":
			base_val = float(magic_resist)
		"move_speed":
			base_val = float(move_speed)
		"critical_chance":
			base_val = float(critical_chance)
		_:
			var prop_val = get(stat_name)
			if prop_val != null and (prop_val is int or prop_val is float):
				base_val = float(prop_val)
			else:
				base_val = 0.0

	var flat_sum: float = 0.0
	if _flat_modifiers.has(stat_name):
		var flat_dict: Dictionary = _flat_modifiers[stat_name]
		for val in flat_dict.values():
			flat_sum += float(val)

	var percent_sum: float = 0.0
	if _percent_modifiers.has(stat_name):
		var pct_dict: Dictionary = _percent_modifiers[stat_name]
		for val in pct_dict.values():
			percent_sum += float(val)

	var final_val: float = (base_val + flat_sum) * (1.0 + percent_sum)

	match stat_name:
		"max_hp":
			return maxf(1.0, final_val)
		"critical_chance":
			return clampf(final_val, 0.0, 1.0)
		"max_mana", "attack_power", "magic_power", "armor", "magic_resist", "move_speed":
			return maxf(0.0, final_val)
		_:
			return maxf(0.0, final_val)


func add_flat_modifier(stat_name: String, id: String, value: float) -> void:
	if not _flat_modifiers.has(stat_name):
		_flat_modifiers[stat_name] = {}
	_flat_modifiers[stat_name][id] = value
	stat_modified.emit(stat_name, get_stat(stat_name))


func add_percent_modifier(stat_name: String, id: String, value: float) -> void:
	if not _percent_modifiers.has(stat_name):
		_percent_modifiers[stat_name] = {}
	_percent_modifiers[stat_name][id] = value
	stat_modified.emit(stat_name, get_stat(stat_name))


func remove_modifier(stat_name: String, id: String) -> void:
	var changed: bool = false
	if _flat_modifiers.has(stat_name) and _flat_modifiers[stat_name].has(id):
		_flat_modifiers[stat_name].erase(id)
		if _flat_modifiers[stat_name].is_empty():
			_flat_modifiers.erase(stat_name)
		changed = true
	if _percent_modifiers.has(stat_name) and _percent_modifiers[stat_name].has(id):
		_percent_modifiers[stat_name].erase(id)
		if _percent_modifiers[stat_name].is_empty():
			_percent_modifiers.erase(stat_name)
		changed = true
	if changed:
		stat_modified.emit(stat_name, get_stat(stat_name))


func clear_all_modifiers() -> void:
	var impacted_stats: Dictionary = {}
	for stat in _flat_modifiers.keys():
		impacted_stats[stat] = true
	for stat in _percent_modifiers.keys():
		impacted_stats[stat] = true
	_flat_modifiers.clear()
	_percent_modifiers.clear()
	for stat in impacted_stats.keys():
		stat_modified.emit(stat, get_stat(stat))


func has_modifier(stat_name: String, id: String) -> bool:
	var in_flat: bool = _flat_modifiers.has(stat_name) and _flat_modifiers[stat_name].has(id)
	var in_pct: bool = _percent_modifiers.has(stat_name) and _percent_modifiers[stat_name].has(id)
	return in_flat or in_pct
