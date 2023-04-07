extends Control


signal item_dropped(item_id)
signal item_used(item_id)


const CLICK_ON_TOWER_RADIUS: float = 100


@onready var object_ysort: Node2D = get_node("%Map").get_node("ObjectYSort")
@onready var item_bar: GridContainer = get_node("%HUD/RightMenuBar/%ItemBar")
@onready var _map: Node = get_node("%Map/")

var _dragged_item_id: int = -1

#########################
### Code starts here  ###
#########################

func _on_Creep_death(_event: Event, creep: Creep):
	# TODO: Implement proper item drop chance caclculation
	if Utils.rand_chance(0.5):
		var item_id_list: Array = Properties.get_item_id_list()
		var random_index: int = randi_range(0, item_id_list.size() - 1)
		var item_id: int = item_id_list[random_index]
		var item_properties: Dictionary = Properties.get_item_csv_properties()[item_id]
		var rarity: int = item_properties[Item.CsvProperty.RARITY].to_int()

		var rarity_name: String = ""

		match rarity:
			Constants.Rarity.COMMON: rarity_name = "CommonItem"
			Constants.Rarity.UNCOMMON: rarity_name = "UncommonItem"
			Constants.Rarity.RARE: rarity_name = "RareItem"
			Constants.Rarity.UNIQUE: rarity_name = "UniqueItem"
		
		var item_drop_scene_path: String = "res://Scenes/Items/%s.tscn" % [rarity_name]
		var item_drop_scene = load(item_drop_scene_path)
		var item_drop = item_drop_scene.instantiate()
		item_drop.set_id(item_id)
		item_drop.position = creep.position
		item_drop.selected.connect(_on_Item_selected.bind(item_drop))
		object_ysort.add_child(item_drop, true)
		item_dropped.emit(item_drop.get_id())

func _on_Item_selected(item_drop):
	item_bar.add_item_button(item_drop.get_id())
	item_drop.queue_free()

func _on_ItemButton_pressed(item_id: int):
	_dragged_item_id = item_id
	
#   NOTE: setting hotspot to (32, 32) centers the cursor
#   because total size of texture is 64x64
	var icon = load("res://Assets/icon.png")
	var hotspot: Vector2 = Vector2(32, 32)
	Input.set_custom_mouse_cursor(icon, Input.CURSOR_ARROW, hotspot)


func _unhandled_input(event: InputEvent):
	if !event.is_action("left_click"):
		return

	var drag_in_progress: bool = _dragged_item_id != -1

	if !drag_in_progress:
		return

	var tower: Tower = _get_tower_under_mouse()

	if tower == null:
		return

	tower.add_item(_dragged_item_id)

	_dragged_item_id = -1

#	NOTE: for some reason need to call this twice to reset
#	the cursor. Calling it once causes the cursor to
#	disappear.
	Input.set_custom_mouse_cursor(null)
	Input.set_custom_mouse_cursor(null)

	get_viewport().set_input_as_handled()


func _get_tower_under_mouse() -> Tower:
	var mouse_pos: Vector2 = _map.get_mouse_world_pos()
	var unit_list: Array[Unit] = Utils.get_units_in_range(TargetType.new(TargetType.TOWERS), mouse_pos, CLICK_ON_TOWER_RADIUS)
	Utils.sort_unit_list_by_distance(unit_list, mouse_pos)

	if !unit_list.is_empty():
		var tower: Tower = unit_list[0] as Tower

		return tower
	else:
		return null
