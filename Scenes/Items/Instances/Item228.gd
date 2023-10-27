# Bloody Key
extends Item


var human_aura: BuffType


func get_ability_description() -> String:
	var text: String = ""

	text += "[color=GOLD]Bestial Rage - Aura[/color]\n"
	text += "Grants 12% bonus damage against orc and humanoid creeps and also increases dps by 100 for all towers in 200 AoE.\n"
	text += " \n"
	text += "[color=ORANGE]Level Bonus:[/color]\n"
	text += "+0.24% to orcs and humanoids\n"
	text += "+6 dps\n"

	return text


func load_modifier(modifier: Modifier):
	modifier.add_modification(Modification.Type.MOD_EXP_RECEIVED, -0.70, 0.0)
	modifier.add_modification(Modification.Type.MOD_BOUNTY_RECEIVED, -0.70, 0.0)


func item_init():
	var m: Modifier = Modifier.new()
	human_aura = BuffType.create_aura_effect_type("human_aura", true, self)
	m.add_modification(Modification.Type.MOD_DMG_TO_HUMANOID, 0.12, 0.0024)
	m.add_modification(Modification.Type.MOD_DMG_TO_ORC, 0.12, 0.0024)
	m.add_modification(Modification.Type.MOD_DPS_ADD, 100, 6)
	human_aura.set_buff_modifier(m)
	human_aura.set_stacking_group("human_aura")
	human_aura.set_buff_icon("@@0@@")
	human_aura.set_buff_tooltip("Bestial Rage\nThis unit is under the effect of Bestial Rage Aura; it will deal more damage to orc and humanoid units and it has increased DPS.")

	var aura: AuraType = AuraType.new()
	aura.aura_range = 200
	aura.target_type = TargetType.new(TargetType.TOWERS)
	aura.target_self = true
	aura.level = 0
	aura.level_add = 1
	aura.power = 0
	aura.power_add = 1
	aura.aura_effect = human_aura
	add_aura(aura)
