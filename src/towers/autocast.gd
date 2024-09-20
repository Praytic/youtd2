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

# NOTE: num_buffs_before_idle, buff_target_type and buff_type are
# only relevant to "_BUFF" autocast types. For other
# autocast types leave these values blank.

# NOTE: cast_range is the range used when autocast is
# manually triggered by the user, auto_range is the range
# used for regular autocasts that cast automatically.
var title: String = "Placeholder Title"
var description: String = "Description"
var description_short: String = "Description Short"
var icon: String = "res://resources/icons/hud/gold.tres"
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
var buff_target_type: TargetType = null
var target_art: String = ""
var auto_range: float = 1000
var handler: Callable = Callable()
var item_owner: Item = null
var dont_cast_at_zero_charges: bool = false
# NOTE: only used for POINT type autocasts
var _target_pos: Vector2 = Vector2.ZERO
var _target_type: TargetType = null

var _caster: Unit = null
var _is_item_autocast: bool = false

# Tracks how much time is left before ability can be used.
@export var _cooldown_timer: ManualTimer
# While auto mode is enabled, this timer periodically
# triggers an attempt to cast ability if all requirements
# are met. While auto mode is disabled, this timer is
# paused.
@export var _auto_timer: ManualTimer

static var _uid_max: int = 1
var _uid: int = 0


#########################
###     Built-in      ###
#########################

func _ready():
	_cooldown_timer.wait_time = cooldown
	_cooldown_timer.one_shot = true

	_uid = _uid_max
	Autocast._uid_max += 1

	GroupManager.add("autocasts", self, get_uid())

	if !can_use_auto_mode():
		_auto_timer.set_paused(true)

	_check_buff_target_type()

	_target_type = _calculate_target_type()


#########################
###       Public      ###
#########################

func get_uid() -> int:
	return _uid


func toggle_auto_mode():
	var new_paused_value: bool = !_auto_timer.is_paused()
	_auto_timer.set_paused(new_paused_value)


func auto_mode_is_enabled() -> bool:
	var is_enabled: bool = !_auto_timer.is_paused()

	return is_enabled


func do_cast_at_pos(target_pos: Vector2):
	_target_pos = target_pos
	var target: Unit = null
	do_cast(target)


# NOTE: target arg may be null if autocast is immediate
func do_cast(target: Unit):
	CombatLog.log_autocast(_caster, target, self)

	_cooldown_timer.start()
	
	if !handler.is_null():
		var autocast_event: Event = _make_autocast_event(target)
		handler.call(autocast_event)
	elif buff_type != null:
		buff_type.apply(_caster, target, _caster.get_level())
	else:
		push_error("Incorrect autocast state, handler = %s, buff_type= %s" % [handler, buff_type])

		return

#	NOTE: need to subtract mana after performing autocast
#	because some autocast handlers need to check mana value
#	before it is spent.
	_caster.subtract_mana(mana_cost, false)

	var spell_casted_event: Event = _make_autocast_event(target)
	_caster.spell_casted.emit(spell_casted_event)

	if target != null:
		var spell_targeted_event: Event = _make_autocast_event(_caster)
		target.spell_targeted.emit(spell_targeted_event)

	if !caster_art.is_empty():
		var effect: int = Effect.create_simple_at_unit(caster_art, _caster)
		Effect.destroy_effect_after_its_over(effect)

	if !target_art.is_empty() && target != null:
		var effect: int = Effect.create_simple_at_unit(target_art, target)
		Effect.destroy_effect_after_its_over(effect)


func check_target_for_unit_autocast(target: Unit) -> bool:
	if target == null:
		return false

	var target_is_in_range: bool = _get_target_is_in_range(target)
	var target_type_is_valid = _target_type.match(target)
	var target_is_immune: bool = target.is_immune()
	var target_is_ok: bool = target_is_in_range && target_type_is_valid && !target_is_immune

	return target_is_ok


func target_pos_is_in_range(target_pos: Vector2) -> bool:
	var in_range: float = VectorUtils.in_range(_caster.get_position_wc3_2d(), target_pos, cast_range)

	return in_range


func can_cast() -> bool:
	if _caster == null:
		return false

	var on_cooldown: bool = _cooldown_timer.get_time_left() > 0
	var enough_mana: bool = _caster.get_mana() >= mana_cost
	var silenced: bool = _caster.is_silenced()
	var stunned: bool = _caster.is_stunned()
	var result: bool = !on_cooldown && enough_mana && !silenced && !stunned

	return result


# Some autocast types are always manual
func can_use_auto_mode() -> bool:
	var can_use: bool = _types_that_can_use_auto_mode.has(autocast_type)

	return can_use


func add_cast_error_message():
	var cast_error: String = _get_cast_error()

	if !cast_error.is_empty():
		var player: Player = _caster.get_player()
		Utils.add_ui_error(player, cast_error)


func type_is_immediate() -> bool:
	return _immediate_type_list.has(autocast_type)


func type_is_point() -> bool:
	return _point_type_list.has(autocast_type)


func type_is_buff() -> bool:
	return _buff_type_list.has(autocast_type)


func type_is_offensive() -> bool:
	return _offensive_type_list.has(autocast_type)


func type_is_unit() -> bool:
	return _unit_type_list.has(autocast_type)


#########################
###      Private      ###
#########################

func _check_buff_target_type():
	var ac_type_is_buff: bool = type_is_buff()

	if ac_type_is_buff && buff_target_type == null:
		push_error("Autocast %s has autocast type buff but doesn't have buff_target_type defined. You should define a non-null buff_target_type." % title)
	elif !ac_type_is_buff && buff_target_type != null:
		push_error("Autocast %s doesn't have autocast type buff but has non-null buff_target_type. You should change buff_target_type to null." % title)


func _make_autocast_event(target: Unit) -> Event:
	var event: Event = Event.new(target)
	event._autocast = self

	return event


func _get_target_is_in_range(target: Unit) -> bool:
	var range_extended: float = Utils.apply_unit_range_extension(auto_range, _target_type)
	var target_is_in_range: bool = VectorUtils.in_range(target.get_position_wc3_2d(), _caster.get_position_wc3_2d(), range_extended)

	return target_is_in_range


func _calculate_target_type() -> TargetType:
	match autocast_type:
		Autocast.Type.AC_TYPE_ALWAYS_BUFF:
			if buff_target_type != null:
				return buff_target_type
			else:
				return TargetType.new(0)
		Autocast.Type.AC_TYPE_ALWAYS_IMMEDIATE: return TargetType.new(0)
		Autocast.Type.AC_TYPE_OFFENSIVE_BUFF:
			if buff_target_type != null:
				return buff_target_type
			else:
				return TargetType.new(0)
		Autocast.Type.AC_TYPE_OFFENSIVE_UNIT: return TargetType.new(TargetType.CREEPS)
		Autocast.Type.AC_TYPE_OFFENSIVE_IMMEDIATE: return TargetType.new(0)
		Autocast.Type.AC_TYPE_NOAC_IMMEDIATE: return TargetType.new(0)
		Autocast.Type.AC_TYPE_NOAC_CREEP: return TargetType.new(TargetType.CREEPS)
		Autocast.Type.AC_TYPE_NOAC_TOWER: return TargetType.new(TargetType.TOWERS)
		Autocast.Type.AC_TYPE_NOAC_PLAYER_TOWER: return TargetType.new(TargetType.PLAYER_TOWERS)
		Autocast.Type.AC_TYPE_NOAC_POINT: return TargetType.new(0)

	push_error("_calculate_target_type doesn't support type: ", autocast_type)

	return TargetType.new(0)


func _get_target_for_auto_mode() -> Unit:
	if type_is_buff():
		return _get_target_for_buff_autocast()
	elif type_is_unit():
		return _get_target_for_unit_autocast()
	elif type_is_immediate():
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
	var unit_list: Array = Utils.get_units_in_range(_caster, _target_type, _caster.get_position_wc3_2d(), auto_range)

# 	NOTE: should not filter targets by buff groups if
# 	targets are creeps. Buff groups is a feature only for towers
	var autocast_targets_towers: bool = _target_type != null && _target_type.get_unit_type() == TargetType.UnitType.TOWERS
	if autocast_targets_towers:
		unit_list = _filter_target_units_for_caster_buff_group(_caster, unit_list)
	
	Utils.shuffle(Globals.synced_rng, unit_list)

	if !target_self:
		unit_list.erase(_caster)

	for unit in unit_list:
		if !Utils.unit_is_valid(unit):
			continue

		if buff_type == null:
			return unit

		var unit_is_immune: bool = unit.is_immune()
		if unit_is_immune:
			continue

		var buff: Buff = unit.get_buff_of_type(buff_type)
		var unit_has_buff: bool = buff != null

		if !unit_has_buff:
			return unit

	return null


# Examples:
# 
# a) Caster has no buffgroups, target has no buffgroups =>
#    accept
# 
# b) Caster has buffgroup 1=outgoing, target has no
#    buffgroups => reject
# 
# c) Caster has buffgroup 1=outgoing, target has buffgroup
#    1=incoming => accept
# 
# d) Caster has buffgroup 1=outgoing 2=outgoing, target has
#    buffgroup 1=incoming => accept
# 
# e) Caster has no buffgroups, target has
#    buffgroup 1=incoming => accept
func _filter_target_units_for_caster_buff_group(caster: Unit, targets: Array) -> Array:
	var caster_outgoing: Array[int] = caster.get_buff_groups([BuffGroupMode.enm.OUTGOING, BuffGroupMode.enm.BOTH])

	if caster_outgoing.is_empty():
		return targets

	var filtered_targets: Array = targets.filter(
		func(unit: Unit) -> bool:
			for buff_group in caster_outgoing:
				var target_mode: BuffGroupMode.enm = unit.get_buff_group_mode(buff_group)
				var buff_group_match: bool = target_mode == BuffGroupMode.enm.INCOMING || target_mode == BuffGroupMode.enm.BOTH

				if buff_group_match:
					return true

			return false
	)
	
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
	if !can_cast():
		return
	
# 	NOTE: need to do combat check in here instead of in
# 	can_cast() so that if auto mode is disabled, autocast
# 	can still be casted manually by player. For example,
# 	player needs to be able to start the cast to pick the
# 	target before tower starts attacking.
	var cant_cast_because_not_in_combat: bool = type_is_offensive() && !_caster.is_in_combat()

	if cant_cast_because_not_in_combat:
		return

	var cant_cast_because_zero_charges: bool = item_owner != null && item_owner.get_charges() == 0 && dont_cast_at_zero_charges

	if cant_cast_because_zero_charges:
		return

	var target: Unit = _get_target_for_auto_mode()

#	NOTE: no error message here like in manual case becase
#	this is the auto case and adding an error message here
#	would cause spam
	if target == null && !type_is_immediate():
		return

	do_cast(target)


#########################
### Setters / Getters ###
#########################

func set_caster(caster: Unit):
	_caster = caster


func get_caster() -> Unit:
	return _caster


func get_autocast_index() -> int:
	var autocast_list: Array[Autocast] = _caster.get_autocast_list()
	var index: int = autocast_list.find(self)

	return index


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
	var target_type_is_valid = _target_type.match(target)
	var target_is_immune: bool = target.is_immune()

	if !target_is_in_range:
		return "Target is out of range"

	if !target_type_is_valid:
		return "Not a valid target for this ability"

	if target_is_immune:
		return "Target is immune"

	return "Target is valid"


#########################
###       Static      ###
#########################

static func make() -> Autocast:
	var autocast: Autocast = Preloads.autocast_scene.instantiate()

	return autocast
