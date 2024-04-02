# Artifact of Skadi
extends ItemBehavior


var boekie_skadi_bt: BuffType


func get_ability_description() -> String:
	var text: String = ""

	text += "[color=GOLD]Skadi's Influence - Aura[/color]\n"
	text += "Slows movementspeed of creeps in 800 range by 14%.\n"

	return text


func item_init():
	boekie_skadi_bt = BuffType.create_aura_effect_type("boekie_skadi_bt", false, self)
	boekie_skadi_bt.set_stacking_group("boekie_skadi_bt")
	boekie_skadi_bt.set_buff_icon("foot.tres")
	boekie_skadi_bt.set_buff_tooltip("Skadi's Influence\nReduces movement speed.")
	var mod: Modifier = Modifier.new()
	mod.add_modification(Modification.Type.MOD_MOVESPEED, -0.14, 0.0)
	boekie_skadi_bt.set_buff_modifier(mod)

	var aura: AuraType = AuraType.new()
	aura.aura_range = 800
	aura.target_type = TargetType.new(TargetType.CREEPS)
	aura.target_self = false
	aura.level = 0
	aura.level_add = 1
	aura.power = 0
	aura.power_add = 1
	aura.aura_effect = boekie_skadi_bt
	item.add_aura(aura)
