# Writer's Knowledge
extends ItemBehavior


func get_ability_description() -> String:
	var text: String = ""

	text += "[color=GOLD]Learn[/color]\n"
	text += "Every 12 seconds the user of this item gains 1 experience.\n"

	return text


func load_modifier(modifier: Modifier):
	modifier.add_modification(Modification.Type.MOD_DAMAGE_ADD_PERC, 0.0, -0.008)
	modifier.add_modification(Modification.Type.MOD_EXP_RECEIVED, 0.40, -0.008)


func load_triggers(triggers: BuffType):
	triggers.add_periodic_event(periodic, 12)


func periodic(_event: Event):
	CombatLog.log_item_ability(item, null, "Learn")
	
	var tower: Unit = item.get_carrier()
	tower.add_exp(1)
