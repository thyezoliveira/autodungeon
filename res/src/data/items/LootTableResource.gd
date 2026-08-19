class_name LootTableResource
extends Resource

@export var possible_items: Array[ItemData] = []
@export var drop_chances: Array[float] = []
@export var min_gold: int = 5
@export var max_gold: int = 20


func roll_loot() -> Array[ItemData]:
	var dropped: Array[ItemData] = []
	var count: int = mini(possible_items.size(), drop_chances.size())
	for i in range(count):
		var item: ItemData = possible_items[i]
		var chance: float = drop_chances[i]
		if item != null and randf() <= chance:
			dropped.append(item)
	return dropped


func roll_gold() -> int:
	if min_gold >= max_gold:
		return min_gold
	return randi_range(min_gold, max_gold)
