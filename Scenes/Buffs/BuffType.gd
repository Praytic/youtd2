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

var _type: String
var _stacking_group: String = ""
var _time_base: float
var _time_level_add: float
var _friendly: bool
var _modifier: Modifier = Modifier.new()
var _event_handler_list: Array = []
var _periodic_handler_list: Array = []
var _range_handler_list: Array = []
var _aura_type_list: Array[AuraType] = []
var _tooltip_text: String = ""
var _buff_icon: String = ""


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


func set_buff_modifier(modifier: Modifier):
	_modifier = modifier


# This tooltip will be displayed when the buff is applied to
# a unit and player hovers the mouse over the buff icon.
# Note that this should be plain text, rich text format not
# supported.
func set_buff_tooltip(tooltip: String):
	_tooltip_text = tooltip


func set_buff_icon(buff_icon: String):
	_buff_icon = buff_icon


# Only one buff in a stacking group can be active on a unit.
# Applying a buff with same stacking group on top of another
# buff that is lower level will replace the buff.
func set_stacking_group(stacking_group: String):
	_stacking_group = stacking_group


# Base apply function. Overrides time parameters from
# init(). Returns the new buff that was applied or currently
# active buff if it has higher priority due to stacking
# behavior.
#
# NOTE: buffs must be applied after the unit has been added
# to scene tree, after add_child() was called.
func apply_advanced(caster: Unit, target: Unit, level: int, power: int, time: float) -> Buff:
	var higher_prio_buff: Buff = _do_stacking_behavior(target, level)

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

	for handler in _event_handler_list:
		buff._add_event_handler(handler.event_type, handler.callable)

	for handler in _periodic_handler_list:
		buff._add_periodic_event(handler.callable, handler.period)

	for handler in _range_handler_list:
		buff._add_event_handler_unit_comes_in_range(handler.callable, handler.radius, handler.target_type)

	for aura_type in _aura_type_list:
		buff._add_aura(aura_type)

	target._add_buff_internal(buff)

	return buff


func apply_custom_power(caster: Unit, target: Unit, level: int, power: int) -> Buff:
	var time: float = _time_base + _time_level_add * level

	var buff: Buff = apply_advanced(caster, target, level, power, time)

	return buff


# Base apply function. Overrides time parameters from init().
func apply_custom_timed(caster: Unit, target: Unit, level: int, time: float) -> Buff:
	var buff: Buff = apply_advanced(caster, target, level, level, time)

	return buff


# Apply using time parameters that were defined in init()
func apply(caster: Unit, target: Unit, level: int) -> Buff:
	var time: float = _time_base + _time_level_add * level

	var buff: Buff = apply_custom_timed(caster, target, level, time)

	return buff


# Apply overriding time parameters from init() and without
# specifying level. This is a convenience function
func apply_only_timed(caster: Unit, target: Unit, time: float) -> Buff:
	var buff: Buff = apply_custom_timed(caster, target, 0, time)
	
	return buff


func apply_to_unit_permanent(caster: Unit, target: Unit, level: int) -> Buff:
	var buff: Buff = apply_custom_timed(caster, target, level, -1.0)
	buff._purgable = false
	
	return buff


func add_event_handler(event_type: Event.Type, callable: Callable):
	if !callable_object_is_node(callable):
		return

	_event_handler_list.append({
		event_type = event_type,
		callable = callable,
		})


func add_periodic_event(callable: Callable, period: float):
	if !callable_object_is_node(callable):
		return

	_periodic_handler_list.append({
		callable = callable,
		period = period,
		})


func add_event_handler_unit_comes_in_range(callable: Callable, radius: float, target_type: TargetType):
	if !callable_object_is_node(callable):
		return

	_range_handler_list.append({
		callable = callable,
		radius = radius,
		target_type = target_type
		})


func set_event_on_cleanup(callable: Callable):
	add_event_handler(Event.Type.CLEANUP, callable)


func add_event_on_create(callable: Callable):
	add_event_handler(Event.Type.CREATE, callable)


func add_event_on_upgrade(callable: Callable):
	add_event_handler(Event.Type.UPGRADE, callable)


func add_event_on_refresh(callable: Callable):
	add_event_handler(Event.Type.REFRESH, callable)


func add_event_on_death(callable: Callable):
	add_event_handler(Event.Type.DEATH, callable)


func add_event_on_kill(callable: Callable):
	add_event_handler(Event.Type.KILL, callable)


func add_event_on_level_up(callable: Callable):
	add_event_handler(Event.Type.LEVEL_UP, callable)


func add_event_on_attack(callable: Callable):
	add_event_handler(Event.Type.ATTACK, callable)


func add_event_on_attacked(callable: Callable):
	add_event_handler(Event.Type.ATTACKED, callable)


func add_event_on_damage(callable: Callable):
	add_event_handler(Event.Type.DAMAGE, callable)


func add_event_on_damaged(callable: Callable):
	add_event_handler(Event.Type.DAMAGED, callable)


func set_event_on_expire(callable: Callable):
	add_event_handler(Event.Type.EXPIRE, callable)


func add_event_on_spell_casted(callable: Callable):
	add_event_handler(Event.Type.SPELL_CAST, callable)


func add_event_on_spell_targeted(callable: Callable):
	add_event_handler(Event.Type.SPELL_TARGET, callable)


func add_event_on_purge(callable: Callable):
	add_event_handler(Event.Type.PURGE, callable)


func add_aura(aura_type: AuraType):
	_aura_type_list.append(aura_type)


# TODO: implement. Probably need to display this effect on
# buffed unit while buff is active.
func set_special_effect_simple(_effect: String):
	pass


func callable_object_is_node(callable: Callable) -> bool:
	var callable_node: Node = Utils.get_callable_node(callable)
	var is_node = callable_node != null

	if !is_node:
		push_error("Objects that store buff event handlers must inherit from type Node. Error was caused by this callable: ", callable)

	return is_node


# This f-n will return null if new buff can be applied. It
# returns an active buff if new buff cannot be applied due
# to stacking behavior. In addition, this f-n modifies the
# active buff in certain cases.
# 
# NOTE: tower and item scripts depend on upgrade and
# stacking behavior being implemented in this exact manner.
func _do_stacking_behavior(target: Unit, new_level: int) -> Buff:
	var active_buff_of_type: Buff = target.get_buff_of_type(self)
	var active_buff_of_group: Buff = target.get_buff_of_group(_stacking_group)
	var stacking_by_type: bool = !_type.is_empty() && active_buff_of_type != null
	var stacking_by_group: bool = !_stacking_group.is_empty() && active_buff_of_group != null

	if stacking_by_type:
		var active_level: int = active_buff_of_type.get_level()

		if new_level > active_level:
#			NOTE: upgrade active buff, no new buff
			active_buff_of_type._upgrade_by_new_buff(new_level)

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
