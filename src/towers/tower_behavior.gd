class_name TowerBehavior extends Node


# TowerBehavior is used to implement behavior for a
# particular tower. Each tower family has it's own
# TowerBehavior script which is attached to Tower base class
# to create a complete tower.


var tower: Tower
var _stats: Dictionary = {}
var _specials_modifier: Modifier = Modifier.new()


#########################
###       Public      ###
#########################

func init(tower_arg: Tower, preceding_tower: Tower):
	tower = tower_arg

# 	Load stats for current tier. Stats are defined in
# 	subclass.
	var tier: int = tower.get_tier()
	var stats_for_all_tiers: Dictionary = get_tier_stats()
	if stats_for_all_tiers.has(tier):
		_stats = stats_for_all_tiers[tier]
	else:
		_stats = {}

	load_specials(_specials_modifier)
	tower.add_modifier(_specials_modifier)

#	NOTE: need to call load_triggers() after loading stats
#	because stats must be available in load_triggers().
	var triggers_bt: BuffType = BuffType.new("triggers_bt", 0, 0, true, self)
	triggers_bt.set_hidden()
	triggers_bt.disable_stacking_behavior()
	triggers_bt.set_buff_tooltip("Triggers buff for tower")
	load_triggers(triggers_bt)
	triggers_bt.apply_to_unit_permanent(tower, tower, 0)

	tower_init()

#	NOTE: must setup auras and autocasts after calling
#	tower_init() because some auras and autocasts use buff
#	types which are initialized inside tower_init().
	var aura_type_list: Array[AuraType] = get_aura_types()
	for aura_type in aura_type_list:
		tower.add_aura(aura_type)

	var autocast_list: Array[Autocast] = create_autocasts()
	for autocast in autocast_list:
		tower.add_autocast(autocast)

	on_create(preceding_tower)

#	Check that ability icons are valid
	var ability_info_list: Array[AbilityInfo] = get_ability_info_list()
	var tower_id: int = tower.get_id()
	var tower_name: String = TowerProperties.get_display_name(tower_id)
	for ability_info in ability_info_list:
		var ability_name: String = ability_info.name
		var icon_path: String = ability_info.icon
		var icon_path_is_valid: bool = ResourceLoader.exists(icon_path)

		if !icon_path_is_valid:
			push_error("Invalid ability icon for tower %s, ability %s: %s" % [tower_name, ability_name, icon_path])

# 	Check ranges
	for ability_info in ability_info_list:
		var range_is_defined: bool = ability_info.radius != 0
		var target_type_is_defined: bool = ability_info.target_type != null

		if range_is_defined != target_type_is_defined:
			push_error("Invalid ability config for tower %s. Both range radius and target_type must be defined." % [tower_name])



#	Check aura types
	for aura_type in aura_type_list:
		var name_defined: bool = !aura_type.name.is_empty()
		var icon_defined: bool = !aura_type.icon.is_empty()
		var description_short_defined: bool = !aura_type.description_short.is_empty()
		var description_full_defined: bool = !aura_type.description_full.is_empty()
		var aura_type_is_valid: bool = name_defined && icon_defined && description_short_defined && description_full_defined

		if !aura_type_is_valid:
			push_error("Not all properties are defined for aura type for tower %s" % [tower_name])


func get_specials_modifier() -> Modifier:
	return _specials_modifier


# Override in subclass to define custom stats for each tower
# tier. Access as _stats.
func get_tier_stats() -> Dictionary:
	return {}


func get_ability_info_list() -> Array[AbilityInfo]:
	var list: Array[AbilityInfo] = []

	return list


# Override in subclass to attach trigger handlers to
# triggers buff passed in the argument.
func load_triggers(_triggers_bt: BuffType):
	pass


# Override in subclass to add tower specials. This includes
# adding modifiers and changing attack styles to splash or
# bounce.
func load_specials(_modifier: Modifier):
	pass


# Override in subclass to initialize tower.
# NOTE: do NOT use _init() function - that's a native Godot
# function and it's called too early which will make some
# variables unavailable.
# NOTE: tower.init() in JASS
func tower_init():
	pass


# Override in subclass to define auras.
# NOTE: must be called after tower_init()
func get_aura_types() -> Array[AuraType]:
	var empty_list: Array[AuraType] = []

	return empty_list


# Override in subclass to define auras.
# NOTE: must be called after tower_init()
func create_autocasts() -> Array[Autocast]:
	var empty_list: Array[Autocast] = []

	return empty_list
	

# NOTE: tower.onCreate() in JASS
func on_create(_preceding_tower: Tower):
	pass


# NOTE: tower.onDestruct() in JASS
func on_destruct():
	pass


# NOTE: tower.onTowerDetails() in JASS
func on_tower_details() -> MultiboardValues:
	var empty_multiboard: MultiboardValues = MultiboardValues.new(0)

	return empty_multiboard


func get_tower() -> Tower:
	return tower
