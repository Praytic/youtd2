extends ItemBehavior


# NOTE: [ORIGINAL_GAME_DEVIATION] Day/night mechanic is not
# implemented so changed this item effect to be average
# between day and night. Original script gives 2 during day
# and 4 at night, so average it down to 3.


func load_triggers(triggers: BuffType):
	triggers.add_periodic_event(periodic, 15)


func load_modifier(modifier: Modifier):
	modifier.add_modification(Modification.Type.MOD_TRIGGER_CHANCES, 0.20, 0.0)


func periodic(_event: Event):
	var target_effect: int
	var tower: Unit = item.get_carrier()

	target_effect = Effect.create_scaled("res://src/effects/dispel_magic_target.tscn", tower.get_position_wc3(), 0, 2)
	Effect.set_lifetime(target_effect, 2.0)

	CombatLog.log_item_ability(item, null, "Celestial Wisdom")
	tower.add_exp(3.0)
