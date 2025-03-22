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


var electrified_bt: BuffType
var missile_pt: ProjectileType

var _battery_overload_is_active: bool = false


func get_tier_stats() -> Dictionary:
	return {
		1: {projectile_damage = 300, projectile_damage_add = 12, damage_increase = 0.4, damage_increase_add = 0.008, mod_dmg_from_fire = 0.05},
		2: {projectile_damage = 750, projectile_damage_add = 30, damage_increase = 0.8, damage_increase_add = 0.016, mod_dmg_from_fire = 0.10},
		3: {projectile_damage = 1800, projectile_damage_add = 72, damage_increase = 1.2, damage_increase_add = 0.024, mod_dmg_from_fire = 0.15},
	}


func load_triggers(triggers: BuffType):
	triggers.add_event_on_damage(on_damage)
	triggers.add_periodic_event(periodic, 0.2)


func on_autocast(_event: Event):
	tower.set_mana(tower.get_mana() + 100)
	_battery_overload_is_active = true


func debuff_on_damaged(event: Event):
	var b: Buff = event.get_buff()
	var level: int = tower.get_level()
	var extra_damage_chance: float = 0.2 + 0.003 * level

	if !tower.calc_chance(extra_damage_chance):
		CombatLog.log_ability(tower, b.get_buffed_unit(), "Electrify Effect")

		var damage_multiplier: float = _stats.damage_increase + _stats.damage_increase_add * level
		event.damage = event.damage * damage_multiplier

		var damage_text: String = Utils.format_float(event.damage, 0)
		tower.get_player().display_small_floating_text(damage_text, b.get_buffed_unit(), Color8(128, 255, 255), 20)


func hit(_p: Projectile, creep: Unit):
	if creep == null:
		return

	var level: int = tower.get_level()
	var damage: float = _stats.projectile_damage + _stats.projectile_damage_add * level

	tower.do_spell_damage(creep, damage, tower.calc_spell_crit_no_bonus())
	electrified_bt.apply(tower, creep, level)


func tower_init():
	electrified_bt = BuffType.new("electrified_bt", 9, 0.3, false, self)
	electrified_bt.set_buff_icon("res://resources/icons/generic_icons/electric.tres")
	electrified_bt.add_event_on_damaged(debuff_on_damaged)
	electrified_bt.set_buff_tooltip(tr("NVVL"))

	missile_pt = ProjectileType.create("path_to_projectile_sprite", 10, 1200, self)
	missile_pt.enable_homing(hit, 0)


func on_damage(event: Event):
	var target: Unit = event.get_target()
	var level: int = tower.get_level()

	electrified_bt.apply(tower, target, level)


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
