class_name ActionProcessor extends Node


# Contains functions which processes actions. Used by Simulation.


@export var _hud: HUD
@export var _map: Map
@export var _chat_commands: ChatCommands


func process_action(player_id: int, serialized_action: Dictionary):
	var action: Action = Action.new(serialized_action)
	
	var action_type: Action.Type = action.type

	var player: Player = PlayerManager.get_player(player_id)

	if player == null:
		push_error("player is null")
		
		return

	match action_type:
		Action.Type.IDLE: return
		Action.Type.CHAT: _chat(player, serialized_action)
		Action.Type.BUILD_TOWER: _build_tower(player, serialized_action)
		Action.Type.SELL_TOWER: _sell_tower(player, serialized_action)
		Action.Type.SELECT_BUILDER: _select_builder(player, serialized_action)
		Action.Type.TOGGLE_AUTOCAST: _toggle_autocast(player, serialized_action)
		Action.Type.CONSUME_ITEM: _consume_item(player, serialized_action)
		Action.Type.DROP_ITEM: _drop_item(player, serialized_action)
		Action.Type.MOVE_ITEM: _move_item(player, serialized_action)
		Action.Type.AUTOFILL: _autofill(player, serialized_action)
		Action.Type.TRANSMUTE: _transmute(player, serialized_action)


#########################
###      Private      ###
#########################

func _chat(player: Player, serialized_action: Dictionary):
	var action: ActionChat = ActionChat.new(serialized_action)
	var message: String = action.chat_message
	
	var is_chat_command: bool = !message.is_empty() && message[0] == "/"
	
	if is_chat_command:
		_chat_commands.process_command(player, message)
	else:
		_hud.add_chat_message(player.get_id(), message)


# TODO: build tower action looks very bad with the delay.
# Need to add a temporary animation like a cloud of dust,
# while the tower "builds".
func _build_tower(player: Player, serialized_action: Dictionary):
	var action: ActionBuildTower = ActionBuildTower.new(serialized_action)
	var tower_id: int = action.tower_id
	var mouse_pos: Vector2 = action.position

	var verify_ok: bool = _verify_build_tower(player, tower_id, mouse_pos)

	if !verify_ok:
		return

	player.add_food_for_tower(tower_id)
	
	var build_cost: float = TowerProperties.get_cost(tower_id)
	player.spend_gold(build_cost)
	
	var tomes_cost: int = TowerProperties.get_tome_cost(tower_id)
	player.spend_tomes(tomes_cost)

	if Globals.get_game_mode() != GameMode.enm.BUILD:
		var tower_stash: TowerStash = player.get_tower_stash()
		tower_stash.remove_tower(tower_id)

	var new_tower: Tower = Tower.make(tower_id, player)

#	NOTE: need to add tile height to position because towers
#	are built at ground floor
	var build_position: Vector2 = _map.get_pos_on_tilemap_clamped(mouse_pos)
	new_tower.position = build_position + Vector2(0, Constants.TILE_SIZE.y)
	
	_map.add_space_occupied_by_tower(new_tower)

	Utils.add_object_to_world(new_tower)


func _verify_build_tower(player: Player, tower_id: int, mouse_pos: Vector2) -> bool:
	var enough_resources: bool = BuildTower.enough_resources_for_tower(tower_id, player)

	if !enough_resources:
		BuildTower.add_error_about_building_tower(tower_id, player)

		return false

	var can_build: bool = _map.can_build_at_pos(mouse_pos)

	if !can_build:
		Messages.add_error(player, "Can't build here")

		return false

	return true


func _sell_tower(player: Player, serialized_action: Dictionary):
	var action: ActionSellTower = ActionSellTower.new(serialized_action)
	var tower_uid: int = action.tower_unit_id

	var tower_node: Node = GroupManager.get_by_uid("towers", tower_uid)
	var tower: Tower = tower_node as Tower

	if tower == null:
		push_error("Sell tower action failed")

		return

# 	Return tower items to item stash
	var item_list: Array[Item] = tower.get_items()

	for item in item_list:
		item.drop()
		item.fly_to_stash(0.0)

	var tower_id: int = tower.get_id()
	var sell_price: int = TowerProperties.get_sell_price(tower_id)
	player.give_gold(sell_price, tower, false, true)
	player.remove_food_for_tower(tower_id)

	_map.clear_space_occupied_by_tower(tower)

	tower.remove_from_game()


func _select_builder(player: Player, serialized_action: Dictionary):
	var action: ActionSelectBuilder = ActionSelectBuilder.new(serialized_action)
	var builder_id: int = action.builder_id
	
	player.set_builder(builder_id)

	var local_player: Player = PlayerManager.get_local_player()

	if player == local_player:
		var local_builder: Builder = local_player.get_builder()
		var local_builder_name: String = local_builder.get_display_name()
		_hud.set_local_builder_name(local_builder_name)

		if local_builder.get_adds_extra_recipes():
			_hud.enable_extra_recipes()


func _toggle_autocast(player: Player, serialized_action: Dictionary):
	var action: ActionToggleAutocast = ActionToggleAutocast.new(serialized_action)
	var autocast_uid: int = action.autocast_uid

	var autocast_node: Node = GroupManager.get_by_uid("autocasts", autocast_uid)
	var autocast: Autocast = autocast_node as Autocast

	if autocast == null:
		Messages.add_error(player, "Failed to toggle autocast.")

		return

	autocast.toggle_auto_mode()


func _consume_item(player: Player, serialized_action: Dictionary):
	var action: ActionConsumeItem = ActionConsumeItem.new(serialized_action)
	var item_uid: int = action.item_uid

	var item_node: Node = GroupManager.get_by_uid("items", item_uid)
	var item: Item = item_node as Item

	if item == null:
		Messages.add_error(player, "Failed to toggle item.")

		return

	item.consume()


func _drop_item(player: Player, serialized_action: Dictionary):
	var action: ActionDropItem = ActionDropItem.new(serialized_action)
	var item_uid: int = action.item_uid
	var position: Vector2 = action.position
	var src_item_container_uid: int = action.src_item_container_uid

	var item: Item = GroupManager.get_by_uid("items", item_uid)
	var src_item_container: ItemContainer = GroupManager.get_by_uid("item_containers", src_item_container_uid)

	if item == null || src_item_container == null:
		Messages.add_error(player, "Failed to drop item.")

		return

	src_item_container.remove_item(item)

	Item.make_item_drop(item, position)
	item.fly_to_stash(0.0)


func _move_item(player: Player, serialized_action: Dictionary):
	var action: ActionMoveItem = ActionMoveItem.new(serialized_action)
	var item_uid: int = action.item_uid
	var src_item_container_uid: int = action.src_item_container_uid
	var dest_item_container_uid: int = action.dest_item_container_uid

	var item: Item = GroupManager.get_by_uid("items", item_uid)
	var src_item_container: ItemContainer = GroupManager.get_by_uid("item_containers", src_item_container_uid)
	var dest_item_container: ItemContainer = GroupManager.get_by_uid("item_containers", dest_item_container_uid)

	if item == null || src_item_container == null || dest_item_container == null:
		Messages.add_error(player, "Failed to drop item.")

		return

	if !MoveItem.verify_move(player, item, dest_item_container):
		return

	src_item_container.remove_item(item)
	dest_item_container.add_item(item)


func _autofill(player: Player, serialized_action: Dictionary):
	var action: ActionAutofill = ActionAutofill.new(serialized_action)
	var recipe: HoradricCube.Recipe = action.recipe
	var rarity_filter: Array = action.rarity_filter

	HoradricCube.autofill(player, recipe, rarity_filter)


func _transmute(player: Player, _serialized_action: Dictionary):
	HoradricCube.transmute(player)
