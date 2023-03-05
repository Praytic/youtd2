class_name Buff
extends Node2D


# Buff stores buff parameters and applies them to target
# while it is active. Define custom buffs by creating a
# subclass.
# 
# Buffs can have event handlers. To add an event handler,
# define a handler function in your subclass and call the
# appropriate add_event_handler function. All handler
# functions are called with one parameter Event which passes
# information about the event.

# TODO: what is friendly used for? It's not used as sign
# multiplier on value (confirmed by original tower scripts).
# Maybe used for stacking behavior?

# TODO: Event.Type.CLEANUP is currently fired when buff is
# overriden. Need to figure out how cleanup works together
# with REFRESH and UPGRADED event types. If a buff is
# refreshed, should both CLEANUP and REFRESH fire or just
# REFRESH? If so, then refresh needs to reuse current buff
# instance instead of current behavior which is replacing
# with new instance.

# TODO: implement the following event types
# SPELL_CAST
# SPELL_TARGET
# UPGRADE
# REFRESH
# PURGED

# NOTE: this signal is separate from the EXPIRE event type
# and used by Unit to undo buff modifiers. Do not use this
# in Tower scripts. Use EXPIRE event handler.
signal removed()


class EventHandler:
	var object: Node
	var handler_function: String
	var chance: float
	var chance_level_add: float


var user_int: int = 0
var user_int2: int = 0
var user_int3: int = 0
var user_real: float = 0.0
var user_real2: float = 0.0
var user_real3: float = 0.0

var _caster: Unit
var _target: Unit
var _modifier: Modifier = Modifier.new()
var _level: int
var _power: int
var _time_base: float
var _time_level_add: float
var _friendly: bool
var _type: String
# Map of Event.Type -> list of EventHandler's
var event_handler_map: Dictionary = {}


# NOTE: type is used for override logic. Only one buff of a
# type can be active on a unit at any given time and when a
# buff of a type is applied to a unit while it already has
# an active buff of a type, there's override logic for which
# buff will remain on the unit.
# 
# Pass empty string if override logic doesn't matter for
# your buff and multiple active instances of the buff on one
# unit are allowed. For example, buffs that are used solely
# to add event handlers should have empty type.
func _init(type: String, time_base: float, time_level_add: float, friendly: bool):
	_type = type
	_time_base = time_base
	_time_level_add = time_level_add
	_friendly = friendly


# Base apply function. Overrides time parameters from init().
func apply_advanced(caster: Unit, target: Unit, level: int, power: int, time: float):
	_caster = caster
	_level = level
	_power = power

# 	Don't do any override logic for buffs with empty type
# 	and allow stacking multiple instances of same type.
	var need_override_logic: bool = !get_type().is_empty()

	if need_override_logic:
		var can_apply: bool = _check_can_apply_to_unit(target)

		if !can_apply:
			return

		var active_buff = target.get_buff_of_type(get_type())

		if active_buff != null:
			active_buff.expire()

	_target = target
	_target._add_buff_internal(self)
	_target.connect("death",Callable(self,"_on_target_death"))
	_target.connect("kill",Callable(self,"_on_target_kill"))
	_target.connect("level_up",Callable(self,"_on_target_level_up"))
	_target.connect("attack",Callable(self,"_on_target_attack"))
	_target.connect("attacked",Callable(self,"_on_target_attacked"))
	_target.connect("damage",Callable(self,"_on_target_damage"))
	_target.connect("damaged",Callable(self,"_on_target_damaged"))

	if time > 0.0:
		var timer: Timer = Timer.new()
		add_child(timer)
		timer.connect("timeout",Callable(self,"_on_timer_timeout"))

		var buff_duration_mod: float = _caster.get_prop_buff_duration()
		var debuff_duration_mod: float = _target.get_prop_debuff_duration()
		if _friendly:
			debuff_duration_mod = 0.0

		var total_time: float = time * buff_duration_mod * debuff_duration_mod
		timer.start(total_time)

	var create_event: Event = _make_buff_event(_target, 0, true)
	_call_event_handler_list(Event.Type.CREATE, create_event)


func apply_custom_power(caster: Unit, target: Unit, level: int, power: int):
	var time: float = _time_base + _time_level_add * _power

	apply_advanced(caster, target, level, power, time)


# Base apply function. Overrides time parameters from init().
func apply_custom_timed(caster: Unit, target: Unit, level: int, time: float):
	apply_advanced(caster, target, level, level, time)


# Apply using time parameters that were defined in init()
func apply(caster: Unit, target: Unit, level: int):
	var time: float = _time_base + _time_level_add * _power

	apply_custom_timed(caster, target, level, time)


# Apply overriding time parameters from init() and without
# specifying level. This is a convenience function
func apply_only_timed(caster: Unit, target: Unit, time: float):
	apply_custom_timed(caster, target, 0, time)


func apply_to_unit_permanent(caster: Unit, target: Unit, level: int):
	apply_custom_timed(caster, target, level, -1.0)


func set_buff_modifier(modifier: Modifier):
	_modifier = modifier


# TODO: implement
func set_buff_icon(_buff_icon: String):
	pass


# TODO: implement
func set_stacking_group(_stacking_group: String):
	pass


func get_modifier() -> Modifier:
	return _modifier


# Level is used to compare this buff with another buff of
# same type that is active on target and determine which
# buff is stronger. Stronger buff will end up remaining
# active on the target.
func get_level() -> int:
	return _level


# Power level is used to calculate the total time and total
# value of modifiers.
func get_power() -> int:
	return _power


func set_type(type: String):
	_type = type


func get_type() -> String:
	return _type


func get_caster() -> Unit:
	return _caster


func get_buffed_unit() -> Unit:
	return _target


func expire():
	_on_timer_timeout()


func add_event_handler(event_type: int, handler_object: Node, handler_function: String, chance: float, chance_level_add: float):
	if !_check_handler_exists(handler_object, handler_function):
		return

	var handler: EventHandler = EventHandler.new()
	handler.object = handler_object
	handler.handler_function = handler_function
	handler.chance = chance
	handler.chance_level_add = chance_level_add

	_add_event_handler_internal(event_type, handler)


func add_periodic_event(handler_object: Node, handler_function: String, period: float):
	if !_check_handler_exists(handler_object, handler_function):
		return

	var timer: Timer = Timer.new()
	add_child(timer)
	timer.wait_time = period
	timer.one_shot = false
	timer.autostart = true
	timer.connect("timeout",Callable(self,"_on_periodic_event_timer_timeout").bind(handler_object, handler_function, timer))


func add_event_handler_unit_comes_in_range(handler_object: Node, handler_function: String, radius: float, target_type: TargetType):
	if !_check_handler_exists(handler_object, handler_function):
		return

	var buff_range_area_scene: PackedScene = load("res://Scenes/Buffs/BuffRangeArea.tscn")
	var buff_range_area = buff_range_area_scene.instantiate()
#	NOTE: use call_deferred() adding child immediately causes an error about
# 	setting shape during query flushing
	call_deferred("add_child", buff_range_area)
	buff_range_area.init(radius, target_type, handler_object, handler_function)

	buff_range_area.connect("unit_came_in_range",Callable(self,"_on_unit_came_in_range"))


func add_autocast(autocast_data: Autocast.Data, handler_object, handler_function: String) -> Autocast:
	var autocast_scene = load("res://Scenes/Towers/Autocast.tscn").instantiate()
	autocast_scene.set_data(autocast_data, handler_object, handler_function)
	add_child(autocast_scene)

	return autocast_scene


func set_event_on_cleanup(handler_object: Node, handler_function: String):
	add_event_handler(Event.Type.CLEANUP, handler_object, handler_function, 1.0, 0.0)


func add_event_on_create(handler_object: Node, handler_function: String):
	add_event_handler(Event.Type.CREATE, handler_object, handler_function, 1.0, 0.0)


func add_event_on_death(handler_object: Node, handler_function: String):
	add_event_handler(Event.Type.DEATH, handler_object, handler_function, 1.0, 0.0)


func add_event_on_kill(handler_object: Node, handler_function: String):
	add_event_handler(Event.Type.KILL, handler_object, handler_function, 1.0, 0.0)


func add_event_on_level_up(handler_object: Node, handler_function: String):
	add_event_handler(Event.Type.LEVEL_UP, handler_object, handler_function, 1.0, 0.0)


func add_event_on_attack(handler_object: Node, handler_function: String, chance: float, chance_level_add: float):
	add_event_handler(Event.Type.ATTACK, handler_object, handler_function, chance, chance_level_add)


func add_event_on_attacked(handler_object: Node, handler_function: String, chance: float, chance_level_add: float):
	add_event_handler(Event.Type.ATTACKED, handler_object, handler_function, chance, chance_level_add)


func add_event_on_damage(handler_object: Node, handler_function: String, chance: float, chance_level_add: float):
	add_event_handler(Event.Type.DAMAGE, handler_object, handler_function, chance, chance_level_add)


func add_event_on_damaged(handler_object: Node, handler_function: String, chance: float, chance_level_add: float):
	add_event_handler(Event.Type.DAMAGED, handler_object, handler_function, chance, chance_level_add)


func add_event_on_expire(handler_object: Node, handler_function: String):
	add_event_handler(Event.Type.EXPIRE, handler_object, handler_function, 1.0, 0.0)


func _on_unit_came_in_range(handler_object: Node, handler_function: String, unit: Unit):
	var range_event: Event = _make_buff_event(unit, 0, true)

	handler_object.call(handler_function, range_event)


func _add_event_handler_internal(event_type: int, handler: EventHandler):
	if !event_handler_map.has(event_type):
		event_handler_map[event_type] = []

	event_handler_map[event_type].append(handler)


func _call_event_handler_list(event_type: int, event: Event):
	if !event_handler_map.has(event_type):
		return

	event._buff = self

	var handler_list: Array = event_handler_map[event_type]

	for handler in handler_list:
		var caster_level: int = _caster.get_level()
		var total_chance: float = handler.chance + handler.chance_level_add * (1 - caster_level)
		var chance_success: bool = _caster.calc_chance(total_chance)

		if !chance_success:
			continue

		handler.object.call(handler.handler_function, event)


func _on_timer_timeout():
	var cleanup_event: Event = _make_buff_event(_target, 0, true)
	_call_event_handler_list(Event.Type.CLEANUP, cleanup_event)

	emit_signal("removed")

	var expire_event: Event = _make_buff_event(_target, 0, true)
	_call_event_handler_list(Event.Type.EXPIRE, expire_event)


func _on_target_death(event: Event):
	_call_event_handler_list(Event.Type.DEATH, event)
	_call_event_handler_list(Event.Type.CLEANUP, event)


func _on_target_kill(event: Event):
	_call_event_handler_list(Event.Type.KILL, event)


func _on_target_level_up():
	var level_up_event: Event = _make_buff_event(_target, 0, true)
	_call_event_handler_list(Event.Type.LEVEL_UP, level_up_event)


func _on_target_attack(event: Event):
	_call_event_handler_list(Event.Type.ATTACK, event)


func _on_target_attacked(event: Event):
	_call_event_handler_list(Event.Type.ATTACKED, event)


func _on_target_damage(event: Event):
	_call_event_handler_list(Event.Type.DAMAGE, event)


func _on_target_damaged(event: Event):
	_call_event_handler_list(Event.Type.DAMAGED, event)


func _on_periodic_event_timer_timeout(handler_object: Node, handler_function: String, timer: Timer):
	var periodic_event: Event = _make_buff_event(_target, 0, true)
	periodic_event._timer = timer
	handler_object.call(handler_function, periodic_event)


func _check_handler_exists(handler_object: Node, handler_function: String) -> bool:
	var exists: bool = handler_object.has_method(handler_function)

	if !exists:
		print_debug("Attempted to register an event handler that doesn't exist: ", handler_function)

	return exists


# Convenience function to make an event with "_buff" variable set to self
func _make_buff_event(target_arg: Unit, damage_arg: float, is_main_target_arg: bool) -> Event:
	var event: Event = Event.new(target_arg, damage_arg, is_main_target_arg)
	event._buff = self

	return event


func _check_can_apply_to_unit(unit: Unit) -> bool:
	var active_buff = unit.get_buff_of_type(get_type())

	if active_buff != null:
		var should_override: bool = get_level() >= active_buff.get_level()

		if should_override:
			return true
		else:
			return false
	else:
		return true
