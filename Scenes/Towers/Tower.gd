class_name Tower
extends Building


signal items_changed()


# NOTE: order of CsvProperty enums must match the order of
# the columns in tower_properties.csv
enum CsvProperty {
	NAME,
	TIER,
	ID,
	FAMILY_ID,
	AUTHOR,
	RARITY,
	ELEMENT,
	ATTACK_TYPE,
	ATTACK_RANGE,
	ATTACK_CD,
	ATTACK_DAMAGE_MIN,
	ATTACK_DAMAGE_MAX,
	MANA,
	MANA_REGEN,
	COST,
	DESCRIPTION,
	REQUIRED_ELEMENT_LEVEL,
	REQUIRED_WAVE_LEVEL,
	ICON_ATLAS_NUM,
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
const PROJECTILE_SPEED: int = 2000
const BOUNCE_RANGE: int = 250
const ITEM_COUNT_MAX: int = 1

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
var _target_order_issued: bool = false
var _target_order_target: Unit
var _visual_only: bool = false
var _item_list: Array[Item] = []
var _item_oil_list: Array[Item] = []
var _specials_modifier: Modifier = Modifier.new()


@onready var _attack_sound: AudioStreamPlayer2D = AudioStreamPlayer2D.new()
@onready var _range_indicator: RangeIndicator = $RangeIndicator
@onready var _targeting_area: Area2D = $TargetingArea
@onready var _collision_polygon: CollisionPolygon2D = $TargetingArea/CollisionPolygon2D
@onready var _mana_bar: ProgressBar = $ManaBar


#########################
### Code starts here  ###
#########################

# NOTE: these f-ns needs to be called here and not in
# ready() so that we can form tooltip text for button
# tooltip
func _internal_tower_init():
# 	Load stats for current tier. Stats are defined in
# 	subclass.
	var tier: int = get_tier()
	var tier_stats: Dictionary = _get_tier_stats()
	_stats = tier_stats[tier]

	load_specials(_specials_modifier)


func _ready():
	super()

	_attack_sound.set_stream(attack_sound)
	add_child(_attack_sound)

	var attack_range: float = get_range()
	_range_indicator.set_radius(attack_range)

	mana_changed.connect(_on_mana_changed)
	_on_mana_changed()
	_mana_bar.visible = get_base_mana() > 0

	_default_projectile_type = ProjectileType.create("", 0.0, PROJECTILE_SPEED)

	add_modifier(_specials_modifier)

	tower_init()
	on_create()

	_on_modify_property()

	var sprite: Sprite2D = $Model/Sprite2D
	if sprite != null:
		_set_unit_sprite(sprite)

	selected.connect(on_selected)
	unselected.connect(on_unselected)


# NOTE: need to do attack timing without Timer because Timer
# doesn't handle short durations well (<0.5s)
func _process(delta: float):
	if _visual_only:
		return

	if _current_attack_cooldown > 0.0:
		_current_attack_cooldown -= delta

	if _current_attack_cooldown <= 0.0:
		var attack_success: bool = _try_to_attack()

# 		NOTE: important to add, not set! So that if game is
# 		lagging, all of the attacks fire instead of skipping.
		if attack_success:
			_current_attack_cooldown += get_overall_cooldown()


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

	_visual_only = true

# 	Remove selection area2d so that tower preview tower
# 	doesn't participate in hover/select behavior
	if selection_area2d != null:
		selection_area2d.queue_free()


func add_autocast(autocast: Autocast):
	autocast.set_caster(self)
	add_child(autocast)


func add_aura(aura_type: AuraType):
	var aura: Aura = aura_type.make(self)
	add_child(aura)


func have_item_space() -> bool:
	var item_count: int = _item_list.size()
	var have_space: bool = item_count < ITEM_COUNT_MAX

	return have_space


func add_item(item_id: int):
	var item: Item = Item.make(item_id)
	item.apply_to_tower(self)
	_item_list.append(item)
	add_child(item)

	items_changed.emit()


# TODO: when upgrade mechanic is implemented, make sure that
# item oils are transferred to upgraded instance. Iterate
# over _item_oil_list, add re-add oils to upgraded instance.
func add_item_oil(item_id: int):
	var item: Item = Item.make(item_id)
	item.apply_to_tower(self)
	_item_oil_list.append(item)
	add_child(item)


func remove_item(item_id: int):
	var removed_item: Item = null

	for item in _item_list:
		if item.get_id() == item_id:
			removed_item = item
			break

	if removed_item == null:
		return

	removed_item.remove_from_tower()
	_item_list.erase(removed_item)
	removed_item.queue_free()

	items_changed.emit()


func get_items() -> Array[Item]:
	return _item_list


# Called by TowerTooltip to get the part of the tooltip that
# is specific to the subclass
func on_tower_details() -> MultiboardValues:
	var empty_multiboard: MultiboardValues = MultiboardValues.new(0)

	return empty_multiboard


func order_stop():
	_order_stop_requested = true


# NOTE: "attack" is the only order_type encountered in tower
# scripts so ignore that parameter
func issue_target_order(order_type: String, target: Unit):
	if order_type != "attack":
		print_debug("Unhandled order_type in issue_target_order()")

	_target_order_issued = true
	_target_order_target = target


#########################
###      Private      ###
#########################


# This shouldn't be overriden in subclasses. This will
# automatically generate a string for specials that subclass
# defines in load_specials().
func get_specials_tooltip_text() -> String:
	var text: String = ""

	if _target_count_max > 1:
		text += "[b][color=gold]Multishot:[/color][/b]\nAttacks up to %d targets at the same time.\n" % [_target_count_max]

	match _attack_style:
		AttackStyle.SPLASH:
			text += _get_splash_attack_tooltip_text()
		AttackStyle.BOUNCE:
			text += _get_bounce_attack_tooltip_text()
		AttackStyle.NORMAL:
			text += ""

	var modifier_text: String = _specials_modifier.get_tooltip_text()
	text += modifier_text

	return text


# Override in subclass to define tower's extra tooltip text.
# This should contain description of special abilities.
# String can contain rich text format(BBCode).
# NOTE: by default all numbers in this text will be colored
# but you can also define your own custom color tags.
func get_extra_tooltip_text() -> String:
	return ""


# Override in subclass to initialize subclass tower. This is
# the analog of "init" function from original API.
func tower_init():
	pass


# NOTE: override this in subclass to add tower specials.
# This includes adding modifiers and changing attack styles
# to splash or bounce.
func load_specials(_modifier: Modifier):
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


func _try_to_attack() -> bool:
	if _have_target_space():
		var new_target: Creep = _find_new_target()
		_add_target(new_target)

#	NOTE: have to save this value before attacking because
#	attacking may kill targets which modifies the target
#	list
	var attack_success: bool = !_target_list.is_empty()

	for target in _target_list:
		_attack_target(target)
	
	return attack_success


func _attack_target(target: Unit):
	var attack_event: Event = Event.new(target)
	super._do_attack(attack_event)

	if _order_stop_requested:
		_order_stop_requested = false

		return

	if _target_order_issued:
		_target_order_issued = false

		target = _target_order_target

	if target == null:
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


func on_selected():
	_range_indicator.show()


func on_unselected():
	_range_indicator.hide()


func _get_base_properties() -> Dictionary:
	return {}


func _on_modify_property():
	var attack_range: float = get_range()
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
		var distance: float = Isometric.vector_distance_to(splash_pos, neighbor.position)

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


func _get_splash_attack_tooltip_text() -> String:
	var text: String = "[color=green_yellow]Splash attack:[/color]\n"

	var splash_range_list: Array = _splash_map.keys()
	splash_range_list.sort()

	for splash_range in splash_range_list:
		var splash_ratio: float = _splash_map[splash_range]
		var splash_percentage: int = floor(splash_ratio * 100)
		text += "\t%d AoE: %d%% damage\n" % [splash_range, splash_percentage]

	return text


func _get_bounce_attack_tooltip_text() -> String:
	var text: String = "[color=green_yellow]Bounce attack:[/color]\n\t%d targets\n\t-%d%% damage per bounce\n" % [_bounce_count_max, floor(_bounce_damage_multiplier * 100)]

	return text


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
	return TowerProperties.get_tier(_id)

func get_family() -> int:
	return get_csv_property(CsvProperty.FAMILY_ID).to_int()

func get_icon_atlas_num() -> int:
	return TowerProperties.get_icon_atlas_num(_id)

func get_element() -> Tower.Element:
	return TowerProperties.get_element(_id)

# NOTE: in tower scripts getCategory() is called to get
# tower's element instead of getElement(), for some reason,
# so make this wrapper over get_element()
func get_category() -> int:
	return get_element()

# How many the seconds the tower needs to reload without modifications.
func get_base_cooldown() -> float:
	return TowerProperties.get_base_cooldown(_id)

# The result of the calculation of the Base Cooldown and the Attack Speed. 
# This is the real rate with which the tower will attack. 
# Example: If the Base Cooldown is 2.0 seconds and the tower has 125% attackspeed, 
# then the real attack cooldown will be 2.0/1.25 == 1.6 seconds.
func get_overall_cooldown() -> float:
	var attack_cooldown: float = get_base_cooldown()
	var attack_speed_mod: float = get_base_attack_speed()
	var overall_cooldown: float = attack_cooldown / attack_speed_mod
	overall_cooldown = max(ATTACK_CD_MIN, overall_cooldown)

	return overall_cooldown


# NOTE: this f-n returns overall cooldown even though that
# doesn't match the name. See "M.E.F.I.S. Rocket" tower
# script for proof.
func get_current_attack_speed() -> float:
	return get_overall_cooldown()


# TODO: i think this is supposed to return the player that
# owns the tower? Implement later. For now implementing
# owner's function in tower itself and returning tower from
# getOwner()
func getOwner():
	return self


func get_csv_property(csv_property: Tower.CsvProperty) -> String:
	return TowerProperties.get_csv_property(_id, csv_property)

func get_damage_min():
	return TowerProperties.get_damage_min(_id)

func get_damage_max():
	return TowerProperties.get_damage_max(_id)

func get_base_damage():
	return TowerProperties.get_base_damage(_id)

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

# How much damage the tower dealt in total
func get_damage():
	return _damage_dealt_total

# How much kills the tower has in total
func get_kills():
	return _kill_count

# What was the max hit damage the tower dealt
func get_best_hit():
	return _best_hit

func get_range() -> float:
	return TowerProperties.get_range(_id)

func get_rarity() -> String:
	return TowerProperties.get_rarity(_id)
	
func get_rarity_num() -> int:
	return TowerProperties.get_rarity_num(_id)

func get_display_name() -> String:
	return TowerProperties.get_display_name(_id)

func get_attack_type() -> AttackType.enm:
	return TowerProperties.get_attack_type(_id)

func get_base_mana() -> float:
	return get_csv_property(CsvProperty.MANA).to_float()

func get_base_mana_regen() -> float:
	return get_csv_property(CsvProperty.MANA_REGEN).to_float()
