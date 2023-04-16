extends Node


@onready var floating_text_scene: PackedScene = preload("res://Scenes/FloatingText.tscn")

# Map position is free if it contains only ground tiles
static func map_pos_is_free(buildable_area: TileMap, pos: Vector2) -> bool:
	return buildable_area.get_cell_source_id(0, pos) != -1
@onready var object_container = get_tree().get_root().get_node("GameScene").get_node("Map").get_node("ObjectYSort")
@onready var _game_scene: Node = get_tree().get_root().get_node("GameScene")
@onready var _floating_text_container: Node = get_tree().get_root().get_node("GameScene/Map/FloatingTextContainer")

# TODO: move to a better singleton, maybe make a singleton
# for all pre-loaded stuff?
@onready var item_icons_s: Texture2D = preload("res://Assets/Items/item_icons_s.png")
@onready var item_icons_m: Texture2D = preload("res://Assets/Items/item_icons_m.png")
@onready var item_button_fallback_icon: Texture2D = preload("res://Assets/icon.png")

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


func circle_polygon_set_radius(collision_polygon: CollisionPolygon2D, radius: float , angle_from = 0, angle_to = 360):
	var nb_points = radius/20
	var points_arc = PackedVector2Array()
	var center = collision_polygon.position
	
	for i in range(nb_points + 1):
		var angle_point = deg_to_rad(angle_from + i * (angle_to - angle_from) / nb_points - 90)
		var point = center + Vector2(cos(angle_point), sin(angle_point) / 2) * radius
		points_arc.append(point)


# 	NOTE: use call_deferred() here so that
# 	circle_polygon_set_radius() can be called during physics
# 	processing. Changing the state of physics objects while
# 	inside physics processing causes this error: "Can't
# 	change this state while flushing queries.". This can
# 	happen when circle_polygon_set_radius() from the slot
# 	for "body_entered" signal for example.
	collision_polygon.call_deferred("set_polygon", points_arc)


# Chance should be in range [0.0, 1.0]
# To get chance for event with 10% occurence, call rand_chance(0.1)
func rand_chance(chance: float) -> bool:
	var clamped_chance: float = min(1.0, max(0.0, chance))
	var random_float: float = randf()
	var chance_success = random_float <= clamped_chance

	return chance_success


func get_units_in_range(type: TargetType, center: Vector2, radius: float) -> Array[Unit]:
	var node_list: Array[Node] = object_container.get_children()

	var filtered_node_list: Array[Node] = node_list.filter(
		func(node) -> bool:
			if !node is Unit:
				return false

			var unit: Unit = node as Unit

			if type != null:
				var type_match: bool = type.match(unit)

				if !type_match:
					return false

			var distance: float = Isometric.vector_distance_to(center, unit.position)
			var creep_is_in_range = distance <= radius

			if !creep_is_in_range:
				return false

			if unit is Creep:
				var creep: Creep = unit as Creep

				if creep.is_invisible():
					return false

			return true
	)
	
	var filtered_unit_list: Array[Unit] = []
	
	for node in filtered_node_list:
		filtered_unit_list.append(node as Unit)

	return filtered_unit_list


class DistanceSorter:
	var origin = Vector2.ZERO

	func sort(a: Unit, b: Unit):
		var distance_a: float = Isometric.vector_distance_to(a.position, origin)
		var distance_b: float = Isometric.vector_distance_to(b.position, origin)
		var less_than: bool = distance_a < distance_b

		return less_than


func sort_unit_list_by_distance(unit_list: Array, position: Vector2):
	var sorter: DistanceSorter = DistanceSorter.new()
	sorter.origin = position
	unit_list.sort_custom(Callable(sorter,"sort"))


# TODO: figure out what are the mystery float parameters,
# probably related to tween
func display_floating_text_x(text: String, unit: Unit, color_r: int, color_g: int, color_b: int, color_a: int, _mystery_float_1: float, _mystery_float_2: float, time: float):
	var floating_text = floating_text_scene.instantiate()
	floating_text.text = text
	floating_text.color = Color(color_r / 255.0, color_g / 255.0, color_b / 255.0, color_a / 255.0)
	floating_text.duration = time
	floating_text.position = unit.position
	_floating_text_container.add_child(floating_text)


# TODO: implement, not sure what the difference is between this and then _x version
func display_floating_text(text: String, unit: Unit, color_r: int, color_g: int, color_b: int):
	display_floating_text_x(text, unit, color_r, color_g, color_b, 255, 0.0, 0.0, 1.0)


func display_small_floating_text(text: String, unit: Unit, color_r: int, color_g: int, color_b: int, _mystery_float: float):
	display_floating_text_x(text, unit, color_r, color_g, color_b, 255, 0.0, 0.0, 1.0)


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


func screaming_snake_case_to_camel_case(screaming_snake_case: String) -> String:
	var words = screaming_snake_case.split("_")
	var camel_case = ""
	
	for i in range(words.size()):
		camel_case += words[i].capitalize()
	
	return camel_case

# TODO: maybe won't need this at all
func add_unit_animation_properties(_unit: Unit, _mystery_string: String, _mystery_bool: bool):
	pass


func bit_is_set(mask: int, bit: int) -> bool:
	var is_set: bool = (mask & bit) != 0x0

	return is_set


# TODO: implement
func format_float(x: float, _digits: int) -> String:
	return str(x)


func _load_sfx(sfx_name: String) -> AudioStreamMP3:
	if !sfx_name.ends_with(".mp3"):
		print_debug("Attempted to call _load_sfx on non-mp3:", sfx_name)

		return AudioStreamMP3.new()

	var file: FileAccess = FileAccess.open(sfx_name, FileAccess.READ)

	if file == null:
		var open_error: Error = FileAccess.get_open_error()
		print_debug("Failed to open sfx file: %s. Error: %s" % [sfx_name, open_error])
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
