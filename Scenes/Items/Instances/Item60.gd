# Flag of the Alliance
extends Item


var boekie_alliance_aura: BuffType


func get_extra_tooltip_text() -> String:
	var text: String = ""

	text += "[color=GOLD]Motivation - Aura[/color]\n"
	text += "Increases attackspeed of towers in 1000 range by 5%.\n"
	text += " \n"
	text += "[color=ORANGE]Level Bonus:[/color]\n"
	text += "+0.1% attackspeed\n"

	return text


func item_init():
	var m: Modifier = Modifier.new() 
	boekie_alliance_aura = BuffType.create_aura_effect_type("boekie_alliance_aura", true, self)
	m.add_modification(Modification.Type.MOD_ATTACKSPEED, 0.05, 0.001) 
	boekie_alliance_aura.set_buff_modifier(m) 
	boekie_alliance_aura.set_stacking_group("boekie_alliance_aura")
	boekie_alliance_aura.set_buff_icon("@@0@@")
	boekie_alliance_aura.set_buff_tooltip("Alliance Effect\nThis unit's attackspeed is increased.")

	var aura: AuraType = AuraType.new()
	aura.aura_range = 1000
	aura.target_type = TargetType.new(TargetType.TOWERS)
	aura.target_self = true
	aura.level = 0
	aura.level_add = 1
	aura.power = 0
	aura.power_add = 1
	aura.aura_effect = boekie_alliance_aura
	add_aura(aura)
