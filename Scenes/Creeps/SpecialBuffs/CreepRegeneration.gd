class_name CreepRegeneration extends BuffType


var _regen_ratio_map: Dictionary = {
	CreepSize.enm.MASS: 0.05,
	CreepSize.enm.NORMAL: 0.025,
	CreepSize.enm.AIR: 0.0285,
	CreepSize.enm.CHAMPION: 0.022,
	CreepSize.enm.BOSS: 0.007,
	CreepSize.enm.CHALLENGE_MASS: 0.0,
	CreepSize.enm.CHALLENGE_BOSS: 0.0,
}


func _init(parent: Node):
	super("creep_regeneration", 0, 0, true, parent)
	add_event_on_create(on_create)


func on_create(event: Event):
	CreepRegeneration.regen_special_on_create(event, _regen_ratio_map)


static func regen_special_on_create(event: Event, regen_ratio_map: Dictionary):
	var buff: Buff = event.get_buff()
	var creep: Unit = buff.get_buffed_unit()
	var creep_size: CreepSize.enm = creep.get_size()
	var creep_hp: float = creep.get_overall_health()
	var regen_ratio: float = regen_ratio_map[creep_size]
	var regen_value: float = creep_hp * regen_ratio

	creep.modify_property(Modification.Type.MOD_HP_REGEN, regen_value)
