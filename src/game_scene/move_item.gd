class_name MoveItem extends Node

# Handles moving items between item stash, horadric stash
# and tower inventories. Movement is started from various
# sources in the UI via EventBus. Note that while an item is
# being moved, it will be parented to this node.

enum InstantMoveType {
	NONE,
	FROM_ANY_TO_ITEM_STASH,
	FROM_ANY_TO_TOWER,
	FROM_TOWER_TO_HORADRIC_CUBE,
	FROM_ITEM_STASH_TO_HORADRIC_CUBE,
}


# Container from which currently moved item came from. Item
# will return to this container if the player cancels item
# movement.
var _source_container: ItemContainer = null
var _moved_item: Item = null


@export var _mouse_state: MouseState
@export var _map: Map
@export var _game_client: GameClient


#########################
###     Built-in      ###
#########################

func _ready():
	EventBus.player_clicked_in_item_container.connect(_on_player_clicked_in_item_container)
	EventBus.item_flew_to_item_stash.connect(_on_item_flew_to_item_stash)


#########################
###       Public      ###
#########################

func cancel():
	if !_move_in_progress():
		return

	_end_move_process()


# If player started moving an item and then clicked on
# nothing, remove the item from source and make it fly back
# to item stash.
func process_click_on_nothing():
	if !_move_in_progress():
		return
	
	var local_player: Player = PlayerManager.get_local_player()
	var item_uid: int = _moved_item.get_uid()
	var drop_pos: Vector2 = _map.get_global_mouse_position()
	var src_container_uid: int = _source_container.get_uid()

	var verify_ok: bool = ActionDropItem.verify(local_player, _moved_item, _source_container)
	if !verify_ok:
		_end_move_process()
		
		return false

	_end_move_process()

	var action: Action = ActionDropItem.make(item_uid, drop_pos, src_container_uid)
	_game_client.add_action(action)
	
	SFX.play_sfx_random_pitch(SfxPaths.DROP_ITEM)


func process_click_on_tower(tower: Tower):
	var container: ItemContainer = tower.get_item_container()
	_item_container_was_clicked(container)


#########################
###      Private      ###
#########################

func _add_move_action(item: Item, src_item_container: ItemContainer, dest_item_container: ItemContainer, clicked_index: int = -1) -> bool:
	var local_player: Player = PlayerManager.get_local_player()
	
	var verify_ok: bool = ActionMoveItem.verify(local_player, item, src_item_container, dest_item_container, clicked_index)
	if !verify_ok:
		return false

	var item_uid: int = item.get_uid()
	var src_container_uid: int = src_item_container.get_uid()
	var dest_container_uid: int = dest_item_container.get_uid()

	SFX.play_sfx_random_pitch(SfxPaths.DROP_ITEM)

	var action: Action = ActionMoveItem.make(item_uid, src_container_uid, dest_container_uid, clicked_index)
	_game_client.add_action(action)

	return true


func _add_swap_action(item_src: Item, item_dest: Item, src_item_container: ItemContainer, dest_item_container: ItemContainer) -> bool:
	var local_player: Player = PlayerManager.get_local_player()
	
	var verify_ok: bool = ActionSwapItems.verify(local_player, item_src, item_dest, src_item_container, dest_item_container)
	if !verify_ok:
		return false

	var item_uid_src: int = item_src.get_uid()
	var item_uid_dest: int = item_dest.get_uid()
	var src_container_uid: int = src_item_container.get_uid()
	var dest_container_uid: int = dest_item_container.get_uid()

	SFX.play_sfx_random_pitch(SfxPaths.DROP_ITEM)

	var action: Action = ActionSwapItems.make(item_uid_src, item_uid_dest, src_container_uid, dest_container_uid)
	_game_client.add_action(action)

	return true


func _get_local_item_stash() -> ItemContainer:
	var local_player: Player = PlayerManager.get_local_player()
	var local_item_stash: ItemContainer = local_player.get_item_stash()

	return local_item_stash


func _get_local_horadric_stash() -> ItemContainer:
	var local_player: Player = PlayerManager.get_local_player()
	var local_horadric_stash: ItemContainer = local_player.get_horadric_stash()

	return local_horadric_stash


func _move_in_progress() -> bool:
	return _mouse_state.get_state() == MouseState.enm.MOVE_ITEM


# When an item is clicked in an item container, two possible results:
# 
# 1. If no item is currently being moved, then we start
#    moving the clicked item.
# 
# 2. If an item is currently being moved, then we stop
#    moving the old item and start moving the clicked item.
# 
# 3. If player shift clicked, item is instantly moved from
#    current stash to item stash.
# 
# 4. If player ctrl clicked, item is instantly moved:
#	- a) from item stash to selected tower
# 	- b) from tower to horadric cube
func _item_was_clicked_in_item_container(container: ItemContainer, clicked_item: Item):
	if !_can_start_moving():
		return
	
	var clicked_on_moved_item: bool = _moved_item == clicked_item
	if clicked_on_moved_item:
		cancel()

		return

#	If an item is currently getting moved, swap the items
	if _move_in_progress():
		var success: bool = _add_swap_action(_moved_item, clicked_item, _source_container, container)

		if success:
			_end_move_process()
			get_viewport().set_input_as_handled()

		return

	var shift_click: bool = Input.is_action_pressed("shift")
	var ctrl_click: bool = Input.is_action_pressed("ctrl")
	
	var local_player: Player = PlayerManager.get_local_player()
	
	var item_stash: ItemContainer = local_player.get_item_stash()
	var horadric_cube: ItemContainer = local_player.get_horadric_stash()
	var tower_inventory: ItemContainer = null
	
	var selected_unit: Unit = local_player.get_selected_unit()
	
	if selected_unit is Tower:
		var selected_tower: Tower = selected_unit as Tower
		var tower_belongs_to_local_player: bool = selected_tower.belongs_to_local_player()
		
		# do not allow instant move to other players' towers regardless if it allowed otherwise
		if tower_belongs_to_local_player:
			tower_inventory = selected_tower.get_item_container()
	
	var item_is_in_item_stash: bool = container == item_stash
	var item_is_in_selected_tower: bool = container == tower_inventory
	
	var instant_move_type: InstantMoveType = InstantMoveType.NONE
	if shift_click:
		if item_is_in_item_stash:
			instant_move_type = InstantMoveType.FROM_ITEM_STASH_TO_HORADRIC_CUBE
		else:
			instant_move_type = InstantMoveType.FROM_ANY_TO_ITEM_STASH
	elif ctrl_click:
		if item_is_in_selected_tower:
			instant_move_type = InstantMoveType.FROM_TOWER_TO_HORADRIC_CUBE
		elif tower_inventory != null:
			instant_move_type = InstantMoveType.FROM_ANY_TO_TOWER

	if instant_move_type != InstantMoveType.NONE:
		var target_container: ItemContainer
		match instant_move_type:
			InstantMoveType.NONE: target_container = null
			InstantMoveType.FROM_ANY_TO_ITEM_STASH: target_container = item_stash
			InstantMoveType.FROM_ANY_TO_TOWER: target_container = tower_inventory
			InstantMoveType.FROM_TOWER_TO_HORADRIC_CUBE: target_container = horadric_cube
			InstantMoveType.FROM_ITEM_STASH_TO_HORADRIC_CUBE: target_container = horadric_cube

		if target_container == null:
			return
		
		# instant move forces swap with the last slot if target_container is at capacity
		var dest_has_space: bool = target_container.can_add_item(clicked_item)
		var dest_idx: int = -1
		if dest_has_space:
			_add_move_action(clicked_item, container, target_container)
		else:
			var dest_item: Item = target_container.get_item_at_index(dest_idx)
			_add_swap_action(clicked_item, dest_item, container, target_container)
		
		return
	
	_moved_item = clicked_item
	_moved_item.tree_exited.connect(_on_moved_item_tree_exited)
	_source_container = container
	_mouse_state.set_state(MouseState.enm.MOVE_ITEM)
	
	var item_cursor_icon: Texture2D = _get_item_cursor_icon(clicked_item)
	var hotspot: Vector2 = item_cursor_icon.get_size() / 2
	Input.set_custom_mouse_cursor(item_cursor_icon, Input.CURSOR_ARROW, hotspot)

	SFX.play_sfx_random_pitch(SfxPaths.PICKUP_ITEM, 0.0)

	get_viewport().set_input_as_handled()


# When an item container is clicked, we add the currently
# moved item to that container.
func _item_container_was_clicked(container: ItemContainer, clicked_index: int = -1):
	if !_move_in_progress():
		return

	var success: bool = _add_move_action(_moved_item, _source_container, container, clicked_index)

	if success:
		_end_move_process()
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


# NOTE: this function replicates the look of an ItemButton
# by combining a background image with item icon. Note that
# item icon needs to be resized to a smaller size and
# centered on the background - in ItemButton this function
# is done automatically by the theme.
func _get_item_cursor_icon(item: Item) -> Texture2D:
#	NOTE: this value is an estimate to account for margins
#	in item buttons
	const ITEM_ICON_SCALE: float = 0.85
#	NOTE: make cursor icon smaller than actual item button
#	to indicate that item is getting moved
	const CURSOR_ICON_SCALE: float = 0.80

	var viewport_scale: Vector2 = get_viewport().get_final_transform().get_scale()
	var cursor_icon_size: Vector2i = Vector2i(Constants.ITEM_BUTTON_SIZE * viewport_scale * CURSOR_ICON_SCALE)
	var item_icon_size: Vector2i = Vector2i(cursor_icon_size * ITEM_ICON_SCALE)

	var rarity: Rarity.enm = item.get_rarity()
	var background_texture: Texture2D
	match rarity:
		Rarity.enm.COMMON: background_texture = load("res://resources/ui_textures/common_unit_button_hover.tres")
		Rarity.enm.UNCOMMON: background_texture = load("res://resources/ui_textures/uncommon_unit_button_hover.tres")
		Rarity.enm.RARE: background_texture = load("res://resources/ui_textures/rare_unit_button_hover.tres")
		Rarity.enm.UNIQUE: background_texture = load("res://resources/ui_textures/unique_unit_button_hover.tres")
		
	var background_image: Image = background_texture.get_image()
	background_image.resize(cursor_icon_size.x, cursor_icon_size.y)
	
	var atlas_texture: Texture2D = ItemProperties.get_icon(item.get_id())
	var image: Image = atlas_texture.get_image()
	image.resize(item_icon_size.x, item_icon_size.y)
	
	var src_rect: Rect2i = Rect2i(Vector2i(0, 0), item_icon_size)
	var dst: Vector2i = Vector2i((cursor_icon_size - item_icon_size) / 2)
	background_image.blend_rect(image, src_rect, dst)

	var image_texture: ImageTexture = ImageTexture.create_from_image(background_image)

	return image_texture


# Can start moving an item if no other mouse action is
# currently in progress or if we're currently moving an
# item. Starting to move an item while another one is moved
# already performs an item swap.
func _can_start_moving() -> bool:
	var can_start: bool = _mouse_state.get_state() == MouseState.enm.NONE || _mouse_state.get_state() == MouseState.enm.MOVE_ITEM

	return can_start


#########################
###     Callbacks     ###
#########################

func _on_player_clicked_in_item_container(item_container: ItemContainer, clicked_index: int):
	var clicked_item: Item = item_container.get_item_at_index(clicked_index)
	
	if clicked_item != null:
		_item_was_clicked_in_item_container(item_container, clicked_item)
	else:
		_item_container_was_clicked(item_container, clicked_index)


# NOTE: add item to item stash at position 0 so that if
# there are many items and item stash is in scroll mode, the
# player will see the item appear on the left side of the
# item stash. Default scroll position for item stash
# displays the left side.
func _on_player_clicked_main_stash():
	var local_item_stash: ItemContainer = _get_local_item_stash()
	_item_container_was_clicked(local_item_stash)


func _on_item_flew_to_item_stash(item: Item):
	var player: Player = item.get_player()
	var item_stash: ItemContainer = player.get_item_stash()
	item_stash.add_item(item)


# NOTE: this callback handles the case of needing to cancel
# item move when item was removed from source container. For
# example, if item was dropped from tower via code.
func _on_moved_item_tree_exited():
	cancel()
