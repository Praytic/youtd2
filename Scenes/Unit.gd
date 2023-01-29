extends KinematicBody2D

class_name Unit

# Unit implements application of buffs and modifications.


var buff_map: Dictionary


func _ready():
	pass


func apply_buff(buff):
	var buff_id: String = buff.get_id()

	var is_already_applied_to_target: bool = buff_map.has(buff_id)

	if is_already_applied_to_target:
		var current_buff = buff_map[buff_id]
		var should_override: bool = buff.power_level >= current_buff.power_level

		if should_override:
			current_buff.stop()
			apply_buff_internal(buff)
	else:
		apply_buff_internal(buff)


# NOTE: applies buff without any checks for overriding
func apply_buff_internal(buff):
	var buff_id: String = buff.get_id()
	print("buff_id=", buff_id)
	buff_map[buff_id] = buff
	add_child(buff)
	buff.on_apply_success(self)

	buff.connect("expired", self, "on_buff_expired", [buff])


func on_buff_expired(buff):
	var buff_id: String = buff.get_id()
	buff_map.erase(buff_id)
