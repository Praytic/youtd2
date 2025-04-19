extends ItemBehavior


var threads_bt: BuffType


func load_triggers(triggers: BuffType):
	triggers.add_event_on_damage(on_damage)


func item_init():
	threads_bt = BuffType.new("threads_bt", 5.0, 0.1, false, self)
	threads_bt.set_buff_icon("res://resources/icons/generic_icons/spider_web.tres")
	threads_bt.set_buff_tooltip(tr("A8WN"))
	var mod: Modifier = Modifier.new()
	mod.add_modification(ModificationType.enm.MOD_ITEM_QUALITY_ON_DEATH, 0.4, 0.01)
	threads_bt.set_buff_modifier(mod)


func on_damage(event: Event):
	var tower: Tower = item.get_carrier()

	if tower.calc_chance(0.15 * tower.get_base_attack_speed()):
		CombatLog.log_item_ability(item, null, "Silver Threads")
		threads_bt.apply(tower, event.get_target(), tower.get_level())
