# Stunner
extends Item


var cb_stun: BuffType


func get_ability_description() -> String:
	var text: String = ""

	text += "[color=GOLD]Stun[/color]\n"
	text += "When the carrier of this item damages a creep there is a 15% attackspeed adjusted chance to stun the target for 1 second. Has only a 1/3 of the normal chance to trigger on bosses!\n"
	text += " \n"
	text += "[color=ORANGE]Level Bonus:[/color]\n"
	text += "+0.25% chance\n"

	return text


func load_triggers(triggers: BuffType):
	triggers.add_event_on_damage(on_damage)


func item_init():
	cb_stun = CbStun.new("item_269_stun", 0, 0, false, self)


func on_damage(event: Event):
	var itm: Item = self
	var target: Creep = event.get_target()
	var size: int = target.get_size()
	var tower: Tower = itm.get_carrier()
	var speed: float = tower.get_base_attack_speed()

	if size< CreepSize.BOSS:
		if tower.calc_chance((0.15 + tower.get_level() * 0.0025) * speed) && event.is_main_target() == true:
			cb_stun.apply_only_timed(tower, target, 1)
	else:
		if tower.calc_chance((0.15 + tower.get_level() * 0.0025) / 3 * speed) && event.is_main_target() == true:
			cb_stun.apply_only_timed(tower, target, 1)
