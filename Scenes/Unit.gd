class_name Unit
extends Node2D

# Unit is a base class for Towers and Creeps. Keeps track of
# buffs and modifications. Emits signals for events which are used by buffs.

# NOTE: can't use static typing for Buff because of cyclic
# dependency

# NOTE: level_changed() always gets emitted, while
# level_up() gets emitted only when level increases.
signal level_changed
signal level_up
signal attack(event)
signal attacked(event)
signal dealt_damage(event)
signal damaged(event)
signal kill(event)
signal death(event)
signal became_invisible()
signal became_visible()
signal health_changed()
signal mana_changed()
signal spell_casted(event: Event)
signal spell_targeted(event: Event)
signal earn_gold(amount: float, _mystery_bool_1: bool, _mystery_bool_2: bool)
signal buff_list_changed()


signal selected()
signal unselected()


enum DamageSource {
	Attack,
	Spell
}


const MULTICRIT_DIMINISHING_CHANCE: float = 0.8
const INVISIBLE_MODULATE: Color = Color(1, 1, 1, 0.5)
const REGEN_PERIOD: float = 1.0
const BASE_ITEM_DROP_CHANCE: float = 0.0475

var _visual_node: Node2D = null
var _sprite_dimensions: Vector2 = Vector2(100, 100)

# NOTE: userInt/userInt2/... in JASS
var user_int: int = 0
var user_int2: int = 0
var user_int3: int = 0
var user_real: float = 0.0
var user_real2: float = 0.0
var user_real3: float = 0.0

# NOTE: crit bonus in terms of number of crits. The logic is
# different for attack vs spell. For attack crits, the bonus
# is applied only to normal tower attacks. Bonus is not
# applied to do_attack_damage() called from other scripts.
# This is because it would be confusing for an item like
# "every 5th attack is critical" to produce no visible
# change because tower is consuming crit bonus via some
# other attack damage which is not visible to the player.
# For spells, the bonus is applied to all instances of spell
# damage, which includes calls to do_spell_damage(), spells
# casted using Cast class, etc.
var _crit_bonus_for_next_attack: int = 0
var _crit_damage_ratio_for_next_attack: float = 0.0
var _crit_bonus_for_next_spell: int = 0

var _is_dead: bool = false
var _level: int = 0 : get = get_level, set = set_level
var _buff_type_map: Dictionary
var _buff_group_map: Dictionary
var _friendly_buff_list: Array[Buff]
var _unfriendly_buff_list: Array[Buff]
var _direct_modifier_list: Array
var _base_health: float = 100.0 : get = get_base_health, set = set_base_health
var _health: float = 0.0
var _base_health_regen: float = 0.0
var _invisible: bool = false
var _immune: bool = false
var _selected: bool = false : get = is_selected
var _experience: float = 0.0
var _mana: float = 0.0
var _base_mana: float = 0.0
var _base_mana_regen: float = 0.0
var _base_armor: float = 0.0
var _dealt_damage_signal_in_progress: bool = false
var _kill_count: int = 0
var _best_hit: float = 0.0
var _damage_dealt_total: float = 0.0
var _silence_count: int = 0
var _stunned: bool = false
var _visual_only: bool = false
var _autocast_list: Array[Autocast] = []
var _stored_visual_modulate: Color = Color.WHITE

var _selection_visual: Node = null

# This is the count of towers that are currently able to see
# this invisible creep. If there any towers that can see this
# creep, then it is considered to be visible to all towers.
# See Unit.is_invisible() f-n and MagicalSightBuff.
var _invisible_watcher_count: int = 0

# NOTE: logic for default values is the following. If
# property is multiplied, then it's default is 1.0 so that
# by default it doesn't change anything. If property is
# added, then default is 0.0 so that by default it doesn't
# change anything.
#
# Execeptions are MOD_ATK_CRIT_DAMAGE, MOD_SPELL_CRIT_DAMAGE
# which start at 1.5 because by default crits increase
# damage by 50%. MOD_ATK_CRIT_CHANCE and
# MOD_SPELL_CRIT_CHANCE start at 0.01 because by default
# crit chance is 1%.
var _mod_value_map: Dictionary = {
	Modification.Type.MOD_ATK_CRIT_CHANCE: Constants.INNATE_MOD_ATK_CRIT_CHANCE,
	Modification.Type.MOD_ATK_CRIT_DAMAGE: Constants.INNATE_MOD_ATK_CRIT_DAMAGE,
	Modification.Type.MOD_TRIGGER_CHANCES: 1.0,
	Modification.Type.MOD_SPELL_DAMAGE_DEALT: 1.0,
	Modification.Type.MOD_SPELL_DAMAGE_RECEIVED: 1.0,
	Modification.Type.MOD_SPELL_CRIT_DAMAGE: Constants.INNATE_MOD_SPELL_CRIT_DAMAGE,
	Modification.Type.MOD_SPELL_CRIT_CHANCE: Constants.INNATE_MOD_SPELL_CRIT_CHANCE,
	Modification.Type.MOD_BOUNTY_GRANTED: 1.0,
	Modification.Type.MOD_BOUNTY_RECEIVED: 1.0,
	Modification.Type.MOD_EXP_GRANTED: 1.0,
	Modification.Type.MOD_EXP_RECEIVED: 1.0,
	Modification.Type.MOD_BUFF_DURATION: 1.0,
	Modification.Type.MOD_DEBUFF_DURATION: 1.0,
	Modification.Type.MOD_MOVESPEED: 1.0,
	Modification.Type.MOD_MOVESPEED_ABSOLUTE: 0.0,
	Modification.Type.MOD_MULTICRIT_COUNT: 1.0,
	Modification.Type.MOD_ATK_DAMAGE_RECEIVED: 1.0,
	Modification.Type.MOD_ATTACKSPEED: 1.0,
	Modification.Type.MOD_DPS_ADD: 0.0,

	Modification.Type.MOD_ITEM_CHANCE_ON_KILL: 1.0,
	Modification.Type.MOD_ITEM_QUALITY_ON_KILL: 1.0,
	Modification.Type.MOD_ITEM_CHANCE_ON_DEATH: 1.0,
	Modification.Type.MOD_ITEM_QUALITY_ON_DEATH: 1.0,

	Modification.Type.MOD_ARMOR: 0.0,
	Modification.Type.MOD_ARMOR_PERC: 1.0,

	Modification.Type.MOD_DAMAGE_BASE: 0.0,
	Modification.Type.MOD_DAMAGE_BASE_PERC: 1.0,
	Modification.Type.MOD_DAMAGE_ADD: 0.0,
	Modification.Type.MOD_DAMAGE_ADD_PERC: 1.0,

	Modification.Type.MOD_MANA: 0.0,
	Modification.Type.MOD_MANA_PERC: 1.0,
	Modification.Type.MOD_MANA_REGEN: 0.0,
	Modification.Type.MOD_MANA_REGEN_PERC: 1.0,
	Modification.Type.MOD_HP: 0.0,
	Modification.Type.MOD_HP_PERC: 1.0,
	Modification.Type.MOD_HP_REGEN: 0.0,
	Modification.Type.MOD_HP_REGEN_PERC: 1.0,

	Modification.Type.MOD_DMG_TO_MASS: 1.0,
	Modification.Type.MOD_DMG_TO_NORMAL: 1.0,
	Modification.Type.MOD_DMG_TO_CHAMPION: 1.0,
	Modification.Type.MOD_DMG_TO_BOSS: 1.0,
	Modification.Type.MOD_DMG_TO_AIR: 1.0,

	Modification.Type.MOD_DMG_TO_UNDEAD: 1.0,
	Modification.Type.MOD_DMG_TO_MAGIC: 1.0,
	Modification.Type.MOD_DMG_TO_NATURE: 1.0,
	Modification.Type.MOD_DMG_TO_ORC: 1.0,
	Modification.Type.MOD_DMG_TO_HUMANOID: 1.0,
	Modification.Type.MOD_DMG_TO_CHALLENGE: 1.0,

	Modification.Type.MOD_DMG_FROM_ASTRAL: 1.0,
	Modification.Type.MOD_DMG_FROM_DARKNESS: 1.0,
	Modification.Type.MOD_DMG_FROM_NATURE: 1.0,
	Modification.Type.MOD_DMG_FROM_FIRE: 1.0,
	Modification.Type.MOD_DMG_FROM_ICE: 1.0,
	Modification.Type.MOD_DMG_FROM_STORM: 1.0,
	Modification.Type.MOD_DMG_FROM_IRON: 1.0,
}


@onready var _player: Player = get_tree().get_root().get_node("GameScene/Player")


#########################
### Code starts here  ###
#########################


func _init():
	for mod_type in Modification.Type.values():
		if !_mod_value_map.has(mod_type):
			push_error("No default value defined for modification type: ", mod_type)

func _ready():
	if _visual_only:
		return

	_selection_visual = Selection.new()
	_selection_visual.hide()
	_selection_visual.z_index = -1
	add_child(_selection_visual)
	
	var regen_timer: Timer = Timer.new()
	regen_timer.one_shot = false
	regen_timer.wait_time = REGEN_PERIOD
	regen_timer.timeout.connect(_on_regen_timer_timeout)
	add_child(regen_timer)
	regen_timer.start()

	var triggers_buff_type: BuffType = BuffType.new("", 0, 0, true, self)
	load_triggers(triggers_buff_type)
	triggers_buff_type.apply_to_unit_permanent(self, self, 0)


#########################
###       Public      ###
#########################


# NOTE: unit.addAttackCrit() in JASS
func add_attack_crit():
	_crit_bonus_for_next_attack = _crit_bonus_for_next_attack + 1

func add_modified_attack_crit(_mystery_float: float, crit_damage_ratio: float):
	_crit_bonus_for_next_attack = _crit_bonus_for_next_attack + 1
	_crit_damage_ratio_for_next_attack = crit_damage_ratio


# NOTE: unit.addSpellCrit() in JASS
func add_spell_crit():
	_crit_bonus_for_next_spell = _crit_bonus_for_next_spell + 1


# NOTE: unit.addManaPerc() in JASS
func add_mana_perc(ratio: float):
	var overall_mana: float = get_overall_mana()
	var mana_added: float = ratio * overall_mana
	add_mana(mana_added)


# NOTE: unit.addMana() in JASS
func add_mana(mana_added: float):
	var new_mana: float = _mana + mana_added
	set_mana(new_mana)


func add_autocast(autocast: Autocast):
	autocast.set_caster(self)
	_autocast_list.append(autocast)
	add_child(autocast)


func get_autocast_list() -> Array[Autocast]:
	return _autocast_list


func add_aura(aura_type: AuraType):
	var aura: Aura = aura_type.make(self)
	add_child(aura)


# NOTE: for now just returning the one single player
# instance since multiplayer isn't implemented. Also, the
# name isn't "get_player()" because that is already a
# function of Node class.
# 
# NOTE: unit.getOwner() in JASS
# Node.get_owner() is a built-in godot f-n
func get_player() -> Player:
	return _player


# TODO: implement. Should return the number of crits for
# current attack. Needs to be accessible inside attack
# event.
# NOTE: unit.getNumberOfCrits() in JASS
func get_number_of_crits() -> int:
	return 0


# NOTE: this is a stub, used in original tower scripts but
# not needed in godot engine.
# NOTE: unit.setAnimationByIndex() in JASS
func set_animation_by_index(_unit: Unit, _index: int):
	pass


# Unaffected by tower exp ratios. Levels up unit if added
# exp pushes the unit past the level up threshold.
# NOTE: unit.addExpFlat() in JASS
func add_exp_flat(amount: float):
	_change_experience(amount)


# Affected by tower exp ratios.
# NOTE: unit.addExp() in JASS
func add_exp(amount_no_bonus: float):
	var received_mod: float = get_prop_exp_received()
	var amount: float = amount_no_bonus * received_mod
	_change_experience(amount)


# Unaffected by tower exp ratios. Returns how much
# experience was actually removed. How much was actually
# removed may be less than requested if the unit has less
# mana than should be removed. In that case unit's mana gets
# set to 0.
# NOTE: unit.removeExpFlat() in JASS
func remove_exp_flat(amount: float) -> float:
	var actual_change: float = _change_experience(-amount)
	var actual_removed: float = abs(actual_change)

	return actual_removed


# Affected by "exp recieved" modification.
# NOTE: unit.removeExp() in JASS
func remove_exp(amount_no_bonus: float) -> float:
	var received_mod: float = get_prop_exp_received()
	var amount: float = amount_no_bonus / max(0.1, received_mod)
	var actual_change: float = _change_experience(-amount)
	var actual_removed: float = abs(actual_change)

	return actual_removed


# NOTE: unit.calcChance() in JASS
func calc_chance(chance_base: float) -> bool:
	var mod_trigger_chances: float = get_prop_trigger_chances()
	var chance: float = chance_base * mod_trigger_chances
	var success: bool = Utils.rand_chance(chance)

	return success


# "Bad" chance is for events that decrease tower's
# perfomance, for example missing attack. Bad chances are
# unaffected by Modification.Type.MOD_TRIGGER_CHANCES.
# NOTE: unit.calcBadChance() in JASS
func calc_bad_chance(chance: float) -> bool:
	var success: bool = Utils.rand_chance(chance)

	return success


# NOTE: unit.calcSpellCrit() in JASS
func calc_spell_crit(bonus_chance: float, bonus_damage: float) -> float:
	var crit_chance: float = get_spell_crit_chance() + bonus_chance
	var crit_damage: float = get_spell_crit_damage() + bonus_damage

	var crit_success: bool = Utils.rand_chance(crit_chance)

	if _crit_bonus_for_next_spell > 0:
		crit_success = true
		_crit_bonus_for_next_spell = 0

	if crit_success:
		return crit_damage
	else:
		return 1.0


# NOTE: unit.calcSpellCritNoBonus() in JASS
func calc_spell_crit_no_bonus() -> float:
	var result: float = calc_spell_crit(0.0, 0.0)

	return result


# Returns a randomly calculate crit bonus, no multicrit,
# either crit or not crit.
# NOTE: unit.calcAttackCrit() in JASS
func calc_attack_crit(bonus_chance: float, bonus_damage: float) -> float:
	var crit_chance: float = get_prop_atk_crit_chance() + bonus_chance
	var crit_damage: float = get_prop_atk_crit_damage() + bonus_damage

	var crit_success: bool = Utils.rand_chance(crit_chance)

	if crit_success:
		return crit_damage
	else:
		return 1.0


# NOTE: unit.calcAttackCritNoBonus() in JASS
func calc_attack_crit_no_bonus() -> float:
	var result: float = calc_attack_crit(0.0, 0.0)

	return result


# Returns a randomly calculated crit bonus (starts at 1.0),
# taking into account multicrit.
# 0 crits, 150% crit damage = 1.0
# 1 crit, 150% crit damage = 1.5
# 3 crits, 150% crit damage = 1.0 + 0.5 + 0.5 + 0.5 = 2.5
# NOTE: unit.calcAttackMulticrit() in JASS
func calc_attack_multicrit(bonus_multicrit: float, bonus_chance: float, bonus_damage: float) -> float:
	var crit_count: int = _generate_crit_count(bonus_multicrit, bonus_chance)
	var crit_damage: float = _calc_attack_multicrit_internal(crit_count, bonus_damage)

	return crit_damage


func calc_attack_multicrit_no_bonus() -> float:
	return calc_attack_multicrit(0, 0, 0)


# NOTE: unit.doSpellDamage() in JASS
func do_spell_damage(target: Unit, damage: float, crit_ratio: float) -> bool:
	var caster: Unit = self
	var dealt_mod: float = caster.get_prop_spell_damage_dealt()
	var received_mod: float = target.get_prop_spell_damage_received()
	var damage_total: float = damage * dealt_mod * received_mod * crit_ratio

	var killed_unit: bool = _do_damage(target, damage_total, DamageSource.Spell)

	return killed_unit


# NOTE: unit.doAttackDamage() in JASS
func do_attack_damage(target: Unit, damage_base: float, crit_ratio: float):
	var attack_type: AttackType.enm = get_attack_type()
	_do_attack_damage_internal(target, damage_base, crit_ratio, false, attack_type)


# NOTE: unit.doCustomAttackDamage() in JASS
func do_custom_attack_damage(target: Unit, damage_base: float, crit_ratio: float, attack_type: AttackType.enm):
	_do_attack_damage_internal(target, damage_base, crit_ratio, false, attack_type)

func _do_attack_damage_internal(target: Unit, damage_base: float, crit_ratio: float, is_main_target: bool, attack_type: AttackType.enm):
	var armor_mod: float = 1.0 - target.get_current_armor_damage_reduction()
	var received_mod: float = target.get_prop_atk_damage_received()
	var element_mod: float = 1.0

	if self is Tower:
		var tower: Tower = self as Tower
		var element: Element.enm = tower.get_element()
		var mod_type: Modification.Type = Element.convert_to_dmg_from_element_mod(element)
		element_mod = target._mod_value_map[mod_type]

	var damage: float = damage_base * armor_mod * received_mod * element_mod

	var deals_no_damage_to_immune: bool = AttackType.deals_no_damage_to_immune(attack_type)

	if target.is_immune() && deals_no_damage_to_immune:
		damage = 0

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

	_do_damage(target, damage, DamageSource.Attack)


# NOTE: sides_ratio parameter specifies how much less damage
# is dealt to units that are on the "sides" of the aoe
# circle. For example, if sides_ratio is set to 0.3 then
# units on the sides will receive 30% less damage than those
# in the center.
# 
# NOTE: unit.doAttackDamageAoEUnit() in JASS
func do_attack_damage_aoe_unit(target: Unit, radius: float, damage: float, crit_ratio: float, sides_ratio: float):
	var aoe_center: Vector2 = Vector2(target.get_x(), target.get_y())
	var creep_list: Array = Utils.get_units_in_range(TargetType.new(TargetType.CREEPS), aoe_center, radius)

	for creep in creep_list:
		var damage_for_creep: float = _get_aoe_damage(aoe_center, creep, radius, damage, sides_ratio)
		do_attack_damage(creep, damage_for_creep, crit_ratio)


# NOTE: unit.doSpellDamageAoEUnit() in JASS
func do_spell_damage_aoe_unit(target: Unit, radius: float, damage: float, crit_ratio: float, sides_ratio: float):
	do_spell_damage_aoe(target.get_x(), target.get_y(), radius, damage, crit_ratio, sides_ratio)


# NOTE: unit.doSpellDamageAoE() in JASS
func do_spell_damage_aoe(x: float, y: float, radius: float, damage: float, crit_ratio: float, sides_ratio: float):
	var aoe_center: Vector2 = Vector2(x, y)
	var creep_list: Array = Utils.get_units_in_range(TargetType.new(TargetType.CREEPS), aoe_center, radius)

	for creep in creep_list:
		var damage_for_creep: float = _get_aoe_damage(aoe_center, creep, radius, damage, sides_ratio)
		do_spell_damage(creep, damage_for_creep, crit_ratio)


# NOTE: unit.killInstantly() in JASS
func kill_instantly(target: Unit):
	target._killed_by_unit(self)


# NOTE: unit.modifyProperty() in JASS
func modify_property(mod_type: Modification.Type, value: float):
	_modify_property_internal(mod_type, value, 1)


func _modify_property_internal(mod_type: Modification.Type, value: float, direction: int):
	var health_ratio: float = get_health_ratio()
	var mana_ratio: float = get_mana_ratio()

	var current_value: float = _mod_value_map[mod_type]
	var new_value: float = current_value + direction * value
	_mod_value_map[mod_type] = new_value

#	NOTE: restore original health and mana ratios. For
#	example, if original mana was 50/100 and mana was
#	increased by 50, then final values will be 75/150 to
#	preserve the 50% ratio.
	var new_health_max: float = get_overall_health()
	_health = health_ratio * new_health_max
	var new_mana_max: float = get_overall_mana()
	_mana = mana_ratio * new_mana_max

	_on_modify_property()


# NOTE: this modifies only creep's ability to be invisible.
# It won't be invisible if the creep is within range of
# towers that can see invisible units.
func set_invisible(invisible: bool):
	_invisible = invisible
	_update_invisible_modulate()


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


# TODO: silence visual. When silence_count changes from 0 to
# 1, create it and schedule to destroy it once animation
# finishes. Idea for how it should look:
# https://youtu.be/zUCL-_6YOT8?t=46
func add_silence():
	_silence_count += 1


func remove_silence():
	_silence_count -= 1


func set_stunned(value: bool):
	_stunned = value


# Returns the amount of mana that was subtracted.
# NOTE: unit.subtractMana() in JASS
func subtract_mana(amount: float, show_text: bool) -> float:
	var old_mana: float = _mana
	var new_mana: float = clampf(_mana - amount, 0.0, _mana)
	set_mana(new_mana)

	var actual_subtracted: float = old_mana - new_mana

	if show_text:
		var text: String
		var amount_string: String = Utils.format_float(actual_subtracted, 1)

		if actual_subtracted >= 0:
			text = "+%s" % amount_string
		else:
			text = "-%s" % amount_string

		get_player().display_floating_text_color(text, self, Color.BLUE, 1.0)

	return actual_subtracted


#########################
###      Private      ###
#########################


# Returns a prop value after applying diminishing returns to
# it. Diminishing returns reduce effectiveness of mods as
# the prop value gets further away from [0.6, 1.7] range.
func get_prop_with_diminishing_returns(type: Modification.Type) -> float:
	var value: float = max(0, _mod_value_map[type])

	if value > 1.7:
		return 1.7 + (value - 1.7) / pow(1.0 + value - 1.7, 0.66)
	elif value < 0.6:
		return 0.6 / pow(1.0 + 0.6 - value, 1.6)
	else:
		return value


# Generates a random crit count. Different number every
# time.
func _generate_crit_count(bonus_multicrit: float, bonus_chance: float) -> int:
	var multicrit_count_max: int = get_prop_multicrit_count() + int(bonus_multicrit)
	var crit_chance: float = get_prop_atk_crit_chance() + bonus_chance

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

	return crit_count


# Same as calc_attack_multicrit(), but accepts an already
# calculated crit count. Used by Tower.
func _calc_attack_multicrit_internal(crit_count: int, bonus_damage: float) -> float:
	var crit_damage: float = get_prop_atk_crit_damage() + bonus_damage

# 	NOTE: subtract 1.0 from crit_damage, so we do
#	1.0 + 0.5 + 0.5 + 0.5...
# 	not
#	1.0 + 1.5 + 1.5 + 1.5...
	var total_crit_damage: float = 1.0 + (crit_damage - 1.0) * crit_count

	total_crit_damage = max(0.0, total_crit_damage)

	return total_crit_damage


# Set node which will be used to determine the visual
# position of the unit.
func _set_visual_node(visual_node: Node2D):
	_visual_node = visual_node
	_visual_node.modulate = _stored_visual_modulate


# Call this in subclass to set dimensions of unit. Use
# Utils.get_sprite_dimensions() or
# Utils.get_animated_sprite_dimensions() to get the
# dimensions of the sprite in subclass. This will be used to
# calculate positions of different body parts of the unit.
func _set_unit_dimensions(sprite_dimensions: Vector2):
	_sprite_dimensions = sprite_dimensions

	_selection_visual.visual_size = _sprite_dimensions.x


func set_hovered(hovered: bool):
	if _selected:
		return

	_selection_visual.modulate = Color.WHITE
	_selection_visual.set_visible(hovered)


# NOTE: override this in subclass to attach trigger handlers
# to triggers buff passed in the argument.
func load_triggers(_triggers_buff_type: BuffType):
	pass


# NOTE: analog of SetUnitState(unit, UNIT_STATE_MANA) in JASS
func set_mana(new_mana: float):
	var overall_mana: float = get_overall_mana()
	_mana = clampf(new_mana, 0.0, overall_mana)
	mana_changed.emit()


# NOTE: analog of SetUnitState(unit, UNIT_STATE_LIFE) in JASS
func set_health(new_health: float):
	var overall_health: float = get_overall_health()
	_health = clampf(new_health, 0.0, overall_health)
	health_changed.emit()


func set_health_over_max(new_health: float):
	_health = max(new_health, 0.0)
	health_changed.emit()


func _get_aoe_damage(aoe_center: Vector2, target: Unit, radius: float, damage: float, sides_ratio: float) -> float:
	var distance: float = Isometric.vector_distance_to(aoe_center, target.position)
	var target_is_on_the_sides: bool = (distance / radius) > 0.5

	if target_is_on_the_sides:
		return damage * (1.0 - sides_ratio)
	else:
		return damage


func _on_regen_timer_timeout():
	var mana_regen: float = get_overall_mana_regen()
	set_mana(_mana + mana_regen)

	var health_regen: float = get_overall_health_regen()
	set_health(_health + health_regen)


func _do_attack(attack_event: Event):
	attack.emit(attack_event)

	var target = attack_event.get_target()
	target._receive_attack()


func _receive_attack():
	var attacked_event: Event = Event.new(self)
	attacked.emit(attacked_event)


func _do_damage(target: Unit, damage_base: float, damage_source: DamageSource) -> bool:
	var size_mod: float = _get_damage_mod_for_creep_size(target)
	var category_mod: float = _get_damage_mod_for_creep_category(target)
	var armor_type_mod: float = _get_damage_mod_for_creep_armor_type(target)

	var damage: float = damage_base * size_mod * category_mod * armor_type_mod

# 	NOTE: all spell damage is reduced by this amount
	if damage_source == DamageSource.Spell:
		damage *= Constants.SPELL_DAMAGE_RATIO
		
# 	Immune creeps take 0 damage from spells
	if damage_source == DamageSource.Spell && target.is_immune():
		damage = 0

	var damaged_event: Event = Event.new(self)
	damaged_event.damage = damage
	damaged_event._is_spell_damage = damage_source == DamageSource.Spell
	target.damaged.emit(damaged_event)

# 	NOTE: update damage value because it could've been
# 	altered by event handlers of target's "damaged" event
	damage = damaged_event.damage

#	NOTE: record stats about damage only for attack damage
	if damage_source == DamageSource.Attack:
		_damage_dealt_total += damage

		if damage > _best_hit:
			_best_hit = damage

	var health_before_damage: float = target.get_health()
	target.set_health(health_before_damage - damage)

	Globals.add_to_total_damage(damage)

	if Config.damage_numbers():
		get_player().display_floating_text_color(str(int(damage)), target, Color.RED, 1.0)

	var health_after_damage: float = target.get_health()
	var damage_killed_unit: bool = health_before_damage > 0 && health_after_damage <= 0

	if damage_killed_unit:
		target._killed_by_unit(self)

	return damage_killed_unit


# Called when unit killed by caster unit
func _killed_by_unit(caster: Unit):
# 	NOTE: need to use explicit "is_dead" flag. Calling
# 	queue_free() makes is_instance_valid(unit) return false
# 	but that happens only at the end of the current frame.
# 	Other signals/slots might fire before that point and
# 	they need to know if the unit is dead to avoid
# 	processing it.
	_is_dead = true

	var death_event: Event = Event.new(caster)
	death.emit(death_event)

	if caster != null:
		caster._accept_kill(self)

	var caster_item_chance: float = caster.get_item_drop_ratio()
	var target_item_chance: float = get_item_drop_ratio_on_death()
	var item_chance: float = BASE_ITEM_DROP_CHANCE * caster_item_chance * target_item_chance

	var creep: Creep = self as Creep

	if creep != null:
		var creep_size: CreepSize.enm = creep.get_size()
		var item_drop_roll_count: int = CreepSize.get_item_drop_roll_count(creep_size)
		
		if Config.always_drop_items():
			item_drop_roll_count = 1
			item_chance = 1.0
		
		for i in range(0, item_drop_roll_count):
			var item_dropped: bool = Utils.rand_chance(item_chance)

			if item_dropped:
				creep.drop_item(caster, false)

	queue_free()


# Called when unit kills target unit
func _accept_kill(target: Unit):
	var experience_gained: float = _get_experience_for_target(target)
	_change_experience(experience_gained)

	var bounty_gained: int = _get_bounty_for_target(target)
	get_player().give_gold(bounty_gained, target, false, true)

	_kill_count += 1

	var kill_event: Event = Event.new(target)
	kill.emit(kill_event)


# This is for internal use in Buff.gd only. For external
# use, call Buff.apply_to_unit().
func _add_buff_internal(buff: Buff):
	var buff_type: String = buff.get_type()
	_buff_type_map[buff_type] = buff

	var stacking_group: String = buff.get_stacking_group()
	_buff_group_map[stacking_group] = buff

	var friendly: bool = buff.is_friendly()
	_get_buff_list(friendly).append(buff)
	var buff_modifier: Modifier = buff.get_modifier()
	_apply_modifier(buff_modifier, buff.get_power(), 1)
	add_child(buff)
	
	buff_list_changed.emit()


func _apply_modifier(modifier: Modifier, power: int, modify_direction: int):
	var modification_list: Array = modifier.get_modification_list()

	for modification in modification_list:
		var power_bonus: float = modification.level_add * power
		var value: float = modification.value_base + power_bonus

		_modify_property_internal(modification.type, value, modify_direction)


func _update_invisible_modulate():
	if is_invisible():
		modulate = INVISIBLE_MODULATE
	else:
		modulate = Color(1, 1, 1, 1)


func _get_bounty_for_target(target: Unit) -> int:
	if !target is Creep:
		return 0

	var tower: Unit = self
	var creep: Creep = target as Creep
	var creep_size: CreepSize.enm = creep.get_size()
	var gold_multiplier: float = CreepSize.get_gold_multiplier(creep_size)
	var spawn_level: int = creep.get_spawn_level()
	var bounty_base: float = gold_multiplier * (spawn_level / 8 + 1)
	var granted_mod: float = creep.get_prop_bounty_granted()
	var received_mod: float = tower.get_prop_bounty_received()
	var bounty: int = floori(bounty_base * granted_mod * received_mod)

	return bounty


func _get_experience_for_target(target: Unit) -> float:
	if !target is Creep:
		return 0

	var tower: Unit = self
	var creep: Creep = target as Creep
	var creep_size: CreepSize.enm = creep.get_size()
	var experience_base: float = CreepSize.get_experience(creep_size)
	var granted_mod: float = creep.get_prop_exp_granted()
	var received_mod: float = tower.get_prop_exp_received()
	var experience: float = experience_base * granted_mod * received_mod

	return experience


func _get_buff_list(friendly: bool) -> Array[Buff]:
	if friendly:
		return _friendly_buff_list
	else:
		return _unfriendly_buff_list


#########################
###     Callbacks     ###
#########################

func _remove_buff_internal(buff: Buff):
	var buff_modifier: Modifier = buff.get_modifier()
	_apply_modifier(buff_modifier, buff.get_power(), -1)

	var buff_type: String = buff.get_type()
	_buff_type_map.erase(buff_type)

	var stacking_group: String = buff.get_stacking_group()
	_buff_group_map.erase(stacking_group)

	var friendly: bool = buff.is_friendly()
	_get_buff_list(friendly).erase(buff)
	buff_list_changed.emit()

func _on_modify_property():
	pass


#########################
### Setters / Getters ###
#########################

# NOTE: use this instead of changing modulate directly for
# Unit node. This version will not affect colors for
# selection visual and health bars.
# NOTE: SetUnitVertexColor() in JASS
func set_visual_modulate(new_modulate: Color):
	_stored_visual_modulate = new_modulate

	if _visual_node != null:
		_visual_node.modulate = new_modulate


# NOTE: overriden in Tower to return non-null value
func get_current_target() -> Unit:
	return null


# NOTE: unit.isImmune() in JASS
func is_immune() -> bool:
	return _immune


func set_immune(immune: bool):
	_immune = immune


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


func _change_modifier_level(modifier: Modifier, old_level: int, new_level: int):
	_apply_modifier(modifier, old_level, -1)
	_apply_modifier(modifier, new_level, 1)


func is_dead() -> bool:
	return _is_dead


# NOTE: use this instead of regular Node2D.position for
# anything involving visual effects, so projectiles and
# spell effects. Do NOT use visual position for game
# "physics", for example calculating distance between units.
# Game physics need to be performed in 2D space, so use
# regular "position".
func get_visual_position() -> Vector2:
	if _visual_node != null:
		return _visual_node.global_position
	else:
		return global_position

# Returns approximate position of the body part of unit in
# the world. Accepts "origin", "chest" or "head".
# NOTE: body parts were used in original API based on
# coordinates of body parts of 3D models. Approximate this
# feature for 2d tiles by defining body part positions as:
# "origin" = bottom of sprite
# "chest" = middle of sprite
# "head" = top of sprite
# Note that "sprite" here means the occupied part of the
# texture. Some sprites occupy only a small portion of the
# total texture so using texture center/dimensions would
# cause incorrect results.
func get_body_part_position(body_part: String) -> Vector2:
	if _visual_node == null:
		print_debug("No selection area2d defined")

		return get_visual_position()

	var sprite_center: Vector2 = _visual_node.global_position
	var sprite_height: float = float(_sprite_dimensions.y)

	match body_part:
		"head": return sprite_center - Vector2(0, sprite_height / 2)
		"chest": return sprite_center
		"origin": return sprite_center + Vector2(0, sprite_height / 2)
		_:
			push_error("Unhandled body part: ", body_part)

			return get_visual_position()

# NOTE: unit.getX() in JASS
func get_x() -> float:
	return position.x


# NOTE: unit.getY() in JASS
func get_y() -> float:
	return position.y


# NOTE: Getters for mod values are used in TowerInfo.
# Getter names need to match the names of label nodes that
# display the values. For example if getter name is
# get_prop_trigger_chances(), then label name must be
# PropTriggerChances.

func get_prop_buff_duration() -> float:
	return get_prop_with_diminishing_returns(Modification.Type.MOD_BUFF_DURATION)

func get_prop_debuff_duration() -> float:
	return get_prop_with_diminishing_returns(Modification.Type.MOD_DEBUFF_DURATION)

func get_prop_atk_crit_chance() -> float:
	return max(0, _mod_value_map[Modification.Type.MOD_ATK_CRIT_CHANCE])

func get_prop_atk_crit_damage() -> float:
	return max(1.0, _mod_value_map[Modification.Type.MOD_ATK_CRIT_DAMAGE])

# Returns the value of the average damage multipler based on crit chance, crit damage
# and multicrit count of the tower
func get_crit_multiplier() -> float:
	return 1 + get_prop_atk_crit_chance() * get_prop_atk_crit_damage()

func get_prop_bounty_received() -> float:
	return get_prop_with_diminishing_returns(Modification.Type.MOD_BOUNTY_RECEIVED)

func get_prop_bounty_granted() -> float:
	return max(0, _mod_value_map[Modification.Type.MOD_BOUNTY_GRANTED])

func get_prop_exp_received() -> float:
	return get_prop_with_diminishing_returns(Modification.Type.MOD_EXP_RECEIVED)

func get_prop_exp_granted() -> float:
	return max(0, _mod_value_map[Modification.Type.MOD_EXP_GRANTED])

func get_damage_to_air() -> float:
	return max(0, _mod_value_map[Modification.Type.MOD_DMG_TO_AIR])

func get_damage_to_boss() -> float:
	return max(0, _mod_value_map[Modification.Type.MOD_DMG_TO_BOSS])

func get_damage_to_mass() -> float:
	return max(0, _mod_value_map[Modification.Type.MOD_DMG_TO_MASS])

func get_damage_to_normal() -> float:
	return max(0, _mod_value_map[Modification.Type.MOD_DMG_TO_NORMAL])

func get_damage_to_champion() -> float:
	return max(0, _mod_value_map[Modification.Type.MOD_DMG_TO_CHAMPION])

func get_damage_to_undead() -> float:
	return max(0, _mod_value_map[Modification.Type.MOD_DMG_TO_UNDEAD])

func get_damage_to_humanoid() -> float:
	return max(0, _mod_value_map[Modification.Type.MOD_DMG_TO_HUMANOID])

func get_damage_to_nature() -> float:
	return max(0, _mod_value_map[Modification.Type.MOD_DMG_TO_NATURE])

func get_damage_to_magic() -> float:
	return max(0, _mod_value_map[Modification.Type.MOD_DMG_TO_MAGIC])

func get_damage_to_orc() -> float:
	return max(0, _mod_value_map[Modification.Type.MOD_DMG_TO_ORC])

func get_exp_ratio() -> float:
	return get_prop_exp_received()

func get_item_drop_ratio() -> float:
	return get_prop_with_diminishing_returns(Modification.Type.MOD_ITEM_CHANCE_ON_KILL)

func get_item_quality_ratio() -> float:
	return get_prop_with_diminishing_returns(Modification.Type.MOD_ITEM_QUALITY_ON_KILL)

func get_item_drop_ratio_on_death() -> float:
	return max(0, _mod_value_map[Modification.Type.MOD_ITEM_CHANCE_ON_DEATH])

func get_item_quality_ratio_on_death() -> float:
	return max(0, _mod_value_map[Modification.Type.MOD_ITEM_QUALITY_ON_DEATH])

func get_prop_trigger_chances() -> float:
	return get_prop_with_diminishing_returns(Modification.Type.MOD_TRIGGER_CHANCES)

func get_prop_multicrit_count() -> int:
	return int(max(0, _mod_value_map[Modification.Type.MOD_MULTICRIT_COUNT]))

func get_prop_spell_damage_dealt() -> float:
	return max(0, _mod_value_map[Modification.Type.MOD_SPELL_DAMAGE_DEALT])

func get_prop_spell_damage_received() -> float:
	return max(0, _mod_value_map[Modification.Type.MOD_SPELL_DAMAGE_RECEIVED])

func get_spell_crit_chance() -> float:
	return max(0, _mod_value_map[Modification.Type.MOD_SPELL_CRIT_CHANCE])

func get_spell_crit_damage() -> float:
	return max(1.0, _mod_value_map[Modification.Type.MOD_SPELL_CRIT_DAMAGE])

# Returns current value of "attack speed" stat which scales
# tower's attack cooldown. Note that even though name
# contains "base", this f-n returns value which includes
# modifiers.
# 
# NOTE: do not allow attackspeed to go to 0 to prevent
# divisons by 0.
func get_base_attack_speed() -> float:
	return clampf(_mod_value_map[Modification.Type.MOD_ATTACKSPEED], 0.01, 100.0)

func get_level() -> int:
	return _level

func is_invisible() -> bool:
	return _invisible && _invisible_watcher_count == 0

func is_silenced() -> bool:
	return _silence_count > 0

func is_stunned() -> bool:
	return _stunned

# NOTE: overriden in Tower and Creep subclasses
func is_attacking() -> bool:
	return false

# NOTE: unit.getBuffOfType() in JASS
func get_buff_of_type(buff_type: BuffType) -> Buff:
	var type: String = buff_type.get_type()
	var buff = _buff_type_map.get(type, null)

	return buff


# NOTE: unit.getBuffOfGroup() in JASS
func get_buff_of_group(stacking_group: String) -> Buff:
	var buff = _buff_group_map.get(stacking_group, null)

	return buff


# Removes the most recent buff. Returns true if there was a
# buff to remove and false otherwise.
# NOTE: unit.purgeBuff() in JASS
func purge_buff(friendly: bool) -> bool:
	var buff_list: Array[Buff] = _get_buff_list(friendly)

	var purgable_list: Array[Buff] = []

	for buff in buff_list:
		if buff.is_purgable():
			purgable_list.append(buff)

#	NOTE: buff is removed from the list further down the
#	chain from purge_buff() call.
	if !purgable_list.is_empty():
		var buff: Buff = purgable_list.back()
		buff.purge_buff()
		
		buff_list_changed.emit()
		return true
	else:
		return false


func set_base_mana(base_mana: float):
	_base_mana = base_mana


func get_base_mana() -> float:
	return _base_mana

func get_base_mana_bonus() -> float:
	return _mod_value_map[Modification.Type.MOD_MANA]

func get_base_mana_bonus_percent() -> float:
	return max(0, _mod_value_map[Modification.Type.MOD_MANA_PERC])

# NOTE: analog of GetUnitState(unit, UNIT_STATE_MAX_MANA) in JASS
func get_overall_mana() -> float:
	return max(0, (get_base_mana() + get_base_mana_bonus()) * get_base_mana_bonus_percent())

# Returns current percentage of mana
func get_mana_ratio() -> float:
	var overall_mana: float = get_overall_mana()
	var ratio: float = Utils.get_ratio(_mana, overall_mana)

	return ratio


func set_base_mana_regen(base_mana_regen: float):
	_base_mana_regen = base_mana_regen

func get_base_mana_regen() -> float:
	return _base_mana_regen

func get_base_mana_regen_bonus() -> float:
	return max(0, _mod_value_map[Modification.Type.MOD_MANA_REGEN])

func get_base_mana_regen_bonus_percent() -> float:
	return max(0, _mod_value_map[Modification.Type.MOD_MANA_REGEN_PERC])

func get_overall_mana_regen() -> float:
	return (get_base_mana_regen() + get_base_mana_regen_bonus()) * get_base_mana_regen_bonus_percent()

# NOTE: analog of GetUnitState(unit, UNIT_STATE_LIFE) in JASS
func get_health() -> float:
	return _health

func get_base_health() -> float:
	return _base_health

func set_base_health(value: float):
	_base_health = value

func get_base_health_bonus() -> float:
	return _mod_value_map[Modification.Type.MOD_HP]

func get_base_health_bonus_percent() -> float:
	return max(0, _mod_value_map[Modification.Type.MOD_HP_PERC])

# NOTE: do not allow max hp to go below 1 because that
# doesn't make sense and the combat system won't work
# correctly if a unit has max hp of 0
# NOTE: analog of GetUnitState(unit, UNIT_STATE_MAX_LIFE) in JASS
func get_overall_health() -> float:
	return max(1, (get_base_health() + get_base_health_bonus()) * get_base_health_bonus_percent())

# Returns current percentage of health
func get_health_ratio() -> float:
	var overall_health: float = get_overall_health()
	var ratio: float = Utils.get_ratio(_health, overall_health)

	return ratio

func get_base_health_regen():
	return _base_health_regen

func get_base_health_regen_bonus() -> float:
	return max(0, _mod_value_map[Modification.Type.MOD_HP_REGEN])

func get_base_health_regen_bonus_percent() -> float:
	return max(0, _mod_value_map[Modification.Type.MOD_HP_REGEN_PERC])

func get_overall_health_regen() -> float:
	return (get_base_health_regen() + get_base_health_regen_bonus()) * get_base_health_regen_bonus_percent()

func get_prop_move_speed() -> float:
	return max(0, _mod_value_map[Modification.Type.MOD_MOVESPEED])

func get_prop_move_speed_absolute() -> float:
	return _mod_value_map[Modification.Type.MOD_MOVESPEED_ABSOLUTE]

func get_prop_atk_damage_received() -> float:
	return max(0, _mod_value_map[Modification.Type.MOD_ATK_DAMAGE_RECEIVED])

func get_display_name() -> String:
	return "Generic Unit"

func is_selected() -> bool:
	return _selected

func set_selected(selected_arg: bool):
	var selection_color: Color
	if self is Creep:
		selection_color = Color.RED
	else:
		selection_color = Color.GREEN

	_selection_visual.modulate = selection_color
	_selection_visual.set_visible(selected_arg)
	_selected = selected_arg

	if selected_arg:
		selected.emit()
	else:
		unselected.emit()

# Implemented by Tower and Creep to return tower element or
# creep category
# NOTE: because Tower and Creep return different enum types
# have to use typing for int here.
# 
# NOTE: unit.getCategory() in JASS
func get_category() -> int:
	return 0

func get_base_damage_bonus() -> float:
	return _mod_value_map[Modification.Type.MOD_DAMAGE_BASE]

func get_base_damage_bonus_percent() -> float:
	return max(0, _mod_value_map[Modification.Type.MOD_DAMAGE_BASE_PERC])

func get_damage_add() -> float:
	return max(0, _mod_value_map[Modification.Type.MOD_DAMAGE_ADD])

func get_damage_add_percent() -> float:
	return max(0, _mod_value_map[Modification.Type.MOD_DAMAGE_ADD_PERC])

func get_base_armor_damage_reduction() -> float:
	var armor: float = get_base_armor()
	var coeff: float = Constants.ARMOR_COEFFICIENT
	var reduction: float = min(1.0, (armor * coeff) / (1.0 + armor * coeff))

	return reduction

func get_current_armor_damage_reduction() -> float:
	var armor: float = get_overall_armor()
	var coeff: float = Constants.ARMOR_COEFFICIENT
	var reduction: float = min(1.0, (armor * coeff) / (1.0 + armor * coeff))

	return reduction

# NOTE: analog of GetUnitState(unit, UNIT_STATE_MANA) in JASS
func get_mana() -> float:
	return _mana

func set_base_armor(value: float):
	_base_armor = value

func get_base_armor() -> float:
	return _base_armor

func get_base_armor_bonus() -> float:
	return _mod_value_map[Modification.Type.MOD_ARMOR]

func get_base_armor_bonus_percent() -> float:
	return max(0, _mod_value_map[Modification.Type.MOD_ARMOR_PERC])

func get_overall_armor() -> float:
	return (get_base_armor() + get_base_armor_bonus()) * get_base_armor_bonus_percent()

func get_overall_armor_bonus() -> float:
	return (get_base_armor() + get_base_armor_bonus()) * get_base_armor_bonus_percent() - get_base_armor()

func get_dps_bonus() -> float:
	return _mod_value_map[Modification.Type.MOD_DPS_ADD]

func _get_damage_mod_for_creep_category(creep: Creep) -> float:
	const creep_category_to_mod_map: Dictionary = {
		CreepCategory.enm.UNDEAD: Modification.Type.MOD_DMG_TO_MASS,
		CreepCategory.enm.MAGIC: Modification.Type.MOD_DMG_TO_MAGIC,
		CreepCategory.enm.NATURE: Modification.Type.MOD_DMG_TO_NATURE,
		CreepCategory.enm.ORC: Modification.Type.MOD_DMG_TO_ORC,
		CreepCategory.enm.HUMANOID: Modification.Type.MOD_DMG_TO_HUMANOID,
		CreepCategory.enm.CHALLENGE: Modification.Type.MOD_DMG_TO_CHALLENGE,
	}

	var creep_category: CreepCategory.enm = creep.get_category() as CreepCategory.enm
	var mod_type: Modification.Type = creep_category_to_mod_map[creep_category]
	var damage_mod: float = _mod_value_map[mod_type]

	return damage_mod

func _get_damage_mod_for_creep_armor_type(creep: Creep) -> float:
	var attack_type: AttackType.enm = get_attack_type()
	var armor_type: ArmorType.enm = creep.get_armor_type()
	var damage_mod: float = AttackType.get_damage_against(attack_type, armor_type)

	return damage_mod

func _get_damage_mod_for_creep_size(creep: Creep) -> float:
	const creep_size_to_mod_map: Dictionary = {
		CreepSize.enm.MASS: Modification.Type.MOD_DMG_TO_MASS,
		CreepSize.enm.NORMAL: Modification.Type.MOD_DMG_TO_NORMAL,
		CreepSize.enm.CHAMPION: Modification.Type.MOD_DMG_TO_CHAMPION,
		CreepSize.enm.BOSS: Modification.Type.MOD_DMG_TO_BOSS,
		CreepSize.enm.AIR: Modification.Type.MOD_DMG_TO_AIR,
		CreepSize.enm.CHALLENGE_MASS: Modification.Type.MOD_DMG_TO_MASS,
		CreepSize.enm.CHALLENGE_BOSS: Modification.Type.MOD_DMG_TO_BOSS,
	}

	var creep_size: CreepSize.enm = creep.get_size()
	var mod_type: Modification.Type = creep_size_to_mod_map[creep_size]
	var damage_mod: float = _mod_value_map[mod_type]

	return damage_mod

func get_attack_type() -> AttackType.enm:
	return AttackType.enm.PHYSICAL

func get_exp() -> float:
	return _experience


func reached_max_level() -> bool:
	var is_max_level: bool = _level == Constants.MAX_LEVEL

	return is_max_level


# Changes experience of unit. Change can be positive or
# negative. Level will also be changed accordingly. Note
# that level downs are possible.
# TODO: should level_up event trigger multiple times for
# same level if tower levels down and then back up?
func _change_experience(amount: float) -> float:
	var old_exp: float = _experience
	var new_exp: float = max(0.0, _experience + amount)
	var actual_change = new_exp - old_exp
	var old_level: int = _level
	var new_level: int = Experience.get_level_at_exp(new_exp)

	_experience = new_exp

	var level_has_changed: bool = new_level != old_level
	
	if level_has_changed:
		set_level(new_level)
		level_changed.emit()

	var leveled_up: bool = new_level > old_level

	if leveled_up:
		level_up.emit()

		var effect_id: int = Effect.create_simple_at_unit("res://Scenes/Effects/LevelUp.tscn", self)
		var effect_scale: float = max(_sprite_dimensions.x, _sprite_dimensions.y) / Constants.LEVEL_UP_EFFECT_SIZE
		Effect.scale_effect(effect_id, effect_scale)
		Effect.destroy_effect_after_its_over(effect_id)

		var level_up_text: String = "Level %d" % _level
		get_player().display_floating_text_color(level_up_text, self, Color.GOLD , 1.0)

		SFX.sfx_at_unit("res://Assets/SFX/level_up.mp3", self)
	else:
# 		NOTE: display floating text for exp amount only if
# 		didn't level up to avoid overlapping of the two
# 		floating texts
		var sign_string: String
		if amount >= 0:
			sign_string = "+"
		else:
			sign_string = "-"
		var number_string: String = String.num(abs(amount), 1)
		var exp_text: String = "%s%s exp" % [sign_string, number_string]
		var text_color: Color
		if amount >= 0:
			text_color = Color.LIME_GREEN
		else:
			text_color = Color.RED

		get_player().display_floating_text_color(exp_text, self, text_color, 1.0)

	return actual_change
