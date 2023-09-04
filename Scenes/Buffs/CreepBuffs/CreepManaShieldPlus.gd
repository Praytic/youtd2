class_name CreepManaShieldPlus extends BuffType


func _init(parent: Node):
	super("creep_mana_shield_plus", 0, 0, true, parent)

	add_event_on_damaged(on_damaged)


func on_damaged(event: Event):
	var spend_mana: bool = false
	CreepManaShield.shield_effect(event, spend_mana)
