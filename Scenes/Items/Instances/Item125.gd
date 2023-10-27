# Mystical Shell
extends Item


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
	drol_spellDmgRecieved.set_buff_tooltip("Resonance\nThis unit is afflicted by Resonance; it will receive more damage from spells.")


func on_attack(event: Event):
	var itm: Item = self

	var tower: Tower = itm.get_carrier()

	if tower.calc_chance(0.10 * tower.get_base_attack_speed()):
		drol_spellDmgRecieved.apply(tower, event.get_target(), tower.get_level())
