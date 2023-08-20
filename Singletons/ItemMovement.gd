extends Node


# Singleton that implements moving items between item stash
# and tower inventories. Note that while an item is being
# moved, it is parented to this class.

const ITEM_STASH_VISUAL_CAPACITY: int = 8

enum MoveSource {
	ITEM_STASH,
	TOWER,
	CUBE,
}


var _moved_item: Item = null
var _move_source: MoveSource
var _source_tower: Tower = null


func _unhandled_input(event: InputEvent):
	var cancelled: bool = event.is_action_released("ui_cancel")
	var left_click: bool = event.is_action_released("left_click")
	var target_tower: Tower = SelectUnit.get_hovered_unit()
	var clicked_on_tower: bool = left_click && target_tower != null

	if cancelled:
		cancel()
	elif clicked_on_tower:
		tower_was_clicked(target_tower)
		get_viewport().set_input_as_handled()


func in_progress() -> bool:
	return MouseState.get_state() == MouseState.enm.MOVE_ITEM


func item_was_clicked_in_tower_inventory(clicked_item: Item):
	var shift_click: bool = Input.is_action_pressed("shift")

	if shift_click:
		var tower: Tower = clicked_item.get_carrier()
		tower.remove_item(clicked_item)
		ItemStash.add_item(clicked_item)
		
		return

	if !_can_start_moving():
		return

	var tower: Tower = clicked_item.get_carrier()

#	If an item is currently getting moved, add it back to
#	tower at the position of the clicked item
	if in_progress():
#		NOTE: save moved item because it gets reset to null
#		by _end_move_process()
		var prev_moved_item: Item = _moved_item
		_end_move_process()

#		NOTE: this code swaps items. Moved item gets added
#		to tower inventory and the clicked item becomes the
#		new moved item. Need to handle the case where
#		inventory is full correctly, so must remove clicked
#		item first before adding moved item.
		var clicked_index: int = tower.get_item_index(clicked_item)
		tower.remove_item(clicked_item)
		remove_child(prev_moved_item)
		tower.add_item(prev_moved_item, clicked_index)
	else:
		tower.remove_item(clicked_item)
	
	_start_moving_item(clicked_item, MoveSource.TOWER, tower)


func item_was_clicked_in_item_stash(clicked_item: Item):
	var shift_click: bool = Input.is_action_pressed("shift")

	if shift_click:
		if !HoradricCube.have_space():
			Messages.add_error("No space for item")

			return
			
		ItemStash.remove_item(clicked_item)
		HoradricCube.add_item(clicked_item)

		return

	if !_can_start_moving():
		return

#	If an item is currently getting moved, add it back to
#	stash at the position of the clicked item
	if in_progress():
		var clicked_index: int = ItemStash.get_item_index(clicked_item)
		remove_child(_moved_item)
		ItemStash.add_item(_moved_item, clicked_index)
		_end_move_process()

	ItemStash.remove_item(clicked_item)
	_start_moving_item(clicked_item, MoveSource.ITEM_STASH)


func item_was_clicked_in_horadric_cube(clicked_item: Item):
	var shift_click: bool = Input.is_action_pressed("shift")
	
	if shift_click:
		HoradricCube.remove_item(clicked_item)
		ItemStash.add_item(clicked_item)

		return

	if !_can_start_moving():
		return

#	If an item is currently getting moved, add it to
#	horadric cube at the position of clicked item. Note that
#	we need to check if we can add this kind of item.
	if in_progress():
		var prev_moved_item: Item = _moved_item
		_end_move_process()

		var clicked_index: int = HoradricCube.get_item_index(clicked_item)
		HoradricCube.remove_item(clicked_item)
		remove_child(prev_moved_item)
		HoradricCube.add_item(prev_moved_item, clicked_index)
	else:
		HoradricCube.remove_item(clicked_item)
	
	_start_moving_item(clicked_item, MoveSource.CUBE)


# This is called when the empty space in item stash is
# clicked. Move item to item stash when this happens.
func item_stash_was_clicked():
	if !in_progress():
		return

#	NOTE: add item to item stash at position 0 so that if
#	there are many items and item stash is in scroll mode,
#	the player will see the item appear on the left side of
#	the item stash. Default scroll position for item stash
#	displays the left side.
	remove_child(_moved_item)
	ItemStash.add_item(_moved_item, 0)
	_end_move_process()


func horadric_menu_was_clicked():
	if !in_progress():
		return

	if !HoradricCube.have_space():
		Messages.add_error("No space for item")

		return

	remove_child(_moved_item)
	var add_index: int = HoradricCube.get_item_count()
	HoradricCube.add_item(_moved_item, add_index)
	_end_move_process()


func tower_was_clicked(tower: Tower):
	if !in_progress():
		return

	var is_oil: bool = ItemProperties.get_is_oil(_moved_item.get_id())

	if !tower.have_item_space() && !is_oil:
		Messages.add_error("No space for item")

		return

	remove_child(_moved_item)
	tower.add_item(_moved_item)
	_end_move_process()


func cancel():
	if !in_progress():
		return

# 	Return item back to where it was before we started
# 	moving it
	remove_child(_moved_item)

#	NOTE: if cancelling and tower inventory or cube are
#	full, then return item to stash
	match _move_source:
		MoveSource.ITEM_STASH: ItemStash.add_item(_moved_item)
		MoveSource.TOWER:
			if _source_tower.have_item_space():
				_source_tower.add_item(_moved_item)
			else:
				ItemStash.add_item(_moved_item)
		MoveSource.CUBE: 
			if _source_tower.have_space():
				HoradricCube.add_item(_moved_item)
			else:
				ItemStash.add_item(_moved_item)

	_end_move_process()


func _start_moving_item(item: Item, move_source: MoveSource, source_tower: Tower = null):
	add_child(item)

	_moved_item = item
	_move_source = move_source
	_source_tower = source_tower
	MouseState.set_state(MouseState.enm.MOVE_ITEM)
	
	var item_cursor_icon: Texture2D = _get_item_cursor_icon(item)
	var hotspot: Vector2 = item_cursor_icon.get_size() / 2
	Input.set_custom_mouse_cursor(item_cursor_icon, Input.CURSOR_ARROW, hotspot)


func _end_move_process():
	MouseState.set_state(MouseState.enm.NONE)

	_moved_item = null
	_source_tower = null

#	NOTE: for some reason need to call this twice to reset
#	the cursor. Calling it once causes the cursor to
#	disappear.
	Input.set_custom_mouse_cursor(null)
	Input.set_custom_mouse_cursor(null)


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


# Can start moving an item if no other mouse action is
# currently in progress or if we're currently moving an
# item. Starting to move an item while another one is moved
# already performs an item swap.
func _can_start_moving() -> bool:
	var can_start: bool = MouseState.get_state() == MouseState.enm.NONE || MouseState.get_state() == MouseState.enm.MOVE_ITEM

	return can_start
