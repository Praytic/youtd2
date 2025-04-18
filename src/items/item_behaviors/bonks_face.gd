extends ItemBehavior



func load_triggers(triggers: BuffType):
	triggers.add_event_on_damage(on_damage)


func on_damage(event: Event):
	var creep: Unit = event.get_target()
	var twr: Unit = item.get_carrier()
	var target_effect: int

	if creep.is_stunned():
		CombatLog.log_item_ability(item, creep, "Crush")
		twr.do_spell_damage_aoe_unit(creep, 250, twr.get_current_attack_damage_with_bonus() * 0.2, twr.calc_spell_crit_no_bonus(), 0)
		target_effect = Effect.create_animated("res://src/effects/impale_target_dust.tscn", Vector3(creep.get_x(), creep.get_y(), 0.0), 0)
		Effect.set_scale(target_effect, 0.5)
