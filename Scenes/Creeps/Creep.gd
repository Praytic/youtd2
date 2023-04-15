class_name Creep
extends Unit


# TODO: implement armor

signal moved(delta)
signal reached_portal(damage_to_portal)


# NOTE: order is important to be able to compare
enum Size {
	MASS,
	NORMAL,
	AIR,
	CHAMPION,
	BOSS,
	CHALLENGE_MASS,
	CHALLENGE_BOSS,
}

enum Category {
	UNDEAD,
	MAGIC,
	NATURE,
	ORC,
	HUMANOID,
}

const CREEP_HEALTH_MAX: float = 200.0
const MOVE_SPEED_MIN: float = 100.0
const MOVE_SPEED_MAX: float = 500.0
const DEFAULT_MOVE_SPEED: float = MOVE_SPEED_MAX
const HEIGHT_TWEEN_FAST_FORWARD_DELTA: float = 100.0

var _path: Path2D : set = set_path
var _size: Creep.Size
var _category: Creep.Category : set = set_category, get = get_category
var _armor_type: ArmorType.enm : set = set_armor_type, get = get_armor_type
var _current_path_index: int = 0
var movement_enabled: bool = true 
var _facing_angle: float = 0.0
var _height_tween: Tween = null

@onready var _visual = $Visual
@onready var _sprite = $Visual/Sprite2D
@onready var _health_bar = $Visual/HealthBar
@onready var _landscape = get_tree().get_root().get_node("GameScene/Map")


#########################
### Code starts here  ###
#########################

func _ready():
	super()
	var max_health = get_overall_health()
	_health_bar.set_max(max_health)
	_health_bar.set_min(0.0)
	_health_bar.set_value(max_health)
	health_changed.connect(_on_health_changed)

	if _size == Creep.Size.AIR:
		var height: float = 2 * Constants.TILE_HEIGHT
		_visual.position.y = -height

	var sprite: AnimatedSprite2D = $Visual/Sprite2D
	if sprite != null:
		_setup_selection_shape_from_animated_sprite(sprite)

	death.connect(_on_death)


func _process(delta):
	if movement_enabled:
		_move(delta)

	var creep_animation: String = _get_creep_animation()
	_sprite.play(creep_animation)

#	Update z index based on current visual height
	var height: float = -_visual.position.y
	z_index = _landscape.world_height_to_z_index(height)


#########################
###       Public      ###
#########################

func adjust_height(height: float, speed: float):
#	If a tween is already running, complete it instantly
#	before starting new one.
	if _height_tween != null:
		if _height_tween.is_running():
			_height_tween.custom_step(HEIGHT_TWEEN_FAST_FORWARD_DELTA)

		_height_tween.kill()
		_height_tween = null

	_height_tween = create_tween()

	var duration: float = abs(height / speed)

	_height_tween.tween_property(_visual, "position",
		Vector2(_visual.position.x, _visual.position.y - height),
		duration).set_trans(Tween.TRANS_LINEAR).set_ease(Tween.EASE_OUT)

func reach_portal():
	var damage_to_portal = get_damage_to_portal()
	reached_portal.emit(damage_to_portal)
	Utils.sfx_at_unit("res://Assets/SFX/Assets_SFX_hit_3.mp3", self)
	queue_free()

#########################
###      Private      ###
#########################

func _move(delta):
	var path_point: Vector2 = _path.get_curve().get_point_position(_current_path_index) + _path.position
	var move_delta: float = _get_move_speed() * delta
	position = Isometric.vector_move_toward(position, path_point, move_delta)
	moved.emit(delta)
	
	var reached_path_point: bool = (position == path_point)

	var move_direction: Vector2 = path_point - position
	var move_angle: float = rad_to_deg(move_direction.angle())

#	NOTE: on path turns, the move angle becomes 0 for some
#	reason so don't update unit facing during that period
	if int(abs(move_angle)) > 0:
		set_unit_facing(move_angle)
	
	if reached_path_point:
		_current_path_index += 1

#		Delete creep once it has reached the end of the path
		var reached_end_of_path: bool = (_current_path_index >= _path.get_curve().get_point_count())

		if reached_end_of_path:
			queue_free()
			return


func _get_creep_animation() -> String:
#	NOTE: the actual angles for 4-directional isometric movement are around
#   +- 27 degrees from x axis but checking for which quadrant the movement vector
#	falls into works just as well
	if 0 <= _facing_angle && _facing_angle < 90:
		return "run_e"
	elif 90 <= _facing_angle && _facing_angle < 180:
		return "run_s"
	elif 180 <= _facing_angle && _facing_angle < 270:
		return "run_w"
	elif 270 <= _facing_angle && _facing_angle <= 360:
		return "run_n"
	else:
		return "stand"


func _get_move_speed() -> float:
	var base: float = DEFAULT_MOVE_SPEED
	var mod: float = get_prop_move_speed()
	var mod_absolute: float = get_prop_move_speed_absolute()
	var unclamped: float = base * mod + mod_absolute
	var limit_length: float = min(MOVE_SPEED_MAX, max(MOVE_SPEED_MIN, unclamped))

	return limit_length


#########################
###     Callbacks     ###
#########################

func _on_health_changed(_old_value, new_value):
	_health_bar.set_value(new_value)


# 	TODO: Implement proper item drop chance caclculation
func _on_death(_event: Event):
#	Add gold
	var bounty: float = get_bounty()
	GoldControl.add_gold(bounty)

# 	Spawn item drop
	if Utils.rand_chance(0.5):
		var item_id_list: Array = Properties.get_item_id_list()
		var random_index: int = randi_range(0, item_id_list.size() - 1)
		var item_id: int = item_id_list[random_index]
		var item_properties: Dictionary = Properties.get_item_csv_properties()[item_id]
		var rarity: int = item_properties[Item.CsvProperty.RARITY].to_int()

		var rarity_name: String = ""

		match rarity:
			Constants.Rarity.COMMON: rarity_name = "CommonItem"
			Constants.Rarity.UNCOMMON: rarity_name = "UncommonItem"
			Constants.Rarity.RARE: rarity_name = "RareItem"
			Constants.Rarity.UNIQUE: rarity_name = "UniqueItem"
		
		var item_drop_scene_path: String = "res://Scenes/Items/%s.tscn" % [rarity_name]
		var item_drop_scene = load(item_drop_scene_path)
		var item_drop = item_drop_scene.instantiate()
		item_drop.set_id(item_id)
		item_drop.position = position
		Utils.add_object_to_world(item_drop)


#########################
### Setters / Getters ###
#########################


# TODO: Do creeps need IDs?
func get_id():
	return 1


func set_unit_facing(angle: float):
# 	NOTE: limit facing angle to (0, 360) range
	_facing_angle = int(angle + 360) % 360

	var animation: String = _get_creep_animation()
	_sprite.play(animation)


func get_unit_facing() -> float:
	return _facing_angle

func set_creep_size(value: Creep.Size) -> void:
	_size = value

func get_size() -> Creep.Size:
	return _size

func set_category(value: Creep.Category) -> void:
	_category = value

func get_category() -> int:
	return _category

func set_armor_type(value: ArmorType.enm) -> void:
	_armor_type = value

func get_armor_type() -> ArmorType.enm:
	return _armor_type

# NOTE: use this instead of regular Node2D.position for
# anything involving visual effects, so projectiles and spell
# effects.
func get_visual_position() -> Vector2:
	return _visual.global_position


func get_display_name() -> String:
	return "Generic Creep"


func set_path(path: Path2D):
	_path = path
	position = path.get_curve().get_point_position(0) + path.position

func get_damage_to_portal():
	# TODO: Implement formula
	return 1
