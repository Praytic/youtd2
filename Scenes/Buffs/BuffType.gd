class_name BuffType


# BuffType stores buff parameters and can be used to create
# buff instances. It's possible to define a custom BuffType
# by subclassing.
# 
# Buffs can have event handlers. To add an event handler,
# define a handler function in your subclass and call the
# appropriate add_event_handler function. All handler
# functions are called with one parameter Event which passes
# information about the event.

var _type: String
var _time_base: float
var _time_level_add: float
var _friendly: bool
var _modifier: Modifier = Modifier.new()
var _event_handler_list: Array = []
var _periodic_handler_list: Array = []
var _range_handler_list: Array = []
var _aura_type_list: Array[AuraType] = []


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


# TODO: implement
func set_buff_icon(_buff_icon: String):
	pass


# TODO: implement
func set_stacking_group(_stacking_group: String):
	pass


# Base apply function. Overrides time parameters from
# init(). Returns the buff that was applied or currently
# active buff if it was refreshed or upgraded.
func apply_advanced(caster: Unit, target: Unit, level: int, power: int, time: float) -> Buff:
	var need_upgrade_logic: bool = !_type.is_empty()

# 	NOTE: original tower scripts depend on upgrade behavior
# 	being implemented in this exact manner
	if need_upgrade_logic:
		var active_buff = target.get_buff_of_type(self)
		
		if active_buff != null:
			var active_level: int = active_buff.get_level()

			if level >= active_level:
				active_buff._upgrade_or_refresh(level)

				return active_buff

	var buff: Buff = Buff.new()
	buff._caster = caster
	buff._level = level
	buff._power = power
	buff._target = target
	buff._modifier = _modifier
	buff._time = time
	buff._friendly = _friendly
	buff._type = _type

	for handler in _event_handler_list:
		buff._add_event_handler(handler.event_type, handler.handler_object, handler.handler_function, handler.chance, handler.chance_level_add)

	for handler in _periodic_handler_list:
		buff._add_periodic_event(handler.handler_object, handler.handler_function, handler.period)

	for handler in _range_handler_list:
		buff._add_event_handler_unit_comes_in_range(handler.handler_object, handler.handler_function, handler.radius, handler.target_type)

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


func add_event_handler(event_type: Event.Type, handler_object: Object, handler_function: String, chance: float, chance_level_add: float):
	if !_check_handler_exists(handler_object, handler_function):
		return

	_event_handler_list.append({
		event_type = event_type,
		handler_object = handler_object,
		handler_function = handler_function,
		chance = chance,
		chance_level_add = chance_level_add,
		})


func add_periodic_event(handler_object: Object, handler_function: String, period: float):
	if !_check_handler_exists(handler_object, handler_function):
		return

	_periodic_handler_list.append({
		handler_object = handler_object,
		handler_function = handler_function,
		period = period,
		})


func add_event_handler_unit_comes_in_range(handler_object: Object, handler_function: String, radius: float, target_type: TargetType):
	if !_check_handler_exists(handler_object, handler_function):
		return

	_range_handler_list.append({
		handler_object = handler_object,
		handler_function = handler_function,
		radius = radius,
		target_type = target_type,
		})


func set_event_on_cleanup(handler_object: Object, handler_function: String):
	add_event_handler(Event.Type.CLEANUP, handler_object, handler_function, 1.0, 0.0)


func add_event_on_create(handler_object: Object, handler_function: String):
	add_event_handler(Event.Type.CREATE, handler_object, handler_function, 1.0, 0.0)


func add_event_on_upgrade(handler_object: Object, handler_function: String):
	add_event_handler(Event.Type.UPGRADE, handler_object, handler_function, 1.0, 0.0)


func add_event_on_refresh(handler_object: Object, handler_function: String):
	add_event_handler(Event.Type.REFRESH, handler_object, handler_function, 1.0, 0.0)


func add_event_on_death(handler_object: Object, handler_function: String):
	add_event_handler(Event.Type.DEATH, handler_object, handler_function, 1.0, 0.0)


func add_event_on_kill(handler_object: Object, handler_function: String):
	add_event_handler(Event.Type.KILL, handler_object, handler_function, 1.0, 0.0)


func add_event_on_level_up(handler_object: Object, handler_function: String):
	add_event_handler(Event.Type.LEVEL_UP, handler_object, handler_function, 1.0, 0.0)


func add_event_on_attack(handler_object: Object, handler_function: String, chance: float, chance_level_add: float):
	add_event_handler(Event.Type.ATTACK, handler_object, handler_function, chance, chance_level_add)


func add_event_on_attacked(handler_object: Object, handler_function: String, chance: float, chance_level_add: float):
	add_event_handler(Event.Type.ATTACKED, handler_object, handler_function, chance, chance_level_add)


func add_event_on_damage(handler_object: Object, handler_function: String, chance: float, chance_level_add: float):
	add_event_handler(Event.Type.DAMAGE, handler_object, handler_function, chance, chance_level_add)


func add_event_on_damaged(handler_object: Object, handler_function: String, chance: float, chance_level_add: float):
	add_event_handler(Event.Type.DAMAGED, handler_object, handler_function, chance, chance_level_add)


func add_event_on_expire(handler_object: Object, handler_function: String):
	add_event_handler(Event.Type.EXPIRE, handler_object, handler_function, 1.0, 0.0)


func add_event_on_spell_casted(handler_object: Object, handler_function: String):
	add_event_handler(Event.Type.SPELL_CAST, handler_object, handler_function, 1.0, 0.0)


func add_event_on_spell_targeted(handler_object: Object, handler_function: String):
	add_event_handler(Event.Type.SPELL_TARGET, handler_object, handler_function, 1.0, 0.0)


func add_event_on_purge(handler_object: Object, handler_function: String):
	add_event_handler(Event.Type.PURGE, handler_object, handler_function, 1.0, 0.0)


func add_aura(aura_type: AuraType):
	_aura_type_list.append(aura_type)


# TODO: implement. Probably need to display this effect on
# buffed unit while buff is active.
func set_special_effect_simple(_effect: String):
	pass


func _check_handler_exists(handler_object: Object, handler_function: String) -> bool:
	var exists: bool = handler_object.has_method(handler_function)

	if !exists:
		print_debug("Attempted to register an event handler that doesn't exist: ", handler_function)

	return exists
