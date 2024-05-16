class_name InterpolatedSprite extends Node2D


# Draws an AnimatedSprite2D between two units, or two
# points. You can pass your own custom AnimatedSprite2D to
# create() function.

# NOTE: this is the analog of Lightning class in JASS
# Lightning.createFromUnitToUnit() in JASS
# Lightning.createFromUnitToPoint() in JASS
# Lightning.createFromPointToUnit() in JASS
# Lightning.createFromPointToPoint() in JASS
# Instead do this:
# InterpolatedSprite.create_from_unit_to_unit(InterpolatedSprite.LIGHTNING, ...)


const LIGHTNING: String = "res://src/Sprites/LightningAnimation.tscn"

var _sprite_scene_path: String
var _start_unit: Unit
var _end_unit: Unit
var _last_start_pos: Vector2 = Vector2.ZERO
var _last_end_pos: Vector2 = Vector2.ZERO
var _sprite: AnimatedSprite2D
var _sprite_width: float
var _lifetime_timer: ManualTimer


#########################
###     Built-in      ###
#########################

func _ready():
	var sprite_scene: PackedScene = load(_sprite_scene_path)
	var sprite = sprite_scene.instantiate()

	if !sprite is AnimatedSprite2D:
		push_error("InterpolatedSprite must receive a scene for AnimatedSprite2D type. Invalid scene: ", _sprite_scene_path)
		_sprite = null

		return

	_sprite = sprite as AnimatedSprite2D
	add_child(_sprite)

	_sprite_width = _get_sprite_width()

	_lifetime_timer = ManualTimer.new()
	_lifetime_timer.timeout.connect(_on_lifetime_timer_timeout)
	add_child(_lifetime_timer)
	
	_update_transform()


func _process(_delta: float):
	_update_transform()


#########################
###      Private      ###
#########################

func _update_transform():
	if _sprite == null:
		return

# 	NOTE: if either of the units becomes invalid, use last
# 	known position of the unit
# 	NOTE: use is_instance_valid() instead of
# 	Utils.unit_is_valid() because we also want to keep track
# 	of positions of dead units
	var start_pos: Vector2
	if is_instance_valid(_start_unit):
		start_pos = _start_unit.get_visual_position()
		_last_start_pos = start_pos
	else:
		start_pos = _last_start_pos

	var end_pos: Vector2
	if is_instance_valid(_end_unit):
		end_pos = _end_unit.get_visual_position()
		_last_end_pos = end_pos
	else:
		end_pos = _last_end_pos
	
	var diff_vector: Vector2 = end_pos - start_pos
	var middle: Vector2 = start_pos + diff_vector / 2
	
	var sprite_target_width: float = diff_vector.length()
	var sprite_scale: float = sprite_target_width / _sprite_width
	scale.x = sprite_scale
#	NOTE: make the line a bit wider if it's very long
	scale.y = max(1.0, sqrt(sprite_scale))
	
	position = middle
	rotation = diff_vector.angle()

func _get_sprite_width() -> float:
	var sprite_frames: SpriteFrames = _sprite.sprite_frames
	var animation_list: Array = sprite_frames.get_animation_names()
	
	if animation_list.is_empty():
		return 0
	
	var animation: String = animation_list[0]
	var frame_count: int = sprite_frames.get_frame_count(animation)
	
	if frame_count == 0:
		return 0
	
	var texture: Texture2D = sprite_frames.get_frame_texture(animation, 0)
	var texture_width: float = texture.get_size().x
	
	return texture_width


#########################
###     Callbacks     ###
#########################

func _on_lifetime_timer_timeout():
	queue_free()


#########################
### Setters / Getters ###
#########################

func set_lifetime(lifetime: float):
	_lifetime_timer.start(lifetime)


#########################
###       Static      ###
#########################

static func create_from_unit_to_unit(sprite_scene_path: String, start_unit: Unit, end_unit: Unit) -> InterpolatedSprite:
	var interpolated_sprite: InterpolatedSprite = InterpolatedSprite._create_internal(sprite_scene_path, start_unit, end_unit, Vector3.ZERO, Vector3.ZERO)
	
	return interpolated_sprite


static func create_from_point_to_point(sprite_scene_path: String, start_pos: Vector3, end_pos: Vector3) -> InterpolatedSprite:
	var interpolated_sprite: InterpolatedSprite = InterpolatedSprite._create_internal(sprite_scene_path, null, null, start_pos, end_pos)
	
	return interpolated_sprite


static func create_from_unit_to_point(sprite_scene_path: String, start_unit: Unit, end_pos: Vector3) -> InterpolatedSprite:
	var interpolated_sprite: InterpolatedSprite = InterpolatedSprite._create_internal(sprite_scene_path, start_unit, null, Vector3.ZERO, end_pos)
	
	return interpolated_sprite



static func create_from_point_to_unit(sprite_scene_path: String, start_pos: Vector3, end_unit: Unit) -> InterpolatedSprite:
	var interpolated_sprite: InterpolatedSprite = InterpolatedSprite._create_internal(sprite_scene_path, null, end_unit, start_pos, Vector3.ZERO)
	
	return interpolated_sprite


static func _create_internal(sprite_scene_path: String, start_unit: Unit, end_unit: Unit, start_pos_3d: Vector3, end_pos_3d: Vector3) -> InterpolatedSprite:
	var start_pos: Vector2 = VectorUtils.wc3_to_canvas(start_pos_3d)
	var end_pos: Vector2 = VectorUtils.wc3_to_canvas(end_pos_3d)

	var interpolated_sprite: InterpolatedSprite = InterpolatedSprite.new()
	interpolated_sprite._sprite_scene_path = sprite_scene_path
	interpolated_sprite._start_unit = start_unit
	interpolated_sprite._end_unit = end_unit
	interpolated_sprite._last_start_pos = start_pos
	interpolated_sprite._last_end_pos = end_pos
	interpolated_sprite.z_index = 1000

	Utils.add_object_to_world(interpolated_sprite)

	return interpolated_sprite
