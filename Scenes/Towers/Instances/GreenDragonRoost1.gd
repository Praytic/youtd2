extends Tower


var boekie_green_dragon_bt: BuffType


func get_ability_description() -> String:
	var text: String = ""

	text += "[color=GOLD]Green Dragon Force - Aura[/color]\n"
	text += "Increases the multicrit of towers in 200 range by 2.\n"

	return text


func get_ability_description_short() -> String:
	var text: String = ""

	text += "[color=GOLD]Green Dragon Force - Aura[/color]\n"
	text += "Increases multicrit of towers in range.\n"

	return text


func load_specials(modifier: Modifier):
	_set_attack_style_bounce(4, 0.10)
	modifier.add_modification(Modification.Type.MOD_SPELL_CRIT_CHANCE, 0.15, 0.005)
	modifier.add_modification(Modification.Type.MOD_SPELL_CRIT_DAMAGE, 1.5, 0.05)


func tower_init():
	boekie_green_dragon_bt = BuffType.create_aura_effect_type("boekie_green_dragon_bt", true, self)
	var mod: Modifier = Modifier.new()
	mod.add_modification(Modification.Type.MOD_MULTICRIT_COUNT, 2, 0.0)
	boekie_green_dragon_bt.set_buff_modifier(mod)
	boekie_green_dragon_bt.set_buff_icon("@@0@@")
	boekie_green_dragon_bt.set_buff_tooltip("Green Dragon Force Aura\nThis tower is under the effect of Green Dragon Force Aura; it has increased multicrit.")

	var aura: AuraType = AuraType.new()
	aura.aura_range = 200
	aura.target_type = TargetType.new(TargetType.TOWERS)
	aura.target_self = true
	aura.level = 0
	aura.level_add = 1
	aura.power = 0
	aura.power_add = 1
	aura.aura_effect = boekie_green_dragon_bt
	add_aura(aura)
