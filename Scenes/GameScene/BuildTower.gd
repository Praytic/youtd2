class_name BuildTower extends Node

# Contains functions which are called by GameScene to
# implement the process of building towers.

@export var _mouse_state: MouseState
@export var _map: Map
@export var _tower_preview: TowerPreview
@export var _simulation: Simulation


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


func try_to_finish(player: Player):
	var tower_id: int = _tower_preview.get_tower_id()
	var mouse_pos: Vector2 = _tower_preview.get_global_mouse_position()
	var can_build: bool = _map.can_build_at_pos(mouse_pos)
	var can_transform: bool = _map.can_transform_at_pos(mouse_pos)
	var tower_under_mouse: Tower = Utils.get_tower_at_position(mouse_pos)
	var attempting_to_transform: bool = tower_under_mouse != null
	var enough_resources: bool = BuildTower.enough_resources_for_tower(tower_id, player)

	if !can_build && !can_transform:
		var error: String
		if attempting_to_transform && !Globals.game_mode_allows_transform():
			error = "Can't transform towers in build mode."
		else:
			error = "Can't build here."

		Messages.add_error(player, error)
	elif !enough_resources:
		BuildTower.add_error_about_building_tower(tower_id, player)
	elif can_transform:
		_transform_tower(tower_id, tower_under_mouse, player)
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


#########################
###      Private      ###
#########################

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


func _build_tower(tower_id: int):
	var mouse_pos: Vector2 = _tower_preview.get_global_mouse_position()
	var build_position: Vector2 = _map.get_pos_on_tilemap_clamped(mouse_pos)
	
	SFX.sfx_at_pos("res://Assets/SFX/build_tower.mp3", build_position)
	
	EventBus.player_performed_tutorial_advance_action.emit("build_tower")
	
	var action: Action = ActionBuildTower.make(tower_id, build_position)
	_simulation.add_action(action)


func _transform_tower(new_tower_id: int, prev_tower: Tower, player: Player):
	player.remove_food_for_tower(prev_tower.get_id())
	player.add_food_for_tower(new_tower_id)

	var new_tower: Tower = Tower.make(new_tower_id, player)
	new_tower.position = prev_tower.position
	new_tower._temp_preceding_tower = prev_tower
	Utils.add_object_to_world(new_tower)

#	Refund build cost for previous tower
	var refund_value: int = _get_transform_refund(prev_tower.get_id(), new_tower_id)
	prev_tower.get_player().give_gold(refund_value, prev_tower, false, true)

#	Spend build cost for new tower
	var build_cost: float = TowerProperties.get_cost(new_tower_id)
	player.spend_gold(build_cost)

# 	NOTE: don't modify tome count because transform is
# 	enabled only in random modes and tome costs are 0 in
# 	random mode

	prev_tower.remove_from_game()

	SFX.sfx_at_unit("res://Assets/SFX/build_tower.mp3", new_tower)


# This is the value refunded when a tower is transformed
# into another tower
func _get_transform_refund(prev_tower_id: int, new_tower_id: int) -> int:
	var prev_cost: int = TowerProperties.get_cost(prev_tower_id)
	var prev_family: int = TowerProperties.get_family(prev_tower_id)
	var new_family: int = TowerProperties.get_family(new_tower_id)
	var family_is_same: bool = prev_family == new_family

	var transform_refund: int

	if family_is_same:
		transform_refund = floori(prev_cost * 1.0)
	else:
		transform_refund = floori(prev_cost * 0.75)

	return transform_refund
