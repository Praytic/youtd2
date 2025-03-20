extends ItemBehavior


func load_triggers(triggers: BuffType):
	triggers.add_event_on_damage(on_damage)


func on_damage(event: Event):
	var target: Creep = event.get_target()

	if target.get_armor_type() == ArmorType.enm.MYT:
		event.damage = event.damage * 1.25
		Effect.create_simple_at_unit_attached("res://src/effects/crushing_wave.tscn", target)
