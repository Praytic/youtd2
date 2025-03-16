class_name TowerBehavior extends Node


# TowerBehavior is used to implement behavior for a
# particular tower. Each tower family has it's own
# TowerBehavior script which is attached to Tower base class
# to create a complete tower.


var tower: Tower
var _stats: Dictionary = {}
var _specials_modifier: Modifier = Modifier.new()
var _new_aura_type_list: Array[AuraType] = []
var _new_autocast_list: Array[Autocast] = []
var _new_ability_info_list: Array[AbilityInfo] = []


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
	var tower_id: int = tower.get_id()
	var ability_id_list: Array = TowerProperties.get_ability_id_list(tower_id)
	for ability_id in ability_id_list:
		var ability: AbilityInfo = _make_ability(ability_id)
		_new_ability_info_list.append(ability)

	var aura_id_list: Array = TowerProperties.get_aura_id_list(tower_id)
	for aura_id in aura_id_list:
		var aura_type: AuraType = _make_aura_type(aura_id)
		tower.add_aura(aura_type)
		_new_aura_type_list.append(aura_type)

	var autocast_id_list: Array = TowerProperties.get_autocast_id_list(tower_id)
	for autocast_id in autocast_id_list:
		var autocast: Autocast = _make_autocast(autocast_id)
		tower.add_autocast(autocast)
		_new_autocast_list.append(autocast)

	on_create(preceding_tower)


func get_specials_modifier() -> Modifier:
	return _specials_modifier


# Override in subclass to define custom stats for each tower
# tier. Access as _stats.
func get_tier_stats() -> Dictionary:
	return {}


# TODO: remove this f-n and all get_ability_info_list() from
# tower scripts
func get_ability_info_list() -> Array[AbilityInfo]:
	var list: Array[AbilityInfo] = []

	return list


func get_ability_info_list_NEW() -> Array[AbilityInfo]:
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


# TODO: remove this f-n and implementations in tower scripts
# Override in subclass to define auras.
# NOTE: must be called after tower_init()
func get_aura_types() -> Array[AuraType]:
	var empty_list: Array[AuraType] = []

	return empty_list


func get_aura_types_NEW() -> Array[AuraType]:
	return _new_aura_type_list


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


#########################
###      Private      ###
#########################

func _make_ability(ability_id: int) -> AbilityInfo:
	var ability: AbilityInfo = AbilityInfo.new()

	ability.name_english = AbilityProperties.get_name_english(ability_id)
	ability.name = AbilityProperties.get_ability_name(ability_id)
	ability.radius = AbilityProperties.get_ability_range(ability_id)
	ability.target_type = AbilityProperties.get_target_type(ability_id)
	ability.icon = AbilityProperties.get_icon_path(ability_id)
	ability.description_short = AbilityProperties.get_description_short(ability_id)
	ability.description_full = AbilityProperties.get_description_full(ability_id)

	return ability


func _make_autocast(autocast_id: int) -> Autocast:
	var autocast: Autocast = Autocast.make()

	autocast.name_english = AutocastProperties.get_name_english(autocast_id)
	autocast.title = AutocastProperties.get_autocast_name(autocast_id)
	autocast.icon = AutocastProperties.get_icon_path(autocast_id)
	autocast.description_short = AutocastProperties.get_description_short(autocast_id)
	autocast.description = AutocastProperties.get_description_full(autocast_id)

	autocast.caster_art = AutocastProperties.get_caster_art(autocast_id)
	autocast.target_art = AutocastProperties.get_target_art(autocast_id)
	autocast.num_buffs_before_idle = AutocastProperties.get_num_buffs_before_idle(autocast_id)
	autocast.autocast_type = AutocastProperties.get_autocast_type(autocast_id)
	autocast.cast_range = AutocastProperties.get_cast_range(autocast_id)
	autocast.auto_range = AutocastProperties.get_auto_range(autocast_id)
	autocast.target_self = AutocastProperties.get_target_self(autocast_id)
	autocast.cooldown = AutocastProperties.get_cooldown(autocast_id)
	autocast.is_extended = AutocastProperties.get_is_extended(autocast_id)
	autocast.mana_cost = AutocastProperties.get_mana_cost(autocast_id)
	autocast.buff_target_type = AutocastProperties.get_buff_target_type(autocast_id)

	var buff_type_string: String = AutocastProperties.get_buff_type(autocast_id)
	var buff_type: BuffType
	if !buff_type_string.is_empty():
		buff_type = get(buff_type_string)
		
		if buff_type == null:
			push_error("Failed to find buff type for autocast. Buff type = %s, tower id = %d" % [buff_type_string, tower.get_id()])
	else:
		buff_type = null
	
	autocast.buff_type = buff_type

	var handler_function_string: String = AutocastProperties.get_handler_function(autocast_id)
	var handler_function: Callable
	if !handler_function_string.is_empty():
		handler_function = Callable(self, handler_function_string)
		
		if handler_function.is_null():
			push_error("Failed to find handle function for autocast. Handler function = %s, tower id = %d" % [handler_function_string, tower.get_id()])
	else:
		handler_function = Callable()
	
	autocast.handler = handler_function

	return autocast


func _make_aura_type(aura_id: int) -> AuraType:
	var aura: AuraType = AuraType.new()

	aura.name_english = AuraProperties.get_name_english(aura_id)
	aura.name = AuraProperties.get_aura_name(aura_id)
	aura.icon = AuraProperties.get_icon_path(aura_id)
	aura.description_short = AuraProperties.get_description_short(aura_id)
	aura.description_full = AuraProperties.get_description_full(aura_id)
	aura.aura_range = AuraProperties.get_aura_range(aura_id)
	aura.target_type = AuraProperties.get_target_type(aura_id)
	aura.target_self = AuraProperties.get_target_self(aura_id)
	aura.level = AuraProperties.get_level(aura_id)
	aura.level_add = AuraProperties.get_level_add(aura_id)
	aura.is_hidden = AuraProperties.get_is_hidden(aura_id)

	var buff_type_string: String = AuraProperties.get_buff_type(aura_id)
	var buff_type: BuffType = get(buff_type_string)
	if buff_type == null:
		push_error("Failed to find buff type for aura. Buff type = %s, tower id = %d" % [buff_type_string, tower.get_id()])
	aura.aura_effect = buff_type
	
	return aura
