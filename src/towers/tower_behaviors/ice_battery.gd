extends TowerBehavior


# NOTE: rewrote script a bit. Instead of enabling/disabling
# periodic event I added a flag.

# NOTE: original script has a bug where it refunds the cost
# of autocast but the refund doesn't work if tower mana is
# close to max. This is because set_mana() cannot set mana
# above max value. Left this bug unfixed because it's not
# critical.


var frozen_bt: BuffType
var missile_pt: ProjectileType

var _battery_overload_is_active: bool = false


func get_tier_stats() -> Dictionary:
	return {
		1: {projectile_damage = 300, projectile_damage_add = 12, slow_amount = 0.10, slow_amount_add = 0.003},
		2: {projectile_damage = 750, projectile_damage_add = 30, slow_amount = 0.15, slow_amount_add = 0.0045},
		3: {projectile_damage = 1800, projectile_damage_add = 72, slow_amount = 0.20, slow_amount_add = 0.006},
	}



func get_ability_info_list() -> Array[AbilityInfo]:
	var slow_amount: String = Utils.format_percent(_stats.slow_amount, 2)
	var slow_amount_add: String = Utils.format_percent(_stats.slow_amount_add, 2)
	
	var list: Array[AbilityInfo] = []
	
	var ability: AbilityInfo = AbilityInfo.new()
	ability.name = "Frost"
	ability.icon = "res://resources/icons/orbs/orb_ice.tres"
	ability.description_short = "Whenever this tower hits a creep, it applies [color=GOLD]Frost[/color]. [color=GOLD]Frost[/color] slows the creep.\n"
	ability.description_full = "Whenever this tower hits a creep, it applies [color=GOLD]Frost[/color]. [color=GOLD]Frost[/color] slows the creep by %s for 9 seconds.\n" % slow_amount \
	+ " \n" \
	+ "[color=ORANGE]Level Bonus:[/color]\n" \
	+ "+%s slow\n" % slow_amount_add \
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


func hit(_p: Projectile, creep: Unit):
	if creep == null:
		return

	var buff_level: int = int((_stats.slow_amount + _stats.slow_amount_add * tower.get_level()) * 1000)
	var buff_power: int = tower.get_level()

	tower.do_spell_damage(creep, tower.get_level() * _stats.projectile_damage_add + _stats.projectile_damage, tower.calc_spell_crit_no_bonus())
	frozen_bt.apply_custom_power(tower, creep, buff_level, buff_power)


func tower_init():
	var slow: Modifier = Modifier.new()
	slow.add_modification(Modification.Type.MOD_MOVESPEED, -_stats.slow_amount, -_stats.slow_amount_add)

	frozen_bt = BuffType.new("frozen_bt", 9, 0.3, false, self)
	frozen_bt.set_buff_icon("res://resources/icons/generic_icons/azul_flake.tres")
	frozen_bt.set_buff_modifier(slow)
	frozen_bt.set_buff_tooltip("Frozen\nThis creep is frozen; it has reduced movement speed.")

	missile_pt = ProjectileType.create("LichMissile.mdl", 10, 1200, self)
	missile_pt.enable_homing(hit, 0)


func create_autocasts() -> Array[Autocast]:
	var autocast: Autocast = Autocast.make()

	var projectile_damage: String = Utils.format_float(_stats.projectile_damage, 2)
	var projectile_damage_add: String = Utils.format_float(_stats.projectile_damage_add, 2)
	
	autocast.title = "Battery Overload"
	autocast.icon = "res://resources/icons/mechanical/battery.tres"
	autocast.description_short = "Starts attacking very fast until out of mana, dealing spell damage and applying [color=GOLD]Frost[/color].\n"
	autocast.description = "The tower attacks creeps in a range of 1200 every 0.2 seconds till all mana is gone. Each attack (or try to attack) costs 10 mana, deals %s spell damage and applies [color=GOLD]Frost[/color].\n" % [projectile_damage] \
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
	frozen_bt.apply(tower, event.get_target(), tower.get_level())


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
