class_name CreepManaShield extends BuffType

# TODO: add explode visual and also make it so that there's
# no corpse.

static var _max_cost_map: Dictionary = {
	CreepSize.enm.MASS: 3,
	CreepSize.enm.NORMAL: 6,
	CreepSize.enm.AIR: 12,
	CreepSize.enm.CHAMPION: 12,
	CreepSize.enm.BOSS: 12,
	CreepSize.enm.CHALLENGE_MASS: 0,
	CreepSize.enm.CHALLENGE_BOSS: 0,
}


func _init(parent: Node):
	super("creep_mana_shield", 0, 0, true, parent)

	add_event_on_damaged(on_damaged)


func on_damaged(event: Event):
	var spend_mana: bool = true
	CreepManaShield.shield_effect(event, spend_mana)


static func shield_effect(event: Event, spend_mana: bool):
	var caster: Unit = event.get_target()
	var buff: Buff = event.get_buff()
	var creep: Unit = buff.get_buffed_unit()

	var creep_size: CreepSize.enm = creep.get_size()
	var shield_cost_max: float = _max_cost_map[creep_size]
	var shield_cost: float = min(80 * event.damage / creep.get_overall_health(), shield_cost_max) * 100

	var mana_ratio = creep.get_mana_ratio()
	var damage_ratio: float = clampf(1.0 - 0.8 * mana_ratio, 0.2, 1.0)
	event.damage *= damage_ratio

	if spend_mana:
		creep.subtract_mana(shield_cost, false)

#	NOTE: when creep reaches 0 mana it's supposed to
#	explode. Simulate this by killing creep instantly.
	if creep.get_mana() == 0:
		caster.kill_instantly(creep)
