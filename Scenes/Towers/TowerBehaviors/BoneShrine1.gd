extends TowerBehavior


var curse_bt: BuffType


func get_tier_stats() -> Dictionary:
	return {
		1: {dmg_increase = 0.02, dmg_increase_add = 0.0004},
		2: {dmg_increase = 0.04, dmg_increase_add = 0.0008},
		3: {dmg_increase = 0.06, dmg_increase_add = 0.0012},
	}


func get_ability_description() -> String:
	var dmg_increase: String = Utils.format_percent(_stats.dmg_increase, 2)
	var dmg_increase_add: String = Utils.format_percent(_stats.dmg_increase_add, 2)

	var text: String = ""

	text += "[color=GOLD]Empowering Darkness[/color]\n"
	text += "On attack this tower increases the damage the target receives from other darkness towers by %s. This effect stacks up to 10 times.\n" % dmg_increase
	text += " \n"
	text += "[color=ORANGE]Level Bonus:[/color]\n"
	text += " +%s damage increased\n" % dmg_increase_add

	return text


func get_ability_description_short() -> String:
	var text: String = ""

	text += "[color=GOLD]Empowering Darkness[/color]\n"
	text += "On attack, this tower makes the target more vulnerable to Darkness.\n"

	return text


func load_triggers(triggers: BuffType):
	triggers.add_event_on_attack(on_attack)


func tower_init():
	curse_bt = BuffType.new("curse_bt", 0, 0, false, self)
	curse_bt.set_buff_icon("mask_bat.tres")
	curse_bt.set_buff_tooltip("Curse of Shadow\nIncreases damage taken from Darkness towers.")


func on_attack(event: Event):
	var existing_buff: Buff = event.get_target().get_buff_of_type(curse_bt)
	var buff_level: int
	if existing_buff != null:
		buff_level = existing_buff.get_level()
	else:
		buff_level = 0 

	if buff_level < 10:
		event.get_target().modify_property(Modification.Type.MOD_DMG_FROM_DARKNESS, _stats.dmg_increase + tower.get_level() * _stats.dmg_increase_add)
		curse_bt.apply_advanced(tower, event.get_target(), buff_level + 1, 0, 1000)
