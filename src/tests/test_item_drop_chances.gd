class_name TestItemDropChances extends Node


# Simulates multiple games and collects average counts of
# item drops.


const SIMULATION_COUNT: int = 50
const FIRST_WAVE: int = 80
const LAST_WAVE: int = 200

# NOTE: these values are for the carry tower during endgame
const TOWER_ITEM_CHANCE: float = 2.5
const CREEP_ITEM_CHANCE: float = 1.5
const TOWER_ITEM_QUALITY: float = 2.5
const CREEP_ITEM_QUALITY: float = 1.5

# NOTE: these values are for "normal" creeps
const CREEPS_PER_WAVE: int = 10
const ITEM_ROLLS_PER_CREEP: int = 2

# NOTE: stats for these items will be printed separatately
# from the main list
const MARKED_ITEM_LIST: Array = [9, 140, 254]


static func run():
	var item_count_map: Dictionary = {}

	for i in range(0, SIMULATION_COUNT):
		simulate_one_game(item_count_map)

	var rarity_count_map: Dictionary = {}
	for item_id in item_count_map.keys():
		var rarity: Rarity.enm = ItemProperties.get_rarity(item_id)
		var item_count: int = item_count_map[item_id]

		if !rarity_count_map.has(rarity):
			rarity_count_map[rarity] = 0

		rarity_count_map[rarity] += item_count

	var item_id_list: Array = item_count_map.keys()
	item_id_list.sort()

	print(" \n")
	print("----------")
	print("Results of testing item drops")
	print(" \n")
	print("TOWER_ITEM_CHANCE = %s" % Utils.format_percent(TOWER_ITEM_CHANCE, 0))
	print("CREEP_ITEM_CHANCE = %s" % Utils.format_percent(CREEP_ITEM_CHANCE, 0))
	print("TOWER_ITEM_QUALITY = %s" % Utils.format_percent(TOWER_ITEM_QUALITY, 0))
	print("CREEP_ITEM_QUALITY = %s" % Utils.format_percent(CREEP_ITEM_QUALITY, 0))
	print(" \n")
	print(" \n")
	print("All items")
	print(" \n")

	for item_id in item_id_list:
		var item_name: String = ItemProperties.get_display_name(item_id)
		var item_count: float = item_count_map[item_id] * 1.0 / SIMULATION_COUNT

		print("%s: %s" % [item_name, item_count])

	print(" \n")
	print("----------")
	print("Rarity stats")
	print(" \n")
	
	for rarity in Rarity.get_list():
		var rarity_string: String = Rarity.convert_to_string(rarity)
		var count: float = rarity_count_map.get(rarity, 0) * 1.0 / SIMULATION_COUNT

		print("%s: %s" % [rarity_string, count])

	print(" \n")
	print("----------")
	print("Marked items")
	print(" \n")

	for item_id in MARKED_ITEM_LIST:
		var item_name: String = ItemProperties.get_display_name(item_id)
		var item_count: float = item_count_map.get(item_id, 0) * 1.0 / SIMULATION_COUNT
		
		print("%s: %s" % [item_name, item_count])

	print(" \n")
	print(" \n")


static func simulate_one_game(item_count_map: Dictionary):
	var item_chance: float = Constants.BASE_ITEM_DROP_CHANCE * TOWER_ITEM_CHANCE * CREEP_ITEM_CHANCE
	var quality_multiplier: float = TOWER_ITEM_QUALITY * CREEP_ITEM_QUALITY

	for wave in range(FIRST_WAVE, LAST_WAVE):
		var creep_level: int = wave

		for creep in range(0, CREEPS_PER_WAVE):
			for i in range(0, ITEM_ROLLS_PER_CREEP):
				var item_dropped: bool = Utils.rand_chance(Globals.synced_rng, item_chance)
				
				if !item_dropped:
					continue

				var random_item: int = ItemDropCalc._calculate_item_drop(creep_level, quality_multiplier)

				if random_item == 0:
					continue

				if !item_count_map.has(random_item):
					item_count_map[random_item] = 0
				
				item_count_map[random_item] += 1
