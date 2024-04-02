# Liquid Gold
extends ItemBehavior


var drol_liquid_gold_bt: BuffType
var cb_stun: BuffType


func get_ability_description() -> String:
	var text: String = ""

	text += "[color=GOLD]Hangover[/color]\n"
	text += "Each attack has a 10% attackspeed adjusted chance to give the user a hangover, slowing its attackspeed by 30% for 8 seconds and stunning it for 3 seconds when it expires.\n"
	text += " \n"
	text += "[color=ORANGE]Level Bonus:[/color]\n"
	text += "+1% attackspeed\n"
	text += "-0.1 second stun duration\n"

	return text


func load_modifier(modifier: Modifier):
	modifier.add_modification(Modification.Type.MOD_DAMAGE_ADD_PERC, 0.35, 0.0)


func load_triggers(triggers: BuffType):
	triggers.add_event_on_attack(on_attack)


# NOTE: drolDrunk() in original script
func drol_liquid_gold_bt_on_expire(event: Event):
	var b: Buff = event.get_buff()
	var tower: Unit = b.get_caster()
	cb_stun.apply_only_timed(tower, tower, 3 - tower.get_level() * 0.1)


func item_init():
	cb_stun = CbStun.new("item_186_stun", 0, 0, false, self)
	
	drol_liquid_gold_bt = BuffType.new("drol_liquid_gold_bt", 8, 0, false, self)
	drol_liquid_gold_bt.set_buff_icon("orb_empty.tres")
	drol_liquid_gold_bt.set_buff_tooltip("Drunk\nReduces attack speed and stuns after a period of time.")
	drol_liquid_gold_bt.add_event_on_expire(drol_liquid_gold_bt_on_expire)
	var mod: Modifier = Modifier.new()
	mod.add_modification(Modification.Type.MOD_ATTACKSPEED, -0.30, 0.01)
	drol_liquid_gold_bt.set_buff_modifier(mod)


func on_attack(_event: Event):
	var tower: Tower = item.get_carrier()
	var speed: float = tower.get_base_attackspeed()

	if tower.calc_bad_chance(0.1 * speed):
		CombatLog.log_item_ability(item, null, "Hangover")
		drol_liquid_gold_bt.apply(tower, tower, tower.get_level())
