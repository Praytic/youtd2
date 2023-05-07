class_name Creep
extends Unit


# TODO: implement armor

signal moved(delta)
signal reached_portal(damage_to_portal)


# NOTE: timed creeps moving in original game and their speed
# was about 200.
const CREEP_HEALTH_MAX: float = 200.0
const MOVE_SPEED_MIN: float = 50.0
const MOVE_SPEED_MAX: float = 200.0
const DEFAULT_MOVE_SPEED: float = MOVE_SPEED_MAX
const HEIGHT_TWEEN_FAST_FORWARD_DELTA: float = 100.0
const ISOMETRIC_ANGLE_DIFF: float = -30

var _path: Path2D : set = set_path
var _size: CreepSize.enm
var _category: CreepCategory.enm : set = set_category, get = get_category
var _armor_type: ArmorType.enm : set = set_armor_type, get = get_armor_type
var _current_path_index: int = 0
var movement_enabled: bool = true 
var _facing_angle: float = 0.0
var _height_tween: Tween = null
var _corpse_scene: PackedScene = preload("res://Scenes/Creeps/CreepCorpse.tscn")
var _spawn_level: int

@onready var _visual = $Visual
@onready var _sprite: AnimatedSprite2D = $Visual/Sprite2D
@onready var _health_bar = $Visual/HealthBar
@onready var _landscape = get_tree().get_root().get_node("GameScene/Map")


#########################
### Code starts here  ###
#########################

func _ready():
	super()

	add_to_group("creeps")
	
	var max_health = get_overall_health()
	_health_bar.set_max(max_health)
	_health_bar.set_min(0.0)
	_health_bar.set_value(max_health)
	health_changed.connect(_on_health_changed)

	if _size == CreepSize.enm.AIR:
		var height: float = 2 * Constants.TILE_HEIGHT
		_visual.position.y = -height

	var sprite: AnimatedSprite2D = $Visual/Sprite2D
	if sprite != null:
		_set_unit_animted_sprite(sprite)

	death.connect(_on_death)

	_mod_value_map[Modification.Type.MOD_ITEM_CHANCE_ON_DEATH] = CreepSize.get_default_item_chance(_size)
	_mod_value_map[Modification.Type.MOD_ITEM_QUALITY_ON_DEATH] = CreepSize.get_default_item_quality(_size)


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

func adjust_height(height_wc3: float, speed: float):
# 	NOTE: divide by two because in isometric world vertical
# 	axis is squished
	var height_pixels: float = Utils.to_pixels(height_wc3) / 2

#	If a tween is already running, complete it instantly
#	before starting new one.
	if _height_tween != null:
		if _height_tween.is_running():
			_height_tween.custom_step(HEIGHT_TWEEN_FAST_FORWARD_DELTA)

		_height_tween.kill()
		_height_tween = null

	_height_tween = create_tween()

	var duration: float = abs(height_pixels / speed)

	_height_tween.tween_property(_visual, "position",
		Vector2(_visual.position.x, _visual.position.y - height_pixels),
		duration).set_trans(Tween.TRANS_LINEAR).set_ease(Tween.EASE_OUT)

func reach_portal():
	var damage_to_portal = get_damage_to_portal()
	reached_portal.emit(damage_to_portal)
	SFX.play_sfx("res://Assets/SFX/Assets_SFX_hit_3.mp3")
	queue_free()


func drop_item(caster: Tower, _mystery_bool: bool):
	var caster_item_quality: float = caster.get_item_quality_ratio()
	var target_item_quality: float = get_item_quality_ratio_on_death()
	var item_quality: float = clampf(caster_item_quality + target_item_quality, 0.0, 1.0)

# 	TODO: figure out actual distribution
	var rarity: Rarity.enm
	if item_quality >= 0.75:
		rarity = Rarity.enm.UNIQUE
	elif item_quality >= 0.50:
		rarity = Rarity.enm.RARE
	elif item_quality >= 0.25:
		rarity = Rarity.enm.UNCOMMON
	else:
		rarity = Rarity.enm.COMMON

	var rarity_string: String = Rarity.convert_to_string(rarity)

	var item_id_list: Array = Properties.get_item_id_list_by_filter(Item.CsvProperty.RARITY, rarity_string)

#	NOTE: Filter out items that have a script. This should
#	be removed once all item scripts are implemented.
	var items_with_script: Array = []

	for item_id in item_id_list:
		var script_path: String = Item.get_item_script_path(item_id)
		var script_exists: bool = ResourceLoader.exists(script_path)

		if script_exists:
			items_with_script.append(item_id)

	if items_with_script.is_empty():
		push_error("No items with script found for rarity: ", rarity_string)

		return

	var random_index: int = randi_range(0, items_with_script.size() - 1)
	var item_id: int = items_with_script[random_index]

	var item_drop_scene_path: String = "res://Scenes/Items/%sItem.tscn" % rarity_string.capitalize()
	var item_drop_scene = load(item_drop_scene_path)
	var item_drop = item_drop_scene.instantiate()
	item_drop.set_id(item_id)
	item_drop.position = position
	Utils.add_object_to_world(item_drop)


#########################
###      Private      ###
#########################

func _move(delta):
	var path_is_over: bool = _current_path_index >= _path.get_curve().get_point_count()
	if path_is_over:
		return

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


func _get_creep_animation() -> String:
	
	var animation_order: Array[String]
	
# TODO: Switch when certain speed limit is reached
#	if _get_move_speed() > 300:
	match get_size():
		CreepSize.enm.NORMAL, CreepSize.enm.MASS:
			animation_order = [
				"run_slow_E", "", "run_slow_S", "", "run_slow_W", "", "run_slow_N", ""
			]
		_:
			animation_order = [
				"run_e", "run_se", "run_s", "run_sw", "run_w", "run_nw", "run_n", "run_ne"
			]
	var animation_index: int = floor((_facing_angle + ISOMETRIC_ANGLE_DIFF + 10) / 45)

	if animation_index >= animation_order.size():
		print_debug("animation_index out of bounds = ", animation_index)
		animation_index = 0

	var animation: String = animation_order[animation_index]

	return animation


func _get_move_speed() -> float:
	var base: float = DEFAULT_MOVE_SPEED
	var mod: float = get_prop_move_speed()
	var mod_absolute: float = get_prop_move_speed_absolute()
	var unclamped: float = base * mod + mod_absolute
	var move_speed: float = clampf(unclamped, MOVE_SPEED_MIN, MOVE_SPEED_MAX)

	return move_speed


#########################
###     Callbacks     ###
#########################

func _on_health_changed(_old_value, new_value):
	_health_bar.set_value(new_value)


func _on_death(event: Event):
#	Add gold
	var caster: Unit = event.get_target()
	var bounty: float = get_bounty()
	caster.getOwner().give_gold(floor(bounty), self, false, true)

# 	Death visual
	var effect_id: int = Effect.create_simple_at_unit("res://Scenes/Effects/DeathExplode.tscn", self)
	var effect_scale: float = max(_sprite_dimensions.x, _sprite_dimensions.y) / Constants.DEATH_EXPLODE_EFFECT_SIZE
	Effect.scale_effect(effect_id, effect_scale)
	Effect.destroy_effect(effect_id)

# 	Add corpse object
#	NOTE: don't add corpse for air creeps because it would
#	look weird for corpse to appear while creep is flying
#	far above it.
	if _size != CreepSize.enm.AIR:
		var corpse: Node2D = _corpse_scene.instantiate()
		corpse.position = position
		Utils.object_container.add_child(corpse)


#########################
### Setters / Getters ###
#########################


# TODO: Do creeps need IDs?
func get_id():
	return 1


# NOTE: this angle needs to be for coordinate space with Y
# axis going down, to match game world coordinate
# conventions. For example, angle progression of 0, 10, 20
# goes clock-wise.
func set_unit_facing(angle: float):
# 	NOTE: limit facing angle to (0, 360) range
	_facing_angle = int(angle + 360) % 360

	var animation: String = _get_creep_animation()
	if animation != "":
		_sprite.play(animation, randi())


func get_unit_facing() -> float:
	return _facing_angle

func set_creep_size(value: CreepSize.enm) -> void:
	_size = value

func get_size() -> CreepSize.enm:
	return _size

func set_category(value: CreepCategory.enm) -> void:
	_category = value

func get_category() -> int:
	return _category

func set_armor_type(value: ArmorType.enm) -> void:
	_armor_type = value

func get_armor_type() -> ArmorType.enm:
	return _armor_type

func get_display_name() -> String:
	return "Generic Creep"


func set_path(path: Path2D):
	_path = path
	position = path.get_curve().get_point_position(0) + path.position

func get_damage_to_portal():
	# TODO: Implement formula
	return 1


func get_spawn_level() -> int:
	return _spawn_level


func set_spawn_level(spawn_level: int):
	_spawn_level = spawn_level
