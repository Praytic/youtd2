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

# TODO: EventType.CLEANUP is currently fired when buff is
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

enum EventType {
	CLEANUP,
	CREATE,
	DEATH,
	KILL,
	LEVEL_UP,
	ATTACK,
	ATTACKED,
	DAMAGE,
	DAMAGED,
	EXPIRE,
}


class EventHandler:
	var object: Node
	var handler_function: String


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
var _time_base: float
var _time_level_add: float
var _friendly: bool
var _type: String
# Map of EventType -> list of EventHandler's
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
func apply_custom_timed(caster: Unit, target: Unit, level: int, time: float):
	_caster = caster
	_level = level

# 	Don't do any override logic for buffs with empty type
# 	and allow stacking multiple instances of same type.
	var need_override_logic: bool = !get_type().empty()

	if need_override_logic:
		var can_apply: bool = _check_can_apply_to_unit(target)

		if !can_apply:
			return

		var active_buff = target.get_buff_of_type(get_type())

		if active_buff != null:
			active_buff.expire()

	_target = target
	_target._add_buff_internal(self)
	_target.connect("death", self, "_on_target_death")
	_target.connect("kill", self, "_on_target_kill")
	_target.connect("level_up", self, "_on_target_level_up")
	_target.connect("attack", self, "_on_target_attack")
	_target.connect("attacked", self, "_on_target_attacked")
	_target.connect("damage", self, "_on_target_damage")
	_target.connect("damaged", self, "_on_target_damaged")

	if time > 0.0:
		var timer: Timer = Timer.new()
		add_child(timer)
		timer.connect("timeout", self, "_on_timer_timeout")

		var buff_duration_mod: float = _caster.get_buff_duration_mod()
		var debuff_duration_mod: float = _target.get_debuff_duration_mod()
		if _friendly:
			debuff_duration_mod = 0.0

		var total_time: float = time * (1.0 + buff_duration_mod) * (1.0 + debuff_duration_mod)
		timer.start(total_time)

	var create_event: Event = _make_buff_event(_target, 0, true)
	_call_event_handler_list(EventType.CREATE, create_event)


# Apply using time parameters that were defined in init()
func apply(caster: Unit, target: Unit, level: int):
	var time: float = _time_base + _time_level_add * _level

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


func get_level() -> int:
	return _level


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


func add_event_handler(event_type: int, handler_object: Node, handler_function: String):
	if !_check_handler_exists(handler_object, handler_function):
		return

	var handler: EventHandler = EventHandler.new()
	handler.object = handler_object
	handler.handler_function = handler_function

	_add_event_handler_internal(event_type, handler)


func add_event_handler_periodic(handler_object: Node, handler_function: String, period: float):
	if !_check_handler_exists(handler_object, handler_function):
		return

	var timer: Timer = Timer.new()
	add_child(timer)
	timer.wait_time = period
	timer.one_shot = false
	timer.autostart = true
	timer.connect("timeout", self, "_on_periodic_event_timer_timeout", [handler_object, handler_function, timer])


func add_event_handler_unit_comes_in_range(handler_object: Node, handler_function: String, radius: float, target_type: TargetType):
	if !_check_handler_exists(handler_object, handler_function):
		return

	var buff_range_area_scene: PackedScene = load("res://Scenes/Buffs/BuffRangeArea.tscn")
	var buff_range_area = buff_range_area_scene.instance()
#	NOTE: use call_deferred() adding child immediately causes an error about
# 	setting shape during query flushing
	call_deferred("add_child", buff_range_area)
	buff_range_area.init(radius, target_type, handler_object, handler_function)

	buff_range_area.connect("unit_came_in_range", self, "_on_unit_came_in_range")


func add_autocast(autocast_data: Autocast.Data, handler_object, handler_function: String) -> Autocast:
	var autocast_scene = load("res://Scenes/Towers/Autocast.tscn").instance()
	autocast_scene.set_data(autocast_data, handler_object, handler_function)
	add_child(autocast_scene)

	return autocast_scene


func add_event_on_cleanup(handler_object: Node, handler_function: String):
	add_event_handler(EventType.CLEANUP, handler_object, handler_function)


func add_event_on_create(handler_object: Node, handler_function: String):
	add_event_handler(EventType.CREATE, handler_object, handler_function)


func add_event_on_death(handler_object: Node, handler_function: String):
	add_event_handler(EventType.DEATH, handler_object, handler_function)


func add_event_on_kill(handler_object: Node, handler_function: String):
	add_event_handler(EventType.KILL, handler_object, handler_function)


func add_event_on_level_up(handler_object: Node, handler_function: String):
	add_event_handler(EventType.LEVEL_UP, handler_object, handler_function)


func add_event_on_attack(handler_object: Node, handler_function: String):
	add_event_handler(EventType.ATTACK, handler_object, handler_function)


func add_event_on_attacked(handler_object: Node, handler_function: String):
	add_event_handler(EventType.ATTACKED, handler_object, handler_function)


func add_event_on_damage(handler_object: Node, handler_function: String):
	add_event_handler(EventType.DAMAGE, handler_object, handler_function)


func add_event_on_damaged(handler_object: Node, handler_function: String):
	add_event_handler(EventType.DAMAGED, handler_object, handler_function)


func add_event_on_expired(handler_object: Node, handler_function: String):
	add_event_handler(EventType.EXPIRED, handler_object, handler_function)


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
		handler.object.call(handler.handler_function, event)


func _on_timer_timeout():
	var cleanup_event: Event = _make_buff_event(_target, 0, true)
	_call_event_handler_list(EventType.CLEANUP, cleanup_event)

	emit_signal("removed")

	var expire_event: Event = _make_buff_event(_target, 0, true)
	_call_event_handler_list(EventType.EXPIRE, expire_event)


func _on_target_death(event: Event):
	_call_event_handler_list(EventType.DEATH, event)
	_call_event_handler_list(EventType.CLEANUP, event)


func _on_target_kill(event: Event):
	_call_event_handler_list(EventType.KILL, event)


func _on_target_level_up():
	var level_up_event: Event = _make_buff_event(_target, 0, true)
	_call_event_handler_list(EventType.LEVEL_UP, level_up_event)


func _on_target_attack(event: Event):
	_call_event_handler_list(EventType.ATTACK, event)


func _on_target_attacked(event: Event):
	_call_event_handler_list(EventType.ATTACKED, event)


func _on_target_damage(event: Event):
	_call_event_handler_list(EventType.DAMAGE, event)


func _on_target_damaged(event: Event):
	_call_event_handler_list(EventType.DAMAGED, event)


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
