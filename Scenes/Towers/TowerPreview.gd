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

	_tower_instance = TowerManager.get_tower(tower_id)
	add_child(_tower_instance)
	_tower_instance.set_visual_only()


func _physics_process(_delta):
	_tower_instance.modulate = get_current_color()
	position = _landscape.get_current_buildable_pos()


func get_current_color() -> Color:
	if _landscape.can_build_at_mouse_pos():
		return opaque_green
	else:
		return opaque_red
