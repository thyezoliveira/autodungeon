class_name SkillData
extends Resource

@export var id: String = ""
@export var display_name: String = ""
@export_multiline var description: String = ""
@export var icon: Texture2D = null
@export var mana_cost: float = 15.0
@export var cooldown: float = 6.0
@export var cast_time: float = 0.0
@export var range_meters: float = 4.0
@export var effects: Array[SkillEffect] = []
