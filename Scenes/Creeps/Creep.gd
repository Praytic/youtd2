class_name Creep
extends Unit


signal moved(delta)


# NOTE: DEFAULT_MOVE_SPEED was obtained by measuring speed
# in original game. 2000 / 9s ~= 222
# 
# MOVE_SPEED_MAX can be found online, search "warcraft 3 max
# speed 522"
const MOVE_SPEED_MIN: float = 50.0
const MOVE_SPEED_MAX: float = 522.0
const DEFAULT_MOVE_SPEED: float = 222.0
const HEIGHT_TWEEN_FAST_FORWARD_DELTA: float = 100.0
const ISOMETRIC_ANGLE_DIFF: float = -30
const ANIMATION_FOR_DIMENSIONS: String = "default"

var _path: Path2D : set = set_path
var _size: CreepSize.enm
var _category: CreepCategory.enm : set = set_category, get = get_category
var _armor_type: ArmorType.enm : set = set_armor_type, get = get_armor_type
var _current_path_index: int = 0
var _facing_angle: float = 0.0
var _height_tween: Tween = null
var _spawn_level: int
var _total_path_length: float = 0.0
var _distance_covered: float = 0.0

# TODO: can't use @export here because there's no Creep.tscn
# - only subclass scenes. Create base class Creep.tscn to
# fix this.
@onready var _visual = $Visual
@onready var _sprite: AnimatedSprite2D = $Visual/Sprite2D
@onready var _health_bar = $Visual/HealthBar
@onready var _selection_area: Area2D = $Visual/SelectionArea
@onready var _map = get_tree().get_root().get_node("GameScene/Map")


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
	
	SelectUnit.connect_unit(self, _selection_area)
	
	_set_visual_node(_visual)

	var sprite_dimensions: Vector2 = Utils.get_animated_sprite_dimensions(_sprite, ANIMATION_FOR_DIMENSIONS)
	_set_unit_dimensions(sprite_dimensions)

	death.connect(_on_death)


func _process(delta):
	if !is_stunned():
		_move(delta)

	var creep_animation: String = _get_creep_animation()
	_sprite.play(creep_animation)

	z_index = _calculate_current_z_index()


#########################
###       Public      ###
#########################

# NOTE: creeps are always considered to be attacking for the
# purposes of their autocasts.
func is_attacking() -> bool:
	return true


# NOTE: creep.adjustHeight() in JASS
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
	var damage_to_portal_string: String = Utils.format_percent(damage_to_portal / 100, 2)
	var damage_done: float = 1.0 - get_health_ratio()
	var damage_done_string: String = Utils.format_percent(damage_done, 2)
	var size_string: String = CreepSize.convert_to_string(_size)

	if _size == CreepSize.enm.BOSS:
		Messages.add_normal("Dealt %s damage to BOSS" % damage_done_string)
	else:
		Messages.add_normal("Failed to kill a %s" % size_string.to_upper())		

	if damage_to_portal > 0:
		Messages.add_normal("You lose %s of your lives!" % damage_to_portal_string)

	PortalLives.deal_damage(damage_to_portal)

	SFX.play_sfx("res://Assets/SFX/Assets_SFX_hit_3.mp3")
	queue_free()


# NOTE: creep.dropItem() in JASS
func drop_item(caster: Tower, _mystery_bool: bool):
	var random_item: int = ItemDropCalc.get_random_item(caster, self)

	if random_item == 0:
		return

	var item: Item = Item.create(caster.get_player(), random_item, position)
	item.fly_to_stash(0.0)

	var item_name: String = ItemProperties.get_item_name(random_item)
	var item_rarity: Rarity.enm = ItemProperties.get_rarity(random_item)
	var rarity_color: Color = Rarity.get_color(item_rarity)

	caster.get_player().display_floating_text_color(item_name, self, rarity_color, 2)


#########################
###      Private      ###
#########################

func _move(delta):
	var path_is_over: bool = _current_path_index >= _path.get_curve().get_point_count()
	if path_is_over:
		reach_portal()

		return

	var prev_pos: Vector2 = position

	var path_point: Vector2 = _path.get_curve().get_point_position(_current_path_index) + _path.position
	var move_delta: float = _get_move_speed() * delta
	position = Isometric.vector_move_toward(position, path_point, move_delta)
	moved.emit(delta)
	
	var new_pos: Vector2 = position
	var move_distance: float = Isometric.vector_distance_to(prev_pos, new_pos)
	_distance_covered += move_distance

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
	var creep_move_speed = _get_move_speed()
	match get_size():
		CreepSize.enm.MASS:
			if creep_move_speed > 200:
				animation_order = [
					"run_E", "", "run_S", "", "run_W", "", "run_N", ""
				]
			else:
				animation_order = [
					"slow_run_E", "", "slow_run_S", "", "slow_run_W", "", "slow_run_N", ""
				]
		CreepSize.enm.CHALLENGE_MASS:
			if creep_move_speed > 200:
				animation_order = [
					"run_E", "", "run_S", "", "run_W", "", "run_N", ""
				]
			else:
				animation_order = [
					"slow_run_E", "", "slow_run_S", "", "slow_run_W", "", "slow_run_N", ""
				]
		CreepSize.enm.BOSS:
			if creep_move_speed > 350:
				animation_order = [
					"run_E", "", "run_S", "", "run_W", "", "run_N", ""
				]
			else:
				animation_order = [
					"slow_run_E", "", "slow_run_S", "", "slow_run_W", "", "slow_run_N", ""
				]
		CreepSize.enm.CHALLENGE_BOSS:
			if creep_move_speed > 350:
				animation_order = [
					"run_E", "", "run_S", "", "run_W", "", "run_N", ""
				]
			else:
				animation_order = [
					"slow_run_E", "", "slow_run_S", "", "slow_run_W", "", "slow_run_N", ""
				]
		CreepSize.enm.NORMAL, CreepSize.enm.CHAMPION:
			if creep_move_speed > 260:
				animation_order = [
					"run_E", "", "run_S", "", "run_W", "", "run_N", ""
				]
			else:
				animation_order = [
					"slow_run_E", "", "slow_run_S", "", "slow_run_W", "", "slow_run_N", ""
				]
		CreepSize.enm.AIR:
			animation_order = [
				"fly_E", "fly_SE", "fly_S", "fly_SW", "fly_W", "fly_NW", "fly_N", "fly_NE"
			]
		_:
			animation_order = [
				"stand", "stand", "stand", "stand", "stand", "stand", "stand", "stand"
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

func _on_health_changed():
	var health_ratio: float = get_health_ratio()
	_health_bar.ratio = health_ratio


func _on_death(_event: Event):
# 	Death visual
	var effect_id: int = Effect.create_simple_at_unit("res://Scenes/Effects/DeathExplode.tscn", self)
	var effect_scale: float = max(_sprite_dimensions.x, _sprite_dimensions.y) / Constants.DEATH_EXPLODE_EFFECT_SIZE
	Effect.scale_effect(effect_id, effect_scale)
	Effect.destroy_effect_after_its_over(effect_id)

# 	Add corpse object
#	NOTE: don't add corpse for air creeps because it would
#	look weird for corpse to appear while creep is flying
#	far above it.
	if _size != CreepSize.enm.AIR:
		var corpse: Node2D = Globals.corpse_scene.instantiate()
		corpse.position = position
		Utils.add_object_to_world(corpse)


#########################
### Setters / Getters ###
#########################


# NOTE: this angle needs to be for coordinate space with Y
# axis going down, to match game world coordinate
# conventions. For example, angle progression of 0, 10, 20
# goes clock-wise.
# 
# NOTE: SetUnitFacing() in JASS
func set_unit_facing(angle: float):
# 	NOTE: limit facing angle to (0, 360) range
	_facing_angle = int(angle + 360) % 360

	var animation: String = _get_creep_animation()
	if animation != "":
		_sprite.play(animation)


# NOTE: GetUnitFacing() in JASS
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
	_path.default_z = 10
	_total_path_length = _calculate_path_length(path)


func get_damage_to_portal() -> float:
#	NOTE: final wave boss deals full damage to portal
	var is_final_wave: bool = _spawn_level == Constants.FINAL_WAVE

	if is_final_wave:
		return 100.0

	if _size == CreepSize.enm.CHALLENGE_MASS || _size == CreepSize.enm.CHALLENGE_BOSS:
		return 0

	var damage_done: float = 1.0 - get_health_ratio()

	var type_multiplier: float = CreepSize.get_portal_damage_multiplier(_size)

	var damage_done_power: float
	if _size == CreepSize.enm.BOSS:
		damage_done_power = 4
	else:
		damage_done_power = 5

	var first_half: float = 2.5 * type_multiplier * (1 - pow(damage_done, damage_done_power)) * 0.5
	var second_half: float = 2.5 * type_multiplier * 0.5
	var damage_to_portal: float = first_half + second_half

	return damage_to_portal


func get_spawn_level() -> int:
	return _spawn_level


func set_spawn_level(spawn_level: int):
	_spawn_level = spawn_level


func get_distance_until_portal() -> float:
	var distance: float = _total_path_length - _distance_covered
	return distance


func _calculate_path_length(path: Path2D) -> float:
	var length: float = 0.0

	var curve: Curve2D = path.get_curve()
	var prev_point: Vector2

	for index in range(0, curve.point_count):
		var point: Vector2 = curve.get_point_position(index)
		
		if index == 0:
			prev_point = point
			continue

		var distance: float = Isometric.vector_distance_to(point, prev_point)

		length += distance

	return length


# NOTE: when a creep has non-zero height, we need to adjust
# it's z index so that the sprite is drawn correctly in
# front of tiles.
func _calculate_current_z_index() -> int:
	var base_z_index: int = _path.get_z(_current_path_index)
	var height: float = -_visual.position.y
	var height_z_index = _map.world_height_to_z_index(height)
	var total_z_index: int = base_z_index + height_z_index

	return total_z_index
