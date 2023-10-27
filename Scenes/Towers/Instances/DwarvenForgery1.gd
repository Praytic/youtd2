extends Tower


var dwarven_forgery_aura_bt: BuffType


func get_ability_description() -> String:
	var text: String = ""

	text += "[color=GOLD]Dwarven Polish - Aura[/color]\n"
	text += "Increases the item quality ratio of friendly towers in 550 range including itself by 15%.\n"
	text += " \n"
	text += "[color=ORANGE]Level Bonus:[/color]\n"
	text += "+0.4% quality ratio\n"

	return text


func load_specials(modifier: Modifier):
	modifier.add_modification(Modification.Type.MOD_ITEM_QUALITY_ON_KILL, 0.50, 0.01)


func tower_init():
	dwarven_forgery_aura_bt = BuffType.create_aura_effect_type("dwarven_forgery_aura_bt", true, self)
	var mod: Modifier = Modifier.new()
	mod.add_modification(Modification.Type.MOD_ITEM_QUALITY_ON_KILL, 0.15, 0.004)
	dwarven_forgery_aura_bt.set_buff_modifier(mod)
	dwarven_forgery_aura_bt.set_buff_icon("@@0@@")
	dwarven_forgery_aura_bt.set_buff_tooltip("Dwarven Polish Aura\nThis tower is under the effect of Dwarven Polish Aura; it has increased item quality ratio.")

	var aura: AuraType = AuraType.new()
	aura.aura_range = 550
	aura.target_type = TargetType.new(TargetType.TOWERS)
	aura.target_self = true
	aura.level = 0
	aura.level_add = 1
	aura.power = 0
	aura.power_add = 1
	aura.aura_effect = dwarven_forgery_aura_bt
	add_aura(aura)
