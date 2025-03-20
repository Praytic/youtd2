extends ItemBehavior


func load_triggers(triggers: BuffType):
	triggers.add_event_on_damage(on_damage)


func on_damage(event: Event):
	var T: Creep = event.get_target()

	if T.get_armor_type() == ArmorType.enm.HEL:
		event.damage = event.damage * 1.25
		Effect.create_simple_at_unit("res://src/effects/dispel_magic_target.tscn", T)
