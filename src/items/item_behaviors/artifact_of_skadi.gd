extends ItemBehavior


var slow_bt: BuffType


func item_init():
	slow_bt = BuffType.create_aura_effect_type("slow_bt", false, self)
	slow_bt.set_buff_icon("res://resources/icons/generic_icons/foot_trip.tres")
	slow_bt.set_buff_tooltip("Skadi's Influence\nReduces movement speed.")
	var mod: Modifier = Modifier.new()
	mod.add_modification(Modification.Type.MOD_MOVESPEED, -0.14, 0.0)
	slow_bt.set_buff_modifier(mod)

	var aura: AuraType = AuraType.new()
	aura.aura_range = 800
	aura.target_type = TargetType.new(TargetType.CREEPS)
	aura.target_self = false
	aura.level = 0
	aura.level_add = 1
	aura.aura_effect = slow_bt
	item.add_aura(aura)
