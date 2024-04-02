# Mystical Shell
extends ItemBehavior


var drol_mystical_shell_bt: BuffType


func get_ability_description() -> String:
	var text: String = ""

	text += "[color=GOLD]Resonance[/color]\n"
	text += "Grants the carrier a 10% attackspeed adjusted chance to debuff the attacked target, increasing all spelldamage dealt to it by 15% for 5 seconds\n"

	return text


func load_triggers(triggers: BuffType):
	triggers.add_event_on_attack(on_attack)


func item_init():
	drol_mystical_shell_bt = BuffType.new("drol_mystical_shell_bt", 5, 0, false, self)
	drol_mystical_shell_bt.set_buff_icon("orb_swirly.tres")
	drol_mystical_shell_bt.set_buff_tooltip("Resonance\nIncreases spell damage taken.")
	var mod: Modifier = Modifier.new()
	mod.add_modification(Modification.Type.MOD_SPELL_DAMAGE_RECEIVED, 0.15, 0.0)
	drol_mystical_shell_bt.set_buff_modifier(mod)


func on_attack(event: Event):
	var tower: Tower = item.get_carrier()

	if tower.calc_chance(0.10 * tower.get_base_attackspeed()):
		CombatLog.log_item_ability(item, event.get_target(), "Resonance")
		drol_mystical_shell_bt.apply(tower, event.get_target(), tower.get_level())
