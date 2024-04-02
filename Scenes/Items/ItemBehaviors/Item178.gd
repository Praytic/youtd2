# Dark Matter Trident
extends ItemBehavior


var cedi_trident_positive_bt: BuffType
var cedi_trident_negative_bt: BuffType


func get_ability_description() -> String:
	var text: String = ""

	text += "[color=GOLD]Drain Physical Energy[/color]\n"
	text += "Whenever the carrier of this item hits a creep, the carrier gains 2% attackspeed and the creep is slowed by 2%. Both effects are attackspeed adjusted, last 5 seconds and stack up to 20 times.\n"
	text += " \n"
	text += "[color=ORANGE]Level Bonus:[/color]\n"
	text += "+0.1 second duration\n"

	return text


func load_triggers(triggers: BuffType):
	triggers.add_event_on_damage(on_damage)


func item_init():
	cedi_trident_positive_bt = BuffType.new("cedi_trident_positive_bt", 2.5, 0.0, false, self)
	cedi_trident_positive_bt.set_buff_icon("crystal.tres")
	cedi_trident_positive_bt.set_buff_tooltip("Boost Physical Energy\nIncreases attack speed.")
	var cedi_trident_positive_bt_mod: Modifier = Modifier.new()
	cedi_trident_positive_bt_mod.add_modification(Modification.Type.MOD_MOVESPEED, 0.0, -0.0002)
	cedi_trident_positive_bt.set_buff_modifier(cedi_trident_positive_bt_mod)

	cedi_trident_negative_bt = BuffType.new("cedi_trident_negative_bt", 2.5, 0.0, true, self)
	cedi_trident_negative_bt.set_buff_icon("foot.tres")
	cedi_trident_negative_bt.set_buff_tooltip("Drain Physical Energy\nReduces movement speed.")
	var cedi_trident_negative_bt_mod: Modifier = Modifier.new()
	cedi_trident_negative_bt_mod.add_modification(Modification.Type.MOD_ATTACKSPEED, 0.0, 0.0002)
	cedi_trident_negative_bt.set_buff_modifier(cedi_trident_negative_bt_mod)


func on_damage(event: Event):
	if !event.is_main_target():
		return

	var tower: Tower = item.get_carrier()
	var creep: Creep = event.get_target()
	var level_add: int = int(100.0 * tower.get_current_attackspeed())
	var duration: float = 5 + 0.1 * tower.get_level()

	var positive_buff: Buff = tower.get_buff_of_type(cedi_trident_positive_bt)
	if positive_buff != null:
		cedi_trident_positive_bt.apply_custom_timed(tower, tower, min(level_add + positive_buff.get_level(), 2000), duration)
	else:
		cedi_trident_positive_bt.apply_custom_timed(tower, tower, level_add, duration)

	var negative_buff: Buff = creep.get_buff_of_type(cedi_trident_negative_bt)
	if negative_buff != null:
		cedi_trident_negative_bt.apply_custom_timed(tower, creep, min(level_add + negative_buff.get_level(), 2000), duration)
	else:
		cedi_trident_negative_bt.apply_custom_timed(tower, creep, level_add, duration)
