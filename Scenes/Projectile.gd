class_name Projectile
extends DummyUnit


# Projectile are moving objects which have an origin and can
# be setup to move towards a point or unit. The most common
# use case is to fire a projectile from a tower towards a
# creep to deal damage.

enum MoveType {
	NORMAL,
	INTERPOLATED,
}


const FALLBACK_PROJECTILE_SPRITE: String = "res://Scenes/Effects/ProjectileVisual.tscn"
const PRINT_SPRITE_NOT_FOUND_ERROR: bool = false

var _move_type: MoveType
var _target_unit: Unit = null
var _target_pos: Vector2 = Vector2.ZERO
var _interpolation_is_stopped: bool = false
var _interpolation_start: Vector2
var _interpolation_distance: float
var _interpolation_progress: float = 0
var _z_arc: float = 0
var _is_homing: bool = false
var _homing_control_value: float
var _speed: float = 50
var _acceleration: float = 0
var _explode_on_hit: bool = true
var _explode_on_expiration: bool = true
const CONTACT_DISTANCE: int = 15
var _initial_scale: Vector2
var _tower_crit_count: int = 0
var _tower_crit_ratio: float = 0.0
var _tower_bounce_visited_list: Array[Unit] = []
var _interpolation_finished_handler: Callable = Callable()
var _target_hit_handler: Callable = Callable()
var _periodic_handler: Callable = Callable()
var _avert_destruct_requested: bool = false
var _initial_pos: Vector2
var _range: float = 0.0
var _direction: float = 0.0
var _collision_radius: float = 0.0
var _collision_target_type: TargetType = null
var _collision_handler: Callable = Callable()
var _expiration_handler: Callable = Callable()
var _collision_history: Array[Unit] = []
var _collision_enabled: bool = true
var _periodic_enabled: bool = true

var user_int: int = 0
var user_int2: int = 0
var user_int3: int = 0
var user_real: float = 0.0
var user_real2: float = 0.0
var user_real3: float = 0.0


@export var _lifetime_timer: Timer


#########################
###     Built-in      ###
#########################

func _ready():
	super()

	_initial_scale = scale


func _process(delta):
	match _move_type:
		MoveType.NORMAL: _process_normal(delta)
		MoveType.INTERPOLATED: _process_interpolated(delta)


#########################
###       Public      ###
#########################

func avert_destruction():
	_avert_destruct_requested = true


func stop_interpolation():
	_interpolation_is_stopped = true
	set_homing_target(null)
	_interpolation_progress = 0
	_interpolation_distance = 0


func start_interpolation_to_point(target_pos: Vector2, _z_arc_arg: float):
	var target_unit: Unit = null
	var targeted: bool = false
	_start_interpolation_internal(target_unit, target_pos, targeted)


func start_interpolation_to_unit(target_unit: Unit, _z_arc_arg: float, targeted: bool):
	var target_pos: Vector2 = target_unit.get_visual_position()
	_start_interpolation_internal(target_unit, target_pos, targeted)


func start_bezier_interpolation_to_point(target_pos: Vector2, _z_arc_arg: float, _size_arc: float, _steepness: float):
	var target_unit: Unit = null
	var targeted: bool = false
	_start_interpolation_internal(target_unit, target_pos, targeted)


func start_bezier_interpolation_to_unit(target_unit: Unit, _z_arc_arg: float, _size_arc: float, _steepness: float, targeted: bool):
	var target_pos: Vector2 = target_unit.get_visual_position()
	_start_interpolation_internal(target_unit, target_pos, targeted)


# NOTE: disablePeriodic() in JASS
func disable_periodic():
	_periodic_enabled = false


#########################
###      Private      ###
#########################

func _process_normal(delta: float):
	_do_collision_behavior()

	if _range > 0:
		var travel_vector_isometric: Vector2 = position - _initial_pos
		var travel_vector_top_down: Vector2 = Isometric.isometric_vector_to_top_down(travel_vector_isometric)
		var current_travel_distance: float = travel_vector_top_down.length()
		var travel_complete: bool = current_travel_distance >= _range

		if travel_complete:
			_expire()

			return

	_do_homing_behavior(delta)

# 	Apply acceleration
	var new_speed: float = _speed + _acceleration * delta
	set_speed(new_speed)

#	Move forward, based on current direction
	var target_pos_isometric: Vector2 = _get_target_position()
	var move_vector_top_down: Vector2 = (Vector2(1, 0) * _speed * delta).rotated(deg_to_rad(_direction))
	var move_vector_isometric: Vector2 = Isometric.top_down_vector_to_isometric(move_vector_top_down)

	position += move_vector_isometric

	if _is_homing:
		var reached_target = Isometric.vector_in_range(target_pos_isometric, position, CONTACT_DISTANCE)

		if reached_target:
#			NOTE: finished handler will get called even if
#			target unit is dead and null. This is
#			intentional.
			if _target_hit_handler.is_valid():
				_target_hit_handler.call(self, _target_unit)

#			Handler can request projectile to not destroy
#			itself. In that case do no explosion or cleanup.
			if _avert_destruct_requested:
				_avert_destruct_requested = false

				return

			if _explode_on_hit:
				_do_explosion_visual()

			_cleanup()


func _process_interpolated(delta: float):
	_do_collision_behavior()

	if _interpolation_is_stopped:
		return

	var target_pos: Vector2 = _get_target_position()
	
	_interpolation_progress += _speed * delta
	_interpolation_progress = min(_interpolation_progress, _interpolation_distance)
	var progress_ratio: float = _interpolation_progress / _interpolation_distance
	var current_pos_2d: Vector2 = _interpolation_start.lerp(target_pos, progress_ratio)
	var z_max: float = _z_arc * _interpolation_distance
	var z: float = z_max * sin(progress_ratio * PI)
	var current_pos_3d: Vector3 = Vector3(current_pos_2d.x, current_pos_2d.y, z)
	var current_pos: Vector2 = Isometric.vector3_to_isometric_vector2(current_pos_3d)

#	NOTE: save direction so it can be accessed by users of
#	projectile via get_direction(). Note that unlike normal
#	projectiles, interpolated projectiles don't actually use
#	direction for movement logic.
	var move_vector_isometric: Vector2 = current_pos - position
	var move_vector_top_down: Vector2 = Isometric.isometric_vector_to_top_down(move_vector_isometric)
	_direction = rad_to_deg(move_vector_top_down.angle())

	position = current_pos

	var reached_target: float = progress_ratio == 1.0

	if reached_target:
#		NOTE: need to set _interpolation_is_stopped flag to
#		true here so that we can detect if it got changed by
#		the "finished" handler
		_interpolation_is_stopped = true

#		NOTE: finished handler will get called even if
#		target unit is dead and null. This is intentional.
		if _interpolation_finished_handler.is_valid():
			_interpolation_finished_handler.call(self, _target_unit)

#		Handler can request projectile to not destroy
#		itself. In that case do no explosion or cleanup.
		if _avert_destruct_requested:
			_avert_destruct_requested = false

#			NOTE: only stop interpolation here if
#			_interpolation_is_stopped is still true. If it
#			is false, then it got changed by the code inside
#			"finished" handler, which happens when
#			"finished" handler starts a new interpolation
#			after averting destruction.
			if _interpolation_is_stopped:
				stop_interpolation()

			return

		if _explode_on_hit:
			_do_explosion_visual()

		_cleanup()


func _do_collision_behavior():
	if !_collision_enabled:
		return

	if !_collision_handler.is_valid():
		return

	var units_in_range: Array[Unit] = Utils.get_units_in_range(_collision_target_type, global_position, _collision_radius)

# 	Remove units that have already collided. This way, we
# 	collide only once per unit.
	for unit in _collision_history:
		if !Utils.unit_is_valid(unit):
			continue

		units_in_range.erase(unit)

	var collided_list: Array = units_in_range

	for unit in collided_list:
		_collision_handler.call(self, unit)
		_collision_history.append(unit)


# Homing behavior is implemented here. If target pos or
# target unit is defined, the projectile will turn to face
# towards it.
func _do_homing_behavior(delta: float):
	var target_pos_isometric: Vector2 = _get_target_position()

	if !_is_homing:
		return

	var turn_instantly: float = _homing_control_value == 0
	var target_pos: Vector2 = Isometric.isometric_vector_to_top_down(target_pos_isometric)
	var projectile_pos: Vector2 = Isometric.isometric_vector_to_top_down(position)
	var desired_direction_vector: Vector2 = target_pos - projectile_pos
	var desired_direction: float = rad_to_deg(desired_direction_vector.angle())

	if turn_instantly:
		set_direction(desired_direction)

		return

	var current_direction_vector: Vector2 = Vector2.from_angle(deg_to_rad(_direction))
	var direction_diff: float = rad_to_deg(current_direction_vector.angle_to(desired_direction_vector))
	var turn_amount: float = sign(direction_diff) * min(rad_to_deg(_homing_control_value) * delta, abs(direction_diff))
	var new_direction: float = _direction + turn_amount
	
	set_direction(new_direction)


func _expire():
	if _expiration_handler.is_valid():
		_expiration_handler.call(self)

	if _explode_on_expiration:
		_do_explosion_visual()

	_cleanup()


# NOTE: angle should be in degrees. Normalizes the angle to
# [-180, 180] range to match convention used by Vector2
# functions. For example, 220 would be converted to -140.
func _normalize_angle(angle: float) -> float:
	var normalized_angle: float
	if angle > 180:
		normalized_angle = angle - 360
	elif angle < -180:
		normalized_angle = angle + 360
	else:
		normalized_angle = angle

	return normalized_angle


static func _get_direction_to_target(projectile: Projectile, target_pos: Vector2) -> float:
	var target_pos_isometric: Vector2 = target_pos
	var projectile_pos_top_down: Vector2 = Isometric.isometric_vector_to_top_down(projectile.position)
	var target_pos_top_down: Vector2 = Isometric.isometric_vector_to_top_down(target_pos_isometric)
	var angle_to_target_pos: float = projectile_pos_top_down.angle_to_point(target_pos_top_down)
	var direction: float = rad_to_deg(angle_to_target_pos)
	
	return direction


# NOTE: before this f-n is called, projectile must be added
# to world and have a valid position
func _start_interpolation_internal(target_unit: Unit, target_pos: Vector2, targeted: bool):
	if target_unit != null:
		target_pos = target_unit.get_visual_position()

	if target_unit != null:
#		NOTE: if projectile has a target but is not
#		targeted, then it will travel towards the position
#		at which the target was during projectile's
#		creation. It will not follow target's movement.
		if targeted:
			set_homing_target(target_unit)
		else:
			_target_pos = target_pos
	else:
		set_homing_target(null)
		_target_pos = target_pos

	var from_pos: Vector2 = position
	_interpolation_start = from_pos

	_interpolation_is_stopped = false

	var travel_vector_isometric: Vector2 = target_pos - from_pos
	var travel_vector_top_down: Vector2 = Isometric.isometric_vector_to_top_down(travel_vector_isometric)
	var travel_distance: float = travel_vector_top_down.length()
	_interpolation_progress = 0
	_interpolation_distance = travel_distance


func _do_explosion_visual():
	var explosion = Globals.explosion_scene.instantiate()
	explosion.position = position
	Utils.add_object_to_world(explosion)


# Returns target position which is equal to current position
# of target unit. If target unit dies, then this function
# will return the last position of target unit.
func _get_target_position() -> Vector2:
	if _target_unit != null:
		var target_unit_pos: Vector2 = _target_unit.get_visual_position()

		return target_unit_pos
	else:
		return _target_pos


func _clear_target():
	_target_pos = _target_unit.get_visual_position()
	_target_unit.death.disconnect(_on_target_death)
	_target_unit.tree_exiting.disconnect(_on_target_tree_exiting)
	_target_unit = null


#########################
###     Callbacks     ###
#########################

func _on_periodic_timer_timeout():
	if !_periodic_enabled:
		return

	if _periodic_handler.is_valid():
		_periodic_handler.call(self)


func _on_target_death(_event: Event):
	_clear_target()


# NOTE: we need to clear target both on death() and on
# tree_exiting() signal because creeps get removed from the
# game without dying, when they reach the portal.
func _on_target_tree_exiting():
	_clear_target()


func _on_projectile_type_tree_exited():
	_cleanup()


func _on_lifetime_timer_timeout():
	_expire()


#########################
### Setters / Getters ###
#########################

# NOTE: getHomingTarget() in JASS
func get_target() -> Unit:
	return _target_unit


# NOTE: projectile.setScale() in JASS
func setScale(scale_arg: float):
	scale = _initial_scale * scale_arg


func get_tower_crit_count() -> int:
	return _tower_crit_count


func set_tower_crit_count(tower_crit_count: int):
	_tower_crit_count = tower_crit_count


func get_tower_crit_ratio() -> float:
	return _tower_crit_ratio


func set_tower_crit_ratio(tower_crit_ratio: float):
	_tower_crit_ratio = tower_crit_ratio


func get_tower_bounce_visited_list() -> Array[Unit]:
	return _tower_bounce_visited_list


# Returns current direction of projectile's movement. In
# degrees and from top down perspective.
# NOTE: projectile.direction in JASS
func get_direction() -> float:
	return _direction


# Sets direction of projectile. In degrees and top down
# perspective.
# NOTE: this f-n must be used instead of modifying the value
# directly. This is to ensure that direction is always
# normalized.
func set_direction(direction: float):
	_direction = _normalize_angle(direction)


func get_x() -> float:
	return position.x


func get_y() -> float:
	return position.y


func get_z() -> float:
	return 0.0


func get_speed() -> float:
	return _speed


func set_speed(new_speed: float):
	_speed = clampf(new_speed, 0, Constants.PROJECTILE_SPEED_MAX)


func set_acceleration(new_acceleration: float):
	_acceleration = new_acceleration


# NOTE: if new target is null, then homing is disabled
func set_homing_target(new_target: Unit):
	var old_target: Unit = _target_unit

	if old_target != null && old_target.death.is_connected(_on_target_death):
		old_target.death.disconnect(_on_target_death)

	if new_target != null:
#		NOTE: need to check for target death here because a
#		projectile may be launched towards a dead target.
#		For example if some other part of tower script
#		killed the target right before projectile was
#		created. In such cases, projectile will move to the
#		position where target was during death.
		if !new_target.is_dead():
			if !new_target.death.is_connected(_on_target_death):
				new_target.death.connect(_on_target_death)

			if !new_target.tree_exiting.is_connected(_on_target_tree_exiting):
				new_target.tree_exiting.connect(_on_target_tree_exiting)

			_target_unit = new_target
		else:
			_target_unit = null
			_target_pos = new_target.get_visual_position()

		_is_homing = true
	else:
		_target_unit = null
		_target_pos = Vector2.ZERO
		_is_homing = false


# NOTE: setCollisionEnabled() in JASS
func set_collision_enabled(enabled: bool):
	_collision_enabled = enabled


func set_remaining_lifetime(new_lifetime: float):
	if is_inside_tree():
		_lifetime_timer.stop()
		_lifetime_timer.start(new_lifetime)
	else:
		_lifetime_timer.autostart = true
		_lifetime_timer.wait_time = new_lifetime


func set_color(color: Color):
	modulate = color


#########################
###       Static      ###
#########################

# NOTE: Projectile.create() in JASS
static func create(type: ProjectileType, caster: Unit, damage_ratio: float, crit_ratio: float, x: float, y: float, _z: float, facing: float) -> Projectile:
	var initial_position: Vector2 = Vector2(x, y)
	var projectile: Projectile = _create_internal(type, caster, damage_ratio, crit_ratio, initial_position)

	projectile.set_direction(facing)

#	NOTE: have to use map node as parent for projectiles
#	instead of GameScene. Using GameScene as parent would
#	cause projectiles to continue moving while the game is
#	paused because GameScene and it's children ignore pause
#	mode. Map node is specifically configured to be
#	pausable.
	Utils.add_object_to_world(projectile)

	return projectile


# NOTE: Projectile.createFromUnit() in JASS
static func create_from_unit(type: ProjectileType, caster: Unit, from: Unit, facing: float, damage_ratio: float, crit_ratio: float) -> Projectile:
	var pos: Vector2 = from.get_visual_position()
	var z: float = 0.0
	var projectile: Projectile = Projectile.create(type, caster, damage_ratio, crit_ratio, pos.x, pos.y, z, facing)
	
	return projectile


# NOTE: Projectile.createFromPointToPoint() in JASS
static func create_from_point_to_point(type: ProjectileType, caster: Unit, damage_ratio: float, crit_ratio: float, from_pos: Vector2, target_pos: Vector2, _ignore_target_z: bool, expire_when_reached: bool) -> Projectile:
	var from_unit: Unit = null
	var target_unit: Unit = null
	var targeted: bool = false
	var projectile: Projectile = _create_internal_from_to(type, caster, damage_ratio, crit_ratio, from_unit, from_pos, target_unit, target_pos, targeted, expire_when_reached)

	return projectile


# NOTE: Projectile.createFromUnitToPoint() in JASS
static func create_from_unit_to_point(type: ProjectileType, caster: Unit, damage_ratio: float, crit_ratio: float, from_unit: Unit, target_pos: Vector2, _ignore_target_z: bool, expire_when_reached: bool) -> Projectile:
	var from_pos: Vector2 = Vector2.ZERO
	var target_unit: Unit = null
	var targeted: bool = false
	var projectile: Projectile = _create_internal_from_to(type, caster, damage_ratio, crit_ratio, from_unit, from_pos, target_unit, target_pos, targeted, expire_when_reached)

	return projectile


# NOTE: Projectile.createFromPointToUnit() in JASS
static func create_from_point_to_unit(type: ProjectileType, caster: Unit, damage_ratio: float, crit_ratio: float, from_pos: Vector2, target_unit: Unit, targeted: bool, _ignore_target_z: bool, expire_when_reached: bool) -> Projectile:
	var from_unit: Unit = null
	var target_pos: Vector2 = Vector2.ZERO
	var projectile: Projectile = _create_internal_from_to(type, caster, damage_ratio, crit_ratio, from_unit, from_pos, target_unit, target_pos, targeted, expire_when_reached)

	return projectile


# NOTE: Projectile.createFromUnitToUnit() in JASS
static func create_from_unit_to_unit(type: ProjectileType, caster: Unit, damage_ratio: float, crit_ratio: float, from_unit: Unit, target_unit: Unit, targeted: bool, _ignore_target_z: bool, expire_when_reached: bool) -> Projectile:
	var from_pos: Vector2 = Vector2.ZERO
	var target_pos: Vector2 = Vector2.ZERO
	var projectile: Projectile = _create_internal_from_to(type, caster, damage_ratio, crit_ratio, from_unit, from_pos, target_unit, target_pos, targeted, expire_when_reached)

	return projectile


# NOTE: Projectile.createLinearInterpolationFromPointToPoint() in JASS
static func create_linear_interpolation_from_point_to_point(type: ProjectileType, caster: Unit, damage_ratio: float, crit_ratio: float, from_pos: Vector2, target_pos: Vector2, z_arc: float) -> Projectile:
	var from_unit: Unit = null
	var target_unit: Unit = null
	var targeted: bool = false
	var projectile: Projectile = _create_internal_interpolated(type, caster, damage_ratio, crit_ratio, from_unit, from_pos, target_unit, target_pos, z_arc, targeted)

	return projectile


# NOTE: Projectile.createLinearInterpolationFromPointToUnit() in JASS
static func create_linear_interpolation_from_point_to_unit(type: ProjectileType, caster: Unit, damage_ratio: float, crit_ratio: float, from_pos: Vector2, target_unit: Unit, z_arc: float, targeted: bool) -> Projectile:
	var from_unit: Unit = null
	var target_pos: Vector2 = Vector2.ZERO
	var projectile: Projectile = _create_internal_interpolated(type, caster, damage_ratio, crit_ratio, from_unit, from_pos, target_unit, target_pos, z_arc, targeted)

	return projectile


# NOTE: Projectile.createLinearInterpolationFromUnitToPoint() in JASS
static func create_linear_interpolation_from_unit_to_point(type: ProjectileType, caster: Unit, damage_ratio: float, crit_ratio: float, from_unit: Unit, target_pos: Vector2, z_arc: float) -> Projectile:
	var from_pos: Vector2 = Vector2.ZERO
	var target_unit: Unit = null
	var targeted: bool = false
	var projectile: Projectile = _create_internal_interpolated(type, caster, damage_ratio, crit_ratio, from_unit, from_pos, target_unit, target_pos, z_arc, targeted)

	return projectile


# NOTE: Projectile.createLinearInterpolationFromUnitToUnit() in JASS
static func create_linear_interpolation_from_unit_to_unit(type: ProjectileType, caster: Unit, damage_ratio: float, crit_ratio: float, from_unit: Unit, target_unit: Unit, z_arc: float, targeted: bool) -> Projectile:
	var from_pos: Vector2 = Vector2.ZERO
	var target_pos: Vector2 = Vector2.ZERO
	var projectile: Projectile = _create_internal_interpolated(type, caster, damage_ratio, crit_ratio, from_unit, from_pos, target_unit, target_pos, z_arc, targeted)

	return projectile


# TODO: implement
# NOTE: Projectile.createBezierInterpolationFromUnitToUnit() in JASS
static func create_bezier_interpolation_from_unit_to_unit(type: ProjectileType, caster: Unit, damage_ratio: float, crit_ratio: float, from: Unit, target: Unit, z_arc: float, _side_arc: float, _steepness: float, targeted: bool) -> Projectile:
	return create_linear_interpolation_from_unit_to_unit(type, caster, damage_ratio, crit_ratio, from, target, z_arc, targeted)


static func _create_internal(type: ProjectileType, caster: Unit, damage_ratio: float, crit_ratio: float, initial_pos: Vector2) -> Projectile:
	var projectile: Projectile = Globals.projectile_scene.instantiate()

	projectile.set_speed(type._speed)
	projectile._acceleration = type._acceleration
	projectile._explode_on_hit = type._explode_on_hit
	projectile._explode_on_expiration = type._explode_on_expiration
	projectile._move_type = type._move_type
	projectile._homing_control_value = type._homing_control_value

	projectile._cleanup_handler = type._cleanup_handler
	projectile._interpolation_finished_handler = type._interpolation_finished_handler
	projectile._target_hit_handler = type._target_hit_handler
	projectile._collision_handler = type._collision_handler
	projectile._expiration_handler = type._expiration_handler
	projectile._range = type._range
	projectile._collision_radius = type._collision_radius
	projectile._collision_target_type = type._collision_target_type
	projectile._damage_bonus_to_size_map = type._damage_bonus_to_size_map

	var periodic_handler_is_defined: bool = type._periodic_handler.is_valid() && type._periodic_handler_period > 0
	if periodic_handler_is_defined:
		projectile._periodic_handler = type._periodic_handler
		var timer: Timer = Timer.new()
		timer.wait_time = type._periodic_handler_period
		timer.autostart = true
		timer.timeout.connect(projectile._on_periodic_timer_timeout)
		projectile.add_child(timer)

	projectile._damage_ratio = damage_ratio
	projectile._crit_ratio = crit_ratio
	projectile._caster = caster
	projectile.position = initial_pos
	projectile._initial_pos = initial_pos

	if type._lifetime > 0:
		projectile.set_remaining_lifetime(type._lifetime)

	type.tree_exited.connect(projectile._on_projectile_type_tree_exited)

	var sprite_path: String = type._sprite_path
	var sprite_exists: bool = ResourceLoader.exists(sprite_path)
	
	if !sprite_exists:
		if PRINT_SPRITE_NOT_FOUND_ERROR:
			print_debug("Failed to find sprite for projectile. Tried at path:", sprite_path)

		sprite_path = FALLBACK_PROJECTILE_SPRITE

	var sprite_scene: PackedScene = load(sprite_path)
	var sprite: Node = sprite_scene.instantiate()
	projectile.add_child(sprite)

	return projectile


static func _create_internal_from_to(type: ProjectileType, caster: Unit, damage_ratio: float, crit_ratio: float, from_unit: Unit, from_pos: Vector2, target_unit: Unit, target_pos: Vector2, targeted: bool, expire_when_reached: bool) -> Projectile:
	if from_unit != null:
		from_pos = from_unit.get_visual_position()

	if target_unit != null:
		target_pos = target_unit.get_visual_position()

	var projectile: Projectile = _create_internal(type, caster, damage_ratio, crit_ratio, from_pos)

#	NOTE: if projectile has a target but is not targeted,
#	then it will travel towards the position at which the
#	target was during projectile's creation. It will not
#	follow target's movement.
	if target_unit != null && targeted:
		projectile.set_homing_target(target_unit)
	else:
		projectile._target_pos = target_pos

	var initial_direction: float = _get_direction_to_target(projectile, target_pos)
	projectile.set_direction(initial_direction)

	if expire_when_reached:
		var travel_vector_isometric: Vector2 = target_pos - from_pos
		var travel_vector_top_down: Vector2 = Isometric.isometric_vector_to_top_down(travel_vector_isometric)
		var travel_distance: float = travel_vector_top_down.length()
		var time_until_reached: float = travel_distance / projectile._speed
		projectile.set_remaining_lifetime(time_until_reached)

	Utils.add_object_to_world(projectile)

	return projectile


static func _create_internal_interpolated(type: ProjectileType, caster: Unit, damage_ratio: float, crit_ratio: float, from_unit: Unit, from_pos: Vector2, target_unit: Unit, target_pos: Vector2, z_arc: float, targeted: bool) -> Projectile:
	if from_unit != null:
		from_pos = from_unit.get_visual_position()

	var projectile: Projectile = _create_internal(type, caster, damage_ratio, crit_ratio, from_pos)

	projectile._z_arc = z_arc

	Utils.add_object_to_world(projectile)

	projectile._start_interpolation_internal(target_unit, target_pos, targeted)

	return projectile
