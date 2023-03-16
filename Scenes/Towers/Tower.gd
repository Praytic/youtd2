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
}

const _creep_category_to_mod_map: Dictionary = {
	Unit.CreepCategory.UNDEAD: Unit.ModType.MOD_DMG_TO_MASS,
	Unit.CreepCategory.MAGIC: Unit.ModType.MOD_DMG_TO_MAGIC,
	Unit.CreepCategory.NATURE: Unit.ModType.MOD_DMG_TO_NATURE,
	Unit.CreepCategory.ORC: Unit.ModType.MOD_DMG_TO_ORC,
	Unit.CreepCategory.HUMANOID: Unit.ModType.MOD_DMG_TO_HUMANOID,
}

const _creep_size_to_mod_map: Dictionary = {
	Unit.CreepSize.MASS: Unit.ModType.MOD_DMG_TO_MASS,
	Unit.CreepSize.NORMAL: Unit.ModType.MOD_DMG_TO_NORMAL,
	Unit.CreepSize.CHAMPION: Unit.ModType.MOD_DMG_TO_CHAMPION,
	Unit.CreepSize.BOSS: Unit.ModType.MOD_DMG_TO_BOSS,
	Unit.CreepSize.AIR: Unit.ModType.MOD_DMG_TO_AIR,
}

@export var attack_sound: AudioStreamMP3

const ATTACK_CD_MIN: float = 0.2
const SELECTION_SIZE: int = 128

var _id: int = 0
var _stats: Dictionary
var _attack_autocast: Autocast
var _projectile_scene: PackedScene = preload("res://Scenes/Projectile.tscn")
var _splash_map: Dictionary = {}
var _bounce_count_max: int = 0
var _bounce_damage_multiplier: float = 0.0
var _attack_style: int = AttackStyle.NORMAL


@onready var _attack_sound: AudioStreamPlayer2D = AudioStreamPlayer2D.new()
@onready var _range_indicator: RangeIndicator = $RangeIndicator


#########################
### Code starts here  ###
#########################

func _ready():
	super()

	_is_tower = true


# 	Load stats for current tier. Stats are defined in
# 	subclass.
	var tier: int = get_tier()
	var tier_stats: Dictionary = _get_tier_stats()
	_stats = tier_stats[tier]

	_attack_sound.set_stream(attack_sound)
	add_child(_attack_sound)

	var attack_range: float = get_attack_range()
	_range_indicator.set_radius(attack_range)

	_attack_autocast = Autocast.make()
	_attack_autocast.caster_art = ""
	_attack_autocast.num_buffs_before_idle = 0
	_attack_autocast.autocast_type = Autocast.Type.AC_TYPE_OFFENSIVE_UNIT
	_attack_autocast.the_range = attack_range
	_attack_autocast.target_self = false
	_attack_autocast.target_art = ""
	_attack_autocast.cooldown = get_overall_cooldown()
	_attack_autocast.is_extended = true
	_attack_autocast.mana_cost = 0
	_attack_autocast.buff_type = 0
	_attack_autocast.target_type = TargetType.new(TargetType.UnitType.CREEPS)
	_attack_autocast.auto_range = attack_range
	_attack_autocast.handler = _base_class_attack_autocast

	add_autocast(_attack_autocast)

	_tower_init()


#########################
###       Public      ###
#########################


func add_autocast(autocast: Autocast):
	autocast._caster = self
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


#########################
###      Private      ###
#########################


# Override in subclass to initialize subclass tower
func _tower_init():
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
	_attack_autocast._target_count_max = count


func _base_class_attack_autocast(event: Event):
	var target = event.get_target()

	var projectile = _projectile_scene.instantiate()
	projectile.create("placeholder", 0, 1000)
	projectile.create_from_unit_to_unit(self, 0, 0, self, target, true, false, true)
	projectile.set_event_on_target_hit(self, "_on_projectile_target_hit")

	super._do_attack(event)

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
	var attack_cooldown: float = get_overall_cooldown()
	_attack_autocast.set_cooldown(attack_cooldown)


func _get_damage_mod_for_creep_category(creep: Creep) -> float:
	var creep_category: int = creep.get_category()
	var mod_type: int = _creep_category_to_mod_map[creep_category]
	var damage_mod: float = _mod_value_map[mod_type]

	return damage_mod

func _get_damage_mod_for_creep_armor_type(creep: Creep) -> float:
	var attack_type: AttackType.enm = get_attack_type()
	var armor_type: ArmorType.enm = creep.get_armor_type()
	var damage_mod: float = AttackType.get_damage_against(attack_type, armor_type)

	return damage_mod

func _get_damage_mod_for_creep_size(creep: Creep) -> float:
	var creep_size: int = creep.get_size()
	var mod_type: int = _creep_category_to_mod_map[creep_size]
	var damage_mod: float = _mod_value_map[mod_type]

	return damage_mod


func _get_damage_to_creep(creep: Creep) -> float:
	var damage: float = get_current_attack_damage_with_bonus()

	var damage_mod_list: Array = [
		_get_damage_mod_for_creep_size(creep),
		_get_damage_mod_for_creep_category(creep),
		_get_damage_mod_for_creep_armor_type(creep),
	]

#	NOTE: that armor resistance needs to be applied before
#	on_damage

#	NOTE: clamp at 0.0 to prevent damage from turning
#	negative
	for damage_mod in damage_mod_list:
		damage *= damage_mod

	damage = max(0.0, damage)

	return damage


func _get_next_bounce_target(prev_target: Creep) -> Creep:
	var attack_range: float = get_attack_range()
	var creep_list: Array = Utils.over_units_in_range_of_caster(prev_target, TargetType.new(TargetType.UnitType.CREEPS), attack_range)

	Utils.sort_unit_list_by_distance(creep_list, prev_target.position)

	if !creep_list.is_empty():
		var next_target = creep_list[0]

		return next_target
	else:
		return null


#########################
###     Callbacks     ###
#########################


func _on_projectile_target_hit(projectile: Projectile):
	match _attack_style:
		AttackStyle.NORMAL:
			_on_projectile_target_hit_normal(projectile)
		AttackStyle.SPLASH:
			_on_projectile_target_hit_splash(projectile)
		AttackStyle.BOUNCE:
			_on_projectile_target_hit_bounce(projectile)


func _on_projectile_target_hit_normal(projectile: Projectile):
	var target: Unit = projectile.get_target()
	var creep: Creep = target as Creep

	var damage: float = _get_damage_to_creep(creep)
	
	do_attack_damage(target, damage, calc_attack_multicrit(0, 0, 0))


func _on_projectile_target_hit_splash(projectile: Projectile):
	var target: Unit = projectile.get_target()
	var creep: Creep = target as Creep

	if _splash_map.is_empty():
		return

	var damage: float = _get_damage_to_creep(creep)

	do_attack_damage(target, damage, calc_attack_multicrit(0, 0, 0))

	var splash_target: Unit = target
	var splash_pos: Vector2 = splash_target.position

#	Process splash ranges from closest to furthers,
#	so that strongest damage is applied
	var splash_range_list: Array = _splash_map.keys()
	splash_range_list.sort()

	var splash_range_max: float = splash_range_list.back()

	var creep_list: Array = Utils.over_units_in_range_of_caster(splash_target, TargetType.new(TargetType.UnitType.CREEPS), splash_range_max)

	for neighbor in creep_list:
		var distance: float = Utils.vector_isometric_distance_to(splash_pos, neighbor.position)

		for splash_range in splash_range_list:
			var creep_is_in_range: bool = distance < splash_range

			if creep_is_in_range:
				var splash_damage_ratio: float = _splash_map[splash_range]
				var splash_damage: float = damage * splash_damage_ratio
				_do_damage(neighbor, splash_damage, true)

				break


func _on_projectile_target_hit_bounce(projectile: Projectile):
	var target: Unit = projectile.get_target()
	var creep: Creep = target as Creep

	var damage: float = _get_damage_to_creep(creep)

	projectile.user_real = damage
	projectile.user_int = _bounce_count_max

	_on_projectile_bounce_in_progress(projectile)


func _on_projectile_bounce_in_progress(projectile: Projectile):
	var current_target: Unit = projectile.get_target()
	var current_damage: float = projectile.user_real
	var current_bounce_count: int = projectile.user_int

	do_attack_damage(current_target, current_damage, calc_attack_multicrit(0, 0, 0))

# 	Launch projectile for next bounce, if bounce isn't over
	var bounce_end: bool = current_bounce_count == 0

	if bounce_end:
		return

	var next_damage: float = current_damage * (1.0 - _bounce_damage_multiplier)
	var next_bounce_count: int = current_bounce_count - 1

	var next_target: Creep = _get_next_bounce_target(current_target)

	if next_target == null:
		return

	var next_projectile = _projectile_scene.instantiate()
	next_projectile.create("placeholder", 0, 1000)
	next_projectile.create_from_unit_to_unit(self, 0, 0, current_target, next_target, true, false, true)
	next_projectile.user_real = next_damage
	next_projectile.user_int = next_bounce_count
	next_projectile.set_event_on_interpolation_finished(self, "_on_projectile_bounce_in_progress")


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

func get_element() -> int:
	var element_string: String = get_csv_property(CsvProperty.ELEMENT)
	var element: int = Element.get(element_string.to_upper())

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


# TODO: implement
func get_exp() -> float:
	return 0.0


# TODO: implement
func remove_exp_flat(_amount: float):
	pass


# TODO: i think this is supposed to return the player that
# owns the tower? Implement later. For now implementing
# owner's function in tower itself and returning tower from
# getOwner()
func getOwner():
	return self


func get_csv_property(csv_property: int) -> String:
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

# TODO: implement
# How much experience the tower has
func get_experience():
	return 1.0

# TODO: implement
# How much experience the tower needs for the next level
func get_experience_for_next_level():
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
