extends Tower


func _get_tier_stats() -> Dictionary:
	return {
		1: {damage = 70, damage_add = 3.5},
		2: {damage = 250, damage_add = 12.5},
		3: {damage = 700, damage_add = 35},
		4: {damage = 1400, damage_add = 70},
		5: {damage = 2500, damage_add = 125},
}


func _tower_init():
	var autocast: Autocast = Autocast.make()
	autocast.caster_art = ""
	autocast.num_buffs_before_idle = 0
	autocast.autocast_type = Autocast.Type.AC_TYPE_OFFENSIVE_UNIT
	autocast.the_range = 1200
	autocast.target_self = false
	autocast.target_art = ""
	autocast.cooldown = 1
	autocast.is_extended = false
	autocast.mana_cost = 20
	autocast.buff_type = 0
	autocast.target_type = TargetType.new(TargetType.UnitType.MOBS)
	autocast.auto_range = 1200
	autocast.handler = on_autocast

	add_autocast(autocast)


func on_autocast(event: Event):
	var tower: Tower = self

	var creep: Unit = event.get_target()
	tower.do_spell_damage(creep, _stats.damage + (tower.get_level() * _stats.damage_add), tower.calc_spell_crit_no_bonus())
	Utils.sfx_on_unit("Abilities\\Spells\\Other\\Monsoon\\MonsoonBoltTarget.mdl", creep, "origin")
