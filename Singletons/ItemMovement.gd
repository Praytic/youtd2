extends Node


# Singleton that implements moving items between ItemBar and
# tower inventories.


signal item_move_from_itembar_done(success: bool)
signal item_move_from_tower_done(success: bool)
signal item_moved_to_itembar(item_id: int)


enum MoveState {
	NONE,
	FROM_ITEMBAR,
	FROM_TOWER,
}


const _CLICK_ON_TOWER_RADIUS: float = 100

var _moved_item_id: int = -1
var _tower_owner_of_moved_item: Tower = null
var _move_state: MoveState = MoveState.NONE


@onready var _map: Node = get_tree().get_root().get_node("GameScene/Map")


func start_move_from_tower(item_id: int, tower: Tower):
	_tower_owner_of_moved_item = tower
	_start_internal(item_id, MoveState.FROM_TOWER)


func start_move_from_itembar(item_id: int):
	_start_internal(item_id, MoveState.FROM_ITEMBAR)


func on_clicked_on_right_menu_bar():
#	NOTE: forcefully pass null target_tower so that even if
#	there is a tower behind right menubar, we still move the
#	item back to itembar.
	var target_tower: Tower = null
	try_to_move(target_tower)


func cancel():
	if !in_progress():
		return

	_end_move_process(false)


# Moving item begins here
func _start_internal(item_id: int, new_state: MoveState):
	cancel()
	BuildTower.cancel()
	SelectUnit.set_enabled(false)

	_move_state = new_state
	_moved_item_id = item_id
	
	var item_cursor_icon: Texture2D = _get_item_cursor_icon(item_id)
	var hotspot: Vector2 = item_cursor_icon.get_size() / 2
	Input.set_custom_mouse_cursor(item_cursor_icon, Input.CURSOR_ARROW, hotspot)


# Moving item ends here
func _unhandled_input(event: InputEvent):
	if !in_progress():
		return

	var cancelled: bool = event.is_action_released("ui_cancel")

	if cancelled:
		cancel()

	var left_click: bool = event.is_action_pressed("left_click")

	if left_click:
		var target_tower: Tower = _get_tower_under_mouse()
		try_to_move(target_tower)


func try_to_move(target_tower: Tower):
	match _move_state:
		MoveState.FROM_ITEMBAR:
			_move_item_from_itembar(target_tower)
		MoveState.FROM_TOWER:
			_move_item_from_tower(target_tower)


func _end_move_process(success: bool):
	match _move_state:
		MoveState.FROM_ITEMBAR:
			item_move_from_itembar_done.emit(success)
		MoveState.FROM_TOWER:
			item_move_from_tower_done.emit(success)

	SelectUnit.set_enabled(true)
	
	_moved_item_id = -1
	_move_state = MoveState.NONE

#	NOTE: for some reason need to call this twice to reset
#	the cursor. Calling it once causes the cursor to
#	disappear.
	Input.set_custom_mouse_cursor(null)
	Input.set_custom_mouse_cursor(null)


func _move_item_from_itembar(target_tower: Tower):
	var is_oil: bool = ItemProperties.get_is_oil(_moved_item_id)
	
	if target_tower != null:
		if is_oil:
			target_tower.add_item_by_id(_moved_item_id)
			_end_move_process(true)
		else:
			if target_tower.have_item_space():
				target_tower.add_item_by_id(_moved_item_id)
				_end_move_process(true)
			else:
				Globals.error_message_label.add("No space for item")
	else:
		_end_move_process(false)


func _move_item_from_tower(target_tower: Tower):
	var moving_to_itself: bool = target_tower == _tower_owner_of_moved_item

	if moving_to_itself:
		Globals.error_message_label.add("Item is already on tower")
		
		return

#	If clicked on tower, move item to tower,
#	otherwise move item to itembar
	if target_tower != null:
		if target_tower.have_item_space():
			_tower_owner_of_moved_item.remove_item(_moved_item_id)
			_tower_owner_of_moved_item = null
			target_tower.add_item_by_id(_moved_item_id)
			_end_move_process(true)
		else:
			Globals.error_message_label.add("No space for item")
	else:
		_tower_owner_of_moved_item.remove_item(_moved_item_id)
		_tower_owner_of_moved_item = null

		item_moved_to_itembar.emit(_moved_item_id)
		_end_move_process(true)


func _get_tower_under_mouse() -> Tower:
	var mouse_pos: Vector2 = _map.get_mouse_world_pos()
	var unit_list: Array[Unit] = Utils.get_units_in_range(TargetType.new(TargetType.TOWERS), mouse_pos, _CLICK_ON_TOWER_RADIUS)
	Utils.sort_unit_list_by_distance(unit_list, mouse_pos)

	if !unit_list.is_empty():
		var tower: Tower = unit_list[0] as Tower

		return tower
	else:
		return null


func in_progress() -> bool:
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
