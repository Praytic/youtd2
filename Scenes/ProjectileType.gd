class_name ProjectileType

var _speed: float
var _hit_handler: Callable = Callable()
var _lifetime: float = 0.0
var _sprite_path: String = ""
var _explode_on_hit: bool = true
var _cleanup_callable: Callable = Callable()
var _interpolation_finished_callable: Callable = Callable()
var _target_hit_callable: Callable = Callable()


static func create(model: String, lifetime: float, speed: float) -> ProjectileType:
	var pt: ProjectileType = ProjectileType.new()
	pt._speed = speed
	pt._lifetime = lifetime
	pt._sprite_path = model
	
	return pt


static func create_interpolate(model: String, speed: float) -> ProjectileType:
	var pt: ProjectileType = ProjectileType.new()
	pt._speed = speed
	pt._sprite_path = model

	return pt


func disable_explode_on_hit():
	_explode_on_hit = true


# TODO: implement
func disable_explode_on_expiration():
	pass


func enable_homing(hit_handler: Callable, _mystery_float: float):
	_hit_handler = hit_handler


# Example callable:
# func on_cleanup(projectile: Projectile)
func set_event_on_cleanup(callable: Callable):
	_cleanup_callable = callable


# Example callable:
# func on_interpolation_finished(projectile: Projectile, target: Unit)
func set_event_on_interpolation_finished(callable: Callable):
	_interpolation_finished_callable = callable


# Example callable:
# func on_target_hit(projectile: Projectile, target: Unit)
func set_event_on_target_hit(callable: Callable):
	_target_hit_callable = callable
