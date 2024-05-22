extends TowerBehavior


func get_tier_stats() -> Dictionary:
	return {
		1: {damage = 70, damage_add = 3.5},
		2: {damage = 250, damage_add = 12.5},
		3: {damage = 700, damage_add = 35},
		4: {damage = 1400, damage_add = 70},
		5: {damage = 2500, damage_add = 125},
}


func create_autocasts() -> Array[Autocast]:
	var autocast: Autocast = Autocast.make()

	var damage: String = Utils.format_float(_stats.damage, 2)
	var damage_add: String = Utils.format_float(_stats.damage_add, 2)

	autocast.title = "Release Lightning"
	autocast.icon = "res://resources/icons/electricity/lightning_glowing.tres"
	autocast.description_short = "Releases a lightning bolt."
	autocast.description = "Releases a lightning bolt that strikes the target for %s spell damage.\n" % damage \
	+ " \n" \
	+"[color=ORANGE]Level Bonus:[/color]\n" \
	+ "+%s spell damage\n" % damage_add
	autocast.caster_art = ""
	autocast.num_buffs_before_idle = 0
	autocast.autocast_type = Autocast.Type.AC_TYPE_OFFENSIVE_UNIT
	autocast.cast_range = 1200
	autocast.target_self = false
	autocast.target_art = ""
	autocast.cooldown = 1
	autocast.is_extended = false
	autocast.mana_cost = 20
	autocast.buff_type = null
	autocast.target_type = null
	autocast.auto_range = 1200
	autocast.handler = on_autocast

	return [autocast]


func on_autocast(event: Event):
	var creep: Unit = event.get_target()
	tower.do_spell_damage(creep, _stats.damage + (tower.get_level() * _stats.damage_add), tower.calc_spell_crit_no_bonus())
	SFX.sfx_on_unit("Abilities\\Spells\\Other\\Monsoon\\MonsoonBoltTarget.mdl", creep, Unit.BodyPart.ORIGIN)
