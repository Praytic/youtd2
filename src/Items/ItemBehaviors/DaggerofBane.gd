extends ItemBehavior


# NOTE: in original, tower is saved in buff's user_int.
# Changed it so that tower's get_instance_id() is saved instead
# because we can't convert references to ints in gdscript.


var poison_bt: BuffType


func get_ability_description() -> String:
	var text: String = ""

	text += "[color=GOLD]Deadly Poison[/color]\n"
	text += "Whenever the carrier hits the main target, it applies a deadly poison. Each second the poison deals 15% of the tower's base damage as spell damage to the target. The spell damage is always critical. Lasts 4 seconds.\n"

	return text


func load_triggers(triggers: BuffType):
	triggers.add_event_on_damage(on_damage)


# NOTE: dealDamage() in original script
func poison_bt_periodic(event: Event):
	var b: Buff = event.get_buff()
	var tower: Tower = b.get_caster()

	if tower.get_instance_id() == b.user_int:
		tower.do_spell_damage(b.get_buffed_unit(), tower.get_current_attack_damage_base() * 0.15, tower.get_spell_crit_damage())
	else:
		b.remove_buff()


func item_init():
#	+ 0.01 seconds is a dirty hack to make damage tick 4 times with 100% duration
	poison_bt = BuffType.new("poison_bt", 4.01, 0, false, self)
	poison_bt.set_buff_icon("res://resources/Icons/GenericIcons/poison_gas.tres")
	poison_bt.set_buff_tooltip("Deadly Poison\nDeals damage over time.")
	poison_bt.add_periodic_event(poison_bt_periodic, 1)


func on_damage(event: Event):
	var P: Buff
	var u: Unit

	if event.is_main_target():
		u = event.get_target()
		P = u.get_buff_of_type(poison_bt)

		if P != null:
			poison_bt.apply(item.get_carrier(), event.get_target(), 0)
		else:
			poison_bt.apply(item.get_carrier(), event.get_target(), 0).user_int = item.get_carrier().get_instance_id()
