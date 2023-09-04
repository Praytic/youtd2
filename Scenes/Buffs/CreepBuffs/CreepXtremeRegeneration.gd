class_name CreepXtremeRegeneration extends BuffType


var _regen_ratio_map: Dictionary = {
	CreepSize.enm.MASS: 0.175,
	CreepSize.enm.NORMAL: 0.0875,
	CreepSize.enm.AIR: 0.1,
	CreepSize.enm.CHAMPION: 0.078,
	CreepSize.enm.BOSS: 0.025,
	CreepSize.enm.CHALLENGE_MASS: 0.0,
	CreepSize.enm.CHALLENGE_BOSS: 0.0,
}


func _init(parent: Node):
	super("creep_xtreme_regeneration", 0, 0, true, parent)
	add_event_on_create(on_create)


func on_create(event: Event):
	CreepRegeneration.regen_special_on_create(event, _regen_ratio_map)
