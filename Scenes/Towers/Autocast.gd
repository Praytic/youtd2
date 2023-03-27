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


enum Type {
	AC_TYPE_OFFENSIVE_UNIT
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
var range: float = 1000
var buff_type: int = 0
var target_self: bool = false
var target_type: TargetType = null
var target_art: String = ""
var auto_range: float = 1000
var handler: Callable = Callable()

var _caster: Unit = null

@onready var _cooldown_timer: Timer = $CooldownTimer


static func make() -> Autocast:
	var autocast: Autocast = load("res://Scenes/Towers/Autocast.tscn").instantiate()

	return autocast


func _ready():
	_cooldown_timer.wait_time = cooldown
	_cooldown_timer.one_shot = true


func set_caster(caster: Unit):
	_caster = caster
	caster.attack.connect(_on_caster_attack)


func _on_caster_attack(attack_event: Event):
	var target: Unit = attack_event.get_target()
	
# 	NOTE: caster may have higher attack range than autocast
# 	so we need to check that target is in range of autocast
	var distance_to_target: float = Utils.vector_isometric_distance_to(target.position, _caster.position)
	var target_is_in_range: bool = distance_to_target <= auto_range

	if !target_is_in_range:
		return

	if target_type != null:
		var target_matches_type: bool = target_type.match(target)

		if !target_matches_type:
			return

	var enough_mana: bool = _caster.get_mana() >= mana_cost

	if !enough_mana:
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
