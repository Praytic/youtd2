extends Node


# Map position is free if it contains only ground tiles
static func map_pos_is_free(buildable_area: TileMap, pos: Vector2) -> bool:
	return buildable_area.get_cell_source_id(0, pos) != -1
@onready var object_container = get_tree().get_root().get_node("GameScene").get_node("Map").get_node("ObjectYSort")
@onready var _game_scene: Node = get_tree().get_root().get_node("GameScene")


var _loaded_sfx_map: Dictionary = {}
var _2d_sfx_player_list: Array = []
var _sfx_player_list: Array = []


func add_object_to_world(object: Node):
	object_container.add_child(object, true)


# NOTE: this f-n is non-positional. Current viewport
# position doesn't affect the sfx.
func play_sfx(sfx_name: String):
	var sfx_player: AudioStreamPlayer = _get_sfx_player()
	var sfx_stream: AudioStream = _get_sfx(sfx_name)

	var invalid_sfx: bool = sfx_stream.get_length() == 0

	if invalid_sfx:
		return

	sfx_player.set_stream(sfx_stream)
	sfx_player.play()


func sfx_at_pos(sfx_name: String, sfx_position: Vector2):
	var sfx_player: AudioStreamPlayer2D = _get_2d_sfx_player()
	var sfx_stream: AudioStream = _get_sfx(sfx_name)

	var invalid_sfx: bool = sfx_stream.get_length() == 0

	if invalid_sfx:
		return

	sfx_player.set_stream(sfx_stream)
	sfx_player.global_position = sfx_position
	sfx_player.play()


func sfx_at_unit(sfx_name: String, unit: Unit):
	var sfx_position: Vector2 = unit.get_visual_position()
	sfx_at_pos(sfx_name, sfx_position)


func sfx_on_unit(sfx_name: String, unit: Unit, body_part: String):
	var sfx_position: Vector2 = unit.get_body_part_position(body_part)
	sfx_at_pos(sfx_name, sfx_position)


func circle_polygon_set_radius(collision_polygon: CollisionPolygon2D, radius: float , angle_from = 0, angle_to = 360):
	var radius_PIXELS: float = to_pixels(radius)
	circle_polygon_set_radius_PIXELS(collision_polygon, radius_PIXELS, angle_from, angle_to)


func circle_polygon_set_radius_PIXELS(collision_polygon: CollisionPolygon2D, radius: float , angle_from = 0, angle_to = 360):
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
	var radius_PIXELS: float = to_pixels(radius)

	return get_units_in_range_PIXELS(type, center, radius_PIXELS)


func get_units_in_range_PIXELS(type: TargetType, center: Vector2, radius: float) -> Array[Unit]:
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


func bit_is_set(mask: int, bit: int) -> bool:
	var is_set: bool = (mask & bit) != 0x0

	return is_set


func format_float(x: float, digits: int) -> String:
	var out: String = String.num(x, digits)

	return out


func _get_sfx(sfx_name: String) -> AudioStream:
	if _loaded_sfx_map.has(sfx_name):
		return _loaded_sfx_map[sfx_name]

	if !sfx_name.ends_with(".mp3") && !sfx_name.ends_with(".wav") && !sfx_name.ends_with(".ogg"):
		print_debug("Sfx must be mp3, wav or ogg:", sfx_name)

		return AudioStreamMP3.new()

	var file_exists: bool = ResourceLoader.exists(sfx_name)

	if !file_exists:
		print_debug("Failed to find sfx at:", sfx_name)

		return AudioStreamMP3.new()

	var stream: AudioStream = load(sfx_name)
	_loaded_sfx_map[sfx_name] = stream

	return stream


func _get_sfx_player() -> AudioStreamPlayer:
	for sfx_player in _sfx_player_list:
		if !sfx_player.playing:
			return sfx_player

	var new_sfx_player: AudioStreamPlayer = AudioStreamPlayer.new()
	_sfx_player_list.append(new_sfx_player)
	_game_scene.add_child(new_sfx_player)

	return new_sfx_player


# This is a way to recycle existing players
func _get_2d_sfx_player() -> AudioStreamPlayer2D:
	for sfx_player in _2d_sfx_player_list:
		if !sfx_player.playing:
			return sfx_player

	var new_sfx_player: AudioStreamPlayer2D = AudioStreamPlayer2D.new()
	_2d_sfx_player_list.append(new_sfx_player)
	_game_scene.add_child(new_sfx_player)

	return new_sfx_player


func to_pixels(distance_wc3: float) -> float:
	var distance_pixels: float = distance_wc3 * Constants.WC3_DISTANCE_TO_PIXELS

	return distance_pixels


func from_pixels(distance_pixels: float) -> float:
	var distance: float = distance_pixels / Constants.WC3_DISTANCE_TO_PIXELS

	return distance
