extends TowerBehavior


# NOTE: rewrote script a bit. Instead of enabling/disabling
# periodic event I added a flag.

# NOTE: [ORIGINAL_GAME_BUG] (NOT FIXED) Original script has
# a bug where it refunds the cost of autocast in
# on_autocast(). It refunds the cost by calling set_mana()
# but the problem is that at the time when on_autocast() is
# called, the mana cost has not been spent yet. Therefore,
# refund fails if tower is at max mana because set_mana()
# can't go above max mana. Not critical - don't need to fix.


var faerie_bt: BuffType
var missile_pt: ProjectileType

var _battery_overload_is_active: bool = false


func get_tier_stats() -> Dictionary:
	return {
		1: {projectile_damage = 300, projectile_damage_add = 12, mod_spell_damage = 0.10, mod_spell_damage_add = 0.004, mod_debuff_duration = 0.20, mod_debuff_duration_add = 0.006},
		2: {projectile_damage = 750, projectile_damage_add = 30, mod_spell_damage = 0.15, mod_spell_damage_add = 0.006, mod_debuff_duration = 0.25, mod_debuff_duration_add = 0.008},
		3: {projectile_damage = 1800, projectile_damage_add = 72, mod_spell_damage = 0.20, mod_spell_damage_add = 0.008, mod_debuff_duration = 0.30, mod_debuff_duration_add = 0.010},
	}


func load_triggers(triggers: BuffType):
	triggers.add_event_on_damage(on_damage)
	triggers.add_periodic_event(periodic, 0.2)


func on_autocast(_event: Event):
	tower.set_mana(tower.get_mana() + 100)
	_battery_overload_is_active = true


# NOTE: hit() in original script
func missile_pt_on_hit(_p: Projectile, creep: Unit):
	if creep == null:
		return

	var level: int = tower.get_level()
	var damage: float = _stats.projectile_damage + _stats.projectile_damage_add * level

	tower.do_spell_damage(creep, damage, tower.calc_spell_crit_no_bonus())
	faerie_bt.apply(tower, creep, level)


func tower_init():
	var modifier: Modifier = Modifier.new()
	modifier.add_modification(ModificationType.enm.MOD_SPELL_DAMAGE_RECEIVED, _stats.mod_spell_damage, _stats.mod_spell_damage_add)
	modifier.add_modification(ModificationType.enm.MOD_DEBUFF_DURATION, _stats.mod_debuff_duration, _stats.mod_debuff_duration_add)

	faerie_bt = BuffType.new("faerie_bt", 9, 0.3, false, self)
	faerie_bt.set_buff_icon("res://resources/icons/generic_icons/pisces.tres")
	faerie_bt.set_buff_modifier(modifier)
	faerie_bt.set_buff_tooltip(tr("VHUM"))

	missile_pt = ProjectileType.create("path_to_projectile_sprite", 10, 1200, self)
	missile_pt.enable_homing(missile_pt_on_hit, 0)


func on_damage(event: Event):
	faerie_bt.apply(tower, event.get_target(), tower.get_level())


func on_create(_preceding_tower: Tower):
	tower.user_int = 0
	tower.set_mana(0)


func periodic(_event: Event):
	if !_battery_overload_is_active:
		return

	if tower.get_mana() > 10:
		var in_range: Iterate = Iterate.over_units_in_range_of_caster(tower, TargetType.new(TargetType.CREEPS), 1200)
		var target: Unit = in_range.next_random()

		if target != null:
# 			NOTE: original script used createFromPointToUnit and made projectiles from high above the tower
			var p: Projectile = Projectile.create_from_unit_to_unit(missile_pt, tower, 1.0, 1.0, tower, target, true, false, false)
			p.set_projectile_scale(0.5)

#		Spend mana, note that mana is used for unsuccessful
#		attempts as well
		tower.set_mana(tower.get_mana() - 10)
	else:
#		Tower is out of mana so stop shooting
		_battery_overload_is_active = false
