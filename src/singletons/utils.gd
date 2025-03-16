class_name UtilsStatic extends Node


# Takes in a "x_properties" csv and outputs modified version
# of columns + translation map of id->text. 
func setup_translation_map_from_csv(csv_path: String, column_list: Array):
	var csv_contents: Array[PackedStringArray] = UtilsStatic.load_csv(csv_path)
	
	var modified_csv_contents: String = ""
	var translation_map_contents: String = ""

	var column_count: int = column_list.size()
	var row_count: int = csv_contents.size()
	var translation_id_count: int = column_count * row_count
	var new_translation_ids: Array = Utils.generate_new_translation_ids(translation_id_count)

	for line in csv_contents:
		var source_text_list: Array[String] = []

		for column in column_list:
			var source_text: String = line[column]
			source_text_list.append(source_text)

		var text_id_list: Array = []
		for i in range(column_list.size()):
			var text_id: String = new_translation_ids.pop_front()
			text_id_list.append(text_id)

#		Add new lines to texts csv
		for i in range(column_list.size()):
			var text_id: String = text_id_list[i]
			var source_text: String = source_text_list[i]
			translation_map_contents += "\"%s\",\"%s\"\n" % [text_id, source_text]

#		Add new line to props csv
		var modified_csv_line: String 
		for text_id in text_id_list:
			modified_csv_contents += "\"%s\"," % text_id
		modified_csv_contents.trim_suffix(",")
		modified_csv_contents += "\n"

	var modified_csv: FileAccess = FileAccess.open("user://modified_csv.csv", FileAccess.WRITE)
	modified_csv.store_string(modified_csv_contents)

	var translation_map_csv: FileAccess = FileAccess.open("user://translation_map_csv.csv", FileAccess.WRITE)
	translation_map_csv.store_string(translation_map_contents)


func bool_to_string(value: bool) -> String:
	var result: String
	if value == true:
		result = "TRUE"
	else:
		result = "FALSE"
	
	return result


func string_to_bool(bool_string: String) -> bool:
	var result: bool
	if bool_string == "TRUE":
		result = true
	else:
		result = false
	
	return result


func print_new_translation_ids(amount: int):
	var id_list = Utils.generate_new_translation_ids(amount)

	for id in id_list:
		print(id)


func generate_new_translation_ids(amount: int):
	var chars_for_id: Array = []
	
#	Digits
	for char_int in range(48, 57 + 1):
		var char_str: String = String.chr(char_int)
		chars_for_id.append(char_str)

#	Upper-case letters
	for char_int in range(65, 90 + 1):
		var char_str: String = String.chr(char_int)
		chars_for_id.append(char_str)
	
	var existing_key_list: Array[String] = []
	var csv: Array[PackedStringArray] = UtilsStatic.load_csv("res://data/texts.csv")
	for csv_line in csv:
		var key: String = csv_line[0]
		existing_key_list.append(key)
	
	var generated_key_list: Array[String] = []

#	NOTE: repeat multiple times in case there are too many collisions with existing keys
	for i in range(0, 10):
		for j in range(0, amount):
			var generated_key: String = ""
			for k in range(0, 4):
				var random_char: String = chars_for_id.pick_random()
				generated_key += random_char
			
			generated_key_list.append(generated_key)
	
		for existing_key in existing_key_list:
			generated_key_list.erase(existing_key)
			
		if generated_key_list.size() >= amount:
			break
	
	return generated_key_list


# NOTE: in original youtd, range checks for abilities are
# extended slightly so that range check is done from the
# edge of a small circle around the unit instead of the
# center. For abilities casted on towers, the edge is
# roughly at the "edge" of the average sprite. For creeps,
# the extension is much smaller but it's still there in
# original, so it's replicated here as well.
func apply_unit_range_extension(range_original: float, target_type: TargetType) -> float:
	if target_type == null:
		push_error("apply_unit_range_extension() received null target_type")

		return range_original

	var unit_type: TargetType.UnitType = target_type.get_unit_type()
	var target_is_tower: bool = unit_type == TargetType.UnitType.TOWERS
	
	var range_bonus: float
	if target_is_tower:
		range_bonus = Constants.RANGE_CHECK_BONUS_FOR_TOWERS
	else:
		range_bonus = Constants.RANGE_CHECK_BONUS_FOR_OTHER_UNITS

	var range_extended: float = range_original + range_bonus

	return range_extended


# This function is needed to prevent user inputted strings
# from being parsed. Should be applied to all strings coming
# from players: user names, chat messages, etc.
# 
# If this is not done, then players can do stuff like send
# giant full screen chat messages.
func escape_bbcode(string: String) -> String:
	return string.replace("[", "[lb]")


func get_turn_length() -> int:
	var player_mode: PlayerMode.enm = Globals.get_player_mode()
	
	if player_mode == PlayerMode.enm.SINGLEPLAYER:
		return GameHost.SINGLEPLAYER_TURN_LENGTH
	else:
		return GameHost.MULTIPLAYER_TURN_LENGTH


# Adds a red color error text in the middle of the screen
# and plays an error sound.
func add_ui_error(player: Player, text: String):
	Messages.add_error(player, text)
	SFX.play_sfx_for_player(player, SfxPaths.UI_ERROR)


func get_polygon_bounding_box(poly: Polygon2D) -> Rect2:
	var float_max: float = pow(2, 31) - 1
	var float_min: float = -float_max
	var vec_min: Vector2 = Vector2(float_max, float_max)
	var vec_max: Vector2 = Vector2(float_min, float_min)
	var vertice_list: Array = poly.polygon
	
	for vertice in vertice_list:
		vec_min.x = min(vec_min.x, vertice.x)
		vec_min.y = min(vec_min.y, vertice.y)
		
		vec_max.x = max(vec_max.x, vertice.x)
		vec_max.y = max(vec_max.y, vertice.y)
	
	var bbox_pos: Vector2 = vec_min
	var bbox_size: Vector2 = (vec_max - vec_min).abs()
	var bounding_box: Rect2 = Rect2(bbox_pos, bbox_size)
	
	return bounding_box


func show_popup_message(node: Node, title: String, message: String):
	if !node.is_inside_tree():
		push_error("Node must inside scene tree")

		return
	
	var popup_text: String = ""
	if !title.is_empty():
		popup_text += "[center]%s[/center]\n \n" % title
	popup_text += message

#	NOTE: the top node is last in order, after autoload nodes
	var root = node.get_tree().root
	var top_node: Node = root.get_child(root.get_child_count() - 1)
	var popup: MessagePopup = MessagePopup.make(popup_text)
	top_node.add_child(popup)


# Converts unix time UTC (seconds) into local time string
func convert_unix_time_to_string(time_utc: float) -> String:
	var time_zone: Dictionary = Time.get_time_zone_from_system()
	var bias_minutes: float = time_zone.get("bias", 0)
	var bias_seconds: float = bias_minutes * 60
	var time_local: float = time_utc + bias_seconds
	var time_string: String = Time.get_time_string_from_unix_time(int(time_local))
	
	return time_string


func check_dict_has_fields(dict: Dictionary, field_count: int) -> bool:
	var dict_has_keys: bool = true
	
	for key in range(0, field_count):
		if !dict.has(key):
			dict_has_keys = false
			
			break
	
	return dict_has_keys


func convert_bytes_to_dict(bytes: PackedByteArray) -> Dictionary:
	var variant: Variant = bytes_to_var(bytes)

	if variant is Dictionary:
		var dict: Dictionary = variant as Dictionary

		return dict
	else:
		return {}


func get_path_point_wc3(path: Path2D, index: int) -> Vector2:
	var curve: Curve2D = path.get_curve()
	var point_canvas: Vector2 = curve.get_point_position(index)
	var point_wc3: Vector2 = VectorUtils.canvas_to_wc3_2d(point_canvas)

	return point_wc3


func wave_is_bonus(level: int) -> bool:
	return level > Constants.WAVE_COUNT_NEVERENDING	


func create_message_label(text: String) -> RichTextLabel:
	var label: RichTextLabel = RichTextLabel.new()
	label.append_text(text)
	label.fit_content = true
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.set_theme_type_variation("MessageLabel")

	return label


func get_wisdom_upgrade_count_for_player_level(player_level: int) -> int:
	var upgrade_id_list: Array = WisdomUpgradeProperties.get_id_list()
	var upgrade_count_max: int = upgrade_id_list.size()
	var upgrade_count: int = min(upgrade_count_max, floori(player_level * Constants.PLAYER_LEVEL_TO_WISDOM_UPGRADE_COUNT))

	return upgrade_count


func get_local_player_level() -> int:
	var exp_password: String = Settings.get_setting(Settings.EXP_PASSWORD)
	var player_exp: int = ExperiencePassword.decode(exp_password)
	var player_exp_is_valid: bool = player_exp != -1
	
	if !player_exp_is_valid:
		push_warning("Experience password is invalid, resetting level to 0.")
		
		return 0
	
	var player_lvl: int = PlayerExperience.get_level_at_exp(player_exp)
	
	return player_lvl


# Example: 93 -> "01:33"
func convert_time_to_string(time_total_seconds: float):
	var time_hours: int = floori(time_total_seconds / 3600)
	var time_minutes: int = floori((time_total_seconds - time_hours * 3600) / 60)
	var time_seconds: int = floori(time_total_seconds - time_hours * 3600 - time_minutes * 60)
	var time_string: String
	if time_hours > 0:
		time_string = "%02d:%02d:%02d" % [time_hours, time_minutes, time_seconds]
	else:
		time_string = "%02d:%02d" % [time_minutes, time_seconds]
	
	return time_string


# NOTE: you MUST use create_manual_timer() instead of
# get_tree().create_timer() for gameplay code.
# 
# - create_timer() uses Godot Timer class which runs based
#   on real life time.
# - create_manual_timer() uses ManualTimer runs based on
#   game time which takes into account game pause and
#   adjusting game speed.
# 
# Using Godot Timers in gameplay code also causes desyncs
# in multiplayer.
#
# Example: if you were to mistakenly use Godot Timer from
# create_timer() to add delay to a tower spell, then the
# spell would not function as expected and would cause
# desyncs in multiplayer.
#  
# NOTE: another caveat is that you MUST NOT use
# create_manual_timer() for things which are not part of the
# synchronized multiplayer client. If you
# create_manual_timer() for one player but not the others,
# you will mess up the order of updating timers and cause a
# multiplayer desync.
# - Use create_manual_timer() only for code which runs for
#   all players in multiplayer.
# - Use create_timer() for UI and visual code. Also for code
#   which specifically doesn't run in multiplayer, for
#   example title screen code.
func create_manual_timer(duration: float, parent: Node) -> ManualTimer:
	var timer: ManualTimer = ManualTimer.new()

	var parent_is_active: bool = parent.is_inside_tree() && !parent.is_queued_for_deletion()
	if parent_is_active:
		add_child(timer)
		timer.one_shot = true
		timer.timeout.connect(timer.queue_free)
		timer.start(duration)
	else:
		timer.queue_free()

	return timer


func get_tower_at_canvas_pos(pos_canvas_2nd_floor: Vector2) -> Tower:
	var pos_canvas_2nd_floor_snapped: Vector2 = VectorUtils.snap_canvas_pos_to_buildable_pos(pos_canvas_2nd_floor)
	var pos_canvas: Vector2 = pos_canvas_2nd_floor_snapped + Vector2(0, Constants.TILE_SIZE.y)
	var pos_wc3: Vector2 = VectorUtils.canvas_to_wc3_2d(pos_canvas)
	var tower: Tower = Utils.get_tower_at_position(pos_wc3)

	return tower


func get_tower_at_position(position_wc3: Vector2) -> Tower:
	var tower_node_list: Array = get_tree().get_nodes_in_group("towers")

	for tower_node in tower_node_list:
		var tower: Tower = tower_node as Tower
		var this_position: Vector2 = tower.get_position_wc3_2d()
		var position_match: bool = position_wc3.is_equal_approx(this_position)

		if position_match:
			return tower

	return null


# NOTE: Game.getGameTime() in JASS 
func get_time() -> float:
	var game_time: Node = get_tree().get_root().get_node_or_null("GameScene/Gameplay/GameTime")

	if game_time == null:
		push_warning("game_time is null. You can ignore this warning during game restart.")

		return 0.0
	
	var time: float = game_time.get_time()

	return time


# Returns current time of day in the game world, in hours.
# Between 0.0 and 24.0.
# NOTE: this function works as intended but the day/night
# cycle is not supported visually so don't use this in scripts.
# NOTE: GetFloatGameState(GAME_STATE_TIME_OF_DAY) in JASS
func get_time_of_day() -> float:
	var irl_seconds: float = get_time()
	var game_world_hours: float = Constants.INITIAL_TIME_OF_DAY + irl_seconds * Constants.IRL_SECONDS_TO_GAME_WORLD_HOURS
	var time_of_day: float = fmod(game_world_hours, 24.0)

	return time_of_day


func filter_item_list(item_list: Array[Item], rarity_filter: Array = [], type_filter: Array = []) -> Array[Item]:
	var filtered_list: Array = item_list.filter(
		func(item: Item) -> bool:
			var rarity_ok: bool = rarity_filter.has(item.get_rarity()) || rarity_filter.is_empty()
			var type_ok: bool = type_filter.has(item.get_item_type()) || type_filter.is_empty()

			return rarity_ok && type_ok
	)

	return filtered_list


func add_object_to_world(object: Node):
	var object_container: Node = get_tree().get_root().get_node_or_null("GameScene/World/ObjectContainer")
	
	if object_container == null:
		push_warning("object_container is null. You can ignore this warning during game restart.")
		
		return

	object_container.add_child(object, true)


# NOTE: currently, we assure that text fits inside the
# richtextlabel tooltip by setting the minimum size. If all
# lines in the text are shorter than the minimum size, there
# will be extra empty space to the right of the text. It
# looks bad. Would like the tooltip width to automatically
# shrink in such cases so that tooltip size fits text size
# without any empty space. Couldn't figure out how to do
# that. There also seems to be a bug with RichTextLabel,
# fit_content and embedding a RichTextLabel in tooltip which
# stands in the way of implementing such behavior.
func make_rich_text_tooltip(for_text: String) -> RichTextLabel:
	var label: RichTextLabel = RichTextLabel.new()
	label.custom_minimum_size = Vector2(500, 50)
	label.fit_content  = true
	label.append_text(for_text)

	return label


func find_creep_path(player: Player, for_air_creeps: bool) -> Path2D:
	var wave_path_list: Array = get_tree().get_nodes_in_group("wave_paths")

	for path in wave_path_list:
		var player_match: bool = path.player_id == player.get_id()
		var type_match: bool = (path.is_air && for_air_creeps) || (!path.is_air && !for_air_creeps)

		if player_match && type_match:
			return path

	return null


func is_point_on_creep_path(point_wc3: Vector2, player: Player) -> bool:
	var point_wc3_3d: Vector3 = Vector3(point_wc3.x, point_wc3.y, 0)
	var point: Vector2 = VectorUtils.wc3_to_canvas(point_wc3_3d)
	var creep_path_ground: Path2D = Utils.find_creep_path(player, false)

	if creep_path_ground == null:
		push_error("Failed to find creep path.")

		return false

	var curve: Curve2D = creep_path_ground.curve

	var min_distance: float = 10000.0
	var prev: Vector2 = curve.get_point_position(0)

	for i in range(1, curve.point_count):
		var curr: Vector2 = curve.get_point_position(i)

		var closest_point: Vector2 = Geometry2D.get_closest_point_to_segment(point, prev, curr)
		var distance: float = closest_point.distance_to(point)

		min_distance = min(min_distance, distance)

		prev = curr

	return min_distance < 100


# Returns a list of lines, each line is a list of strings.
# It's assumed that the first row is title row and it is
# skipped.
static func load_csv(path: String) -> Array[PackedStringArray]:
	var file_exists: bool = FileAccess.file_exists(path)

	if !file_exists:
		print_debug("Failed to load CSV because file doesn't exist. Path: %s", path)

		return []

	var list: Array[PackedStringArray] = []

	var file: FileAccess = FileAccess.open(path, FileAccess.READ)

	var skip_title_row: bool = true
	while !file.eof_reached():
		var csv_line: PackedStringArray = file.get_csv_line()

		if skip_title_row:
			skip_title_row = false
			continue

		var is_last_line: bool = csv_line.size() == 0 || (csv_line.size() == 1 && csv_line[0].is_empty())
		if is_last_line:
			continue

		list.append(csv_line)

	file.close()

	return list


# Loads properties from a csv file.
# Transforms rows of "id1, prop1, prop2..."
# Into a list of maps of [id1: {prop1: "prop1 value", prop2: "prop2 value"...
static func load_csv_properties(properties_path: String, properties_dict: Dictionary, id_column: int):
	var csv: Array[PackedStringArray] = UtilsStatic.load_csv(properties_path)

	for csv_line in csv:
		var properties: Dictionary = UtilsStatic.load_csv_line(csv_line)
		var id: int = properties[id_column].to_int()
		properties_dict[id] = properties


# Same as load_csv_properties(), but for property csv's
# without an id column.
static func load_csv_properties_with_automatic_ids(properties_path: String, properties_dict: Dictionary):
	var csv: Array[PackedStringArray] = UtilsStatic.load_csv(properties_path)

	for id in range(0, csv.size()):
		var csv_line: PackedStringArray = csv[id]
		var properties: Dictionary = UtilsStatic.load_csv_line(csv_line)
		properties_dict[id] = properties


static func load_csv_line(csv_line) -> Dictionary:
	var out: Dictionary = {}

	for property in range(csv_line.size()):
		var csv_string: String = csv_line[property]
		out[property] = csv_string

	return out


# NOTE: can't use get_used_rect() here because creep atlases
# are compressed.
func get_sprite_dimensions(sprite: Sprite2D) -> Vector2:
	var texture: Texture2D = sprite.texture
	var texture_size: Vector2 = texture.get_size()
	var sprite_dimensions: Vector2 = texture_size * sprite.scale

	return sprite_dimensions


# NOTE: can't use get_used_rect() here because creep atlases
# are compressed.
func get_animated_sprite_dimensions(sprite: AnimatedSprite2D, animation_name: String) -> Vector2:
	var sprite_frames: SpriteFrames = sprite.sprite_frames
	var texture: Texture2D = sprite_frames.get_frame_texture(animation_name, 0)
	var sprite_dimensions: Vector2 = texture.get_size()

	return sprite_dimensions


# NOTE: Game.getMaxLevel() in JASS
func get_max_level() -> int:
	return Globals.get_wave_count()


func get_colored_string(string: String, color: Color) -> String:
	var out: String = "[color=%s]%s[/color]" % [color.to_html(), string]

	return out


# Divides two floats. In case of division by 0, returns
# "result_when_divide_by_zero" arg, 0 by default.
# NOTE: this function must be used instead of "/" whenever
# there's division by variable which has any chance of
# being 0.
func divide_safe(a: float, b: float, result_when_divide_by_zero: float = 0.0) -> float:
	if b != 0.0:
		var ratio: float = a / b

		return ratio
	else:
		return result_when_divide_by_zero


func pick_random(rng: RandomNumberGenerator, array: Array) -> Variant:
	if array.is_empty():
		return null
		
	var random_element: Variant = array[rng.randi() % array.size()]
	
	return random_element


func shuffle(rng: RandomNumberGenerator, array: Array):
	for i in array.size():
		var random_index: int = rng.randi_range(0, array.size() - 1)

		if random_index == i:
			continue
		else:
			var temp = array[random_index]
			array[random_index] = array[i]
			array[i] = temp


# Accepts a map of elements to weights and returns a random
# element. For example:
# { "a": 10, "b": 20, "c": 70 }
# will result in 10% a, 20% b, 70% c.
# Note that weights don't have to add up to 100!
# { "a": 1, "b": 2}
# Will result in 1/3 a, 2/3 b.
func random_weighted_pick(rng: RandomNumberGenerator, element_to_weight_map: Dictionary) -> Variant:
	if element_to_weight_map.is_empty():
		push_error("Argument is empty")

		return null

	var pair_list: Array = []

	for element in element_to_weight_map.keys():
		var weight: float = element_to_weight_map[element]
		var pair: Array = [element, weight]

		pair_list.append(pair)

	var weight_total: float = 0

	for pair in pair_list:
		var weight: float = pair[1]
		weight_total += weight

	for i in range(1, pair_list.size()):
		pair_list[i][1] += pair_list[i - 1][1]

	var k: float = rng.randf_range(0, weight_total)

	for pair in pair_list:
		var element: Variant = pair[0]
		var weight: float = pair[1]

		if k <= weight:
			return element

	push_error("Failed to generate random element")

	return element_to_weight_map.keys()[0]


# Use this in cases where script stores references to units
# over a long time. Units may become invalid if they are
# killed or sold or upgraded. Note that calling any methods,
# including is_queued_for_deletion(), on an invalid unit
# will result in an error. Didn't define type for argument
# on purpose because argument can be an invalid instance
# without type.
func unit_is_valid(unit) -> bool:
	var is_valid: bool = unit != null && is_instance_valid(unit) && unit.is_inside_tree() && !unit.is_queued_for_deletion()

	return is_valid


# Chance should be in range [0.0, 1.0]
# To get chance for event with 10% occurence, call rand_chance(0.1)
func rand_chance(rng: RandomNumberGenerator, chance: float) -> bool:
	var clamped_chance: float = clampf(chance, 0.0, 1.0)
	var random_float: float = rng.randf()
	var chance_success = random_float <= clamped_chance

	return chance_success


# NOTE: this f-n extends the range slightly from the center
# of target unit
func get_units_in_range(caster: Unit, type: TargetType, center: Vector2, radius: float, include_invisible: bool = false) -> Array[Unit]:
	if type == null:
		return []

	var group_name: String
	var target_unit_type: TargetType.UnitType = type.get_unit_type()
	match target_unit_type:
		TargetType.UnitType.TOWERS: group_name = "towers"
		TargetType.UnitType.CREEPS: group_name = "creeps"
		TargetType.UnitType.CORPSES: group_name = "corpses"

	var node_list: Array[Node] = get_tree().get_nodes_in_group(group_name)

	radius = Utils.apply_unit_range_extension(radius, type)

	var player_towers_is_set: bool = type.player_towers_is_set()

#	NOTE: not using Array.filter() here because it takes
#	more time than for loop
	var filtered_unit_list: Array[Unit] = []
	
	for node in node_list:
		var unit: Unit = node as Unit

		if unit.is_queued_for_deletion():
			continue

		var type_match: bool = type.match(unit)

		if !type_match:
			continue

		var unit_is_in_range = VectorUtils.in_range(center, unit.get_position_wc3_2d(), radius)

		if !unit_is_in_range:
			continue

		if unit is Creep:
			var creep: Creep = unit as Creep

			if creep.is_invisible() && !include_invisible:
				continue

		if player_towers_is_set:
			var player_match: bool = caster.get_player() == unit.get_player()

			if !player_match:
				continue

		filtered_unit_list.append(unit)

	return filtered_unit_list


# NOTE: use squared distances to get better perfomance. Also
# don't convert from WC3 to pixel units because it doesn't
# matter for sorting purposes.
class DistanceSorter:
	var origin = Vector2.ZERO

	func sort(a: Unit, b: Unit):
		var a_pos: Vector2 = a.get_position_wc3_2d()
		var distance_a: float = a_pos.distance_squared_to(origin)
		var b_pos: Vector2 = b.get_position_wc3_2d()
		var distance_b: float = b_pos.distance_squared_to(origin)
		var less_than: bool = distance_a < distance_b

		return less_than


func sort_unit_list_by_distance(unit_list: Array, position: Vector2):
	var sorter: DistanceSorter = DistanceSorter.new()
	sorter.origin = position
	unit_list.sort_custom(Callable(sorter,"sort"))


# This sort implements "smart" targeting for towers. It
# ensures that towers will try to finish an older wave
# before switching to a new wave. The sort works like this:
# 
# 1. If one wave is active, then towers will pick nearest
#    targets.
# 
# 2. If multiple waves are active, then towers will pick
#    nearest target in the oldest wave nearby.
class AttackTargetSorter:
	var origin = Vector2.ZERO

	func sort(a: Unit, b: Unit):
		var level_a: float = a.get_spawn_level()
		var level_b: float = b.get_spawn_level()

		var less_than: bool
		if level_a == level_b:
			var a_pos: Vector2 = a.get_position_wc3_2d()
			var distance_a: float = a_pos.distance_to(origin)
			var b_pos: Vector2 = b.get_position_wc3_2d()
			var distance_b: float = b_pos.distance_to(origin)

			less_than = distance_a < distance_b
		else:
			less_than = level_a < level_b

		return less_than

func sort_creep_list_for_targeting(unit_list: Array, position: Vector2):
	var sorter: AttackTargetSorter = AttackTargetSorter.new()
	sorter.origin = position
	unit_list.sort_custom(sorter.sort)


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


# formatFloat() in JASS
func format_float(x: float, digits: int) -> String:
	var out: String = String.num(x, digits)

	return out


# formatPercent() in JASS
func format_percent(x: float, digits: int) -> String:
	var x_percent: float = x * 100
	var out: String = "%s%%" % String.num(x_percent, digits)

	return out


# formatPercentAddColor() in JASS
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


func reset_scroll_container(scroll_container: ScrollContainer):
	var h_scroll_bar: HScrollBar = scroll_container.get_h_scroll_bar()
	h_scroll_bar.set_value(0.0)

	var v_scroll_bar: VScrollBar = scroll_container.get_v_scroll_bar()
	v_scroll_bar.set_value(0.0)


func get_tower_list() -> Array[Tower]:
	var tower_node_list: Array[Node] = get_tree().get_nodes_in_group("towers")
	var tower_list: Array[Tower] = []

	for tower_node in tower_node_list:
		var tower: Tower = tower_node as Tower
		tower_list.append(tower)

	return tower_list


func get_creep_list() -> Array[Creep]:
	var tower_node_list: Array[Node] = get_tree().get_nodes_in_group("creeps")
	var creep_list: Array[Creep] = []

	for creep_node in tower_node_list:
		var creep: Creep = creep_node as Creep
		creep_list.append(creep)

	return creep_list


# Setup range indicators for tower attack, auras and extra
# abilities.
# NOTE: tower stats must be initialized before calling this
func setup_range_indicators(range_data_list: Array[RangeData], parent: Node2D, player: Player) -> Array[RangeIndicator]:
	var indicator_list: Array[RangeIndicator] = []

	var occupied_radius_list: Array = []

	for i in range(0, range_data_list.size()):
		var range_data: RangeData = range_data_list[i]

#		NOTE: if there are multiple ranges with same radius,
#		shift them slightly so that they don't get drawn on
#		top of each other.
		var indicator_radius: float = range_data.get_radius_with_builder_bonus(player)

#		NOTE: add this bonus because
#		Utils.get_units_in_range() adds it. Otherwise the
#		range would look like it's too small.
		if !range_data.targets_creeps:
			indicator_radius += Constants.RANGE_CHECK_BONUS_FOR_TOWERS

		while occupied_radius_list.has(indicator_radius):
			indicator_radius -= 10

#			It's theoretically possible for there to be no
#			available radius, in that case - give up
			if indicator_radius == 10:
				break

		occupied_radius_list.append(indicator_radius)

		var range_indicator: RangeIndicator = RangeIndicator.make()
#		NOTE: enable floor collisions only for range
#		indicators intended for creeps. For other range
#		indicators, like tower auras, we should not do
#		floor collisions because the range indicator may be
#		fully located on the second floor.
		range_indicator.ability_name = range_data.name
		range_indicator.enable_floor_collisions = range_data.targets_creeps
		range_indicator.set_radius(indicator_radius)
		var range_color: Color = RangeData.get_color_for_index(i)
		range_indicator.color = range_color

#		NOTE: range indicators which affect towers will be
#		drawn at same height as tower.
#		 
#		Range indicators which affect creeps will be drawn
#		one level lower, so that the indicator is "on the
#		ground".
		var y_offset: float
		if range_data.targets_creeps:
			y_offset = Constants.TILE_SIZE.y
		else:
			y_offset = 0

		range_indicator.y_offset = y_offset

		parent.add_child(range_indicator)
		indicator_list.append(range_indicator)

	return indicator_list


# Returns AoE damage dealt to unit, taking into account how
# far the unit is from the AoE center. Normally, all units
# inside the AoE range will receive the same damage but if
# the "sides_ratio" arg is not 0, units far away from center
# will receive less damage. For example, if sides_ratio is
# 0.10, then units far away from the center of aoe will
# receive 10% less damage.
func get_aoe_damage(aoe_center: Vector2, target: Unit, radius: float, damage: float, sides_ratio: float) -> float:
	var target_pos: Vector2 = target.get_position_wc3_2d()
	var distance: float = aoe_center.distance_to(target_pos)
	var distance_ratio: float = Utils.divide_safe(distance, radius)
	var target_is_on_the_sides: bool = distance_ratio > 0.5

	if target_is_on_the_sides:
		return damage * (1.0 - sides_ratio)
	else:
		return damage


func item_id_list_to_item_list(item_id_list: Array[int], player: Player) -> Array[Item]:
	var item_list: Array[Item] = []

	for item_id in item_id_list:
		var item: Item = Item.make(item_id, player)
		item_list.append(item)

	return item_list


func item_list_to_item_id_list(item_list: Array[Item]) -> Array[int]:
	var item_id_list: Array[int] = []

	for item in item_list:
		var item_id: int = item.get_id()
		item_id_list.append(item_id)

#	NOTE: sort so that item lists can be compared
	item_id_list.sort()

	return item_id_list


# NOTE: this assumes that you got a sprite inside a sprite
# parent and the scale value returned by this function will
# multiply the sprite's scale.
func get_scale_from_grows(sprite_scale_min: float, sprite_scale_max: float, current_grows: float, max_grows: float) -> float:
	var scale_max: float = sprite_scale_max / sprite_scale_min
	var grow_ratio: float = clampf(current_grows / max_grows, 0.0, 1.0)
	var current_scale: float = 1.0 + (scale_max - 1.0) *grow_ratio

	return current_scale
