extends Node


# Map position is free if it contains only ground tiles
static func map_pos_is_free(buildable_area: TileMap, pos: Vector2) -> bool:
	return buildable_area.get_cell_source_id(0, pos) != -1
@onready var object_container = get_tree().get_root().get_node("GameScene").get_node("Map").get_node("ObjectYSort")


# TODO: connect this to actual max level that was picked
# based on difficulty, etc.
func get_max_level() -> int:
	return 80


func get_player_state(_player: Player, state: PlayerState.enm) -> float:
	match state:
		PlayerState.enm.RESOURCE_GOLD: return GoldControl.get_gold()

	return 0.0


func get_game_time() -> float:
	var time: float = Time.get_unix_time_from_system()

	return time


func get_colored_string(string: String, color: Color) -> String:
	var out: String = "[color=%s]%s[/color]" % [color.to_html(), string]

	return out


# Gets the ratio of two floats. If divisor is 0, returns 0.
func get_ratio(a: float, b: float) -> float:
	if b > 0.0:
		var ratio: float = a / b

		return ratio
	else:
		return 0.0


# Accepts a map of elements to weights and returns a random
# element. For example:
# { "a": 10, "b": 20, "c": 70 }
# will result in 10% a, 20% b, 70% c.
# Note that weights don't have to add up to 100!
# { "a": 1, "b": 2}
# Will result in 1/3 a, 2/3 b.
func random_weighted_pick(element_to_weight_map: Dictionary) -> Variant:
	if element_to_weight_map.is_empty():
		push_error("Argument is empty")

		return null

	var pair_list: Array = []

	for element in element_to_weight_map.keys():
		var weight: int = element_to_weight_map[element]
		var pair: Array = [element, weight]

		pair_list.append(pair)

	var weight_total: float = 0

	for pair in pair_list:
		var weight: float = pair[1]
		weight_total += weight

	for i in range(1, pair_list.size()):
		pair_list[i][1] += pair_list[i - 1][1]

	var k: float = randf_range(0, weight_total)

	for pair in pair_list:
		var element: Variant = pair[0]
		var weight: float = pair[1]

		if k <= weight:
			return element

	push_error("Failed to generate random element")

	return element_to_weight_map.keys()[0]


# This f-n simulates getUID() f-n from JASS. Used to check
# if unit references saved before tower script splits are
# still valid after sleep is over.
# 
# NOTE: this f-n can't be a member f-n of Unit like in JASS
# because in Gdscript you can't call functions on invalid
# references - causes an error.
func getUID(unit):
	if is_instance_valid(unit) && !unit.is_dead():
		return unit.get_instance_id()
	else:
		return 0


func add_object_to_world(object: Node):
	object_container.add_child(object, true)


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
	var clamped_chance: float = clampf(chance, 0.0, 1.0)
	var random_float: float = randf()
	var chance_success = random_float <= clamped_chance

	return chance_success


func get_units_in_range(type: TargetType, center: Vector2, radius: float, include_invisible: bool = false) -> Array[Unit]:
	var radius_PIXELS: float = to_pixels(radius)

	return get_units_in_range_PIXELS(type, center, radius_PIXELS, include_invisible)


func get_units_in_range_PIXELS(type: TargetType, center: Vector2, radius: float, include_invisible: bool = false) -> Array[Unit]:
	var node_list: Array[Node] = []

	match type._unit_type:
		TargetType.UnitType.TOWERS: node_list = get_tree().get_nodes_in_group("towers")
		TargetType.UnitType.PLAYER_TOWERS: node_list = get_tree().get_nodes_in_group("towers")
		TargetType.UnitType.CREEPS: node_list = get_tree().get_nodes_in_group("creeps")

	var filtered_node_list: Array[Node] = node_list.filter(
		func(node) -> bool:
			var unit: Unit = node as Unit

			if unit.is_dead():
				return false

			if type != null:
				var type_match: bool = type.match(unit)

				if !type_match:
					return false

			var distance: float = Isometric.vector_distance_to_PIXELS(center, unit.position)
			var creep_is_in_range = distance <= radius

			if !creep_is_in_range:
				return false

			if unit is Creep:
				var creep: Creep = unit as Creep

				if creep.is_invisible() && !include_invisible:
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


func format_percent(x: float, digits: int) -> String:
	var x_percent: float = x * 100
	var sign_string: String
	if x >= 0:
		sign_string = "+"
	else:
		sign_string = "-"
	var out: String = "%s%s%%" % [sign_string, String.num(x_percent, digits)]

	return out


func format_percent_add_color(x: float, digits: int) -> String:
	var uncolored: String = format_percent(x, digits)
	var color: Color
	if x < 0:
		color = Color.RED
	else:
		color = Color.GREEN
	var out: String = get_colored_string(uncolored, color)

	return out


func to_pixels(distance_wc3: float) -> float:
	var distance_pixels: float = distance_wc3 * Constants.WC3_DISTANCE_TO_PIXELS

	return distance_pixels


func from_pixels(distance_pixels: float) -> float:
	var distance: float = distance_pixels / Constants.WC3_DISTANCE_TO_PIXELS

	return distance
