extends TowerBehavior


# NOTE: [ORIGINAL_GAME_BUG] Fixed error in original script
# where "Time Field" buff was "unfriendly" even though it's
# applied on a tower. Changed it to "friendly".


var aura_bt: BuffType
var time_field_bt: BuffType
var multiboard: MultiboardValues
var exp_exchanged: int


func load_triggers(triggers: BuffType):
	triggers.add_periodic_event(periodic, 10)


func tower_init():
	time_field_bt = BuffType.new("time_field_bt", 10, 0, true, self)
	time_field_bt.set_special_effect("res://src/effects/spell_aire.tscn", 150, 1.0)
	time_field_bt.add_periodic_event(time_field_bt_periodic, 1.0)
	time_field_bt.set_buff_icon("res://resources/icons/generic_icons/rss.tres")
	time_field_bt.set_buff_tooltip(tr("ZD87"))

	aura_bt = BuffType.create_aura_effect_type("aura_bt", true, self)
	var aura_bt_mod: Modifier = Modifier.new()
	aura_bt_mod.add_modification(Modification.Type.MOD_EXP_RECEIVED, 0.1, 0.016)
	aura_bt_mod.add_modification(Modification.Type.MOD_ATTACKSPEED, 0.1, 0.01)
	aura_bt_mod.add_modification(Modification.Type.MOD_MANA_REGEN_PERC, 0.05, 0.02)
	aura_bt_mod.add_modification(Modification.Type.MOD_BUFF_DURATION, 0.125, 0.015)
	aura_bt.set_buff_modifier(aura_bt_mod)
	aura_bt.set_buff_icon("res://resources/icons/generic_icons/electric.tres")
	aura_bt.set_buff_tooltip(tr("WG04"))

	multiboard = MultiboardValues.new(1)
	multiboard.set_key(0, "Exp Exchanged")


func on_create(_preceding: Tower):
	exp_exchanged = 0


func on_destruct():
	tower.add_exp_flat(exp_exchanged)


func on_tower_details() -> MultiboardValues:
	var exp_exchanged_string: String = str(exp_exchanged)
	multiboard.set_value(0, exp_exchanged_string)

	return multiboard


func periodic(_event: Event):
	if tower.get_exp() >= 700:
		tower.remove_exp_flat(50)
		exp_exchanged += 50
		tower.modify_property(Modification.Type.MOD_SPELL_DAMAGE_DEALT, 0.05)
		Effect.create_simple_at_unit("res://src/effects/charm_target.tscn", tower, Unit.BodyPart.OVERHEAD)
	else:
		tower.add_exp(2)
		Effect.create_simple_at_unit("res://src/effects/blink_target.tscn", tower, Unit.BodyPart.CHEST)


func on_autocast(_event: Event):
	time_field_bt.apply(tower, tower, tower.get_level())


# NOTE: "MajFieldDamage()" in original script
func time_field_bt_periodic(event: Event):
	var buff: Buff = event.get_buff()
	var caster: Tower = buff.get_caster()
	var damage: float = 1500 + 75 * buff.get_level()

	caster.do_spell_damage_pb_aoe(950, damage, caster.calc_spell_crit_no_bonus(), 0.0)
