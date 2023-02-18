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

enum UnitProperty {
	TRIGGER_CHANCES,
	MOVE_SPEED,

#	Modifies buff durations for buffs cast by this unit
#	Applies to both friendly and unfriendly buffs
#	0.01 = +1% duration
	BUFF_DURATION,

#	Modifies buff durations for debuffs cast ONTO this unit
#	Debuffs are those with "friednly" set to false
#	0.01 = -1% duration
	DEBUFF_DURATION,
}


const MOVE_SPEED_MIN: float = 100.0
const MOVE_SPEED_MAX: float = 500.0

var _level: int = 1 setget set_level, get_level
var _buff_map: Dictionary
var _modifier_list: Array
var _specials_modifier_list: Array
var _health: float = 100.0
var _unit_properties: Dictionary = {
	UnitProperty.TRIGGER_CHANCES: 0.0,
	UnitProperty.MOVE_SPEED: MOVE_SPEED_MAX,
	UnitProperty.BUFF_DURATION: 0.0,
	UnitProperty.DEBUFF_DURATION: 0.0,
}

const _unit_mod_to_property_map: Dictionary = {
	Modification.Type.MOD_TRIGGER_CHANCES: UnitProperty.TRIGGER_CHANCES,
	Modification.Type.MOD_MOVE_SPEED_ABSOLUTE: UnitProperty.MOVE_SPEED,
	Modification.Type.MOD_BUFF_DURATION: UnitProperty.BUFF_DURATION,
	Modification.Type.MOD_DEBUFF_DURATION: UnitProperty.DEBUFF_DURATION,
	Modification.Type.MOD_MOVE_SPEED: UnitProperty.MOVE_SPEED,
}

func _ready():
	pass


# TODO: implement
func is_immune() -> bool:
	return false


func calc_chance(chance_base: float) -> bool:
	var chance_mod: float = _unit_properties[UnitProperty.TRIGGER_CHANCES]
	var chance: float = chance_base + chance_mod
	var success: bool = Utils.rand_chance(chance)

	return success


# "Bad" chance is for events that decrease tower's
# perfomance, for example missing attack. In such cases the
# "trigger chances" property decreases the chance of the
# event occuring.
func calc_bad_chance(chance_base: float) -> bool:
	var chance_mod: float = _unit_properties[UnitProperty.TRIGGER_CHANCES]
	var chance: float = chance_base - chance_mod
	var success: bool = Utils.rand_chance(chance)

	return success


# TODO: implement, probably calculates total modifier from
# crit without multi-crit?
func calc_spell_crit_no_bonus() -> float:
	return 0.0


# TODO: implement _crit_mod.
# 
# TODO: is it safe to call _receive_damage()? That f-n
# triggers DAMAGED event. If there's a tower which somehow
# debuffs a unit so that everytime it's DAMAGED, the tower
# damages it again, then there will be infinite recursion.
# So far only saw that towers deal additional damaged in
# event handlers for DAMAGE.
func do_spell_damage(target: Unit, damage: float, _crit_mod: float, is_main_target: bool):
	# NOTE: do not call _do_damage(), that can cause infinite recursion
	target._receive_damage(self, damage, is_main_target)


func add_modifier(modifier: Modifier):
	_apply_modifier(modifier, 1)
	_modifier_list.append(modifier)


# NOTE: this is for modifiers that tower applies to itself,
# modifiers applied like this will level together with the
# tower
# 
# TODO: might be a better way to do this. Maybe as part of a
# buff? But buffs aren't supposed to change level after
# creation.
func add_specials_modifier(modifier: Modifier):
	modifier.level = _level
	_apply_modifier(modifier, 1)
	_specials_modifier_list.append(modifier)


# TODO: not sure how to implement remove_modifier(). Maybe
# assign modifiers an id in add_modifier()? Need to see
# concrete use case for removing modifiers first. Will
# probably encounter it when implementing items.


func set_level(new_level: int):
	_level = new_level

#	NOTE: apply level change to specials modifiers
	for modifier in _specials_modifier_list:
		_apply_modifier(modifier, -1)
		modifier.level = new_level
		_apply_modifier(modifier, 1)

	emit_signal("level_up")


func get_buff_duration_mod() -> float:
	return _unit_properties[UnitProperty.BUFF_DURATION]


func get_debuff_duration_mod() -> float:
	return _unit_properties[UnitProperty.DEBUFF_DURATION]


func get_level() -> int:
	return _level


func kill_instantly(target: Unit):
	target._killed_by_unit(self, true)


func modify_property(modification_type: int, modification_value: float):
	_modify_property_general(_unit_properties, _unit_mod_to_property_map, modification_type, modification_value)

#	Call subclass version
	_modify_property_subclass(modification_type, modification_value)


# NOTE: important to store move speed without clamping and
# clamp only the value that is returned by getter to avoid
# overflow issues.
func get_move_speed() -> float:
	var unclamped_value: float = _unit_properties[UnitProperty.MOVE_SPEED]
	var move_speed: float = min(MOVE_SPEED_MAX, max(MOVE_SPEED_MIN, unclamped_value))

	return move_speed


# TODO: implement
func is_invisible() -> bool:
	return false


func _do_attack(target: Unit):
	var attack_event: Event = Event.new(target, 0, true)
	emit_signal("attack", attack_event)

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
	_health -= damage

	var damaged_event: Event = Event.new(caster, damage, is_main_target)
	emit_signal("damaged", damaged_event)

	Utils.display_floating_text_x(String(int(damage)), self, Color.red, 0.0, 0.0, 1.0)

	if _health <= 0:
		_killed_by_unit(caster, is_main_target)

		return


func _killed_by_unit(caster: Unit, is_main_target: bool):
	var death_event: Event = Event.new(caster, 0, is_main_target)
	emit_signal("death", death_event)

	caster._accept_kill(self, is_main_target)

	queue_free()


# Called when unit kills another unit
func _accept_kill(target: Unit, is_main_target: bool):
	var kill_event: Event = Event.new(target, 0, is_main_target)
	emit_signal("kill", kill_event)


func _on_buff_removed(buff):
	var buff_modifier: Modifier = buff.get_modifier()
	_apply_modifier(buff_modifier, -1)

	var buff_id: String = buff.get_id()
	_buff_map.erase(buff_id)
	buff.queue_free()


# This shouldn't be used directly, use Buff.apply_to_unit().
# Returns true if the buff was applied successfully. Buff
# can fail to apply if a stronger buff of same type is
# already active.
func _apply_buff(buff) -> bool:
	var buff_id: String = buff.get_id()

	var is_already_applied_to_target: bool = _buff_map.has(buff_id)
	
	var override_success: bool = false

	if is_already_applied_to_target:
		var current_buff = _buff_map[buff_id]
		var should_override: bool = buff.get_level() >= current_buff.get_level()

		if should_override:
			current_buff.stop()
			override_success = true

	if !is_already_applied_to_target || override_success:
		_buff_map[buff_id] = buff
		buff.connect("removed", self, "_on_buff_removed", [buff])
		var buff_modifier: Modifier = buff.get_modifier()
		_apply_modifier(buff_modifier, 1)
		add_child(buff)

		return true
	else:
		return false


func _modify_property_subclass(_modification_type: int, _modification_value: float):
	pass


# This f-n is used by Unit and Unit subclasses, because they
# have separate property maps and mod_to_property maps.
static func _modify_property_general(property_map: Dictionary, mod_to_property_map: Dictionary, modification_type: int, modification_value: float):
	var can_process_modification: bool = mod_to_property_map.has(modification_type)

	if !can_process_modification:
		return

	var property: int = mod_to_property_map[modification_type]
	var current_value: float = property_map[property]
	var new_value: float = 0.0

	var math_type: int = Modification.get_math_type(modification_type)

	match math_type:
		Modification.MathType.ADD:
			new_value = current_value + modification_value
		Modification.MathType.MULTIPLY:
			new_value = current_value * (1.0 + modification_value)

	property_map[property] = new_value


func _apply_modifier(modifier: Modifier, apply_direction: int):
	var modification_list: Array = modifier.get_modification_list()

	for modification in modification_list:
		var level_bonus: float = modification.level_add * (modifier.level - 1)
		var value: float = apply_direction * (modification.value_base + level_bonus)
		modify_property(modification.type, value)
