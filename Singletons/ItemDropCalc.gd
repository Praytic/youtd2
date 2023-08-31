extends Node


# This is a rough translation of the original JASS code that
# picks which item should be dropped. Some of the code has
# been rewritten but the end behavior is the same.

# 	Values in this list translate to the following
# 	probabilities.
# 
#	common 		= 75%
#	uncommon 	= 25%
#	rare 		= 6%
#	unique 		= 2%
var _rarity_probabilities: Array[float] = [
	1000.0,
	0.25,
	0.06,
	0.02
]

# Quality threshold for different rarities of oils.
# Doesn't affect regular items, those have custom required
# levels assigned to each item.
var _quality_threshold: Array[int] = [
	0,
	6,
	18,
	36
]


# NOTE: returns 0 if no item was available for current game
# conditions.
func get_random_item(tower: Tower, target: Creep) -> int:
	var creep_level: int = target.get_spawn_level()
	var tower_quality_ratio: float = tower.get_item_quality_ratio()
	var target_quality_ratio: float = target.get_item_quality_ratio_on_death()
	var quality_multiplier: float = tower_quality_ratio * target_quality_ratio
	var random_item: int = _calculate_item_drop(creep_level, quality_multiplier)
	
	return random_item


func _calculate_item_drop(creep_level: int, quality_multiplier: float) -> int:
	var rarity: int = 3
	var rarity_chance: float = randf_range(0.0, 1.0)

#	Pick a random rarity, using
#	_rarity_probabilities and quality_multiplier.
	while true:
		rarity_chance = rarity_chance - _rarity_probabilities[rarity] * quality_multiplier

		if rarity_chance < 0.0 || rarity == 0:
			break

		rarity = rarity - 1

	var drop_oil_or_consumable: bool = Utils.rand_chance(0.4)

	if drop_oil_or_consumable:
#		Oil and consumable items

# 		Reduce rarity to match tower's level. For example,
# 		if we initially picked "uncommon" rarity but tower
# 		is level 1, then the rarity gets reduced to
# 		"common".
		while true:
			if creep_level >= _quality_threshold[rarity]:
				break

			rarity = rarity - 1

		var random_oil_or_consumable: int = get_random_oil_or_consumable(rarity)

		return random_oil_or_consumable
	else:
#		Regular items
		var random_regular_item: int = get_random_item_at_or_below_rarity_bounded(rarity, 0, creep_level)

		return random_regular_item


func get_random_oil_or_consumable(rarity: int) -> int:
#	Find all items which are oils and fall into selected
#	rarity
	var rarity_string: String = Rarity.convert_to_string(rarity)
	var oil_type_string: String = ItemType.convert_to_string(ItemType.enm.OIL)
	var consumable_type_string: String = ItemType.convert_to_string(ItemType.enm.CONSUMABLE)
	var oil_item_list: Array = Properties.get_item_id_list_by_filter(Item.CsvProperty.TYPE, oil_type_string)
	var consumable_item_list: Array = Properties.get_item_id_list_by_filter(Item.CsvProperty.TYPE, consumable_type_string)

	var item_list: Array = oil_item_list + consumable_item_list

	item_list = Properties.filter_item_id_list(item_list, Item.CsvProperty.RARITY, rarity_string)

	if item_list.is_empty():
		return 0

	var random_item: int = item_list.pick_random()

	return random_item


func get_random_item_at_or_below_rarity_bounded(rarity: int, lvl_min: int, lvl_max: int) -> int:
	var random_item: int = get_random_item_at_rarity_bounded(rarity, lvl_min, lvl_max)

	if random_item != 0:
		return random_item
	else:
		if rarity > 0:
#			Try to find items in lower rarity
			return get_random_item_at_rarity_bounded(rarity - 1, lvl_min, lvl_max)
		else:
#			Give up
			return 0


# RandomItemSet.permanent.getRandomItemAtRarityBounded() in JASS
func get_random_item_at_rarity_bounded(rarity: int, lvl_min: int, lvl_max: int) -> int:
#	Find all items which are not oils and fall into selected
#	rarity
	var rarity_string: String = Rarity.convert_to_string(rarity)
	var regular_type_string: String = ItemType.convert_to_string(ItemType.enm.REGULAR)
	var item_list: Array = Properties.get_item_id_list_by_filter(Item.CsvProperty.TYPE, regular_type_string)
	item_list = Properties.filter_item_id_list(item_list, Item.CsvProperty.RARITY, rarity_string)

# 	Filter the item list by level
	var available_item_list: Array[int] = []

	for item in item_list:
		var required_level: int = ItemProperties.get_required_wave_level(item)
		var level_is_ok: bool = lvl_min <= required_level && required_level <= lvl_max

		if level_is_ok:
			available_item_list.append(item)

#	NOTE: some items are disabled because their scripts are
#	incomplete or broken.
	for disabled_item in Item.disabled_item_list:
		available_item_list.erase(disabled_item)

	var items_are_available: bool = !available_item_list.is_empty()

	if items_are_available:
		var random_item: int = available_item_list.pick_random()

		return random_item
	else:
		return 0
