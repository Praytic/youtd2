class_name Unit
extends KinematicBody2D

# Unit is a base class for Towers and Mobs. Keeps track of
# buffs and modifications. Emits signals for events which are used by buffs.

# NOTE: can't use static typing for Buff because of cyclic
# dependency

signal level_up
signal attack(event)
signal attacked(event)
signal damage(event)
signal damaged(event)
signal kill(event)
signal death(event)


# TODO: implement these mod types
# MOD_ARMOR
# MOD_ARMOR_PERC
# MOD_EXP_GRANTED
# MOD_ITEM_CHANCE_ON_KILL
# MOD_ITEM_QUALITY_ON_KILL
# MOD_EXP_RECEIVED
# MOD_SPELL_CRIT_CHANCE
# MOD_ATK_DAMAGE_RECEIVED
# MOD_ATK_DAMAGE_RECEIVED
# MOD_DAMAGE_BASE
# MOD_DAMAGE_BASE_PERC
# MOD_DAMAGE_ADD
# MOD_DAMAGE_ADD_PERC
# MOD_DPS_ADD
# MOD_HP
# MOD_HP_PERC
# MOD_HP_REGEN
# MOD_HP_REGEN_PERC
# MOD_MANA
# MOD_MANA_PERC
# MOD_MANA_REGEN
# MOD_MANA_REGEN_PERC
# MOD_DMG_FROM_ASTRAL
# MOD_DMG_FROM_DARKNESS
# MOD_DMG_FROM_NATURE
# MOD_DMG_FROM_FIRE
# MOD_DMG_FROM_ICE
# MOD_DMG_FROM_STORM
# MOD_DMG_FROM_IRON

enum ModType {
	MOD_ARMOR,
	MOD_ARMOR_PERC,
	MOD_EXP_GRANTED,
	MOD_EXP_RECEIVED,
	MOD_SPELL_DAMAGE_RECEIVED,
	MOD_SPELL_DAMAGE_DEALT,
	MOD_SPELL_CRIT_CHANCE,
	MOD_BOUNTY_GRANTED,
	MOD_BOUNTY_RECEIVED,
	MOD_ATK_CRIT_CHANCE,
	MOD_ATK_CRIT_DAMAGE,
	MOD_ATK_DAMAGE_RECEIVED,
	MOD_ATTACKSPEED,
	MOD_MULTICRIT_COUNT,
	MOD_ITEM_CHANCE_ON_KILL,
	MOD_ITEM_QUALITY_ON_KILL,
	MOD_BUFF_DURATION,
	MOD_DEBUFF_DURATION,
	MOD_TRIGGER_CHANCES,
	MOD_MOVESPEED,
	MOD_MOVESPEED_ABSOLUTE,
	MOD_DAMAGE_BASE,
	MOD_DAMAGE_BASE_PERC,
	MOD_DAMAGE_ADD,
	MOD_DAMAGE_ADD_PERC,
	MOD_DPS_ADD,
	MOD_HP,
	MOD_HP_PERC,
	MOD_HP_REGEN,
	MOD_HP_REGEN_PERC,
	MOD_MANA,
	MOD_MANA_PERC,
	MOD_MANA_REGEN,
	MOD_MANA_REGEN_PERC,

	MOD_DMG_TO_MASS,
	MOD_DMG_TO_NORMAL,
	MOD_DMG_TO_CHAMPION,
	MOD_DMG_TO_BOSS,
	MOD_DMG_TO_AIR,

	MOD_DMG_TO_UNDEAD,
	MOD_DMG_TO_MAGIC,
	MOD_DMG_TO_NATURE,
	MOD_DMG_TO_ORC,
	MOD_DMG_TO_HUMANOID,

	MOD_DMG_FROM_ASTRAL,
	MOD_DMG_FROM_DARKNESS,
	MOD_DMG_FROM_NATURE,
	MOD_DMG_FROM_FIRE,
	MOD_DMG_FROM_ICE,
	MOD_DMG_FROM_STORM,
	MOD_DMG_FROM_IRON,
}

# NOTE: order is important to be able to compare
enum MobSize {
	MASS,
	NORMAL,
	AIR,
	CHAMPION,
	BOSS,
	CHALLENGE,
}

enum MobType {
	UNDEAD,
	MAGIC,
	NATURE,
	ORC,
	HUMANOID,
}


# HACK: to fix cyclic dependency between Tower<->TargetType
var _is_mob: bool = false
var _is_tower: bool = false

var user_int: int = 0
var user_int2: int = 0
var user_int3: int = 0
var user_real: float = 0.0
var user_real2: float = 0.0
var user_real3: float = 0.0

var _is_dead: bool = false
var _level: int = 1 setget set_level, get_level
var _buff_map: Dictionary
var _direct_modifier_list: Array
var _health: float = 0.0
var _mod_value_map: Dictionary = {}


#########################
### Code starts here  ###
#########################

func _init():
	for mod_type in ModType.values():
		_mod_value_map[mod_type] = 0.0
	_mod_value_map[ModType.MOD_ATK_CRIT_CHANCE] = 0.01
	_mod_value_map[ModType.MOD_ATK_CRIT_DAMAGE] = 0.5


#########################
###       Public      ###
#########################

func calc_chance(chance_base: float) -> bool:
	var chance_mod: float = _mod_value_map[ModType.MOD_TRIGGER_CHANCES]
	var chance: float = chance_base + chance_mod
	var success: bool = Utils.rand_chance(chance)

	return success


# "Bad" chance is for events that decrease tower's
# perfomance, for example missing attack. Bad chances are
# unaffected by ModType.MOD_TRIGGER_CHANCES.
func calc_bad_chance(chance: float) -> bool:
	var success: bool = Utils.rand_chance(chance)

	return success


# TODO: implement, probably calculates total modifier from
# crit without multi-crit?
func calc_spell_crit_no_bonus() -> float:
	return 0.0


# TODO: implement
func calc_attack_multicrit(_mystery1: float, _mystery2: float, _mystery3: float) -> float:
	return 0.0


# TODO: implement _crit_mod.
func do_spell_damage(target: Unit, damage: float, _crit_mod: float):
	var dealt_mod: float = _mod_value_map[ModType.MOD_SPELL_DAMAGE_DEALT]
	var received_mod: float = target._mod_value_map[ModType.MOD_SPELL_DAMAGE_RECEIVED]
	var damage_total: float = damage * (1.0 + dealt_mod) * (1.0 + received_mod)
	_do_damage(target, damage_total, false)


# TODO: finish implementation. Need to implement crit, find
# out what myster float does. Also implement the difference
# between spell/attack damage
func do_attack_damage_aoe_unit(target: Unit, radius: float, damage: float, _crit: float, _mystery_float: float):
	var mob_list: Array = Utils.get_mob_list_in_range(target.position, radius)

	for mob in mob_list:
		mob._receive_damage(self, damage, false)


func do_spell_damage_aoe_unit(target: Unit, radius: float, damage: float, _crit: float, _mystery_float: float):
	var mob_list: Array = Utils.get_mob_list_in_range(target.position, radius)

	for mob in mob_list:
		mob._receive_damage(self, damage, false)

func kill_instantly(target: Unit):
	target._killed_by_unit(self, true)


func modify_property(mod_type: int, value: float, direction: int):
	var current_value: float = _mod_value_map[mod_type]
	var new_value: float = current_value + direction * value
	_mod_value_map[mod_type] = new_value

	_on_modify_property()


#########################
###      Private      ###
#########################

func _do_attack(attack_event: Event):
	emit_signal("attack", attack_event)

	var target = attack_event.get_target()
	target._receive_attack()


func _receive_attack():
	var attacked_event: Event = Event.new(self, 0, true)
	emit_signal("attacked", attacked_event)


# NOTE: this function should not be called in any event
# handlers or public Unit functions that can be called from
# event handlers because that can cause an infinite
# recursion of DAMAGE events causing infinite DAMAGE events.
func _do_damage(target: Unit, damage: float, is_main_target: bool):
	var damage_event: Event = Event.new(target, damage, is_main_target)
	emit_signal("damage", damage_event)

	target._receive_damage(self, damage_event.damage, is_main_target)


func _receive_damage(caster: Unit, damage: float, is_main_target: bool):
	var health_before_damage: float = _health

	_health -= damage

	var damaged_event: Event = Event.new(caster, damage, is_main_target)
	emit_signal("damaged", damaged_event)

	Utils.display_floating_text_x(String(int(damage)), self, 255, 0, 0, 0.0, 0.0, 1.0)

	var damage_killed_unit: bool = health_before_damage > 0 && _health <= 0

	if damage_killed_unit:
		_killed_by_unit(caster, is_main_target)

		return

# Called when unit killed by caster unit
func _killed_by_unit(caster: Unit, is_main_target: bool):
# 	NOTE: need to use explicit "is_dead" flag. Calling
# 	queue_free() makes is_instance_valid(unit) return false
# 	but that happens only at the end of the current frame.
# 	Other signals/slots might fire before that point and
# 	they need to know if the unit is dead to avoid
# 	processing it.
	_is_dead = true

	var death_event: Event = Event.new(self, 0, is_main_target)
	emit_signal("death", death_event)

	caster._accept_kill(self, is_main_target)

	queue_free()


# Called when unit kills target unit
func _accept_kill(target: Unit, is_main_target: bool):
# 	TODO: load bounty_base from somewhere
	var bounty_base: float = 10.0
	var granted_mod: float = target._mod_value_map[ModType.MOD_BOUNTY_GRANTED]
	var received_mod: float = _mod_value_map[ModType.MOD_BOUNTY_RECEIVED]
	var bounty: int = int(bounty_base * (1.0 + granted_mod) * (1.0 + received_mod))
	GoldManager.add_gold(bounty)

	var kill_event: Event = Event.new(target, 0, is_main_target)
	emit_signal("kill", kill_event)


# This is for internal use in Buff.gd only. For external
# use, call Buff.apply_to_unit().
func _add_buff_internal(buff):
	var buff_type: String = buff.get_type()
	_buff_map[buff_type] = buff
	buff.connect("removed", self, "_on_buff_removed", [buff])
	var buff_modifier: Modifier = buff.get_modifier()
	_apply_modifier(buff_modifier, buff.get_power(), 1)
	add_child(buff)


func _apply_modifier(modifier: Modifier, power: int, modify_direction: int):
	var modification_list: Array = modifier.get_modification_list()

	for modification in modification_list:
		var power_bonus: float = modification.level_add * (power - 1)
		var value: float = modification.value_base + power_bonus

		modify_property(modification.type, value, modify_direction)


#########################
###     Callbacks     ###
#########################

func _on_buff_removed(buff):
	var buff_modifier: Modifier = buff.get_modifier()
	_apply_modifier(buff_modifier, buff.get_power(), -1)

	var buff_type: String = buff.get_type()
	_buff_map.erase(buff_type)
	buff.queue_free()

func _on_modify_property():
	pass


#########################
### Setters / Getters ###
#########################

# TODO: implement
func is_immune() -> bool:
	return false

# Adds modifier directly to unit. Modifier will
# automatically scale with this unit's level. If you need to
# make a modifier that scales with another unit's level, use
# buffs.
func add_modifier(modifier: Modifier):
	_apply_modifier(modifier, _level, 1)
	_direct_modifier_list.append(modifier)


func remove_modifier(modifier: Modifier):
	if _direct_modifier_list.has(modifier):
		_apply_modifier(modifier, _level, -1)
		_direct_modifier_list.append(modifier)


func set_level(new_level: int):
	var old_level: int = _level
	_level = new_level

#	NOTE: apply level change to modifiers
	for modifier in _direct_modifier_list:
		_apply_modifier(modifier, old_level, -1)
		_apply_modifier(modifier, new_level, 1)

	emit_signal("level_up")


func is_dead() -> bool:
	return _is_dead


func is_mob() -> bool:
	return _is_mob


func is_tower() -> bool:
	return _is_tower


func get_x() -> float:
	return position.x


func get_y() -> float:
	return position.y


func get_buff_duration() -> float:
	return _mod_value_map[ModType.MOD_BUFF_DURATION]

func get_debuff_duration() -> float:
	return _mod_value_map[ModType.MOD_DEBUFF_DURATION]

func get_attack_crit_chance() -> float:
	return _mod_value_map[ModType.MOD_ATK_CRIT_CHANCE]

func get_attack_crit_damage() -> float:
	return _mod_value_map[ModType.MOD_ATK_CRIT_DAMAGE]

# TODO: implement
# Returns the value of the average damage multipler based on crit chance, crit damage
# and multicrit count of the tower
func get_crit_multiplier() -> float:
	return 1 + get_attack_crit_chance() * get_attack_crit_damage()

func get_bounty_ratio() -> float:
	return _mod_value_map[ModType.MOD_BOUNTY_RECEIVED]

func get_damage_to_air() -> float:
	return _mod_value_map[ModType.MOD_DMG_TO_AIR]

func get_damage_to_boss() -> float:
	return _mod_value_map[ModType.MOD_DMG_TO_BOSS]

func get_damage_to_mass() -> float:
	return _mod_value_map[ModType.MOD_DMG_TO_MASS]

func get_damage_to_normal() -> float:
	return _mod_value_map[ModType.MOD_DMG_TO_NORMAL]

func get_damage_to_champion() -> float:
	return _mod_value_map[ModType.MOD_DMG_TO_CHAMPION]

func get_damage_to_undead() -> float:
	return _mod_value_map[ModType.MOD_DMG_TO_UNDEAD]

func get_damage_to_humanoid() -> float:
	return _mod_value_map[ModType.MOD_DMG_TO_HUMANOID]

func get_damage_to_nature() -> float:
	return _mod_value_map[ModType.MOD_DMG_TO_NATURE]

func get_damage_to_magic() -> float:
	return _mod_value_map[ModType.MOD_DMG_TO_MAGIC]

func get_damage_to_orc() -> float:
	return _mod_value_map[ModType.MOD_DMG_TO_ORC]

func get_exp_ratio() -> float:
	return _mod_value_map[ModType.MOD_EXP_RECEIVED]

func get_item_drop_ratio() -> float:
	return _mod_value_map[ModType.MOD_ITEM_CHANCE_ON_KILL]

func get_item_quality_ratio() -> float:
	return _mod_value_map[ModType.MOD_ITEM_QUALITY_ON_KILL]

func get_trigger_chances() -> float:
	return _mod_value_map[ModType.MOD_TRIGGER_CHANCES]

func get_multicrit_count() -> int:
	return int(max(0, 1.0 + _mod_value_map[ModType.MOD_MULTICRIT_COUNT]))

func get_base_spell_damage() -> float:
	return _mod_value_map[ModType.MOD_SPELL_DAMAGE_DEALT]

# TODO: implement
func get_spell_crit_chance() -> float:
	return 0.0

# TODO: implement
func get_spell_crit_damage() -> float:
	return 0.0

# The Base Cooldown is divided by this value. Towers gain some attackspeed per level and items, 
# buffs and auras can grant attackspeed.
func get_base_attack_speed() -> float:
	return _mod_value_map[ModType.MOD_ATTACKSPEED]

func get_level() -> int:
	return _level

# TODO: implement
func is_invisible() -> bool:
	return false


func get_buff_of_type(type: String):
	var buff = _buff_map.get(type, null)

	return buff

# TODO: implement
func get_base_mana():
	return 0.0

# TODO: implement
func get_base_mana_bonus():
	return 0.0

# TODO: implement
func get_base_mana_bonus_percent():
	return 0.0

func get_overall_mana():
	return (get_base_mana() + get_base_mana_bonus()) * (1 + get_base_mana_bonus_percent())

# TODO: implement
func get_base_mana_regen():
	return 0.0

# TODO: implement
func get_base_mana_regen_bonus():
	return 0.0

# TODO: implement
func get_base_mana_regen_bonus_percent():
	return 0.0

func get_overall_mana_regen():
	return (get_base_mana_regen() + get_base_mana_regen_bonus()) * (1 + get_base_mana_regen_bonus_percent())
