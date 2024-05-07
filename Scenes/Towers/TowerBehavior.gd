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

#	NOTE: must setup aura's after calling tower_init()
#	because auras use buff types which are initialized
#	inside tower_init().
	var aura_type_list: Array[AuraType] = get_aura_types()
	for aura_type in aura_type_list:
		tower.add_aura(aura_type)

	on_create(preceding_tower)


func get_specials_modifier() -> Modifier:
	return _specials_modifier


# Override in subclass to define custom stats for each tower
# tier. Access as _stats.
func get_tier_stats() -> Dictionary:
	return {}


func get_ability_info_list() -> Array[AbilityInfo]:
	var list: Array[AbilityInfo] = []

	return list


# Override in subclass to define the description of tower
# abilities. String can contain rich text format(BBCode).
# NOTE: by default all numbers in this text will be colored
# but you can also define your own custom color tags.
func get_ability_description() -> String:
	return ""


# Same as get_ability_description() but shorter. Should not
# contain any numbers.
func get_ability_description_short() -> String:
	return ""


# Override in subclass to define ranges for abilities which
# are not an aura or autocast. Ranges for auras and autocast
# are displayed automatically and should not be included in
# this list.
# NOTE: this function is called to generate data into csv
# file. Not used during normal gameplay.
func get_ability_ranges() -> Array[RangeData]:
	return []


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
# NOTE: must be called after _stats is initialized.
func get_aura_types() -> Array[AuraType]:
	var empty_list: Array[AuraType] = []

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
