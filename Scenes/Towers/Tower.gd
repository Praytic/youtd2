class_name Tower
extends Building


# Tower attacks by periodically firing projectiles at mobs
# that are in range.


signal upgraded


enum Property {
#	Properties below should be defined in the .csv file and
# 	the integer values must match the columns in csv file.
	FILENAME = 0,
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

	CSV_COLUMN_COUNT = 17,

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

	DMG_TO_UNDEAD,
	DMG_TO_MAGIC,
	DMG_TO_NATURE,
	DMG_TO_ORC,
	DMG_TO_HUMANOID,
}

export(int) var id
export(int) var next_tier_id
export(AudioStreamMP3) var attack_sound

# Mapping of modification type to the tower property that it
# modifies.
const _modification_type_to_property_map: Dictionary = {
	Modification.Type.MOD_ATTACK_CRIT_CHANCE: Property.ATTACK_CRIT_CHANCE, 
	Modification.Type.MOD_MULTICRIT_COUNT: Property.MULTICRIT_COUNT, 

	Modification.Type.MOD_DMG_TO_MASS: Property.DMG_TO_MASS, 
	Modification.Type.MOD_DMG_TO_NORMAL: Property.DMG_TO_NORMAL, 
	Modification.Type.MOD_DMG_TO_CHAMPION: Property.DMG_TO_CHAMPION, 
	Modification.Type.MOD_DMG_TO_BOSS: Property.DMG_TO_BOSS, 

	Modification.Type.MOD_DMG_TO_UNDEAD: Property.DMG_TO_UNDEAD, 
	Modification.Type.MOD_DMG_TO_MAGIC: Property.DMG_TO_MAGIC, 
	Modification.Type.MOD_DMG_TO_NATURE: Property.DMG_TO_NATURE, 
	Modification.Type.MOD_DMG_TO_ORC: Property.DMG_TO_ORC, 
	Modification.Type.MOD_DMG_TO_HUMANOID: Property.DMG_TO_HUMANOID, 
}

const _mob_type_to_property_map: Dictionary = {
	Mob.Type.UNDEAD: Property.DMG_TO_MASS,
	Mob.Type.MAGIC: Property.DMG_TO_MAGIC,
	Mob.Type.NATURE: Property.DMG_TO_NATURE,
	Mob.Type.ORC: Property.DMG_TO_ORC,
	Mob.Type.HUMANOID: Property.DMG_TO_HUMANOID,
}

const _mob_size_to_property_map: Dictionary = {
	Mob.Size.MASS: Property.DMG_TO_MASS,
	Mob.Size.NORMAL: Property.DMG_TO_NORMAL,
	Mob.Size.CHAMPION: Property.DMG_TO_CHAMPION,
	Mob.Size.BOSS: Property.DMG_TO_BOSS,
}

var _target_mob: Mob = null
var _aoe_scene: PackedScene = preload("res://Scenes/Towers/AreaOfEffect.tscn")
var _projectile_scene: PackedScene = preload("res://Scenes/Projectile.tscn")
var _properties: Dictionary = {
	Property.ID: 0,
	Property.NAME: "unknown",
	Property.FAMILY_ID: 0,
	Property.AUTHOR: "unknown",
	Property.RARITY: "unknown",
	Property.ELEMENT: "unknown",
	Property.ATTACK_TYPE: "unknown",
	Property.COST: 0,
	Property.DESCRIPTION: "unknown",

	Property.ATTACK_RANGE: 0.0,
	Property.ATTACK_CD: 0.0,
	Property.ATTACK_DAMAGE_MIN: 0,
	Property.ATTACK_DAMAGE_MAX: 0,
	Property.ATTACK_CRIT_CHANCE: 0.0,
# NOTE: crit damage default means the default bonus damage
# from crits, so default value of 1.0 means +100%
	Property.ATTACK_CRIT_DAMAGE: 1.0,
	Property.MULTICRIT_COUNT: 1.0,
	Property.ATTACK_MISS_CHANCE: 0.0,

	Property.DMG_TO_MASS: 0.0,
	Property.DMG_TO_NORMAL: 0.0,
	Property.DMG_TO_CHAMPION: 0.0,
	Property.DMG_TO_BOSS: 0.0,

	Property.DMG_TO_UNDEAD: 0.0,
	Property.DMG_TO_MAGIC: 0.0,
	Property.DMG_TO_NATURE: 0.0,
	Property.DMG_TO_ORC: 0.0,
	Property.DMG_TO_HUMANOID: 0.0,
}


onready var _game_scene: Node = get_tree().get_root().get_node("GameScene")
onready var _attack_cooldown_timer: Timer = $AttackCooldownTimer
onready var _targeting_area: Area2D = $TargetingArea
onready var _attack_sound: AudioStreamPlayer2D = AudioStreamPlayer2D.new()


func _ready():
	add_child(_aoe_scene.instance(), true)

#	NOTE: Load properties from csv first, then load from
#	subclass script to add additional values or override csv
#	values
	var script: Reference = get_script()
	var script_file: String = script.get_path().get_file()
	var script_filename: String = script_file.trim_suffix(".gd")

	var csv_properties: Dictionary = Properties.get_csv_properties_by_filename(script_filename)

	for property in csv_properties.keys():
		_properties[property] = csv_properties[property]

# 	NOTE: tower properties may omit keys for convenience, so
# 	need to iterate over keys in properties to avoid
# 	triggering "invalid key" error
	
	# Most properties should be defined in the .csv file.
	var base_properties: Dictionary = _get_base_properties()

	for property in base_properties.keys():
		_properties[property] = base_properties[property]

	var specials_modifier: Modifier = _get_specials_modifier()

	if specials_modifier != null:
		add_modifier(specials_modifier)

	_apply_properties_to_scene_children()

	$AreaOfEffect.hide()

	_attack_cooldown_timer.connect("timeout", self, "_on_AttackCooldownTimer_timeout")
	_attack_cooldown_timer.one_shot = true

	_targeting_area.connect("body_entered", self, "_on_TargetingArea_body_entered")
	_targeting_area.connect("body_exited", self, "_on_TargetingArea_body_exited")

	_attack_sound.set_stream(attack_sound)
	add_child(_attack_sound)


static func convert_csv_string_to_property_value(csv_string: String, property: int):
	if property > Property.CSV_COLUMN_COUNT:
		return csv_string

	match property:
		Property.FILENAME: return csv_string
		Property.NAME: return csv_string
		Property.ID: return csv_string.to_int()
		Property.FAMILY_ID: return csv_string.to_int()
		Property.AUTHOR: return csv_string
		Property.RARITY: return csv_string
		Property.ELEMENT: return csv_string
		Property.ATTACK_TYPE: return csv_string
		Property.ATTACK_RANGE: return csv_string.to_float()
		Property.ATTACK_CD: return csv_string.to_float()
		Property.ATTACK_DAMAGE_MIN : return csv_string.to_float()
		Property.ATTACK_DAMAGE_MAX : return csv_string.to_float()
		Property.COST : return csv_string.to_int()
		Property.DESCRIPTION : return csv_string
		Property.TIER : return csv_string.to_int()
		Property.REQUIRED_ELEMENT_LEVEL : return csv_string.to_int()
		Property.REQUIRED_WAVE_LEVEL : return csv_string.to_int()
		_:
			print_debug("Unhandled property in Tower.convert_csv_string_to_property_value(): ", property)

			return csv_string


func get_name() -> String:
	return _properties[Property.NAME]


func get_id() -> int:
	return _properties[Property.ID]


func build_init():
	.build_init()
	$AreaOfEffect.show()


func upgrade() -> PackedScene:
	var next_tier_tower = TowerManager.get_tower(next_tier_id)
	emit_signal("upgraded")
	return next_tier_tower


func change_level(new_level: int):
	set_level(new_level)

# 	NOTE: properties could've change due to level up so
# 	re-apply them
	_apply_properties_to_scene_children()


func _on_AttackCooldownTimer_timeout():
	if !_have_target():
		_target_mob = _find_new_target()
		
	_try_to_attack()


func _on_TargetingArea_body_entered(body):
	if _have_target():
		return
		
	if body is Mob:
#		New target acquired
		_target_mob = body
		_try_to_attack()


func _on_TargetingArea_body_exited(body):
	if body == _target_mob:
#		Target has gone out of range
		_target_mob = _find_new_target()
		_try_to_attack()


# Find a target that is currently in range
# TODO: prioritizing closest mob here, but maybe change behavior
# based on tower properties or other game design considerations
func _find_new_target() -> Mob:
	var body_list: Array = _targeting_area.get_overlapping_bodies()
	var closest_mob: Mob = null
	var distance_min: float = 1000000.0
	
	for body in body_list:
		if body is Mob:
			var mob: Mob = body
			var distance: float = (mob.position - self.position).length()
			
			if distance < distance_min:
				closest_mob = mob
				distance_min = distance
	
	return closest_mob


func _try_to_attack() -> bool:
	if building_in_progress:
		return false

	if !_have_target():
		return false
	
	var attack_on_cooldown: bool = _attack_cooldown_timer.time_left > 0
	
	if attack_on_cooldown:
		return false

	var event: Event = Event.new()
	event.target = _target_mob

	._do_attack(_target_mob)

	var projectile = _projectile_scene.instance()
	projectile.init(_target_mob, global_position)
	projectile.connect("reached_mob", self, "_on_projectile_reached_mob")
	_game_scene.call_deferred("add_child", projectile)

	_attack_sound.play()
	
	_attack_cooldown_timer.start()
	return true


func _have_target() -> bool:
#	NOTE: have to check validity because mobs can get killed by other towers
#	which free's them and makes them invalid
	return _target_mob != null and is_instance_valid(_target_mob)


func _select():
	._select()
	print_debug("Tower %s has been selected." % id)


func _unselect():
	._unselect()
	print_debug("Tower %s has been unselected." % id)


func _on_projectile_reached_mob(mob: Mob):
	var attack_miss_chance: float = _properties[Property.ATTACK_MISS_CHANCE]
	var is_miss: bool = Utils.rand_chance(attack_miss_chance)

	if is_miss:
		return

	var damage_base: float = _get_rand_damage_base()
	var damage: float = _get_damage_to_mob(mob, damage_base)
	
	._do_damage(mob, damage, true)


func _apply_properties_to_scene_children():
	var cast_range: float = _properties[Property.ATTACK_RANGE]
	Utils.circle_shape_set_radius($TargetingArea/CollisionShape2D, cast_range)
	$AreaOfEffect.set_radius(cast_range)

	var attack_cd: float = _properties[Property.ATTACK_CD]
	_attack_cooldown_timer.wait_time = attack_cd


# NOTE: returns random damage within range without any mods applied
func _get_rand_damage_base() -> float:
	var damage_min: float = _properties[Property.ATTACK_DAMAGE_MIN]
	var damage_max: float = _properties[Property.ATTACK_DAMAGE_MAX]
	var damage: float = rand_range(damage_min, damage_max)

	return damage


func _get_base_properties() -> Dictionary:
	return {}


func _get_specials_modifier() -> Modifier:
	return null


func _modify_property(modification_type: int, modification_value: float):
	var can_modify: bool = _modification_type_to_property_map.has(modification_type)

	if can_modify:
		var property: int = _modification_type_to_property_map[modification_type]
		var current_value: float = _properties[property]
		var new_value: float = current_value + modification_value
		_properties[property] = new_value


func _get_crit_count() -> int:
	var crit_count: int = 0

	var multicrit_count: int = int(max(0, _properties[Property.MULTICRIT_COUNT]))

	for _i in range(multicrit_count):
		var attack_crit_chance: float = _properties[Property.ATTACK_CRIT_CHANCE]
		var is_critical: bool = Utils.rand_chance(attack_crit_chance)

		if is_critical:
			crit_count += 1
		else:
			break

	return crit_count


func _get_damage_mod_for_mob_type(mob: Mob) -> float:
	var mob_type: int = mob.get_type()
	var property: int = _mob_type_to_property_map[mob_type]
	var damage_mod: float = _properties[property]

	return damage_mod


func _get_damage_mod_for_mob_size(mob: Mob) -> float:
	var mob_size: int = mob.get_size()
	var property: int = _mob_size_to_property_map[mob_size]
	var damage_mod: float = _properties[property]

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
	var crit_mod: float = _properties[Property.ATTACK_CRIT_DAMAGE]

	for _i in range(crit_count):
		damage_mod_list.append(crit_mod)

#	NOTE: clamp at 0.0 to prevent damage from turning
#	negative
	for damage_mod in damage_mod_list:
		damage *= max(0.0, (1.0 + damage_mod))

	return damage
