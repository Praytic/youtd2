class_name BuildTower extends Node

# Contains functions which are called by GameScene to
# implement the process of building towers.

@export var _mouse_state: MouseState
@export var _build_space: BuildSpace
@export var _tower_preview: TowerPreview
@export var _game_client: GameClient


#########################
###       Public      ###
#########################

func start(tower_id: int, player: Player):
#	NOTE: check only gold and tomes before starting to build
#	tower. Ignore food, so that it's possible to transform a
#	tower in cases where player is already at food cap.
#	Transforming removes preceding tower so if final food
#	usage is under cap, it's acceptable.
	var enough_resources: bool = BuildTower.enough_resources_for_tower_only_gold_and_tomes(tower_id, player)

	if !enough_resources:
		BuildTower.add_error_about_tower_only_gold_and_tomes(tower_id, player)

		return

	var can_start_building: bool = _mouse_state.get_state() != MouseState.enm.NONE && _mouse_state.get_state() != MouseState.enm.BUILD_TOWER
	if can_start_building:
		return

	_mouse_state.set_state(MouseState.enm.BUILD_TOWER)

	_tower_preview.set_tower(tower_id)
	_tower_preview.show()

	EventBus.player_started_build_process.emit()


# NOTE: it would've been better to use Action verify() f-ns
# here but it doesn't work well. Need special checking
# logic.
func try_to_finish(player: Player):
	var tower_id: int = _tower_preview.get_tower_id()
	var mouse_pos: Vector2 = _tower_preview.get_global_mouse_position()
	var local_player: Player = PlayerManager.get_local_player()
	var can_build: bool = _build_space.can_build_at_pos(local_player, mouse_pos)
	var tower_under_mouse: Tower = Utils.get_tower_at_canvas_pos(mouse_pos)
	var attempting_to_transform: bool = tower_under_mouse != null
	var transform_is_allowed: bool = Globals.game_mode_allows_transform()
	var can_transform: bool = attempting_to_transform && transform_is_allowed
	var enough_resources_for_build: bool = BuildTower.enough_resources_for_tower(tower_id, player)

	var preceding_tower_id: int
	if tower_under_mouse != null:
		preceding_tower_id = tower_under_mouse.get_id()
	else:
		preceding_tower_id = -1
	var enough_resources_for_transform: bool = BuildTower.enough_resources_for_tower(tower_id, player, preceding_tower_id)

	if !can_build && !can_transform:
		var error: String
		if attempting_to_transform && !transform_is_allowed:
			error = tr("MESSAGE_CANT_TRANSFORM_IN_BUILD_MODE")
		else:
			error = tr("MESSAGE_CANT_BUILD_HERE")

		Utils.add_ui_error(player, error)
	elif can_transform:
		if enough_resources_for_transform:
			_transform_tower(tower_under_mouse, tower_id)
			cancel()
		else:
			BuildTower.add_error_about_building_tower(tower_id, player, preceding_tower_id)
	else:
		if enough_resources_for_build:
			_build_tower(tower_id)
			cancel()
		else:
			BuildTower.add_error_about_building_tower(tower_id, player)


func cancel():
	if _mouse_state.get_state() != MouseState.enm.BUILD_TOWER:
		return

	_mouse_state.set_state(MouseState.enm.NONE)
	_tower_preview.hide()
	EventBus.player_stopped_build_process.emit()


static func enough_resources_for_tower_only_gold_and_tomes(tower_id: int, player: Player) -> bool:
	var enough_gold: bool = player.enough_gold_for_tower(tower_id)
	var enough_tomes: bool = player.enough_tomes_for_tower(tower_id)
	var enough_resources: bool = enough_gold && enough_tomes

	return enough_resources


# NOTE: if preceding_tower_id is given, then this f-n will
# consider the food cost of the preceding tower. For
# example, if player is 1 away from food cap (54/55) and is
# transforming tower which costs 4 food into another tower
# which also costs 4 food, then food check will be okay
# because end result will still be under food cap.
static func enough_resources_for_tower(tower_id: int, player: Player, preceding_tower_id: int = -1) -> bool:
	var enough_gold: bool = player.enough_gold_for_tower(tower_id)
	var enough_tomes: bool = player.enough_tomes_for_tower(tower_id)
	var enough_food: bool = player.enough_food_for_tower(tower_id, preceding_tower_id)
	var enough_resources: bool = enough_gold && enough_tomes && enough_food

	return enough_resources


static func add_error_about_tower_only_gold_and_tomes(tower_id: int, player: Player):
	var enough_gold: bool = player.enough_gold_for_tower(tower_id)
	var enough_tomes: bool = player.enough_tomes_for_tower(tower_id)

	if !enough_gold:
		Utils.add_ui_error(player, Utils.tr("MESSAGE_NOT_ENOUGH_GOLD"))
	elif !enough_tomes:
		Utils.add_ui_error(player, Utils.tr("MESSAGE_NOT_ENOUGH_TOMES_FOR_BUILD"))


static func add_error_about_building_tower(tower_id: int, player: Player, preceding_tower_id: int = -1):
	var enough_gold: bool = player.enough_gold_for_tower(tower_id)
	var enough_tomes: bool = player.enough_tomes_for_tower(tower_id)
	var enough_food: bool = player.enough_food_for_tower(tower_id, preceding_tower_id)

	if !enough_gold:
		Utils.add_ui_error(player, Utils.tr("MESSAGE_NOT_ENOUGH_GOLD"))
	elif !enough_tomes:
		Utils.add_ui_error(player, Utils.tr("MESSAGE_NOT_ENOUGH_TOMES_FOR_BUILD"))
	elif !enough_food:
		Utils.add_ui_error(player, Utils.tr("MESSAGE_NOT_ENOUGH_FOOD"))


#########################
###      Private      ###
#########################

func _build_tower(tower_id: int):
	var mouse_pos: Vector2 = _tower_preview.get_global_mouse_position()
	
	var random_pitch: float = Globals.local_rng.randf_range(1.0, 1.1)
	SFX.sfx_at_pos(SfxPaths.BUILD_TOWER, mouse_pos, 0.0, random_pitch)
	
	var action: Action = ActionBuildTower.make(tower_id, mouse_pos)
	_game_client.add_action(action)


func _transform_tower(prev_tower: Tower, new_tower_id: int):
	var local_player: Player = PlayerManager.get_local_player()
	var verify_ok: bool = ActionTransformTower.verify(local_player, prev_tower, new_tower_id)
	if !verify_ok:
		return

	var global_pos: Vector2 = _tower_preview.get_global_mouse_position()
	var random_pitch: float = Globals.local_rng.randf_range(1.0, 1.1)
	SFX.sfx_at_pos(SfxPaths.BUILD_TOWER, global_pos, 0.0, random_pitch)
	
	var prev_tower_uid: int = prev_tower.get_uid()
	var action: Action = ActionTransformTower.make(prev_tower_uid, new_tower_id)
	_game_client.add_action(action)
