class_name Tower
extends Building


enum CsvProperty {
	SCENE_NAME = 0,
	NAME = 1,
	ID = 2,
	FAMILY_ID = 3,
	AUTHOR = 4,
	RARITY = 5,
	ELEMENT = 6,
	ATTACK_TYPE = 7,
	ATTACK_RANGE = 8,
	ATTACK_CD = 9,
	ATTACK_DAMAGE_MIN = 10,
	ATTACK_DAMAGE_MAX = 11,
	MANA = 12,
	MANA_REGEN = 13,
	COST = 14,
	DESCRIPTION = 15,
	TIER = 16,
	REQUIRED_ELEMENT_LEVEL = 17,
	REQUIRED_WAVE_LEVEL = 18,
	ICON_ATLAS_NUM = 19,
}

enum AttackStyle {
	NORMAL,
	SPLASH,
	BOUNCE,
}

enum Element {
	ICE ,
	NATURE,
	FIRE,
	ASTRAL,
	DARKNESS,
	IRON,
	STORM,
	NONE,
}



@export var attack_sound: AudioStreamMP3

const ATTACK_CD_MIN: float = 0.2
const SELECTION_SIZE: int = 128
const PROJECTILE_SPEED: int = 2000
const BOUNCE_RANGE: int = 250

var _id: int = 0
var _stats: Dictionary
var _splash_map: Dictionary = {}
var _bounce_count_max: int = 0
var _bounce_damage_multiplier: float = 0.0
var _attack_style: AttackStyle = AttackStyle.NORMAL
var _target_list: Array[Creep] = []
var _target_count_max: int = 1
var _default_projectile_type: ProjectileType
var _order_stop_requested: bool = false
var _current_attack_cooldown: float = 0.0


@onready var _attack_sound: AudioStreamPlayer2D = AudioStreamPlayer2D.new()
@onready var _range_indicator: RangeIndicator = $RangeIndicator
@onready var _targeting_area: Area2D = $TargetingArea
@onready var _collision_polygon: CollisionPolygon2D = $TargetingArea/CollisionPolygon2D
@onready var _mana_bar: ProgressBar = $ManaBar


#########################
### Code starts here  ###
#########################

func _ready():
	super()

# 	Load stats for current tier. Stats are defined in
# 	subclass.
	var tier: int = get_tier()
	var tier_stats: Dictionary = _get_tier_stats()
	_stats = tier_stats[tier]

	_attack_sound.set_stream(attack_sound)
	add_child(_attack_sound)

	var attack_range: float = get_attack_range()
	_range_indicator.set_radius(attack_range)

	mana_changed.connect(_on_mana_changed)
	_on_mana_changed()
	_mana_bar.visible = get_base_mana() > 0

	_default_projectile_type = ProjectileType.create("", 0.0, PROJECTILE_SPEED)

	load_specials()
	tower_init()
	on_create()

	_on_modify_property()


# NOTE: need to do attack timing without Timer because Timer
# doesn't handle short durations well (<0.5s)
func _process(delta: float):
	if _current_attack_cooldown > 0.0:
		_current_attack_cooldown -= delta

	if _current_attack_cooldown < 0.0:
		_on_attack_cooldown_timeout()


#########################
###       Public      ###
#########################

# Disables attacking or any other game interactions for the
# tower. Must be called after add_child().
func set_visual_only():
	_mana_bar.hide()

	for connection in get_incoming_connections():
		var the_signal: Signal = connection["signal"]
		var callable: Callable = connection.callable

		the_signal.disconnect(callable)


func add_autocast(autocast: Autocast):
	autocast.set_caster(self)
	add_child(autocast)


# TODO: implement. Also move to the "owner" class that is
# returned by getOwner(), when owner gets implemented. Find
# out what mystery bools are for.
func give_gold(amount: int, _unit: Unit, _mystery_bool_1: bool, _mystery_bool_2: bool):
	GoldManager.add_gold(amount)


func enable_default_sprite():
	$DefaultSprite.show()


# Called by TowerTooltip to get the part of the tooltip that
# is specific to the subclass
func on_tower_details() -> MultiboardValues:
	var empty_multiboard: MultiboardValues = MultiboardValues.new(0)

	return empty_multiboard


func order_stop():
	_order_stop_requested = true


#########################
###      Private      ###
#########################


# Override in subclass to initialize subclass tower. This is
# the analog of "init" function from original API.
func tower_init():
	pass


# NOTE: override this in subclass to add tower specials.
# This includes adding modifiers and changing attack styles
# to splash or bounce.
func load_specials():
	pass


# Override this in tower subclass to implement the "On Tower
# Creation" trigger. This is the analog of "onCreate"
# function from original API.
func on_create():
	pass


func _set_attack_style_splash(splash_map: Dictionary):
	_attack_style = AttackStyle.SPLASH
	_splash_map = splash_map


func _set_attack_style_bounce(bounce_count_max: int, bounce_damage_multiplier: float):
	_attack_style = AttackStyle.BOUNCE
	_bounce_count_max = bounce_count_max
	_bounce_damage_multiplier = bounce_damage_multiplier


# NOTE: if your tower needs to attack more than 1 target,
# call this f-n once in _ready() method of subclass
func _set_target_count(count: int):
	_target_count_max = count


func _tower_attack(target: Unit):
	var attack_event: Event = Event.new(target)
	super._do_attack(attack_event)

	if _order_stop_requested:
		_order_stop_requested = false

		return

	var projectile: Projectile = Projectile.create_from_unit_to_unit(_default_projectile_type, self, 0, 0, self, target, true, false, true)
	projectile.set_event_on_target_hit(_on_projectile_target_hit)

	_attack_sound.play()


# Override this in subclass to define custom stats for each
# tower tier. Access as _stats.
func _get_tier_stats() -> Dictionary:
	var tier: int = get_tier()
	var default_out: Dictionary = {}

	for i in range(1, tier + 1):
		default_out[i] = {}

	return default_out


func _select():
	super._select()

	_range_indicator.show()


func _unselect():
	super._unselect()

	_range_indicator.hide()


func _get_base_properties() -> Dictionary:
	return {}


func _on_modify_property():
	var attack_range: float = get_attack_range()
	Utils.circle_polygon_set_radius(_collision_polygon, attack_range)


func _get_next_bounce_target(prev_target: Creep) -> Creep:
	var creep_list: Array = Utils.get_units_in_range(TargetType.new(TargetType.CREEPS), prev_target.position, BOUNCE_RANGE)

	creep_list.erase(prev_target)

	Utils.sort_unit_list_by_distance(creep_list, prev_target.position)

	if !creep_list.is_empty():
		var next_target = creep_list[0]

		return next_target
	else:
		return null


func _try_to_attack():
	var attack_on_cooldown: bool = _current_attack_cooldown > 0
	
	if attack_on_cooldown:
		return

	var attacked_target: bool = false

	for target in _target_list:
		_tower_attack(target)

		attacked_target = true
	
# 	NOTE: important to add, not set! So that if game is
# 	lagging, all of the attacks fire instead of skipping.
	if attacked_target:
		_current_attack_cooldown += get_overall_cooldown()


func _find_new_target() -> Creep:
	var body_list: Array = _targeting_area.get_overlapping_bodies()

#	NOTE: can't use existing targets as new targets
	for target in _target_list:
		body_list.erase(target)

	body_list = body_list.filter(func(body): return body is Creep && !body.is_dead() && !body.is_invisible())

	Utils.sort_unit_list_by_distance(body_list, position)

	if body_list.size() != 0:
		var closest_creep: Creep = body_list[0]

		return closest_creep
	else:
		return null


func _have_target_space() -> bool:
	return _target_list.size() < _target_count_max


func _add_target(new_target: Creep):
	if new_target == null || new_target.is_dead() || new_target.is_invisible():
		return

	new_target.death.connect(_on_target_death.bind(new_target))
	new_target.became_invisible.connect(_on_target_became_invisible.bind(new_target))
	_target_list.append(new_target)


func _remove_target(target: Creep):
	target.death.disconnect(_on_target_death)
	target.became_invisible.disconnect(_on_target_became_invisible)

	_target_list.erase(target)


#########################
###     Callbacks     ###
#########################


func _on_mana_changed():
	_mana_bar.set_as_ratio(_mana / get_base_mana())


func _on_projectile_target_hit(projectile: Projectile, target: Unit):
	match _attack_style:
		AttackStyle.NORMAL:
			_on_projectile_target_hit_normal(projectile, target)
		AttackStyle.SPLASH:
			_on_projectile_target_hit_splash(projectile, target)
		AttackStyle.BOUNCE:
			_on_projectile_target_hit_bounce(projectile, target)


func _on_projectile_target_hit_normal(_projectile: Projectile, target: Unit):
	var damage: float = get_current_attack_damage_with_bonus()
	
	_do_attack_damage_internal(target, damage, calc_attack_multicrit(0, 0, 0), true)


func _on_projectile_target_hit_splash(_projectile: Projectile, target: Unit):
	if _splash_map.is_empty():
		return

	var damage: float = get_current_attack_damage_with_bonus()

	_do_attack_damage_internal(target, damage, calc_attack_multicrit(0, 0, 0), true)

	var splash_target: Unit = target
	var splash_pos: Vector2 = splash_target.position

#	Process splash ranges from closest to furthers,
#	so that strongest damage is applied
	var splash_range_list: Array = _splash_map.keys()
	splash_range_list.sort()

	var splash_range_max: float = splash_range_list.back()

	var creep_list: Array = Utils.get_units_in_range(TargetType.new(TargetType.CREEPS), splash_pos, splash_range_max)

	creep_list.erase(splash_target)

	for neighbor in creep_list:
		var distance: float = Utils.vector_isometric_distance_to(splash_pos, neighbor.position)

		for splash_range in splash_range_list:
			var creep_is_in_range: bool = distance < splash_range

			if creep_is_in_range:
				var splash_damage_ratio: float = _splash_map[splash_range]
				var splash_damage: float = damage * splash_damage_ratio
				_do_attack_damage_internal(neighbor, splash_damage, calc_attack_multicrit(0, 0, 0), false)

				break


func _on_projectile_target_hit_bounce(projectile: Projectile, target: Unit):
	var damage: float = get_current_attack_damage_with_bonus()

	projectile.user_real = damage
	projectile.user_int = _bounce_count_max - 1

	_on_projectile_bounce_in_progress(projectile, target)


func _on_projectile_bounce_in_progress(projectile: Projectile, current_target: Unit):
	var current_damage: float = projectile.user_real
	var current_bounce_count: int = projectile.user_int

	var is_first_bounce: bool = current_bounce_count == _bounce_count_max
	var is_main_target: bool = is_first_bounce

	_do_attack_damage_internal(current_target, current_damage, calc_attack_multicrit(0, 0, 0), is_main_target)

# 	Launch projectile for next bounce, if bounce isn't over
	var bounce_end: bool = current_bounce_count == 0

	if bounce_end:
		return

	var next_damage: float = current_damage * (1.0 - _bounce_damage_multiplier)
	var next_bounce_count: int = current_bounce_count - 1

	var next_target: Creep = _get_next_bounce_target(current_target)

	if next_target == null:
		return

	var next_projectile: Projectile = Projectile.create_from_unit_to_unit(_default_projectile_type, self, 0, 0, current_target, next_target, true, false, true)
	next_projectile.set_event_on_target_hit(_on_projectile_bounce_in_progress)
	next_projectile.user_real = next_damage
	next_projectile.user_int = next_bounce_count


func _on_targeting_area_body_entered(body):
	if !body is Creep:
		return

# 	If invisible creep comes in range, don't add it as target,
# 	but remember it by connecting to it's signal. If the creep
# 	becomes visible (while still in range), it may become a
# 	target.
	if !body.is_connected("became_visible", _on_creep_in_range_became_visible):
		body.became_visible.connect(_on_creep_in_range_became_visible.bind(body))

	if body.is_invisible():
		return

	if _have_target_space():
		var new_target: Creep = body as Creep
		_add_target(new_target)
		_try_to_attack()


func _on_targeting_area_body_exited(body):
	if !body is Creep:
		return

	body.became_visible.disconnect(_on_creep_in_range_became_visible)

	var target_went_out_of_range: bool = _target_list.has(body)

	if target_went_out_of_range:
		var old_target: Creep = body as Creep
		_remove_target(old_target)


func _on_target_became_invisible(target: Creep):
	_remove_target(target)


func _on_creep_in_range_became_visible(creep: Creep):
	_on_targeting_area_body_entered(creep)


func _on_target_death(_event: Event, target: Creep):
	_remove_target(target)


func _on_attack_cooldown_timeout():
	if _have_target_space():
		var new_target: Creep = _find_new_target()
		_add_target(new_target)

# 	NOTE: this is the one case where _try_to_attack() is called
# 	even if add_target() wasn't called
	_try_to_attack()


#########################
### Setters / Getters ###
#########################

func get_item_name() -> String:
	return get_csv_property(CsvProperty.NAME)


# NOTE: this must be called once after the tower is created
# but before it's added to game scene
func set_id(id: int):
	_id = id


func get_id() -> int:
	return _id


func get_tier() -> int:
	return get_csv_property(CsvProperty.TIER).to_int()

func get_family() -> int:
	return get_csv_property(CsvProperty.FAMILY_ID).to_int()

func get_icon_atlas_num() -> int:
	var icon_atlas_num_string: String = get_csv_property(CsvProperty.ICON_ATLAS_NUM)

	if !icon_atlas_num_string.is_empty():
		var icon_atlas_num: int = icon_atlas_num_string.to_int()

		return icon_atlas_num
	else:
		return -1

func get_element() -> Tower.Element:
	var element_string: String = get_csv_property(CsvProperty.ELEMENT)
	var element: Element = Element.get(element_string.to_upper())

	return element

# NOTE: in tower scripts getCategory() is called to get
# tower's element instead of getElement(), for some reason,
# so make this wrapper over get_element()
func get_category() -> int:
	return get_element()

# How many the seconds the tower needs to reload without modifications.
func get_base_cooldown() -> float:
	return get_csv_property(CsvProperty.ATTACK_CD).to_float()

# The result of the calculation of the Base Cooldown and the Attack Speed. 
# This is the real rate with which the tower will attack. 
# Example: If the Base Cooldown is 2.0 seconds and the tower has 125% attackspeed, 
# then the real attack cooldown will be 2.0/1.25 == 1.6 seconds.
func get_overall_cooldown() -> float:
	var attack_cooldown: float = get_base_cooldown()
	var attack_speed_mod: float = get_base_attack_speed()
	var overall_cooldown: float = attack_cooldown * (1.0 + attack_speed_mod)
	overall_cooldown = max(ATTACK_CD_MIN, overall_cooldown)

	return overall_cooldown


# TODO: i think this is supposed to return the player that
# owns the tower? Implement later. For now implementing
# owner's function in tower itself and returning tower from
# getOwner()
func getOwner():
	return self


func get_csv_property(csv_property: Tower.CsvProperty) -> String:
	var properties: Dictionary = Properties.get_tower_csv_properties_by_id(_id)
	var value: String = properties[csv_property]

	return value

func get_damage_min():
	return get_csv_property(CsvProperty.ATTACK_DAMAGE_MIN).to_int()

func get_damage_max():
	return get_csv_property(CsvProperty.ATTACK_DAMAGE_MAX).to_int()

func get_base_damage():
	return (get_damage_min() + get_damage_max()) / 2.0

func get_current_attack_damage() -> float:
	var damage_min: float = get_damage_min()
	var damage_max: float = get_damage_max()
	var damage: float = randf_range(damage_min, damage_max)

	return damage

func get_current_attack_damage_with_bonus() -> float:
	var damage_base: float = get_current_attack_damage()
	var white_damage: float = (damage_base + get_base_damage_bonus()) * (1.0 + get_base_damage_bonus_percent())
	var green_damage: float = get_damage_add() * (1.0 + get_damage_add_percent())

	var dps_bonus: float = get_dps_bonus()
	var cooldown: float = get_overall_cooldown()
	var dps_mod: float = dps_bonus * cooldown

	var damage: float = white_damage + green_damage + dps_mod

	return damage

# How much damage the tower deals with its attack per second on average (not counting in any crits). 
func get_overall_dps():
	return get_current_attack_damage_with_bonus() / get_overall_cooldown()

# How much damage the tower deals with its attack per second on average when 
# counting attack crits and multicrits.
func get_dps_with_crit():
	return get_overall_dps() * get_crit_multiplier()

# TODO: implement
# How much damage the tower dealt in total
func get_damage():
	return 1.0

# TODO: implement
# How much kills the tower has in total
func get_kills():
	return 1.0

# TODO: implement
# What was the max hit damage the tower dealt
func get_best_hit():
	return 1.0

func get_attack_range() -> float:
	return get_csv_property(CsvProperty.ATTACK_RANGE).to_float()

func get_rarity() -> String:
	return get_csv_property(CsvProperty.RARITY)
	
func get_rarity_num() -> int:
	return Constants.Rarity.get(get_rarity().to_upper())

func get_selection_size() -> int:
	return SELECTION_SIZE

func get_display_name() -> String:
	return get_csv_property(CsvProperty.NAME)

func get_attack_type() -> AttackType.enm:
	var attack_type_string: String = get_csv_property(CsvProperty.ATTACK_TYPE)
	var attack_type: AttackType.enm = AttackType.from_string(attack_type_string)

	return attack_type

func get_base_mana() -> float:
	return get_csv_property(CsvProperty.MANA).to_float()

func get_base_mana_regen() -> float:
	return get_csv_property(CsvProperty.MANA_REGEN).to_float()
