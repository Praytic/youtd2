class_name Creep
extends Unit


signal moved(delta)


const HEIGHT_TWEEN_FAST_FORWARD_DELTA: float = 100.0
const ANIMATION_FOR_DIMENSIONS: String = "default"

# NOTE: need to limit size of selection visual so that creep
# selection visual doesn't clip into floor2 tiles.
const MAX_SELECTION_VISUAL_SIZE: float = 120.0

var _path: Path2D : set = set_path
var _size: CreepSize.enm
var _category: CreepCategory.enm : set = set_category, get = get_category
var _armor_type: ArmorType.enm : set = set_armor_type, get = get_armor_type
var _current_path_index: int = 0
var _facing_angle: float = 0.0
var _height_tween: Tween = null
var _spawn_level: int
var _special_list: Array[int] = []

static var _id_max: int = 1
var _id: int

# TODO: can't use @export here because there's no Creep.tscn
# - only subclass scenes. Create base class Creep.tscn to
# fix this.
@onready var _visual = $Visual
@onready var _sprite: AnimatedSprite2D = $Visual/Sprite
@onready var _health_bar = $Visual/HealthBar
@onready var _selection_area: Area2D = $Visual/SelectionArea


#########################
###     Built-in      ###
#########################

func _ready():
	super()

	_id = _id_max
	_id_max += 1

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
	_set_sprite_node(_sprite)
	_selection_outline = $Visual/SelectionOutline

	var sprite_dimensions: Vector2 = Utils.get_animated_sprite_dimensions(_sprite, ANIMATION_FOR_DIMENSIONS)
	_set_unit_dimensions(sprite_dimensions)

	var selection_size: float = min(sprite_dimensions.x, MAX_SELECTION_VISUAL_SIZE)
	_set_selection_size(selection_size)

	death.connect(_on_death)


func _process(delta):
	if !is_stunned():
		_move(delta)

	var creep_animation: String = _get_creep_animation()
	_sprite.play(creep_animation)
	_selection_outline.play(creep_animation)

	z_index = _calculate_current_z_index()


#########################
###       Public      ###
#########################

# NOTE: creep.adjustHeight() in JASS
func adjust_height(height_wc3: float, speed: float):
#	NOTE: can't create tween's while node is outside tree.
#	If creep is outside tree then it's okay to do nothing
#	because creep is about to get deleted anyway.
	if !is_inside_tree():
		return

	var creep_is_air: bool = get_size() == CreepSize.enm.AIR

#	NOTE: shouldn't change height of air creeps - it would
#	look weird
	if creep_is_air:
		return
	
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

# NOTE: when a creep has non-zero height, we need to adjust
# it's z index so that the sprite is drawn correctly in
# front of tiles.
func _calculate_current_z_index() -> int:
	var height: float = -_visual.position.y

# 	TODO: "100" is the placeholder. Figure out actual logic
# 	for how z_index of creep should change as it's height
# 	increases.
# 	NOTE: make z_index for air reeps 1 higher because air
# 	creeps should always be drawn above any ground creep
# 	which was elevated
	if height > 100:
		if get_size() == CreepSize.enm.AIR:
			return 11
		else:
			return 10
	else:
		return 0


func _reach_portal():
	var damage_to_portal = _get_damage_to_portal()
	var damage_to_portal_string: String = Utils.format_percent(damage_to_portal / 100, 1)
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


func _move(delta):
	var path_is_over: bool = _current_path_index >= _path.get_curve().get_point_count()
	if path_is_over:
		_reach_portal()

		return

	var path_point: Vector2 = _path.get_curve().get_point_position(_current_path_index) + _path.position
	var move_delta: float = get_current_movespeed() * delta
	position = Isometric.vector_move_toward(position, path_point, move_delta)
	moved.emit(delta)
	
	var reached_path_point: bool = (position == path_point)
	
	if reached_path_point:
		_current_path_index += 1

	var new_facing_angle: float = _get_current_movement_angle()
	set_unit_facing(new_facing_angle)


# Returns current movement angle, top down and in degrees
func _get_current_movement_angle() -> float:
	var path_curve: Curve2D = _path.get_curve()

	if _current_path_index >= path_curve.point_count:
		return _facing_angle

	var next_point: Vector2 = path_curve.get_point_position(_current_path_index) + _path.position
	var facing_vector_isometric: Vector2 = next_point - position
	var facing_vector_top_down: Vector2 = Isometric.isometric_vector_to_top_down(facing_vector_isometric)
	var top_down_angle_radians: float = facing_vector_top_down.angle()
	var top_down_angle_degrees: float = rad_to_deg(top_down_angle_radians)

	return top_down_angle_degrees


func _get_damage_to_portal() -> float:
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

	var damage_reduction_from_hp_ratio: float = (1 - pow(damage_done, damage_done_power))
	var damage_to_portal: float = 2.5 * type_multiplier * damage_reduction_from_hp_ratio

# 	NOTE: flock creeps deal half damage to portal
	var has_flock_special: bool = WaveSpecial.creep_has_flock_special(self)
	if has_flock_special:
		damage_to_portal *= 0.5

	return damage_to_portal


func _get_creep_animation() -> String:
	var animation_order: Array[String]
	
# TODO: Switch when certain speed limit is reached
#	if get_current_movespeed() > 300:
	var creep_move_speed = get_current_movespeed()
	match get_size():
		CreepSize.enm.MASS:
			if creep_move_speed > Constants.DEFAULT_MOVE_SPEED * 0.90:
				animation_order = [
					"run_E", "run_S", "run_W", "run_N"
				]
			else:
				animation_order = [
					"slow_run_E", "slow_run_S", "slow_run_W", "slow_run_N"
				]
		CreepSize.enm.CHALLENGE_MASS:
			if creep_move_speed > Constants.DEFAULT_MOVE_SPEED * 0.90:
				animation_order = [
					"run_E", "run_S", "run_W", "run_N"
				]
			else:
				animation_order = [
					"slow_run_E", "slow_run_S", "slow_run_W", "slow_run_N"
				]
		CreepSize.enm.BOSS:
			if creep_move_speed > Constants.DEFAULT_MOVE_SPEED * 1.50:
				animation_order = [
					"run_E", "run_S", "run_W", "run_N"
				]
			else:
				animation_order = [
					"slow_run_E", "slow_run_S", "slow_run_W", "slow_run_N"
				]
		CreepSize.enm.CHALLENGE_BOSS:
			if creep_move_speed > Constants.DEFAULT_MOVE_SPEED * 1.50:
				animation_order = [
					"run_E", "run_S", "run_W", "run_N"
				]
			else:
				animation_order = [
					"slow_run_E", "slow_run_S", "slow_run_W", "slow_run_N"
				]
		CreepSize.enm.NORMAL, CreepSize.enm.CHAMPION:
			if creep_move_speed > Constants.DEFAULT_MOVE_SPEED * 1.50:
				animation_order = [
					"run_E", "run_S", "run_W", "run_N"
				]
			else:
				animation_order = [
					"slow_run_E", "slow_run_S", "slow_run_W", "slow_run_N"
				]
		CreepSize.enm.AIR:
			animation_order = [
				"fly_E", "fly_SE", "fly_S", "fly_SW", "fly_W", "fly_NW", "fly_N", "fly_NE"
			]
		_:
			animation_order = [
				"stand", "stand", "stand", "stand", "stand", "stand", "stand", "stand"
			]

	var animation: String = _get_animation_based_on_facing_angle(animation_order)

	return animation


func _get_death_animation() -> String:
	var animation_list: Array[String] = [
		"death_E", "death_S", "death_W", "death_N"
	];
	var animation: String = _get_animation_based_on_facing_angle(animation_list)

	return animation


func _get_animation_based_on_facing_angle(animation_order: Array[String]) -> String:
# 	NOTE: convert facing angle to animation index by
# 	breaking down the 360 degree space into sections. 4 for
# 	ground units and 8 for air units. Then we figure out
# 	which section does the facing angle belong to. The index
# 	of that section will be equal to the animation index.
	var section_count: int = animation_order.size()
	var section_angle: float = 360.0 / section_count
	var animation_index: int = roundi((_facing_angle - section_angle / 2) / section_angle)

	if animation_index >= animation_order.size():
		print_debug("animation_index out of bounds = ", animation_index)
		animation_index = 0

	var animation: String = animation_order[animation_index]

	return animation


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
	if _size != CreepSize.enm.AIR:
		var corpse: Node2D = Globals.corpse_scene.instantiate()
		var death_animation: String = _get_death_animation()
		corpse.setup_sprite(_sprite, death_animation)
		corpse.position = position
		Utils.add_object_to_world(corpse)

		var blood_pool: Node2D = Globals.blood_pool_scene.instantiate()
		blood_pool.position = position
		Utils.add_object_to_world(blood_pool)


#########################
### Setters / Getters ###
#########################

# NOTE: creep.getBaseBountyValue() in JASS
func get_base_bounty_value() -> float:
	var creep_size: CreepSize.enm = get_size()
	var gold_multiplier: float = CreepSize.get_gold_multiplier(creep_size)
	var spawn_level: int = get_spawn_level()
	var bounty: float = gold_multiplier * (spawn_level / 8 + 1)

	return bounty


func get_log_name() -> String:
	var size_name: String = CreepSize.convert_to_string(get_size())
	var log_name: String = "%s-%d" % [size_name, _id]

	return log_name


# NOTE: SetUnitTimeScale() in JASS
func set_unit_time_scale(time_scale: float):
	_sprite.set_speed_scale(time_scale)
	_selection_outline.set_speed_scale(time_scale)


# NOTE: creeps are always considered to be attacking for the
# purposes of their autocasts.
func is_attacking() -> bool:
	return true


func get_current_movespeed() -> float:
	var base: float = get_base_movespeed()
	var mod: float = get_prop_move_speed()
	var mod_absolute: float = get_prop_move_speed_absolute()
	var unclamped: float = (base + mod_absolute) * mod
	var move_speed: float = clampf(unclamped, Constants.MOVE_SPEED_MIN, Constants.MOVE_SPEED_MAX)

	return move_speed


# Sets unit facing to an angle with respect to the positive
# X axis, in degrees.
# 
# NOTE: SetUnitFacing() in JASS
func set_unit_facing(angle: float):
# 	NOTE: limit facing angle to (0, 360) range
	_facing_angle = int(angle + 360) % 360

	var animation: String = _get_creep_animation()
	if animation != "":
		_sprite.play(animation)
		_selection_outline.play(animation)


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


func get_spawn_level() -> int:
	return _spawn_level


func set_spawn_level(spawn_level: int):
	_spawn_level = spawn_level


func get_special_list() -> Array[int]:
	return _special_list
