extends Node

# Singleton that manages building towers

signal tower_built(tower_id)


# List of offsets from tower center position which are used
# to generate positions of quarter tiles.
const QUARTER_OFFSET_LIST_NORMAL: Array[Vector2] = [
	Constants.TILE_SIZE * Vector2(0, -0.25),
	Constants.TILE_SIZE * Vector2(0, 0.25),
	Constants.TILE_SIZE * Vector2(0.25, 0),
	Constants.TILE_SIZE * Vector2(-0.25, 0),
]

# Alternative list for Maverick builder which doesn't allow
# adjacent towers.
const QUARTER_OFFSET_LIST_BIG: Array[Vector2] = [
	Constants.TILE_SIZE * Vector2(0, 0.25),
	Constants.TILE_SIZE * Vector2(0, -0.25),
	Constants.TILE_SIZE * Vector2(0.25, 0),
	Constants.TILE_SIZE * Vector2(-0.25, 0),

	Constants.TILE_SIZE * Vector2(0.75, 0),
	Constants.TILE_SIZE * Vector2(-0.75, 0),
	Constants.TILE_SIZE * Vector2(0, 0.75),
	Constants.TILE_SIZE * Vector2(0, -0.75),

	Constants.TILE_SIZE * Vector2(0.75, 0),
	Constants.TILE_SIZE * Vector2(-0.75, 0),
	Constants.TILE_SIZE * Vector2(0, 0.75),
	Constants.TILE_SIZE * Vector2(0, -0.75),

	Constants.TILE_SIZE * Vector2(0.25, 0.5),
	Constants.TILE_SIZE * Vector2(-0.25, 0.5),
	Constants.TILE_SIZE * Vector2(0.25, -0.5),
	Constants.TILE_SIZE * Vector2(-0.25, -0.5),

	Constants.TILE_SIZE * Vector2(0.5, 0.25),
	Constants.TILE_SIZE * Vector2(-0.5, 0.25),
	Constants.TILE_SIZE * Vector2(0.5, -0.25),
	Constants.TILE_SIZE * Vector2(-0.5, -0.25),
]

var _tower_preview: TowerPreview = null


# List of positions of quarter tiles which are occupied by
# towers. Each tower occupies 4 quarter tiles.
var _occupied_quarter_list: Array[Vector2] = []


#########################
###     Built-in      ###
#########################

func _unhandled_input(event):
	if !in_progress():
		return

	var cancelled: bool = event.is_action_released("ui_cancel") || event.is_action_released("right_click")
	
	if cancelled:
		cancel()

	var left_click: bool = event.is_action_released("left_click")
	
	if left_click:
		_try_to_build()


#########################
###       Public      ###
#########################

func in_progress() -> bool:
	return MouseState.get_state() == MouseState.enm.BUILD_TOWER


func start(tower_id: int):
	var can_start: bool = MouseState.get_state() != MouseState.enm.NONE && MouseState.get_state() != MouseState.enm.BUILD_TOWER
	if can_start:
		return

	cancel()
	MouseState.set_state(MouseState.enm.BUILD_TOWER)

	_tower_preview = Globals.tower_preview_scene.instantiate()
	_tower_preview.tower_id = tower_id

	var game_scene: Node = get_tree().get_root().get_node("GameScene")
	game_scene.add_child(_tower_preview)


func cancel():
	if !in_progress():
		return

	MouseState.set_state(MouseState.enm.NONE)

	_tower_preview.queue_free()


func quarter_is_occupied(position: Vector2) -> bool:
	var occupied: bool = _occupied_quarter_list.has(position)

	return occupied


func tower_exists_on_position(position: Vector2) -> bool:
	var tower_at_position: Tower = _get_tower_at_position(position)
	var has_tower: bool = tower_at_position != null

	return has_tower


# Returns true if there are enough resources for tower
func enough_resources_for_tower(tower_id: int) -> bool:
	var enough_gold: bool = GoldControl.enough_gold_for_tower(tower_id)
	var enough_tomes: bool = KnowledgeTomesManager.enough_tomes_for_tower(tower_id)
	var enough_food: bool = FoodManager.enough_food_for_tower(tower_id)
	var enough_resources: bool = enough_gold && enough_tomes && enough_food

	return enough_resources


func add_error_about_resources(tower_id: int):
	var enough_gold: bool = GoldControl.enough_gold_for_tower(tower_id)
	var enough_tomes: bool = KnowledgeTomesManager.enough_tomes_for_tower(tower_id)
	var enough_food: bool = FoodManager.enough_food_for_tower(tower_id)

	if !enough_gold:
		Messages.add_error("Not enough gold.")
	elif !enough_tomes:
		Messages.add_error("Not enough tomes.")
	elif !enough_food:
		Messages.add_error("Not enough food.")


func clear_space_occupied_by_tower(tower: Tower):
#	NOTE: need to subtract tile height because tower's
#	position is on the ground and occupied spaces are on the
#	2nd floor
	var visual_position: Vector2 = tower.position - Vector2(0, Constants.TILE_SIZE.y)

	for offset in _get_quarter_offset_list():
		var pos: Vector2 = visual_position + offset
		_occupied_quarter_list.erase(pos)


#########################
###      Private      ###
#########################

func _get_tower_at_position(visual_position: Vector2) -> Tower:
	var position: Vector2 = visual_position + Vector2(0, Constants.TILE_SIZE.y)

	var tower_node_list: Array = get_tree().get_nodes_in_group("towers")

	for tower_node in tower_node_list:
		var tower: Tower = tower_node as Tower
		var this_position: Vector2 = tower.position
		var position_match: bool = position.is_equal_approx(this_position)

		if position_match:
			return tower

	return null


func _try_to_build():
	var tower_id: int = _tower_preview.tower_id
	var map: Map = get_tree().get_root().get_node("GameScene/Map")
	var can_build: bool = map.can_build_at_mouse_pos()
	var can_transform: bool = map.can_transform_at_mouse_pos()
	var mouse_pos: Vector2 = map.get_mouse_pos_on_tilemap_clamped()
	var tower_under_mouse: Tower = _get_tower_at_position(mouse_pos)
	var attempting_to_transform: bool = tower_under_mouse != null
	var enough_resources: bool = BuildTower.enough_resources_for_tower(tower_id)

	if !can_build && !can_transform:
		var error: String
		if attempting_to_transform && !PregameSettings.game_mode_allows_transform():
			error = "Can't transform towers in build mode."
		else:
			error = "Can't build here."

		Messages.add_error(error)
	elif !enough_resources:
		add_error_about_resources(tower_id)
	elif can_transform:
		_transform_tower(tower_id, tower_under_mouse)
	else:
		_build_tower(tower_id)


func _transform_tower(new_tower_id: int, prev_tower: Tower):
	FoodManager.remove_tower(prev_tower.get_id())
	FoodManager.add_tower(new_tower_id)

	var new_tower: Tower = TowerManager.get_tower(new_tower_id)
	new_tower.position = prev_tower.position
	new_tower._temp_preceding_tower = prev_tower
	Utils.add_object_to_world(new_tower)
	tower_built.emit(new_tower_id)

#	Refund build cost for previous tower
	var refund_value: int = _get_transform_refund(prev_tower.get_id(), new_tower_id)
	prev_tower.get_player().give_gold(refund_value, prev_tower, false, true)

#	Spend build cost for new tower
	var build_cost: float = TowerProperties.get_cost(new_tower_id)
	GoldControl.spend_gold(build_cost)

# 	NOTE: don't modify tome count because transform is
# 	enabled only in random modes and tome costs are 0 in
# 	random mode

	prev_tower.queue_free()

	SFX.sfx_at_unit("res://Assets/SFX/build_tower.mp3", new_tower)

	cancel()


func _build_tower(tower_id: int):
	var new_tower: Tower = TowerManager.get_tower(tower_id)
	var map: Map = get_tree().get_root().get_node("GameScene/Map")
	var visual_position: Vector2 = map.get_mouse_pos_on_tilemap_clamped()
	var build_position: Vector2 = visual_position + Vector2(0, Constants.TILE_SIZE.y)
	new_tower.position = build_position
	Utils.add_object_to_world(new_tower)
	tower_built.emit(tower_id)
	FoodManager.add_tower(tower_id)

	var build_cost: float = TowerProperties.get_cost(tower_id)
	GoldControl.spend_gold(build_cost)

	var tomes_cost: int = TowerProperties.get_tome_cost(tower_id)
	KnowledgeTomesManager.spend(tomes_cost)

	SFX.sfx_at_unit("res://Assets/SFX/build_tower.mp3", new_tower)
	
	Globals.built_at_least_one_tower = true

#	NOTE: use visual_position for quarters because we need
#	2nd floor position. Visual position is on 2nd floor
#	while build position is on 1st floor.
	for offset in _get_quarter_offset_list():
		var pos: Vector2 = visual_position + offset
		_occupied_quarter_list.append(pos)

	cancel()


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


func _get_quarter_offset_list() -> Array[Vector2]:
	if Globals.get_builder_allows_adjacent_towers():
		return QUARTER_OFFSET_LIST_NORMAL
	else:
		return QUARTER_OFFSET_LIST_BIG
