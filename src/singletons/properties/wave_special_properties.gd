extends Node


const PROPERTIES_PATH: String = "res://data/wave_special_properties.csv"

enum CsvProperty {
	ID,
	NAME,
	SHORT_NAME,
	SCRIPT_NAME,
	HP_MODIFIER,
	REQUIRED_WAVE_LEVEL,
	FREQUENCY,
	APPLICABLE_SIZES,
	CHAMPION_OR_BOSS_WAVE_ONLY,
	GROUP_LIST,
	USES_MANA,
	COLOR,
	DESCRIPTION,
	ENABLED,
	ICON_PATH,
}

var FLOCK: int

var _properties: Dictionary = {}
# Map of group [String] to special [int]
var _group_to_special_map: Dictionary = {}
var _buff_map: Dictionary = {}
var _icon_map: Dictionary = {}


#########################
###     Built-in      ###
#########################

func _ready():
	UtilsStatic.load_csv_properties(PROPERTIES_PATH, _properties, CsvProperty.ID)
	_group_to_special_map = _make_group_to_special_map()

	print_verbose("_group_to_special_map = ", _group_to_special_map)

#	Check paths
	var id_list: Array = WaveSpecialProperties.get_all_specials_list()
	for id in id_list:
		var script_path: String = WaveSpecialProperties.get_script_path(id)
		var script_path_is_valid: bool = ResourceLoader.exists(script_path)
		if !script_path_is_valid:
			push_error("Invalid wave special script path: %s" % script_path)

		var icon_path: String = WaveSpecialProperties.get_icon_path(id)
		var icon_path_is_valid: bool = ResourceLoader.exists(icon_path)
		if !icon_path_is_valid:
			push_error("Invalid wave special icon path: %s" % icon_path)

#	Load buff types
	var special_list: Array = WaveSpecialProperties.get_all_specials_list()

	for special in special_list:
		var script_path: String = WaveSpecialProperties.get_script_path(special)

		var script: Script = load(script_path)
		var special_bt: BuffType = script.new(self)
		var special_name: String = WaveSpecialProperties.get_special_name(special)
		var description: String = WaveSpecialProperties.get_description(special)
		var tooltip: String = "%s\n%s" % [special_name, description]
		special_bt.set_buff_tooltip(tooltip)
		
		special_bt.set_hidden()
		
		_buff_map[special] = special_bt

#	Load icons
	for special in special_list:
		var icon_path: String = WaveSpecialProperties.get_icon_path(special)
		var icon_scene: PackedScene = load(icon_path)

		_icon_map[special] = icon_scene

	FLOCK = _find_flock_id()


#########################
###       Public      ###
#########################

func get_all_specials_list() -> Array:
	return _properties.keys()


func get_special_name(special: int) -> String:
	var string: String = _get_property(special, CsvProperty.NAME)

	return string


func get_short_name(special: int) -> String:
	var string: String = _get_property(special, CsvProperty.SHORT_NAME)

	return string


func get_special_script_name(special: int) -> String:
	var string: String = _get_property(special, CsvProperty.SCRIPT_NAME)

	return string


func get_script_path(special: int) -> String:
	var script_name: String = WaveSpecialProperties.get_special_script_name(special)
	var script_path: String = "res://src/creeps/special_buffs/%s.gd" % script_name

	return script_path


func get_icon_path(special: int) -> String:
	var script_name: String = WaveSpecialProperties.get_special_script_name(special)
	var icon_path: String = "res://src/creeps/special_icons/%sSpecial.tscn" % script_name

	return icon_path


func get_required_wave_level(special: int) -> int:
	var level: int = _get_property(special, CsvProperty.REQUIRED_WAVE_LEVEL).to_int()

	return level


func get_frequency(special: int) -> int:
	var frequency: int = _get_property(special, CsvProperty.FREQUENCY).to_int()

	return frequency


# NOTE: in case creep has multiple specials, we return color
# of the first one. Mixing colors wouldn't look good.
func get_base_color(special_list: Array[int]) -> Color:
	if special_list.is_empty():
		return Color.WHITE
	
	var first_special: int = special_list[0]
	var color_html: String = _get_property(first_special, CsvProperty.COLOR)
	var color: Color = Color.html(color_html)

	return color


func get_description(special: int) -> String:
	var description: String = _get_property(special, CsvProperty.DESCRIPTION)

	return description


func get_enabled(special: int) -> bool:
	var enabled: bool = _get_property(special, CsvProperty.ENABLED) == "TRUE"

	return enabled


func get_applicable_sizes(special: int) -> Array[CreepSize.enm]:
	var size_list_string: String = _get_property(special, CsvProperty.APPLICABLE_SIZES)

	if size_list_string == "all":
		return [CreepSize.enm.MASS, CreepSize.enm.NORMAL, CreepSize.enm.AIR, CreepSize.enm.BOSS]

	var size_list: Array[CreepSize.enm] = []

	var size_string_list: Array = size_list_string.split(",")

	for size_string in size_string_list:
		var creep_size: CreepSize.enm = CreepSize.from_string(size_string)
		size_list.append(creep_size)

	return size_list


# NOTE: this is separate from "applicable sizes" because
# this defines if wave buff can apply to specific creep, not
# the whole wave. For example if the wave is 10 normal + 1
# champion, then special can apply to whole wave but the
# buff portion will apply only to the champion. Note that
# health modifiers still apply to whole wave.
func get_champion_or_boss_wave_only(special: int) -> bool:
	var champion_or_boss_wave_only: bool = _get_property(special, CsvProperty.CHAMPION_OR_BOSS_WAVE_ONLY) == "TRUE"

	return champion_or_boss_wave_only


func get_group_list(special: int) -> Array[String]:
	var group_list_packed: PackedStringArray = _get_property(special, CsvProperty.GROUP_LIST).split(",")
	
	var group_list: Array[String] = []
	
	for group in group_list_packed:
		group_list.append(group)

	return group_list


func get_uses_mana(special: int) -> bool:
	var uses_mana: bool = _get_property(special, CsvProperty.USES_MANA) == "TRUE"

	return uses_mana


func get_hp_modifier(special: int) -> float:
	var hp_modifier: float = _get_property(special, CsvProperty.HP_MODIFIER) as float

	return hp_modifier


func get_specials_in_group(group: String) -> Array:
	var special_list: Array = _group_to_special_map[group]

	return special_list


func get_special_buff(special_id: int) -> BuffType:
	return _buff_map[special_id]


func get_special_icon(special: int) -> TextureRect:
	var icon_scene: PackedScene = _icon_map[special]
	var icon: TextureRect = icon_scene.instantiate()

	return icon


#########################
###      Private      ###
#########################

func _get_property(special: int, property: CsvProperty) -> String:
	if !_properties.has(special):
		push_error("No properties for special: ", special)

		return ""

	var map: Dictionary = _properties[special]
	var property_value: String = map[property]

	return property_value


func _make_group_to_special_map() -> Dictionary:
	var result: Dictionary = {}

	var special_list: Array = _properties.keys()

	for special in special_list:
		var group_list: Array[String] = get_group_list(special)

		for group in group_list:
			if !result.has(group):
				result[group] = []

			result[group].append(special)

	return result


func _find_flock_id() -> int:
	var flock_id: int = -1
	var special_list: Array = WaveSpecialProperties.get_all_specials_list()

	for special in special_list:
		var special_name: String = WaveSpecialProperties.get_special_name(special)

		if special_name == "Flock":
			flock_id = special

			break

	if flock_id == -1:
		push_error("Failed to find flock special and map it to id.")

		flock_id = 0

	return flock_id
