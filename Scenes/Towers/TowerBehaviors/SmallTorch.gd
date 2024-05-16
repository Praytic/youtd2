extends TowerBehavior


func get_tier_stats() -> Dictionary:
	return {
		1: {damage = 60, damage_add = 3},
		2: {damage = 215, damage_add = 11},
		3: {damage = 600, damage_add = 30},
		4: {damage = 1200, damage_add = 60},
		5: {damage = 2150, damage_add = 107},
}


func create_autocasts() -> Array[Autocast]:
	var autocast: Autocast = Autocast.make()

	var damage: String = Utils.format_float(_stats.damage, 2)
	var damage_add: String = Utils.format_float(_stats.damage_add, 2)

	autocast.title = "Fire Blast"
	autocast.icon = "res://resources/Icons/elements/fire.tres"
	autocast.description_short = "Deals spell damage in a small area with magical flames.\n"
	autocast.description = "Releases a blast of fire that strikes all targets in 200 AoE around the main target for %s damage.\n" % damage \
	+ " \n" \
	+ "[color=ORANGE]Level Bonus:[/color]\n" \
	+ "+%s damage\n" % damage_add

	autocast.caster_art = ""
	autocast.num_buffs_before_idle = 0
	autocast.autocast_type = Autocast.Type.AC_TYPE_OFFENSIVE_UNIT
	autocast.cast_range = 900
	autocast.target_self = false
	autocast.target_art = ""
	autocast.cooldown = 1
	autocast.is_extended = false
	autocast.mana_cost = 20
	autocast.buff_type = null
	autocast.target_type = null
	autocast.auto_range = 900
	autocast.handler = on_autocast

	return [autocast]


func on_autocast(event: Event):
	SFX.sfx_at_unit("Abilities\\Spells\\Other\\Incinerate\\FireLordDeathExplode.mdl", event.get_target())
	tower.do_spell_damage_aoe_unit(event.get_target(), 200, _stats.damage + _stats.damage_add * tower.get_level(), tower.calc_spell_crit_no_bonus(), 0.0)
