# Crescent Stone
extends ItemBehavior


var earth_and_moon_bt: BuffType


func get_ability_description() -> String:
	var text: String = ""

	text += "[color=GOLD]Earth and Moon[/color]\n"
	text += "Every 15 seconds the carrier has its trigger chances increased by 25% for 5 seconds.\n"
	text += " \n"
	text += "[color=ORANGE]Level Bonus:[/color]\n"
	text += "+1% trigger chance\n"

	return text


func load_triggers(triggers: BuffType):
	triggers.add_periodic_event(periodic, 15)


func item_init():
	earth_and_moon_bt = BuffType.new("earth_and_moon_bt", 5, 0, true, self)
	earth_and_moon_bt.set_buff_icon("res://Resources/Textures/Buffs/star.tres")
	earth_and_moon_bt.set_buff_tooltip("Earth and Moon\nIncreases trigger chances.")
	var mod: Modifier = Modifier.new()
	mod.add_modification(Modification.Type.MOD_TRIGGER_CHANCES, 0.25, 0.01)
	earth_and_moon_bt.set_buff_modifier(mod)


func periodic(_event: Event):
	var tower: Tower = item.get_carrier()
	CombatLog.log_item_ability(item, null, "Earth and Moon")
	earth_and_moon_bt.apply(tower, tower, tower.get_level())
