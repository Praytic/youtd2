extends Tower


func _get_tier_stats() -> Dictionary:
	return {
		1: {damage = 60, damage_add = 3},
		2: {damage = 215, damage_add = 11},
		3: {damage = 600, damage_add = 30},
		4: {damage = 1200, damage_add = 60},
		5: {damage = 2150, damage_add = 107},
}


func _tower_init():
	var attack_autocast_data: Autocast.Data = Autocast.Data.new()
	attack_autocast_data.caster_art = ""
	attack_autocast_data.num_buffs_before_idle = 0
	attack_autocast_data.autocast_type = Autocast.Type.AC_TYPE_OFFENSIVE_UNIT
	attack_autocast_data.the_range = 900
	attack_autocast_data.target_self = false
	attack_autocast_data.target_art = ""
	attack_autocast_data.cooldown = 1
	attack_autocast_data.is_extended = false
	attack_autocast_data.mana_cost = 20
	attack_autocast_data.buff_type = 0
	attack_autocast_data.target_type = TargetType.new(TargetType.UnitType.MOBS)
	attack_autocast_data.auto_range = 900

	var autocast_buff: Buff = TriggersBuff.new()
	_attack_autocast = autocast_buff.add_autocast(attack_autocast_data, self, "on_autocast")
	autocast_buff.apply_to_unit_permanent(self, self, 0)


func on_autocast(event: Event):
	var tower: Tower = self

	Utils.sfx_at_unit("Abilities\\Spells\\Other\\Incinerate\\FireLordDeathExplode.mdl", event.get_target())
	tower.do_spell_damage_aoe_unit(event.get_target(), 200, _stats.damage * tower.get_level() * _stats.damage_add, tower.calc_spell_crit_no_bonus(), 0.0)
