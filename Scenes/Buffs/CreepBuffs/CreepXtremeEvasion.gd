class_name CreepXtremeEvasion extends BuffType


func _init(parent: Node):
	super("creep_xtreme_evasion", 0, 0, true, parent)
	add_event_on_damaged(on_damaged)


func on_damaged(event: Event):
	CreepEvasion.evasion_effect(event, 0.66)
