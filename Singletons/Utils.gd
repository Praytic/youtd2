extends Node


# Map position is free if it contains only ground tiles
static func map_pos_is_free(buildable_area: TileMap, pos: Vector2) -> bool:
	return buildable_area.get_cellv(pos) != TileMap.INVALID_CELL
onready var object_container = get_tree().get_root().get_node("GameScene").get_node("Map").get_node("MobYSort")


func list_files_in_directory(path: String, regex_search: RegEx = null) -> Array:
	var files = []
	var dir = Directory.new()
	dir.open(path)
	dir.list_dir_begin()
	if not regex_search:
		regex_search = RegEx.new()
		regex_search.compile("^(?!\\.).*$")
	
	while true:
		var file = dir.get_next()
		if file == "":
			break
		elif regex_search.search(file):
			files.append(file)

	dir.list_dir_end()

	return files


func circle_shape_set_radius(collision_shape: CollisionShape2D, radius: float):
	var shape: Shape2D = collision_shape.shape
	var circle_shape: CircleShape2D = shape as CircleShape2D
	
	if circle_shape == null:
		print_debug("Failed to cast area shape to circle")
		return
	
	circle_shape.radius = radius

func randi_range(value_min: int, value_max: int):
	var out = randi() % (value_max - value_min + 1) + value_min
	return out


func get_mob_list_in_range(position: Vector2, range_value: float) -> Array:
	var mob_list: Array = []

	for node in object_container.get_children():
		if node is Mob:
			var mob: Mob = node as Mob
			var distance: float = position.distance_to(mob.position)
			var mob_is_in_range = distance < range_value

			if mob_is_in_range:
				mob_list.append(mob)

	return mob_list
