extends Node


# Generates random towers, based on current element levels.
# This happens after every wave and also at the start of the
# game when player rolls the first towers.

# NOTE: this code is convoluted because it attempts to
# accurately reproduce the algorithm from the original game.
# There are some differences in the implementation but final
# behavior is the same. Make sure that any changes you make
# to this code do not cause unintentional changes to
# behavior.


# Tower groups are lists of towers mapped by element and
# rarity:
# Element -> Rarity -> Array of tower id's
var _tower_groups_all_tiers: Dictionary
var _tower_groups_first_tier_only: Dictionary


#########################
###     Built-in      ###
#########################

func _ready():
	_tower_groups_all_tiers = _generate_tower_groups(false)
	_tower_groups_first_tier_only = _generate_tower_groups(true)


#########################
###       Public      ###
#########################

# Called after each wave.
func roll_towers(player: Player) -> Array[int]:
	var tower_list: Array[int] = _generate_random_towers(player)

	return tower_list


#########################
###      Private      ###
#########################

# Adds random towers. The amount will be at least one and
# more towers will be added for higher wave levels.
func _generate_random_towers(player: Player) -> Array[int]:
	var tower_list: Array[int] = []

	var element_list: Array[Element.enm] = _get_possible_element_list(player)
	Utils.shuffle(Globals.synced_rng, element_list)

	if element_list.is_empty():
		return []

#	On first pass, try to roll each element once. This is
#	likely to not result in any towers at low element
#	levels.
	for element in element_list:
		var chance_for_element: float = _get_chance_for_element(player, element)
		while chance_for_element > 0:
			var tower: int = _generate_random_tower_for_element(player, element, chance_for_element)

			if tower != 0:
				tower_list.append(tower)
			
			chance_for_element -= 1.0

#	If first pass rolled 0 towers, we do a second pass where
#	we roll 1 tower by brute force. This pass will happen
#	for majority of early waves.
	if tower_list.size() == 0:
		tower_list = generate_random_towers_with_count(player, 1)

	return tower_list


# Adds the given amount of towers.
func generate_random_towers_with_count(player: Player, count: int) -> Array[int]:
	var tower_list: Array[int] = []

	var element_list: Array[Element.enm] = _get_possible_element_list(player)

	if element_list.is_empty():
		return []

#	NOTE: original algorithm doesn't do this and iterates
#	over elements in same order every time. I'm pretty sure
#	that causes some elements to incorrectly have higher
#	probability. Therefore, we shuffle the elements before
#	iterating over them.
	Utils.shuffle(Globals.synced_rng, element_list)

	var brute_force_count: int = 0

#	Iterate over all elements in a loop until the required
#	amount of towers has been rolled. This is a "brute
#	force" approach.
	while true:
		var element: Element.enm = element_list.pop_front()
		element_list.push_back(element)

		var tower: int = _generate_random_tower_for_element(player, element)

		if tower != 0:
			tower_list.append(tower)

		var rolled_enough_towers: bool = tower_list.size() == count

		if rolled_enough_towers:
			break

		brute_force_count += 1

		if brute_force_count == 1000:
			push_error("Tried to roll tower 1000 times. Giving up - something might be wrong with tower groups.")

			break

	return tower_list


# Returns list of elements with non-zero chances. Useful to
# reduce the amount of brute forcing.
func _get_possible_element_list(player: Player) -> Array[Element.enm]:
	var element_list: Array[Element.enm] = []

	for element in Element.get_list():
		var chance_for_element: float = _get_chance_for_element(player, element)

		if chance_for_element > 0:
			element_list.append(element)

	return element_list


# Returns chance for rolling a tower of a given element.
# Increasing element level increases this chance.
func _get_chance_for_element(player: Player, element: Element.enm) -> float:
	var base: float = 0.0

	var add: float
	match Globals.get_game_mode():
		GameMode.enm.RANDOM_WITH_UPGRADES: add = 0.075
		GameMode.enm.TOTALLY_RANDOM: add = 0.1
		_: add = 0.0

	var level: int = player.get_element_level(element)
	var chance: float = base + add * level

	return chance


# Returns chance for rolling a tower in a given "group" of
# element and rarity. Is affected by current element level.
# Increasing element level increases chances for all
# rarities, except for common, which gets decreased.
func _get_chance_for_group(player: Player, element: Element.enm, rarity: Rarity.enm) -> float:
	var base_map: Dictionary = {
		Rarity.enm.COMMON: 0.76,
		Rarity.enm.UNCOMMON: 0.18,
		Rarity.enm.RARE: 0.06,
		Rarity.enm.UNIQUE: 0.0,
	}
#	NOTE: chance for common rarity decreases
	var add_map: Dictionary = {
		Rarity.enm.COMMON: -0.018,
		Rarity.enm.UNCOMMON: 0.008,
		Rarity.enm.RARE: 0.006,
		Rarity.enm.UNIQUE: 0.004,
	}

	var level: int = player.get_element_level(element)
	var base: float = base_map[rarity]
	var add: float = add_map[rarity]
	var chance: float = base + add * level
	chance = clampf(chance, 0.0, 1.0)

	return chance


func _generate_tower_groups(first_tier_only: bool) -> Dictionary:
	var result: Dictionary = {}

	for element in Element.get_list():
		result[element] = Dictionary()

		for rarity in Rarity.get_list():
			result[element][rarity] = Array()

	var all_towers: Array = TowerProperties.get_tower_id_list()

#	Sort tower list by cost so that all resulting tower
#	groups are also sorted by cost
	all_towers.sort_custom(func(a, b): 
		var cost_a: int = TowerProperties.get_cost(a)
		var cost_b: int = TowerProperties.get_cost(b)
		return cost_a < cost_b)

	for tower in all_towers:
		var element: Element.enm = TowerProperties.get_element(tower)
		var rarity: Rarity.enm = TowerProperties.get_rarity(tower)
		var tier: int = TowerProperties.get_tier(tower)

		if first_tier_only && tier > 1:
			continue

		result[element][rarity].append(tower)

	return result


# Returns 0 if failed to generate
func _generate_random_tower_for_element(player: Player, element: Element.enm, chance_for_element: float = -2.0) -> int:
	if chance_for_element == -2.0:
		chance_for_element = _get_chance_for_element(player, element)
	
	var roll_success: bool = Utils.rand_chance(Globals.synced_rng, chance_for_element)
	if !roll_success:
		return 0

	var max_cost: float = _get_max_cost(player, element)

	var rarity: Rarity.enm = _roll_rarity_for_element(player, element, max_cost)

	var cost_multiplier_for_rarity: float = _get_cost_multiplier_for_rarity(rarity)
	max_cost *= cost_multiplier_for_rarity

	var group_map: Dictionary
	var weight_cost_power: float
	match Globals.get_game_mode():
		GameMode.enm.RANDOM_WITH_UPGRADES: 
			group_map = _tower_groups_first_tier_only
			weight_cost_power = 0.25
		GameMode.enm.TOTALLY_RANDOM: 
			group_map = _tower_groups_all_tiers
			weight_cost_power = 0.8
		_: 
			group_map = {}
			weight_cost_power = 0.0

#	Remove all towers which are above max cost. If group
#	ends up being empty, reduce rarity.
	var group: Array
	while true:
		group = group_map[element][rarity]
		group = group.filter(func(tower) -> bool:
			var cost: int = TowerProperties.get_cost(tower)
			var below_max_cost: bool = cost < max_cost

			return below_max_cost)

		if !group.is_empty() || rarity == 0:
			break
		else:
			rarity = (rarity - 1) as Rarity.enm
	
	if group.is_empty():
		push_error("Tower group is empty for:", player.get_team().get_level(), element, rarity)

		return 0

#	NOTE: adjust chance of picking a tower based on it's
#	cost
#	for total random:
#	- if cost is 50, then weight is ~22.87
#	- if cost is 100, then weight is ~39.81
#	- that means for if tower is 2x more expensive it is x1.741 likelier to appear
#	for random with upgrade:
#	- if cost is 50, then weight is ~2.659
#	- if cost is 100, then weight is ~3.162
#	- that means for if tower is 2x more expensive it is x1.189 likelier to appear
#	This means that we will pick towers with higher costs
#	more often. This way, the player will get the most
#	powerful towers available at the moment.
	var group_weights: Dictionary = {}
	for tower in group:
		var cost: int = TowerProperties.get_cost(tower)
		var weight: float = pow(cost, weight_cost_power)
		group_weights[tower] = weight

	var random_tower: int = Utils.random_weighted_pick(Globals.synced_rng, group_weights)

	return random_tower


# Returns max cost for rolling towers. All rolled towers
# will be below this cost. Researching elements unlocks more
# expensive towers.
func _get_max_cost(player: Player, element: Element.enm) -> float:
	var wave_level: int = player.get_team().get_level()
	var max_cost: float = floorf(70 + wave_level * (5 + wave_level * 0.6))

	var cost_multiplier: float = _get_cost_multiplier_for_element(player, element)
	max_cost = max_cost * cost_multiplier
	
	max_cost = floori(max_cost * Globals.synced_rng.randf_range(1.0, 1.1))

	return max_cost


func _get_cost_multiplier_for_element(player: Player, element: Element.enm) -> float:
	var base: float = 0.75
	var add: float = 0.03
	var level: int = player.get_element_level(element)
	var multiplier: float = base + add * level

	return multiplier


# Rolls random rarity for element. Depends on current
# element level and max cost. Rarity will be picked so that
# towers of rarity are below max cost. Researching elements
# unlocks towers with higher rarity.
func _roll_rarity_for_element(player: Player, element: Element.enm, max_cost: float) -> Rarity.enm:
	var cost_threshold_map: Dictionary = {
		Rarity.enm.COMMON: 0,
		Rarity.enm.UNCOMMON: 0,
		Rarity.enm.RARE: 500,
		Rarity.enm.UNIQUE: 1500,
	}

	var rarity_list: Array = Rarity.get_list()

#	NOTE: have to generate chance map here because it
#	changes based on current element level
	var rarity_chance_map: Dictionary = {}

	for rarity in rarity_list:
		var chance: float = _get_chance_for_group(player, element, rarity)
		rarity_chance_map[rarity] = chance

#	Remove rarities whose cost thresholds are above max cost
	for rarity in rarity_list:
		var cost_threshold: int = cost_threshold_map[rarity]

		if cost_threshold > max_cost:
			rarity_chance_map.erase(rarity)

	var random_rarity: Rarity.enm = Utils.random_weighted_pick(Globals.synced_rng, rarity_chance_map)

	return random_rarity


func _get_cost_multiplier_for_rarity(rarity: Rarity.enm) -> float:
	var rarity_multiplier_map: Dictionary = {
		Rarity.enm.COMMON: 1.0,
		Rarity.enm.UNCOMMON: 1.05,
		Rarity.enm.RARE: 1.12,
		Rarity.enm.UNIQUE: 1.2,
	}
	var multiplier: float = rarity_multiplier_map[rarity]

	return multiplier
