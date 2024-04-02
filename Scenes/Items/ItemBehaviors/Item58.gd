# Warsong Double Bass
extends ItemBehavior


var neotopia_warsong_bt: BuffType


func get_ability_description() -> String:
	var text: String = ""

	text += "[color=GOLD]Warsong Double Bass - Aura[/color]\n"
	text += "The catchy Bass Line of the drums increases the attackspeed of towers in 200 range, by 7.5%.\n"
	text += " \n"
	text += "[color=ORANGE]Level Bonus:[/color]\n"
	text += "+0.1% attack speed\n"

	return text


func item_init():
	neotopia_warsong_bt = BuffType.create_aura_effect_type("neotopia_warsong_bt", true, self)
	neotopia_warsong_bt.set_buff_icon("angel_wings.tres")
	neotopia_warsong_bt.set_buff_tooltip("Warsong Double Bass Effect\nIncreased attack speed.")
	neotopia_warsong_bt.set_stacking_group("neotopia_warsong_bt")
	var mod: Modifier = Modifier.new()
	mod.add_modification(Modification.Type.MOD_ATTACKSPEED, 0.0, 0.0001)
	neotopia_warsong_bt.set_buff_modifier(mod)

	var aura: AuraType = AuraType.new()
	aura.aura_range = 200
	aura.target_type = TargetType.new(TargetType.TOWERS)
	aura.target_self = true
	aura.level = 0
	aura.level_add = 10
	aura.power = 0
	aura.power_add = 10
	aura.aura_effect = neotopia_warsong_bt
	item.add_aura(aura)
