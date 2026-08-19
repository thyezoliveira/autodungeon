class_name ItemData
extends Resource

enum ItemType { WEAPON, ARMOR, CONSUMABLE, MATERIAL, GOLD }

@export var item_id: String = ""
@export var item_name: String = ""
@export_multiline var description: String = ""
@export var icon: Texture2D = null
@export var item_type: ItemType = ItemType.CONSUMABLE
@export var gold_value: int = 10
@export var heal_amount: int = 0
@export var auto_trigger_hp_threshold: float = 0.30
