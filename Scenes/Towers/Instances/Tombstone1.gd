extends Tower

# TODO: find out "required element level" and "required wave level" for .csv file
# TODO: add sprites and icons
# TODO: instant kill looks weird because mob disappears and projectile doesn't fly to it. Confirm what is the concept of "attack". Currently "attack" is the moment before projectile is shot.

const _stats_map: Dictionary = {
	1: {chance_base = 0.008, chance_add = 0.0015},
	2: {chance_base = 0.010, chance_add = 0.0017},
	3: {chance_base = 0.012, chance_add = 0.0020},
	4: {chance_base = 0.014, chance_add = 0.0022},
	5: {chance_base = 0.016, chance_add = 0.0024},
	6: {chance_base = 0.020, chance_add = 0.0025},
}


func _ready():
	var tombs_curse = Buff.new("tombs_curse")
	tombs_curse.add_event_handler(Buff.EventType.DAMAGE, self, "on_damage")
	tombs_curse.apply_to_unit_permanent(self, self, 0, true)


func on_damage(event: Event):
	var tier: int = get_tier()
	var stats = _stats_map[tier]
	var chance: float = stats.chance_base + get_level() * stats.chance_add
	var trigger_success: bool = calc_bad_chance(chance)

	if !trigger_success:
		return

	var mob: Mob = event.get_target() as Mob
	var mob_size: int = mob.get_size()

	if mob_size < Mob.Size.CHAMPION:
		kill_instantly(mob)
		Utils.sfx_at_unit("Abilities\\Spells\\Undead\\DeathCoil\\DeathCoilSpecialArt.mdl", mob)
