# Liquid Gold
extends Item


var drol_hangover: BuffType
var cb_stun: BuffType


func get_extra_tooltip_text() -> String:
	var text: String = ""

	text += "[color=GOLD]Hangover[/color]\n"
	text += "Each attack has a 10% attackspeed adjusted chance to give the user a hangover, slowing its attackspeed by 30% for 8 seconds and stunning it for 3 seconds when it expires."
	text += "[color=ORANGE]Level Bonus:[/color]\n"
	text += "+1% attackspeed\n"
	text += "-0.1 second stun duration\n"
	text += " \n"

	return text


func load_modifier(modifier: Modifier):
	modifier.add_modification(Modification.Type.MOD_DAMAGE_ADD_PERC, 0.35, 0.0)


func load_triggers(triggers: BuffType):
	triggers.add_event_on_attack(on_attack)


func drol_drunk(event: Event):
	var b: Buff = event.get_buff()
	var tower: Unit = b.get_caster()
	cb_stun.apply_only_timed(tower, tower, 3 - tower.get_level() * 0.1)


func item_init():
	cb_stun = CbStun.new("cb_stun", 0, 0, false, self)

	var m: Modifier = Modifier.new()
	m.add_modification(Modification.Type.MOD_ATTACKSPEED, -0.30, 0.01)
	drol_hangover = BuffType.new("drol_hangover", 8, 0, false, self)
	drol_hangover.set_buff_modifier(m)
	drol_hangover.set_buff_icon("@@0@@")
	drol_hangover.set_event_on_expire(drol_drunk)
	drol_hangover.set_buff_tooltip("Drunk\nTower's attackspeed is decreased and it will befcome stunned soon.")


func on_attack(event: Event):
	var itm: Item = self
	var tower: Tower = itm.get_carrier()
	var speed: float = tower.get_base_attack_speed()

	if tower.calc_bad_chance(0.1 * speed):
		drol_hangover.apply(tower, tower, tower.get_level())
