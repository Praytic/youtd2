extends ItemBehavior


var warsong_bt: BuffType


func get_ability_description() -> String:
	var text: String = ""

	text += "[color=GOLD]Warsong Double Bass - Aura[/color]\n"
	text += "The catchy Bass Line of the drums increases attack speed of towers in 200 range by 7.5%.\n"
	text += " \n"
	text += "[color=ORANGE]Level Bonus:[/color]\n"
	text += "+0.1% attack speed\n"

	return text


func item_init():
	warsong_bt = BuffType.create_aura_effect_type("warsong_bt", true, self)
	warsong_bt.set_buff_icon("res://resources/icons/generic_icons/rss.tres")
	warsong_bt.set_buff_tooltip("Warsong Double Bass Effect\nIncreased attack speed.")
	warsong_bt.set_stacking_group("warsong_bt")
	var mod: Modifier = Modifier.new()
	mod.add_modification(Modification.Type.MOD_ATTACKSPEED, 0.0, 0.0001)
	warsong_bt.set_buff_modifier(mod)

	var aura: AuraType = AuraType.new()
	aura.aura_range = 200
	aura.target_type = TargetType.new(TargetType.TOWERS)
	aura.target_self = true
	aura.level = 0
	aura.level_add = 10
	aura.power = 0
	aura.power_add = 10
	aura.aura_effect = warsong_bt
	item.add_aura(aura)
