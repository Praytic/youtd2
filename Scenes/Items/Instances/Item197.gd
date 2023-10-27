# Magnetic Field
extends Item


var dave_magnetic: BuffType


func get_ability_description() -> String:
	var text: String = ""

	text += "[color=GOLD]Magnetic Field - Aura[/color]\n"
	text += "Grants +10% buff duration and -15% debuff duration to all towers within 200 range.\n"

	return text


func item_init():
	var m: Modifier = Modifier.new()
	dave_magnetic = BuffType.create_aura_effect_type("example_buff", true, self)
	m.add_modification(Modification.Type.MOD_DEBUFF_DURATION, -0.15, 0.0)
	m.add_modification(Modification.Type.MOD_BUFF_DURATION, 0.1, 0.0)
	dave_magnetic.set_buff_modifier(m)
	dave_magnetic.set_buff_icon("@@0@@")
	dave_magnetic.set_buff_tooltip("Magnetic Field\nThis unit is under the effect of Magnetic Field Aura; it has increased buff duration and reduced debuff duration.")

	var aura: AuraType = AuraType.new()
	aura.aura_range = 200
	aura.target_type = TargetType.new(TargetType.TOWERS)
	aura.target_self = true
	aura.level = 0
	aura.level_add = 0
	aura.power = 1
	aura.power_add = 0
	aura.aura_effect = dave_magnetic
	add_aura(aura)
