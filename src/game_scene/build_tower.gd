class_name BuildTower extends Node

# Contains functions which are called by GameScene to
# implement the process of building towers.

@export var _mouse_state: MouseState
@export var _map: Map
@export var _build_space: BuildSpace
@export var _tower_preview: TowerPreview
@export var _game_client: GameClient


#########################
###       Public      ###
#########################

func start(tower_id: int, player: Player):
	var enough_resources: bool = BuildTower.enough_resources_for_tower(tower_id, player)

	if !enough_resources:
		BuildTower.add_error_about_building_tower(tower_id, player)

		return

	var can_start_building: bool = _mouse_state.get_state() != MouseState.enm.NONE && _mouse_state.get_state() != MouseState.enm.BUILD_TOWER
	if can_start_building:
		return

	_mouse_state.set_state(MouseState.enm.BUILD_TOWER)

	_tower_preview.set_tower(tower_id)
	_tower_preview.show()

	_map.set_buildable_area_visible(true)


# NOTE: it would've been better to use Action verify() f-ns
# here but it doesn't work well. Need special checking
# logic.
func try_to_finish(player: Player):
	var tower_id: int = _tower_preview.get_tower_id()
	var mouse_pos: Vector2 = _tower_preview.get_global_mouse_position()
	var can_build: bool = _build_space.can_build_at_pos(mouse_pos)
	var tower_under_mouse: Tower = Utils.get_tower_at_canvas_pos(mouse_pos)
	var attempting_to_transform: bool = tower_under_mouse != null
	var transform_is_allowed: bool = Globals.game_mode_allows_transform()
	var can_transform: bool = attempting_to_transform && transform_is_allowed
	var enough_resources: bool = BuildTower.enough_resources_for_tower(tower_id, player)

	if !can_build && !can_transform:
		var error: String
		if attempting_to_transform && !transform_is_allowed:
			error = "Can't transform towers in build mode."
		else:
			error = "Can't build here."

		Messages.add_error(player, error)
	elif !enough_resources:
		BuildTower.add_error_about_building_tower(tower_id, player)
	elif can_transform:
		_transform_tower(tower_under_mouse, tower_id)
		cancel()
	else:
		_build_tower(tower_id)
		cancel()


func cancel():
	if _mouse_state.get_state() != MouseState.enm.BUILD_TOWER:
		return

	_mouse_state.set_state(MouseState.enm.NONE)
	_tower_preview.hide()
	_map.set_buildable_area_visible(false)


static func enough_resources_for_tower(tower_id: int, player: Player) -> bool:
	var enough_gold: bool = player.enough_gold_for_tower(tower_id)
	var enough_tomes: bool = player.enough_tomes_for_tower(tower_id)
	var enough_food: bool = player.enough_food_for_tower(tower_id)
	var enough_resources: bool = enough_gold && enough_tomes && enough_food

	return enough_resources


static func add_error_about_building_tower(tower_id: int, player: Player):
	var enough_gold: bool = player.enough_gold_for_tower(tower_id)
	var enough_tomes: bool = player.enough_tomes_for_tower(tower_id)
	var enough_food: bool = player.enough_food_for_tower(tower_id)

	if !enough_gold:
		Messages.add_error(player, "Not enough gold.")
	elif !enough_tomes:
		Messages.add_error(player, "Not enough tomes.")
	elif !enough_food:
		Messages.add_error(player, "Not enough food.")


#########################
###      Private      ###
#########################

func _build_tower(tower_id: int):
	var mouse_pos: Vector2 = _tower_preview.get_global_mouse_position()
	
	var random_pitch: float = Globals.local_rng.randf_range(1.0, 1.1)
	SFX.sfx_at_pos(SfxPaths.BUILD_TOWER, mouse_pos, -10.0, random_pitch)
	
	var action: Action = ActionBuildTower.make(tower_id, mouse_pos)
	_game_client.add_action(action)


func _transform_tower(prev_tower: Tower, new_tower_id: int):
	var local_player: Player = PlayerManager.get_local_player()
	var verify_ok: bool = ActionTransformTower.verify(local_player, prev_tower, new_tower_id)
	if !verify_ok:
		return

	var global_pos: Vector2 = _tower_preview.get_global_mouse_position()
	SFX.sfx_at_pos(SfxPaths.BUILD_TOWER, global_pos)
	
	var prev_tower_uid: int = prev_tower.get_uid()
	var action: Action = ActionTransformTower.make(prev_tower_uid, new_tower_id)
	_game_client.add_action(action)
