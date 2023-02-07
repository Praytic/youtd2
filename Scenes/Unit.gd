class_name Unit
extends KinematicBody2D


signal selected
signal unselected
signal dead
signal level_up
signal attack(event)
signal attacked(event)
signal damage(event)
signal damaged(event)

# Unit implements application of buffs and modifications.

# NOTE: can't use static typing for Buff because of cyclic
# dependency


var _level: int = 1 setget set_level, get_level
var _buff_map: Dictionary
var _modifier_list: Array
var _health: float = 100.0


func _ready():
	pass


func apply_buff(buff):
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
		buff.connect("expired", self, "_on_buff_expired", [buff])
		var buff_modifier: Modifier = buff.get_modifier()
		_apply_modifier(buff_modifier, 1)
		add_child(buff)
		buff.applied_successfully(self)


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


func die():
	emit_signal("dead")
	queue_free()


func do_attack(target: Unit):
	var attack_event: Event = Event.new()
	attack_event.target = target
	emit_signal("attack", attack_event)

	target.receive_attack()


func receive_attack():
	var attacked_event: Event = Event.new()
	attacked_event.target = self
	emit_signal("attacked", attacked_event)


func do_damage(target: Unit, damage: float):
	var damage_event: Event = Event.new()
	damage_event.damage = damage
	damage_event.target = target
	emit_signal("damage", damage_event)

	target.receive_damage(damage_event.damage)


func receive_damage(damage: float):
#	TODO: should the target of "damaged" event be the unit
#	that caused damage to the mob?
	var damaged_event: Event = Event.new()
	damaged_event.damage = damage
	emit_signal("damaged", damaged_event)
	
	_health -= damaged_event.damage

	if _health < 0:
		die()


func _on_buff_expired(buff):
	var buff_modifier: Modifier = buff.get_modifier()
	_apply_modifier(buff_modifier, -1)

	var buff_id: String = buff.get_id()
	_buff_map.erase(buff_id)
	buff.queue_free()


func modify_property(modification_type: int, value: float):
	_modify_property(modification_type, value)


func _modify_property(_modification_type: int, _value: float):
	pass


func _apply_modifier(modifier: Modifier, apply_direction: int):
	var modification_list: Array = modifier.get_modification_list()

	for modification in modification_list:
		var level_bonus: float = 1.0 + modification.level_add * (modifier.level - 1)
		var value: float = apply_direction * modification.value_base * level_bonus
		_modify_property(modification.type, value)
