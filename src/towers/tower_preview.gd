class_name TowerPreview
extends Node2D


@export var _build_space: BuildSpace


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
@export var _transform_label: RichTextLabel
@export var _sprite_parent: Node2D


func set_tower(tower_id: int):
	if _tower_sprite != null:
		_sprite_parent.remove_child(_tower_sprite)
		_tower_sprite.queue_free()
		_tower_sprite = null
		
	for old_range_indicator in _range_indicator_container.get_children():
		old_range_indicator.queue_free()
	
	_tower_id = tower_id
	
	_tower_sprite = TowerSprites.get_sprite(tower_id)
	_sprite_parent.add_child(_tower_sprite)
	
	var range_data_list: Array[RangeData] = TowerProperties.get_range_data_list(tower_id)
	var local_player: Player = PlayerManager.get_local_player()
	Utils.setup_range_indicators(range_data_list, _range_indicator_container, local_player)


func set_range_manual(radius: int, friendly: bool, is_attack: bool = false):
	for old_range_indicator in _range_indicator_container.get_children():
		old_range_indicator.queue_free()

	var target_type: TargetType
	if friendly:
		target_type = TargetType.new(TargetType.TOWERS)
	else:
		target_type = TargetType.new(TargetType.CREEPS)

	var range_data: RangeData = RangeData.new("", radius, target_type, is_attack)
	var range_data_list: Array[RangeData] = [range_data]
	
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
	var new_position: Vector2 = VectorUtils.snap_canvas_pos_to_buildable_pos(mouse_pos)
	position = new_position

	var can_transform: bool = _build_space.can_transform_at_pos(mouse_pos)

	if can_transform:
		_sprite_parent.modulate = opaque_blue
	else:
		_sprite_parent.modulate = Color.WHITE
	
	_transform_label.visible = can_transform

	var local_player: Player = PlayerManager.get_local_player()
	var build_info: Array = _build_space.get_build_info_for_pos(local_player, mouse_pos)
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
