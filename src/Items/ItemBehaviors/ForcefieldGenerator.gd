extends ItemBehavior


var forcefield_bt: BuffType


func get_ability_description() -> String:
	var text: String = ""

	text += "[color=GOLD]Forcefield[/color]\n"
	text += "Reduces the duration of debuffs cast on the carrier and all towers within 200 range of the carrier by 15%.\n"
	text += " \n"
	text += "[color=ORANGE]Level Bonus:[/color]\n"
	text += "-1% debuff duration\n"

	return text


func item_init():
	forcefield_bt = BuffType.create_aura_effect_type("forcefield_bt", true, self)
	forcefield_bt.set_buff_icon("res://resources/icons/GenericIcons/rss.tres")
	forcefield_bt.set_buff_tooltip("Forcefield\nReduces debuff duration.")
	var mod: Modifier = Modifier.new()
	mod.add_modification(Modification.Type.MOD_DEBUFF_DURATION, -0.15, -0.01)
	forcefield_bt.set_buff_modifier(mod)

	var aura: AuraType = AuraType.new()
	aura.aura_range = 200
	aura.target_type = TargetType.new(TargetType.TOWERS)
	aura.target_self = true
	aura.level = 0
	aura.level_add = 1
	aura.power = 0
	aura.power_add = 1
	aura.aura_effect = forcefield_bt
	item.add_aura(aura)
