# Dagger of Bane
extends Item


# NOTE: in original, tower is saved in buff's user_int.
# Changed it so that tower's get_instance_id() is saved instead
# because we can't convert references to ints in gdscript.


var fright_poison_dagger_buff: BuffType


func get_extra_tooltip_text() -> String:
	var text: String = ""

	text += "[color=GOLD]Deadly Poison[/color]\n"
	text += "Applies a deadly poison on damage to the main target of the attack. Each second the poison deals 15% of the tower's base damage as spell damage to the target. The spell damage is always critical. Lasts 4 seconds.\n"

	return text


func load_triggers(triggers: BuffType):
	triggers.add_event_on_damage(on_damage, 1.0, 0.0)


func deal_damage(event: Event):
	var b: Buff = event.get_buff()
	var tower: Tower = b.get_caster()

	if tower.get_instance_id() == b.user_int:
		tower.do_spell_damage(b.get_buffed_unit(), tower.get_current_attack_damage_base() * 0.15, tower.get_spell_crit_damage())
	else:
		b.remove_buff()


func item_init():
#	+ 0.01 seconds is a dirty hack to make damage tick 4 times with 100% duration
	fright_poison_dagger_buff = BuffType.new("fright_poison_dagger_buff", 4.01, 0, false, self)
	fright_poison_dagger_buff.set_buff_icon("@@0@@")
	fright_poison_dagger_buff.add_periodic_event(deal_damage, 1)
	fright_poison_dagger_buff.set_buff_tooltip("Deadly Poison Effect\nThis unit is poisoned and suffers periodic damage for 4 sec.")


func on_damage(event: Event):
	var itm: Item = self

	var P: Buff
	var u: Unit

	if event.is_main_target():
		u = event.get_target()
		P = u.get_buff_of_type(fright_poison_dagger_buff)

		if P != null:
			fright_poison_dagger_buff.apply(itm.get_carrier(), event.get_target(), 0)
		else:
			fright_poison_dagger_buff.apply(itm.get_carrier(), event.get_target(), 0).user_int = itm.get_carrier().get_instance_id()
