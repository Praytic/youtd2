class_name BuffType
extends Node


# BuffType stores buff parameters and can be used to create
# buff instances. It's possible to define a custom BuffType
# by subclassing.
# 
# Buffs can have event handlers. To add an event handler,
# define a handler function in your subclass and call the
# appropriate add_event_handler function. All handler
# functions are called with one parameter Event which passes
# information about the event.
#
# NOTE: BuffType needs to be Node so that it can be used as
# event handler for Buffs. Buff event handlers must be Node
# because buff's need to connect to Node's tree_exited()
# signal for correct "cleanup" event logic.


class SpecialEffect:
	var path: String = ""
	var z: float = 0.0
	var scale: float = 1.0
	var color: Color = Color.WHITE
	var draw_below_unit: bool = false

class CommonHandlerData:
	var handler: Callable
	var event_type: Event.Type

class PeriodicHandlerData:
	var handler: Callable
	var period: float

class RangeHandlerData:
	var handler: Callable
	var radius: float
	var target_type: TargetType

class AuraCreationInfo:
	var aura_id: int
	var object_with_buff_var: Object


var _unique_name: String
var _time_base: float
var _time_level_add: float
var _friendly: bool
var _modifier: Modifier = Modifier.new()
var _common_handler_list: Array[CommonHandlerData] = []
var _periodic_handler_list: Array[PeriodicHandlerData] = []
var _range_handler_list: Array[RangeHandlerData] = []
var _aura_creation_info_list: Array[AuraCreationInfo] = []
var _tooltip_text: String = ""
var _buff_icon: String = ""
var _buff_icon_color: Color = Color.GRAY
var _defined_custom_buff_icon_color: bool = false
var _is_hidden: bool = false
var _is_purgable: bool = true
var _stacking_behavior_is_enabled: bool = true
var _special_effect_data: SpecialEffect = null
# NOTE: these values are defined if the buff type was
# created inside a TowerBehavior script.
var _is_owned_by_tower: bool
var _tower_family: int
var _tower_tier: int


#########################
###     Built-in      ###
#########################

# NOTE: if your script creates multiple BuffType's, then
# each BuffType should be created with a different
# "variable_name" arg. Examples: "poison_bt", "curse_bt".
func _init(variable_name: String, time_base: float, time_level_add: float, friendly: bool, owner_node: Node):
	owner_node.add_child(self)

#	NOTE: add path of owner script to ensure uniqueness
	var parent_script: Script = owner_node.get_script()
	var parent_script_path: String = parent_script.get_path()
	_unique_name = "%s-%s" % [parent_script_path, variable_name]

	_time_base = time_base
	_time_level_add = time_level_add
	_friendly = friendly

	if owner_node is TowerBehavior:
		var owner_tower_behavior: TowerBehavior = owner_node as TowerBehavior
		var owner_tower: Tower = owner_tower_behavior.get_tower()
		_is_owned_by_tower = true
		_tower_family = owner_tower.get_family()
		_tower_tier = owner_tower.get_tier()
	else:
		_is_owned_by_tower = false
		_tower_family = -1
		_tower_tier = -1


#########################
###       Public      ###
#########################

# NOTE: buffType.applyAdvanced() in JASS
func _apply_internal(caster: Unit, target: Unit, level: int, time: float) -> Buff:
	if _stacking_behavior_is_enabled:
		var higher_prio_buff: Buff = _do_stacking_behavior(target, level)

		if higher_prio_buff != null:
			return higher_prio_buff

	var buff: Buff = Buff.new()
	buff._caster = caster
	buff._level = level
	buff._target = target
	buff._modifier = _modifier
	buff._time = time
	buff._friendly = _friendly
	buff._buff_type_name = _unique_name
	buff._tooltip_text = _tooltip_text
	buff._is_hidden = _is_hidden
	buff._buff_icon = _buff_icon
	buff._buff_icon_color = _buff_icon_color
	buff._is_owned_by_tower = _is_owned_by_tower
	buff._tower_family = _tower_family
	buff._tower_tier = _tower_tier
	buff._is_purgable = _is_purgable

	if _defined_custom_buff_icon_color:
		buff._buff_icon_color = _buff_icon_color
	elif get_parent() is TowerBehavior && caster is Tower:
		var tower: Tower = caster as Tower
		var element: Element.enm = tower.get_element()
		var element_color: Color = Element.get_color(element)

		buff._buff_icon_color = element_color
	else:
		buff._buff_icon_color = Color.GRAY

	tree_exited.connect(buff._on_buff_type_tree_exited)

	for handler in _common_handler_list:
		buff._add_event_handler(handler.event_type, handler.handler)

	for handler in _periodic_handler_list:
		buff._add_periodic_event(handler.handler, handler.period)

	for handler in _range_handler_list:
		buff._add_event_handler_unit_comes_in_range(handler.handler, handler.radius, handler.target_type)

	for aura_creation_info in _aura_creation_info_list:
		var aura_id: int = aura_creation_info.aura_id
		var object_with_buff_var: Object = aura_creation_info.object_with_buff_var
		buff._add_aura(aura_id, object_with_buff_var)

#	NOTE: need to handle edge cases where buff should not be
#	applied:
# 	1. If buffs are applied to a unit which is in the
# 	   process of getting deleted. In such cases, still
# 	   create the buff to be able to return it and avoid
# 	   null errors but don't add the buff to the unit.
# 	   Adding buff to unit while unit is getting removed
# 	   from tree causes Godot "parent is busy" error.
#	2. If time is 0. Note that time can be "-1" in case of
#	   permanent buffs.
#	In such cases, free the buff immediately.
	var target_is_active: bool = target.is_inside_tree() && !target.is_queued_for_deletion()
	var time_is_valid: bool = time == -1 || time > 0
	var buff_should_be_applied: bool = target_is_active && time_is_valid
	if buff_should_be_applied:
		target._add_buff_internal(buff)
		target.add_child(buff)

		if _special_effect_data != null:
			var special_effect_id: int = Effect.create_simple_at_unit_attached(_special_effect_data.path, target, Unit.BodyPart.ORIGIN, _special_effect_data.z)
			Effect.set_auto_destroy_enabled(special_effect_id, false)
			Effect.set_scale(special_effect_id, _special_effect_data.scale)
			Effect.set_color(special_effect_id, _special_effect_data.color)
			if _special_effect_data.draw_below_unit:
				Effect.set_z_index(special_effect_id, -1)
			buff._special_effect_id = special_effect_id
	else:
#		NOTE: set _cleanup_done to true because no cleanup
#		is needed. Buff was never added to tree, so _ready()
#		wasn't called, so buff's CREATE event wasn't
#		triggered.
		buff._cleanup_done = true
		buff.queue_free()

	return buff


# Base apply function. Overrides time parameters from init().
# 
# NOTE: buffType.applyCustomTimed() in JASS
func apply_custom_timed(caster: Unit, target: Unit, level: int, time: float) -> Buff:
	var buff: Buff = _apply_internal(caster, target, level, time)

	return buff


# Basic apply function. Uses time parameters that were
# passed to BuffType.new(). Returns the new buff that was
# applied or currently active buff if it has higher priority
# due to stacking behavior.
#
# NOTE: buffs must be applied after the unit has been added
# to scene tree, after add_child() was called.
# 
# NOTE: buffType.apply() in JASS
func apply(caster: Unit, target: Unit, level: int) -> Buff:
	var time: float = _time_base + _time_level_add * level

	var buff: Buff = apply_custom_timed(caster, target, level, time)

	return buff


# Apply overriding time parameters from init() and without
# specifying level. This is a convenience function
# 
# NOTE: buffType.applyOnlyTimed() in JASS
func apply_only_timed(caster: Unit, target: Unit, time: float) -> Buff:
	var buff: Buff = apply_custom_timed(caster, target, 0, time)
	
	return buff

# NOTE: buffType.applyToUnitPermanent() in JASS
func apply_to_unit_permanent(caster: Unit, target: Unit, level: int) -> Buff:
	var buff: Buff = apply_custom_timed(caster, target, level, -1.0)
	buff.set_is_purgable(false)

	return buff


func add_event_handler(event_type: Event.Type, handler: Callable):
	var data: CommonHandlerData = CommonHandlerData.new()
	data.handler = handler
	data.event_type = event_type

	_common_handler_list.append(data)


# NOTE: buffType.addPeriodicEvent() in JASS
func add_periodic_event(handler: Callable, period: float):
	var data: PeriodicHandlerData = PeriodicHandlerData.new()
	data.handler = handler
	data.period = period

	_periodic_handler_list.append(data)


# NOTE: buffType.addEventOnUnitComesInRange() in JASS
func add_event_on_unit_comes_in_range(handler: Callable, radius: float, target_type: TargetType):
	var data: RangeHandlerData = RangeHandlerData.new()
	data.handler = handler
	data.radius = radius
	data.target_type = target_type

	_range_handler_list.append(data)


# NOTE: buffType.addEventOnCleanup() in JASS
func add_event_on_cleanup(handler: Callable):
	add_event_handler(Event.Type.CLEANUP, handler)


# NOTE: buffType.addEventOnCreate() in JASS
func add_event_on_create(handler: Callable):
	add_event_handler(Event.Type.CREATE, handler)


# NOTE: buffType.addEventOnUpgrade() in JASS
func add_event_on_upgrade(handler: Callable):
	add_event_handler(Event.Type.UPGRADE, handler)


# NOTE: buffType.addEventOnRefresh() in JASS
func add_event_on_refresh(handler: Callable):
	add_event_handler(Event.Type.REFRESH, handler)


# NOTE: buffType.addEventOnDeath() in JASS
func add_event_on_death(handler: Callable):
	add_event_handler(Event.Type.DEATH, handler)


# NOTE: buffType.addEventOnKill() in JASS
func add_event_on_kill(handler: Callable):
	add_event_handler(Event.Type.KILL, handler)


# NOTE: buffType.addEventOnLevelUp() in JASS
func add_event_on_level_up(handler: Callable):
	add_event_handler(Event.Type.LEVEL_UP, handler)


# NOTE: buffType.addEventOnAttack() in JASS
func add_event_on_attack(handler: Callable):
	add_event_handler(Event.Type.ATTACK, handler)


# NOTE: buffType.addEventOnAttacked() in JASS
func add_event_on_attacked(handler: Callable):
	add_event_handler(Event.Type.ATTACKED, handler)


# This event handler will be called when buffed unit deals
# attack damage (not spell damage!). Note that this event
# can't recurse. If your handler deals attack damage, that
# will not trigger another DAMAGE event.
# NOTE: buffType.addEventOnDamage() in JASS
func add_event_on_damage(handler: Callable):
	add_event_handler(Event.Type.DAMAGE, handler)


# This event handler will be called when buffed unit
# receives attack damage (not spell damage!).
# NOTE: buffType.addEventOnDamaged() in JASS
func add_event_on_damaged(handler: Callable):
	add_event_handler(Event.Type.DAMAGED, handler)


# NOTE: buffType.setEventOnExpire() in JASS
func add_event_on_expire(handler: Callable):
	add_event_handler(Event.Type.EXPIRE, handler)


# NOTE: buffType.addEventOnSpellCasted() in JASS
func add_event_on_spell_casted(handler: Callable):
	add_event_handler(Event.Type.SPELL_CAST, handler)


# NOTE: buffType.addEventOnSpellTargeted() in JASS
func add_event_on_spell_targeted(handler: Callable):
	add_event_handler(Event.Type.SPELL_TARGET, handler)


# NOTE: buffType.addEventOnPurge() in JASS
func add_event_on_purge(handler: Callable):
	add_event_handler(Event.Type.PURGE, handler)


# NOTE: when aura is added to buff type, we only store the
# creation info. The actual aura instance is created later
# when buff is applied on a unit.
func add_aura(aura_id: int, object_with_buff_var: Object):
	var aura_creation_info: AuraCreationInfo = AuraCreationInfo.new()
	aura_creation_info.aura_id = aura_id
	aura_creation_info.object_with_buff_var = object_with_buff_var
	
	_aura_creation_info_list.append(aura_creation_info)


# NOTE: this is useful in rare cases like trigger buffs and
# aura carrier buffs
func disable_stacking_behavior():
	_stacking_behavior_is_enabled = false


#########################
###      Private      ###
#########################

# This function handles situations where a buff is applied
# while another buff of same type is already active.
# 
# This f-n will return null if new buff can be applied. It
# returns an active buff if new buff cannot be applied due
# to stacking behavior. In addition, this f-n modifies the
# active buff in certain cases.
#
# NOTE: there's a special case for two buffs from same
# bufftype buf different tower tiers (same family). In such
# cases, we can't compare by level because different tier
# towers define completely different bonuses for buffs. If
# old tier is lower, old buff gets discarded. If old tier is
# higher, new buff gets discarded. The level difference gets
# ignored.
# 
# NOTE: the stacking logic has to be in the exact way as
# defined here. Changing this logic will break tower and
# item scripts.
# 
# [ORIGINAL_GAME_DEVIATION] The comparison of tower tiers
# didn't exist in original game. If lower tier tower applied
# a buff and a higher tier tower tried to overwrite it, the
# buff from higher tier tower would get rejected.
func _do_stacking_behavior(target: Unit, new_level: int):
	var active_buff: Buff = target.get_buff_of_type(self)

#	NOTE: no active buff, so ok to create new buff
	if active_buff == null:
		return null

	var owned_by_tower: bool = get_is_owned_by_tower()
	var family_active: int = active_buff.get_tower_family()
	var family_new: int = self.get_tower_family()
	var family_is_same: bool = family_active == family_new
	var tier_active: int = active_buff.get_tower_tier()
	var tier_new: int = self.get_tower_tier()
	var tier_is_same: bool = tier_active == tier_new

	if owned_by_tower && family_is_same && !tier_is_same:
		if tier_active > tier_new:
#			NOTE: active buff is always prio if it comes
#			from higher tier same family tower
			return active_buff
		elif tier_active < tier_new:
#			NOTE: active buff gets removed (not upgraded) if
#			it comes from lower tier same family tower.
			active_buff.remove_buff()

			return null

	var active_level: int = active_buff.get_level()

	if new_level > active_level:
#		NOTE: upgrade active buff, no new buff
		active_buff._upgrade_by_new_buff(new_level)

		return active_buff
	elif new_level == active_level:
#		NOTE: refresh active buff, no new buff
		active_buff._refresh_by_new_buff()

		return active_buff
	else :
#		(new_level < active_level)
#		NOTE: keep active buff, no new buff
		return active_buff


#########################
### Setters / Getters ###
#########################

func get_is_owned_by_tower() -> bool:
	return _is_owned_by_tower


func get_tower_family() -> int:
	return _tower_family


func get_tower_tier() -> int:
	return _tower_tier


func get_unique_name() -> String:
	return _unique_name


# Defines a modifier which will be applied to target unit.
# Note that unlike modifiers applied via Unit.add_modifier()
# function, buff modifiers will not react to unit level ups.
# The strength of buff modifiers depends on buff level.
# NOTE: buffType.setBuffModifier() in JASS
func set_buff_modifier(modifier: Modifier):
	_modifier = modifier


# This tooltip will be displayed when the buff is applied to
# a unit and player hovers the mouse over the buff icon.
# Note that this should be plain text, rich text format not
# supported.
func set_buff_tooltip(tooltip: String):
	_tooltip_text = tooltip


# NOTE: buffType.setBuffIcon() in JASS
func set_buff_icon(buff_icon: String):
	_buff_icon = buff_icon


# NOTE: if you don't define a color and bufftype belongs to
# tower, then buff will use the color of the tower element.
func set_buff_icon_color(color: Color):
	_defined_custom_buff_icon_color = true
	_buff_icon_color = color


# NOTE: this f-n is not implemented. With the way tower
# scripts are done in youtd2, it's not possible to implement
# stacking groups in the same way as in original youtd.
# Instead, there's a workaround where buffs are always
# prio'd by caster "tier".
# 
# NOTE: buffType.setStackingGroup() in JASS
# func set_stacking_group(_stacking_group: String):
# 	pass


# NOTE: effects created by this functions will not follow a
# unit. Try to use this only for buffs applied to towers.
# NOTE: buffType.setSpecialEffect() in JASS
func set_special_effect(effect_path: String, z: float, scale: float, color: Color = Color.WHITE, draw_below_unit: bool = false):
	_special_effect_data = SpecialEffect.new()
	_special_effect_data.path = effect_path
	_special_effect_data.z = z
	_special_effect_data.scale = scale
	_special_effect_data.color = color
	_special_effect_data.draw_below_unit = draw_below_unit


# NOTE: if a buff is hidden, it will not be displayed in the
# unit menu. Note that for development purposes, you can
# force hidden buffs to be shown via config.
func set_hidden():
	_is_hidden = true


func set_is_purgable(value: bool):
	_is_purgable = value


#########################
###       Static      ###
#########################

# NOTE: BuffType.createAuraEffectType() in JASS
static func create_aura_effect_type(type: String, friendly: bool, parent: Node) -> BuffType:
	var buff_type: BuffType = BuffType.new(type, 0.0, 0.0, friendly, parent)
	buff_type.set_is_purgable(false)

	return buff_type
