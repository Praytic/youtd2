extends Node


enum CsvProperty {
	ID,
	NAME_ENGLISH,
	HANDLER_FUNCTION,
	AUTOCAST_TYPE,
	COOLDOWN,
	MANA_COST,
	CAST_RANGE,
	AUTO_RANGE,
	TARGET_SELF,
	IS_EXTENDED,
	BUFF_TYPE,
	BUFF_TARGET_TYPE,
	NUM_BUFFS_BEFORE_IDLE,
	CASTER_ART,
	TARGET_ART,
	ICON_PATH,
	NAME,
	DESCRIPTION_SHORT,
	DESCRIPTION_FULL,
}

const PROPERTIES_PATH = "res://data/autocast_properties.csv"


var _properties: Dictionary = {}


#########################
###     Built-in      ###
#########################

func _ready():
	UtilsStatic.load_csv_properties(PROPERTIES_PATH, _properties, CsvProperty.ID)

#	Check paths
	var id_list: Array = get_id_list()
	for id in id_list:
		var icon_path: String = AutocastProperties.get_icon_path(id)
		var icon_path_is_valid: bool = ResourceLoader.exists(icon_path)

		if !icon_path_is_valid:
			push_error("Invalid icon path for autocast: %s" % icon_path)


#########################
###       Public      ###
#########################

func get_id_list() -> Array:
	return _properties.keys()


func get_name_english(id: int) -> String:
	var name_english: String = _get_property(id, CsvProperty.NAME_ENGLISH)

	return name_english


func get_handler_function(id: int) -> String:
	var handler_function: String = _get_property(id, CsvProperty.HANDLER_FUNCTION)

	return handler_function


func get_autocast_type(id: int) -> Autocast.Type:
	var autocast_type_string: String = _get_property(id, CsvProperty.AUTOCAST_TYPE)
	var autocast_type: Autocast.Type = Autocast.string_to_autocast_type(autocast_type_string)

	return autocast_type


func get_cooldown(id: int) -> float:
	var cooldown_string: String = _get_property(id, CsvProperty.COOLDOWN)
	var cooldown: float = cooldown_string.to_float()

	return cooldown


func get_mana_cost(id: int) -> int:
	var mana_cost_string: String = _get_property(id, CsvProperty.MANA_COST)
	var mana_cost: int = mana_cost_string.to_int()

	return mana_cost


func get_cast_range(id: int) -> float:
	var cast_range_string: String = _get_property(id, CsvProperty.CAST_RANGE)
	var cast_range: float = cast_range_string.to_float()

	return cast_range


func get_auto_range(id: int) -> float:
	var auto_range_string: String = _get_property(id, CsvProperty.AUTO_RANGE)
	var auto_range: float = auto_range_string.to_float()

	return auto_range


func get_target_self(id: int) -> bool:
	var target_self_string: String = _get_property(id, CsvProperty.TARGET_SELF)
	var target_self: bool = Utils.string_to_bool(target_self_string)

	return target_self


func get_is_extended(id: int) -> bool:
	var is_extended_string: String = _get_property(id, CsvProperty.IS_EXTENDED)
	var is_extended: bool = Utils.string_to_bool(is_extended_string)

	return is_extended


func get_buff_type(id: int) -> String:
	var buff_type: String = _get_property(id, CsvProperty.BUFF_TYPE)

	return buff_type


func get_buff_target_type(id: int) -> TargetType:
	var buff_type_string: String = _get_property(id, CsvProperty.BUFF_TARGET_TYPE)
	var buff_target_type: TargetType = TargetType.convert_from_string(buff_type_string)

	return buff_target_type


func get_num_buffs_before_idle(id: int) -> int:
	var string: String = _get_property(id, CsvProperty.	NUM_BUFFS_BEFORE_IDLE)
	var num_buffs_before_idle: int = string.to_int()

	return num_buffs_before_idle


func get_caster_art(id: int) -> String:
	var caster_art: String = _get_property(id, CsvProperty.CASTER_ART)

	return caster_art


func get_target_art(id: int) -> String:
	var target_art: String = _get_property(id, CsvProperty.TARGET_ART)

	return target_art


func get_icon_path(id: int) -> String:
	var icon_path: String = _get_property(id, CsvProperty.ICON_PATH)

	return icon_path


func get_autocast_name(id: int) -> String:
	var autocast_name_text_id: String = _get_property(id, CsvProperty.NAME)
	var autocast_name: String = tr(autocast_name_text_id)

	return autocast_name


func get_description_short(id: int) -> String:
	var description_short_text_id: String = _get_property(id, CsvProperty.DESCRIPTION_SHORT)
	var description_short: String = tr(description_short_text_id)

	return description_short


func get_description_full(id: int) -> String:
	var description_full_text_id: String = _get_property(id, CsvProperty.DESCRIPTION_FULL)
	var description_full: String = tr(description_full_text_id)

	return description_full


#########################
###      Private      ###
#########################

func _get_property(id: int, property: CsvProperty) -> String:
	if !_properties.has(id):
		push_error("No properties for id: ", id)

		return ""

	var map: Dictionary = _properties[id]
	var property_value: String = map[property]

	return property_value
