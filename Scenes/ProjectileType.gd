class_name ProjectileType

var _speed: float
var _range: float = 0.0
var _lifetime: float = 0.0
var _sprite_path: String = ""
var _explode_on_hit: bool = true
var _cleanup_handler: Callable = Callable()
var _interpolation_finished_handler: Callable = Callable()
var _target_hit_handler: Callable = Callable()
var _collision_radius: float = 0.0
var _collision_target_type: TargetType = null
var _collision_handler: Callable = Callable()


# ProjectileType.create() in JASS
static func create(model: String, lifetime: float, speed: float) -> ProjectileType:
	var pt: ProjectileType = ProjectileType.new()
	pt._speed = speed
	pt._lifetime = lifetime
	pt._sprite_path = model
	
	return pt


# ProjectileType.createInterpolate() in JASS
static func create_interpolate(model: String, speed: float) -> ProjectileType:
	var pt: ProjectileType = ProjectileType.new()
	pt._speed = speed
	pt._sprite_path = model

	return pt


# Creates a projectile that will travel for a max of
# range from initial position.
# ProjectileType.createRanged() in JASS
static func create_ranged(model: String, the_range: float, speed: float) -> ProjectileType:
	var pt: ProjectileType = ProjectileType.new()
	pt._speed = speed
	pt._range = the_range
	pt._sprite_path = model
	
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


# TODO: implement
# projectileType.setAcceleration() in JASS
func set_acceleration(_value: float):
	pass
