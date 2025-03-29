extends ItemBehavior


var multiboard: MultiboardValues


func load_modifier(modifier: Modifier):
	modifier.add_modification(Modification.Type.MOD_DAMAGE_ADD_PERC, -0.20, 0)
	modifier.add_modification(Modification.Type.MOD_SPELL_DAMAGE_DEALT, -0.20, 0.0)
	modifier.add_modification(Modification.Type.MOD_BOUNTY_RECEIVED, 0.50, 0.0)


func load_triggers(triggers: BuffType):
	triggers.add_event_on_unit_comes_in_range(on_unit_in_range, 600, TargetType.new(TargetType.CREEPS + TargetType.SIZE_BOSS))


func item_init():
	multiboard = MultiboardValues.new(1)
	var arms_sold_label: String = tr("YQK4")
	multiboard.set_key(0, arms_sold_label)


func on_create():
	item.user_int = 0
	item.user_int2 = 0


func on_tower_details() -> MultiboardValues:
	var arms_sold_text: String = Utils.format_float(item.user_int2, 0)
	multiboard.set_value(0, arms_sold_text)

	return multiboard


func on_unit_in_range(event: Event):
	var t: Tower = item.get_carrier() 
	var c: Creep = event.get_target()
	var p: Player = t.get_player()
	var boss_level: int = c.get_spawn_level()
	var reward_value: int

	if item.user_int < boss_level && t.calc_chance(0.25):
		CombatLog.log_item_ability(item, null, "The Customer Is Boss")
		
		reward_value = t.get_level() + boss_level + 25
		p.give_gold(reward_value, t, true, false)
		var arms_sold_text: String = "%s %d" % [tr("YQK4"), reward_value]
		p.display_floating_text(arms_sold_text, t, Color8(0, 255, 0))
		item.user_int = boss_level
		item.user_int2 = item.user_int2 + reward_value
