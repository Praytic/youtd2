extends ItemBehavior


var slow_bt: BuffType


func get_ability_description() -> String:
	var text: String = ""

	text += "[color=GOLD]Skadi's Influence - Aura[/color]\n"
	text += "Slows movementspeed of creeps in 800 range by 14%.\n"

	return text


func item_init():
	slow_bt = BuffType.create_aura_effect_type("slow_bt", false, self)
	slow_bt.set_stacking_group("slow_bt")
	slow_bt.set_buff_icon("res://Resources/Textures/GenericIcons/foot_trip.tres")
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
	aura.power = 0
	aura.power_add = 1
	aura.aura_effect = slow_bt
	item.add_aura(aura)
