# Even More Magical Hammer
extends Item


var hammer_mark: BuffType
var hammer_aura: BuffType


func get_extra_tooltip_text() -> String:
	var text: String = ""

	text += "[color=GOLD]Even More Magical Weapon[/color]\n"
	text += "Every 5th instance of spell damage is a critical hit.\n"

	return text


func load_triggers(triggers: BuffType):
	triggers.add_event_on_unit_comes_in_range(on_unit_in_range, 2000, TargetType.new(TargetType.CREEPS))


func mark_setup(event: Event):
	var B: Buff = event.get_buff()

	B.user_int = 5
	B.user_int2 = 5
	B.user_int3 = 5

	B.user_real = 50
	B.user_real2 = 50
	B.user_real3 = 50


func hammer_aura_trig(event: Event):
	var B: Buff = event.get_buff()
	var T: Tower = event.get_target()
	var lvl: int

	if event.is_spell_damage():
#		Has attacker the mark buff?
		B = T.get_buff_of_type(hammer_mark)

		if B != null:
			lvl = B.get_level()

#			Attacking tower carries a hammer
#			Hammer 1
			B.user_int = B.user_int - 1
			if B.user_int <= 0:
				B.user_int = 5
				T.add_spell_crit()

#			Hammer 2
			if lvl >= 2:
				B.user_int2 = B.user_int2 - 1
				if B.user_int2 <= 0:
					B.user_int2 = 5
					T.add_spell_crit()
			else:
#				Only 1 hammer
				return

#			Hammer 3
			if lvl >= 3:
				B.user_int3 = B.user_int3 - 1
				if B.user_int3 <= 0:
					B.user_int3 = 5
					T.add_spell_crit()
			else:
#				Only 2 hammer
				return

#			Hammer 4
			if lvl >= 4:
				B.user_real = B.user_real - 10
#				Because real are realy not accurate at all.
				if B.user_real < 5:
					B.user_real = 50
					T.add_spell_crit()
			else:
#				Only 3 hammer
				return

#			Hammer 5
			if lvl >= 5:
				B.user_real2 = B.user_real2 - 10
#				Because real are realy not accurate at all.
				if B.user_real2 < 5:
					B.user_real2 = 50
					T.add_spell_crit()
			else:
#				Only 4 hammer
				return

#			Hammer 6
			if lvl >= 6:
				B.user_real3 = B.user_real3 - 10
#				Because real are realy not accurate at all.
				if B.user_real3 < 5:
					B.user_real3 = 50
					T.add_spell_crit()


func item_init():
	hammer_mark = BuffType.new("hammer_mark", -1, 0, true, self)
	hammer_mark.set_buff_icon("@@0@@")
	hammer_mark.add_event_on_create(mark_setup)

	hammer_aura = BuffType.new("hammer_aura", -1, 0, true, self)
	hammer_aura.set_buff_icon("@@1@@")
	hammer_aura.add_event_on_damaged(hammer_aura_trig)


func on_drop():
	var itm: Item = self
	var T: Tower = itm.get_carrier()
	var B: Buff = T.get_buff_of_type(hammer_mark)

	if B != null:
#		First hammer on tower
		if B.get_level() == 1:
#			Only one hammer was on tower
			B.remove_buff()
		else:
			B.set_level(B.get_level() - 1)
	else:
#		No buff, although there is still a hammer on the tower! Shit happened!
		return


func on_pickup():
	var itm: Item = self
	var T: Tower = itm.get_carrier()
	var B: Buff = T.get_buff_of_type(hammer_mark)

	if B == null:
#		First hammer on tower
		hammer_mark.apply(T, T, 1)
	else:
#		Already a hammer on the tower
		B.set_level(B.get_level() + 1)


func on_unit_in_range(event: Event):
	var itm: Item = self
	var U: Unit = event.get_target()

	if U.get_buff_of_type(hammer_aura) == null:
		hammer_aura.apply(itm.get_carrier(), U, 0)
