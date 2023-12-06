extends Node


# Singleton that implements moving items between item stash
# and tower inventories. Note that while an item is being
# moved, it is parented to this class.


var _moved_item: Item = null
# Container from which currently moved item came from. Item
# will return to this container if the player cancels item
# movement.
var _source_container: ItemContainer = null

@onready var _map = get_tree().get_root().get_node("GameScene/Map")


func _unhandled_input(event: InputEvent):
	var cancelled: bool = event.is_action_released("ui_cancel")
	var left_click: bool = event.is_action_released("left_click")
	var hovered_unit: Unit = SelectUnit.get_hovered_unit()
	var target_tower: Tower = hovered_unit as Tower

	if cancelled:
		cancel()
	elif left_click && in_progress():
		if target_tower != null:
			tower_was_clicked(target_tower)
		else:
			_return_item_to_stash()


func in_progress() -> bool:
	return MouseState.get_state() == MouseState.enm.MOVE_ITEM


func item_was_clicked_in_tower_inventory(clicked_item: Item):
	var shift_click: bool = Input.is_action_pressed("shift")
	var tower: Tower = clicked_item.get_carrier()
	
	if shift_click && !in_progress():
		var tower_container: ItemContainer = tower.get_item_container()
		var item_stash_container: ItemContainer = ItemStash.get_item_container()
		tower_container.remove_item(clicked_item)
		var add_index: int = 0
		item_stash_container.add_item(clicked_item, add_index)
		
		return

	var container: ItemContainer = tower.get_item_container()
	_item_was_clicked_in_item_container(container, clicked_item)


func item_was_clicked_in_item_stash(clicked_item: Item):
	var shift_click: bool = Input.is_action_pressed("shift")

	if shift_click && !in_progress():
		var horadric_cube_container: ItemContainer = HoradricCube.get_item_container()
		var item_stash_container: ItemContainer = ItemStash.get_item_container()
		
		if !horadric_cube_container.have_item_space():
			Messages.add_error("No space for item")

			return
			
		item_stash_container.remove_item(clicked_item)
		var add_index: int = horadric_cube_container.get_item_count()
		horadric_cube_container.add_item(clicked_item, add_index)

#		NOTE: this is needed to prevent the click getting
#		passed to SelectUnit which closes the tower menu
		get_viewport().set_input_as_handled()

		return

	var container: ItemContainer = ItemStash.get_item_container()
	_item_was_clicked_in_item_container(container, clicked_item)


func item_was_clicked_in_horadric_cube(clicked_item: Item):
	var shift_click: bool = Input.is_action_pressed("shift")
	
	if shift_click:
		var horadric_cube_container: ItemContainer = HoradricCube.get_item_container()
		var item_stash_container: ItemContainer = ItemStash.get_item_container()

		horadric_cube_container.remove_item(clicked_item)
		var add_index: int = 0
		item_stash_container.add_item(clicked_item, add_index)

		return

	var container: ItemContainer = HoradricCube.get_item_container()
	_item_was_clicked_in_item_container(container, clicked_item)


# NOTE: add item to item stash at position 0 so that if
# there are many items and item stash is in scroll mode, the
# player will see the item appear on the left side of the
# item stash. Default scroll position for item stash
# displays the left side.
func item_stash_was_clicked():
	var container: ItemContainer = ItemStash.get_item_container()
	var add_index: int = 0
	_item_container_was_clicked(container, add_index)


func horadric_menu_was_clicked():
	var container: ItemContainer = HoradricCube.get_item_container()
	var add_index: int = container.get_item_count()
	_item_container_was_clicked(container, add_index)


func tower_was_clicked(tower: Tower):
	var container: ItemContainer = tower.get_item_container()
	var add_index: int = container.get_item_count()
	_item_container_was_clicked(container, add_index)


func cancel():
	if !in_progress():
		return

# 	Return item back to where it was before we started
# 	moving it
	remove_child(_moved_item)

#	NOTE: if cancelling and tower inventory or cube are
#	full, then return item to stash. Item stash has
#	unlimited capacity.
# 
#	NOTE: note that source container may become invalid if
#	it was a tower and it wass sold before cancelling.
	if is_instance_valid(_source_container) && _source_container.have_item_space():
		_source_container.add_item(_moved_item)
	else:
		var item_stash_container: ItemContainer = ItemStash.get_item_container()
		item_stash_container.add_item(_moved_item)

	_end_move_process()


# When an item is clicked in an item container, two possible results:
# 
# 1. If no item is currently being moved, then we start
#    moving the clicked item.
# 
# 2. If an item is currently being moved, then we swap the
#    items. We put the old moved item in the container and
#    start moving the clicked item.
func _item_was_clicked_in_item_container(container: ItemContainer, clicked_item: Item):
	if !_can_start_moving():
		return

	if in_progress() && !_check_consumable_into_tower_case(container):
		return

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
		var clicked_index: int = container.get_item_index(clicked_item)
		container.remove_item(clicked_item)
		remove_child(prev_moved_item)
		container.add_item(prev_moved_item, clicked_index)
	else:
		container.remove_item(clicked_item)

	add_child(clicked_item)

	_moved_item = clicked_item
	_source_container = container
	MouseState.set_state(MouseState.enm.MOVE_ITEM)
	
	var item_cursor_icon: Texture2D = _get_item_cursor_icon(clicked_item)
	var hotspot: Vector2 = item_cursor_icon.get_size() / 2
	Input.set_custom_mouse_cursor(item_cursor_icon, Input.CURSOR_ARROW, hotspot)

	SFX.play_sfx("res://Assets/SFX/move_item.mp3", -10.0)

	get_viewport().set_input_as_handled()


# When an item container is clicked, we add the currently
# moved item to that container.
func _item_container_was_clicked(container: ItemContainer, add_index: int = 0):
	if !in_progress():
		return

	if !_check_consumable_into_tower_case(container):
		return

	if !container.can_add_item(_moved_item):
		Messages.add_error("No space for item")

		return

#	NOTE: add item to container at position 0 so that if
#	there are many items and item stash is in scroll mode,
#	the player will see the item appear on the left side of
#	the item stash. Default scroll position for item stash
#	displays the left side.
	remove_child(_moved_item)
	container.add_item(_moved_item, add_index)
	_end_move_process()

	SFX.play_sfx("res://Assets/SFX/move_item.mp3", -10.0)

	get_viewport().set_input_as_handled()


func _end_move_process():
	MouseState.set_state(MouseState.enm.NONE)

	_moved_item = null
	_source_container = null

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


# Return item to stash with a flying animation so player
# understands what is happening.
func _return_item_to_stash():
	var drop_position: Vector2 = _map.get_mouse_pos_on_tilemap_clamped()

	remove_child(_moved_item)
	Item._create_item_drop(_moved_item, drop_position)
	_moved_item.fly_to_stash(0.0)
	_end_move_process()

	SFX.play_sfx("res://Assets/SFX/move_item.mp3", -10.0)


# Checks if currently moved item can't be placed into
# container because container belongs to tower and item is
# consumable. Also adds an error messages if needed.
# Returns true if can move.
func _check_consumable_into_tower_case(container: ItemContainer) -> bool:
	if _moved_item == null:
		return true

	var cant_move_consumable_to_tower: bool = _moved_item.is_consumable() && container is TowerItemContainer
	var move_ok: bool = !cant_move_consumable_to_tower

	if !move_ok:
		Messages.add_error("Can't place consumables into towers")

	return move_ok
