class_name InterpolatedSprite extends Node2D


# Draws an AnimatedSprite2D between two units, or two
# points. You can pass your own custom AnimatedSprite2D to
# create() function.


var _sprite_scene_path: String
var _lifetime: float
var _start_unit: Unit
var _end_unit: Unit
var _last_start_pos: Vector2 = Vector2.ZERO
var _last_end_pos: Vector2 = Vector2.ZERO
var _sprite: AnimatedSprite2D
var _sprite_width: float


@export var _lifetime_timer: Timer


static func create_between_units(sprite_scene_path: String, lifetime: float, start_unit: Unit, end_unit: Unit) -> InterpolatedSprite:
	var interpolated_sprite: InterpolatedSprite = Globals.interpolated_sprite_scene.instantiate()
	interpolated_sprite._sprite_scene_path = sprite_scene_path
	interpolated_sprite._lifetime = lifetime
	interpolated_sprite._start_unit = start_unit
	interpolated_sprite._end_unit = end_unit
	
	return interpolated_sprite


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

	_lifetime_timer.start(_lifetime)
	
	_update_transform()


func _process(_delta: float):
	_update_transform()


func _update_transform():
	if _sprite == null:
		return

# 	NOTE: if either of the units becomes invalid, use last
# 	known position of the unit
	var start_pos: Vector2
	if Utils.unit_is_valid(_start_unit):
		start_pos = _start_unit.get_visual_position()
		_last_start_pos = start_pos
	else:
		start_pos = _last_start_pos

	var end_pos: Vector2
	if Utils.unit_is_valid(_end_unit):
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


func _on_lifetime_timer_timeout():
	queue_free()


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
