class_name ClassData
extends Resource

enum Role { TANK_MELEE, DPS_RANGED, DPS_MELEE, SUPPORT_HEALER }

@export var class_name_str: String = ""
@export var role: Role = Role.TANK_MELEE
@export var default_attack_range: float = 2.0
@export var base_move_speed: float = 4.0
@export var class_skills: Array[SkillData] = []
