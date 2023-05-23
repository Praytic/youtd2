# Mighty Tree's Acorns
extends Item


var poussix_multi_aura: BuffType


func get_extra_tooltip_text() -> String:
	var text: String = ""

	text += "[color=GOLD]Charity Aura - Aura[/color]\n"
	text += "Increases maximum mana, spell damage and trigger chances for all towers in 300 range by 2%."
	text += " \n"
	text += "[color=ORANGE]Level Bonus:[/color]\n"
	text += "+0.4% maximum mana\n"
	text += "+0.4% spell damage\n"
	text += "+0.4% trigger chances\n"

	return text


func load_modifier(modifier: Modifier):
	modifier.add_modification(Modification.Type.MOD_DAMAGE_ADD_PERC, -0.20, 0.0)
	modifier.add_modification(Modification.Type.MOD_SPELL_DAMAGE_DEALT, -0.20, 0.0)


func tower_init():
	var m: Modifier = Modifier.new()
	poussix_multi_aura = BuffType.create_aura_effect_type("poussix_multi_aura", true, self)
	m.add_modification(Modification.Type.MOD_TRIGGER_CHANCES, 0.02, 0.004)
	m.add_modification(Modification.Type.MOD_MANA_PERC, 0.02, 0.004)
	m.add_modification(Modification.Type.MOD_SPELL_DAMAGE_DEALT, 0.02, 0.004)
	poussix_multi_aura.set_buff_modifier(m)
	poussix_multi_aura.set_stacking_group("multi_aura")
	poussix_multi_aura.set_buff_icon("@@0@@")

	poussix_multi_aura.set_buff_tooltip("Charitable Presence\nA nearby tower is being charitable. This tower's maximum mana, spell damage and trigger chances are increased.")

	var aura_type: AuraType = AuraType.new()
	aura_type.aura_range = 300
	aura_type.target_type = TargetType.new(TargetType.TOWERS)
	aura_type.target_self = true
	aura_type.level = 0
	aura_type.level_add = 1
	aura_type.power = 0
	aura_type.power_add = 1
	aura_type.aura_effect = poussix_multi_aura
	add_aura(aura_type)
