# Staff of the Wild Equus
extends ItemBehavior


# NOTE: original script moves lifted creeps a little by
# random offset. Removed it because youtd2 creeps are
# supposed to always be "on rails", on creep path.


var ascended_bt: BuffType


func get_ability_description() -> String:
	var text: String = ""

	text += "[color=GOLD]Ascension[/color]\n"
	text += "Each attack has an 8% base attackspeed adjusted chance to ascend the target creep, lifting it up for 2 seconds and making it grant 20% more experience when killed in the air. Only works on normal and mass creeps.\n"
	text += " \n"
	text += "[color=ORANGE]Level Bonus:[/color]\n"
	text += "+0.8% experience\n"

	return text


func load_triggers(triggers_buff_type: BuffType):
	triggers_buff_type.add_event_on_damage(on_damage)


# NOTE: drol_lift_up() in original script
func ascended_bt_on_create(event: Event):
	var b: Buff = event.get_buff()
	var c: Unit = b.get_buffed_unit()
	b.user_int = Effect.create_simple_on_unit("res://Scenes/Effects/SpiritOfVengeanceMissile.tscn", c, Unit.BodyPart.ORIGIN)
	c.adjust_height(300, 150)


# NOTE: drol_lift_period() in original script
func ascended_bt_periodic(event: Event):
	var b: Buff = event.get_buff()
	var c: Unit = b.get_buffed_unit()
	c.set_unit_facing(c.get_unit_facing() + 125)


# NOTE: drol_lift_down() in original script
func ascended_bt_on_cleanup(event: Event):
	var b: Buff = event.get_buff()
	var c: Unit = b.get_buffed_unit()
	c.adjust_height(-300, 2500)
	Effect.destroy_effect(b.user_int)
	var bolt_impact: int = Effect.create_simple_at_unit("res://Scenes/Effects/WarStompCaster.tscn", c)
	Effect.destroy_effect_after_its_over(bolt_impact)


func item_init():
	ascended_bt = CbStun.new("ascended_bt", 2.0, 0, false, self)
	ascended_bt.set_buff_icon("res://Resources/Textures/GenericIcons/star_swirl.tres")
	ascended_bt.set_buff_tooltip("Ascended\nStuns and increases experience granted if killed while in the air.")
	ascended_bt.add_event_on_create(ascended_bt_on_create)
	ascended_bt.add_periodic_event(ascended_bt_periodic, 0.1)
	ascended_bt.add_event_on_cleanup(ascended_bt_on_cleanup)
	var mod: Modifier = Modifier.new()
	mod.add_modification(Modification.Type.MOD_EXP_GRANTED, 0.2, 0.008)
	ascended_bt.set_buff_modifier(mod)


func on_damage(event: Event):
	var tower: Tower = item.get_carrier()
	var size: CreepSize.enm = event.get_target().get_size()

	if event.is_main_target() && tower.calc_chance(0.08 * tower.get_base_attackspeed()) && (size == CreepSize.enm.MASS || size == CreepSize.enm.CHALLENGE_MASS || size == CreepSize.enm.NORMAL):
		CombatLog.log_item_ability(item, null, "Ascension")
		ascended_bt.apply(tower, event.get_target(), tower.get_level())
