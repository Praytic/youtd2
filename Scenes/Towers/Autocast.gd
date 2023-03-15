class_name Autocast
extends Node

# Autocast is a special event that is an advanced version of
# periodic event. In addition to calling the handler
# function periodically like periodic event does, it also
# keeps track of a target and passes the target to the
# handler function. It's used to implement attacks and
# spells casted by towers. Used by creating a Buff and
# calling Buff.add_autocast().


enum Type {
	AC_TYPE_OFFENSIVE_UNIT
}


# TODO: why are there two "range" variables?
# TODO: implement arts
var caster_art: String = ""
var cooldown: float = 0.1
var num_buffs_before_idle: int = 0
var is_extended: bool = false
var autocast_type: int = Type.AC_TYPE_OFFENSIVE_UNIT
var mana_cost: int = 0
var the_range: float = 1000
var buff_type: int = 0
var target_self: bool = false
var target_type: TargetType = TargetType.new(TargetType.UnitType.CREEPS)
var target_art: String = ""
var auto_range: float = 1000
var handler: Callable = Callable()


var _target_list: Array = []
var _target_count_max: int = 1
var _caster: Unit = null

@onready var _targeting_area: Area2D = $TargetingArea
@onready var _collision_polygon: CollisionPolygon2D = $TargetingArea/CollisionPolygon2D
@onready var _cooldown_timer: Timer = $CooldownTimer


static func make() -> Autocast:
	var autocast: Autocast = load("res://Scenes/Towers/Autocast.tscn").instantiate()

	return autocast


func _ready():
	Utils.circle_polygon_set_radius(_collision_polygon, auto_range)

	set_cooldown(cooldown)

	if _caster == null:
		print_debug("caster is null, you must set it before calling add_child() on autocast")


# NOTE: this should be used only by Tower.gd to update
# cooldown because for towers cooldown may be changed
# dynamically by buffs, items and other effects.
func set_cooldown(new_cooldown: float):
	_cooldown_timer.wait_time = new_cooldown


func _add_target(new_target: Creep):
	if new_target == null || new_target.is_dead() || new_target.is_invisible():
		return

	new_target.death.connect(_on_target_death.bind(new_target))
	new_target.became_invisible.connect(_on_target_became_invisible.bind(new_target))
	_target_list.append(new_target)


func _remove_target(target: Creep):
	target.death.disconnect(_on_target_death)
	target.became_invisible.disconnect(_on_target_became_invisible)

	_target_list.erase(target)


func _have_target_space() -> bool:
	return _target_list.size() < _target_count_max


# Find a target that is currently in range
# TODO: prioritizing closest creep here, but maybe change behavior
# based on tower properties or other game design considerations
func _find_new_target() -> Creep:
	var body_list: Array = _targeting_area.get_overlapping_bodies()

#	NOTE: can't use existing targets as new targets
	for target in _target_list:
		body_list.erase(target)

	body_list = body_list.filter(func(body): return body is Creep && !body.is_dead() && !body.is_invisible())

	Utils.shuffle_list(body_list)

	if body_list.size() != 0:
		var closest_creep: Creep = body_list[0]

		return closest_creep
	else:
		return null


func _try_to_cast():
	var attack_on_cooldown: bool = _cooldown_timer.time_left > 0
	
	if attack_on_cooldown:
		return

	var enough_mana: bool = _caster.get_mana() >= mana_cost

	if !enough_mana:
		return

	var casted_on_target: bool = false

	for target in _target_list:
		var event = Event.new(target, 0, true)
		handler.call(event)

		casted_on_target = true
	
	if casted_on_target:
		_cooldown_timer.start()

		_caster.spend_mana(mana_cost)


func _on_target_death(_event: Event, target: Creep):
	_remove_target(target)


func _on_CooldownTimer_timeout():
	if _have_target_space():
		var new_target: Creep = _find_new_target()
		_add_target(new_target)

# 	NOTE: this is the one case where try_to_cast() is called
# 	even if add_target() wasn't called
	_try_to_cast()


func _on_TargetingArea_body_entered(body):
	if !body is Creep:
		return

# 	If invisible creep comes in range, don't add it as target,
# 	but remember it by connecting to it's signal. If the creep
# 	becomes visible (while still in range), it may become a
# 	target.
	if !body.is_connected("became_visible", _on_creep_in_range_became_visible):
		body.became_visible.connect(_on_creep_in_range_became_visible.bind(body))

	if body.is_invisible():
		return

	if _have_target_space():
		var new_target: Creep = body as Creep
		_add_target(new_target)
		_try_to_cast()


func _on_TargetingArea_body_exited(body):
	if !body is Creep:
		return

	body.became_visible.disconnect(_on_creep_in_range_became_visible)

	var target_went_out_of_range: bool = _target_list.has(body)

	if target_went_out_of_range:
		var old_target: Creep = body as Creep
		_remove_target(old_target)


func _on_target_became_invisible(target: Creep):
	_remove_target(target)


func _on_creep_in_range_became_visible(creep: Creep):
	_on_TargetingArea_body_entered(creep)
