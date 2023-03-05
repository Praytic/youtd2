extends Node


@onready var floating_text_scene: PackedScene = preload("res://Scenes/FloatingText.tscn")

# Map position is free if it contains only ground tiles
static func map_pos_is_free(buildable_area: TileMap, pos: Vector2) -> bool:
	return buildable_area.get_cellv(pos) != TileMap.INVALID_CELL
@onready var object_container = get_tree().get_root().get_node("GameScene").get_node("Map").get_node("MobYSort")
@onready var _game_scene: Node = get_tree().get_root().get_node("GameScene")

var _loaded_sfx_map: Dictionary = {}
var _sfx_player_list: Array = []


func sfx_at_unit(sfx_name: String, unit: Unit):
	var sfx_exists: bool = FileAccess.file_exists(sfx_name)

	if !sfx_exists:
		return

	if !_loaded_sfx_map.has(sfx_name):
		var sfx_stream: AudioStreamMP3 = _load_sfx(sfx_name)
		_loaded_sfx_map[sfx_name] = sfx_stream

	var sfx_player: AudioStreamPlayer2D = _get_sfx_player()

	var sfx_stream: AudioStreamMP3 = _loaded_sfx_map[sfx_name]
	sfx_player.set_stream(sfx_stream)
	sfx_player.global_position = unit.get_visual_position()
	sfx_player.play()


# TODO: implement _body_part parameter. Example body parts:
# "chest", "head", "origin".
func sfx_on_unit(sfx_name: String, unit: Unit, _body_part: String):
	sfx_at_unit(sfx_name, unit)


func list_files_in_directory(path: String, regex_search: RegEx = null) -> Array:
	var files = []
	var dir = DirAccess.open(path)
	dir.list_dir_begin() # TODOGODOT4 fill missing arguments https://github.com/godotengine/godot/pull/40547
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


# Returns random number in [value_min, value_max] range,
# inclusive
func randi_range(value_min: int, value_max: int):
	var out = randi() % (value_max - value_min + 1) + value_min
	return out


# Chance should be in range [0.0, 1.0]
# To get chance for event with 10% occurence, call rand_chance(0.1)
func rand_chance(chance: float) -> bool:
	var clamped_chance: float = min(1.0, max(0.0, chance))
	var random_float: float = randf()
	var chance_success = random_float <= clamped_chance

	return chance_success

func get_mob_list_in_range(position: Vector2, range_value: float) -> Array:
	var mob_list: Array = []

	for node in object_container.get_children():
		if node is Mob:
			var mob: Mob = node as Mob
			var distance: float = position.distance_to(mob.position)
			var mob_is_in_range = distance < range_value

			if mob_is_in_range && !mob.is_invisible():
				mob_list.append(mob)

	return mob_list


class DistanceSorter:
	var origin = Vector2.ZERO

	func sort(a: Unit, b: Unit):
		return a.position.distance_to(origin) < b.position.distance_to(origin)


func sort_unit_list_by_distance(unit_list: Array, position: Vector2):
	var sorter: DistanceSorter = DistanceSorter.new()
	sorter.origin = position
	unit_list.sort_custom(Callable(sorter,"sort"))


# TODO: figure out what are the mystery float parameters,
# probably related to tween
func display_floating_text_x(text: String, unit: Unit, color_r: int, color_g: int, color_b: int, _mystery_float_1: float, _mystery_float_2: float, time: float):
	var floating_text = floating_text_scene.instantiate()
	floating_text.text = text
	floating_text.color = Color(color_r / 255.0, color_g / 255.0, color_b / 255.0)
	floating_text.duration = time
	unit.add_child(floating_text)


# TODO: implement, not sure what the difference is between this and then _x version
func display_floating_text(text: String, unit: Unit, color_r: int, color_g: int, color_b: int):
	display_floating_text_x(text, unit, color_r, color_g, color_b, 0.0, 0.0, 1.0)


func display_small_floating_text(text: String, unit: Unit, color_r: int, color_g: int, color_b: int, _mystery_float: float):
	display_floating_text_x(text, unit, color_r, color_g, color_b, 0.0, 0.0, 1.0)


func shuffle_list(list) -> Array:
	var index_list: Array = []

	for i in range(0, list.size()):
		index_list.append(i)

	var sorted: Array = []

	while !index_list.is_empty():
		var random_index_of_index: int = randi_range(0, index_list.size() - 1)
		var random_index: int = index_list.pop_at(random_index_of_index)
		sorted.append(list[random_index])

	return sorted


# Converts CamelCaseSTR_Name to camel_case_str_name
func camel_to_snake(camel_string: String) -> String:
	var snake_string = ""
	var previous_char = ""
	
	for c in camel_string:
		if c.to_upper() == c and previous_char != "" and previous_char.to_upper() != previous_char:
			snake_string += "_"
		snake_string += c.to_lower()
		previous_char = c
	
	return snake_string


# TODO: maybe won't need this at all
func add_unit_animation_properties(_unit: Unit, _mystery_string: String, _mystery_bool: bool):
	pass


func _load_sfx(sfx_name: String) -> AudioStreamMP3:
	if !sfx_name.ends_with(".mp3"):
		print_debug("Attempted to call _load_sfx on non-mp3:", sfx_name)

		return AudioStreamMP3.new()

	var file: FileAccess = FileAccess.open(sfx_name, FileAccess.READ)

	if file == null:
		var open_error: Error = FileAccess.get_open_error()
		print_debug("Failed to open sfx file. Error: ", open_error)
		file.close()

		return AudioStreamMP3.new()

	var bytes = file.get_buffer(file.get_length())
	var stream: AudioStreamMP3 = AudioStreamMP3.new()
	stream.data = bytes

# 	TODO: need to close file or no?

	return stream


# This is a way to recycle existing players
# TODO: maybe there's a better way
func _get_sfx_player() -> AudioStreamPlayer2D:
	for sfx_player in _sfx_player_list:
		if !sfx_player.playing:
			return sfx_player

	var new_sfx_player: AudioStreamPlayer2D = AudioStreamPlayer2D.new()
	_sfx_player_list.append(new_sfx_player)
	_game_scene.add_child(new_sfx_player)

	return new_sfx_player
