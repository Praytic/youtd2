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

enum TowerProperty {
	ATTACK_RANGE,
	ATTACK_SPEED,
	ATTACK_DAMAGE_MIN,
	ATTACK_DAMAGE_MAX,

#	These properties shouldn't be defined directly. Use a
#	Modifier.
	ATTACK_CRIT_CHANCE,
	ATTACK_CRIT_DAMAGE,
	MULTICRIT_COUNT,
	ATTACK_MISS_CHANCE,

	DMG_TO_MASS,
	DMG_TO_NORMAL,
	DMG_TO_CHAMPION,
	DMG_TO_BOSS,
	DMG_TO_AIR,

	DMG_TO_UNDEAD,
	DMG_TO_MAGIC,
	DMG_TO_NATURE,
	DMG_TO_ORC,
	DMG_TO_HUMANOID,

# 	TODO: implement
	ITEM_CHANCE_ON_KILL,
	ITEM_QUALITY_ON_KILL,
	EXP_RECEIVED,
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

export(AudioStreamMP3) var attack_sound

const _tower_mod_to_property_map: Dictionary = {
	Modification.Type.MOD_ATTACK_CRIT_CHANCE: TowerProperty.ATTACK_CRIT_CHANCE, 
	Modification.Type.MOD_MULTICRIT_COUNT: TowerProperty.MULTICRIT_COUNT, 

	Modification.Type.MOD_DMG_TO_MASS: TowerProperty.DMG_TO_MASS, 
	Modification.Type.MOD_DMG_TO_NORMAL: TowerProperty.DMG_TO_NORMAL, 
	Modification.Type.MOD_DMG_TO_CHAMPION: TowerProperty.DMG_TO_CHAMPION, 
	Modification.Type.MOD_DMG_TO_BOSS: TowerProperty.DMG_TO_BOSS, 
	Modification.Type.MOD_DMG_TO_AIR: TowerProperty.DMG_TO_AIR, 

	Modification.Type.MOD_DMG_TO_UNDEAD: TowerProperty.DMG_TO_UNDEAD, 
	Modification.Type.MOD_DMG_TO_MAGIC: TowerProperty.DMG_TO_MAGIC, 
	Modification.Type.MOD_DMG_TO_NATURE: TowerProperty.DMG_TO_NATURE, 
	Modification.Type.MOD_DMG_TO_ORC: TowerProperty.DMG_TO_ORC, 
	Modification.Type.MOD_DMG_TO_HUMANOID: TowerProperty.DMG_TO_HUMANOID, 

	Modification.Type.MOD_ITEM_CHANCE_ON_KILL: TowerProperty.ITEM_CHANCE_ON_KILL, 
	Modification.Type.MOD_ITEM_QUALITY_ON_KILL: TowerProperty.ITEM_QUALITY_ON_KILL, 

	Modification.Type.MOD_EXP_RECEIVED: TowerProperty.EXP_RECEIVED, 

	Modification.Type.MOD_ATTACK_SPEED: TowerProperty.ATTACK_SPEED,
}

const _mob_type_to_property_map: Dictionary = {
	Mob.Type.UNDEAD: TowerProperty.DMG_TO_MASS,
	Mob.Type.MAGIC: TowerProperty.DMG_TO_MAGIC,
	Mob.Type.NATURE: TowerProperty.DMG_TO_NATURE,
	Mob.Type.ORC: TowerProperty.DMG_TO_ORC,
	Mob.Type.HUMANOID: TowerProperty.DMG_TO_HUMANOID,
}

const _mob_size_to_property_map: Dictionary = {
	Mob.Size.MASS: TowerProperty.DMG_TO_MASS,
	Mob.Size.NORMAL: TowerProperty.DMG_TO_NORMAL,
	Mob.Size.CHAMPION: TowerProperty.DMG_TO_CHAMPION,
	Mob.Size.BOSS: TowerProperty.DMG_TO_BOSS,
	Mob.Size.AIR: TowerProperty.DMG_TO_AIR,
}

const _csv_property_to_tower_property_map: Dictionary = {
	CsvProperty.ATTACK_RANGE: TowerProperty.ATTACK_RANGE,
	CsvProperty.ATTACK_DAMAGE_MIN: TowerProperty.ATTACK_DAMAGE_MIN,
	CsvProperty.ATTACK_DAMAGE_MAX: TowerProperty.ATTACK_DAMAGE_MAX,
}


const ATTACK_CD_MIN: float = 0.2

var _id: int = 0
var _stats: Dictionary
var _attack_autocast = null
var _projectile_scene: PackedScene = preload("res://Scenes/Projectile.tscn")
var _tower_properties: Dictionary = {
	TowerProperty.ATTACK_RANGE: 0.0,
	TowerProperty.ATTACK_SPEED: 1.0,
	TowerProperty.ATTACK_DAMAGE_MIN: 0,
	TowerProperty.ATTACK_DAMAGE_MAX: 0,
	TowerProperty.ATTACK_CRIT_CHANCE: 0.0,
# NOTE: crit damage default means the default bonus damage
# from crits, so default value of 1.0 means +100%
	TowerProperty.ATTACK_CRIT_DAMAGE: 1.0,
	TowerProperty.MULTICRIT_COUNT: 1.0,
	TowerProperty.ATTACK_MISS_CHANCE: 0.0,

	TowerProperty.DMG_TO_MASS: 0.0,
	TowerProperty.DMG_TO_NORMAL: 0.0,
	TowerProperty.DMG_TO_CHAMPION: 0.0,
	TowerProperty.DMG_TO_BOSS: 0.0,
	TowerProperty.DMG_TO_AIR: 0.0,

	TowerProperty.DMG_TO_UNDEAD: 0.0,
	TowerProperty.DMG_TO_MAGIC: 0.0,
	TowerProperty.DMG_TO_NATURE: 0.0,
	TowerProperty.DMG_TO_ORC: 0.0,
	TowerProperty.DMG_TO_HUMANOID: 0.0,

# 	TODO: these should probably default to something
# 	non-zero
	TowerProperty.ITEM_CHANCE_ON_KILL: 0.0,
	TowerProperty.ITEM_QUALITY_ON_KILL: 0.0,
}


onready var _game_scene: Node = get_tree().get_root().get_node("GameScene")
onready var _attack_sound: AudioStreamPlayer2D = AudioStreamPlayer2D.new()
onready var _range_indicator: RangeIndicator = $RangeIndicator


#########################
### Code starts here  ###
#########################

func _ready():
	_is_tower = true

# 	Load some default property values from csv
	for csv_property in _csv_property_to_tower_property_map.keys():
		var tower_property: int = _csv_property_to_tower_property_map[csv_property]
		var value: float = get_csv_property(csv_property).to_float()
		_tower_properties[tower_property] = value

# 	Load stats for current tier. Stats are defined in
# 	subclass.
	var tier: int = get_tier()
	var tier_stats: Dictionary = _get_tier_stats()
	_stats = tier_stats[tier]

	_attack_sound.set_stream(attack_sound)
	add_child(_attack_sound)

# 	NOTE: settings for attack autocast will be fully loaded
# 	_apply_properties_to_scene_children() is called
	var attack_autocast_data = Autocast.Data.new()
	attack_autocast_data.caster_art = ""
	attack_autocast_data.num_buffs_before_idle = 0
	attack_autocast_data.autocast_type = Autocast.Type.AC_TYPE_OFFENSIVE_UNIT
	attack_autocast_data.the_range = 0
	attack_autocast_data.target_self = false
	attack_autocast_data.target_art = ""
	attack_autocast_data.cooldown = 1
	attack_autocast_data.is_extended = true
	attack_autocast_data.mana_cost = 0
	attack_autocast_data.buff_type = 0
	attack_autocast_data.target_type = TargetType.new(TargetType.UnitType.MOBS)
	attack_autocast_data.auto_range = 0

	var attack_buff = TriggersBuff.new()
	_attack_autocast = attack_buff.add_autocast(attack_autocast_data, self, "_on_attack_autocast")
	attack_buff.apply_to_unit_permanent(self, self, 0)

	_apply_properties_to_scene_children()


#########################
###       Public      ###
#########################

# TODO: implement. Also move to the "owner" class that is
# returned by get_owner(), when owner gets implemented. Find
# out what mystery bools are for.
func give_gold(_amount: int, _unit: Unit, _mystery_bool_1: bool, _mystery_bool_2: bool):
	pass


func change_level(new_level: int):
	set_level(new_level)

# 	NOTE: properties could've change due to level up so
# 	re-apply them
	_apply_properties_to_scene_children()

func enable_default_sprite():
	$DefaultSprite.show()

#########################
###      Private      ###
#########################


# NOTE: if your tower needs to attack more than 1 target,
# call this f-n once in _ready() method of subclass
func _set_target_count(count: int):
	_attack_autocast._target_count_max = count


func _on_attack_autocast(event: Event):
	var target = event.get_target()

	var projectile = _projectile_scene.instance()
	projectile.init(target, global_position)
	projectile.connect("reached_mob", self, "_on_projectile_reached_mob")
	_game_scene.call_deferred("add_child", projectile)

	._do_attack(event)

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
	._select()

	_range_indicator.show()


func _unselect():
	._unselect()

	_range_indicator.hide()


func _apply_properties_to_scene_children():
	var cast_range: float = _tower_properties[TowerProperty.ATTACK_RANGE]
	var attack_cooldown: float = get_overall_cooldown()

	_attack_autocast.update_data(cast_range, attack_cooldown)
	_range_indicator.set_radius(cast_range)


# NOTE: returns random damage within range without any mods applied
func _get_rand_damage_base() -> float:
	var damage_min: float = _tower_properties[TowerProperty.ATTACK_DAMAGE_MIN]
	var damage_max: float = _tower_properties[TowerProperty.ATTACK_DAMAGE_MAX]
	var damage: float = rand_range(damage_min, damage_max)

	return damage


func _get_base_properties() -> Dictionary:
	return {}


func _modify_property_subclass(modification_type: int, modification_value: float, modify_direction: int):
	_modify_property_general(_tower_properties, _tower_mod_to_property_map, modification_type, modification_value, modify_direction)

	_apply_properties_to_scene_children()


func _get_crit_count() -> int:
	var crit_count: int = 0

	var multicrit_count: int = int(max(0, _tower_properties[TowerProperty.MULTICRIT_COUNT]))

	for _i in range(multicrit_count):
		var attack_crit_chance: float = _tower_properties[TowerProperty.ATTACK_CRIT_CHANCE]
		var is_critical: bool = Utils.rand_chance(attack_crit_chance)

		if is_critical:
			crit_count += 1
		else:
			break

	return crit_count


func _get_damage_mod_for_mob_type(mob: Mob) -> float:
	var mob_type: int = mob.get_type()
	var property: int = _mob_type_to_property_map[mob_type]
	var damage_mod: float = _tower_properties[property]

	return damage_mod


func _get_damage_mod_for_mob_size(mob: Mob) -> float:
	var mob_size: int = mob.get_size()
	var property: int = _mob_size_to_property_map[mob_size]
	var damage_mod: float = _tower_properties[property]

	return damage_mod


func _get_damage_to_mob(mob: Mob, damage_base: float) -> float:
	var damage: float = damage_base
	
	var damage_mod_list: Array = [
		_get_damage_mod_for_mob_size(mob),
		_get_damage_mod_for_mob_type(mob),
	]

# 	NOTE: crit count can go above 1 because of the multicrit
# 	property
	var crit_count: int = _get_crit_count()
	var crit_mod: float = _tower_properties[TowerProperty.ATTACK_CRIT_DAMAGE]

	for _i in range(crit_count):
		damage_mod_list.append(crit_mod)

#	NOTE: clamp at 0.0 to prevent damage from turning
#	negative
	for damage_mod in damage_mod_list:
		damage *= max(0.0, (1.0 + damage_mod))

	return damage


#########################
###     Callbacks     ###
#########################


func _on_projectile_reached_mob(mob: Mob):
	var attack_miss_chance: float = _tower_properties[TowerProperty.ATTACK_MISS_CHANCE]
	var is_miss: bool = Utils.rand_chance(attack_miss_chance)

	if is_miss:
		return

	var damage_base: float = _get_rand_damage_base()
	var damage: float = _get_damage_to_mob(mob, damage_base)
	
	._do_damage(mob, damage, true)


#########################
### Setters / Getters ###
#########################

func get_name() -> String:
	return get_csv_property(CsvProperty.NAME)


# NOTE: this must be called once after the tower is created
# but before it's added to game scene
func set_id(id: int):
	_id = id


func get_id() -> int:
	return _id


func get_tier() -> int:
	return get_csv_property(CsvProperty.TIER).to_int()


func get_element() -> int:
	var element_string: String = get_csv_property(CsvProperty.ELEMENT)
	var element: int = Element.get(element_string.to_upper())

	return element

func get_icon_atlas_num() -> int:
	return get_csv_property(CsvProperty.ICON_ATLAS_NUM).to_int()

func get_base_attack_speed() -> float:
	return _tower_properties[TowerProperty.ATTACK_SPEED]


func get_base_cooldown() -> float:
	return get_csv_property(CsvProperty.ATTACK_CD).to_float()


func get_overall_cooldown() -> float:
	var attack_cooldown: float = get_base_cooldown()
	var attack_speed: float = get_base_attack_speed()
	var overall_cooldown: float = attack_cooldown * attack_speed
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
# get_owner()
func get_owner():
	return self


func get_csv_property(csv_property: int) -> String:
	var properties: Dictionary = Properties.get_tower_csv_properties_by_id(_id)
	var value: String = properties[csv_property]

	return value

func get_damage_min():
	return get_csv_property(CsvProperty.ATTACK_DAMAGE_MIN).to_int()


func get_damage_max():
	return get_csv_property(CsvProperty.ATTACK_DAMAGE_MAX).to_int()
