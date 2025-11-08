class_name CreepDart extends BuffType

# NOTE: this special is not affected by silence, on purpose.
# This is how it was in the original game.

const DART_CHANCE: float = 300
const DART_CD: float = 6
const DART_DISTANCE: float = 300

var tired_bt: BuffType


func _init(parent: Node):
	super("creep_dart", 0, 0, true, parent)

	add_event_on_damaged(on_damaged)

	var modifier: Modifier = Modifier.new()
	modifier.add_modification(ModificationType.enm.MOD_MOVESPEED, -0.60, 0.0)
	set_buff_modifier(modifier)

	tired_bt = BuffType.new("tired_bt", DART_CD, 0, true, self
		)
	tired_bt.set_buff_icon("res://resources/icons/generic_icons/animal_skull.tres")
	tired_bt.set_buff_icon_color(Color.LIGHT_BLUE)
	tired_bt.set_buff_tooltip(tr("MS3N"))
	tired_bt.set_is_purgable(false)


func on_damaged(event: Event):
	var buff: Buff = event.get_buff()
	var creep: Unit = buff.get_buffed_unit()

	if !creep.calc_chance(DART_CHANCE):
		return

	var dart_is_on_cd: bool = creep.get_buff_of_type(tired_bt) != null

	if dart_is_on_cd:
		return

	var creep_pos: Vector2 = creep.get_position_wc3_2d()

	var path: Path2D = creep.get_move_path()
	var path_index: int = creep._current_path_index
	var path_point: Vector2 = Utils.get_path_point_wc3(path, path_index)
	var distance_to_path_point_squared: float = creep_pos.distance_squared_to(path_point)
	var dart_would_overshoot_path_point: bool = distance_to_path_point_squared < pow(DART_DISTANCE, 2)

	if dart_would_overshoot_path_point:
		return

	var dart_vector: Vector2 = creep_pos.direction_to(path_point) * DART_DISTANCE
	var dart_pos: Vector2 = creep_pos + dart_vector
	creep.set_position_wc3_2d(dart_pos)

	tired_bt.apply(creep, creep, 1)
