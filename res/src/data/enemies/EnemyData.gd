class_name EnemyData
extends Resource

enum EnemyTier { MINION, ELITE, BOSS }

@export var enemy_id: String = ""
@export var enemy_name: String = ""
@export var tier: EnemyTier = EnemyTier.MINION
@export var max_hp: int = 50
@export var armor: int = 2
@export var attack_power: int = 8
@export var attack_range: float = 1.8
@export var move_speed: float = 3.5
@export var loot_table: LootTableResource = null
@export var skills: Array[SkillData] = []
