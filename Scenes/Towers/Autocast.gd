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


# NOTE: cast_range is the range used when autocast is
# manually triggered by the user, auto_range is the range
# used for regular autocasts that cast automatically.
var display_name: String = "Autocast name"
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

@onready var _cooldown_timer: Timer = $CooldownTimer
@onready var _buff_timer: Timer = $BuffTimer
@onready var _immediate_timer: Timer = $ImmediateTimer


static func make() -> Autocast:
	var autocast: Autocast = load("res://Scenes/Towers/Autocast.tscn").instantiate()

	return autocast


func _ready():
	_cooldown_timer.wait_time = cooldown
	_cooldown_timer.one_shot = true

#	NOTE: AC_TYPE_OFFENSIVE_UNIT is triggered when caster
#	attacks, while AC_TYPE_ALWAYS_BUFF runs on it's own
#	timer.
	match autocast_type:
		Type.AC_TYPE_OFFENSIVE_UNIT:
			_caster.attack.connect(_on_caster_attack)
		Type.AC_TYPE_ALWAYS_BUFF:
			_buff_timer.start()
		Type.AC_TYPE_OFFENSIVE_BUFF:
			_buff_timer.start()
		Type.AC_TYPE_OFFENSIVE_IMMEDIATE:
			_immediate_timer.start()
		Type.AC_TYPE_ALWAYS_IMMEDIATE:
			_immediate_timer.start()


func set_caster(caster: Unit):
	_caster = caster


func get_cooldown() -> float:
	return cooldown

func get_remaining_cooldown() -> float:
	return _cooldown_timer.time_left

func get_manacost() -> int:
	return mana_cost


func is_item_autocast() -> bool:
	return _is_item_autocast


func _on_caster_attack(attack_event: Event):
	if !_can_cast():
		return
	
	var target: Unit = attack_event.get_target()

# 	NOTE: caster may have higher attack range than autocast
# 	so we need to check that target is in range of autocast
	var distance_to_target: float = Isometric.vector_distance_to(target.position, _caster.position)
	var target_is_in_range: bool = distance_to_target <= auto_range

	if !target_is_in_range:
		return

	if target_type != null:
		var target_matches_type: bool = target_type.match(target)

		if !target_matches_type:
			return

	if !caster_art.is_empty():
		var effect: int = Effect.create_simple_at_unit(caster_art, _caster)
		Effect.destroy_effect(effect)

	if !target_art.is_empty():
		var effect: int = Effect.create_simple_at_unit(caster_art, target)
		Effect.destroy_effect(effect)

	_do_cast(target)

	_cooldown_timer.start()


func _on_buff_timer_timeout():
	if !_can_cast():
		return

	if autocast_type == Type.AC_TYPE_OFFENSIVE_BUFF && !_caster.is_attacking():
		return

	var unit_list: Array = Utils.get_units_in_range(target_type, _caster.position, auto_range)
	Utils.sort_unit_list_by_distance(unit_list, _caster.position)

	var target: Unit = null

	for unit in unit_list:
		var buff: Buff = unit.get_buff_of_type(buff_type)
		var unit_has_buff: bool = buff != null

		if !unit_has_buff:
			target = unit

			break

	if target == null:
		return

	_do_cast(target)


func _on_immediate_timer_timeout():
	if !_can_cast():
		return

	if autocast_type == Type.AC_TYPE_OFFENSIVE_IMMEDIATE && !_caster.is_attacking():
		return

# 	NOTE: immediate autocasts have no target so use the
# 	caster itself as target
	_do_cast(_caster)

	_cooldown_timer.start()


func _do_cast(target: Unit):
	_caster.subtract_mana(mana_cost, true)
	
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

	var spell_targeted_event: Event = Event.new(target)
	spell_targeted_event._autocast = self
	target.spell_targeted.emit(spell_targeted_event)


func _can_cast() -> bool:
	var on_cooldown: bool = _cooldown_timer.get_time_left() > 0
	var enough_mana: bool = _caster.get_mana() >= mana_cost
	var silenced: bool = _caster.is_silenced()
	var stunned: bool = _caster.is_stunned()
	var can_cast: bool = !on_cooldown && enough_mana && !silenced && !stunned

	return can_cast
