class_name Autocast
extends Node

# Autocast is a special event that is attached to a unit and
# is triggered everytime the unit attacks. Autocast will
# call autocast handler if the autocast is currently not on
# cooldown and the caster has enough mana. The attack target
# is used as the target for the cast. Can be attached to
# towers using Tower.add_autocast() or to buffs using
# Buff.add_autocast().
#
# Defining a target_type will cause autocast to trigger only
# for targets that match the defined type. Set this to null
# if you don't need any filtering.
#
# AC_TYPE_OFFENSIVE_UNIT - performs an autocast when tower
# attacks.
# 
# AC_TYPE_OFFENSIVE_BUFF - while tower is attacking,
# performs an autocast on targets in range that don't
# already have the buff_type. If handler is specified, it
# will be called. If handler is not specified, then buff
# will be applied on the target automatically.
#
# AC_TYPE_ALWAYS_BUFF - same as AC_TYPE_OFFENSIVE_BUFF, but
# casts always, event while tower is not attacking.
#
# AC_TYPE_OFFENSIVE_IMMEDIATE - while tower is attacking,
# performs an autocast without a target. Parameters like
# range and target type are not used.


# TODO: implement AC_TYPE_NOAC_IMMEDIATE. This type doesn't
# trigger automatically. Instead, it's triggered when user
# selects tower and presses the button that triggers this
# autocast.

enum Type {
	AC_TYPE_ALWAYS_BUFF,
	AC_TYPE_ALWAYS_IMMEDIATE,
	AC_TYPE_OFFENSIVE_BUFF,
	AC_TYPE_OFFENSIVE_UNIT,
	AC_TYPE_OFFENSIVE_IMMEDIATE,
	AC_TYPE_NOAC_IMMEDIATE
}

var _immediate_type_list: Array[Autocast.Type] = [
	Autocast.Type.AC_TYPE_ALWAYS_IMMEDIATE,
	Autocast.Type.AC_TYPE_OFFENSIVE_IMMEDIATE,
	Autocast.Type.AC_TYPE_NOAC_IMMEDIATE,
]
var _buff_type_list: Array[Autocast.Type] = [
	Autocast.Type.AC_TYPE_ALWAYS_BUFF,
	Autocast.Type.AC_TYPE_OFFENSIVE_BUFF,
]
var _offensive_type_list: Array[Autocast.Type] = [
	Autocast.Type.AC_TYPE_OFFENSIVE_BUFF,
	Autocast.Type.AC_TYPE_OFFENSIVE_UNIT,
	Autocast.Type.AC_TYPE_OFFENSIVE_IMMEDIATE,
]
var _unit_type_list: Array[Autocast.Type] = [
	Autocast.Type.AC_TYPE_OFFENSIVE_UNIT,
]

# NOTE: num_buffs_before_idle, target_type and buff_type are
# only relevant to "_BUFF" autocast types. For other
# autocast types leave these values blank.

# NOTE: cast_range is the range used when autocast is
# manually triggered by the user, auto_range is the range
# used for regular autocasts that cast automatically.
var description: String = "Description"
var caster_art: String = ""
var cooldown: float = 0.1
# NOTE: in original engine "num_buffs_before_idle"
# determines how many times autocast is triggered before it
# checks whether tower is still in combat. This is needed
# because in original engine checking if tower is still in
# combat takes time. In godot engine, combat check is
# instant so it looks like this value isn't needed.
var num_buffs_before_idle: int = 0
var is_extended: bool = false
var autocast_type: Autocast.Type = Type.AC_TYPE_OFFENSIVE_UNIT
var mana_cost: int = 0
var cast_range: float = 1000
var buff_type: BuffType = null
var target_self: bool = false
var target_type: TargetType = null
var target_art: String = ""
var auto_range: float = 1000
var handler: Callable = Callable()

var _caster: Unit = null
var _is_item_autocast: bool = false

# Tracks how much time is left before ability can be used.
@onready var _cooldown_timer: Timer = $CooldownTimer
# While auto mode is enabled, this timer periodically
# triggers an attempt to cast ability if all requirements
# are met. While auto mode is disabled, this timer is
# paused.
@onready var _auto_timer: Timer = $AutoTimer


static func make() -> Autocast:
	var autocast: Autocast = load("res://Scenes/Towers/Autocast.tscn").instantiate()

	return autocast


func _ready():
	_cooldown_timer.wait_time = cooldown
	_cooldown_timer.one_shot = true

	if !can_use_auto_mode():
		_auto_timer.set_paused(true)


func set_caster(caster: Unit):
	_caster = caster


func toggle_auto_mode():
	if !can_use_auto_mode():
		Messages.add_error("This ability cannot be casted automatically")

		return

	var new_paused_value: bool = !_auto_timer.is_paused()
	_auto_timer.set_paused(new_paused_value)


func auto_mode_is_enabled() -> bool:
	var is_enabled: bool = !_auto_timer.is_paused()

	return is_enabled


func get_cooldown() -> float:
	return cooldown

func get_remaining_cooldown() -> float:
	return _cooldown_timer.time_left

func get_manacost() -> int:
	return mana_cost


func is_item_autocast() -> bool:
	return _is_item_autocast


# This is called when player triggers autocast by pressing
# on the item or autocast button.
func do_cast_manually():
	if !_can_cast():
		_add_cast_error_message()
		
		return

	var target: Unit
	if _type_is_immediate():
		target = null
	elif _type_is_buff():
		target = _get_target_for_buff_autocast()
	elif _type_is_unit():
#		NOTE: for manual cast on unit, need to exit this f-n
#		to select target. The cast will finish when player
#		selects a target and
#		do_cast_manually_finish_for_manual_target() is
#		called.
		SelectTargetForCast.start(self)

		return
	else:
		push_error("do_cast_manually doesn't support this autocast type: ", autocast_type)

		return

	_do_cast(target)


# Returns if cast was successful
func do_cast_manually_finish_for_manual_target(target: Unit) -> bool:
#	NOTE: while player was selecting a target, conditions
#	for cast may have changed. For example tower's mana may
#	have been drained. So we need to check if we can cast
#	again.
	if !_can_cast():
		_add_cast_error_message()

		return false

	_do_cast(target)

	return true


func _on_auto_timer_timeout():
	if !_can_cast():
		return

	var target: Unit = _get_target_for_auto_mode()

# 	NOTE: null target is okay for immediate autocasts
# 	because they do not need a target
	if target == null && !_type_is_immediate():
		return

	_do_cast(target)


func _get_target_for_auto_mode() -> Unit:
	if _type_is_buff():
		return _get_target_for_buff_autocast()
	elif _type_is_unit():
		return _get_target_for_unit_autocast()
	elif _type_is_immediate():
#		Immediate autocasts have no target
		return null
	else:
		return null


func _get_target_for_unit_autocast() -> Unit:
# 	NOTE: use tower's current attack target instead of
# 	searching for nearby units ourselves.
	var target: Unit = _caster.get_current_target()

	var target_is_ok: bool = check_target_for_unit_autocast(target)

	if target_is_ok:
		return target
	else:
		return null


func _get_target_for_buff_autocast() -> Unit:
	var unit_list: Array = Utils.get_units_in_range(target_type, _caster.position, auto_range)
	Utils.sort_unit_list_by_distance(unit_list, _caster.position)

	for unit in unit_list:
		if buff_type == null:
			return unit

		var buff: Buff = unit.get_buff_of_type(buff_type)
		var unit_has_buff: bool = buff != null

		if !unit_has_buff:
			return unit

	return null


# NOTE: target arg may be null if autocast is immediate
func _do_cast(target: Unit):
	_caster.subtract_mana(mana_cost, true)
	_cooldown_timer.start()
	
	if !handler.is_null():
		var autocast_event = Event.new(target)
		handler.call(autocast_event)
	elif buff_type != null:
		buff_type.apply(_caster, target, _caster.get_level())
	else:
		push_error("Incorrect autocast state, handler = %s, buff_type= %s" % [handler, buff_type])

		return

	var spell_casted_event: Event = Event.new(target)
	spell_casted_event._autocast = self
	_caster.spell_casted.emit(spell_casted_event)

	if target != null:
		var spell_targeted_event: Event = Event.new(target)
		spell_targeted_event._autocast = self
		target.spell_targeted.emit(spell_targeted_event)

	if !caster_art.is_empty():
		var effect: int = Effect.create_simple_at_unit(caster_art, _caster)
		Effect.destroy_effect(effect)

	if !target_art.is_empty() && target != null:
		var effect: int = Effect.create_simple_at_unit(target_art, target)
		Effect.destroy_effect(effect)


func _can_cast() -> bool:
	if _caster == null:
		return false

# 	NOTE: if auto mode is off, do not prevent player from
# 	starting a cast while tower is not attacking. For
# 	example, player needs to be able to start the cast to
# 	pick the target before tower starts attacking.
	var cant_cast_because_not_attacking: bool = auto_mode_is_enabled() && _type_is_offensive() && !_caster.is_attacking()

	if cant_cast_because_not_attacking:
		return false

	var on_cooldown: bool = _cooldown_timer.get_time_left() > 0
	var enough_mana: bool = _caster.get_mana() >= mana_cost
	var silenced: bool = _caster.is_silenced()
	var stunned: bool = _caster.is_stunned()
	var can_cast: bool = !on_cooldown && enough_mana && !silenced && !stunned

	return can_cast


func _add_cast_error_message():
	var cast_error: String = _get_cast_error()

	if !cast_error.is_empty():
		Messages.add_error(cast_error)


func _get_cast_error() -> String:
	if _caster == null:
		return ""

	var on_cooldown: bool = _cooldown_timer.get_time_left() > 0
	var enough_mana: bool = _caster.get_mana() >= mana_cost
	var silenced: bool = _caster.is_silenced()
	var stunned: bool = _caster.is_stunned()

	if on_cooldown:
		return "This ability is not ready yet"
	elif !enough_mana:
		return "Not enough mana"
	elif silenced:
		return "Can't cast ability because caster is silenced"
	elif stunned:
		return "Can't cast ability because caster is stunned"
	else:
		return ""


# Some autocast types are always manual
func can_use_auto_mode() -> bool:
	var types_that_can_use_auto_mode: Array[Autocast.Type] = [
		Autocast.Type.AC_TYPE_ALWAYS_BUFF,
		Autocast.Type.AC_TYPE_ALWAYS_IMMEDIATE,
		Autocast.Type.AC_TYPE_OFFENSIVE_BUFF,
		Autocast.Type.AC_TYPE_OFFENSIVE_UNIT,
		Autocast.Type.AC_TYPE_OFFENSIVE_IMMEDIATE,
	]

	var can_use: bool = types_that_can_use_auto_mode.has(autocast_type)

	return can_use


func _type_is_immediate() -> bool:
	return _immediate_type_list.has(autocast_type)


func _type_is_buff() -> bool:
	return _buff_type_list.has(autocast_type)


func _type_is_offensive() -> bool:
	return _offensive_type_list.has(autocast_type)


func _type_is_unit() -> bool:
	return _unit_type_list.has(autocast_type)


func check_target_for_unit_autocast(target: Unit) -> bool:
	if target == null:
		return false

# 	NOTE: caster may have higher attack range than autocast
# 	so we need to check that target is in range of autocast
	var distance_to_target: float = Isometric.vector_distance_to(target.position, _caster.position)
	var target_is_in_range: bool = distance_to_target <= auto_range

	if !target_is_in_range:
		return false

#	NOTE: only creep targets are allowed for unit type
#	autocasts
	var creep_target_type: TargetType = TargetType.new(TargetType.CREEPS)

	if !creep_target_type.match(target):
		return false

	return true
