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
# because buff's need to connect to Node's tree_exiting()
# signal for correct "cleanup" event logic.


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


var _type: String
var _stacking_group: String = ""
var _time_base: float
var _time_level_add: float
var _friendly: bool
var _modifier: Modifier = Modifier.new()
var _common_handler_list: Array[CommonHandlerData] = []
var _periodic_handler_list: Array[PeriodicHandlerData] = []
var _range_handler_list: Array[RangeHandlerData] = []
var _aura_type_list: Array[AuraType] = []
var _tooltip_text: String = ""
var _buff_icon: String = ""


# NOTE: BuffType.createAuraEffectType() in JASS
static func create_aura_effect_type(type: String, friendly: bool, parent: Node) -> BuffType:
	var buff_type: BuffType = BuffType.new(type, 0.0, 0.0, friendly, parent)

	return buff_type


# NOTE: type string determines what happens when a buff is
# applied while the target already has active buffs. If buff
# type is empty, then buff will always be applied. If buff
# type is set to something, then buff will be applied only
# if the target doesn't already have an active buff with
# same type. If new buff has higher lever than current
# active buff, then current active buff is upgraded and
# refreshed. In general, set type to something unique.
#
# NOTE: "parent" parameter is needed so that buff can react
# to parent's "tree_exiting()" signal. For example, let's say
# this is a debuff buff type that's created and applied by
# an item to creeps. If that item is removed from the tower,
# we need to remove all debuffs applied by the item. To do
# that we need to connect to parent's (item's) tree_exiting
# signal, not caster's, because caster (tower) has not been
# removed and so won't emit that signal.
func _init(type: String, time_base: float, time_level_add: float, friendly: bool, parent: Node):
	parent.add_child(self)
	_type = type
	_time_base = time_base
	_time_level_add = time_level_add
	_friendly = friendly


func get_type() -> String:
	return _type


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


# Only one buff in a stacking group can be active on a unit.
# Applying a buff with same stacking group on top of another
# buff that is lower level will replace the buff.
# NOTE: buffType.setStackingGroup() in JASS
func set_stacking_group(stacking_group: String):
	_stacking_group = stacking_group


# Base apply function. Overrides time parameters from
# init(). Returns the new buff that was applied or currently
# active buff if it has higher priority due to stacking
# behavior.
#
# NOTE: buffs must be applied after the unit has been added
# to scene tree, after add_child() was called.
# 
# NOTE: buffType.applyAdvanced() in JASS
func apply_advanced(caster: Unit, target: Unit, level: int, power: int, time: float) -> Buff:
	var higher_prio_buff: Buff = _do_stacking_behavior(target, level, power)

	if higher_prio_buff != null:
		return higher_prio_buff

	var buff: Buff = Buff.new()
	buff._caster = caster
	buff._level = level
	buff._power = power
	buff._target = target
	buff._modifier = _modifier
	buff._time = time
	buff._friendly = _friendly
	buff._type = _type
	buff._stacking_group = _stacking_group
	buff._tooltip_text = _tooltip_text
	buff._buff_icon = _buff_icon

	for handler in _common_handler_list:
		buff._add_event_handler(handler.event_type, handler.handler)

	for handler in _periodic_handler_list:
		buff._add_periodic_event(handler.handler, handler.period)

	for handler in _range_handler_list:
		buff._add_event_handler_unit_comes_in_range(handler.handler, handler.radius, handler.target_type)

	for aura_type in _aura_type_list:
		buff._add_aura(aura_type)

	target._add_buff_internal(buff)

	if target.is_dead():
		buff.remove_buff()

	return buff


# NOTE: buffType.applyCustomPower() in JASS
func apply_custom_power(caster: Unit, target: Unit, level: int, power: int) -> Buff:
	var time: float = _time_base + _time_level_add * level

	var buff: Buff = apply_advanced(caster, target, level, power, time)

	return buff


# Base apply function. Overrides time parameters from init().
# 
# NOTE: buffType.applyCustomTimed() in JASS
func apply_custom_timed(caster: Unit, target: Unit, level: int, time: float) -> Buff:
	var buff: Buff = apply_advanced(caster, target, level, level, time)

	return buff


# Apply using time parameters that were defined in init()
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
	buff._purgable = false
	
	return buff


func add_event_handler(event_type: Event.Type, handler: Callable):
	if !handler_object_is_node(handler):
		return

	var data: CommonHandlerData = CommonHandlerData.new()
	data.handler = handler
	data.event_type = event_type

	_common_handler_list.append(data)


# NOTE: buffType.addPeriodicEvent() in JASS
func add_periodic_event(handler: Callable, period: float):
	if !handler_object_is_node(handler):
		return
		
	var data: PeriodicHandlerData = PeriodicHandlerData.new()
	data.handler = handler
	data.period = period

	_periodic_handler_list.append(data)


# NOTE: buffType.addEventOnUnitComesInRange() in JASS
func add_event_on_unit_comes_in_range(handler: Callable, radius: float, target_type: TargetType):
	if !handler_object_is_node(handler):
		return

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


# NOTE: buffType.addEventOnDamage() in JASS
func add_event_on_damage(handler: Callable):
	add_event_handler(Event.Type.DAMAGE, handler)


# NOTE: buffType.addEventOnDamaged() in JASS
func add_event_on_damaged(handler: Callable):
	add_event_handler(Event.Type.DAMAGED, handler)


# NOTE: buffType.setEventOnExpire() in JASS
func set_event_on_expire(handler: Callable):
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


func add_aura(aura_type: AuraType):
	_aura_type_list.append(aura_type)


# TODO: implement. Probably need to display this effect on
# buffed unit while buff is active.
# 
# NOTE: buffType.setSpecialEffectSimple() in JASS
func set_special_effect_simple(_effect: String):
	pass


func handler_object_is_node(handler: Callable) -> bool:
	var handler_node: Node = Utils.get_callable_node(handler)
	var is_node = handler_node != null

	if !is_node:
		push_error("Objects that store buff event handlers must inherit from type Node. Error was caused by this handler: ", handler)

	return is_node


# This f-n will return null if new buff can be applied. It
# returns an active buff if new buff cannot be applied due
# to stacking behavior. In addition, this f-n modifies the
# active buff in certain cases.
# 
# NOTE: tower and item scripts depend on upgrade and
# stacking behavior being implemented in this exact manner.
func _do_stacking_behavior(target: Unit, new_level: int, new_power: int) -> Buff:
	var active_buff_of_type: Buff = target.get_buff_of_type(self)
	var active_buff_of_group: Buff = target.get_buff_of_group(_stacking_group)
	var stacking_by_type: bool = !_type.is_empty() && active_buff_of_type != null
	var stacking_by_group: bool = !_stacking_group.is_empty() && active_buff_of_group != null

	if stacking_by_type:
		var active_level: int = active_buff_of_type.get_level()

		if new_level > active_level:
#			NOTE: upgrade active buff, no new buff
			active_buff_of_type._upgrade_by_new_buff(new_level, new_power)

			return active_buff_of_type
		elif new_level == active_level:
#			NOTE: refresh active buff, no new buff
			active_buff_of_type._refresh_by_new_buff()

			return active_buff_of_type
		elif new_level < active_level:
#			NOTE: keep active buff, no new buff
			return active_buff_of_type
	elif stacking_by_group:
		var active_level: int = active_buff_of_group.get_level()

		if new_level > active_level:
#			NOTE: remove active buff, apply new buff
			active_buff_of_group.remove_buff()

			return null
		elif new_level <= active_level:
#			NOTE: keep active buff, no new buff
			return active_buff_of_group
	else:
#		NOTE: no active buff, apply new buff
		return null
	
	return null
