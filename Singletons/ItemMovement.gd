extends Node


# Singleton that implements moving items between ItemBar and
# tower inventories.


signal item_move_from_itembar_done(success: bool)
signal item_move_from_tower_done(success: bool)


enum MoveSource {
	NONE,
	ITEMBAR,
	TOWER,
}


var _moved_item: Item = null
var _move_source: MoveSource = MoveSource.NONE


func _unhandled_input(event: InputEvent):
	if !in_progress():
		return

	var cancelled: bool = event.is_action_released("ui_cancel")

	if cancelled:
		cancel()

	var left_click: bool = event.is_action_released("left_click")

	if left_click:
		var target_tower: Tower = SelectUnit.get_hovered_unit()
		_try_to_move(target_tower)


func in_progress() -> bool:
	return MouseState.get_state() == MouseState.enm.MOVE_ITEM


func start_move_from_tower(item: Item) -> bool:
	return _start_internal(item, MoveSource.TOWER)


func start_move_from_itembar(item: Item) -> bool:
	return _start_internal(item, MoveSource.ITEMBAR)


func cancel():
	if !in_progress():
		return

	_end_move_process(false)


func on_clicked_on_right_menu_bar():
	if !in_progress():
		return

#	NOTE: forcefully pass null target_tower so that even if
#	there is a tower behind right menubar, we still move the
#	item back to itembar.
	var target_tower: Tower = null
	_try_to_move(target_tower)


# Moving item begins here. Returns true if can start.
func _start_internal(item: Item, move_source: MoveSource) -> bool:
	var can_start: bool = MouseState.get_state() != MouseState.enm.NONE && MouseState.get_state() != MouseState.enm.MOVE_ITEM
	if can_start:
		return false

	cancel()
	MouseState.set_state(MouseState.enm.MOVE_ITEM)
	_move_source = move_source
	_moved_item = item
	
	var item_cursor_icon: Texture2D = _get_item_cursor_icon(item)
	var hotspot: Vector2 = item_cursor_icon.get_size() / 2
	Input.set_custom_mouse_cursor(item_cursor_icon, Input.CURSOR_ARROW, hotspot)

	return true


func _try_to_move(target_tower: Tower):
	match _move_source:
		MoveSource.ITEMBAR:
			_move_item_from_itembar(target_tower)
		MoveSource.TOWER:
			_move_item_from_tower(target_tower)


func _end_move_process(success: bool):
	match _move_source:
		MoveSource.ITEMBAR:
			item_move_from_itembar_done.emit(success)
		MoveSource.TOWER:
			item_move_from_tower_done.emit(success)

	MouseState.set_state(MouseState.enm.NONE)

	_moved_item = null
	_move_source = MoveSource.NONE

#	NOTE: for some reason need to call this twice to reset
#	the cursor. Calling it once causes the cursor to
#	disappear.
	Input.set_custom_mouse_cursor(null)
	Input.set_custom_mouse_cursor(null)


func _move_item_from_itembar(target_tower: Tower):
	var is_oil: bool = ItemProperties.get_is_oil(_moved_item.get_id())
	
	if target_tower != null:
		if is_oil:
			_moved_item._pickup_internal(target_tower)
			_end_move_process(true)
		else:
			if target_tower.have_item_space():
				_moved_item.pickup(target_tower)
				_end_move_process(true)
			else:
				Messages.add_error("No space for item")
	else:
		_end_move_process(false)


func _move_item_from_tower(target_tower: Tower):
	var moving_to_itself: bool = target_tower == _moved_item.get_carrier()

	if moving_to_itself:
		Messages.add_error("Item is already on tower")
		
		return

#	If clicked on tower, move item to tower,
#	otherwise move item to itembar
	if target_tower != null:
		if target_tower.have_item_space():
			_moved_item.drop()
			_moved_item.pickup(target_tower)
			_end_move_process(true)
		else:
			Messages.add_error("No space for item")
	else:
#		NOTE: move item directly to stash by emitting
#		item_drop_picked_up signal. Do not fly to stash
#		because that would look weird after dragging item to
#		stash with mouse.
		_moved_item.drop()
		_moved_item.move_to_stash()
		_end_move_process(true)


# NOTE: Input.set_custom_mouse_cursor() currently has a bug
# which causes errors if we use AtlasTexture returned by
# ItemProperties.get_icon() (it returns base class Texture2D but it's
# still an atlas texture). Copy image from AtlasTexture to
# ImageTexture to avoid this bug.
func _get_item_cursor_icon(item: Item) -> Texture2D:
	var item_id: int = item.get_id()
	var atlas_texture: Texture2D = ItemProperties.get_icon(item_id)
	var image: Image = atlas_texture.get_image()
#	NOTE: make cursor icon slightly smaller so it looks nice
	var final_size: Vector2 = image.get_size() * 0.75
	image.resize(int(final_size.x), int(final_size.y))
	var image_texture: ImageTexture = ImageTexture.create_from_image(image)

	return image_texture
