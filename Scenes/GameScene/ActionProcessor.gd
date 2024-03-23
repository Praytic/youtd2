class_name ActionProcessor extends Node


# Contains functions which processes actions. Used by Simulation.


@export var _player_container: PlayerContainer
@export var _hud: HUD
@export var _map: Map
@export var _chat_commands: ChatCommands


func process_action(player_id: int, serialized_action: Dictionary):
	var action: Action = Action.new(serialized_action)
	
	var action_type: Action.Type = action.type

	var player: Player = _player_container.get_player(player_id)

	if player == null:
		push_error("player is null")
		
		return

	match action_type:
		Action.Type.IDLE: return
		Action.Type.CHAT: _chat(player, serialized_action)
		Action.Type.BUILD_TOWER: _build_tower(player, serialized_action)
		Action.Type.SELL_TOWER: _sell_tower(player, serialized_action)
		Action.Type.SELECT_BUILDER: _select_builder(player, serialized_action)


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
	var position: Vector2 = action.position

	var verify_ok: bool = _verify_build_tower(player, tower_id, position)

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

#	NOTE: need to add tile height to position because towers are built at ground floor
	new_tower.position = position + Vector2(0, Constants.TILE_SIZE.y)
	
	_map.add_space_occupied_by_tower(new_tower)

	Utils.add_object_to_world(new_tower)


func _verify_build_tower(player: Player, tower_id: int, position: Vector2) -> bool:
	var enough_resources: bool = BuildTower.enough_resources_for_tower(tower_id, player)

	if !enough_resources:
		BuildTower.add_error_about_building_tower(tower_id, player)

		return false

	var can_build: bool = _map.can_build_at_pos(position)

	if !can_build:
		Messages.add_error(player, "Can't build here")

		return false

	return true


func _sell_tower(player: Player, serialized_action: Dictionary):
	var action: ActionSellTower = ActionSellTower.new(serialized_action)
	var tower_unit_id: int = action.tower_unit_id

	var tower: Tower = _get_tower_by_uid(tower_unit_id)

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

	var local_player: Player = _player_container.get_local_player()

	if player == local_player:
		var local_builder: Builder = local_player.get_builder()
		var local_builder_name: String = local_builder.get_display_name()
		_hud.set_local_builder_name(local_builder_name)

		if local_builder.get_adds_extra_recipes():
			_hud.enable_extra_recipes()


func _get_tower_by_uid(tower_unit_id: int) -> Tower:
	var tower_list: Array[Tower] = Utils.get_tower_list()

	for tower in tower_list:
		if tower.get_uid() == tower_unit_id:
			return tower

	push_error("Failled to find tower with uid: ", tower_unit_id)

	return null
