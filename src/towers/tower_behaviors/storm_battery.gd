extends TowerBehavior


# NOTE: rewrote script a bit. Instead of enabling/disabling
# periodic event I added a flag.

# NOTE: original script has a bug where it refunds the cost
# of autocast but the refund doesn't work if tower mana is
# close to max. This is because set_mana() cannot set mana
# above max value. Left this bug unfixed because it's not
# critical.

var electrified_bt: BuffType
var missile_pt: ProjectileType

var _battery_overload_is_active: bool = false


func get_tier_stats() -> Dictionary:
	return {
		1: {projectile_damage = 300, projectile_damage_add = 12, damage_increase = 0.4, damage_increase_add = 0.008, mod_dmg_from_fire = 0.05, debuff_level = 1, debuff_level_add = 0},
		2: {projectile_damage = 750, projectile_damage_add = 30, damage_increase = 0.8, damage_increase_add = 0.016, mod_dmg_from_fire = 0.10, debuff_level = 26, debuff_level_add = 2},
		3: {projectile_damage = 1800, projectile_damage_add = 72, damage_increase = 1.2, damage_increase_add = 0.024, mod_dmg_from_fire = 0.15, debuff_level = 52, debuff_level_add = 3},
	}


func get_ability_info_list() -> Array[AbilityInfo]:
	var damage_increase: String = Utils.format_percent(_stats.damage_increase, 2)
	var damage_increase_add: String = Utils.format_percent(_stats.damage_increase_add, 2)

	var list: Array[AbilityInfo] = []
	
	var ability: AbilityInfo = AbilityInfo.new()
	ability.name = "Electrify"
	ability.icon = "res://resources/icons/electricity/electricity_yellow.tres"
	ability.description_short = "Whenever this tower hits a creep, it applies [color=GOLD]Electrify[/color]. [color=GOLD]Electrify[/color] makes the creep occasionally take extra damage\n"
	ability.description_full = "Whenever this tower hits a creep, it applies [color=GOLD]Electrify[/color] for 9 seconds. Everytime the [color=GOLD]Electrified[/color] creep is damaged by an attack or spell it has a chance of 20%% to take %s extra damage.\n" % damage_increase \
	+ " \n" \
	+ "[color=ORANGE]Level Bonus:[/color]\n" \
	+ "+0.3% chance\n" \
	+ "+%s damage\n" % damage_increase_add \
	+ "+0.3 seconds duration\n"
	list.append(ability)

	return list


func load_triggers(triggers: BuffType):
	triggers.add_event_on_damage(on_damage)
	triggers.add_periodic_event(periodic, 0.2)


func load_specials(modifier: Modifier):
	modifier.add_modification(Modification.Type.MOD_MANA, 0, 10)


func on_autocast(_event: Event):
	tower.set_mana(tower.get_mana() + 100)
	_battery_overload_is_active = true


func debuff_on_damaged(event: Event):
	var b: Buff = event.get_buff()

	if tower.calc_chance(0.2 + b.get_power() * 0.003):
		CombatLog.log_ability(tower, b.get_buffed_unit(), "Electrify Effect")

		event.damage = event.damage * b.user_real
		var damage_text: String = Utils.format_float(event.damage, 0)
		tower.get_player().display_small_floating_text(damage_text, b.get_buffed_unit(), Color8(128, 255, 255), 20)


func hit(_p: Projectile, creep: Unit):
	if creep == null:
		return

	tower.do_spell_damage(creep, tower.get_level() * _stats.projectile_damage_add + _stats.projectile_damage, tower.calc_spell_crit_no_bonus())
	electrified_bt.apply_custom_power(tower, creep, _stats.debuff_level_add * tower.get_level() + _stats.debuff_level, tower.get_level())


func tower_init():
	electrified_bt = BuffType.new("electrified_bt", 9, 0.3, false, self)
	electrified_bt.set_buff_icon("res://resources/icons/generic_icons/electric.tres")
	electrified_bt.add_event_on_damaged(debuff_on_damaged)
	electrified_bt.set_stacking_group("StormBattery")
	electrified_bt.set_buff_tooltip("Electrified\nThis creep has been electrified; it will sometimes take extra damage when damaged by attacks or spells.")

	missile_pt = ProjectileType.create("FarseerMissile.mdl", 10, 1200, self)
	missile_pt.enable_homing(hit, 0)


func create_autocasts() -> Array[Autocast]:
	var autocast: Autocast = Autocast.make()

	var projectile_damage: String = Utils.format_float(_stats.projectile_damage, 2)
	var projectile_damage_add: String = Utils.format_float(_stats.projectile_damage_add, 2)

	autocast.title = "Battery Overload"
	autocast.icon = "res://resources/icons/mechanical/battery.tres"
	autocast.description_short = "Starts attacking very fast until out of mana, dealing spell damage and applying [color=GOLD]Electrify[/color].\n"
	autocast.description = "The tower attacks creeps in a range of 1200 every 0.2 seconds till all mana is gone. Each attack (or try to attack) costs 10 mana, deals %s spell damage and applies [color=GOLD]Electrify[/color].\n" % [projectile_damage] \
	+ " \n" \
	+ "[color=ORANGE]Level Bonus:[/color]\n" \
	+ "+%s spell damage\n" % projectile_damage_add
	autocast.caster_art = ""
	autocast.num_buffs_before_idle = 0
	autocast.autocast_type = Autocast.Type.AC_TYPE_OFFENSIVE_IMMEDIATE
	autocast.cast_range = 1200
	autocast.target_self = false
	autocast.target_art = ""
	autocast.cooldown = 20
	autocast.is_extended = false
	autocast.mana_cost = 100
	autocast.buff_type = null
	autocast.target_type = null
	autocast.auto_range = 800
	autocast.handler = on_autocast

	return [autocast]


func on_damage(event: Event):
	var tower_level: int = tower.get_level()
	electrified_bt.apply_custom_power(tower, event.get_target(), int(1000 * (_stats.damage_increase + _stats.damage_increase_add * tower_level) * (0.2 + 0.003 * tower_level)), tower_level).user_real = _stats.damage_increase + _stats.damage_increase_add * tower_level + 1


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
