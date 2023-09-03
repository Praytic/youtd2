extends Tower


func get_tier_stats() -> Dictionary:
	return {
		1: {damage = 60, damage_add = 3},
		2: {damage = 215, damage_add = 11},
		3: {damage = 600, damage_add = 30},
		4: {damage = 1200, damage_add = 60},
		5: {damage = 2150, damage_add = 107},
}


func get_fire_blast_description() -> String:
	var damage: String = Utils.format_float(_stats.damage, 2)
	var damage_add: String = Utils.format_float(_stats.damage_add, 2)

	var text: String = ""

	text += "Releases a blast of fire that strikes all targets in 200 AoE around the main target for %s damage.\n" % damage
	text += " \n"
	text += "[color=ORANGE]Level Bonus:[/color]\n"
	text += "+%s damage\n" % damage_add

	return text


func tower_init():
	var autocast: Autocast = Autocast.make()
	autocast.title = "Fire Blast"
	autocast.description = get_fire_blast_description()
	autocast.icon = "res://Resources/Textures/gold.tres"
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

	add_autocast(autocast)


func on_autocast(event: Event):
	var tower: Tower = self

	SFX.sfx_at_unit("Abilities\\Spells\\Other\\Incinerate\\FireLordDeathExplode.mdl", event.get_target())
	tower.do_spell_damage_aoe_unit(event.get_target(), 200, _stats.damage + _stats.damage_add * tower.get_level(), tower.calc_spell_crit_no_bonus(), 0.0)
