extends Tower

# TODO: find out "required element level" and "required wave level" for .csv file
# TODO: add sprites and icons
# TODO: instant kill looks weird because creep disappears and projectile doesn't fly to it. Confirm what is the concept of "attack". Currently "attack" is the moment before projectile is shot.


func _get_tier_stats() -> Dictionary:
	return {
		1: {chance_base = 0.008, chance_add = 0.0015},
		2: {chance_base = 0.010, chance_add = 0.0017},
		3: {chance_base = 0.012, chance_add = 0.0020},
		4: {chance_base = 0.014, chance_add = 0.0022},
		5: {chance_base = 0.016, chance_add = 0.0024},
		6: {chance_base = 0.020, chance_add = 0.0025},
	}


func load_triggers(triggers_buff_type: BuffType):
	triggers_buff_type.add_event_on_damage(self, "on_damage", _stats.chance_base, _stats.chance_add)


func on_damage(event: Event):
	var tower = self

	var creep: Unit = event.get_target()
	var size: int = creep.get_creep_size()

	if size < Creep.Size.CHAMPION:
		tower.kill_instantly(creep)
		Utils.sfx_at_unit("Abilities\\Spells\\Undead\\DeathCoil\\DeathCoilSpecialArt.mdl", creep)
