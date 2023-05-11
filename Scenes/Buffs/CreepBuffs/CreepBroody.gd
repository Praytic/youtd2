class_name CreepBroody extends BuffType


var creep_darting: BuffType
var creep_tired: BuffType


func _init(parent: Node):
	super("creep_broody", 0, 0, true, parent)

	add_event_on_damaged(on_damaged, 1.0, 0.0)

	var modifier: Modifier = Modifier.new()
	modifier.add_modification(Modification.Type.MOD_MOVESPEED, -0.60, 0.0)
	set_buff_modifier(modifier)

	creep_tired = BuffType.new("creep_tired", 6.0, 0, false, self
		)
	creep_tired.set_buff_tooltip("Tired\nThis creep is tired and cannot dart for a period of time.")

	creep_tired = BuffType.new("creep_tired", 6.0, 0, false, self
		)
	creep_tired.set_buff_tooltip("Tired\nThis creep is tired and cannot dart for a period of time.")


func on_damaged(event: Event):
	var buff: Buff = event.get_buff()
	var creep: Unit = buff.get_buffed_unit()

	var active_buff: Buff = creep.get_buff_of_type(creep_tired)

	if active_buff == null:
		creep_tired.apply(creep, creep, 0)

