extends Tower


var sir_timevault_aura_bt: BuffType


func get_ability_description() -> String:
	var text: String = ""

	text += "[color=GOLD]Time Travel[/color]\n"
	text += "Damaged targets will be teleported 3 seconds back in time after 3 seconds delay. Has a 20% chance to teleport bosses, all others will be always teleported.\n"
	text += " \n"
	text += "[color=ORANGE]Level Bonus:[/color]\n"
	text += "+0.5% chance for bosses\n"
	text += " \n"
	text += "[color=GOLD]Timesurge - Aura[/color]\n"
	text += "Increases triggerchance of towers in 600 range by 30%.\n"
	text += " \n"
	text += "[color=ORANGE]Level Bonus:[/color]\n"
	text += "+0.6% chance\n"

	return text


func get_ability_description_short() -> String:
	var text: String = ""

	text += "[color=GOLD]Time Travel[/color]\n"
	text += "Damaged targets will be teleported back in time after a delay.\n"
	text += " \n"
	text += "[color=GOLD]Timesurge - Aura[/color]\n"
	text += "Increases triggerchance of nearby towers.\n"

	return text


func load_triggers(triggers: BuffType):
	triggers.add_event_on_damage(on_damage)


func tower_init():
	sir_timevault_aura_bt = BuffType.create_aura_effect_type("sir_timevault_aura_bt", true, self)
	var mod: Modifier = Modifier.new()
	mod.add_modification(Modification.Type.MOD_TRIGGER_CHANCES, 0.30, 0.006)
	sir_timevault_aura_bt.set_buff_modifier(mod)
	sir_timevault_aura_bt.set_buff_icon("@@0@@")
	sir_timevault_aura_bt.set_buff_tooltip("Title\nDescription.")

	var aura: AuraType = AuraType.new()
	aura.aura_range = 600
	aura.target_type = TargetType.new(TargetType.TOWERS)
	aura.target_self = false
	aura.level = 0
	aura.level_add = 1
	aura.power = 0
	aura.power_add = 1
	aura.aura_effect = sir_timevault_aura_bt
	add_aura(aura)


func on_damage(event: Event):
	var tower: Tower = self
	var creep: Creep = event.get_target()
	var target_is_boss: bool = creep.get_size() >= CreepSize.enm.BOSS
	var chance_for_boss: float = 0.20 + 0.005 * tower.get_level()

	if target_is_boss && !tower.calc_chance(chance_for_boss):
		return

	var old_position: Vector2 = creep.position
	var effect: int = Effect.add_special_effect_target("ManaDrainTarget.mdl", creep, "origin")

	await get_tree().create_timer(3.0).timeout

	Effect.destroy_effect(effect)

	if Utils.unit_is_valid(creep):
		creep.teleport_to_old_position(old_position)
		SFX.sfx_at_unit("MassTeleportCaster.mdl", creep)
