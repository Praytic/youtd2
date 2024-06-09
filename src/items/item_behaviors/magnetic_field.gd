extends ItemBehavior


var magnetic_bt: BuffType


func get_ability_description() -> String:
	var text: String = ""

	text += "[color=GOLD]Magnetic Field - Aura[/color]\n"
	text += "Grants +10% buff duration and -15% debuff duration to all towers within 200 range.\n"

	return text


func item_init():
	magnetic_bt = BuffType.create_aura_effect_type("magnetic_bt", true, self)
	magnetic_bt.set_buff_icon("res://resources/icons/generic_icons/rss.tres")
	magnetic_bt.set_buff_tooltip("Magnetic Field\nIncreases buff duration and reduces debuff duration.")
	var mod: Modifier = Modifier.new()
	mod.add_modification(Modification.Type.MOD_DEBUFF_DURATION, -0.15, 0.0)
	mod.add_modification(Modification.Type.MOD_BUFF_DURATION, 0.1, 0.0)
	magnetic_bt.set_buff_modifier(mod)
	
	var aura: AuraType = AuraType.new()
	aura.aura_range = 200
	aura.target_type = TargetType.new(TargetType.TOWERS)
	aura.target_self = true
	aura.level = 0
	aura.level_add = 1
	aura.aura_effect = magnetic_bt
	item.add_aura(aura)
