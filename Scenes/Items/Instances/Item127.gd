# Crescent Stone
extends Item


var drol_moonStone: BuffType


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
	var m: Modifier = Modifier.new()
	m.add_modification(Modification.Type.MOD_TRIGGER_CHANCES, 0.25, 0.01)

	drol_moonStone = BuffType.new("drol_moonStone", 5, 0, true, self)
	drol_moonStone.set_buff_icon("@@0@@")
	drol_moonStone.set_buff_modifier(m)
	drol_moonStone.set_buff_tooltip("Earth and Moon\nThis unit is affected by Crescent Stone; it has increased trigger chances.")


func periodic(_event: Event):
	var itm: Item = self
	var tower: Tower = itm.get_carrier()
	CombatLog.log_item_ability(self, null, "Earth and Moon")
	drol_moonStone.apply(tower, tower, tower.get_level())
