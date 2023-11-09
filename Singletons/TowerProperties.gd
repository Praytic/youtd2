extends Node

# Convenience getters for tower properties. Actual values
# are stored in Properties, this class contains getters.


const ICON_SIZE_M = 128
const TIER_ICON_SIZE_M = 64
const _tier_icons_m = preload("res://Assets/Towers/tier_icons_m.png")
const _tower_icons_m = preload("res://Assets/Towers/tower_icons_m.png")
const _placeholder_tower_icon: Texture2D = preload("res://Resources/UI/PlaceholderTowerIcon.tres")


var _min_required_wave_for_build_mode = {
	Rarity.enm.COMMON: 0,
	Rarity.enm.UNCOMMON: 6,
	Rarity.enm.RARE: 24,
	Rarity.enm.UNIQUE: 60
}


func get_icon_texture(tower_id: int) -> Texture2D:
	var icon_atlas_num: int = TowerProperties.get_icon_atlas_num(tower_id)

	var tower_has_no_icon: bool = icon_atlas_num == -1
	if tower_has_no_icon:
		return _placeholder_tower_icon
	
	var tower_icon = AtlasTexture.new()
	var icon_size: int
	
	tower_icon.set_atlas(_tower_icons_m)
	icon_size = ICON_SIZE_M
	
	var region: Rect2 = Rect2(TowerProperties.get_element(tower_id) * icon_size, icon_atlas_num * icon_size, icon_size, icon_size)
	tower_icon.set_region(region)
	return tower_icon


func get_tier(tower_id: int) -> int:
	return TowerProperties.get_csv_property(tower_id, Tower.CsvProperty.TIER).to_int()


func get_tier_icon_texture(tower_id: int) -> Texture2D:
	var tower_rarity: Rarity.enm = TowerProperties.get_rarity(tower_id)
	var tower_tier = TowerProperties.get_tier(tower_id) - 1
	var tier_icon = AtlasTexture.new()
	var icon_size: int
	
	tier_icon.set_atlas(_tier_icons_m)
	icon_size = TIER_ICON_SIZE_M
	
	tier_icon.set_region(Rect2(tower_tier * icon_size, tower_rarity * icon_size, icon_size, icon_size))
	return tier_icon


func is_released(tower_id: int) -> bool:
	if Settings.get_bool_setting(Settings.ENABLE_UNRELEASED_TOWERS):
		return true

	return TowerProperties.get_csv_property(tower_id, Tower.CsvProperty.RELEASE).to_int() as bool


func get_icon_atlas_num(tower_id: int) -> int:
	var icon_atlas_num_string: String = TowerProperties.get_csv_property(tower_id, Tower.CsvProperty.ICON_ATLAS_NUM)

	if !icon_atlas_num_string.is_empty():
		var icon_atlas_num: int = icon_atlas_num_string.to_int()

		return icon_atlas_num
	else:
		return -1


func get_element(tower_id: int) -> Element.enm:
	var element_string: String = TowerProperties.get_csv_property(tower_id, Tower.CsvProperty.ELEMENT)
	var element: Element.enm = Element.from_string(element_string)

	return element


func get_csv_property(tower_id: int, csv_property: Tower.CsvProperty) -> String:
	assert(tower_id != 0, "Tower is undefined.")
	
	var properties: Dictionary = Properties.get_tower_csv_properties_by_id(tower_id)
	var value: String = properties[csv_property]

	return value


func get_rarity(tower_id: int) -> Rarity.enm:
	var rarity_string: String = get_csv_property(tower_id, Tower.CsvProperty.RARITY)
	var rarity: Rarity.enm = Rarity.convert_from_string(rarity_string)

	return rarity
	

func get_display_name(tower_id: int) -> String:
	return get_csv_property(tower_id, Tower.CsvProperty.NAME)


func get_tooltip_text(tower_id: int) -> String:
	var display_name: String = get_display_name(tower_id)
	var tooltip: String = "%s, %s" % [display_name, tower_id]

	return tooltip


func get_cost(tower_id: int) -> int:
	var cost: int = get_csv_property(tower_id, Tower.CsvProperty.COST) as int

	return cost


func get_description(tower_id: int) -> String:
	var description: String = get_csv_property(tower_id, Tower.CsvProperty.DESCRIPTION)

	return description


func get_author(tower_id: int) -> String:
	var author: String = get_csv_property(tower_id, Tower.CsvProperty.AUTHOR)

	return author


func get_damage_min(tower_id: int) -> int:
	var damage_min: int = get_csv_property(tower_id, Tower.CsvProperty.ATTACK_DAMAGE_MIN).to_int()

	return damage_min


func get_damage_max(tower_id: int) -> int:
	var damage_max: int = get_csv_property(tower_id, Tower.CsvProperty.ATTACK_DAMAGE_MAX).to_int()

	return damage_max


func get_base_damage(tower_id: int) -> int:
	var base_damage: int = floor((get_damage_min(tower_id) + get_damage_max(tower_id)) / 2.0)

	return base_damage


func get_base_cooldown(tower_id: int) -> float:
	var base_cooldown: float = get_csv_property(tower_id,Tower. CsvProperty.ATTACK_CD).to_float()

	return base_cooldown


func get_attack_type(tower_id: int) -> AttackType.enm:
	var attack_type_string: String = get_csv_property(tower_id,Tower. CsvProperty.ATTACK_TYPE)
	var attack_type: AttackType.enm = AttackType.from_string(attack_type_string)

	return attack_type


func get_range(tower_id: int) -> float:
	var attack_range: float = get_csv_property(tower_id,Tower. CsvProperty.ATTACK_RANGE).to_float()

	return attack_range


func get_required_element_level(tower_id: int) -> int:
	var element_level_string: String = TowerProperties.get_csv_property(tower_id, Tower.CsvProperty.REQUIRED_ELEMENT_LEVEL)
	var element_level_is_defined: bool = !element_level_string.is_empty()

	var element_level: int
	if element_level_is_defined:
		element_level = element_level_string.to_int()
	else:
		element_level = _get_required_element_level_from_formula(tower_id)

#	NOTE: required element level cannot be 0
	element_level = max(1, element_level)

	return element_level


func get_required_wave_level(tower_id: int) -> int:
	var required_wave_string: String = TowerProperties.get_csv_property(tower_id, Tower.CsvProperty.REQUIRED_WAVE_LEVEL)
	var required_wave_is_defined: bool = !required_wave_string.is_empty()

	var required_wave: int
	if required_wave_is_defined:
		required_wave = required_wave_string.to_int()
	else:
		required_wave = _get_required_wave_level_from_formula(tower_id)

	if Globals.game_mode == GameMode.enm.BUILD:
		var rarity: Rarity.enm = TowerProperties.get_rarity(tower_id)
		var min_required_wave: int = _min_required_wave_for_build_mode[rarity]
		required_wave = max(required_wave, min_required_wave)

	return required_wave


func wave_level_foo(tower_id: int) -> bool:
	var wave_level: int = WaveLevel.get_current()
	var required_wave_level: int = TowerProperties.get_required_wave_level(tower_id)
	var out: bool = wave_level >= required_wave_level

	return out


func element_level_foo(tower_id: int) -> bool:
	var required_element_level: int = TowerProperties.get_required_element_level(tower_id)
	var element: Element.enm = get_element(tower_id)
	var element_research_level: int = ElementLevel.get_current(element)
	var out: bool = element_research_level >= required_element_level

	return out


func requirements_are_satisfied(tower_id: int) -> bool:
	if Config.ignore_upgrade_requirements():
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
	if Globals.game_mode == GameMode.enm.RANDOM_WITH_UPGRADES && tier == 1:
		return true
	elif Globals.game_mode == GameMode.enm.TOTALLY_RANDOM:
		return true

	var out: bool = element_level_foo(tower_id) && wave_level_foo(tower_id)

	return out


# NOTE: tower.getFamily() in JASS
func get_family(tower_id: int) -> int:
	return TowerProperties.get_csv_property(tower_id, Tower.CsvProperty.FAMILY_ID).to_int()


# NOTE: sorted by tier
func get_towers_in_family(family_id: int) -> Array:
	var family_list: Array = Properties.get_tower_id_list_by_filter(Tower.CsvProperty.FAMILY_ID, str(family_id))
	family_list.sort_custom(func(a, b): 
		var tier_a: int = TowerProperties.get_tier(a)
		var tier_b: int = TowerProperties.get_tier(b)
		return tier_a < tier_b)

	return family_list


# NOTE: this formula is the inverse of the formula for tower cost
# from TowerDistribution._get_max_cost()
func _get_required_wave_level_from_formula(tower_id: int) -> int:
# 	NOTE: prevent value inside sqrt() from going below 0
	var tower_cost: int = get_cost(tower_id)
	var wave_level: int = ceili((sqrt(max(0.01, 60 * tower_cost - 3575)) - 25) / 6)

	if wave_level < 0:
		return 0

	return wave_level


# TODO: adjust to be accurate. Some of the min costs in the
# map may be higher than they should be. This will cause
# this f-n to return element level which is 1 less than it
# was in original game.
func _get_required_element_level_from_formula(tower_id: int) -> int:
	var element_level_to_min_cost_map: Dictionary = {
		1: 140,
		2: 220,
		3: 350,
		4: 500,
		5: 680,
		6: 900,
		7: 1100,
		8: 1300,
		9: 1600,
		10: 2000,
		11: 2130,
		12: 2450,
		13: 2750,
		14: 3150,
		15: 4000,
	}

	var tower_cost: int = get_cost(tower_id)

	for element_level in range(15, 0, -1):
		var min_cost: int = element_level_to_min_cost_map[element_level]

		if tower_cost >= min_cost:
			return element_level

	return 1


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

	for capacity in range(max_capacity, 0, -1):
		var min_cost: int = capacity_to_min_cost_map[capacity]

		if tower_cost >= min_cost:
			var clamped_capacity: int = clampi(capacity, min_capacity, max_capacity)

			return clamped_capacity

	return 1
