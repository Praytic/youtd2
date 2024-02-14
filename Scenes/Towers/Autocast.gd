class_name Autocast
extends Node

# Autocast is attached to a unit and triggers an ability.
# Can be attached using Tower.add_autocast(),
# Buff.add_autocast() or Item.set_autocast().
#
# Note that autocast doesn't implement the gameplay effects
# of the ability like dealing damage. That needs to be
# implemented in the autocast handler. The only gameplay
# effect that some autocasts do is applying buffs on units.
#
# Autocast type determines the way that the autocast
# behaves. See below for descriptions of autocast types.
#
# AC_TYPE_ALWAYS_BUFF - applies a buff on targets in range
# that don't already have the buff_type. Note that if a
# handler is specified, then it will be called and buff
# should be applied by the handler.
#
# AC_TYPE_ALWAYS_IMMEDIATE - calls the defined handler.
# Ability effects should be implemented by the handler.
#
# AC_TYPE_OFFENSIVE_BUFF - same as AC_TYPE_ALWAYS_BUFF, but
# is active only while tower is attacking.
#
# AC_TYPE_OFFENSIVE_UNIT - calls handler and passes current
# attack target of caster via the event argument.
#
# AC_TYPE_OFFENSIVE_IMMEDIATE - same as
# AC_TYPE_ALWAYS_IMMEDIATE but is active only while tower is
# active.
#
# AC_TYPE_NOAC_IMMEDIATE - same as AC_TYPE_ALWAYS_IMMEDIATE
# but is always in manual mode.
#
# AC_TYPE_NOAC_CREEP - same as AC_TYPE_OFFENSIVE_UNIT but is
# always in manual mode.
# 
# AC_TYPE_NOAC_TOWER - same as AC_TYPE_NOAC_CREEP but
# accepts only tower targets.
#
# AC_TYPE_NOAC_PLAYER_TOWER - same as AC_TYPE_NOAC_TOWER but
# accepts only player tower targets.
# 
# See _types_that_can_use_auto_mode list for information
# about which autocast types can use auto mode. Types not in
# the list are always in manual mode.


enum Type {
	AC_TYPE_ALWAYS_BUFF,
	AC_TYPE_ALWAYS_IMMEDIATE,
	AC_TYPE_OFFENSIVE_BUFF,
	AC_TYPE_OFFENSIVE_UNIT,
	AC_TYPE_OFFENSIVE_IMMEDIATE,
	AC_TYPE_OFFENSIVE_POINT,
	AC_TYPE_NOAC_IMMEDIATE,
	AC_TYPE_NOAC_CREEP,
	AC_TYPE_NOAC_TOWER,
	AC_TYPE_NOAC_PLAYER_TOWER,
	AC_TYPE_NOAC_POINT,
}


var _types_that_can_use_auto_mode: Array[Autocast.Type] = [
	Autocast.Type.AC_TYPE_ALWAYS_BUFF,
	Autocast.Type.AC_TYPE_ALWAYS_IMMEDIATE,
	Autocast.Type.AC_TYPE_OFFENSIVE_BUFF,
	Autocast.Type.AC_TYPE_OFFENSIVE_UNIT,
	Autocast.Type.AC_TYPE_OFFENSIVE_IMMEDIATE,
]
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
	Autocast.Type.AC_TYPE_OFFENSIVE_POINT,
]
var _unit_type_list: Array[Autocast.Type] = [
	Autocast.Type.AC_TYPE_OFFENSIVE_UNIT,
]
var _point_type_list: Array[Autocast.Type] = [
	Autocast.Type.AC_TYPE_OFFENSIVE_POINT,
	Autocast.Type.AC_TYPE_NOAC_POINT,
]

# NOTE: num_buffs_before_idle, target_type and buff_type are
# only relevant to "_BUFF" autocast types. For other
# autocast types leave these values blank.

# NOTE: cast_range is the range used when autocast is
# manually triggered by the user, auto_range is the range
# used for regular autocasts that cast automatically.
var title: String = "Placeholder Title"
var description: String = "Description"
var description_short: String = "Description Short"
var icon: String = "res://Resources/Textures/UI/Icons/gold_icon.tres"
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
var item_owner: Item = null
var dont_cast_at_zero_charges: bool = false
# NOTE: only used for POINT type autocasts
var _target_pos: Vector2 = Vector2.ZERO

var _caster: Unit = null
var _is_item_autocast: bool = false

# Tracks how much time is left before ability can be used.
@export var _cooldown_timer: Timer
# While auto mode is enabled, this timer periodically
# triggers an attempt to cast ability if all requirements
# are met. While auto mode is disabled, this timer is
# paused.
@export var _auto_timer: Timer


#########################
###     Built-in      ###
#########################

func _ready():
	_cooldown_timer.wait_time = cooldown
	_cooldown_timer.one_shot = true

	if !can_use_auto_mode():
		_auto_timer.set_paused(true)


#########################
###       Public      ###
#########################

func toggle_auto_mode():
	if !can_use_auto_mode():
		Messages.add_error("This ability cannot be casted automatically")

		return

	var new_paused_value: bool = !_auto_timer.is_paused()
	_auto_timer.set_paused(new_paused_value)


func auto_mode_is_enabled() -> bool:
	var is_enabled: bool = !_auto_timer.is_paused()

	return is_enabled


# This is called when player triggers autocast by pressing
# on the item or autocast button.
func do_cast_manually():
	if !_can_cast():
		_add_cast_error_message()

		return

#	NOTE: immediate autocasts do not have targets even when
#	manually casted
# 
#	NOTE: for other autocast types we switch to selecting
#	the target. The cast will finish when player selects a
#	target and do_cast_manually_finish_for_manual_target()
#	is called.
	if _type_is_immediate():

		var target: Unit = null
		_do_cast(target)
	elif _type_is_point():
#		NOTE: for manual cast on unit, need to exit this f-n
#		to select point in world. The cast will finish when
#		player selects a point and
#		do_cast_manually_finish_for_point() is called.
		SelectPointForCast.start(self)
	else:
#		NOTE: for manual cast on unit, need to exit this f-n
#		to select target. The cast will finish when player
#		selects a target and
#		do_cast_manually_finish_for_manual_target() is
#		called.
		SelectTargetForCast.start(self)


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


func do_cast_manually_finish_for_point(target_pos: Vector2) -> bool:
#	NOTE: while player was selecting a target, conditions
#	for cast may have changed. For example tower's mana may
#	have been drained. So we need to check if we can cast
#	again.
	if !_can_cast():
		_add_cast_error_message()

		return false

	var in_range: float = Isometric.vector_in_range(_caster.position, target_pos, cast_range)

	if !in_range:
		Messages.add_error("Out of range")

		return false

	_target_pos = target_pos
	var target: Unit = null
	_do_cast(target)

	return true


func check_target_for_unit_autocast(target: Unit) -> bool:
	if target == null:
		return false

	var target_is_in_range: bool = _get_target_is_in_range(target)
	var target_type_is_valid = _get_target_type_is_valid_for_manual_cast(target)
	var target_is_ok: bool = target_is_in_range && target_type_is_valid

	return target_is_ok


#########################
###      Private      ###
#########################


# NOTE: target arg may be null if autocast is immediate
func _do_cast(target: Unit):
	CombatLog.log_autocast(_caster, target, self)

	_caster.subtract_mana(mana_cost, false)
	_cooldown_timer.start()
	
	if !handler.is_null():
		var autocast_event: Event = _make_autocast_event(target)
		handler.call(autocast_event)
	elif buff_type != null:
		buff_type.apply(_caster, target, _caster.get_level())
	else:
		push_error("Incorrect autocast state, handler = %s, buff_type= %s" % [handler, buff_type])

		return

	var spell_casted_event: Event = _make_autocast_event(target)
	_caster.spell_casted.emit(spell_casted_event)

	if target != null:
		var spell_targeted_event: Event = _make_autocast_event(target)
		target.spell_targeted.emit(spell_targeted_event)

	if !caster_art.is_empty():
		var effect: int = Effect.create_simple_at_unit(caster_art, _caster)
		Effect.destroy_effect_after_its_over(effect)

	if !target_art.is_empty() && target != null:
		var effect: int = Effect.create_simple_at_unit(target_art, target)
		Effect.destroy_effect_after_its_over(effect)


func _make_autocast_event(target: Unit) -> Event:
	var event: Event = Event.new(target)
	event._autocast = self

	return event


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


# Some autocast types are always manual
func can_use_auto_mode() -> bool:
	var can_use: bool = _types_that_can_use_auto_mode.has(autocast_type)

	return can_use


func _type_is_immediate() -> bool:
	return _immediate_type_list.has(autocast_type)


func _type_is_point() -> bool:
	return _point_type_list.has(autocast_type)


func _type_is_buff() -> bool:
	return _buff_type_list.has(autocast_type)


func _type_is_offensive() -> bool:
	return _offensive_type_list.has(autocast_type)


func _type_is_unit() -> bool:
	return _unit_type_list.has(autocast_type)


func _get_target_is_in_range(target: Unit) -> bool:
	var target_is_in_range: bool = Isometric.vector_in_range(target.position, _caster.position, auto_range)

	return target_is_in_range


func _get_target_type_is_valid_for_manual_cast(target: Unit) -> bool:
	var manual_target_type: TargetType = _get_target_type_for_manual_cast()
	var type_is_ok: bool = manual_target_type.match(target)

	return type_is_ok


func _get_target_type_for_manual_cast() -> TargetType:
	match autocast_type:
		Autocast.Type.AC_TYPE_ALWAYS_BUFF:
			if target_type != null:
				return target_type
		Autocast.Type.AC_TYPE_OFFENSIVE_BUFF:
			if target_type != null:
				return target_type
		Autocast.Type.AC_TYPE_OFFENSIVE_UNIT: return TargetType.new(TargetType.CREEPS)
		Autocast.Type.AC_TYPE_NOAC_CREEP: return TargetType.new(TargetType.CREEPS)
		Autocast.Type.AC_TYPE_NOAC_TOWER: return TargetType.new(TargetType.TOWERS)
		Autocast.Type.AC_TYPE_NOAC_PLAYER_TOWER: return TargetType.new(TargetType.PLAYER_TOWERS)

	push_error("_get_target_type_for_manual_cast doesn't support type: ", autocast_type)

	return TargetType.new(0)


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
	unit_list = _filter_target_units_for_caster_buff_group(_caster, unit_list)
	unit_list.shuffle()

	if !target_self:
		unit_list.erase(_caster)

	for unit in unit_list:
		if buff_type == null:
			return unit

		var buff: Buff = unit.get_buff_of_type(buff_type)
		var unit_has_buff: bool = buff != null

		if !unit_has_buff:
			return unit

	return null


func _filter_target_units_for_caster_buff_group(caster: Unit, targets: Array) -> Array:
	var caster_outgoing_buff_groups: Array[String] = caster.get_buff_groups(BuffGroup.Mode.OUTGOING)
	
	if caster_outgoing_buff_groups.is_empty():
		return targets
	
	var caster_outgoing_buff_group_numbers: Array = caster_outgoing_buff_groups.map(func(group): \
		return BuffGroup.get_buff_group_number(group))
	
	var filtered_targets: Array = []
	for target in targets:
		for target_group in target.get_buff_groups(BuffGroup.Mode.INCOMING):
			var group_number: int = BuffGroup.get_buff_group_number(target_group)
			if caster_outgoing_buff_group_numbers.has(group_number):
				filtered_targets.append(target)
	
	return filtered_targets


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


#########################
###     Callbacks     ###
#########################

func _on_auto_timer_timeout():
	if !_can_cast():
		return

	var cant_cast_because_zero_charges: bool = item_owner != null && item_owner.get_charges() == 0 && dont_cast_at_zero_charges

	if cant_cast_because_zero_charges:
		return

	var target: Unit = _get_target_for_auto_mode()

#	NOTE: no error message here like in manual case becase
#	this is the auto case and adding an error message here
#	would cause spam
	if target == null && !_type_is_immediate():
		return

	_do_cast(target)


#########################
### Setters / Getters ###
#########################

func set_caster(caster: Unit):
	_caster = caster


func get_caster() -> Unit:
	return _caster


# NOTE: autocast.getCooldown() in JASS
func get_cooldown() -> float:
	return cooldown


func get_remaining_cooldown() -> float:
	if !is_node_ready():
		push_error("Autocast cannot perform the request because it hasn't been added to the scene tree. Make sure that autocast's parent and it's ancestors have been added to the scene tree. Parent: ", get_parent())

		return 0.0

	return _cooldown_timer.time_left

# NOTE: autocast.getManacost() in JASS
func get_manacost() -> int:
	return mana_cost


func is_item_autocast() -> bool:
	return _is_item_autocast


func get_target_pos() -> Vector2:
	return _target_pos


func get_target_error_message(target: Unit) -> String:
	if target == null:
		return "No target selected"

	var target_is_in_range: bool = _get_target_is_in_range(target)
	var target_type_is_valid = _get_target_type_is_valid_for_manual_cast(target)

	if !target_is_in_range:
		return "Target is out of range"

	if !target_type_is_valid:
		return "Not a valid target for this ability"

	return "Target is valid"


#########################
###       Static      ###
#########################

static func make() -> Autocast:
	var autocast: Autocast = Globals.autocast_scene.instantiate()

	return autocast
