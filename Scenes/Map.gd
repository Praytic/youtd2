extends Node2D


@export var play_area: Area2D
@export var play_area_shape: CollisionShape2D
@export var _black_border: Node2D
@export var _buildable_area: TileMap
@export var _prerendered_background: Node2D
@export var _foreground_map: TileMap

const BUILDABLE_PULSE_ALPHA_MIN = 0.1
const BUILDABLE_PULSE_ALPHA_MAX = 0.5
const BUILDABLE_PULSE_PERIOD = 1.0


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
	
	MouseState.mouse_state_changed.connect(_build_mode_changed)

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
		var background_map_scene: PackedScene = load("res://Scenes/BackgroundMap.tscn")
		var background_map = background_map_scene.instantiate()
		_buildable_area.add_sibling(background_map)
	else:
		print_verbose("Using prerendered map")


func setup_for_prerendering():
	_prerendered_background.hide()
	_black_border.hide()
	_foreground_map.hide()


func _build_mode_changed():
	_buildable_area.visible = MouseState.get_state() == MouseState.enm.BUILD_TOWER


func get_play_area_size() -> Vector2:
	return play_area_shape.get_shape().size


func get_play_area_pos() -> Vector2:
	return play_area_shape.global_position


func get_mouse_pos_on_tilemap_clamped() -> Vector2:
	var world_pos: Vector2 = _buildable_area.get_local_mouse_position()
	var map_pos: Vector2 = _buildable_area.local_to_map(world_pos)
	var clamped_world_pos: Vector2 = _buildable_area.map_to_local(map_pos)
	var clamped_global_pos = _buildable_area.to_global(clamped_world_pos)

	return clamped_global_pos


func mouse_is_over_buildable_tile() -> bool:
	var global_pos: Vector2 = get_mouse_pos_on_tilemap_clamped()
	var local_pos: Vector2 = _buildable_area.to_local(global_pos)
	var map_pos: Vector2 = _buildable_area.local_to_map(local_pos)
	var buildable_area_cell_exists_at_pos: bool = _buildable_area.get_cell_source_id(0, map_pos) != -1

	return buildable_area_cell_exists_at_pos


func can_build_at_mouse_pos() -> bool:
	var pos: Vector2 = get_mouse_pos_on_tilemap_clamped()
	var occupied: bool = BuildTower.position_is_occupied(pos)

	var buildable_tile: bool = mouse_is_over_buildable_tile()

	var can_build: bool = !occupied && buildable_tile

	return can_build


func can_transform_at_mouse_pos() -> bool:
	if Globals.game_mode == GameMode.enm.BUILD && !Config.allow_transform_in_build_mode():
		return false

	var pos: Vector2 = get_mouse_pos_on_tilemap_clamped()
	var there_is_a_tower_under_mouse: bool = BuildTower.position_is_occupied(pos)
	var can_transform: bool = there_is_a_tower_under_mouse

	return can_transform


func get_mouse_world_pos() -> Vector2:
	var out: Vector2 = _buildable_area.get_local_mouse_position()

	return out


func pos_is_on_ground(_pos: Vector2) -> bool:
	return true
