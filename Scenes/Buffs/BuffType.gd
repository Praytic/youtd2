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
# event handler for Buffs.

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


static func create_aura_effect_type(type: String, friendly: bool) -> BuffType:
	var buff_type: BuffType = BuffType.new(type, 0.0, 0.0, friendly)

	return buff_type


func _init(type: String, time_base: float, time_level_add: float, friendly: bool):
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
# init(). Returns the buff that was applied or currently
# active buff if it was refreshed, upgraded or rejected due to stacking.
func apply_advanced(caster: Unit, target: Unit, level: int, power: int, time: float) -> Buff:
# 	NOTE: original tower scripts depend on upgrade and
# 	stacking behavior being implemented in this exact manner
	var active_buff_of_type: Buff = target.get_buff_of_type(self)
	var active_buff_of_group: Buff = target.get_buff_of_group(_stacking_group)
	
	if !_type.is_empty() && active_buff_of_type != null:
		var active_level: int = active_buff_of_type.get_level()

		if level >= active_level:
			active_buff_of_type._upgrade_or_refresh(level)
#			NOTE: new buff is rejected

			return active_buff_of_type
	elif !_stacking_group.is_empty() && active_buff_of_group != null:
		var active_level: int = active_buff_of_group.get_level()

		if level > active_level:
			active_buff_of_group.remove_buff()
		else:
#			NOTE: new buff is rejected

			return active_buff_of_group

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
		buff._add_event_handler(handler.event_type, handler.callable, handler.chance, handler.chance_level_add)

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
	
	return buff


func add_event_handler(event_type: Event.Type, callable: Callable, chance: float, chance_level_add: float):
	if !callable_object_is_node(callable):
		return

	_event_handler_list.append({
		event_type = event_type,
		callable = callable,
		chance = chance,
		chance_level_add = chance_level_add,
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
	add_event_handler(Event.Type.CLEANUP, callable, 1.0, 0.0)


func add_event_on_create(callable: Callable):
	add_event_handler(Event.Type.CREATE, callable, 1.0, 0.0)


func add_event_on_upgrade(callable: Callable):
	add_event_handler(Event.Type.UPGRADE, callable, 1.0, 0.0)


func add_event_on_refresh(callable: Callable):
	add_event_handler(Event.Type.REFRESH, callable, 1.0, 0.0)


func add_event_on_death(callable: Callable):
	add_event_handler(Event.Type.DEATH, callable, 1.0, 0.0)


func add_event_on_kill(callable: Callable):
	add_event_handler(Event.Type.KILL, callable, 1.0, 0.0)


func add_event_on_level_up(callable: Callable):
	add_event_handler(Event.Type.LEVEL_UP, callable, 1.0, 0.0)


func add_event_on_attack(callable: Callable, chance: float, chance_level_add: float):
	add_event_handler(Event.Type.ATTACK, callable, chance, chance_level_add)


func add_event_on_attacked(callable: Callable, chance: float, chance_level_add: float):
	add_event_handler(Event.Type.ATTACKED, callable, chance, chance_level_add)


func add_event_on_damage(callable: Callable, chance: float, chance_level_add: float):
	add_event_handler(Event.Type.DAMAGE, callable, chance, chance_level_add)


func add_event_on_damaged(callable: Callable, chance: float, chance_level_add: float):
	add_event_handler(Event.Type.DAMAGED, callable, chance, chance_level_add)


func add_event_on_expire(callable: Callable):
	add_event_handler(Event.Type.EXPIRE, callable, 1.0, 0.0)


func add_event_on_spell_casted(callable: Callable):
	add_event_handler(Event.Type.SPELL_CAST, callable, 1.0, 0.0)


func add_event_on_spell_targeted(callable: Callable):
	add_event_handler(Event.Type.SPELL_TARGET, callable, 1.0, 0.0)


func add_event_on_purge(callable: Callable):
	add_event_handler(Event.Type.PURGE, callable, 1.0, 0.0)


func add_aura(aura_type: AuraType):
	_aura_type_list.append(aura_type)


# TODO: implement. Probably need to display this effect on
# buffed unit while buff is active.
func set_special_effect_simple(_effect: String):
	pass


func callable_object_is_node(callable: Callable) -> bool:
	var callable_object: Object = callable.get_object()
	var callable_node: Node = callable_object as Node
	var callable_object_is_node = callable_node != null

	if !callable_object_is_node:
		push_error("Objects that store buff event handlers must inherit from type Node. Error was caused by this callable: ", callable)

	return callable_object_is_node
