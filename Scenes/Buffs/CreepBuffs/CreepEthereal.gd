class_name CreepEthereal extends BuffType


# TODO: find out the the value for period and duration
const ETHEREAL_PERIOD: float = 10.0
const ETHEREAL_DURATION: float = 5.0


var ethereal_active_buff: BuffType


func _init(parent: Node):
	super("creep_ethereal", 0, 0, true, parent)

	ethereal_active_buff = BuffType.new("creep_ethereal_active", ETHEREAL_DURATION, 0, true, self)
	ethereal_active_buff.add_event_on_damaged(on_damaged, 1.0, 0.0)
	ethereal_active_buff.set_buff_tooltip("Ethereal Active\nThis unit is currently ethereal. It is immune against physical attacks but takes 40% more damage from magic attacks and spells.")

	add_periodic_event(on_periodic, ETHEREAL_PERIOD)


func on_periodic(event: Event):
	var buff: Buff = event.get_buff()
	var creep: Unit = buff.get_buffed_unit()

	ethereal_active_buff.apply(creep, creep, 0)


func on_damaged(event: Event):
	if event.is_spell_damage():
		event.damage *= 1.4
	else:
		event.damage = 0
