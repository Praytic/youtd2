# Mana Stone
extends ItemBehavior


var aura_bt: BuffType


func get_ability_description() -> String:
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
	aura_bt = BuffType.create_aura_effect_type("aura_bt", true, self)
	aura_bt.set_buff_icon("letter_omega.tres")
	aura_bt.set_buff_tooltip("Mana Aura\nIncreases mana regeneration.")
	var mod: Modifier = Modifier.new() 
	mod.add_modification(Modification.Type.MOD_MANA_REGEN_PERC, 0.075, 0.0) 
	aura_bt.set_buff_modifier(mod)

	var aura: AuraType = AuraType.new()
	aura.aura_range = 200
	aura.target_type = TargetType.new(TargetType.TOWERS)
	aura.target_self = true
	aura.level = 0
	aura.level_add = 1
	aura.power = 0
	aura.power_add = 1
	aura.aura_effect = aura_bt
	item.add_aura(aura)


func on_attack(_event: Event):
	item.user_int = item.user_int + 1

	if item.user_int == 3:
		item.get_carrier().add_mana_perc(0.01)
		item.user_int = 0


func on_pickup():
	item.user_int = 0


func on_kill(_event: Event):
	var tower: Tower = item.get_carrier()
	var effect: int = Effect.create_scaled("SpiritTouchTarget.mdl", tower.get_visual_position().x, tower.get_visual_position().y, 10.0, 0.0, 5)
	Effect.destroy_effect_after_its_over(effect)

