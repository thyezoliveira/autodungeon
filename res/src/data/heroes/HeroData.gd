class_name HeroData
extends Resource

@export var hero_id: String = ""
@export var hero_name: String = ""
@export var portrait: Texture2D = null
@export var race: RaceData = null
@export var hero_class: ClassData = null
@export var base_max_hp: int = 100
@export var base_max_mana: float = 50.0
@export var base_armor: int = 10
@export var base_magic_resist: int = 5
@export var base_attack_power: int = 15
@export var base_magic_power: int = 10
@export var innate_skills: Array[SkillData] = []


func get_total_max_hp() -> int:
	var race_bonus: int = race.bonus_max_hp if race else 0
	return base_max_hp + race_bonus


func get_total_armor() -> int:
	var race_bonus: int = race.bonus_armor if race else 0
	return base_armor + race_bonus


func get_total_magic_resist() -> int:
	var race_bonus: int = race.bonus_magic_resist if race else 0
	return base_magic_resist + race_bonus


func get_total_attack_power() -> int:
	var race_bonus: int = race.bonus_physical_attack if race else 0
	return base_attack_power + race_bonus


func get_total_magic_power() -> int:
	var race_bonus: int = race.bonus_magic_power if race else 0
	return base_magic_power + race_bonus
