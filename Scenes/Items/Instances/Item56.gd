# Bhaal's Essence
extends Item


# NOTE: fixed an error in original script. Slow modifier
# wasn't added to aura effect type.

# thanks to Gex "ice core" aura
var poussix_fright_aura: BuffType


func get_extra_tooltip_text() -> String:
	var text: String = ""

	text += "[color=GOLD]Fright Aura - Aura[/color]\n"
	text += "Slows movement speed of enemies in 650 range by 10% and decreases their armor by 4.\n"
	text += " \n"
	text += "[color=ORANGE]Level Bonus:[/color]\n"
	text += "+0.2% slow\n"
	text += "+0.2 armor\n"

	return text


func load_modifier(modifier: Modifier):
	modifier.add_modification(Modification.Type.MOD_DEBUFF_DURATION, -0.60, 0.0)


func item_init():
	var m: Modifier = Modifier.new()
	poussix_fright_aura = BuffType.create_aura_effect_type("poussix_fright_aura", true, self)
	m.add_modification(Modification.Type.MOD_MOVESPEED, -0.10, -0.0020)
	m.add_modification(Modification.Type.MOD_ARMOR, -4.00, -0.2)
	poussix_fright_aura.set_buff_modifier(m)
	poussix_fright_aura.set_stacking_group("fright_aura")
	poussix_fright_aura.set_buff_icon("@@0@@")
	poussix_fright_aura.set_buff_tooltip("Fright\nThis unit is under the effect of Fright Aura; it has reduced movement speed and armor.")

	var aura: AuraType = AuraType.new()
	aura.aura_range = 650
	aura.target_type = TargetType.new(TargetType.CREEPS)
	aura.target_self = false
	aura.level = 0
	aura.level_add = 1
	aura.power = 0
	aura.power_add = 1
	aura.aura_effect = poussix_fright_aura
	add_aura(aura)
