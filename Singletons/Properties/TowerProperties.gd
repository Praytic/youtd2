extends Node


# NOTE: order of CsvProperty enums must match the order of
# the columns in tower_properties.csv
enum CsvProperty {
	NAME,
	TIER,
	ID,
	FAMILY_ID,
	AUTHOR,
	RARITY,
	ELEMENT,
	ATTACK_ENABLED,
	ATTACK_TYPE,
	ATTACK_RANGE,
	ATTACK_CD,
	ATTACK_DAMAGE_MIN,
	ATTACK_DAMAGE_MAX,
	MANA,
	MANA_REGEN,
	COST,
	DESCRIPTION,
	ICON_ATLAS_NUM,
}


enum RangeColumn {
	TOWER_ID,
	NAME,
	RADIUS,
	TARGETS_CREEPS,
	AFFECTED_BY_BUILDER,
	COUNT
}

const PROPERTIES_PATH = "res://Data/tower_properties.csv"
const TOWER_TOOLTIPS_PATH = "res://Data/tower_tooltips.csv"
const TOWER_RANGES_PATH: String = "res://Data/tower_ranges.csv"

const REQUIRED_WAVE_MAX: int = 80

var _min_required_wave_for_build_mode = {
	Rarity.enm.COMMON: 0,
	Rarity.enm.UNCOMMON: 6,
	Rarity.enm.RARE: 24,
	Rarity.enm.UNIQUE: 60
}

var _properties: Dictionary = {}
var _tower_tooltips: Dictionary = {}
var _tower_ranges: Dictionary = {}
var _element_map: Dictionary = {}
var _attack_type_map: Dictionary = {}
var _rarity_map: Dictionary = {}


#########################
###     Built-in      ###
#########################

# NOTE: convert some property strings to enums in _ready()
# so that we avoid this overhead during runtime.
func _ready():
	UtilsStatic.load_csv_properties(PROPERTIES_PATH, _properties, CsvProperty.ID)
	UtilsStatic.load_csv_properties(TOWER_TOOLTIPS_PATH, _tower_tooltips, 0)

	_tower_ranges = _load_tower_ranges_map()
	
	for tower_id in get_tower_id_list():
		var element_string: String = _get_property(tower_id, CsvProperty.ELEMENT)
		var element: Element.enm = Element.from_string(element_string)

		var attack_type_string: String = _get_property(tower_id, CsvProperty.ATTACK_TYPE)
		var attack_type: AttackType.enm = AttackType.from_string(attack_type_string)

		var rarity_string: String = _get_property(tower_id, CsvProperty.RARITY)
		var rarity: Rarity.enm = Rarity.convert_from_string(rarity_string)
		
		_element_map[tower_id] = element
		_attack_type_map[tower_id] = attack_type
		_rarity_map[tower_id] = rarity


#########################
###       Public      ###
#########################

func get_properties(tower_id: int) -> Dictionary:
	if _properties.has(tower_id):
		var out: Dictionary = _properties[tower_id]

		return out
	else:
		return {}


func get_tower_id_list() -> Array:
	return _properties.keys()


func get_tower_id_list_by_filter(tower_property: CsvProperty, filter_value: String) -> Array:
	var result_list = []
	for tower_id in _properties.keys():
		if _properties[tower_id][tower_property] == filter_value:
			result_list.append(tower_id)
	return result_list


func get_tier(tower_id: int) -> int:
	return _get_property(tower_id, CsvProperty.TIER).to_int()


func get_icon_atlas_num(tower_id: int) -> int:
	var icon_atlas_num_string: String = _get_property(tower_id, CsvProperty.ICON_ATLAS_NUM)

	if !icon_atlas_num_string.is_empty():
		var icon_atlas_num: int = icon_atlas_num_string.to_int()

		return icon_atlas_num
	else:
		return -1


func get_element(tower_id: int) -> Element.enm:
	var element: Element.enm = _element_map[tower_id]

	return element


func get_rarity(tower_id: int) -> Rarity.enm:
	var rarity: Rarity.enm = _rarity_map[tower_id]

	return rarity
	

func get_display_name(tower_id: int) -> String:
	return _get_property(tower_id, CsvProperty.NAME)


func get_tooltip_text(tower_id: int) -> String:
	var display_name: String = get_display_name(tower_id)
	var tooltip: String = "%s, %s" % [display_name, tower_id]

	return tooltip


func get_cost(tower_id: int) -> int:
	var cost: int = _get_property(tower_id, CsvProperty.COST) as int

	return cost


func get_sell_price(tower_id: int) -> int:
	var game_mode: GameMode.enm = Globals.get_game_mode()
	var sell_ratio: float = GameMode.get_sell_ratio(game_mode)
	var cost: float = TowerProperties.get_cost(tower_id)
	var sell_price: int = floori(cost * sell_ratio)

	return sell_price


func get_description(tower_id: int) -> String:
	var description: String = _get_property(tower_id, CsvProperty.DESCRIPTION)

	return description


func get_author(tower_id: int) -> String:
	var author: String = _get_property(tower_id, CsvProperty.AUTHOR)

	return author


func get_damage_min(tower_id: int) -> int:
	var damage_min: int = _get_property(tower_id, CsvProperty.ATTACK_DAMAGE_MIN).to_int()

	return damage_min


func get_damage_max(tower_id: int) -> int:
	var damage_max: int = _get_property(tower_id, CsvProperty.ATTACK_DAMAGE_MAX).to_int()

	return damage_max


func get_base_damage(tower_id: int) -> int:
	var base_damage: int = floor((get_damage_min(tower_id) + get_damage_max(tower_id)) / 2.0)

	return base_damage


func get_base_attackspeed(tower_id: int) -> float:
	var attackspeed: float = _get_property(tower_id,  CsvProperty.ATTACK_CD).to_float()

	if attackspeed == 0.0:
		push_error("Base attackspeed for tower %d is equal to 0.0. Attackspeed must greater than 0.0, even if the tower doesn't attack. Returning 1.0 instead.")

		return 1.0

	return attackspeed


func get_attack_enabled(tower_id: int) -> bool:
	var attack_enabled: bool = _get_property(tower_id, CsvProperty.ATTACK_ENABLED) == "TRUE"

	return attack_enabled


func get_attack_type(tower_id: int) -> AttackType.enm:
	var attack_type: AttackType.enm = _attack_type_map[tower_id]

	return attack_type


func get_range(tower_id: int) -> float:
	var attack_range: float = _get_property(tower_id, CsvProperty.ATTACK_RANGE).to_float()

	if attack_range == 0.0:
		push_error("Tower attack range must be greater than 0. Forcing value to 1.")

		attack_range = 1

	return attack_range


func get_required_element_level(tower_id: int) -> int:
	const element_level_to_min_cost_map: Dictionary = {
		1: 140,
		2: 215,
		3: 345,
		4: 500,
		5: 680,
		6: 900,
		7: 1080,
		8: 1300,
		9: 1550,
		10: 1850,
		11: 2130,
		12: 2440,
		13: 2750,
		14: 3100,
		15: 3500,
	}

	var tower_cost: int = get_cost(tower_id)

	var element_level: int = 1

	for level in range(15, 0, -1):
		var min_cost: int = element_level_to_min_cost_map[level]

		if tower_cost >= min_cost:
			element_level = level

			break

	return element_level


# NOTE: this formula is the inverse of the formula for tower cost
# from TowerDistribution._get_max_cost()
func get_required_wave_level(tower_id: int) -> int:
# 	NOTE: prevent value inside sqrt() from going below 0
# 	because sqrt() expects positive arg
	var tower_cost: int = get_cost(tower_id)
	var required_wave: int = ceili((sqrt(max(0.01, 60 * tower_cost - 3575)) - 25) / 6)

	var required_wave_min: int
	if Globals.get_game_mode() == GameMode.enm.BUILD:
		var rarity: Rarity.enm = TowerProperties.get_rarity(tower_id)
		required_wave_min = _min_required_wave_for_build_mode[rarity]
	else:
		required_wave_min = 0

	required_wave = clampi(required_wave, required_wave_min, REQUIRED_WAVE_MAX)

	return required_wave


func wave_level_foo(tower_id: int, player: Player) -> bool:
	var wave_level: int = player.get_team().get_level()
	var required_wave_level: int = TowerProperties.get_required_wave_level(tower_id)
	var out: bool = wave_level >= required_wave_level

	return out


func element_level_foo(tower_id: int, player: Player) -> bool:
	var required_element_level: int = TowerProperties.get_required_element_level(tower_id)
	var element: Element.enm = get_element(tower_id)
	var element_research_level: int = player.get_element_level(element)
	var out: bool = element_research_level >= required_element_level

	return out


func requirements_are_satisfied(tower_id: int, player: Player) -> bool:
	if Config.ignore_tower_requirements():
		return true

	var tier: int = TowerProperties.get_tier(tower_id)

#	NOTE: for random game modes, some towers do not have
#	requirements because they are obtained randomly from the
#	tower distribution game mechanic. Tower distribution
#	already has minimum requirements for when a tower can be
#	rolled.
# 
#	For "random with upgrades" mode, only the first tiers
#	come from tower distribution. Other tiers still need
#	requirements.
# 
#   For "totally random" mode, all towers come from tower
#   distribution, so we can ignore requirements completely.
	if Globals.get_game_mode() == GameMode.enm.RANDOM_WITH_UPGRADES && tier == 1:
		return true
	elif Globals.get_game_mode() == GameMode.enm.TOTALLY_RANDOM:
		return true

	var out: bool = element_level_foo(tower_id, player) && wave_level_foo(tower_id, player)

	return out


# NOTE: tower.getFamily() in JASS
func get_family(tower_id: int) -> int:
	return _get_property(tower_id, CsvProperty.FAMILY_ID).to_int()


# NOTE: sorted by tier
func get_towers_in_family(family_id: int) -> Array:
	var family_list: Array = get_tower_id_list_by_filter(CsvProperty.FAMILY_ID, str(family_id))
	family_list.sort_custom(func(a, b): 
		var tier_a: int = TowerProperties.get_tier(a)
		var tier_b: int = TowerProperties.get_tier(b)
		return tier_a < tier_b)

	return family_list


func get_food_cost(tower_id: int) -> int:
	var food_cost_map: Dictionary = {
		Rarity.enm.COMMON: 2,
		Rarity.enm.UNCOMMON: 3,
		Rarity.enm.RARE: 4,
		Rarity.enm.UNIQUE: 6,
	}
	var rarity: Rarity.enm = get_rarity(tower_id)
	var food_cost: int = food_cost_map[rarity]

	return food_cost


func get_tome_cost(tower_id: int) -> int:
	if Globals.game_mode_is_random():
		return 0

	var tome_cost_map: Dictionary = {
		Rarity.enm.COMMON: 0,
		Rarity.enm.UNCOMMON: 4,
		Rarity.enm.RARE: 10,
		Rarity.enm.UNIQUE: 25,
	}
	var rarity: Rarity.enm = get_rarity(tower_id)
	var tome_cost: int = tome_cost_map[rarity]

	return tome_cost


# Inventory capacity is derived from tower cost and there
# are also min/max values based on tower rarity.
# 
# Examples:
# 
# Energy Junction is an uncommon tower which costs 500. 500
# is between 400 and 1200, so it's capacity is 2. Capacity of 2
# fits within the [1,4] range of allowed capacities for
# uncommon towers.
# 
# Igloo is a rare tower and costs 700. 700 is between 400
# and 1200 so it's capacity should be 2 BUT the minimum
# capacity for rare towers is 3, so Igloo's capacity is 3.
func get_inventory_capacity(tower_id: int) -> int:
	var capacity_to_min_cost_map: Dictionary = {
		1: 0,
		2: 400,
		3: 1200,
		4: 1500,
		5: 1700,
		6: 2000,
	}
	var min_capacity_map: Dictionary = {
		Rarity.enm.COMMON: 1,
		Rarity.enm.UNCOMMON: 1,
		Rarity.enm.RARE: 3,
		Rarity.enm.UNIQUE: 5,
	}
	var max_capacity_map: Dictionary = {
		Rarity.enm.COMMON: 4,
		Rarity.enm.UNCOMMON: 4,
		Rarity.enm.RARE: 5,
		Rarity.enm.UNIQUE: 6,
	}

	var tower_cost: int = get_cost(tower_id)
	var tower_rarity: Rarity.enm = get_rarity(tower_id)
	var min_capacity: int = min_capacity_map[tower_rarity]
	var max_capacity: int = max_capacity_map[tower_rarity]

	var result_capacity: int = 1

	for capacity in range(max_capacity, 0, -1):
		var min_cost: int = capacity_to_min_cost_map[capacity]

		if tower_cost >= min_cost:
			result_capacity = clampi(capacity, min_capacity, max_capacity)

			break

	result_capacity = min(result_capacity, Constants.INVENTORY_CAPACITY_MAX)

	return result_capacity


func get_generated_tooltip(tower_id: int) -> String:
	if !_tower_tooltips.has(tower_id) || !_tower_tooltips[tower_id].has(1):
		return "[missing tooltip]"

	var tooltip: String = _tower_tooltips[tower_id][1]

	return tooltip


func get_dps(tower_id: int) -> float:
	var damage: int = TowerProperties.get_base_damage(tower_id)
	var attackspeed: float = TowerProperties.get_base_attackspeed(tower_id)
	var dps: float = Utils.divide_safe(damage, attackspeed)

	return dps


func get_mana(tower_id: int) -> int:
	var mana: int = _get_property(tower_id, CsvProperty.MANA) as int

	return mana


func get_mana_regen(tower_id: int) -> int:
	var mana_regen: int = _get_property(tower_id, CsvProperty.MANA_REGEN) as int

	return mana_regen


func get_upgrade_id_for_tower(tower_id: int) -> int:
	var family_id: int = get_family(tower_id)
	var family_list: Array = get_towers_in_family(family_id)
	var next_tier: int = get_tier(tower_id) + 1

	for id in family_list:
		var this_tier: int = get_tier(id)

		if this_tier == next_tier:
			return id
	
	return -1


func get_range_data_list(tower_id: int) -> Array[RangeData]:
	if !_tower_ranges.has(tower_id):
		var empty_list: Array[RangeData] = []

		return empty_list

	var range_data_list: Array[RangeData] = _tower_ranges[tower_id]

	return range_data_list


# Family name is the name of the first tier tower in the
# family, with spaces removed. Used to construct filenames
# for tower scenes and scripts.
func get_family_name(tower_id: int) -> String:
	var family_id: int = TowerProperties.get_family(tower_id)
	var towers_in_family: Array = TowerProperties.get_towers_in_family(family_id)

	if towers_in_family.is_empty():
		return ""

	var first_tier_id: int = towers_in_family.front()
	var first_tier_name: String = TowerProperties.get_display_name(first_tier_id)
	var family_name: String = first_tier_name.replace(" ", "")

	return family_name


#########################
###      Private      ###
#########################

func _get_property(tower_id: int, csv_property: CsvProperty) -> String:
	if !_properties.has(tower_id):
		push_error("No properties for tower: ", tower_id)

		return ""
	
	var properties: Dictionary = _properties[tower_id]
	var value: String = properties[csv_property]

	return value


# Create range data based on attack ranges and extra ranges
# for abilities, defined in ranges csv
func _load_tower_ranges_map() -> Dictionary:
	var csv: Array[PackedStringArray] = UtilsStatic.load_csv(TOWER_RANGES_PATH)

	var result: Dictionary = {}

# 	Add attack ranges
	var tower_id_list: Array = get_tower_id_list()
	for tower_id in tower_id_list:
		var empty_list: Array[RangeData] = []
		result[tower_id] = empty_list
		
		var attack_enabled: bool = get_attack_enabled(tower_id)

		if attack_enabled:
			var attack_range: float = get_range(tower_id)
			var range_data: RangeData = RangeData.new("Attack Range", attack_range)
			range_data.targets_creeps = true
			range_data.affected_by_builder = true
			result[tower_id].append(range_data)

# 	Add ability ranges
	for csv_line in csv:
		var properties: Dictionary = UtilsStatic.load_csv_line(csv_line)
		var tower_id: int = properties[TowerProperties.RangeColumn.TOWER_ID].to_int()
		var range_name: String = properties[TowerProperties.RangeColumn.NAME]
		var radius: float = properties[TowerProperties.RangeColumn.RADIUS].to_float()
		var targets_creeps_string: String = properties[TowerProperties.RangeColumn.TARGETS_CREEPS]
		var targets_creeps: bool = targets_creeps_string == "TRUE"

		var range_data: RangeData = RangeData.new(range_name, radius)
		range_data.targets_creeps = targets_creeps

		result[tower_id].append(range_data)

	return result
