extends Control


signal item_dropped(item_id)
signal item_used(item_id)
signal drag_start(item_id)
signal drag_end(item_id)


enum MoveState {
	NONE,
	FROM_ITEMBAR,
	FROM_TOWER,
}

const CLICK_ON_TOWER_RADIUS: float = 100


@onready var object_ysort: Node2D = get_node("%Map").get_node("ObjectYSort")
@onready var item_bar: GridContainer = get_node("%HUD/RightMenuBar/%ItemBar")
@onready var _map: Node = get_node("%Map/")

var _moved_item_id: int = -1
var _tower_owner_of_moved_item: Tower = null
var _move_state: MoveState = MoveState.NONE

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


func on_item_button_pressed_in_tower(item_id: int, tower: Tower):
	_tower_owner_of_moved_item = tower
	_on_item_button_pressed(item_id, MoveState.FROM_TOWER)


func on_item_button_pressed_in_itembar(item_id: int):
	_on_item_button_pressed(item_id, MoveState.FROM_ITEMBAR)


func _on_item_button_pressed(item_id: int, new_state: MoveState):
	if _item_move_in_progress():
		return

	_move_state = new_state
	_moved_item_id = item_id
	
	var item_cursor_icon: Texture2D = _get_item_cursor_icon(item_id)
	var hotspot: Vector2 = item_cursor_icon.get_size() / 2
	Input.set_custom_mouse_cursor(item_cursor_icon
	, Input.CURSOR_ARROW, hotspot)


func _unhandled_input(event: InputEvent):
	if !_item_move_in_progress():
		return

	var move_is_over: bool = event.is_action_pressed("left_click")

	if !move_is_over:
		return

	var tower: Tower = _get_tower_under_mouse()

	match _move_state:
		MoveState.FROM_ITEMBAR:
			if tower != null:
				tower.add_item(_moved_item_id)

			var item_was_moved: bool = tower != null
			item_bar.item_move_over(item_was_moved)
		MoveState.FROM_TOWER:
			_tower_owner_of_moved_item.remove_item(_moved_item_id)
			_tower_owner_of_moved_item = null

#			If clicked on tower, move item to tower,
#			otherwise move item to itembar
			if tower != null:
				tower.add_item(_moved_item_id)
			else:
				item_bar.add_item_button(_moved_item_id)

	_moved_item_id = -1
	_move_state = MoveState.NONE

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


func _item_move_in_progress() -> bool:
	return _move_state != MoveState.NONE


# NOTE: Input.set_custom_mouse_cursor() currently has a bug
# which causes errors if we use AtlasTexture returned by
# ItemProperties.get_icon() (it returns base class Texture2D but it's
# still an atlas texture). Copy image from AtlasTexture to
# ImageTexture to avoid this bug.
func _get_item_cursor_icon(item_id: int) -> Texture2D:
	var atlas_texture: Texture2D = ItemProperties.get_icon(item_id, "S")
	var image: Image = atlas_texture.get_image()
#	NOTE: make cursor icon slightly smaller so it looks nice
	var final_size: Vector2 = image.get_size() * 0.75
	image.resize(int(final_size.x), int(final_size.y))
	var image_texture: ImageTexture = ImageTexture.create_from_image(image)

	return image_texture
