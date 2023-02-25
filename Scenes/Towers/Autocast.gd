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
class Data:
	var caster_art: String = ""
	var cooldown: float = 0.1
	var num_buffs_before_idle: int = 0
	var is_extended: bool = false
	var autocast_type: int = Type.AC_TYPE_OFFENSIVE_UNIT
	var mana_cost: int = 0
	var the_range: float = 1000
	var buff_type: int = 0
	var target_self: bool = false
	var target_type: TargetType = TargetType.new(TargetType.UnitType.MOBS)
	var target_art: String = ""
	var auto_range: float = 1000


var _data: Data = Data.new()
var _handler_object = null
var _handler_function: String = ""
var _target_list: Array = []
var _target_count_max: int = 1

onready var _targeting_area: Area2D = $TargetingArea
onready var _collision_shape: CollisionShape2D = $TargetingArea/CollisionShape2D
onready var _cooldown_timer: Timer = $CooldownTimer


func _ready():
	_load_data_for_scene_nodes()


func set_data(data: Data, handler_object, handler_function: String):
	_data = data
	_handler_object = handler_object
	_handler_function = handler_function

	var handler_function_exists: bool = _handler_object.has_method(handler_function)

	if !handler_function_exists:
		print_debug("Attempted to register an autocast handler function that doesn't exist: ", handler_function)


# NOTE: this should be used only by Tower.gd to update range
# and cooldown of attack autocast when tower's properties
# are modified.
func update_data(new_range: float, new_cooldown: float):
	_data.the_range = new_range
	_data.auto_range = new_range

	_data.cooldown = new_cooldown

	_load_data_for_scene_nodes()


func _load_data_for_scene_nodes():
	Utils.circle_shape_set_radius(_collision_shape, _data.auto_range)
	_cooldown_timer.wait_time = _data.cooldown


func _add_target(new_target: Mob):
	if new_target == null && !new_target.is_dead():
		return

	new_target.connect("death", self, "_on_target_death", [new_target])
	_target_list.append(new_target)


func _remove_target(target: Mob):
	target.disconnect("death", self, "_on_target_death")
	_target_list.erase(target)


func _have_target_space() -> bool:
	return _target_list.size() < _target_count_max


# Find a target that is currently in range
# TODO: prioritizing closest mob here, but maybe change behavior
# based on tower properties or other game design considerations
func _find_new_target() -> Mob:
	var body_list: Array = _targeting_area.get_overlapping_bodies()
	var closest_mob: Mob = null
	var distance_min: float = 1000000.0

#	NOTE: can't use existing targets as new targets
	for target in _target_list:
		body_list.erase(target)
	
	for body in body_list:
		if body is Mob || !body.is_dead():
			var mob: Mob = body
			var distance: float = (mob.position - self.position).length()
			
			if distance < distance_min:
				closest_mob = mob
				distance_min = distance
	
	return closest_mob


func _try_to_cast():
	if !_handler_object.has_method(_handler_function):
		return

	var attack_on_cooldown: bool = _cooldown_timer.time_left > 0
	
	if attack_on_cooldown:
		return

	for target in _target_list:
		var event = Event.new(target, 0, true)
		_handler_object.call(_handler_function, event)
	
	if !_target_list.empty():
		_cooldown_timer.start()


func _on_target_death(_event: Event, target: Mob):
	_remove_target(target)


func _on_CooldownTimer_timeout():
	if _have_target_space():
		var new_target: Mob = _find_new_target()
		_add_target(new_target)

# 	NOTE: this is the one case where try_to_cast() is called
# 	even if add_target() wasn't called
	_try_to_cast()


func _on_TargetingArea_body_entered(body):
	if !body is Mob:
		return

	if _have_target_space():
		var new_target: Mob = body as Mob
		_add_target(new_target)
		_try_to_cast()


func _on_TargetingArea_body_exited(body):
	var target_went_out_of_range: bool = _target_list.has(body)

	if target_went_out_of_range:
		var old_target: Mob = body as Mob
		_remove_target(old_target)
