extends Tower


var boekie_dragon_sorcerer_bt: BuffType


func get_autocast_description() -> String:
	var text: String = ""

	text += "This tower adds a buff to a tower in 500 range that lasts 10 seconds. The buff increases the multicrit count by 1,  the crit chance by 7.5% and the attack speed by 25%.\n"
	text += " \n"
	text += "[color=ORANGE]Level Bonus:[/color]\n"
	text += "+0.4 seconds duration\n"
	text += "+0.6% attackspeed\n"
	text += "+0.2% crit chance\n"

	return text


func get_autocast_description_short() -> String:
	var text: String = ""

	text += "This tower adds a buff to a tower in range. The buff increases multicrit, crit chance and attack speed.\n"

	return text


func load_specials(modifier: Modifier):
	modifier.add_modification(Modification.Type.MOD_MANA, 0.0, 5.0)
	modifier.add_modification(Modification.Type.MOD_MANA_REGEN, 0.0, 0.1)


func tower_init():
	boekie_dragon_sorcerer_bt = BuffType.new("boekie_dragon_sorcerer_bt", 10.0, 0.4, true, self)
	var mod: Modifier = Modifier.new()
	mod.add_modification(Modification.Type.MOD_MULTICRIT_COUNT, 1.0, 0.0)
	mod.add_modification(Modification.Type.MOD_ATK_CRIT_CHANCE, 0.075, 0.002)
	mod.add_modification(Modification.Type.MOD_ATTACKSPEED, 0.25, 0.006)
	boekie_dragon_sorcerer_bt.set_buff_modifier(mod)
	boekie_dragon_sorcerer_bt.set_buff_icon("@@0@@")
	boekie_dragon_sorcerer_bt.set_buff_tooltip("Burning Mark\nThis tower has the Burning Mark; it has increased multicrit, crit chance and attack speed.")

	var autocast: Autocast = Autocast.make()
	autocast.title = "Burning Mark"
	autocast.description = get_autocast_description()
	autocast.description_short = get_autocast_description_short()
	autocast.icon = "res://path/to/icon.png"
	autocast.caster_art = ""
	autocast.target_art = "DoomDeath.mdl"
	autocast.autocast_type = Autocast.Type.AC_TYPE_OFFENSIVE_BUFF
	autocast.num_buffs_before_idle = 3
	autocast.cast_range = 500
	autocast.auto_range = 500
	autocast.cooldown = 2
	autocast.mana_cost = 20
	autocast.target_self = false
	autocast.is_extended = false
	autocast.buff_type = boekie_dragon_sorcerer_bt
	autocast.target_type = TargetType.new(TargetType.TOWERS)
	autocast.handler = Callable()
	add_autocast(autocast)
