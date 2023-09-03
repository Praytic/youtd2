extends Tower


func get_tier_stats() -> Dictionary:
	return {
		1: {damage = 70, damage_add = 3.5},
		2: {damage = 250, damage_add = 12.5},
		3: {damage = 700, damage_add = 35},
		4: {damage = 1400, damage_add = 70},
		5: {damage = 2500, damage_add = 125},
}


func get_release_lightning_description() -> String:
	var damage: String = Utils.format_float(_stats.damage, 2)
	var damage_add: String = Utils.format_float(_stats.damage_add, 2)

	var text: String = ""

	text += "This tower releases a lightning bolt that strikes the target for %s damage.\n" % damage
	text += " \n"
	text +="[color=ORANGE]Level Bonus:[/color]\n"
	text += "+%s damage\n" % damage_add

	return text


func tower_init():
	var autocast: Autocast = Autocast.make()
	autocast.title = "Release Lightning"
	autocast.description = get_release_lightning_description()
	autocast.icon = "res://Resources/Textures/gold.tres"
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

	add_autocast(autocast)


func on_autocast(event: Event):
	var tower: Tower = self

	var creep: Unit = event.get_target()
	tower.do_spell_damage(creep, _stats.damage + (tower.get_level() * _stats.damage_add), tower.calc_spell_crit_no_bonus())
	SFX.sfx_on_unit("Abilities\\Spells\\Other\\Monsoon\\MonsoonBoltTarget.mdl", creep, "origin")
