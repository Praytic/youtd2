class_name Unit
extends CharacterBody2D

# Unit is a base class for Towers and Mobs. Keeps track of
# buffs and modifications. Emits signals for events which are used by buffs.

# NOTE: can't use static typing for Buff because of cyclic
# dependency

signal level_up
signal attack(event)
signal attacked(event)
signal dealt_damage(event)
signal damaged(event)
signal kill(event)
signal death(event)
signal became_invisible()
signal became_visible()

signal selected
signal unselected

# TODO: implement these mod types
# MOD_ARMOR
# MOD_ARMOR_PERC
# MOD_ITEM_CHANCE_ON_KILL
# MOD_ITEM_QUALITY_ON_KILL
# MOD_SPELL_CRIT_CHANCE
# MOD_DPS_ADD

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

enum MobCategory {
	UNDEAD,
	MAGIC,
	NATURE,
	ORC,
	HUMANOID,
}

var element_to_dmg_from_element_mod: Dictionary = {
	Tower.Element.ICE: ModType.MOD_DMG_FROM_ICE,
	Tower.Element.NATURE: ModType.MOD_DMG_FROM_NATURE,
	Tower.Element.FIRE: ModType.MOD_DMG_FROM_FIRE,
	Tower.Element.ASTRAL: ModType.MOD_DMG_FROM_ASTRAL,
	Tower.Element.DARKNESS: ModType.MOD_DMG_FROM_DARKNESS,
	Tower.Element.IRON: ModType.MOD_DMG_FROM_IRON,
	Tower.Element.STORM: ModType.MOD_DMG_FROM_STORM,
}

const MULTICRIT_DIMINISHING_CHANCE: float = 0.8
const INVISIBLE_MODULATE: Color = Color(1, 1, 1, 0.5)
# TODO: replace this placeholder constant with real value.
const EXP_PER_LEVEL: float = 100
const REGEN_PERIOD: float = 1.0


# HACK: to fix cyclic dependency between Tower<->TargetType
var _is_mob: bool = false
var _is_tower: bool = false
# TODO: Implement
#var _is_item_drop: bool = false

var user_int: int = 0
var user_int2: int = 0
var user_int3: int = 0
var user_real: float = 0.0
var user_real2: float = 0.0
var user_real3: float = 0.0

var _is_dead: bool = false
var _level: int = 1 : get = get_level, set = set_level
var _buff_map: Dictionary
var _direct_modifier_list: Array
var _base_health: float = 0.0
var _health: float = 0.0
var _base_health_regen: float = 1.0
var _mod_value_map: Dictionary = {}
var _invisible: bool = false
var _selection_size: int : get = get_selection_size
var _selected: bool = false : get = is_selected
var _experience: float = 0.0
var _base_mana: float = 0.0
var _mana: float = 0.0
var _base_mana_regen: float = 2.0

# This is the count of towers that are currently able to see
# this invisible mob. If there any towers that can see this
# mob, then it is considered to be visible to all towers.
# See Unit.is_invisible() f-n and MagicalSightBuff.
var _invisible_watcher_count: int = 0


#########################
### Code starts here  ###
#########################

func _init():
	for mod_type in ModType.values():
		_mod_value_map[mod_type] = 0.0
	_mod_value_map[ModType.MOD_ATK_CRIT_CHANCE] = 0.01
	_mod_value_map[ModType.MOD_ATK_CRIT_DAMAGE] = 1.5
	_mod_value_map[ModType.MOD_TRIGGER_CHANCES] = 1.0
	_mod_value_map[ModType.MOD_SPELL_DAMAGE_DEALT] = 1.0
	_mod_value_map[ModType.MOD_SPELL_DAMAGE_RECEIVED] = 1.0
	_mod_value_map[ModType.MOD_BOUNTY_GRANTED] = 1.0
	_mod_value_map[ModType.MOD_BOUNTY_RECEIVED] = 1.0
	_mod_value_map[ModType.MOD_EXP_GRANTED] = 1.0
	_mod_value_map[ModType.MOD_EXP_RECEIVED] = 1.0
	_mod_value_map[ModType.MOD_BUFF_DURATION] = 1.0
	_mod_value_map[ModType.MOD_DEBUFF_DURATION] = 1.0
	_mod_value_map[ModType.MOD_MOVESPEED] = 1.0
	_mod_value_map[ModType.MOD_MULTICRIT_COUNT] = 1.0
	_mod_value_map[ModType.MOD_ATK_DAMAGE_RECEIVED] = 1.0

	_mod_value_map[ModType.MOD_DAMAGE_BASE] = 0.0
	_mod_value_map[ModType.MOD_DAMAGE_BASE_PERC] = 0.0
	_mod_value_map[ModType.MOD_DAMAGE_ADD] = 0.0
	_mod_value_map[ModType.MOD_DAMAGE_ADD_PERC] = 0.0

	_mod_value_map[ModType.MOD_MANA] = 0.0
	_mod_value_map[ModType.MOD_MANA_PERC] = 0.0
	_mod_value_map[ModType.MOD_MANA_REGEN] = 0.0
	_mod_value_map[ModType.MOD_MANA_REGEN_PERC] = 0.0
	_mod_value_map[ModType.MOD_HP] = 0.0
	_mod_value_map[ModType.MOD_HP_PERC] = 0.0
	_mod_value_map[ModType.MOD_HP_REGEN] = 0.0
	_mod_value_map[ModType.MOD_HP_REGEN_PERC] = 0.0

	_mod_value_map[ModType.MOD_DMG_TO_MASS] = 1.0
	_mod_value_map[ModType.MOD_DMG_TO_NORMAL] = 1.0
	_mod_value_map[ModType.MOD_DMG_TO_CHAMPION] = 1.0
	_mod_value_map[ModType.MOD_DMG_TO_BOSS] = 1.0
	_mod_value_map[ModType.MOD_DMG_TO_AIR] = 1.0

	_mod_value_map[ModType.MOD_DMG_TO_UNDEAD] = 1.0
	_mod_value_map[ModType.MOD_DMG_TO_MAGIC] = 1.0
	_mod_value_map[ModType.MOD_DMG_TO_NATURE] = 1.0
	_mod_value_map[ModType.MOD_DMG_TO_ORC] = 1.0
	_mod_value_map[ModType.MOD_DMG_TO_HUMANOID] = 1.0

	_mod_value_map[ModType.MOD_DMG_FROM_ASTRAL] = 1.0
	_mod_value_map[ModType.MOD_DMG_FROM_DARKNESS] = 1.0
	_mod_value_map[ModType.MOD_DMG_FROM_NATURE] = 1.0
	_mod_value_map[ModType.MOD_DMG_FROM_FIRE] = 1.0
	_mod_value_map[ModType.MOD_DMG_FROM_ICE] = 1.0
	_mod_value_map[ModType.MOD_DMG_FROM_STORM] = 1.0
	_mod_value_map[ModType.MOD_DMG_FROM_IRON] = 1.0

func _ready():
	_update_invisible_modulate()
	var selection = Node2D.new()
	selection.name = "Selection"
	selection.hide()
	selection.set_script(load("res://Scenes/Selection.gd"))
	selection.z_index = -1
	add_child(selection)
	
	var regen_timer: Timer = Timer.new()
	regen_timer.one_shot = false
	regen_timer.wait_time = REGEN_PERIOD
	regen_timer.timeout.connect(_on_regen_timer_timeout)
	add_child(regen_timer)
	regen_timer.start()


func _unhandled_input(event):
	if event is InputEventMouseButton:
		if event.get_button_index() == MOUSE_BUTTON_LEFT or event.get_button_index() == MOUSE_BUTTON_RIGHT:
			var is_inside: bool = Geometry2D.is_point_in_polygon(
				$CollisionShape2D.get_local_mouse_position(), 
				$CollisionShape2D.polygon)
			if is_inside:
				_select()
			else:
				if _selected:
					_unselect()


#########################
###       Public      ###
#########################

func calc_chance(chance_base: float) -> bool:
	var mod_trigger_chances: float = get_prop_trigger_chances()
	var chance: float = chance_base * mod_trigger_chances
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


# Returns a randomly calculated multicrit count.
# 
# TODO: figure out what mystery float parameters are for. In
# all tower scripts seen so far they were just 0's.
func calc_attack_multicrit(_mystery1: float, _mystery2: float, _mystery3: float) -> int:
	var crit_count: int = 0
	var multicrit_count_max: int = get_prop_multicrit_count()
	var current_crit_chance: float = get_prop_atk_crit_chance()

	for _i in range(multicrit_count_max):
		var is_critical: bool = Utils.rand_chance(current_crit_chance)

		if is_critical:
			crit_count += 1

#			Decrease chance of each subsequent multicrit to
#			implement diminishing returns.
			current_crit_chance *= MULTICRIT_DIMINISHING_CHANCE
		else:
			break

	return crit_count


# TODO: are dealt and received mods multiplied or added?
# (1.2 * 0.7) = 0.84
# or
# (1.2 - 0.3) = 0.9
# Might also apply to do_attack_damage() and mods for each attack element.
# 
# TODO: implement _crit_mod.
func do_spell_damage(target: Unit, damage: float, _crit_mod: float):
	var dealt_mod: float = get_prop_spell_damage_dealt()
	var received_mod: float = target.get_prop_spell_damage_received()
	var damage_total: float = damage * dealt_mod * received_mod
	_do_damage(target, damage_total, false)


# TODO: implement _crit_mod. Example call:
# doAttackDamage(creep, 100, tower.calcAttackMulticrit(0, 0, 0))
func do_attack_damage(target: Unit, damage: float, _crit_mod: float):
	var dealt_mod: float = get_prop_spell_damage_dealt()
	var received_mod: float = target.get_prop_atk_damage_received()
	var damage_total: float = damage * dealt_mod * received_mod
	_do_damage(target, damage_total, false)


# TODO: finish implementation. Need to implement crit, find
# out what myster float does. Also implement the difference
# between spell/attack damage
func do_attack_damage_aoe_unit(target: Unit, radius: float, damage: float, _crit: float, _mystery_float: float):
	var mob_list: Array = Utils.over_units_in_range_of_caster(target, TargetType.new(TargetType.UnitType.MOBS), radius)

	for mob in mob_list:
		mob._receive_damage(self, damage, false)


func do_spell_damage_aoe_unit(target: Unit, radius: float, damage: float, _crit: float, _mystery_float: float):
	var mob_list: Array = Utils.over_units_in_range_of_caster(target, TargetType.new(TargetType.UnitType.MOBS), radius)

	for mob in mob_list:
		mob._receive_damage(self, damage, false)

func kill_instantly(target: Unit):
	target._killed_by_unit(self, true)


func modify_property(mod_type: int, value: float, direction: int):
	var current_value: float = _mod_value_map[mod_type]
	var new_value: float = current_value + direction * value
	_mod_value_map[mod_type] = new_value

	_on_modify_property()


# These two functions are used to implement magical sight
# effects.
func add_invisible_watcher():
	_invisible_watcher_count += 1
	_update_invisible_modulate()

	if !is_invisible():
		became_visible.emit()


func remove_invisible_watcher():
	_invisible_watcher_count -= 1
	_update_invisible_modulate()

	if is_invisible():
		became_invisible.emit()


func spend_mana(mana_cost: float):
	_mana = max(0.0, _mana - mana_cost)


#########################
###      Private      ###
#########################


func _on_regen_timer_timeout():
	var mana_max: float = get_overall_mana()
	var mana_regen: float = get_overall_mana_regen()
	_mana = min(_mana + mana_regen, mana_max)

	var health_max: float = get_overall_health()
	var health_regen: float = get_overall_health_regen()
	_health = min(_health + health_regen, health_max)


func _do_attack(attack_event: Event):
	attack.emit(attack_event)

	var target = attack_event.get_target()
	target._receive_attack()


func _receive_attack():
	var attacked_event: Event = Event.new(self, 0, true)
	attacked.emit(attacked_event)


# NOTE: this function should not be called in any event
# handlers or public Unit functions that can be called from
# event handlers because that can cause an infinite
# recursion of DAMAGE events causing infinite DAMAGE events.
func _do_damage(target: Unit, damage: float, is_main_target: bool):
	var damage_event: Event = Event.new(target, damage, is_main_target)
	dealt_damage.emit(damage_event)

	target._receive_damage(self, damage_event.damage, is_main_target)


func _receive_damage(caster: Unit, damage_base: float, is_main_target: bool):
	var element_modifier: float = _get_damage_from_element_mod(caster)
	var damage: float = damage_base * element_modifier

	var health_before_damage: float = _health

	_health -= damage

	var damaged_event: Event = Event.new(caster, damage, is_main_target)
	damaged.emit(damaged_event)

	Utils.display_floating_text_x(str(int(damage)), self, 255, 0, 0, 0.0, 0.0, 1.0)

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
	death.emit(death_event)

	caster._accept_kill(self, is_main_target)

	queue_free()


# Called when unit kills target unit
func _accept_kill(target: Unit, is_main_target: bool):
	var bounty: float = _get_bounty_for_target(target)
	GoldManager.add_gold(bounty)

	var experience_gained: float = _get_experience_for_target(target)
	_experience += experience_gained

	if _experience >= EXP_PER_LEVEL:
		_experience -= EXP_PER_LEVEL

		var new_level: int = _level + 1
		set_level(new_level)

	var kill_event: Event = Event.new(target, 0, is_main_target)
	kill.emit(kill_event)


# This is for internal use in Buff.gd only. For external
# use, call Buff.apply_to_unit().
func _add_buff_internal(buff):
	var buff_type: String = buff.get_type()
	_buff_map[buff_type] = buff
	buff.removed.connect(_on_buff_removed.bind(buff))
	var buff_modifier: Modifier = buff.get_modifier()
	_apply_modifier(buff_modifier, buff.get_power(), 1)
	add_child(buff)


func _apply_modifier(modifier: Modifier, power: int, modify_direction: int):
	var modification_list: Array = modifier.get_modification_list()

	for modification in modification_list:
		var power_bonus: float = modification.level_add * (power - 1)
		var value: float = modification.value_base + power_bonus

		modify_property(modification.type, value, modify_direction)


func _update_invisible_modulate():
	if is_invisible():
		modulate = INVISIBLE_MODULATE
	else:
		modulate = Color(1, 1, 1, 1)

func _select():
	$Selection.show()
	_selected = true
	selected.emit()


func _unselect():
	$Selection.hide()
	_selected = false
	unselected.emit()


func _get_damage_from_element_mod(caster: Unit) -> float:
	if !caster is Tower:
		return 1.0

	var tower: Tower = caster as Tower

	var caster_element: int = tower.get_element()
	var mod_type: int = element_to_dmg_from_element_mod[caster_element]
	var mod_value: float = _mod_value_map[mod_type]

	return mod_value


func _get_bounty_for_target(target: Unit) -> float:
# 	TODO: Replace this placeholder constant with real value.
	var bounty_base: float = 10.0
	var granted_mod: float = target.get_prop_bounty_granted()
	var received_mod: float = get_prop_bounty_received()
	var bounty: int = int(bounty_base * granted_mod * received_mod)

	return bounty


func _get_experience_for_target(target: Unit) -> float:
# 	TODO: Replace this placeholder constant with real value.
	var experience_base: float = 10.0
	var granted_mod: float = target.get_prop_exp_granted()
	var received_mod: float = get_prop_exp_received()
	var experience: int = int(experience_base * granted_mod * received_mod)

	return experience


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
		_change_modifier_level(modifier, old_level, new_level)

	level_up.emit()


func _change_modifier_level(modifier: Modifier, old_level: int, new_level: int):
	_apply_modifier(modifier, old_level, -1)
	_apply_modifier(modifier, new_level, 1)


func is_dead() -> bool:
	return _is_dead


func is_mob() -> bool:
	return _is_mob


func is_tower() -> bool:
	return _is_tower


func get_visual_position() -> Vector2:
	return position


func get_x() -> float:
	return position.x


func get_y() -> float:
	return position.y


# NOTE: Getters for mod values are used in TowerTooltip.
# Getter names need to match the names of label nodes that
# display the values. For example if getter name is
# get_prop_trigger_chances(), then label name must be
# PropTriggerChances.

func get_prop_buff_duration() -> float:
	return _mod_value_map[ModType.MOD_BUFF_DURATION]

func get_prop_debuff_duration() -> float:
	return _mod_value_map[ModType.MOD_DEBUFF_DURATION]

func get_prop_atk_crit_chance() -> float:
	return _mod_value_map[ModType.MOD_ATK_CRIT_CHANCE]

func get_prop_atk_crit_damage() -> float:
	return _mod_value_map[ModType.MOD_ATK_CRIT_DAMAGE]

# TODO: implement
# Returns the value of the average damage multipler based on crit chance, crit damage
# and multicrit count of the tower
func get_crit_multiplier() -> float:
	return 1 + get_prop_atk_crit_chance() * get_prop_atk_crit_damage()

func get_prop_bounty_received() -> float:
	return _mod_value_map[ModType.MOD_BOUNTY_RECEIVED]

func get_prop_bounty_granted() -> float:
	return _mod_value_map[ModType.MOD_BOUNTY_GRANTED]

func get_prop_exp_received() -> float:
	return _mod_value_map[ModType.MOD_EXP_RECEIVED]

func get_prop_exp_granted() -> float:
	return _mod_value_map[ModType.MOD_EXP_GRANTED]

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

func get_prop_trigger_chances() -> float:
	return _mod_value_map[ModType.MOD_TRIGGER_CHANCES]

func get_prop_multicrit_count() -> int:
	return int(max(0, _mod_value_map[ModType.MOD_MULTICRIT_COUNT]))

func get_prop_spell_damage_dealt() -> float:
	return _mod_value_map[ModType.MOD_SPELL_DAMAGE_DEALT]

func get_prop_spell_damage_received() -> float:
	return _mod_value_map[ModType.MOD_SPELL_DAMAGE_RECEIVED]

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

func is_invisible() -> bool:
	return _invisible && _invisible_watcher_count == 0

func get_buff_of_type(type: String):
	var buff = _buff_map.get(type, null)

	return buff

func get_base_mana():
	return _base_mana

func get_base_mana_bonus():
	return _mod_value_map[ModType.MOD_MANA]

func get_base_mana_bonus_percent():
	return _mod_value_map[ModType.MOD_MANA_PERC]

func get_overall_mana():
	return (get_base_mana() + get_base_mana_bonus()) * (1 + get_base_mana_bonus_percent())

func get_base_mana_regen():
	return _base_mana_regen

func get_base_mana_regen_bonus():
	return _mod_value_map[ModType.MOD_MANA_REGEN]

func get_base_mana_regen_bonus_percent():
	return _mod_value_map[ModType.MOD_MANA_REGEN_PERC]

func get_overall_mana_regen():
	return (get_base_mana_regen() + get_base_mana_regen_bonus()) * (1 + get_base_mana_regen_bonus_percent())

func get_base_health():
	return _base_health

func get_base_health_bonus():
	return _mod_value_map[ModType.MOD_HP]

func get_base_health_bonus_percent():
	return _mod_value_map[ModType.MOD_HP_PERC]

func get_overall_health():
	return (get_base_health() + get_base_health_bonus()) * (1 + get_base_health_bonus_percent())

func get_base_health_regen():
	return _base_health_regen

func get_base_health_regen_bonus():
	return _mod_value_map[ModType.MOD_HP_REGEN]

func get_base_health_regen_bonus_percent():
	return _mod_value_map[ModType.MOD_HP_REGEN_PERC]

func get_overall_health_regen():
	return (get_base_health_regen() + get_base_health_regen_bonus()) * (1 + get_base_health_regen_bonus_percent())

func get_prop_move_speed() -> float:
	return _mod_value_map[ModType.MOD_MOVESPEED]

func get_prop_move_speed_absolute() -> float:
	return _mod_value_map[ModType.MOD_MOVESPEED_ABSOLUTE]

func get_prop_atk_damage_received() -> float:
	return _mod_value_map[ModType.MOD_ATK_DAMAGE_RECEIVED]

func get_selection_size():
	return _selection_size

func get_display_name() -> String:
	return "Generic Unit"

func is_selected() -> bool:
	return _selected

func set_selected(selected_arg: bool):
	if selected_arg:
		_select()
	else:
		_unselect()

# Implemented by Tower and Mob to return tower element or
# mob category
func get_category() -> int:
	return 0

func get_base_damage_bonus() -> float:
	return _mod_value_map[ModType.MOD_DAMAGE_BASE]

func get_base_damage_bonus_percent() -> float:
	return _mod_value_map[ModType.MOD_DAMAGE_BASE_PERC]

func get_damage_add() -> float:
	return _mod_value_map[ModType.MOD_DAMAGE_ADD]

func get_damage_add_percent() -> float:
	return _mod_value_map[ModType.MOD_DAMAGE_ADD_PERC]

# TODO: implement. Should be a combination of armor base,
# armor_add, armor_add_perc. Should be in range [0.0, 1.0]
func get_current_armor_damage_reduction() -> float:
	return 0.0

func get_mana() -> float:
	return _mana
