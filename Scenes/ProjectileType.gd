class_name ProjectileType extends Node

var _speed: float
var _range: float = 0.0
var _lifetime: float = 0.0
var _sprite_path: String = ""
var _explode_on_hit: bool = true
var _cleanup_handler: Callable = Callable()
var _interpolation_finished_handler: Callable = Callable()
var _target_hit_handler: Callable = Callable()
var _expiration_handler: Callable = Callable()
var _collision_radius: float = 0.0
var _collision_target_type: TargetType = null
var _collision_handler: Callable = Callable()
var _damage_bonus_to_size_map: Dictionary = {}


func _init():
	#	NOTE: fix "unused" warning
	_damage_bonus_to_size_map = _damage_bonus_to_size_map


# ProjectileType.create() in JASS
static func create(model: String, lifetime: float, speed: float, parent: Node) -> ProjectileType:
	var pt: ProjectileType = ProjectileType.new()
	pt._speed = speed
	pt._lifetime = lifetime
	pt._sprite_path = model
	parent.add_child(pt)
	
	return pt


# ProjectileType.createInterpolate() in JASS
static func create_interpolate(model: String, speed: float, parent: Node) -> ProjectileType:
	var pt: ProjectileType = ProjectileType.new()
	pt._speed = speed
	pt._sprite_path = model
	parent.add_child(pt)

	return pt


# Creates a projectile that will travel for a max of
# range from initial position.
# ProjectileType.createRanged() in JASS
static func create_ranged(model: String, the_range: float, speed: float, parent: Node) -> ProjectileType:
	var pt: ProjectileType = ProjectileType.new()
	pt._speed = speed
	pt._range = the_range
	pt._sprite_path = model
	parent.add_child(pt)
	
	return pt


# projectileType.disableExplodeOnHit() in JASS
func disable_explode_on_hit():
	_explode_on_hit = true


# TODO: implement
# projectileType.disableExplodeOnExpiration() in JASS
func disable_explode_on_expiration():
	pass


# projectileType.enableCollision() in JASS
func enable_collision(handler: Callable, radius: float, target_type: TargetType, _mystery_bool: bool):
	_collision_handler = handler
	_collision_radius = radius
	_collision_target_type = target_type


# projectileType.enableHoming() in JASS
func enable_homing(target_hit_handler: Callable, _mystery_float: float):
	_target_hit_handler = target_hit_handler


# Example handler:
# func on_cleanup(projectile: Projectile)
# projectileType.setEventOnCleanup() in JASS
func set_event_on_cleanup(handler: Callable):
	_cleanup_handler = handler


# Example handler:
# func on_interpolation_finished(projectile: Projectile, target: Unit)
# projectileType.setEventOnInterpolationFinished() in JASS
func set_event_on_interpolation_finished(handler: Callable):
	_interpolation_finished_handler = handler


# This handler will be called when projectile's lifetime
# timer expires or when projectile travels for the defined
# range.
# Example handler:
# func on_expiration(projectile: Projectile)
# projectileType.setEventOnExpiration() in JASS
func set_event_on_expiration(handler: Callable):
	_expiration_handler = handler


# TODO: implement
# projectileType.setAcceleration() in JASS
func set_acceleration(_value: float):
	pass


# NOTE: DamageTable.setBonusToSize() in JASS
func set_bonus_to_size(creep_size: CreepSize.enm, bonus: float):
	_damage_bonus_to_size_map[creep_size] = bonus
