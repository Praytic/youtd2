extends ItemBehavior


# NOTE: original script uses buff.userInt as a flag so that
# attack() f-n does nothing the first time it is called and
# does something the second time it is called. This is to
# solve some issue which exists in original script engine.
# In current engine this is not needed and causes a bug
# where follow up attack to happen twice. So it was removed.


var followup_bt: BuffType


func load_triggers(triggers: BuffType):
	triggers.add_event_on_attack(on_attack)


# NOTE: attack() in original
func followup_bt_on_attack(event: Event):
	var B: Buff = event.get_buff()
	var t: Tower = B.get_buffed_unit()

	t.add_modified_attack_crit(0.00, 0.5 + t.get_level() / 100.0)
	B.remove_buff()


func item_init():
	followup_bt = BuffType.new("followup_bt", 30, 0, true, self)
	followup_bt.set_buff_icon("res://resources/icons/generic_icons/hammer_drop.tres")
	followup_bt.set_buff_tooltip(tr("F6D7"))
	followup_bt.add_event_on_attack(followup_bt_on_attack)
	var mod: Modifier = Modifier.new()
	mod.add_modification(ModificationType.enm.MOD_ATTACKSPEED, 3.0, 0.04)
	followup_bt.set_buff_modifier(mod)


func on_attack(_event: Event):
	var tower: Tower = item.get_carrier()

	if !tower.calc_chance(0.1 + 0.004 * tower.get_level()):
		return

	CombatLog.log_item_ability(item, null, "Follow up")

	followup_bt.apply(item.get_carrier(), item.get_carrier(), item.get_carrier().get_level())
