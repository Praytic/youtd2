class_name Projectile
extends DummyUnit


# Projectile moves towards the target and disappears when it
# reaches the target.

enum MoveType {
	TARGETED,
	FACING,
}


const FALLBACK_PROJECTILE_SPRITE: String = "res://Scenes/Effects/ProjectileVisual.tscn"
const PRINT_SPRITE_NOT_FOUND_ERROR: bool = false

var _move_type: MoveType = MoveType.TARGETED
var _target: Unit = null
var _last_known_position: Vector2 = Vector2.ZERO
var _speed: float = 50
var _explode_on_hit: bool = true
const CONTACT_DISTANCE: int = 15
var _map_node: Node = null
var _targeted: bool
var _target_position_on_creation: Vector2
var _initial_scale: Vector2
var _tower_crit_count: int = 0
var _tower_crit_ratio: float = 0.0
var _interpolation_finished_handler: Callable = Callable()
var _target_hit_handler: Callable = Callable()
var _initial_pos: Vector2
var _range: float = 0.0
var _facing: float = 0.0
var _collision_radius: float = 0.0
var _collision_target_type: TargetType = null
var _collision_handler: Callable = Callable()
var _collision_history: Array[Unit] = []

var user_int: int = 0
var user_int2: int = 0
var user_int3: int = 0
var user_real: float = 0.0
var user_real2: float = 0.0
var user_real3: float = 0.0


# NOTE: Projectile.createFromUnit() in JASS
static func create_from_unit(type: ProjectileType, caster: Unit, from: Unit, facing: float, damage_ratio: float, crit_ratio: float) -> Projectile:
	var projectile: Projectile = _create_internal(type, caster, damage_ratio, crit_ratio, from)

	projectile._move_type = MoveType.FACING
	projectile._facing = deg_to_rad(facing)

#	NOTE: have to use map node as parent for projectiles
#	instead of GameScene. Using GameScene as parent would
#	cause projectiles to continue moving while the game is
#	paused because GameScene and it's children ignore pause
#	mode. Map node is specifically configured to be
#	pausable.
	projectile._map_node.add_child(projectile)

	return projectile


# TODO: ignore_target_z - ignore target height value,
# projectile flies straight without changing it's height to
# match target height. Probably relevant to air units?
# NOTE: Projectile.createFromUnitToUnit() in JASS
static func create_from_unit_to_unit(type: ProjectileType, caster: Unit, damage_ratio: float, crit_ratio: float, from: Unit, target: Unit, targeted: bool, _ignore_target_z: bool, expire_when_reached: bool) -> Projectile:
	var projectile: Projectile = _create_internal(type, caster, damage_ratio, crit_ratio, from)

	projectile._move_type = MoveType.TARGETED
	projectile._target = target
	projectile._targeted = targeted
	projectile._target_position_on_creation = target.get_visual_position()
	if type._lifetime > 0.0 && !expire_when_reached:
		projectile._set_lifetime(type._lifetime)

	projectile._map_node.add_child(projectile)

	return projectile


# TODO: implement actual interpolation, for now calling
# normal create()
# NOTE: Projectile.createLinearInterpolationFromUnitToUnit() in JASS
static func create_linear_interpolation_from_unit_to_unit(type: ProjectileType, caster: Unit, damage_ratio: float, crit_ratio: float, from: Unit, target: Unit, _z_arc: float, targeted: bool) -> Projectile:
	return create_from_unit_to_unit(type, caster, damage_ratio, crit_ratio, from, target, targeted, false, true)


# TODO: implement
# NOTE: Projectile.createBezierInterpolationFromUnitToUnit() in JASS
static func create_bezier_interpolation_from_unit_to_unit(type: ProjectileType, caster: Unit, damage_ratio: float, crit_ratio: float, from: Unit, target: Unit, _z_arc: float, _side_arc: float, _steepness: float, targeted: bool) -> Projectile:
	return create_from_unit_to_unit(type, caster, damage_ratio, crit_ratio, from, target, targeted, false, true)


static func _create_internal(type: ProjectileType, caster: Unit, damage_ratio: float, crit_ratio: float, from: Unit) -> Projectile:
	var projectile: Projectile = Globals.projectile_scene.instantiate()

	projectile._speed = type._speed
	projectile._explode_on_hit = type._explode_on_hit

	projectile._cleanup_handler = type._cleanup_handler
	projectile._interpolation_finished_handler = type._interpolation_finished_handler
	projectile._target_hit_handler = type._target_hit_handler
	projectile._collision_handler = type._collision_handler
	projectile._range = type._range
	projectile._collision_radius = type._collision_radius
	projectile._collision_target_type = type._collision_target_type
	projectile._damage_bonus_to_size_map = type._damage_bonus_to_size_map

	projectile._damage_ratio = damage_ratio
	projectile._crit_ratio = crit_ratio
	projectile._caster = caster
	projectile.position = from.get_visual_position()
	projectile._initial_pos = from.get_visual_position()
	projectile._map_node = caster.get_tree().get_root().get_node("GameScene/Map")

	var handler_list: Array[Callable] = [
		projectile._cleanup_handler,
		projectile._interpolation_finished_handler,
		projectile._target_hit_handler,
		projectile._collision_handler,
		]

	for handler in handler_list:
		if !handler.is_valid():
			continue

		projectile._connect_to_handler_tree_exited_signal(handler)

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


func _ready():
	super()

	_initial_scale = scale

	if _move_type == MoveType.TARGETED:
		_target.tree_exited.connect(_on_target_tree_exited)
		
		if _target.is_dead():
			_on_target_death(Event.new(null))
		else:
			_target.death.connect(_on_target_death)


func _process(delta):
	match _move_type:
		MoveType.TARGETED: _process_targeted(delta)
		MoveType.FACING: _process_facing(delta)


func _process_targeted(delta: float):
	_do_collision()

#	Move towards target
	var target_pos = _get_target_position()
	var move_delta: float = _speed * delta
	position = Isometric.vector_move_toward(position, target_pos, move_delta)

	var distance: float = Isometric.vector_distance_to(target_pos, position)
	var reached_target = distance < CONTACT_DISTANCE

	if reached_target:
		if _target != null:
			if _target_hit_handler.is_valid():
				_target_hit_handler.call(self, _target)

			if _interpolation_finished_handler.is_valid():
				_interpolation_finished_handler.call(self, _target)

		if _explode_on_hit:
			var explosion = Globals.explosion_scene.instantiate()

			if _target != null:
				explosion.position = _target.get_visual_position()
				explosion.z_index = _target.z_index
			else:
				explosion.position = global_position

			_map_node.add_child(explosion)

		_cleanup()


func _process_facing(delta: float):
	_do_collision()

	var move_vector: Vector2 = Vector2.from_angle(_facing) * _speed * delta
	position += move_vector

	var current_travel_distance: float = Isometric.vector_distance_to(_initial_pos, position)
	var travel_complete: bool = current_travel_distance > _range

	if travel_complete:
		_cleanup()


func get_target() -> Unit:
	return _target


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


func _get_target_position() -> Vector2:
	if _targeted:
		if _target != null:
			var target_pos: Vector2 = _target.get_visual_position()

			return target_pos
		else:
			return _last_known_position
	else:
		return _target_position_on_creation


func _on_target_death(_event: Event):
	_last_known_position = _get_target_position()
	_target = null


func _on_target_tree_exited():
	_cleanup()


func _set_lifetime(lifetime: float):
	var timer: Timer = Timer.new()
	timer.timeout.connect(_on_lifetime_timeout)
	timer.autostart = true
	timer.wait_time = lifetime


func _on_lifetime_timeout():
	queue_free()


func _do_collision():
	if !_collision_handler.is_valid():
		return

	var units_in_range: Array[Unit] = Utils.get_units_in_range(_collision_target_type, global_position, _collision_radius)

# 	Remove units that have already collided. This way, we
# 	collide only once per unit.
	for unit in _collision_history:
		units_in_range.erase(unit)

	var collided_list: Array = units_in_range

	for unit in collided_list:
		_collision_handler.call(self, unit)
		_collision_history.append(unit)
