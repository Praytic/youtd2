extends ItemBehavior


var threads_bt: BuffType


func get_ability_description() -> String:
	var text: String = ""

	text += "[color=GOLD]Silver Threads[/color]\n"
	text += "Whenever the carrier hits a creep, it has a 15% attack speed adjusted chance to cover the creep in a silvered web, increasing its item quality by 40% for 5 seconds.\n"
	text += " \n"
	text += "[color=ORANGE]Level Bonus:[/color]\n"
	text += "+1% item quality\n"
	text += "+0.1 seconds duration\n"

	return text


func load_triggers(triggers: BuffType):
	triggers.add_event_on_damage(on_damage)


func item_init():
	threads_bt = BuffType.new("threads_bt", 5.0, 0.1, false, self)
	threads_bt.set_buff_icon("res://resources/icons/GenericIcons/spider_web.tres")
	threads_bt.set_buff_tooltip("Silver Threads\nIncreases quality of dropped items.")
	var mod: Modifier = Modifier.new()
	mod.add_modification(Modification.Type.MOD_ITEM_QUALITY_ON_DEATH, 0.4, 0.01)
	threads_bt.set_buff_modifier(mod)


func on_damage(event: Event):
	var tower: Tower = item.get_carrier()

	if tower.calc_chance(0.15 * tower.get_base_attack_speed()):
		CombatLog.log_item_ability(item, null, "Silver Threads")
		threads_bt.apply(tower, event.get_target(), tower.get_level())
