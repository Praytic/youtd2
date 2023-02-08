class_name Unit
extends KinematicBody2D


signal selected
signal unselected
signal level_up
signal attack(event)
signal attacked(event)
signal damage(event)
signal damaged(event)
signal kill(event)
signal death(event)

# Unit implements application of buffs and modifications.

# NOTE: can't use static typing for Buff because of cyclic
# dependency


var _level: int = 1 setget set_level, get_level
var _buff_map: Dictionary
var _modifier_list: Array
var _health: float = 100.0


func _ready():
	pass


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


# TODO: implement
func is_immune() -> bool:
	return false


# TODO: implement, needs to be affected by bonuses to chance
func calc_chance(chance: float) -> bool:
	return Utils.rand_chance(chance)


# TODO: implement, probably calculates total modifier from
# crit without multi-crit?
func calc_spell_crit_no_bonus() -> float:
	return 0.0


# TODO: implement. is_main_target parameter doesn't exist in
# original api, not sure how to do without it
func do_spell_damage(target: Unit, damage: float, _crit_mod: float, is_main_target: int):
	_do_damage(target, damage, is_main_target)


func add_modifier(modifier: Modifier):
	_apply_modifier(modifier, 1)
	_modifier_list.append(modifier)


# TODO: not sure how to implement remove_modifier(). Maybe
# assign modifiers an id in add_modifier()? Need to see
# concrete use case for removing modifiers first. Will
# probably encounter it when implementing items.


func set_level(new_level: int):
	_level = new_level

#	NOTE: apply level change to modifiers
	for modifier in _modifier_list:
		_apply_modifier(modifier, -1)
		modifier.level = new_level
		_apply_modifier(modifier, 1)

	emit_signal("level_up")


func get_level() -> int:
	return _level


func kill_instantly(target: Unit):
	_do_damage(target, target._health, Event.IsMainTarget.YES)


func modify_property(modification_type: int, value: float):
	_modify_property(modification_type, value)


func _do_attack(target: Unit):
	var attack_event: Event = Event.new()
	attack_event.target = target
	emit_signal("attack", attack_event)

	target._receive_attack()


func _receive_attack():
	var attacked_event: Event = Event.new()
	attacked_event.target = self
	emit_signal("attacked", attacked_event)


func _do_damage(target: Unit, damage: float, is_main_target: int):
	var damage_event: Event = Event.new()
	damage_event.damage = damage
	damage_event.target = target
	damage_event.is_main_target = is_main_target
	emit_signal("damage", damage_event)

	target._receive_damage(self, damage_event.damage, is_main_target)


func _receive_damage(caster: Unit, damage: float, is_main_target: int):
	_health -= damage

	var damaged_event: Event = Event.new()
	damaged_event.target = caster
	damaged_event.damage = damage
	damaged_event.is_main_target = is_main_target
	emit_signal("damaged", damaged_event)

	if _health < 0:
		var death_event: Event = Event.new()
		death_event.target = caster
		death_event.damage = damage
		death_event.is_main_target = is_main_target
		emit_signal("death", death_event)

		caster._accept_kill(self, is_main_target)

		queue_free()

		return


# Called when unit kills another unit
func _accept_kill(target: Unit, is_main_target: int):
	var kill_event: Event = Event.new()
	kill_event.target = target
	kill_event.is_main_target = is_main_target
	emit_signal("kill", kill_event)


func _on_buff_removed(buff):
	var buff_modifier: Modifier = buff.get_modifier()
	_apply_modifier(buff_modifier, -1)

	var buff_id: String = buff.get_id()
	_buff_map.erase(buff_id)
	buff.queue_free()


func _modify_property(_modification_type: int, _value: float):
	pass


func _apply_modifier(modifier: Modifier, apply_direction: int):
	var modification_list: Array = modifier.get_modification_list()

	for modification in modification_list:
		var level_bonus: float = 1.0 + modification.level_add * (modifier.level - 1)
		var value: float = apply_direction * modification.value_base * level_bonus
		_modify_property(modification.type, value)
