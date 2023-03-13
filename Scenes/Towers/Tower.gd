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
	COST = 12,
	DESCRIPTION = 13,
	TIER = 14,
	REQUIRED_ELEMENT_LEVEL = 15,
	REQUIRED_WAVE_LEVEL = 16,
	ICON_ATLAS_NUM = 17,
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

const _mob_category_to_mod_map: Dictionary = {
	Unit.MobCategory.UNDEAD: Unit.ModType.MOD_DMG_TO_MASS,
	Unit.MobCategory.MAGIC: Unit.ModType.MOD_DMG_TO_MAGIC,
	Unit.MobCategory.NATURE: Unit.ModType.MOD_DMG_TO_NATURE,
	Unit.MobCategory.ORC: Unit.ModType.MOD_DMG_TO_ORC,
	Unit.MobCategory.HUMANOID: Unit.ModType.MOD_DMG_TO_HUMANOID,
}

const _mob_size_to_mod_map: Dictionary = {
	Unit.MobSize.MASS: Unit.ModType.MOD_DMG_TO_MASS,
	Unit.MobSize.NORMAL: Unit.ModType.MOD_DMG_TO_NORMAL,
	Unit.MobSize.CHAMPION: Unit.ModType.MOD_DMG_TO_CHAMPION,
	Unit.MobSize.BOSS: Unit.ModType.MOD_DMG_TO_BOSS,
	Unit.MobSize.AIR: Unit.ModType.MOD_DMG_TO_AIR,
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

	var attack_autocast_data = Autocast.Data.new()
	attack_autocast_data.caster_art = ""
	attack_autocast_data.num_buffs_before_idle = 0
	attack_autocast_data.autocast_type = Autocast.Type.AC_TYPE_OFFENSIVE_UNIT
	attack_autocast_data.the_range = attack_range
	attack_autocast_data.target_self = false
	attack_autocast_data.target_art = ""
	attack_autocast_data.cooldown = get_overall_cooldown()
	attack_autocast_data.is_extended = true
	attack_autocast_data.mana_cost = 0
	attack_autocast_data.buff_type = 0
	attack_autocast_data.target_type = TargetType.new(TargetType.UnitType.MOBS)
	attack_autocast_data.auto_range = attack_range

	var attack_buff = TriggersBuff.new()
	_attack_autocast = attack_buff.add_autocast(attack_autocast_data, self, "_on_attack_autocast")
	attack_buff.apply_to_unit_permanent(self, self, 0)

	_tower_init()


#########################
###       Public      ###
#########################

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


func _on_attack_autocast(event: Event):
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


# NOTE: returns random damage within range without any mods applied
func _get_rand_damage_base() -> float:
	var damage_min: float = get_damage_min()
	var damage_max: float = get_damage_max()
	var damage: float = randf_range(damage_min, damage_max)

	return damage


func _get_base_properties() -> Dictionary:
	return {}


func _on_modify_property():
	var attack_cooldown: float = get_overall_cooldown()
	_attack_autocast.set_cooldown(attack_cooldown)


func _get_damage_mod_for_mob_category(mob: Mob) -> float:
	var mob_category: int = mob.get_category()
	var mod_type: int = _mob_category_to_mod_map[mob_category]
	var damage_mod: float = _mod_value_map[mod_type]

	return damage_mod

func _get_damage_mod_for_mob_armor_type(mob: Mob) -> float:
	var attack_type: AttackType.enm = get_attack_type()
	var armor_type: ArmorType.enm = mob.get_armor_type()
	var damage_mod: float = AttackType.get_damage_against(attack_type, armor_type)

	return damage_mod

func _get_damage_mod_for_mob_size(mob: Mob) -> float:
	var mob_size: int = mob.get_size()
	var mod_type: int = _mob_category_to_mod_map[mob_size]
	var damage_mod: float = _mod_value_map[mod_type]

	return damage_mod


# TODO: should bonus from multiple crits add with each other
# or multiply? For example: if there are 3 crits should
# total bonus be (1.5 + 1.5 + 1.5) or (1.5 * 1.5 * 1.5)?
# TODO: is base crit bonus from one crit +50% dmg or + 100%
# dmg?
# TODO: white/green might be wrong
func _get_damage_to_mob(mob: Mob) -> float:
	var white_damage: float = _get_rand_damage_base() * (1.0 + get_base_damage_bonus_percent())
	var green_damage: float = get_damage_add() * (1.0 + get_damage_add_percent())

	var damage = white_damage + green_damage

	var damage_mod_list: Array = [
		_get_damage_mod_for_mob_size(mob),
		_get_damage_mod_for_mob_category(mob),
		_get_damage_mod_for_mob_armor_type(mob),
	]

# 	NOTE: crit count can go above 1 because of the multicrit
# 	property

#	TODO: according to this comment in one tower script,
#	crit mod should happend after on_damage event:
#
# 	Quote: "The engine calculates critical strike extra
# 	damage ***AFTER*** the onDamage event, so there is no
# 	need to care about it in this trigger."
# 
#	NOTE: that armor resistance needs to be applied before
#	on_damage
	var crit_count: int = calc_attack_multicrit(0, 0, 0)
	var crit_mod: float = get_prop_atk_crit_damage()

	for _i in range(crit_count):
		damage_mod_list.append(crit_mod)

#	NOTE: clamp at 0.0 to prevent damage from turning
#	negative
	for damage_mod in damage_mod_list:
		damage *= damage_mod

	damage = max(0.0, damage)

	return damage


func _get_next_bounce_target(prev_target: Mob) -> Mob:
	var attack_range: float = get_attack_range()
	var mob_list: Array = Utils.over_units_in_range_of_caster(prev_target, TargetType.new(TargetType.UnitType.MOBS), attack_range)

	Utils.sort_unit_list_by_distance(mob_list, prev_target.position)

	if !mob_list.is_empty():
		var next_target = mob_list[0]

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
	var mob: Mob = target as Mob

	var damage: float = _get_damage_to_mob(mob)
	
	super._do_damage(target, damage, true)


func _on_projectile_target_hit_splash(projectile: Projectile):
	var target: Unit = projectile.get_target()
	var mob: Mob = target as Mob

	if _splash_map.is_empty():
		return

	var damage: float = _get_damage_to_mob(mob)

	super._do_damage(target, damage, true)

	var splash_target: Unit = target
	var splash_pos: Vector2 = splash_target.position

#	Process splash ranges from closest to furthers,
#	so that strongest damage is applied
	var splash_range_list: Array = _splash_map.keys()
	splash_range_list.sort()

	var splash_range_max: float = splash_range_list.back()

	var mob_list: Array = Utils.over_units_in_range_of_caster(splash_target, TargetType.new(TargetType.UnitType.MOBS), splash_range_max)

	for neighbor in mob_list:
		var distance: float = Utils.vector_isometric_distance_to(splash_pos, neighbor.position)

		for splash_range in splash_range_list:
			var mob_is_in_range: bool = distance < splash_range

			if mob_is_in_range:
				var splash_damage_ratio: float = _splash_map[splash_range]
				var splash_damage: float = damage * splash_damage_ratio
				_do_damage(neighbor, splash_damage, true)

				break


func _on_projectile_target_hit_bounce(projectile: Projectile):
	var target: Unit = projectile.get_target()
	var mob: Mob = target as Mob

	var damage: float = _get_damage_to_mob(mob)

	projectile.user_real = damage
	projectile.user_int = _bounce_count_max

	_on_projectile_bounce_in_progress(projectile)


func _on_projectile_bounce_in_progress(projectile: Projectile):
	var current_target: Unit = projectile.get_target()
	var current_damage: float = projectile.user_real
	var current_bounce_count: int = projectile.user_int

	super._do_damage(current_target, current_damage, true)

# 	Launch projectile for next bounce, if bounce isn't over
	var bounce_end: bool = current_bounce_count == 0

	if bounce_end:
		return

	var next_damage: float = current_damage * (1.0 - _bounce_damage_multiplier)
	var next_bounce_count: int = current_bounce_count - 1

	var next_target: Mob = _get_next_bounce_target(current_target)

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

func get_overall_base_damage():
	return (get_base_damage() + get_base_damage_bonus()) * (1 + get_base_damage_bonus_percent())

func get_overall_damage():
	return (get_overall_base_damage() + get_damage_add()) * (1 + get_damage_add_percent())

# How much damage the tower deals with its attack per second on average (not counting in any crits). 
func get_overall_dps():
	return get_overall_damage() / get_overall_cooldown()

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
