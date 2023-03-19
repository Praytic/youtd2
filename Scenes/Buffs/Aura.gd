class_name Aura
extends Node2D

# Aura applies an effect to targets in range of caster.
# Create an aura instance, set it's variables and add as
# child of the caster scene to use the aura. Caster should
# define a function which creates a buff for the aura effect
# and set aura's create_aura_effect_function variable to the
# name of this function.

# TODO: current implementation has a lag of 0.2s because it
# is based on a timer. (Godot timer's aren't supposed to
# have wait times of lower than 0.2s and it would cause
# perfomance issues anyway). An implementation without lag
# would need to not use a timer and instead connect to
# body_entered/exited() signals of the Area2D. That
# implementation is considerably more complex to implement
# because of the need to handle overlapping aura's from
# different towers. For example, if a creep is inside two
# intersecting aura's of same type, and exits one of them,
# the aura effect has to be swapped to the aura that the creep
# remains in. Also need to handle aura upgrades when creep
# enters aura of same type but higher level effect.

# TODO: implement target type


var aura_range: float = 10.0
var target_type: TargetType = TargetType.new(TargetType.CREEPS)
var target_self: bool = false
var level: int = 0
var level_add: int = 0
var power: int = 0
var power_add: int = 0
var aura_effect_is_friendly: bool = false
var create_aura_effect_function: String = ""
var caster: Unit = null
var create_aura_effect_object: Object = null

@onready var _timer: Timer = $Timer
@onready var _area: Area2D = $Area2D
@onready var _collision_polygon: CollisionPolygon2D = $Area2D/CollisionPolygon2D


func _ready():
	Utils.circle_polygon_set_radius(_collision_polygon, aura_range)
	_timer.one_shot = false
	_timer.wait_time = 0.2
	_timer.start()


func _on_Timer_timeout():
	var body_list: Array = _area.get_overlapping_bodies()

	for body in body_list:
		if !body is Creep:
			continue

		var aura_effect = _create_aura_effect()

		if aura_effect == null:
			return

		var creep: Creep = body as Creep
		# NOTE: use 0.21 duration so that buff is refreshed
		# right before it expires
		aura_effect.apply_custom_timed(caster, creep, get_level(), 0.21)


func _create_aura_effect() -> Buff:
	if create_aura_effect_object == null:
		print_debug("Failed to create aura effect because create_aura_effect_object variable is not set.")

		return null

	if !create_aura_effect_object.has_method(create_aura_effect_function):
		print_debug("Failed to create aura effect because create_aura_effect_object doesn't have the create_aura_effect_function.")

		return null

	var aura_effect: Buff = create_aura_effect_object.call(create_aura_effect_function)

	return aura_effect


func get_power() -> int:
	return power + caster.get_level() * power_add


func get_level() -> int:
	return level + caster.get_level() * level_add
