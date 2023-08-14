extends Node


# This class distributes random towers to players. This
# happens after every wave and also at the start of the game
# after player upgrades elements four times.

# NOTE: this code is convoluted because it attempts to
# accurately reproduce the algorithm from the original game.
# There are some differences in the implementation but final
# behavior is the same. Make sure that any changes you make
# to this code do not cause unintentional changes to
# behavior.


signal rolling_starting_towers()
signal random_tower_distributed(tower_id)


# Tower groups are lists of towers mapped by element and
# rarity:
# Element -> Rarity -> Array of tower id's
var _tower_groups_all_tiers: Dictionary
var _tower_groups_first_tier_only: Dictionary
var _starting_roll_count: int = 6


func _ready():
	_tower_groups_all_tiers = _generate_tower_groups(false)
	_tower_groups_first_tier_only = _generate_tower_groups(true)


# Called at the start of the game when the "roll towers"
# button is pressed. Each call reduces the resulting amount
# of towers by one. Returns whether can make any more rolls.
func roll_starting_towers() -> bool:
	if _starting_roll_count == 0:
		return false

	rolling_starting_towers.emit()

	var wave_level: int = 0
	var tower_list: Array[int] = _generate_random_towers_with_count(wave_level, _starting_roll_count)
	_add_towers_to_stash(tower_list)

	_starting_roll_count -= 1

	var can_roll_again: bool = _starting_roll_count > 1

	return can_roll_again


func get_current_starting_tower_roll_amount() -> int:
	return _starting_roll_count


# Called after each wave. Adds random towers to tower stash.
# 
# NOTE: wave_level argument is used instead of current wave
# level because we need to distribute towers when waves are
# finished and waves may finish out of order. For example,
# player can spawn wave 2 early after wave 1 is done
# spawning but then finish wave 2 before wave 1.
func roll_towers(wave_level: int):
	var tower_list: Array[int] = _generate_random_towers(wave_level)
	_add_towers_to_stash(tower_list)


# Adds random towers. The amount will be at least one and
# more towers will be added for higher wave levels.
func _generate_random_towers(wave_level: int) -> Array[int]:
	var tower_list: Array[int] = []

	var element_list: Array[Element.enm] = _get_possible_element_list()

#	On first pass, try to roll each element once. This is
#	likely to not result in any towers at low element
#	levels.
	for element in element_list:
		var tower: int = _generate_random_tower_for_element(wave_level, element)

		if tower != 0:
			tower_list.append(tower)

#	If first pass rolled 0 towers, we do a second pass where
#	we roll 1 tower by brute force. This pass will happen
#	for majority of early waves.
	if tower_list.size() == 0:
		tower_list = _generate_random_towers_with_count(wave_level, 1)

	return tower_list


# Adds the given amount of towers.
func _generate_random_towers_with_count(wave_level: int, count: int) -> Array[int]:
	var tower_list: Array[int] = []

	var element_list: Array[Element.enm] = _get_possible_element_list()

#	NOTE: original algorithm doesn't do this and iterates
#	over elements in same order every time. I'm pretty sure
#	that causes some elements to incorrectly have higher
#	probability. Therefore, we shuffle the elements before
#	iterating over them.
	element_list.shuffle()

	var brute_force_count: int = 0

#	Iterate over all elements in a loop until the required
#	amount of towers has been rolled. This is a "brute
#	force" approach.
	while true:
		var element: Element.enm = element_list.pop_front()
		element_list.push_back(element)

		var tower: int = _generate_random_tower_for_element(wave_level, element)

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


# Adds towers to tower stash (BuildBar)
func _add_towers_to_stash(tower_list: Array[int]):
#	NOTE: BuildBar connects to random_tower_distributed()
#	signal and will add towers.
	for tower in tower_list:
		random_tower_distributed.emit(tower)

#	Add messages about new towers
	Messages.add_normal("New towers were added to stash:")

#	Sort tower list by element to group messages for same
#	element together
	tower_list.sort_custom(func(a, b): 
		var element_a: int = TowerProperties.get_element(a)
		var element_b: int = TowerProperties.get_element(b)
		return element_a < element_b)

	for tower in tower_list:
		var element: Element.enm = TowerProperties.get_element(tower)
		var element_string: String = Element.convert_to_colored_string(element)
		var rarity: Rarity.enm = TowerProperties.get_rarity(tower)
		var rarity_color: Color = Rarity.get_color(rarity)
		var tower_name: String = TowerProperties.get_display_name(tower)
		var tower_name_colored: String = Utils.get_colored_string(tower_name, rarity_color)
		var message: String = "    %s: %s" % [element_string, tower_name_colored]

		Messages.add_normal(message)


# Returns list of elements with non-zero chances. Useful to
# reduce the amount of brute forcing.
func _get_possible_element_list() -> Array[Element.enm]:
	var element_list: Array[Element.enm] = []

	for element in Element.get_list():
		var chance_for_element: float = _get_chance_for_element(element)

		if chance_for_element > 0:
			element_list.append(element)

	return element_list


# Returns chance for rolling a tower of a given element.
# Increasing element level increases this chance.
func _get_chance_for_element(element: Element.enm) -> float:
	var base: float = 0.0

	var add: float
	match Globals.game_mode:
		GameMode.enm.RANDOM_WITH_UPGRADES: add = 0.075
		GameMode.enm.TOTALLY_RANDOM: add = 0.1
		_: add = 0.0

	var level: int = ElementLevel.get_current(element)
	var chance: float = base + add * level

	return chance


# Returns chance for rolling a tower in a given "group" of
# element and rarity. Is affected by current element level.
# Increasing element level increases chances for all
# rarities, except for common, which gets decreased.
func _get_chance_for_group(element: Element.enm, rarity: Rarity.enm) -> float:
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

	var level: int = ElementLevel.get_current(element)
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

	var all_towers: Array = Properties.get_tower_id_list()

#	Sort tower list by cost so that all resulting tower
#	groups are also sorted by cost
	all_towers.sort_custom(func(a, b): 
		var cost_a: int = TowerProperties.get_cost(a)
		var cost_b: int = TowerProperties.get_cost(b)
		return cost_a < cost_b)

	for tower in all_towers:
		var element: Element.enm = TowerProperties.get_element(tower)
		var rarity: Rarity.enm = TowerProperties.get_rarity(tower)
		var tier: Rarity.enm = TowerProperties.get_tier(tower) as Rarity.enm

		if first_tier_only && tier > 1:
			continue

		result[element][rarity].append(tower)

	return result


# Returns 0 if failed to generate
func _generate_random_tower_for_element(wave_level: int, element: Element.enm) -> int:
	var chance_for_element: float = _get_chance_for_element(element)
	
	var roll_success: bool = Utils.rand_chance(chance_for_element)
	if !roll_success:
		return 0

	var max_cost: float = _get_max_cost(wave_level, element)

	var rarity: Rarity.enm = _roll_rarity_for_element(element, max_cost)

	var cost_multiplier_for_rarity: float = _get_cost_multiplier_for_rarity(rarity)
	max_cost *= cost_multiplier_for_rarity

	var group_map: Dictionary
	match Globals.game_mode:
		GameMode.enm.RANDOM_WITH_UPGRADES: group_map = _tower_groups_first_tier_only
		GameMode.enm.TOTALLY_RANDOM: group_map = _tower_groups_all_tiers
		_: group_map = {}

#	Remove all towers which are above max cost. If group
#	ends up being empty, reduce rarity.
	var group: Array
	while true:
		group = group_map[element][rarity]
		group = group.filter(func(tower):
			var cost: int = TowerProperties.get_cost(tower)
			var below_max_cost: bool = cost < max_cost

			return below_max_cost)

		if !group.is_empty() || rarity == 0:
			break
		else:
			rarity = (rarity - 1) as Rarity.enm
	
	if group.is_empty():
		push_error("Tower group is empty for:", wave_level, element, rarity)

		return 0

#	NOTE: adjust chance of picking a tower based on it's
#	cost
#	- if cost is 50, then weight is ~2287
#	- if cost is 100, then weight is ~8000
#	This means that we will pick towers with higher costs
#	more often. This way, the player will get the most
#	powerful towers available at the moment.
	var group_weights: Dictionary = {}
	for tower in group:
		var cost: int = TowerProperties.get_cost(tower)
		var weight: float = floorf(100 * pow(cost, 0.8))
		group_weights[tower] = weight

	var tower: int = Utils.random_weighted_pick(group_weights)

	return tower


# Returns max cost for rolling towers. All rolled towers
# will be below this cost. Researching elements unlocks more
# expensive towers.
func _get_max_cost(wave_level: int, element: Element.enm) -> float:
	var max_cost: float = floorf(70 + wave_level * (5 + wave_level * 0.6))

	var cost_multiplier: float = _get_cost_multiplier_for_element(element)
	max_cost = max_cost * cost_multiplier
	
	max_cost = floori(max_cost * randf_range(1.0, 1.1))

	return max_cost


func _get_cost_multiplier_for_element(element: Element.enm) -> float:
	var base: float = 0.75
	var add: float = 0.03
	var level: int = ElementLevel.get_current(element)
	var multiplier: float = base + add * level

	return multiplier


# Rolls random rarity for element. Depends on current
# element level and max cost. Rarity will be picked so that
# towers of rarity are below max cost. Researching elements
# unlocks towers with higher rarity.
func _roll_rarity_for_element(element: Element.enm, max_cost: float) -> Rarity.enm:
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
		var chance: float = _get_chance_for_group(element, rarity)
		rarity_chance_map[rarity] = chance

#	Remove rarities whose cost thresholds are above max cost
	for rarity in rarity_list:
		var cost_threshold: int = cost_threshold_map[rarity]

		if cost_threshold > max_cost:
			rarity_chance_map.erase(rarity)

	var random_rarity: Rarity.enm = Utils.random_weighted_pick(rarity_chance_map)

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
