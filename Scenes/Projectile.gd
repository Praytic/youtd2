class_name Projectile
extends DummyUnit


# Projectile moves towards the target and disappears when it
# reaches the target.


signal target_hit(projectile, target)
signal interpolation_finished(projectile)

const FALLBACK_PROJECTILE_SPRITE: String = "res://Resources/Sprites/Projectiles/DefaultProjectileSprite.tscn"
const PRINT_SPRITE_NOT_FOUND_ERROR: bool = false

var _target: Unit = null
var _last_known_position: Vector2 = Vector2.ZERO
var _speed: float = 100
var _explode_on_hit: bool = true
const CONTACT_DISTANCE: int = 30
var _explosion_scene: PackedScene = preload("res://Scenes/Explosion.tscn")
var _game_scene: Node = null
var _targeted: bool
var _target_position_on_creation: Vector2
var _initial_scale: Vector2

var user_int: int = 0
var user_int2: int = 0
var user_int3: int = 0
var user_real: float = 0.0
var user_real2: float = 0.0
var user_real3: float = 0.0


# TODO: ignore_target_z - ignore target height value,
# projectile flies straight without changing it's height to
# match target height. Probably relevant to air units?
static func create_from_unit_to_unit(type: ProjectileType, caster: Unit, damage_ratio: float, crit_ratio: float, from: Unit, target: Unit, targeted: bool, _ignore_target_z: bool, expire_when_reached: bool) -> Projectile:
	var _projectile_scene: PackedScene = preload("res://Scenes/Projectile.tscn")
	var projectile: Projectile = _projectile_scene.instantiate()

	projectile._speed = type._speed
	projectile._explode_on_hit = type._explode_on_hit

	if !type._hit_handler.is_null():
		projectile.set_event_on_target_hit(type._hit_handler)

	projectile._damage_ratio = damage_ratio
	projectile._crit_ratio = crit_ratio
	projectile._caster = caster
	projectile._target = target
	projectile._targeted = targeted
	projectile.position = from.get_visual_position()
	projectile._game_scene = caster.get_tree().get_root().get_node("GameScene")

	projectile._target_position_on_creation = target.get_visual_position()

	if type._lifetime > 0.0 && !expire_when_reached:
		projectile._set_lifetime(type._lifetime)

	var sprite_path: String = type._sprite_path
	var sprite_exists: bool = ResourceLoader.exists(sprite_path)
	
	if !sprite_exists:
		if PRINT_SPRITE_NOT_FOUND_ERROR:
			print_debug("Failed to find sprite for projectile. Tried at path:", sprite_path)

		sprite_path = FALLBACK_PROJECTILE_SPRITE

	var sprite_scene: PackedScene = load(sprite_path)
	var sprite: Node = sprite_scene.instantiate()
	projectile.add_child(sprite)

	projectile._game_scene.add_child(projectile)

	return projectile


# TODO: implement actual interpolation, for now calling
# normal create()
static func create_linear_interpolation_from_unit_to_unit(type: ProjectileType, caster: Unit, damage_ratio: float, crit_ratio: float, from: Unit, target: Unit, _z_arc: float, targeted: bool) -> Projectile:
	return create_from_unit_to_unit(type, caster, damage_ratio, crit_ratio, from, target, targeted, false, true)


func _ready():
	_initial_scale = scale

	if _target.is_dead():
		_on_target_death(Event.new(null))
	else:
		_target.death.connect(_on_target_death)


func _process(delta):
#	Move towards target
	var target_pos = _get_target_position()
	var pos_diff = target_pos - position
	var move_delta: float = _speed * delta
	position = Isometric.vector_move_toward(position, target_pos, move_delta)

	var distance: float = Isometric.vector_length(pos_diff)
	var reached_target = distance < CONTACT_DISTANCE

	if reached_target:
		if _target != null:
			target_hit.emit(self, _target)

#			TODO: emit interpolation_finished() signal when
#			interpolation finishes.
			interpolation_finished.emit(self)

		if _explode_on_hit:
			var explosion = _explosion_scene.instantiate()

			if _target != null:
				explosion.position = _target.get_visual_position()
				explosion.z_index = _target.z_index
			else:
				explosion.position = global_position

			_game_scene.add_child(explosion)

		queue_free()


func get_target() -> Unit:
	return _target


# NOTE: unlike buff and unit events, there's no weird stuff
# like trigger chances, so projectile events can be
# implemented as simple signals. These set_event() f-ns are
# still needed to match original API.

func set_event_on_target_hit(handler: Callable):
	target_hit.connect(handler)


func set_event_on_interpolation_finished(handler: Callable):
	interpolation_finished.connect(handler)


func setScale(scale_arg: float):
	scale = _initial_scale * scale_arg


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


func _set_lifetime(lifetime: float):
	var timer: Timer = Timer.new()
	timer.timeout.connect(_on_lifetime_timeout)
	timer.autostart = true
	timer.wait_time = lifetime


func _on_lifetime_timeout():
	queue_free()
