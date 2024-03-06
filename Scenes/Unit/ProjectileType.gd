class_name ProjectileType extends Node

var _move_type: Projectile.MoveType
var _speed: float
var _acceleration: float = 0.0
var _homing_control_value: float
var _range: float = 0.0
var _lifetime: float = 0.0
var _sprite_path: String = ""
var _explode_on_hit: bool = true
var _explode_on_expiration: bool = true
var _cleanup_handler: Callable = Callable()
var _interpolation_finished_handler: Callable = Callable()
var _target_hit_handler: Callable = Callable()
var _periodic_handler: Callable = Callable()
var _periodic_handler_period: float = 0.0
var _expiration_handler: Callable = Callable()
var _collision_radius: float = 0.0
var _collision_target_type: TargetType = null
var _destroy_on_collision: bool = false
var _collision_handler: Callable = Callable()
var _damage_bonus_to_size_map: Dictionary = {}


#########################
###     Built-in      ###
#########################

func _init():
	#	NOTE: fix "unused" warning
	_damage_bonus_to_size_map = _damage_bonus_to_size_map


#########################
###       Public      ###
#########################

# projectileType.disableExplodeOnHit() in JASS
func disable_explode_on_hit():
	_explode_on_hit = false


# projectileType.disableExplodeOnExpiration() in JASS
func disable_explode_on_expiration():
	_explode_on_expiration = false


# projectileType.enableCollision() in JASS
func enable_collision(handler: Callable, radius: float, target_type: TargetType, destroy_on_collision: bool):
	_collision_handler = handler
	_collision_radius = radius
	_collision_target_type = target_type
	_destroy_on_collision = destroy_on_collision


# "homing_control_value" determines how fast the projectile
# will turn towards the homing target. This value is in
# degrees per second. If you set homing_control_value it too
# low, then the projectile can miss the target!
# 
# Set homing_control_value to 0 to make the projectile turn
# instantly towards the target.
# 
# NOTE: target hit handler will still get called if target
# died. In that case, target argument will be null so you
# need to do a null check if you use the target.
# 
# projectileType.enableHoming() in JASS
func enable_homing(target_hit_handler: Callable, homing_control_value: float):
	_target_hit_handler = target_hit_handler
	_homing_control_value = homing_control_value


# Example handler:
# func periodic_handler(p: Projectile)
# NOTE: projectileType.enable_periodic() in JASS
func enable_periodic(handler: Callable, period: float):
	_periodic_handler = handler
	_periodic_handler_period = period


#########################
### Setters / Getters ###
#########################

# Example handler:
# func on_cleanup(projectile: Projectile)
# projectileType.setEventOnCleanup() in JASS
func set_event_on_cleanup(handler: Callable):
	_cleanup_handler = handler


# NOTE: finished handler will still get called if target
# died. In that case, target argument will be null so you
# need to do a null check if you use the target.
# 
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


# projectileType.setAcceleration() in JASS
func set_acceleration(value: float):
	_acceleration = value


# NOTE: DamageTable.setBonusToSize() in JASS
func set_bonus_to_size(creep_size: CreepSize.enm, bonus: float):
	_damage_bonus_to_size_map[creep_size] = bonus


#########################
###       Static      ###
#########################

# ProjectileType.create() in JASS
static func create(model: String, lifetime: float, speed: float, parent: Node) -> ProjectileType:
	var pt: ProjectileType = ProjectileType.new()
	pt._move_type = Projectile.MoveType.NORMAL
	pt._speed = speed
	pt._lifetime = lifetime
	pt._sprite_path = model
	parent.add_child(pt)
	
	return pt


# ProjectileType.createInterpolate() in JASS
static func create_interpolate(model: String, speed: float, parent: Node) -> ProjectileType:
	var pt: ProjectileType = ProjectileType.new()
	pt._move_type = Projectile.MoveType.INTERPOLATED
	pt._speed = speed
	pt._sprite_path = model
	parent.add_child(pt)

	return pt


# Creates a projectile that will travel for a max of
# range from initial position.
# ProjectileType.createRanged() in JASS
static func create_ranged(model: String, the_range: float, speed: float, parent: Node) -> ProjectileType:
	var pt: ProjectileType = ProjectileType.new()
	pt._move_type = Projectile.MoveType.NORMAL
	pt._speed = speed
	pt._range = the_range
	pt._sprite_path = model
	parent.add_child(pt)
	
	return pt
