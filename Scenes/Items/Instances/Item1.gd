# Artifact of Skadi
extends Item


var boekie_skadiSlow_aura: BuffType


func get_ability_description() -> String:
	var text: String = ""

	text += "[color=GOLD]Skadi's Influence - Aura[/color]\n"
	text += "Slows movementspeed of creeps in 800 range by 14%.\n"

	return text


func item_init():
	var m: Modifier = Modifier.new()
	boekie_skadiSlow_aura = BuffType.create_aura_effect_type("boekie_skadiSlow_aura", false, self)
	m.add_modification(Modification.Type.MOD_MOVESPEED, -0.14, 0.0)
	boekie_skadiSlow_aura.set_buff_modifier(m)
	boekie_skadiSlow_aura.set_stacking_group("boekie_skadiSlow_aura")
	boekie_skadiSlow_aura.set_buff_icon("@@0@@")
	boekie_skadiSlow_aura.set_buff_tooltip("Skadi's Influence\nThis unit is under the effect of Skadi's Influence Aura; it has reduced movement speed.")

	var aura: AuraType = AuraType.new()
	aura.aura_range = 800
	aura.target_type = TargetType.new(TargetType.CREEPS)
	aura.target_self = false
	aura.level = 0
	aura.level_add = 1
	aura.power = 0
	aura.power_add = 1
	aura.aura_effect = boekie_skadiSlow_aura
	add_aura(aura)
