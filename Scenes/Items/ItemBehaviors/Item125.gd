# Mystical Shell
extends ItemBehavior


var drol_spellDmgRecieved: BuffType


func get_ability_description() -> String:
	var text: String = ""

	text += "[color=GOLD]Resonance[/color]\n"
	text += "Grants the carrier a 10% attackspeed adjusted chance to debuff the attacked target, increasing all spelldamage dealt to it by 15% for 5 seconds\n"

	return text


func load_triggers(triggers: BuffType):
	triggers.add_event_on_attack(on_attack)


func item_init():
	var m: Modifier = Modifier.new()
	m.add_modification(Modification.Type.MOD_SPELL_DAMAGE_RECEIVED, 0.15, 0.0)

	drol_spellDmgRecieved = BuffType.new("drol_spellDmgRecieved", 5, 0, false, self)
	drol_spellDmgRecieved.set_buff_icon("@@0@@")
	drol_spellDmgRecieved.set_buff_modifier(m)
	drol_spellDmgRecieved.set_buff_tooltip("Resonance\nIncreases spell damage taken.")


func on_attack(event: Event):
	var tower: Tower = item.get_carrier()

	if tower.calc_chance(0.10 * tower.get_base_attackspeed()):
		CombatLog.log_item_ability(item, event.get_target(), "Resonance")
		drol_spellDmgRecieved.apply(tower, event.get_target(), tower.get_level())
