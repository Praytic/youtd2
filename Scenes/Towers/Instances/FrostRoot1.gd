extends Tower


const _stats_map: Dictionary = {
	1: {damage = 25, damage_add = 1},
	2: {damage = 125, damage_add = 5},
	3: {damage = 375, damage_add = 15},
	4: {damage = 750, damage_add = 30},
	5: {damage = 1500, damage_add = 60},
	6: {damage = 2500, damage_add = 100},
}

func _ready():
	var frozen_thorn_buff: Buff = Buff.new("frozen_thorn")
	frozen_thorn_buff.add_event_handler(Buff.EventType.DAMAGE, self, "_on_damage")

	frozen_thorn_buff.apply_to_unit_permanent(self, self, 0, false)


func _on_damage(event: Event):
	var tower = self
	var tier: int = get_tier()
	var stats = _stats_map[tier]

	if event.is_main_target() && tower.calc_chance(0.15) && !event.get_target().is_immune():
		Utils.sfx_at_unit("Abilities\\Spells\\Undead\\FrostArmor\\FrostArmorDamage.mdl", event.get_target())
		tower.do_spell_damage(event.get_target(), stats.damage + stats.damage_add * get_level(), tower.calc_spell_crit_no_bonus(), false)
