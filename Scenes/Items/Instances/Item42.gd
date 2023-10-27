# Sleeve of Rage
extends Item


var sir_sleeve_buff: BuffType


func get_ability_description() -> String:
	var text: String = ""

	text += "[color=GOLD]Ancient Rage[/color]\n"
	text += "On attack this tower will enrage for 1.5 seconds gaining 0.5% increased attackspeed 1% attack damage and 0.25% spell damage. This effect stacks up to 120 times.\n"

	return text


func load_triggers(triggers: BuffType):
	triggers.add_event_on_attack(on_attack)


func item_init():
	var m: Modifier = Modifier.new()
	m.add_modification(Modification.Type.MOD_ATTACKSPEED, 0.0, 0.005)
	m.add_modification(Modification.Type.MOD_SPELL_DAMAGE_DEALT, 0.0, 0.0025)
	m.add_modification(Modification.Type.MOD_DAMAGE_ADD_PERC, 0.0, 0.01)
	sir_sleeve_buff = BuffType.new("sir_sleeve_buff", 5, 0, true, self)
	sir_sleeve_buff.set_buff_icon("@@0@@")
	sir_sleeve_buff.set_buff_modifier(m)
	sir_sleeve_buff.set_stacking_group("sir_sleeve_group")
	sir_sleeve_buff.set_buff_tooltip("Enraged\nThis unit is Enraged; it has increased attack speed, spell damage and attack damage.")


func on_attack(_event: Event):
	var itm: Item = self
	var tower: Tower = itm.get_carrier()
	var b: Buff = tower.get_buff_of_type(sir_sleeve_buff)

	var level: int
	if b != null:
		level = b.get_level()
	else:
		level = 0

	if level < 120:
		sir_sleeve_buff.apply_advanced(tower, tower, 1 + level, level, 1.5)
	else:
		b.refresh_duration()
