class_name CbSilence
extends BuffType

# NOTE: globally available cb_silence in JASS


# NOTE: BuffType.createDuplicate(cb_silence...) in JASS
func _init(type: String, time_base: float, time_level_add: float,friendly: bool, parent: Node):
	super(type, time_base, time_level_add, friendly, parent)
	add_event_on_create(on_create)
	set_event_on_cleanup(_on_cleanup)

	set_buff_tooltip("Silence\nThis unit is silenced; it can't cast spells.")


func on_create(event: Event):
	var buff: Buff = event.get_buff()
	var target = buff.get_buffed_unit()

	target.add_silence()


func _on_cleanup(event: Event):
	var buff: Buff = event.get_buff()
	var target = buff.get_buffed_unit()

	target.remove_silence()
