extends ItemBehavior


func load_triggers(triggers: BuffType):
	triggers.add_event_on_damage(on_damage)


func on_damage(event: Event):
	var t: Creep = event.get_target()

	if t.get_armor_type() == ArmorType.enm.SIF:
		item.get_carrier().do_spell_damage(t, event.damage * 0.25, item.get_carrier().calc_spell_crit_no_bonus())
		Effect.create_simple_at_unit("res://src/effects/spell_breaker_target.tscn", t)
