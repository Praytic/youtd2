extends ItemBehavior


var drunk_bt: BuffType
var stun_bt: BuffType


func load_triggers(triggers: BuffType):
	triggers.add_event_on_attack(on_attack)


# NOTE: drolDrunk() in original script
func drunk_bt_on_expire(event: Event):
	var b: Buff = event.get_buff()
	var tower: Unit = b.get_caster()
	stun_bt.apply_only_timed(tower, tower, 3 - tower.get_level() * 0.1)


func item_init():
	stun_bt = CbStun.new("stun_bt", 0, 0, false, self)
	
	drunk_bt = BuffType.new("drunk_bt", 8, 0, false, self)
	drunk_bt.set_buff_icon("res://resources/icons/generic_icons/perpendicular_rings.tres")
	drunk_bt.set_buff_tooltip(tr("W9YO"))
	drunk_bt.add_event_on_expire(drunk_bt_on_expire)
	var mod: Modifier = Modifier.new()
	mod.add_modification(ModificationType.enm.MOD_ATTACKSPEED, -0.30, 0.01)
	drunk_bt.set_buff_modifier(mod)


func on_attack(_event: Event):
	var tower: Tower = item.get_carrier()
	var speed: float = tower.get_base_attack_speed()

	if tower.calc_bad_chance(0.1 * speed):
		CombatLog.log_item_ability(item, null, "Hangover")
		drunk_bt.apply(tower, tower, tower.get_level())
