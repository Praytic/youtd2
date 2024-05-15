extends ItemBehavior


var resonance_bt: BuffType


func get_ability_description() -> String:
	var text: String = ""

	text += "[color=GOLD]Resonance[/color]\n"
	text += "Whenever the carrier attacks, it has a 10% attack speed adjusted chance to debuff the main target, increasing all spell damage dealt to it by 15% for 5 seconds\n"

	return text


func load_triggers(triggers: BuffType):
	triggers.add_event_on_attack(on_attack)


func item_init():
	resonance_bt = BuffType.new("resonance_bt", 5, 0, false, self)
	resonance_bt.set_buff_icon("res://Resources/Icons/GenericIcons/rss.tres")
	resonance_bt.set_buff_tooltip("Resonance\nIncreases spell damage taken.")
	var mod: Modifier = Modifier.new()
	mod.add_modification(Modification.Type.MOD_SPELL_DAMAGE_RECEIVED, 0.15, 0.0)
	resonance_bt.set_buff_modifier(mod)


func on_attack(event: Event):
	var tower: Tower = item.get_carrier()

	if tower.calc_chance(0.10 * tower.get_base_attack_speed()):
		CombatLog.log_item_ability(item, event.get_target(), "Resonance")
		resonance_bt.apply(tower, event.get_target(), tower.get_level())
