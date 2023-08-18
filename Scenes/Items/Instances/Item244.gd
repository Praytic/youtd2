# Arms Dealer
extends Item


var limfa_dealerboard: MultiboardValues



func get_extra_tooltip_text() -> String:
	var text: String = ""

	text += "[color=GOLD]The Customer Is Boss[/color]\n"
	text += "Bosses coming within 600 range of the carrier have a 25% chance to grant [25 + current wave] gold. Cannot trigger on the same boss twice.\n"
	text += "[color=ORANGE]Level Bonus:[/color]\n"
	text += "+1 gold\n"

	return text


func load_modifier(modifier: Modifier):
	modifier.add_modification(Modification.Type.MOD_DAMAGE_ADD_PERC, -0.20, 0.004)
	modifier.add_modification(Modification.Type.MOD_SPELL_DAMAGE_DEALT, -0.20, 0.0)
	modifier.add_modification(Modification.Type.MOD_BOUNTY_RECEIVED, 0.50, 0.0)


func load_triggers(triggers: BuffType):
	triggers.add_event_on_unit_comes_in_range(on_unit_in_range, 600, TargetType.new(TargetType.CREEPS + TargetType.SIZE_BOSS))


func item_init():
	limfa_dealerboard = MultiboardValues.new(1)
	limfa_dealerboard.set_key(0, "Arms Sold$")


func on_create():
	var itm: Item = self

	itm.user_int = 0
	itm.user_int2 = 0


func on_tower_details() -> MultiboardValues:
	var itm: Item = self

	limfa_dealerboard.set_value(0, str(itm.user_int2))
	return limfa_dealerboard


func on_unit_in_range(event: Event):
	var itm: Item = self

	var t: Tower = itm.get_carrier() 
	var c: Creep = event.get_target()
	var p: Player = t.get_player()
	var boss_level: int = c.get_spawn_level()
	var reward_value: int

	if itm.user_int < boss_level && t.calc_chance(0.25):
		reward_value = t.get_level() + boss_level + 25
		p.give_gold(reward_value, t, true, false)
		p.display_floating_text("Arms Sold $" + str(reward_value), t, 0, 255, 0)
		itm.user_int = boss_level
		itm.user_int2 = itm.user_int2 + reward_value
