class_name TowerPreview
extends Node2D


@onready var _landscape = get_tree().get_root().get_node("GameScene/Map")


const opaque_red := Color(1, 0, 0, 0.5)
const opaque_green := Color(0, 1, 0, 0.5)

var tower_id: int
var _tower_instance: Node2D

@onready var _range_indicator: RangeIndicator = $RangeIndicator


func _ready():
	var tower_properties: Dictionary = Properties.get_tower_csv_properties_by_id(tower_id)
	var attack_range: float = tower_properties[Tower.CsvProperty.ATTACK_RANGE].to_float()

	_range_indicator.set_radius(attack_range)

	var visual_only: bool = true
	_tower_instance = TowerManager.get_tower(tower_id, visual_only)
	add_child(_tower_instance)


func _physics_process(_delta):
# 	Show tower preview under map normally, but make it stick
# 	to tile position when mouse is hovered over a buildable
# 	tile.
	if _landscape.mouse_is_over_buildable_tile():
		position = _landscape.get_mouse_pos_on_tilemap()
	else:
		position = get_global_mouse_position()

	if _landscape.can_build_at_mouse_pos():
		_tower_instance.modulate = opaque_green
	else:
		_tower_instance.modulate = opaque_red
