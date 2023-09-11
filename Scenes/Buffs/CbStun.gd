class_name CbStun
extends BuffType

# NOTE: analog of globally available cb_stun in JASS


# NOTE: BuffType.createDuplicate(cb_stun...) in JASS
func _init(type: String, time_base: float, time_level_add: float,friendly: bool, parent: Node):
	super(type, time_base, time_level_add, friendly, parent)
	add_event_on_create(on_create)
	add_event_on_cleanup(_on_cleanup)

	set_stacking_group("stun")

#	NOTE: this is the default tooltip for stun buff. It may
#	be overriden in buffs that extend this buff.
	set_buff_tooltip("Stun\nThis unit is stunned; it can't perform any actions.")


func on_create(event: Event):
	var buff: Buff = event.get_buff()
	var target = buff.get_buffed_unit()

	target.add_stun()


func _on_cleanup(event: Event):
	var buff: Buff = event.get_buff()
	var target = buff.get_buffed_unit()

	target.remove_stun()
