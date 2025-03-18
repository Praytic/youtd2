class_name TowerBehavior extends Node


# TowerBehavior is used to implement behavior for a
# particular tower. Each tower family has it's own
# TowerBehavior script which is attached to Tower base class
# to create a complete tower.


var tower: Tower
var _stats: Dictionary = {}


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
	var tower_id: int = tower.get_id()
	var aura_id_list: Array = TowerProperties.get_aura_id_list(tower_id)
	for aura_id in aura_id_list:
		var aura_type: AuraType = AuraType.make_aura_type(aura_id, self)
		tower.add_aura(aura_type)

	var autocast_id_list: Array = TowerProperties.get_autocast_id_list(tower_id)
	for autocast_id in autocast_id_list:
		var autocast: Autocast = Autocast.make_from_id(autocast_id, self)
		tower.add_autocast(autocast)

	on_create(preceding_tower)


# Override in subclass to define custom stats for each tower
# tier. Access as _stats.
func get_tier_stats() -> Dictionary:
	return {}


# Override in subclass to attach trigger handlers to
# triggers buff passed in the argument.
func load_triggers(_triggers_bt: BuffType):
	pass


# Override in subclass to initialize tower.
# NOTE: do NOT use _init() function - that's a native Godot
# function and it's called too early which will make some
# variables unavailable.
# NOTE: tower.init() in JASS
func tower_init():
	pass


# TODO: remove this f-n and implementations in tower scripts
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
