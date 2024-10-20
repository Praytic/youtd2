extends ItemBehavior


func load_triggers(triggers: BuffType):
	triggers.add_event_on_damage(on_damage)


func on_damage(event: Event):
	var tower: Tower = item.get_carrier()
	var creep: Creep = event.get_target()

	# var l: Lightning

	if event.is_main_target():
		if creep.subtract_mana((8 + 0.6 * tower.get_level() * tower.get_base_attack_speed()) * (55 / pow(tower.get_base_range(), 0.6)), true) > 0:
			var lightning: InterpolatedSprite = InterpolatedSprite.create_from_unit_to_unit(InterpolatedSprite.LIGHTNING, tower, creep)
			lightning.modulate = Color.LIGHT_GREEN
			lightning.set_lifetime(0.1)
			var effect: int = Effect.create_simple_at_unit("res://src/effects/arcane_tower_attack.tscn", creep)
			Effect.set_color(effect, Color.LIGHT_BLUE)
