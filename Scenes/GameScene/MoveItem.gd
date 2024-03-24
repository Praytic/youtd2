class_name MoveItem extends Node

# Handles moving items between item stash, horadric stash
# and tower inventories. Movement is started from various
# sources in the UI via EventBus. Note that while an item is
# being moved, it will be parented to this node.


# Container from which currently moved item came from. Item
# will return to this container if the player cancels item
# movement.
var _source_container: ItemContainer = null
var _moved_item: Item = null
var _item_stash: ItemContainer = null
var _horadric_stash: ItemContainer = null


@export var _mouse_state: MouseState


#########################
###     Built-in      ###
#########################

func _ready():
	EventBus.player_clicked_item_in_tower_inventory.connect(_on_player_clicked_item_in_tower_inventory)
	EventBus.player_clicked_item_in_main_stash.connect(_on_player_clicked_item_in_main_stash)
	EventBus.player_clicked_item_in_horadric_stash.connect(_on_player_clicked_item_in_horadric_stash)
	EventBus.player_clicked_main_stash.connect(_on_player_clicked_main_stash)
	EventBus.player_clicked_horadric_stash.connect(_on_player_clicked_horadric_stash)
	EventBus.player_clicked_tower_inventory.connect(_on_player_clicked_tower_inventory)
	EventBus.item_flew_to_item_stash.connect(_on_item_flew_to_item_stash)


#########################
###       Public      ###
#########################

# TODO: fix for multiplayer. Do item movement using rpc.
func set_player(player: Player):
	_item_stash = player.get_item_stash()
	_horadric_stash = player.get_horadric_stash()


func cancel():
	if !_move_in_progress():
		return

	_end_move_process()


# If player started moving an item and then clicked on
# nothing, remove the item from source and make it fly back
# to item stash.
func process_click_on_nothing(map: Map):
	if !_move_in_progress():
		return

	_remove_moved_item_from_source_container()

	var drop_position: Vector2 = map.get_mouse_pos_on_tilemap_clamped()
	Item.make_item_drop(_moved_item, drop_position)
	_moved_item.fly_to_stash(0.0)
	SFX.play_sfx("res://Assets/SFX/move_item.mp3", -10.0)

	_end_move_process()


func process_click_on_tower(tower: Tower):
	_on_player_clicked_tower_inventory(tower)


#########################
###      Private      ###
#########################

func _move_in_progress() -> bool:
	return _mouse_state.get_state() == MouseState.enm.MOVE_ITEM


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

	if _move_in_progress() && !_check_consumable_into_tower_case(container):
		return

#	If an item is currently getting moved, end move process
#	for old item and start moving new item
	if _move_in_progress():
		_end_move_process()

	_moved_item = clicked_item
	_moved_item.tree_exited.connect(_on_moved_item_tree_exited)
	_source_container = container
	_mouse_state.set_state(MouseState.enm.MOVE_ITEM)
	
	var item_cursor_icon: Texture2D = _get_item_cursor_icon(clicked_item)
	var hotspot: Vector2 = item_cursor_icon.get_size() / 2
	Input.set_custom_mouse_cursor(item_cursor_icon, Input.CURSOR_ARROW, hotspot)

	SFX.play_sfx("res://Assets/SFX/move_item.mp3", -10.0)

	get_viewport().set_input_as_handled()


# When an item container is clicked, we add the currently
# moved item to that container.
func _item_container_was_clicked(container: ItemContainer, add_index: int = 0):
	if !_move_in_progress():
		return

	if !_check_consumable_into_tower_case(container):
		return

	if !container.can_add_item(_moved_item):
		Messages.add_error(PlayerManager.get_local_player(), "No space for item")

		return

#	NOTE: add item to container at position 0 so that if
#	there are many items and item stash is in scroll mode,
#	the player will see the item appear on the left side of
#	the item stash. Default scroll position for item stash
#	displays the left side.
	_remove_moved_item_from_source_container()
	container.add_item(_moved_item, add_index)
	_end_move_process()

	SFX.play_sfx("res://Assets/SFX/move_item.mp3", -10.0)

	get_viewport().set_input_as_handled()


func _end_move_process():
	_mouse_state.set_state(MouseState.enm.NONE)

	if _moved_item.tree_exited.is_connected(_on_moved_item_tree_exited):
		_moved_item.tree_exited.disconnect(_on_moved_item_tree_exited)
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
	var can_start: bool = _mouse_state.get_state() == MouseState.enm.NONE || _mouse_state.get_state() == MouseState.enm.MOVE_ITEM

	return can_start


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
		Messages.add_error(PlayerManager.get_local_player(), "Can't place consumables into towers")

	return move_ok


# NOTE: need to disconnect signal before removing to avoid
# triggering _on_moved_item_tree_exited() callback when it's
# not needed.
func _remove_moved_item_from_source_container():
	if _moved_item.tree_exited.is_connected(_on_moved_item_tree_exited):
		_moved_item.tree_exited.disconnect(_on_moved_item_tree_exited)

	_source_container.remove_item(_moved_item)


#########################
###     Callbacks     ###
#########################

func _on_player_clicked_item_in_tower_inventory(clicked_item: Item):
	var shift_click: bool = Input.is_action_pressed("shift")
	var tower: Tower = clicked_item.get_carrier()
	
	if shift_click && !_move_in_progress():
		var tower_container: ItemContainer = tower.get_item_container()
		tower_container.remove_item(clicked_item)
		var add_index: int = 0
		_item_stash.add_item(clicked_item, add_index)
		
		return

	var container: ItemContainer = tower.get_item_container()
	_item_was_clicked_in_item_container(container, clicked_item)


func _on_player_clicked_item_in_main_stash(clicked_item: Item):
	var shift_click: bool = Input.is_action_pressed("shift")

	if shift_click && !_move_in_progress():
		if !_horadric_stash.have_item_space():
			Messages.add_error(PlayerManager.get_local_player(), "No space for item")

			return
			
		_item_stash.remove_item(clicked_item)
		var add_index: int = _horadric_stash.get_item_count()
		_horadric_stash.add_item(clicked_item, add_index)

#		NOTE: this is needed to prevent the click getting
#		passed to SelectUnit which closes the tower menu
		get_viewport().set_input_as_handled()

		return

	_item_was_clicked_in_item_container(_item_stash, clicked_item)


func _on_player_clicked_item_in_horadric_stash(clicked_item: Item):
	var shift_click: bool = Input.is_action_pressed("shift")
	
	if shift_click:
		_horadric_stash.remove_item(clicked_item)
		var add_index: int = 0
		_item_stash.add_item(clicked_item, add_index)

		return

	_item_was_clicked_in_item_container(_horadric_stash, clicked_item)


# NOTE: add item to item stash at position 0 so that if
# there are many items and item stash is in scroll mode, the
# player will see the item appear on the left side of the
# item stash. Default scroll position for item stash
# displays the left side.
func _on_player_clicked_main_stash():
	var add_index: int = 0
	_item_container_was_clicked(_item_stash, add_index)


func _on_player_clicked_horadric_stash():
	var add_index: int = _horadric_stash.get_item_count()
	_item_container_was_clicked(_horadric_stash, add_index)


func _on_player_clicked_tower_inventory(tower: Tower):
	var container: ItemContainer = tower.get_item_container()
	var add_index: int = container.get_item_count()
	_item_container_was_clicked(container, add_index)


func _on_item_flew_to_item_stash(item: Item):
	_item_stash.add_item(item)


# NOTE: this callback handles the case of needing to cancel
# item move when item was removed from source container. For
# example, if item was dropped from tower via code.
func _on_moved_item_tree_exited():
	cancel()
