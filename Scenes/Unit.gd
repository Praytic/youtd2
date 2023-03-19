class_name Unit
extends CharacterBody2D

# Unit is a base class for Towers and Creeps. Keeps track of
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


var element_to_dmg_from_element_mod: Dictionary = {
	Tower.Element.ICE: Modification.Type.MOD_DMG_FROM_ICE,
	Tower.Element.NATURE: Modification.Type.MOD_DMG_FROM_NATURE,
	Tower.Element.FIRE: Modification.Type.MOD_DMG_FROM_FIRE,
	Tower.Element.ASTRAL: Modification.Type.MOD_DMG_FROM_ASTRAL,
	Tower.Element.DARKNESS: Modification.Type.MOD_DMG_FROM_DARKNESS,
	Tower.Element.IRON: Modification.Type.MOD_DMG_FROM_IRON,
	Tower.Element.STORM: Modification.Type.MOD_DMG_FROM_STORM,
}

const _creep_category_to_mod_map: Dictionary = {
	Creep.Category.UNDEAD: Modification.Type.MOD_DMG_TO_MASS,
	Creep.Category.MAGIC: Modification.Type.MOD_DMG_TO_MAGIC,
	Creep.Category.NATURE: Modification.Type.MOD_DMG_TO_NATURE,
	Creep.Category.ORC: Modification.Type.MOD_DMG_TO_ORC,
	Creep.Category.HUMANOID: Modification.Type.MOD_DMG_TO_HUMANOID,
}

const _creep_size_to_mod_map: Dictionary = {
	Creep.Size.MASS: Modification.Type.MOD_DMG_TO_MASS,
	Creep.Size.NORMAL: Modification.Type.MOD_DMG_TO_NORMAL,
	Creep.Size.CHAMPION: Modification.Type.MOD_DMG_TO_CHAMPION,
	Creep.Size.BOSS: Modification.Type.MOD_DMG_TO_BOSS,
	Creep.Size.AIR: Modification.Type.MOD_DMG_TO_AIR,
}

const MULTICRIT_DIMINISHING_CHANCE: float = 0.8
const INVISIBLE_MODULATE: Color = Color(1, 1, 1, 0.5)
# TODO: replace this placeholder constant with real value.
const EXP_PER_LEVEL: float = 100
const REGEN_PERIOD: float = 1.0


# HACK: to fix cyclic dependency between Tower<->TargetType
var _is_creep: bool = false
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
var _mana: float = 0.0
# TODO: define real value
var _base_armor: float = 45.0
var _dealt_damage_signal_in_progress: bool = false

# This is the count of towers that are currently able to see
# this invisible creep. If there any towers that can see this
# creep, then it is considered to be visible to all towers.
# See Unit.is_invisible() f-n and MagicalSightBuff.
var _invisible_watcher_count: int = 0


#########################
### Code starts here  ###
#########################

func _init():
	for mod_type in Modification.Type.values():
		_mod_value_map[mod_type] = 0.0
	_mod_value_map[Modification.Type.MOD_ATK_CRIT_CHANCE] = 0.01
	_mod_value_map[Modification.Type.MOD_ATK_CRIT_DAMAGE] = 1.5
	_mod_value_map[Modification.Type.MOD_TRIGGER_CHANCES] = 1.0
	_mod_value_map[Modification.Type.MOD_SPELL_DAMAGE_DEALT] = 1.0
	_mod_value_map[Modification.Type.MOD_SPELL_DAMAGE_RECEIVED] = 1.0
	_mod_value_map[Modification.Type.MOD_SPELL_CRIT_DAMAGE] = 1.5
	_mod_value_map[Modification.Type.MOD_SPELL_CRIT_CHANCE] = 0.01
	_mod_value_map[Modification.Type.MOD_BOUNTY_GRANTED] = 1.0
	_mod_value_map[Modification.Type.MOD_BOUNTY_RECEIVED] = 1.0
	_mod_value_map[Modification.Type.MOD_EXP_GRANTED] = 1.0
	_mod_value_map[Modification.Type.MOD_EXP_RECEIVED] = 1.0
	_mod_value_map[Modification.Type.MOD_BUFF_DURATION] = 1.0
	_mod_value_map[Modification.Type.MOD_DEBUFF_DURATION] = 1.0
	_mod_value_map[Modification.Type.MOD_MOVESPEED] = 1.0
	_mod_value_map[Modification.Type.MOD_MULTICRIT_COUNT] = 1.0
	_mod_value_map[Modification.Type.MOD_ATK_DAMAGE_RECEIVED] = 1.0

	_mod_value_map[Modification.Type.MOD_ARMOR] = 0.01
	_mod_value_map[Modification.Type.MOD_ARMOR_PERC] = 1.5

	_mod_value_map[Modification.Type.MOD_DAMAGE_BASE] = 0.0
	_mod_value_map[Modification.Type.MOD_DAMAGE_BASE_PERC] = 0.0
	_mod_value_map[Modification.Type.MOD_DAMAGE_ADD] = 0.0
	_mod_value_map[Modification.Type.MOD_DAMAGE_ADD_PERC] = 0.0

	_mod_value_map[Modification.Type.MOD_MANA] = 0.0
	_mod_value_map[Modification.Type.MOD_MANA_PERC] = 0.0
	_mod_value_map[Modification.Type.MOD_MANA_REGEN] = 0.0
	_mod_value_map[Modification.Type.MOD_MANA_REGEN_PERC] = 0.0
	_mod_value_map[Modification.Type.MOD_HP] = 0.0
	_mod_value_map[Modification.Type.MOD_HP_PERC] = 0.0
	_mod_value_map[Modification.Type.MOD_HP_REGEN] = 0.0
	_mod_value_map[Modification.Type.MOD_HP_REGEN_PERC] = 0.0

	_mod_value_map[Modification.Type.MOD_DMG_TO_MASS] = 1.0
	_mod_value_map[Modification.Type.MOD_DMG_TO_NORMAL] = 1.0
	_mod_value_map[Modification.Type.MOD_DMG_TO_CHAMPION] = 1.0
	_mod_value_map[Modification.Type.MOD_DMG_TO_BOSS] = 1.0
	_mod_value_map[Modification.Type.MOD_DMG_TO_AIR] = 1.0

	_mod_value_map[Modification.Type.MOD_DMG_TO_UNDEAD] = 1.0
	_mod_value_map[Modification.Type.MOD_DMG_TO_MAGIC] = 1.0
	_mod_value_map[Modification.Type.MOD_DMG_TO_NATURE] = 1.0
	_mod_value_map[Modification.Type.MOD_DMG_TO_ORC] = 1.0
	_mod_value_map[Modification.Type.MOD_DMG_TO_HUMANOID] = 1.0

	_mod_value_map[Modification.Type.MOD_DMG_FROM_ASTRAL] = 1.0
	_mod_value_map[Modification.Type.MOD_DMG_FROM_DARKNESS] = 1.0
	_mod_value_map[Modification.Type.MOD_DMG_FROM_NATURE] = 1.0
	_mod_value_map[Modification.Type.MOD_DMG_FROM_FIRE] = 1.0
	_mod_value_map[Modification.Type.MOD_DMG_FROM_ICE] = 1.0
	_mod_value_map[Modification.Type.MOD_DMG_FROM_STORM] = 1.0
	_mod_value_map[Modification.Type.MOD_DMG_FROM_IRON] = 1.0

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

	_mana = get_base_mana()


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
# unaffected by Modification.Type.MOD_TRIGGER_CHANCES.
func calc_bad_chance(chance: float) -> bool:
	var success: bool = Utils.rand_chance(chance)

	return success


func calc_spell_crit(bonus_chance: float, bonus_damage: float) -> float:
	var crit_chance: float = get_spell_crit_chance() + bonus_chance
	var crit_damage: float = get_spell_crit_damage() + bonus_damage

	var crit_success: bool = Utils.rand_chance(crit_chance)

	if crit_success:
		return crit_damage
	else:
		return 1.0


func calc_spell_crit_no_bonus() -> float:
	var result: float = calc_spell_crit(0.0, 0.0)

	return result


# Returns a randomly calculate crit bonus, no multicrit,
# either crit or not crit.
func calc_attack_crit(bonus_chance: float, bonus_damage: float) -> float:
	var crit_chance: float = get_prop_atk_crit_chance() + bonus_chance
	var crit_damage: float = get_prop_atk_crit_damage() + bonus_damage

	var crit_success: bool = Utils.rand_chance(crit_chance)

	if crit_success:
		return crit_damage
	else:
		return 1.0


func calc_attack_crit_no_bonus() -> float:
	var result: float = calc_spell_crit(0.0, 0.0)

	return result


# Returns a randomly calculated crit bonus (starts at 1.0),
# taking into account multicrit.
# 0 crits, 150% crit damage = 1.0
# 1 crit, 150% crit damage = 1.5
# 3 crits, 150% crit damage = 1.0 + 0.5 + 0.5 + 0.5 = 2.5
func calc_attack_multicrit(bonus_multicrit: float, bonus_chance: float, bonus_damage: float) -> float:
	var multicrit_count_max: int = get_prop_multicrit_count() + int(bonus_multicrit)
	var crit_chance: float = get_prop_atk_crit_chance() + bonus_chance
	var crit_damage: float = get_prop_atk_crit_damage() + bonus_damage

	var crit_count: int = 0
	var current_crit_chance: float = crit_chance
	
	for _i in range(multicrit_count_max):
		var is_critical: bool = Utils.rand_chance(current_crit_chance)

		if is_critical:
			crit_count += 1

#			Decrease chance of each subsequent multicrit to
#			implement diminishing returns.
			current_crit_chance *= MULTICRIT_DIMINISHING_CHANCE
		else:
			break

# 	NOTE: subtract 1.0 from crit_damage, so we do
#	1.0 + 0.5 + 0.5 + 0.5...
# 	not
#	1.0 + 1.5 + 1.5 + 1.5...
	var total_crit_damage: float = 1.0 + (crit_damage - 1.0) * crit_count

	total_crit_damage = max(0.0, total_crit_damage)

	return total_crit_damage


func do_spell_damage(target: Unit, damage: float, crit_ratio: float):
	var dealt_mod: float = get_prop_spell_damage_dealt()
	var received_mod: float = target.get_prop_spell_damage_received()
	var damage_total: float = damage * dealt_mod * received_mod * crit_ratio

	if target.is_immune():
		damage_total = 0

	_do_damage(target, damage_total, false, true)


func do_attack_damage(target: Unit, damage_base: float, crit_ratio: float):
	_do_attack_damage_internal(target, damage_base, crit_ratio, false)


func _do_attack_damage_internal(target: Unit, damage_base: float, crit_ratio: float, is_main_target: bool):
	var armor_mod: float = target.get_current_armor_damage_reduction()
	var received_mod: float = target.get_prop_atk_damage_received()
	var element_mod: float = 1.0

	if self is Tower:
		var tower: Tower = self as Tower
		var element: Tower.Element = tower.get_element()
		var mod_type: Modification.Type = element_to_dmg_from_element_mod[element]
		element_mod = target._mod_value_map[mod_type]

	var damage: float = damage_base * armor_mod * received_mod * element_mod

#   NOTE: do not emit damage event if one is already in
#   progress. Some towers have damage event handlers that
#   call doAttackDamage() so recursive damage events would
#   cause infinite recursion.
	if !_dealt_damage_signal_in_progress:
		_dealt_damage_signal_in_progress = true

		var damage_event: Event = Event.new(target)
		damage_event.damage = damage
		damage_event._is_main_target = is_main_target
		dealt_damage.emit(damage_event)
		damage = damage_event.damage

		_dealt_damage_signal_in_progress = false

#	NOTE: according to this comment in one tower script,
#	crit bonus damage should be applied after damage event:
#
# 	Quote: "The engine calculates critical strike extra
# 	damage ***AFTER*** the onDamage event, so there is no
# 	need to care about it in this trigger."
	damage *= crit_ratio

	_do_damage(target, damage, false, false)


# NOTE: sides_ratio parameter specifies how much less damage
# is dealt to units that are on the "sides" of the aoe
# circle. For example, if sides_ratio is set to 0.3 then
# units on the sides will receive 30% less damage than those
# in the center.
func do_attack_damage_aoe_unit(target: Unit, radius: float, damage: float, crit_ratio: float, sides_ratio: float):
	var creep_list: Array = Utils.get_units_in_range(TargetType.new(TargetType.CREEPS), target.position, radius)

	for creep in creep_list:
		var damage_for_creep: float = _get_aoe_damage(creep, radius, damage, sides_ratio)
		do_attack_damage(target, damage_for_creep, crit_ratio)


func do_spell_damage_aoe_unit(target: Unit, radius: float, damage: float, crit_ratio: float, sides_ratio: float):
	var creep_list: Array = Utils.get_units_in_range(TargetType.new(TargetType.CREEPS), target.position, radius)

	for creep in creep_list:
		var damage_for_creep: float = _get_aoe_damage(creep, radius, damage, sides_ratio)
		do_spell_damage(self, damage_for_creep, crit_ratio)

func kill_instantly(target: Unit):
	target._killed_by_unit(self)


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


func _get_aoe_damage(target: Unit, radius: float, damage: float, sides_ratio: float) -> float:
	var distance: float = Utils.vector_isometric_distance_to(position, target.position)
	var target_is_on_the_sides: bool = (distance / radius) > 0.5

	if target_is_on_the_sides:
		return damage * (1.0 - sides_ratio)
	else:
		return damage


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
	var attacked_event: Event = Event.new(self)
	attacked.emit(attacked_event)


func _do_damage(target: Unit, damage_base: float, is_main_target: bool, is_spell_damage: bool):
	var size_mod: float = _get_damage_mod_for_creep_size(target)
	var category_mod: float = _get_damage_mod_for_creep_category(target)
	var armor_type_mod: float = _get_damage_mod_for_creep_armor_type(target)

	var damage: float = damage_base * size_mod * category_mod * armor_type_mod

	var damaged_event: Event = Event.new(self)
	damaged_event.damage = damage
	damaged_event._is_main_target = is_main_target
	damaged_event._is_spell_damage = is_spell_damage
	target.damaged.emit(damaged_event)

	damage = damaged_event.damage

	var health_before_damage: float = target._health

	target._health -= damage

	Utils.display_floating_text_x(str(int(damage)), target, 255, 0, 0, 0.0, 0.0, 1.0)

	var damage_killed_unit: bool = health_before_damage > 0 && target._health <= 0

	if damage_killed_unit:
		target._killed_by_unit(self)


# Called when unit killed by caster unit
func _killed_by_unit(caster: Unit):
# 	NOTE: need to use explicit "is_dead" flag. Calling
# 	queue_free() makes is_instance_valid(unit) return false
# 	but that happens only at the end of the current frame.
# 	Other signals/slots might fire before that point and
# 	they need to know if the unit is dead to avoid
# 	processing it.
	_is_dead = true

	var death_event: Event = Event.new(self)
	death.emit(death_event)

	caster._accept_kill(self)

	queue_free()


# Called when unit kills target unit
func _accept_kill(target: Unit):
	var bounty: float = _get_bounty_for_target(target)
	GoldManager.add_gold(bounty)

	var experience_gained: float = _get_experience_for_target(target)
	_experience += experience_gained

	if _experience >= EXP_PER_LEVEL:
		_experience -= EXP_PER_LEVEL

		var new_level: int = _level + 1
		set_level(new_level)

	var kill_event: Event = Event.new(target)
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


func is_creep() -> bool:
	return _is_creep


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
	return _mod_value_map[Modification.Type.MOD_BUFF_DURATION]

func get_prop_debuff_duration() -> float:
	return _mod_value_map[Modification.Type.MOD_DEBUFF_DURATION]

func get_prop_atk_crit_chance() -> float:
	return _mod_value_map[Modification.Type.MOD_ATK_CRIT_CHANCE]

func get_prop_atk_crit_damage() -> float:
	return _mod_value_map[Modification.Type.MOD_ATK_CRIT_DAMAGE]

# TODO: implement
# Returns the value of the average damage multipler based on crit chance, crit damage
# and multicrit count of the tower
func get_crit_multiplier() -> float:
	return 1 + get_prop_atk_crit_chance() * get_prop_atk_crit_damage()

func get_prop_bounty_received() -> float:
	return _mod_value_map[Modification.Type.MOD_BOUNTY_RECEIVED]

func get_prop_bounty_granted() -> float:
	return _mod_value_map[Modification.Type.MOD_BOUNTY_GRANTED]

func get_prop_exp_received() -> float:
	return _mod_value_map[Modification.Type.MOD_EXP_RECEIVED]

func get_prop_exp_granted() -> float:
	return _mod_value_map[Modification.Type.MOD_EXP_GRANTED]

func get_damage_to_air() -> float:
	return _mod_value_map[Modification.Type.MOD_DMG_TO_AIR]

func get_damage_to_boss() -> float:
	return _mod_value_map[Modification.Type.MOD_DMG_TO_BOSS]

func get_damage_to_mass() -> float:
	return _mod_value_map[Modification.Type.MOD_DMG_TO_MASS]

func get_damage_to_normal() -> float:
	return _mod_value_map[Modification.Type.MOD_DMG_TO_NORMAL]

func get_damage_to_champion() -> float:
	return _mod_value_map[Modification.Type.MOD_DMG_TO_CHAMPION]

func get_damage_to_undead() -> float:
	return _mod_value_map[Modification.Type.MOD_DMG_TO_UNDEAD]

func get_damage_to_humanoid() -> float:
	return _mod_value_map[Modification.Type.MOD_DMG_TO_HUMANOID]

func get_damage_to_nature() -> float:
	return _mod_value_map[Modification.Type.MOD_DMG_TO_NATURE]

func get_damage_to_magic() -> float:
	return _mod_value_map[Modification.Type.MOD_DMG_TO_MAGIC]

func get_damage_to_orc() -> float:
	return _mod_value_map[Modification.Type.MOD_DMG_TO_ORC]

func get_exp_ratio() -> float:
	return _mod_value_map[Modification.Type.MOD_EXP_RECEIVED]

func get_item_drop_ratio() -> float:
	return _mod_value_map[Modification.Type.MOD_ITEM_CHANCE_ON_KILL]

func get_item_quality_ratio() -> float:
	return _mod_value_map[Modification.Type.MOD_ITEM_QUALITY_ON_KILL]

func get_prop_trigger_chances() -> float:
	return _mod_value_map[Modification.Type.MOD_TRIGGER_CHANCES]

func get_prop_multicrit_count() -> int:
	return int(max(0, _mod_value_map[Modification.Type.MOD_MULTICRIT_COUNT]))

func get_prop_spell_damage_dealt() -> float:
	return _mod_value_map[Modification.Type.MOD_SPELL_DAMAGE_DEALT]

func get_prop_spell_damage_received() -> float:
	return _mod_value_map[Modification.Type.MOD_SPELL_DAMAGE_RECEIVED]

func get_spell_crit_chance() -> float:
	return _mod_value_map[Modification.Type.MOD_SPELL_CRIT_CHANCE]

func get_spell_crit_damage() -> float:
	return _mod_value_map[Modification.Type.MOD_SPELL_CRIT_DAMAGE]

# The Base Cooldown is divided by this value. Towers gain some attackspeed per level and items, 
# buffs and auras can grant attackspeed.
func get_base_attack_speed() -> float:
	return _mod_value_map[Modification.Type.MOD_ATTACKSPEED]

func get_level() -> int:
	return _level

func is_invisible() -> bool:
	return _invisible && _invisible_watcher_count == 0

func get_buff_of_type(type: String):
	var buff = _buff_map.get(type, null)

	return buff

# NOTE: real value returned in subclass version
func get_base_mana() -> float:
	return 0.0

func get_base_mana_bonus():
	return _mod_value_map[Modification.Type.MOD_MANA]

func get_base_mana_bonus_percent():
	return _mod_value_map[Modification.Type.MOD_MANA_PERC]

func get_overall_mana():
	return (get_base_mana() + get_base_mana_bonus()) * (1 + get_base_mana_bonus_percent())

# NOTE: real value returned in subclass version
func get_base_mana_regen() -> float:
	return 0.0

func get_base_mana_regen_bonus():
	return _mod_value_map[Modification.Type.MOD_MANA_REGEN]

func get_base_mana_regen_bonus_percent():
	return _mod_value_map[Modification.Type.MOD_MANA_REGEN_PERC]

func get_overall_mana_regen():
	return (get_base_mana_regen() + get_base_mana_regen_bonus()) * (1 + get_base_mana_regen_bonus_percent())

func get_base_health():
	return _base_health

func get_base_health_bonus():
	return _mod_value_map[Modification.Type.MOD_HP]

func get_base_health_bonus_percent():
	return _mod_value_map[Modification.Type.MOD_HP_PERC]

func get_overall_health():
	return (get_base_health() + get_base_health_bonus()) * (1 + get_base_health_bonus_percent())

func get_base_health_regen():
	return _base_health_regen

func get_base_health_regen_bonus():
	return _mod_value_map[Modification.Type.MOD_HP_REGEN]

func get_base_health_regen_bonus_percent():
	return _mod_value_map[Modification.Type.MOD_HP_REGEN_PERC]

func get_overall_health_regen():
	return (get_base_health_regen() + get_base_health_regen_bonus()) * (1 + get_base_health_regen_bonus_percent())

func get_prop_move_speed() -> float:
	return _mod_value_map[Modification.Type.MOD_MOVESPEED]

func get_prop_move_speed_absolute() -> float:
	return _mod_value_map[Modification.Type.MOD_MOVESPEED_ABSOLUTE]

func get_prop_atk_damage_received() -> float:
	return _mod_value_map[Modification.Type.MOD_ATK_DAMAGE_RECEIVED]

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

# Implemented by Tower and Creep to return tower element or
# creep category
func get_category() -> int:
	return 0

func get_base_damage_bonus() -> float:
	return _mod_value_map[Modification.Type.MOD_DAMAGE_BASE]

func get_base_damage_bonus_percent() -> float:
	return _mod_value_map[Modification.Type.MOD_DAMAGE_BASE_PERC]

func get_damage_add() -> float:
	return _mod_value_map[Modification.Type.MOD_DAMAGE_ADD]

func get_damage_add_percent() -> float:
	return _mod_value_map[Modification.Type.MOD_DAMAGE_ADD_PERC]

# TODO: implement real formula
func get_current_armor_damage_reduction() -> float:
	var armor: float = get_overall_armor()
	var reduction: float = max(1.0, armor / 1000.0)

	return reduction

func get_mana() -> float:
	return _mana

func get_base_armor() -> float:
	return _base_armor

func get_base_armor_bonus() -> float:
	return _mod_value_map[Modification.Type.MOD_ARMOR]

func get_base_armor_bonus_percent() -> float:
	return _mod_value_map[Modification.Type.MOD_ARMOR_PERC]

func get_overall_armor():
	return (get_base_armor() + get_base_armor_bonus()) * (1.0 + get_base_armor_bonus_percent())

func get_dps_bonus() -> float:
	return _mod_value_map[Modification.Type.MOD_DPS_ADD]

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

func get_attack_type() -> AttackType.enm:
	return AttackType.enm.PHYSICAL
