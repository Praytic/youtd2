class_name PlaytestBot extends Node


# Performs a rough playtest. Builds random sets of towers
# with random items and lets them attack some waves.
# Rebuilds new towers periodically.

# Increase config/update_ticks_per_physics_tick to run the
# playtest at faster speed.

enum TowerSelectType {
	RANDOM,
	MANUAL,
}

const TOWER_SELECT_TYPE: TowerSelectType = TowerSelectType.MANUAL
const RANDOM_TOWER_COUNT: int = 30
const MANUAL_TOWER_LIST: Array[int] = [391, 115, 120, 360, 135, 149, 162, 269, 186, 192, 198, 209, 286, 233, 266, 279, 304, 307, 391, 115, 120]

const ADD_RANDOM_ITEMS: bool = true
const TIME_PER_SET: float = 5 * 60
# NOTE: (2,2) is the tip of the corner of buildable area
const POSITIONS_ORIGIN: Vector2 = Vector2(500, 200)
const POSITIONS_X_RANGE: Array = [-10, 10]
const POSITIONS_Y_RANGE: Array = [-20, 15]

static var item_id_list: Array
static var oil_id_list: Array
static var built_tower_list: Array[Tower] = []
static var all_tower_id_list: Array
static var position_list: Array


static func run(build_space: BuildSpace):
	all_tower_id_list = TowerProperties.get_tower_id_list()
	
	var regular_type_string: String = ItemType.convert_to_string(ItemType.enm.REGULAR)
	PlaytestBot.item_id_list = ItemProperties.get_id_list_by_filter(ItemProperties.CsvProperty.TYPE, regular_type_string)

	var oil_type_string: String = ItemType.convert_to_string(ItemType.enm.OIL)
	oil_id_list = ItemProperties.get_id_list_by_filter(ItemProperties.CsvProperty.TYPE, oil_type_string)

	var position_count: int
	match TOWER_SELECT_TYPE:
		TowerSelectType.RANDOM: position_count = RANDOM_TOWER_COUNT
		TowerSelectType.MANUAL: position_count = MANUAL_TOWER_LIST.size()

	position_list = PlaytestBot._generate_position_list(build_space, position_count)

	while true:
		run_cycle()
		
		await Utils.create_manual_timer(TIME_PER_SET, build_space).timeout


static func run_cycle():
	for tower in built_tower_list:
		tower.remove_from_game()
	built_tower_list.clear()

#	NOTE: empty item stash to prevent overflow during testing
	var player: Player = PlayerManager.get_local_player()
	var item_stash: ItemContainer = player.get_item_stash()
	var item_list: Array[Item] = item_stash.get_item_list()
	for item in item_list:
		item_stash.remove_item(item)
		item.queue_free()

	var tower_id_list: Array
	match TOWER_SELECT_TYPE:
		TowerSelectType.RANDOM:
			tower_id_list = _generate_random_tower_list()
			MANUAL_TOWER_LIST.duplicate()
		TowerSelectType.MANUAL: tower_id_list = MANUAL_TOWER_LIST.duplicate()

	for i in range(0, tower_id_list.size()):
		var tower_id: int = tower_id_list[i]
		var build_pos: Vector2 = position_list[i]
		var tower: Tower = PlaytestBot._build_random_tower(tower_id, build_pos)
		built_tower_list.append(tower)


static func _generate_random_tower_list() -> Array[int]:
	var result: Array[int] = []

	for i in range(0, RANDOM_TOWER_COUNT):
		var tower_id: int = all_tower_id_list.pick_random()
		result.append(tower_id)

	return result


static func _build_random_tower(tower_id: int, unclamped_pos: Vector2) -> Tower:
	var player: Player = PlayerManager.get_local_player()
	
	var tower: Tower = Tower.make(tower_id, player)
	var build_pos_2nd_floor: Vector2 = VectorUtils.snap_canvas_pos_to_buildable_pos(unclamped_pos)
	var build_pos_1st_floor_canvas: Vector2 = build_pos_2nd_floor + Vector2(0, Constants.TILE_SIZE.y)
	var build_pos: Vector2 = VectorUtils.canvas_to_wc3_2d(build_pos_1st_floor_canvas)
	tower.set_position_wc3_2d(build_pos)
	Utils.add_object_to_world(tower)

	if ADD_RANDOM_ITEMS:
		_add_random_items_to_tower(tower)
	
	return tower


# NOTE: need to sometimes leave empty space in
# tower inventory to test some abilities which
# require non-full inventory
static func _add_random_items_to_tower(tower: Tower):
	var player: Player = PlayerManager.get_local_player()
	var free_slots: int = tower.count_free_slots()
	var item_count: int = randi_range(0, free_slots)

	for j in range(0, item_count):
		var random_item_id: int = PlaytestBot.item_id_list.pick_random()
		var random_item: Item = Item.create(player, random_item_id, Vector3.ZERO)
		random_item.pickup(tower)

	var oil_count: int = randi_range(0, 3)
	for j in range(0, oil_count):
		var random_oil_id: int = PlaytestBot.oil_id_list.pick_random()
		var random_oil: Item = Item.create(player, random_oil_id, Vector3.ZERO)
		random_oil.pickup(tower)


static func _generate_position_list(build_space: BuildSpace, count: int) -> Array[Vector2]:
	var result: Array[Vector2] = []

	var origin: Vector2 = POSITIONS_ORIGIN

	var offset_list: Array[Vector2] = [Vector2(0, 0), Vector2(-0.5, -0.5)]
	
	var local_player: Player = PlayerManager.get_local_player()

	for x in range(POSITIONS_X_RANGE[0], POSITIONS_X_RANGE[1]):
		for y in range(POSITIONS_Y_RANGE[0], POSITIONS_Y_RANGE[1]):
			for offset in offset_list:
				var position: Vector2 = origin + Constants.TILE_SIZE * (Vector2(x, y) + offset)
				var can_build: bool = build_space.can_build_at_pos(local_player, position)

				if can_build:
					result.append(position)
	
	result.sort_custom(func (a, b) -> bool:
		var dist_a: float = a.distance_to(origin)
		var dist_b: float = b.distance_to(origin)

		return dist_a < dist_b
		)
	
	print("Found %d positions. Reducing to %d closest positions." % [result.size(), count])
	
	if result.size() > count:
		result.resize(count)

	return result
