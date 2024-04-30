class_name Map extends Node2D


@export var play_area: Area2D
@export var play_area_shape: CollisionShape2D
@export var _black_border: Node2D
@export var _buildable_area: TileMap
@export var _prerendered_background: Node2D
@export var _foreground_map: TileMap
@export var _ground_indicator_map: TileMap

const BUILDABLE_PULSE_ALPHA_MIN = 0.1
const BUILDABLE_PULSE_ALPHA_MAX = 0.5
const BUILDABLE_PULSE_PERIOD = 1.0


#########################
###     Built-in      ###
#########################

func _ready():
	var camera: Camera2D = get_viewport().get_camera_2d()
	var s = play_area.scale
	var ss = play_area_shape.scale
	var ps = get_play_area_size()
	var pp = get_play_area_pos()
	camera.limit_bottom = pp.y + ps.y / 2 * s.y * ss.y
	camera.limit_top = pp.y - ps.y / 2 * s.y * ss.y
	camera.limit_left = pp.x - ps.x / 2 * s.x * ss.x
	camera.limit_right = pp.x + ps.x / 2 * s.x * ss.x
	camera.position = pp
	print_verbose("Set camera limits to [lb: %s, lt: %s, ll: %s, lr: %s] and pos [%s]" \
		% [camera.limit_bottom, camera.limit_top, camera.limit_left, camera.limit_right, pp])
	
#	Make buildable area pulse by tweening it's alpha between
#	min and max
	var buildable_area_tween = create_tween()
	buildable_area_tween.tween_property(_buildable_area, "modulate",
		Color(1.0, 1.0, 1.0, BUILDABLE_PULSE_ALPHA_MIN),
		0.5 * BUILDABLE_PULSE_PERIOD).set_trans(Tween.TRANS_LINEAR)
	buildable_area_tween.tween_property(_buildable_area, "modulate",
		Color(1.0, 1.0, 1.0, BUILDABLE_PULSE_ALPHA_MAX),
		0.5 * BUILDABLE_PULSE_PERIOD).set_trans(Tween.TRANS_LINEAR).set_delay(0.5 * BUILDABLE_PULSE_PERIOD)
	buildable_area_tween.set_loops()

	_prerendered_background.visible = Config.use_prerendered_background()

#	NOTE: create real tilemap if not using prerendered
#	version. We do this here instead of in scene to avoid
#	the real tilemap eating VRAM while being hidden.
	if !Config.use_prerendered_background():
		print_verbose("Using raw map (not prerendered)")
		var background_map_scene: PackedScene = load("res://Scenes/Map/BackgroundMap.tscn")
		var background_map = background_map_scene.instantiate()
		_buildable_area.add_sibling(background_map)
	else:
		print_verbose("Using prerendered map")


#########################
###       Public      ###
#########################

func get_buildable_cells() -> Array[Vector2i]:
	var buildable_cells: Array[Vector2i] = _buildable_area.get_used_cells(0)

	return buildable_cells


func setup_for_prerendering():
	_prerendered_background.hide()
	_black_border.hide()
	_foreground_map.hide()


func get_play_area_size() -> Vector2:
	return play_area_shape.get_shape().size


func get_play_area_pos() -> Vector2:
	return play_area_shape.global_position


func pos_is_on_ground(pos: Vector2) -> bool:
	var map_pos = _ground_indicator_map.local_to_map(pos)
	var tile_data_at_pos: TileData = _ground_indicator_map.get_cell_tile_data(0, map_pos)
	var tile_exists: bool = tile_data_at_pos != null

	return tile_exists


func set_buildable_area_visible(value: bool):
	_buildable_area.visible = value
