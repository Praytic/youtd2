class_name RangeData


# This class is used to store data about a tower "range".
# Range can refer to range of tower attack, tower aura or
# tower ability. when displaying ranges in tower details and
# when setting up range indicators.


var name_english: String = "placeholder"
var radius: float = 100
var targets_creeps: bool = true
var affected_by_builder: bool = false
var is_attack_range: bool = false

# NOTE: avoid using any greenish colors to avoid confusion
# with selection circle.
const COLOR_LIST: Array = [Color.AQUA, Color.ORANGE, Color.YELLOW, Color.PURPLE, Color.PINK, Color.RED, Color.LIGHT_BLUE]


func _init(name_english_arg: String, radius_arg: float, target_type: TargetType = null, is_attack: bool = false):
	name_english = name_english_arg
	radius = radius_arg
	is_attack_range = is_attack
	if target_type != null:
		targets_creeps = target_type.get_unit_type() == TargetType.UnitType.CREEPS


func get_radius_with_builder_bonus(player: Player):
	var builder: Builder = player.get_builder()
	var with_bonus: float = radius
	if affected_by_builder or is_attack_range:
		var radius_bonus: float = builder.get_range_bonus()
		with_bonus += radius_bonus
	
	if is_attack_range:
		with_bonus += builder.get_attack_range_bonus()
	
	return with_bonus


static func get_color_for_index(index: int) -> Color:
	var wrapped_index: int = wrapi(index, 0, COLOR_LIST.size())
	var color: Color = COLOR_LIST[wrapped_index]

	return color
