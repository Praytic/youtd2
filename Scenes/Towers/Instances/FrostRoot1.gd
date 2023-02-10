extends Tower


const _tier_stats_map: Dictionary = {
	1: {damage = 25, damage_add = 1},
	2: {damage = 125, damage_add = 5},
	3: {damage = 375, damage_add = 15},
	4: {damage = 750, damage_add = 30},
	5: {damage = 1500, damage_add = 60},
	6: {damage = 2500, damage_add = 100},
}

func _ready():
	var frozen_thorn_buff: Buff = Buff.new("frozen_thorn")
	frozen_thorn_buff.add_event_handler_with_chance(Buff.EventType.DAMAGE, self, "_on_damage", 1.0, 0.0)

	frozen_thorn_buff.apply_to_unit_permanent(self, self, 0, false)


func _on_damage(event: Event):
	var event_target: Unit = event.get_target()

	if event.is_main_target() && calc_chance(0.15) && !event_target.is_immune():
		Utils.sfx_at_unit("Abilities\\Spells\\Undead\\FrostArmor\\FrostArmorDamage.mdl", event_target)

		var tier: int = get_tier()
		var stats = _tier_stats_map[tier]

		var damage: float = stats.damage + stats.damage_add * get_level()

		do_spell_damage(event_target, damage, calc_spell_crit_no_bonus(), false)
