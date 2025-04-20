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


const _types_that_can_use_auto_mode: Array[Autocast.Type] = [
	Autocast.Type.AC_TYPE_ALWAYS_BUFF,
	Autocast.Type.AC_TYPE_ALWAYS_IMMEDIATE,
	Autocast.Type.AC_TYPE_OFFENSIVE_BUFF,
	Autocast.Type.AC_TYPE_OFFENSIVE_UNIT,
	Autocast.Type.AC_TYPE_OFFENSIVE_IMMEDIATE,
]
const _immediate_type_list: Array[Autocast.Type] = [
	Autocast.Type.AC_TYPE_ALWAYS_IMMEDIATE,
	Autocast.Type.AC_TYPE_OFFENSIVE_IMMEDIATE,
	Autocast.Type.AC_TYPE_NOAC_IMMEDIATE,
]
const _buff_type_list: Array[Autocast.Type] = [
	Autocast.Type.AC_TYPE_ALWAYS_BUFF,
	Autocast.Type.AC_TYPE_OFFENSIVE_BUFF,
]
const _offensive_type_list: Array[Autocast.Type] = [
	Autocast.Type.AC_TYPE_OFFENSIVE_BUFF,
	Autocast.Type.AC_TYPE_OFFENSIVE_UNIT,
	Autocast.Type.AC_TYPE_OFFENSIVE_IMMEDIATE,
	Autocast.Type.AC_TYPE_OFFENSIVE_POINT,
]
const _unit_type_list: Array[Autocast.Type] = [
	Autocast.Type.AC_TYPE_OFFENSIVE_UNIT,
]
const _point_type_list: Array[Autocast.Type] = [
	Autocast.Type.AC_TYPE_OFFENSIVE_POINT,
	Autocast.Type.AC_TYPE_NOAC_POINT,
]

# NOTE: buff_target_type and buff_type are
# only relevant to "_BUFF" autocast types. For other
# autocast types leave these values blank.

var _autocast_id: int = -1
var _autocast_type: Autocast.Type = Type.AC_TYPE_OFFENSIVE_UNIT
var _buff_type: BuffType = null
var _buff_target_type: TargetType = null
var _handler: Callable = Callable()
var _target_pos: Vector2 = Vector2.ZERO
var _target_type: TargetType = null
var _caster: Unit = null
var _is_item_autocast: bool = false
var _item_owner: Item = null

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
	_cooldown_timer.wait_time = get_cooldown()
	_cooldown_timer.one_shot = true

	_uid = _uid_max
	Autocast._uid_max += 1

	GroupManager.add("autocasts", self, get_uid())

	if !can_use_auto_mode():
		_auto_timer.set_paused(true)

	_check_buff_target_type()

	_target_type = Autocast.calculate_target_type(_autocast_type, _buff_target_type)


#########################
###       Public      ###
#########################

func get_id() -> int:
	return _autocast_id


func get_name_english() -> String:
	var name_english: String = AutocastProperties.get_name_english(_autocast_id)

	return name_english


func get_autocast_name() -> String:
	var autocast_name: String = AutocastProperties.get_autocast_name(_autocast_id)

	return autocast_name


func get_description_long() -> String:
	var description_long: String = AutocastProperties.get_description_long(_autocast_id)

	return description_long


func get_icon_path() -> String:
	var icon_path: String = AutocastProperties.get_icon_path(_autocast_id)

	return icon_path


func get_target_self() -> bool:
	var target_self: bool = AutocastProperties.get_target_self(_autocast_id)

	return target_self


func get_cast_range() -> float:
	var cast_range: float = AutocastProperties.get_cast_range(_autocast_id)

	return cast_range


func get_auto_range() -> float:
	var auto_range: float = AutocastProperties.get_auto_range(_autocast_id)

	return auto_range


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
	
	if !_handler.is_null():
		var autocast_event: Event = _make_autocast_event(target)
		_handler.call(autocast_event)
	elif _buff_type != null:
		_buff_type.apply(_caster, target, _caster.get_level())
	else:
		push_error("Incorrect autocast state, _handler = %s, _buff_type= %s" % [_handler, _buff_type])

		return

#	NOTE: need to subtract mana after performing autocast
#	because some autocast handlers need to check mana value
#	before it is spent.
	var mana_cost: int = get_mana_cost()
	_caster.subtract_mana(mana_cost, false)

	var spell_casted_event: Event = _make_autocast_event(target)
	_caster.spell_casted.emit(spell_casted_event)

	if target != null:
		var spell_targeted_event: Event = _make_autocast_event(_caster)
		target.spell_targeted.emit(spell_targeted_event)

	var caster_art: String = AutocastProperties.get_caster_art(_autocast_id)
	if !caster_art.is_empty():
		Effect.create_simple_at_unit(caster_art, _caster)

	var target_art: String = AutocastProperties.get_target_art(_autocast_id)
	if !target_art.is_empty() && target != null:
		Effect.create_simple_at_unit(target_art, target)


func check_target_for_unit_autocast(target: Unit) -> bool:
	if target == null:
		return false

	var target_is_in_range: bool = _get_target_is_in_range(target)
	var target_type_is_valid = _target_type.match(target)
	var target_is_immune: bool = target.is_immune()
	var target_is_self: bool = target == _caster
	var target_self: bool = get_target_self()
	var targetting_self_when_forbidden: bool = !target_self && target_is_self
	var target_is_ok: bool = target_is_in_range && target_type_is_valid && !target_is_immune && !targetting_self_when_forbidden

	return target_is_ok


func target_pos_is_in_range(target_pos: Vector2) -> bool:
	var in_range: float = VectorUtils.in_range(_caster.get_position_wc3_2d(), target_pos, get_cast_range())

	return in_range


func can_cast() -> bool:
	if _caster == null:
		return false

	var on_cooldown: bool = _cooldown_timer.get_time_left() > 0
	var mana_cost: int = get_mana_cost()
	var enough_mana: bool = _caster.get_mana() >= mana_cost
	var silenced: bool = _caster.is_silenced()
	var stunned: bool = _caster.is_stunned()
	var result: bool = !on_cooldown && enough_mana && !silenced && !stunned

	return result


# Some autocast types are always manual
func can_use_auto_mode() -> bool:
	var can_use: bool = _types_that_can_use_auto_mode.has(_autocast_type)

	return can_use


# Some autocast types are always manual
static func can_use_auto_mode_for_id(autocast_id: int) -> bool:
	var autocast_type: Autocast.Type = AutocastProperties.get_autocast_type(autocast_id)
	var can_use: bool = _types_that_can_use_auto_mode.has(autocast_type)

	return can_use


func add_cast_error_message():
	var cast_error: String = _get_cast_error()

	if !cast_error.is_empty():
		var player: Player = _caster.get_player()
		Utils.add_ui_error(player, cast_error)


func type_is_immediate() -> bool:
	return _immediate_type_list.has(_autocast_type)


func type_is_point() -> bool:
	return _point_type_list.has(_autocast_type)


func type_is_buff() -> bool:
	return _buff_type_list.has(_autocast_type)


func type_is_offensive() -> bool:
	return _offensive_type_list.has(_autocast_type)


func type_is_unit() -> bool:
	return _unit_type_list.has(_autocast_type)


# NOTE: this is used if this autocast is "owned" by an item
# instead of a tower.
func set_item_owner(item: Item):
	_item_owner = item
	_is_item_autocast = true


#########################
###      Private      ###
#########################

func _check_buff_target_type():
	var ac_type_is_buff: bool = type_is_buff()

	if ac_type_is_buff && _buff_target_type == null:
		push_error("Autocast %s has autocast type buff but doesn't have buff_target_type defined. You should define a non-null buff_target_type." % get_name_english())
	elif !ac_type_is_buff && _buff_target_type != null:
		push_error("Autocast %s doesn't have autocast type buff but has non-null buff_target_type. You should change buff_target_type to null." % get_name_english())


func _make_autocast_event(target: Unit) -> Event:
	var event: Event = Event.new(target)
	event._autocast = self

	return event


func _get_target_is_in_range(target: Unit) -> bool:
	var range_extended: float = Utils.apply_unit_range_extension(get_auto_range(), _target_type)
	var target_is_in_range: bool = VectorUtils.in_range(target.get_position_wc3_2d(), _caster.get_position_wc3_2d(), range_extended)

	return target_is_in_range


static func calculate_target_type(autocast_type_arg: Autocast.Type, buff_target_type_arg: TargetType) -> TargetType:
	match autocast_type_arg:
		Autocast.Type.AC_TYPE_ALWAYS_BUFF:
			if buff_target_type_arg != null:
				return buff_target_type_arg
			else:
				return TargetType.new(0)
		Autocast.Type.AC_TYPE_ALWAYS_IMMEDIATE: return TargetType.new(0)
		Autocast.Type.AC_TYPE_OFFENSIVE_BUFF:
			if buff_target_type_arg != null:
				return buff_target_type_arg
			else:
				return TargetType.new(0)
		Autocast.Type.AC_TYPE_OFFENSIVE_UNIT: return TargetType.new(TargetType.CREEPS)
		Autocast.Type.AC_TYPE_OFFENSIVE_IMMEDIATE: return TargetType.new(0)
		Autocast.Type.AC_TYPE_NOAC_IMMEDIATE: return TargetType.new(0)
		Autocast.Type.AC_TYPE_NOAC_CREEP: return TargetType.new(TargetType.CREEPS)
		Autocast.Type.AC_TYPE_NOAC_TOWER: return TargetType.new(TargetType.TOWERS)
		Autocast.Type.AC_TYPE_NOAC_PLAYER_TOWER: return TargetType.new(TargetType.PLAYER_TOWERS)
		Autocast.Type.AC_TYPE_NOAC_POINT: return TargetType.new(0)

	push_error("_calculate_target_type doesn't support type: ", autocast_type_arg)

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
	var unit_list: Array = Utils.get_units_in_range(_caster, _target_type, _caster.get_position_wc3_2d(), get_auto_range())

# 	NOTE: should not filter targets by buff groups if
# 	targets are creeps. Buff groups is a feature only for towers
	var autocast_targets_towers: bool = _target_type != null && _target_type.get_unit_type() == TargetType.UnitType.TOWERS
	if autocast_targets_towers:
		unit_list = _filter_target_units_for_caster_buff_group(_caster, unit_list)
	
	Utils.shuffle(Globals.synced_rng, unit_list)

	var target_self: bool = get_target_self()
	if !target_self:
		unit_list.erase(_caster)

	for unit in unit_list:
		if !Utils.unit_is_valid(unit):
			continue

		if _buff_type == null:
			return unit

		var unit_is_immune: bool = unit.is_immune()
		if unit_is_immune:
			continue

		var buff: Buff = unit.get_buff_of_type(_buff_type)
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
	var mana_cost: int = get_mana_cost()
	var enough_mana: bool = _caster.get_mana() >= mana_cost
	var silenced: bool = _caster.is_silenced()
	var stunned: bool = _caster.is_stunned()

	if on_cooldown:
		return tr("AUTOCAST_ERROR_NOT_READY")
	elif !enough_mana:
		return tr("AUTOCAST_ERROR_NOT_ENOUGH_MANA")
	elif silenced:
		return tr("AUTOCAST_ERROR_SILENCED")
	elif stunned:
		return tr("AUTOCAST_ERROR_STUNNED")
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

	var cant_cast_because_zero_charges: bool = _item_owner != null && _item_owner.get_charges() == 0 && _item_owner.uses_charges()

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
	var cooldown: float = AutocastProperties.get_cooldown(_autocast_id)

	return cooldown


func get_remaining_cooldown() -> float:
	if !is_node_ready():
		push_error("Autocast cannot perform the request because it hasn't been added to the scene tree. Make sure that autocast's parent and it's ancestors have been added to the scene tree. Parent: ", get_parent())

		return 0.0

	return _cooldown_timer.time_left

# NOTE: autocast.getManacost() in JASS
func get_mana_cost() -> int:
	var mana_cost: int = AutocastProperties.get_mana_cost(_autocast_id)

	return mana_cost


func is_item_autocast() -> bool:
	return _is_item_autocast


func get_target_pos() -> Vector2:
	return _target_pos


func get_target_error_message(target: Unit) -> String:
	if target == null:
		return tr("MESSAGE_NO_TARGET")

	var target_is_in_range: bool = _get_target_is_in_range(target)
	var target_type_is_valid = _target_type.match(target)
	var target_is_immune: bool = target.is_immune()
	var target_is_self: bool = target != null && target == _caster
	var target_self: bool = get_target_self()
	var targetting_self_when_forbidden: bool = !target_self && target_is_self

	if !target_is_in_range:
		return tr("MESSAGE_OUT_OF_RANGE")

	if !target_type_is_valid:
		return tr("MESSAGE_TARGET_NOT_VALID")

	if target_is_immune:
		return tr("MESSAGE_TARGET_IMMUNE")

	if targetting_self_when_forbidden:
		return tr("MESSAGE_CANT_CAST_ON_SELF")

	return tr("MESSAGE_TARGET_IS_VALID")


#########################
###       Static      ###
#########################

static func make(autocast_id: int, creator_object: Object) -> Autocast:
	var buff_type_string: String = AutocastProperties.get_buff_type(autocast_id)
	var buff_type: BuffType
	if !buff_type_string.is_empty():
		buff_type = creator_object.get(buff_type_string)
		
		if buff_type == null:
			push_error("Failed to find buff type for autocast. Buff type = %s, autocast id = %s" % [buff_type_string, autocast_id])
	else:
		buff_type = null

	var handler_function_string: String = AutocastProperties.get_handler_function(autocast_id)
	var handler_function: Callable
	if !handler_function_string.is_empty():
		handler_function = Callable(creator_object, handler_function_string)
		
		if !handler_function.is_valid():
			push_error("Failed to find handle function for autocast. Handler function = %s, autocast id = %d" % [handler_function_string, autocast_id])
#			NOTE: Switch to empty callable to prevent
#			runtime errors
			handler_function = Callable()
	else:
		handler_function = Callable()
	
#	NOTE: need to store autocast_type and buff_target_type
#	in variables instead of getting them from
#	AutocastProperties every time because these properties
#	are a bit costly too calculate all the time. Other
#	properties are okay to get through AutocastProperties.
	var autocast: Autocast = Preloads.autocast_scene.instantiate()
	autocast._autocast_id = autocast_id
	autocast._autocast_type = AutocastProperties.get_autocast_type(autocast_id)
	autocast._buff_target_type = AutocastProperties.get_buff_target_type(autocast_id)
	autocast._buff_type = buff_type
	autocast._handler = handler_function

	return autocast


static func autocast_type_to_string(t: Type) -> String:
	match t:
		Type.AC_TYPE_ALWAYS_BUFF: return "AC_TYPE_ALWAYS_BUFF"
		Type.AC_TYPE_ALWAYS_IMMEDIATE: return "AC_TYPE_ALWAYS_IMMEDIATE"
		Type.AC_TYPE_OFFENSIVE_BUFF: return "AC_TYPE_OFFENSIVE_BUFF"
		Type.AC_TYPE_OFFENSIVE_UNIT: return "AC_TYPE_OFFENSIVE_UNIT"
		Type.AC_TYPE_OFFENSIVE_IMMEDIATE: return "AC_TYPE_OFFENSIVE_IMMEDIATE"
		Type.AC_TYPE_OFFENSIVE_POINT: return "AC_TYPE_OFFENSIVE_POINT"
		Type.AC_TYPE_NOAC_IMMEDIATE: return "AC_TYPE_NOAC_IMMEDIATE"
		Type.AC_TYPE_NOAC_CREEP: return "AC_TYPE_NOAC_CREEP"
		Type.AC_TYPE_NOAC_TOWER: return "AC_TYPE_NOAC_TOWER"
		Type.AC_TYPE_NOAC_PLAYER_TOWER: return "AC_TYPE_NOAC_PLAYER_TOWER"
		Type.AC_TYPE_NOAC_POINT: return "AC_TYPE_NOAC_POINT"

	return "UNKNOWN"


static func string_to_autocast_type(t_string: String) -> Type:
	match t_string:
		"AC_TYPE_ALWAYS_BUFF": return Type.AC_TYPE_ALWAYS_BUFF
		"AC_TYPE_ALWAYS_IMMEDIATE": return Type.AC_TYPE_ALWAYS_IMMEDIATE
		"AC_TYPE_OFFENSIVE_BUFF": return Type.AC_TYPE_OFFENSIVE_BUFF
		"AC_TYPE_OFFENSIVE_UNIT": return Type.AC_TYPE_OFFENSIVE_UNIT
		"AC_TYPE_OFFENSIVE_IMMEDIATE": return Type.AC_TYPE_OFFENSIVE_IMMEDIATE
		"AC_TYPE_OFFENSIVE_POINT": return Type.AC_TYPE_OFFENSIVE_POINT
		"AC_TYPE_NOAC_IMMEDIATE": return Type.AC_TYPE_NOAC_IMMEDIATE
		"AC_TYPE_NOAC_CREEP": return Type.AC_TYPE_NOAC_CREEP
		"AC_TYPE_NOAC_TOWER": return Type.AC_TYPE_NOAC_TOWER
		"AC_TYPE_NOAC_PLAYER_TOWER": return Type.AC_TYPE_NOAC_PLAYER_TOWER
		"AC_TYPE_NOAC_POINT": return Type.AC_TYPE_NOAC_POINT

	return Type.AC_TYPE_NOAC_POINT
