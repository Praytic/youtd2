# Jungle Stalker's Doll
extends Item


var poussix_rageitem_buff: BuffType


func get_ability_description() -> String:
	var text: String = ""

	text += "[color=GOLD]Bloodthirst[/color]\n"
	text += "When the carrier kills a unit it becomes enraged for 3 seconds. While enraged, it has 20% bonus attackspeed. Cannot retrigger while active!"
	text += " \n"
	text += "[color=ORANGE]Level Bonus:[/color]\n"
	text += "+0.4% attackspeed\n"

	return text


func load_triggers(triggers: BuffType):
	triggers.add_event_on_kill(on_kill)


func load_modifier(modifier: Modifier):
	modifier.add_modification(Modification.Type.MOD_ATK_CRIT_CHANCE, 0.025, 0.001)


func item_init():
	var m: Modifier = Modifier.new()
	m.add_modification(Modification.Type.MOD_ATTACKSPEED, 0.20, 0.004)

	poussix_rageitem_buff = BuffType.new("poussix_rageitem_buff", 0, 0, true, self)
	poussix_rageitem_buff.set_buff_modifier(m)
	poussix_rageitem_buff.set_buff_icon("@@0@@")
	poussix_rageitem_buff.set_stacking_group("poussix_rageitem_buff")
	poussix_rageitem_buff.set_buff_tooltip("Enraged\nThis unit is enraged; it has increased attack speed.")


func on_kill(event: Event):
	var itm: Item = self
	var tower: Tower = itm.get_carrier()

	if tower.get_buff_of_type(poussix_rageitem_buff) == null:
		SFX.sfx_at_unit("StampedMissileDeath.mdl", event.get_target())
		poussix_rageitem_buff.apply_custom_timed(tower, tower, tower.get_level(), 3.0)

