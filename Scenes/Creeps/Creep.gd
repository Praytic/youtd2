class_name Creep
extends Unit


signal moved(delta)


const HEIGHT_TWEEN_FAST_FORWARD_DELTA: float = 100.0
const ANIMATION_FOR_DIMENSIONS: String = "default"

# NOTE: need to limit size of selection visual so that creep
# selection visual doesn't clip into floor2 tiles.
const MAX_SELECTION_VISUAL_SIZE: float = 120.0

const run_animations: Array[String] = ["run_E", "run_S", "run_W", "run_N"]
const slow_run_animations: Array[String] = ["slow_run_E", "slow_run_S", "slow_run_W", "slow_run_N"]
const fly_animations: Array[String] = ["fly_E", "fly_SE", "fly_S", "fly_SW", "fly_W", "fly_NW", "fly_N", "fly_NE"]
const death_animations: Array[String] = ["death_E", "death_S", "death_W", "death_N"]

# This is a threshold speed at which creeps will switch from
# "slow run" to "fast run" animations.
const run_animation_threshold_map: Dictionary = {
	CreepSize.enm.MASS: Constants.DEFAULT_MOVE_SPEED * 0.90,
	CreepSize.enm.NORMAL: Constants.DEFAULT_MOVE_SPEED * 1.50,
	CreepSize.enm.AIR: Constants.DEFAULT_MOVE_SPEED * 1.50,
	CreepSize.enm.CHAMPION: Constants.DEFAULT_MOVE_SPEED * 1.50,
	CreepSize.enm.BOSS: Constants.DEFAULT_MOVE_SPEED * 1.50,
	CreepSize.enm.CHALLENGE_MASS: Constants.DEFAULT_MOVE_SPEED * 0.90,
	CreepSize.enm.CHALLENGE_BOSS: Constants.DEFAULT_MOVE_SPEED * 1.50,
}

var _path: Path2D : set = set_path
var _size: CreepSize.enm
var _category: CreepCategory.enm : set = set_category, get = get_category
var _armor_type: ArmorType.enm : set = set_armor_type, get = get_armor_type
var _current_path_index: int = 0
var _facing_angle: float = 0.0
var _spawn_level: int
var _special_list: Array[int] = [] : set = set_special_list, get = get_special_list
var _current_height: float = 0.0
var _target_height: float = 0.0
var _height_change_speed: float = 0.0


# NOTE: need to use @onready for these variables instead of
# @export because export vars cause null errors in HTML5
# build, for some reason.
# TODO: figure out the reason for errors and fix them if possible.
@onready var _visual = $Visual
@onready var _sprite: AnimatedSprite2D = $Visual/Sprite
@onready var _health_bar = $Visual/HealthBar
@onready var _selection_area: Area2D = $Visual/SelectionArea
@onready var _specials_icon_container: Container = $Visual/SpecialsIconContainer


#########################
###     Built-in      ###
#########################

func _ready():
	super()

	GroupManager.add("creeps", self, get_uid())
	
	var max_health = get_overall_health()
	_health_bar.set_max(max_health)
	_health_bar.set_min(0.0)
	_health_bar.set_value(max_health)
	health_changed.connect(_on_health_changed)

	if _size == CreepSize.enm.AIR:
		_current_height = 2 * Constants.TILE_SIZE.y
		_target_height = _current_height
		_visual.position.y = -_current_height
	
	_setup_selection_signals(_selection_area)
	
	_set_visual_node(_visual)
	var outline_thickness: float = _get_outline_thickness()
	_set_sprite_node(_sprite, outline_thickness)

	var sprite_dimensions: Vector2 = Utils.get_animated_sprite_dimensions(_sprite, ANIMATION_FOR_DIMENSIONS)
	_set_unit_dimensions(sprite_dimensions)

	var selection_size: float = min(sprite_dimensions.x, MAX_SELECTION_VISUAL_SIZE)
	_set_selection_size(selection_size)

	death.connect(_on_death)


func update(delta: float):
	if !is_stunned():
		_move(delta)

	if is_queued_for_deletion():
		return

	var creep_animation: String = _get_creep_animation()
	_sprite.play(creep_animation)
	_selection_outline.play(creep_animation)

	if _current_height != _target_height:
		var height_change: float = _height_change_speed * delta

		if _current_height < _target_height:
			_current_height = max(_target_height, _current_height + height_change)
		else:
			_current_height = min(_target_height, _current_height - height_change)

		_visual.position.y = -_current_height

	z_index = _calculate_current_z_index()


#########################
###       Public      ###
#########################

# Returns score which will be granted by Creep.
# Note that this value depends on creep health.
# NOTE: this function is *mostly* correct. Some multipliers
# may still be missing.
# TODO: implement score multiplier which depends team count
# or "owner gets bounty" setting. Couldn't understand how it
# works last time I tried.
func get_score(difficulty: Difficulty.enm, game_length: int, game_mode: GameMode.enm) -> float:
	const difficulty_multiplier_map: Dictionary = {
		Difficulty.enm.BEGINNER: 1.0,
		Difficulty.enm.EASY: 2.0,
		Difficulty.enm.MEDIUM: 3.0,
		Difficulty.enm.HARD: 4.0,
		Difficulty.enm.EXTREME: 5.0,
	}
	var difficulty_multiplier: float = difficulty_multiplier_map[difficulty]

	const length_multiplier_map: Dictionary = {
		Constants.WAVE_COUNT_TRIAL: 1.0,
		Constants.WAVE_COUNT_FULL: 1.0,
		Constants.WAVE_COUNT_NEVERENDING: 0.9,
	}
	var length_multiplier: float = length_multiplier_map[game_length]

	const game_mode_multiplier_map: Dictionary = {
		GameMode.enm.BUILD: 0.9,
		GameMode.enm.RANDOM_WITH_UPGRADES: 1.0,
		GameMode.enm.TOTALLY_RANDOM: 1.35,
	}
	var game_mode_multiplier: float = game_mode_multiplier_map[game_mode]

	var settings_multiplier: float = difficulty_multiplier * length_multiplier * game_mode_multiplier

	var damage_done: float = get_damage_done()
	var size_multiplier: float = CreepSize.get_score_multiplier(_size)
	var score: float = damage_done * (_spawn_level / 8 + 1) * settings_multiplier * size_multiplier
	
	return score


func get_damage_to_portal() -> float:
#	NOTE: final wave boss deals full damage to portal
	var wave_count: int = Globals.get_wave_count()
	var is_final_wave: bool = _spawn_level == wave_count

	if is_final_wave:
		return 100.0

	if _size == CreepSize.enm.CHALLENGE_MASS || _size == CreepSize.enm.CHALLENGE_BOSS:
		return 0

	var damage_done: float = get_damage_done()

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


func add_special_icon(special_icon: TextureRect):
	_specials_icon_container.add_child(special_icon)


# Creep moves to a point on path, which is closest to given
# point.
func move_to_point(point: Vector2):
	var curve: Curve2D = _path.curve

	var min_distance: float = 10000.0
	var min_index: int = -1
	var min_position: Vector2 = Vector2.ZERO
	var prev: Vector2 = curve.get_point_position(0)

	for i in range(1, curve.point_count):
		var curr: Vector2 = curve.get_point_position(i)
		var closest_point: Vector2 = Geometry2D.get_closest_point_to_segment(point, prev, curr)
		var distance: float = closest_point.distance_to(point)

		if distance < min_distance:
			min_distance = distance
			min_index = i
			min_position = closest_point

		prev = curr

	if min_index == -1:
		return
	
	position = min_position
	_current_path_index = min_index


# NOTE: creep.adjustHeight() in JASS
# NOTE: can't use tween here because it causes desync.
func adjust_height(height_wc3: float, speed_wc3: float):
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
	var speed_pixels: float = Utils.to_pixels(speed_wc3) / 2

	_target_height += height_pixels
	_height_change_speed = speed_pixels


# NOTE: creep.dropItem() in JASS

# NOTE: _use_creep_player is supposed to switch between
# using the player which owns the tower vs the player which
# owns the lane on which the creep spawned. Currently, the
# concept of "item being owned by a player" is not
# implemented.
func drop_item(caster: Tower, use_creep_player: bool):
	var random_item: int = ItemDropCalc.get_random_item(caster, self)

	if random_item == 0:
		return

	drop_item_by_id(caster, use_creep_player, random_item)


func drop_item_by_id(caster: Tower, _use_creep_player: bool, item_id):
	var item: Item = Item.create(caster.get_player(), item_id, position)
	item.fly_to_stash(0.0)

	var item_name: String = ItemProperties.get_item_name(item_id)
	var item_rarity: Rarity.enm = ItemProperties.get_rarity(item_id)
	var rarity_color: Color = Rarity.get_color(item_rarity)

	caster.get_player().display_floating_text(item_name, self, rarity_color)


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


func _move(delta):
	var path_is_over: bool = _current_path_index >= _path.get_curve().get_point_count()
	if path_is_over:
		_deal_damage_to_portal()
		remove_from_game()

		return

	var path_point: Vector2 = _path.get_curve().get_point_position(_current_path_index)
	var move_delta: float = get_current_movespeed() * delta
	position = Isometric.vector_move_toward(position, path_point, move_delta)
	moved.emit(delta)
	
	var reached_path_point: bool = (position == path_point)
	
	if reached_path_point:
		_current_path_index += 1

	var new_facing_angle: float = _get_current_movement_angle()
	set_unit_facing(new_facing_angle)


func _deal_damage_to_portal():
	var damage_to_portal = get_damage_to_portal()
	var damage_to_portal_string: String = Utils.format_percent(damage_to_portal / 100, 1)
	var damage_done: float = get_damage_done()
	var damage_done_string: String = Utils.format_percent(damage_done, 2)
	var creep_size: CreepSize.enm = get_size()
	var creep_size_string: String = CreepSize.convert_to_string(creep_size)
	var creep_score: float = get_score(Globals.get_difficulty(), Globals.get_wave_count(), Globals.get_game_mode())

	var player: Player = get_player()
	
	if creep_size == CreepSize.enm.BOSS:
		Messages.add_normal(player, "Dealt %s damage to BOSS" % damage_done_string)
	else:
		Messages.add_normal(player, "Failed to kill a %s" % creep_size_string.to_upper())		

	if damage_to_portal > 0:
		Messages.add_normal(player, "You lose %s of your lives!" % damage_to_portal_string)

	if creep_score > 0:
		player.add_score(creep_score)

	player.get_team().modify_lives(-damage_to_portal)

	SFX.play_sfx("res://Assets/SFX/Assets_SFX_hit_3.mp3")


# Returns current movement angle, top down and in degrees
func _get_current_movement_angle() -> float:
	var path_curve: Curve2D = _path.get_curve()

	if _current_path_index >= path_curve.point_count:
		return _facing_angle

	var next_point: Vector2 = path_curve.get_point_position(_current_path_index)
	var facing_vector_isometric: Vector2 = next_point - position
	var facing_vector_top_down: Vector2 = Isometric.isometric_vector_to_top_down(facing_vector_isometric)
	var top_down_angle_radians: float = facing_vector_top_down.angle()
	var top_down_angle_degrees: float = rad_to_deg(top_down_angle_radians)

	return top_down_angle_degrees


func _get_creep_animation() -> String:
	var animation_list: Array[String]
	
	if get_size() == CreepSize.enm.AIR:
		animation_list = fly_animations
	else:
		var creep_move_speed: float = get_current_movespeed()
		var fast_run_threshold: float = run_animation_threshold_map[get_size()]
		var use_run_animations: bool = creep_move_speed > fast_run_threshold

		if use_run_animations:
			animation_list = run_animations
		else:
			animation_list = slow_run_animations

	var animation: String = _get_animation_based_on_facing_angle(animation_list)

	return animation


func _get_death_animation() -> String:
	var animation: String = _get_animation_based_on_facing_angle(death_animations)

	return animation


func _get_animation_based_on_facing_angle(animation_order: Array[String]) -> String:
# 	NOTE: convert facing angle to animation index by
# 	breaking down the 360 degree space into sections. 4 for
# 	ground units and 8 for air units. Then we figure out
# 	which section does the facing angle belong to. The index
# 	of that section will be equal to the animation index.
	var facing_angle_top_down: float = _facing_angle
	var facing_angle_isometric: float = facing_angle_top_down - 45
	var section_count: int = animation_order.size()
	var section_angle: float = 360.0 / section_count
	var animation_index: int = roundi(facing_angle_isometric / section_angle)

	if animation_index >= animation_order.size():
		print_debug("animation_index out of bounds = ", animation_index)
		animation_index = 0

	var animation: String = animation_order[animation_index]

	return animation


# NOTE: different thickness is used for different sizes to
# account for differences in sprite scale.
func _get_outline_thickness() -> float:
	match get_size():
		CreepSize.enm.MASS: return 4.5
		CreepSize.enm.NORMAL: return 3.8
		CreepSize.enm.AIR: return 3.0
		CreepSize.enm.CHAMPION: return 2.8
		CreepSize.enm.BOSS: return 2.0
		CreepSize.enm.CHALLENGE_MASS: return 4.5
		CreepSize.enm.CHALLENGE_BOSS: return 2.0

	return 10.0


#########################
###     Callbacks     ###
#########################

func _on_health_changed():
	var health_ratio: float = get_health_ratio()
	_health_bar.ratio = health_ratio


func _on_death(_event: Event):
	var creep_score: float = get_score(Globals.get_difficulty(), Globals.get_wave_count(), Globals.get_game_mode())

	if creep_score > 0:
		var player: Player = get_player()
		player.add_score(creep_score)

# 	Death visual
	var effect_id: int = Effect.create_simple_at_unit("res://Scenes/Effects/DeathExplode.tscn", self)
	var effect_scale: float = max(_sprite_dimensions.x, _sprite_dimensions.y) / Constants.DEATH_EXPLODE_EFFECT_SIZE
	Effect.set_scale(effect_id, effect_scale)
	Effect.destroy_effect_after_its_over(effect_id)

# 	Add corpse object
	if _size != CreepSize.enm.AIR:
		var death_animation: String = _get_death_animation()
		var corpse: CreepCorpse = CreepCorpse.make(get_player(), _sprite, death_animation)
		corpse.position = position
		Utils.add_object_to_world(corpse)

		var blood_pool: Node2D = Preloads.blood_pool_scene.instantiate()
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
	var size_name: String = CreepSize.convert_to_string(_size)
	var log_name: String = "%s-%d" % [size_name, get_uid()]

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
# NOTE: angle is top down
# 
# NOTE: SetUnitFacing() in JASS
func set_unit_facing(angle: float):
# 	NOTE: limit facing angle to (0, 360) range
	_facing_angle = int(angle + 360) % 360

	var animation: String = _get_creep_animation()
	if animation != "":
		_sprite.play(animation)
		_selection_outline.play(animation)


# NOTE: angle is top down
# NOTE: GetUnitFacing() in JASS
func get_unit_facing() -> float:
	return _facing_angle

func set_creep_size(value: CreepSize.enm) -> void:
	_size = value

# NOTE: this special function forces CHALLENGE_MASS and
# CHALLENGE_BOSS to be treated as MASS and BOSS creeps. Use
# get_size_including_challenge_sizes() to get the "real"
# creep size.
func get_size() -> CreepSize.enm:
	if _size == CreepSize.enm.CHALLENGE_MASS:
		return CreepSize.enm.MASS
	elif _size == CreepSize.enm.CHALLENGE_BOSS:
		return CreepSize.enm.BOSS
	else:
		return _size

func get_size_including_challenge_sizes() -> CreepSize.enm:
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
	if path:
		position = path.get_curve().get_point_position(0)


func get_spawn_level() -> int:
	return _spawn_level


func set_spawn_level(spawn_level: int):
	_spawn_level = spawn_level


func get_special_list() -> Array[int]:
	return _special_list


func set_special_list(special_list: Array[int]):
	_special_list = special_list


func set_hovered(hovered: bool):
	super.set_hovered(hovered)
	if hovered:
		_specials_icon_container.set_visible(hovered)
	else:
		_specials_icon_container.set_visible(is_selected())


func set_selected(value: bool):
	super.set_selected(value)
	_specials_icon_container.set_visible(value)
