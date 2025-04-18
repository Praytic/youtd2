extends ItemBehavior


var enraged_bt: BuffType


func load_triggers(triggers: BuffType):
	triggers.add_event_on_kill(on_kill)


func item_init():
	enraged_bt = BuffType.new("enraged_bt", 0, 0, true, self)
	enraged_bt.set_buff_icon("res://resources/icons/generic_icons/mighty_force.tres")
	enraged_bt.set_buff_tooltip(tr("JE2F"))
	var mod: Modifier = Modifier.new()
	mod.add_modification(Modification.Type.MOD_ATTACKSPEED, 0.20, 0.004)
	enraged_bt.set_buff_modifier(mod)


func on_kill(event: Event):
	var tower: Tower = item.get_carrier()

	if tower.get_buff_of_type(enraged_bt) == null:
		SFX.sfx_at_unit(SfxPaths.TELEPORT_BASS, event.get_target())
		Effect.create_simple_at_unit("res://src/effects/stampede_missile_death.tscn", event.get_target())
		enraged_bt.apply_custom_timed(tower, tower, tower.get_level(), 3.0)
