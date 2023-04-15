class_name ProjectileType

var _speed: float
var _hit_handler: Callable = Callable()
var _lifetime: float = 0.0
var _sprite_path: String = ""
var _explode_on_hit: bool = true


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


func enable_homing(hit_handler: Callable, _mystery_int: int):
	_hit_handler = hit_handler
