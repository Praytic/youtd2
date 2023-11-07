class_name TowerPreview
extends Node2D


@onready var _map = get_tree().get_root().get_node("GameScene/Map")


const opaque_red := Color(1, 0, 0, 0.5)
const opaque_green := Color(0, 1, 0, 0.5)
const opaque_blue := Color(0, 0, 1, 0.5)

var tower_id: int
var _tower_instance: Node2D

@export var _range_indicator: RangeIndicator


func _ready():
	var tower_properties: Dictionary = Properties.get_tower_csv_properties_by_id(tower_id)
	var attack_range: float = tower_properties[Tower.CsvProperty.ATTACK_RANGE].to_float()

	_range_indicator.set_radius(attack_range)

#	NOTE: have to move range indicator down because tower sprite is on 2nd floor
# 	and range indicator needs to be on 1st floor. Also note that setting
# 	indicator's position doesn't work exactly, probably because of the way
# 	range indicator is drawn.
	_range_indicator.y_offset = 128

	var visual_only: bool = true
	_tower_instance = TowerManager.get_tower(tower_id, visual_only)
	add_child(_tower_instance)

	var aura_type_list: Array[AuraType] = _tower_instance.get_aura_types()
	Utils.add_range_indicators_for_auras(aura_type_list, self)


func _physics_process(_delta):
# 	Show tower preview under map normally, but make it stick
# 	to tile position when mouse is hovered over a buildable
# 	tile.
	if _map.mouse_is_over_buildable_tile():
		var new_position = _map.get_mouse_pos_on_tilemap_clamped()
		if new_position != position:
			_range_indicator.ignore_layer = false
			_range_indicator.queue_redraw()
		position = new_position
	else:
		var new_position = get_global_mouse_position()
		if fmod(position.x, 128) != 0 or fmod(position.y, 128) != 0:
			_range_indicator.ignore_layer = true
			_range_indicator.queue_redraw()
		position = new_position

	if _map.can_build_at_mouse_pos():
		_tower_instance.modulate = opaque_green
	elif _map.can_transform_at_mouse_pos():
		_tower_instance.modulate = opaque_blue
	else:
		_tower_instance.modulate = opaque_red
