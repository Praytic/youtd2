class_name ActionProcessor extends Node


# Calls appropriate functions based on action type. Used by
# Simulation.


@export var _hud: HUD
@export var _map: Map
@export var _chat_commands: ChatCommands


func process_action(player_id: int, serialized_action: Dictionary):
	var action_type: Action.Type = serialized_action[Action.Field.TYPE]

	var action: Dictionary = serialized_action

	var player: Player = PlayerManager.get_player(player_id)

	if player == null:
		push_error("player is null")
		
		return

	match action_type:
		Action.Type.IDLE: return
		Action.Type.CHAT: ActionChat.execute(action, player, _hud, _chat_commands)
		Action.Type.BUILD_TOWER: ActionBuildTower.execute(action, player, _map)
		Action.Type.TRANSFORM_TOWER: ActionTransformTower.execute(action, player, _map)
		Action.Type.SELL_TOWER: ActionSellTower.execute(action, player, _map)
		Action.Type.SELECT_BUILDER: ActionSelectBuilder.execute(action, player, _hud)
		Action.Type.TOGGLE_AUTOCAST: ActionToggleAutocast.execute(action, player)
		Action.Type.CONSUME_ITEM: ActionConsumeItem.execute(action, player)
		Action.Type.DROP_ITEM: ActionDropItem.execute(action, player)
		Action.Type.MOVE_ITEM: ActionMoveItem.execute(action, player)
		Action.Type.AUTOFILL: ActionAutofill.execute(action, player)
		Action.Type.TRANSMUTE: ActionTransmute.execute(action, player)
		Action.Type.RESEARCH_ELEMENT: ActionResearchElement.execute(action, player, _hud)
		Action.Type.ROLL_TOWERS: ActionRollTowers.execute(action, player)
		Action.Type.START_NEXT_WAVE: ActionStartNextWave.execute(action, player, _hud)
