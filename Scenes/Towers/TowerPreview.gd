class_name TowerPreview
extends Node2D


@onready var _map = get_tree().get_root().get_node("GameScene/Map")


const opaque_red := Color(1, 0, 0, 0.5)
const opaque_green := Color(0, 1, 0, 0.5)
const opaque_blue := Color(0, 0, 1, 0.5)

var tower_id: int
var _tower_instance: Node2D

@export var _range_indicator: RangeIndicator
@export var _pedestal_up: Polygon2D
@export var _pedestal_right: Polygon2D
@export var _pedestal_down: Polygon2D
@export var _pedestal_left: Polygon2D


func _ready():
	var tower_properties: Dictionary = Properties.get_tower_csv_properties_by_id(tower_id)
	var attack_range: float = tower_properties[Tower.CsvProperty.ATTACK_RANGE].to_float()

	_range_indicator.set_radius(attack_range)

#	NOTE: have to move range indicator down because tower sprite is on 2nd floor
# 	and range indicator needs to be on 1st floor. Also note that setting
# 	indicator's position doesn't work exactly, probably because of the way
# 	range indicator is drawn.
	_range_indicator.y_offset = 128

	var is_tower_preview: bool = true
	_tower_instance = TowerManager.get_tower(tower_id, is_tower_preview)
#	NOTE: have to init stats because we call
#	get_aura_types() on tower. For some towers, calling
#	get_aura_types() will touch _stats variable, which is
#	initialized by init_stats_and_specials().
	_tower_instance.init_stats_and_specials()
	add_child(_tower_instance)

	var aura_type_list: Array[AuraType] = _tower_instance.get_aura_types()
	Utils.add_range_indicators_for_auras(aura_type_list, self)


func _physics_process(_delta):
# 	Show tower preview under map normally, but make it stick
# 	to tile position when mouse is hovered over a buildable
# 	tile.
	var old_position: Vector2 = position
	var new_position: Vector2 = _map.get_mouse_pos_on_tilemap_clamped()
	position = new_position

	if new_position != old_position:
		_range_indicator.visible = true
		_range_indicator.ignore_layer = false
		_range_indicator.queue_redraw()

	var can_transform: bool = _map.can_transform_at_mouse_pos()

	if can_transform:
		_tower_instance.modulate = opaque_blue
	else:
		_tower_instance.modulate = Color.WHITE

	var build_info: Array = _map.get_build_info_for_mouse_pos()
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
