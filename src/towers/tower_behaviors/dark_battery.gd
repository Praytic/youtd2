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


var corruption_bt: BuffType
var missile_pt: ProjectileType

var _battery_overload_is_active: bool = false


func get_tier_stats() -> Dictionary:
	return {
		1: {projectile_damage = 300, projectile_damage_add = 12, mod_spell_damage = 0.05, mod_spell_damage_add = 0.002, mod_attack_damage = 0.10, mod_attack_damage_add = 0.004},
		2: {projectile_damage = 750, projectile_damage_add = 30, mod_spell_damage = 0.10, mod_spell_damage_add = 0.003, mod_attack_damage = 0.20, mod_attack_damage_add = 0.008},
		3: {projectile_damage = 1800, projectile_damage_add = 72, mod_spell_damage = 0.15, mod_spell_damage_add = 0.006, mod_attack_damage = 0.30, mod_attack_damage_add = 0.012},
	}


func get_ability_info_list_DELETEME() -> Array[AbilityInfo]:
	var mod_spell_damage: String = Utils.format_percent(_stats.mod_spell_damage, 2)
	var mod_spell_damage_add: String = Utils.format_percent(_stats.mod_spell_damage_add, 2)
	var mod_attack_damage: String = Utils.format_percent(_stats.mod_attack_damage, 2)
	var mod_attack_damage_add: String = Utils.format_percent(_stats.mod_attack_damage_add, 2)

	var list: Array[AbilityInfo] = []
	
	var ability: AbilityInfo = AbilityInfo.new()
	ability.name = "Corruption"
	ability.icon = "res://resources/icons/tower_variations/meteor_totem_purple.tres"
	ability.description_short = "Corrupts hit creeps, increasing damage received from attacks and spells.\n"
	ability.description_full = "Corrupts hit creeps, increasing damage received from attacks by %s and damage received from spells by %s for 9 seconds\n" % [mod_attack_damage, mod_spell_damage] \
	+ " \n" \
	+ "[color=ORANGE]Level Bonus:[/color]\n" \
	+ "+%s damage from attacks\n" % mod_attack_damage_add \
	+ "+%s damage from spells\n" % mod_spell_damage_add \
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

	var level: int = tower.get_level()
	var damage: float = _stats.projectile_damage + _stats.projectile_damage_add * level

	tower.do_spell_damage(creep, damage, tower.calc_spell_crit_no_bonus())
	corruption_bt.apply(tower, creep, level)


func tower_init():
	var modifier: Modifier = Modifier.new()
	modifier.add_modification(Modification.Type.MOD_SPELL_DAMAGE_RECEIVED, _stats.mod_spell_damage, _stats.mod_spell_damage_add)
	modifier.add_modification(Modification.Type.MOD_ATK_DAMAGE_RECEIVED, _stats.mod_attack_damage, _stats.mod_attack_damage_add)

	corruption_bt = BuffType.new("corruption_bt", 9, 0.3, false, self)
	corruption_bt.set_buff_icon("res://resources/icons/generic_icons/poison_gas.tres")
	corruption_bt.set_buff_modifier(modifier)
	corruption_bt.set_buff_tooltip("Corruption\nIncreases attack and spell damage taken.")

	missile_pt = ProjectileType.create("path_to_projectile_sprite", 10, 1200, self)
	missile_pt.enable_homing(hit, 0)


func create_autocasts_DELETEME() -> Array[Autocast]:
	var autocast: Autocast = Autocast.make()

	var projectile_damage: String = Utils.format_float(_stats.projectile_damage, 2)
	var projectile_damage_add: String = Utils.format_float(_stats.projectile_damage_add, 2)

	autocast.title = "Battery Overload"
	autocast.icon = "res://resources/icons/mechanical/battery.tres"
	autocast.description_short = "Attacks very fast while consuming mana, dealing spell damage and applying [color=GOLD]Corruption[/color].\n"
	autocast.description = "The tower attacks creeps in a range of 1200 every 0.2 seconds till all mana is gone. Each attack (or try to attack) costs 10 mana, deals %s spell damage and applies [color=GOLD]Corruption[/color].\n" % [projectile_damage] \
	+ " \n" \
	+ "[color=GOLD]Note:[/color] this ability does not trigger any \"on hit\" effects.\n" \
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
	autocast.buff_target_type = null
	autocast.auto_range = 800
	autocast.handler = on_autocast

	return [autocast]


func on_damage(event: Event):
	corruption_bt.apply(tower, event.get_target(), tower.get_level())


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
