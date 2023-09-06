# Staff of the Wild Equus
extends Item


var drol_liftBuff: BuffType


func get_extra_tooltip_text() -> String:
	var text: String = ""

	text += "[color=GOLD]Ascension[/color]\n"
	text += "Each attack has an 8% base attackspeed adjusted chance to ascend the target creep, lifting it up for 2 seconds and making it grant 20% more experience when killed in the air. Only works on normal and mass creeps.\n"
	text += " \n"
	text += "[color=ORANGE]Level Bonus:[/color]\n"
	text += "+0.8% experience\n"

	return text


func load_triggers(triggers_buff_type: BuffType):
	triggers_buff_type.add_event_on_damage(on_damage)


func drol_lift_up(event: Event):
	var b: Buff = event.get_buff()
	var c: Unit = b.get_buffed_unit()
	b.user_int = Effect.create_simple_on_unit("res://Scenes/Effects/SpiritOfVengeanceMissile.tscn", c, "origin")
	c.adjust_height(300, 150)


func drol_lift_period(event: Event):
	var b: Buff = event.get_buff()
	var c: Unit = b.get_buffed_unit()
#	TODO: implement move to point
# 	c.move_to_point(c.getX() + GetRandomReal(-5, 5), c.getY() + GetRandomReal(-5, 5), true)
	c.set_unit_facing(c.get_unit_facing() + 125)


func drol_lift_down(event: Event):
	var b: Buff = event.get_buff()
	var c: Unit = b.get_buffed_unit()
	c.adjust_height(-300, 2500)
	Effect.destroy_effect(b.user_int)
	var bolt_impact: int = Effect.create_simple_at_unit("res://Scenes/Effects/WarStompCaster.tscn", c)
	Effect.destroy_effect_after_its_over(bolt_impact)


func item_init():
	var m: Modifier = Modifier.new()
	m.add_modification(Modification.Type.MOD_EXP_GRANTED, 0.2, 0.008)

	drol_liftBuff = CbStun.new("drol_liftBuff", 2.0, 0, false, self)
	drol_liftBuff.add_event_on_create(drol_lift_up)
	drol_liftBuff.add_periodic_event(drol_lift_period, 0.1)
	drol_liftBuff.add_event_on_cleanup(drol_lift_down)
	drol_liftBuff.set_buff_modifier(m)
	drol_liftBuff.set_buff_icon("@@0@@")
	drol_liftBuff.set_buff_tooltip("Ascended\nThis unit has been Ascended; it can't move and will grant extra experience if killed while in the air.")


func on_damage(event: Event):
	var itm: Item = self
	var tower: Tower = itm.get_carrier()
	var size: CreepSize.enm = event.get_target().get_size()

	if event.is_main_target() && tower.calc_chance(0.08 * tower.get_base_attack_speed()) && (size == CreepSize.enm.MASS || size == CreepSize.enm.CHALLENGE_MASS || size == CreepSize.enm.NORMAL):
		drol_liftBuff.apply(tower, event.get_target(), tower.get_level())
