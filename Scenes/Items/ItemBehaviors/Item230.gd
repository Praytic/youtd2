# The Divine Wings of Tragedy
extends ItemBehavior


var symph_divine_wings_bt: BuffType


func get_ability_description() -> String:
	var text: String = ""

	text += "[color=GOLD]The Divine Wings of Tragedy - Aura[/color]\n"
	text += "Increases attack damage and attack speed of towers in 250 range by 15%.\n"

	return text


func load_modifier(modifier: Modifier):
	modifier.add_modification(Modification.Type.MOD_BUFF_DURATION, 0.37, 0)


func item_init():
	symph_divine_wings_bt = BuffType.create_aura_effect_type("item230_symph_divine_wings_bt", true, self)
	symph_divine_wings_bt.set_buff_icon("winged_man.tres")
	symph_divine_wings_bt.set_buff_tooltip("The Divine Wings of Tragedy\nIncreases attack damage and attack speed.")
	symph_divine_wings_bt.set_stacking_group("symph_divine_wings_bt")
	var mod: Modifier = Modifier.new()
	mod.add_modification(Modification.Type.MOD_ATTACKSPEED, 0.15, 0.0)
	mod.add_modification(Modification.Type.MOD_DAMAGE_ADD_PERC, 0.15, 0.0)
	symph_divine_wings_bt.set_buff_modifier(mod)

	var aura: AuraType = AuraType.new()
	aura.aura_range = 250
	aura.target_type = TargetType.new(TargetType.TOWERS)
	aura.target_self = true
	aura.level = 0
	aura.level_add = 1
	aura.power = 0
	aura.power_add = 1
	aura.aura_effect = symph_divine_wings_bt
	item.add_aura(aura)
