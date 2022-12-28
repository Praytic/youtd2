extends Node


# Map position is free if it contains only ground tiles
static func map_pos_is_free(map_parent: Node2D, buildable_area: TileMap, pos: Vector2) -> bool:
	return buildable_area.get_cellv(pos) != TileMap.INVALID_CELL


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
