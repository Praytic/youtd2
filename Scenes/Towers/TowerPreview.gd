class_name TowerPreview
extends Node2D


@onready var _map = get_tree().get_root().get_node("GameScene/World/Map")


const opaque_red := Color(1, 0, 0, 0.5)
const opaque_green := Color(0, 1, 0, 0.5)
const opaque_blue := Color(0, 0, 1, 0.5)

var _tower_id: int = 0
var _tower_sprite: Node2D = null

@export var _pedestal_up: Polygon2D
@export var _pedestal_right: Polygon2D
@export var _pedestal_down: Polygon2D
@export var _pedestal_left: Polygon2D
@export var _range_indicator_container: Node2D


func set_tower(tower_id: int):
	if _tower_sprite != null:
		remove_child(_tower_sprite)
		_tower_sprite.queue_free()
		_tower_sprite = null
		
	for old_range_indicator in _range_indicator_container.get_children():
		old_range_indicator.queue_free()
	
	_tower_id = tower_id
	
	_tower_sprite = TowerSprites.get_sprite(tower_id)
	add_child(_tower_sprite)
	
	var range_data_list: Array[RangeData] = TowerProperties.get_range_data_list(tower_id)
	var local_player: Player = PlayerManager.get_local_player()
	Utils.setup_range_indicators(range_data_list, _range_indicator_container, local_player)


func get_tower_id() -> int:
	return _tower_id


func _process(_delta: float):
	if !visible || _tower_sprite == null:
		return
	
	var mouse_pos: Vector2 = get_global_mouse_position()

# 	Show tower preview under map normally, but make it stick
# 	to tile position when mouse is hovered over a buildable
# 	tile.
	var new_position: Vector2 = _map.get_pos_on_tilemap_clamped(mouse_pos)
	position = new_position

	var can_transform: bool = _map.can_transform_at_pos(mouse_pos)

	if can_transform:
		_tower_sprite.modulate = opaque_blue
	else:
		_tower_sprite.modulate = Color.WHITE

	var build_info: Array = _map.get_build_info_for_pos(mouse_pos)
	var polygon_list: Array = [
		_pedestal_up,
		_pedestal_right,
		_pedestal_down,
		_pedestal_left,
	]

	for i in range(0, 4):
		var quarter_tile_is_ok: bool = build_info[i]
		var pedestal: Polygon2D = polygon_list[i]

		if can_transform:
			pedestal.color = opaque_blue
		elif quarter_tile_is_ok:
			pedestal.color = Color(Color.GREEN, 0.5)
		else:
			pedestal.color = Color(Color.RED, 0.5)
