class_name CreepDart extends BuffType


# TODO: how long do creeps dart? Set it to 2s for now

# TODO: what's the movespeed modifier while darting?


var creep_darting: BuffType
var creep_tired: BuffType


func _init(parent: Node):
	super("creep_dart", 0, 0, true, parent)

	add_event_on_damaged(on_damaged)

	var modifier: Modifier = Modifier.new()
	modifier.add_modification(Modification.Type.MOD_MOVESPEED, -0.60, 0.0)
	set_buff_modifier(modifier)

	creep_darting = BuffType.new("creep_darting", 2.0, 0, false, self
		)
	var darting_modifier: Modifier = Modifier.new()
	darting_modifier.add_modification(Modification.Type.MOD_MOVESPEED, 3.00, 0.0)
	creep_darting.set_buff_modifier(darting_modifier)
	creep_darting.set_buff_tooltip("Darting\nThis creep is Darting; it has increased movement speed!")
	creep_darting.add_event_on_cleanup(on_darting_cleanup)

	creep_tired = BuffType.new("creep_tired", 4.0, 0, false, self
		)
	creep_tired.set_buff_tooltip("Tired\nThis creep is tired; it can't dart for a period of time.")


func on_damaged(event: Event):
	var buff: Buff = event.get_buff()
	var creep: Unit = buff.get_buffed_unit()

	var active_darting: Buff = creep.get_buff_of_type(creep_darting)
	var active_tired: Buff = creep.get_buff_of_type(creep_tired)

	if active_darting == null && active_tired == null:
		creep_darting.apply(creep, creep, 0)



func on_darting_cleanup(event: Event):
	var buff: Buff = event.get_buff()
	var creep: Unit = buff.get_buffed_unit()

	creep_tired.apply(creep, creep, 0)
