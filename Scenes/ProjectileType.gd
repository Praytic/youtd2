class_name ProjectileType

var _speed: float
var _hit_handler: Callable = Callable()
var _lifetime: float = 0.0


# TODO: use model. Currently using placeholder sprite.
static func create(_model: String, lifetime: float, speed: float) -> ProjectileType:
	var pt: ProjectileType = ProjectileType.new()
	pt._speed = speed
	pt._lifetime = lifetime
	
	return pt


static func create_interpolate(_model: String, speed: float) -> ProjectileType:
	var pt: ProjectileType = ProjectileType.new()
	pt._speed = speed

	return pt


# TODO: implement
func enable_free_rotation():
	pass


# TODO: implement
func disable_explode_on_hit():
	pass


func enable_homing(hit_handler: Callable, _mystery_int: int):
	_hit_handler = hit_handler
