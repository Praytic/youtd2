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
# already have the buff_type. Note that the autocast doesn't
# apply the buff automatically, autocast handler should
# apply the buff.
#
# AC_TYPE_ALWAYS_BUFF - same as AC_TYPE_OFFENSIVE_BUFF, but
# casts always, event while tower is not attacking.
#
# AC_TYPE_OFFENSIVE_IMMEDIATE - while tower is attacking,
# performs an autocast without a target. Parameters like
# range and target type are not used.


enum Type {
	AC_TYPE_ALWAYS_BUFF,
	AC_TYPE_OFFENSIVE_BUFF,
	AC_TYPE_OFFENSIVE_UNIT,
	AC_TYPE_OFFENSIVE_IMMEDIATE
}


# NOTE: cast_range is the range used when autocast is
# manually triggered by the user, auto_range is the range
# used for regular autocasts that cast automatically.
var caster_art: String = ""
var cooldown: float = 0.1
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


func set_caster(caster: Unit):
	_caster = caster


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

	_caster.spend_mana(mana_cost)

	if !caster_art.is_empty():
		var effect: int = Effect.create_simple_at_unit(caster_art, _caster)
		Effect.destroy_effect(effect)

	if !target_art.is_empty():
		var effect: int = Effect.create_simple_at_unit(caster_art, target)
		Effect.destroy_effect(effect)

	var autocast_event = Event.new(target)
	handler.call(autocast_event)

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

	_caster.spend_mana(mana_cost)

	var autocast_event = Event.new(target)
	handler.call(autocast_event)


func _on_immediate_timer_timeout():
	if !_can_cast():
		return

	if !_caster.is_attacking():
		return

	_caster.spend_mana(mana_cost)

	var autocast_event = Event.new(_caster)
	handler.call(autocast_event)

	_cooldown_timer.start()


func _can_cast() -> bool:
	var on_cooldown: bool = _cooldown_timer.get_time_left() > 0
	var enough_mana: bool = _caster.get_mana() >= mana_cost
	var silenced: bool = _caster.is_silenced()
	var can_cast: bool = !on_cooldown && enough_mana && !silenced

	return can_cast
