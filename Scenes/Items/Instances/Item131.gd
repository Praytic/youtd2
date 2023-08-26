# Mana Stone
extends Item


var fright_mana_aura: BuffType


func get_extra_tooltip_text() -> String:
	var text: String = ""

	text += "[color=GOLD]Mana Charge[/color]\n"
	text += "On every 3rd attack the carrier regenerates 1% of its maximum mana.\n"
	text += " \n"
	text += "[color=GOLD]Absorb[/color]\n"
	text += "Whenever the carrier kills a creep it regenerates 3% of its maximum mana.\n"
	text += " \n"
	text += "[color=GOLD]Mana Aura - Aura[/color]\n"
	text += "Increases mana regeneration of all towers in 200 range of the carrier by 7.5%.\n"

	return text


func load_triggers(triggers: BuffType):
	triggers.add_event_on_attack(on_attack)
	triggers.add_event_on_kill(on_kill)


func item_init():
	var m: Modifier = Modifier.new() 
	fright_mana_aura = BuffType.create_aura_effect_type("fright_mana_aura", true, self)
	m.add_modification(Modification.Type.MOD_MANA_REGEN_PERC, 0.075, 0.0) 
	fright_mana_aura.set_buff_modifier(m) 
	fright_mana_aura.set_buff_icon("@@0@@")
	fright_mana_aura.set_buff_tooltip("Mana Aura\nThis unit is under the effect of Mana Aura; it has increased mana regeneration.")

	var aura: AuraType = AuraType.new()
	aura.aura_range = 200
	aura.target_type = TargetType.new(TargetType.TOWERS)
	aura.target_self = true
	aura.level = 0
	aura.level_add = 1
	aura.power = 0
	aura.power_add = 1
	aura.aura_effect = fright_mana_aura
	add_aura(aura)


func on_attack(_event: Event):
	var itm: Item = self
	itm.user_int = itm.user_int + 1

	if itm.user_int == 3:
		itm.get_carrier().add_mana_perc(0.01)
		itm.user_int = 0


func on_pickup():
	var itm: Item = self
	itm.user_int = 0


func on_kill(event: Event):
	var itm: Item = self
	var tower: Tower = itm.get_carrier()
	var effect: int = Effect.create_scaled("SpiritTouchTarget.mdl", tower.get_visual_position().x, tower.get_visual_position().y, 10.0, 0.0, 1.2)
	Effect.destroy_effect_after_its_over(effect)

