class_name Aura
extends Node2D

# Aura applies an aura effect(buff) to targets in range of
# caster.

# NOTE: it is important to use get_units_in_range() for all
# aura range checking code. get_units_in_range() does the
# special range extension for towers - other range/distance
# functions don't.

# NOTE: level and level_add parameters define how aura level
# scales with tower level.
# aura level = level + level_add * tower_level
# - Setting level to 0 and level_add to 1 will make aura
#   level the same as tower level.
# - Setting level to 100 and level_add to 2 will make aura
#   level start at 200 and incrase by 2 for each tower
#   level.

var _aura_range: float = 10.0
var _target_type: TargetType = null
var _target_self: bool = false
var _level: int = 0
var _level_add: int = 0
var _aura_effect: BuffType = null

# NOTE: this is only used by MagicalSightBuff. All other
# aura's do not include invisible units.
var _include_invisible: bool = false

var _caster: Unit = null
var _target_list: Array = []


#########################
###     Built-in      ###
#########################

func _ready():
	_caster.level_up.connect(_on_caster_level_up)
	tree_exited.connect(_on_tree_exited)


#########################
###       Public      ###
#########################

# Triggers REFRESH event for buffs applied by this aura.
func refresh():
	var caster_position: Vector2 = _caster.get_position_wc3_2d()
	var units_in_range: Array = Utils.get_units_in_range(_caster, _target_type, caster_position, _aura_range, _include_invisible)

	for unit in units_in_range:
		var buff: Buff = unit.get_buff_of_type(_aura_effect)

		if buff == null:
			continue

		var buff_caster: Unit = buff.get_caster()
		var buff_was_applied_by_this_aura: bool = buff_caster == _caster

		if !buff_was_applied_by_this_aura:
			continue
		
		buff._emit_refresh_event()


func get_level() -> int:
	return _level + _caster.get_level() * _level_add


func get_range() -> float:
	return _aura_range


#########################
###      Private      ###
#########################

func _remove_aura_effect_from_units(unit_list: Array):
	_remove_invalid_targets()

	for target in unit_list:
		var buff: Buff = target.get_buff_of_type(_aura_effect)

		if buff != null && buff.get_caster() == _caster:
			buff._remove_as_aura()


func _remove_invalid_targets():
	var invalid_list: Array = []
	
	for target in _target_list:
		if !is_instance_valid(target):
			invalid_list.append(target)

	for target in invalid_list:
		_target_list.erase(target)


func _change_buff_level_to_this_aura_level(buff: Buff):
	buff.set_level(get_level())
	buff._change_giver_of_aura_effect(_caster)
	buff._emit_refresh_event()


#########################
###     Callbacks     ###
#########################

func _on_manual_timer_timeout():
	_remove_invalid_targets()

	var caster_position: Vector2 = _caster.get_position_wc3_2d()
	var units_in_range: Array = Utils.get_units_in_range(_caster, _target_type, caster_position, _aura_range, _include_invisible)

# 	Remove buff from units that have went out of range or
# 	became invisible
	var removed_target_list: Array = []

	for target in _target_list:
		var in_range = units_in_range.has(target)

		if !in_range || (target.is_invisible() && !_include_invisible):
			removed_target_list.append(target)

	for target in removed_target_list:
		_target_list.erase(target)

	_remove_aura_effect_from_units(removed_target_list)

# 	Apply buff to units in range
	for unit in units_in_range:
		if !_target_self && unit == _caster:
			continue

		var active_buff: Buff = unit.get_buff_of_type(_aura_effect)

#		NOTE: If there's an active buff and it's from a
#		tower of same family but lower tier - remove it.
#		This is to always prio auras from higher tier
#		towers. Doesn't affect buffs defined outside tower
#		scripts, in items for example.
#
#		[ORIGINAL_GAME_DEVIATION] The mechanic of comparing
#		tower tiers didn't exist in original game. Aura
#		which was entered first would stay on the creep,
#		even if creep entered a stronger version of same
#		aura.
# 
#		NOTE: this code section needs to be duplicated from
#		BuffType._do_stacking_behavior() because for auras
#		this logic needs to be slightly different.
		if active_buff != null:
			var owned_by_tower: bool = _aura_effect.get_is_owned_by_tower()
			var family_active: int = active_buff.get_tower_family()
			var family_new: int = _aura_effect.get_tower_family()
			var family_is_same: bool = family_active == family_new
			var tier_active: int = active_buff.get_tower_tier()
			var tier_new: int = _aura_effect.get_tower_tier()
			var new_tier_is_greater: bool = tier_new > tier_active

			if owned_by_tower && family_is_same && new_tier_is_greater:
				active_buff._remove_as_aura()
				active_buff = null

		if active_buff == null:
			_aura_effect.apply_to_unit_permanent(_caster, unit, get_level())
			_target_list.append(unit)
		else:
			var can_increase_level: bool = active_buff.get_level() < get_level()
			if can_increase_level:
				_change_buff_level_to_this_aura_level(active_buff)


func _on_tree_exited():
	_remove_aura_effect_from_units(_target_list)


# Level down the aura buffs here when tower levels down.
# Note that level ups are handled in _on_timer_timeout().
# 
# NOTE: the way lving down is handled is a bit imperfect
# because if there are two towers with same aura and one of
# them levels down, then the aura will temporarily level
# down for 0.2s and then go back up to the level of the
# strongest aura. It's not critical and I couldn't find a
# better solution which doesn't break anything else.
func _on_caster_level_up(_level_increased: bool):
	_remove_invalid_targets()
	
	var new_level: int = _caster.get_level()

	for target in _target_list:
		var active_buff: Buff = target.get_buff_of_type(_aura_effect)

		if active_buff == null:
			continue

		var need_to_level_down: bool = active_buff.get_level() > new_level

		if need_to_level_down:
			_change_buff_level_to_this_aura_level(active_buff)


#########################
###       Static      ###
#########################

static func make(aura_id: int, object_with_buff_var: Object, caster: Unit) -> Aura:
	var aura: Aura = Preloads.aura_scene.instantiate()

	aura._aura_range = AuraProperties.get_aura_range(aura_id)
	aura._target_type = AuraProperties.get_target_type(aura_id)
	aura._target_self = AuraProperties.get_target_self(aura_id)
	aura._level = AuraProperties.get_level(aura_id)
	aura._level_add = AuraProperties.get_level_add(aura_id)
	aura._caster = caster

	var buff_type_string: String = AuraProperties.get_buff_type(aura_id)
	var buff_type: BuffType = object_with_buff_var.get(buff_type_string)
	if buff_type == null:
		push_error("Failed to find buff type for aura. Buff type = %s, aura id = %d" % [buff_type_string, aura_id])
	aura._aura_effect = buff_type
	
	return aura
