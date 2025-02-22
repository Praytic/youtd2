extends ItemBehavior


func load_triggers(triggers: BuffType):
	triggers.add_event_on_damage(on_damage)


func on_damage(event: Event):
	var target: Creep = event.get_target()

	if target.get_armor_type() == ArmorType.enm.SOL:
		event.damage = event.damage * 1.25
	
		var effect: int = Effect.create_simple_at_unit("res://src/effects/frag_boom_spawn.tscn", target)
		Effect.set_color(effect, Color.DARK_BLUE)
