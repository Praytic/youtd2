extends Tower


# NOTE: rewrote script a bit. Instead of enabling/disabling
# periodic event I added a flag.


var dark_battery_corruption: BuffType
var pt: ProjectileType

var _battery_overload_is_active: bool = false


func get_tier_stats() -> Dictionary:
	return {
		1: {projectile_damage = 300, projectile_damage_add = 12, mod_spell_damage = 0.05, mod_spell_damage_add = 0.002, mod_attack_damage = 0.10, mod_attack_damage_add = 0.004, debuff_level = 1, debuff_level_add = 0},
		2: {projectile_damage = 750, projectile_damage_add = 30, mod_spell_damage = 0.10, mod_spell_damage_add = 0.003, mod_attack_damage = 0.20, mod_attack_damage_add = 0.008, debuff_level = 26, debuff_level_add = 2},
		3: {projectile_damage = 1800, projectile_damage_add = 72, mod_spell_damage = 0.15, mod_spell_damage_add = 0.006, mod_attack_damage = 0.30, mod_attack_damage_add = 0.012, debuff_level = 52, debuff_level_add = 3},
	}


func get_extra_tooltip_text() -> String:
	var mod_spell_damage: String = Utils.format_percent(_stats.mod_spell_damage, 2)
	var mod_spell_damage_add: String = Utils.format_percent(_stats.mod_spell_damage_add, 2)
	var mod_attack_damage: String = Utils.format_percent(_stats.mod_attack_damage, 2)
	var mod_attack_damage_add: String = Utils.format_percent(_stats.mod_attack_damage_add, 2)

	var text: String = ""

	text += "[color=GOLD]Corruption[/color]\n"
	text += "A corrupted creep takes %s extra damage from attacks and %s extra damage from spells for 9 seconds\n" % [mod_attack_damage, mod_spell_damage]
	text += " \n"
	text += "[color=ORANGE]Level Bonus:[/color]\n"
	text += "+%s damage from attacks\n" % mod_attack_damage_add
	text += "+%s damage from spells\n" % mod_spell_damage_add
	text += "+0.3 seconds duration\n"

	return text


func get_autocast_description() -> String:
	var projectile_damage: String = Utils.format_float(_stats.projectile_damage, 2)
	var projectile_damage_add: String = Utils.format_float(_stats.projectile_damage_add, 2)

	var text: String = ""

	text += "The tower attacks creeps in a range of 1200 every 0.2 seconds till all mana is gone. Each attack (or try to attack) costs 10 mana, deals %s damage and applies Corruption.\n" % [projectile_damage]
	text += " \n"
	text += "[color=ORANGE]Level Bonus:[/color]\n"
	text += "+%s damage\n" % projectile_damage_add

	return text


func load_triggers(triggers: BuffType):
	triggers.add_event_on_damage(on_damage)
	triggers.add_periodic_event(periodic, 0.2)


func load_specials(modifier: Modifier):
	modifier.add_modification(Modification.Type.MOD_MANA, 0, 10)


func on_autocast(_event: Event):
	var tower: Tower = self

	tower.set_mana(tower.get_mana() + 100)
	_battery_overload_is_active = true


func hit(p: Projectile, creep: Unit):
	var tower: Tower = p.get_caster()
	tower.do_spell_damage(creep, tower.get_level() * _stats.projectile_damage_add + _stats.projectile_damage, tower.calc_spell_crit_no_bonus())
	dark_battery_corruption.apply_custom_power(tower, creep, _stats.debuff_level_add * tower.get_level() + _stats.debuff_level, tower.get_level())


func tower_init():
	var modifier: Modifier = Modifier.new()
	modifier.add_modification(Modification.Type.MOD_SPELL_DAMAGE_RECEIVED, _stats.mod_spell_damage, _stats.mod_spell_damage_add)
	modifier.add_modification(Modification.Type.MOD_ATK_DAMAGE_RECEIVED, _stats.mod_attack_damage, _stats.mod_attack_damage_add)

	dark_battery_corruption = BuffType.new("dark_battery_corruption", 9, 0.3, false, self)
	dark_battery_corruption.set_buff_icon("@@0@@")
	dark_battery_corruption.set_buff_modifier(modifier)
	dark_battery_corruption.set_stacking_group("DarkBattery")
	dark_battery_corruption.set_buff_tooltip("Corruption\nThis creep is affected by Corruption; it will take extra damage from attacks and spells.")

	pt = ProjectileType.create("ProcMissile.mdl", 10, 1200, self)
	pt.enable_homing(hit, 0)

	var autocast: Autocast = Autocast.make()
	autocast.title = "Battery Overload"
	autocast.description = get_autocast_description()
	autocast.icon = "res://path/to/icon.png"
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
	add_autocast(autocast)


func on_damage(event: Event):
	var tower: Tower = self
	dark_battery_corruption.apply(tower, event.get_target(), tower.get_level())


func on_create(_preceding_tower: Tower):
	var tower: Tower = self
	tower.user_int = 0
	tower.set_mana(0)


func periodic(_event: Event):
	if !_battery_overload_is_active:
		return

	var tower: Tower = self

	if tower.get_mana() > 10:
		var in_range: Iterate = Iterate.over_units_in_range_of_caster(tower, TargetType.new(TargetType.CREEPS), 1200)
		var target: Unit = in_range.next_random()

		if target != null:
# 			NOTE: original script used createFromPointToUnit and made projectiles from high above the tower
			var p: Projectile = Projectile.create_from_unit_to_unit(pt, tower, 1.0, 1.0, tower, target, true, false, false)
			p.setScale(0.5)

#		Spend mana, note that mana is used for unsuccessful
#		attempts as well
		tower.set_mana(tower.get_mana() - 10)
	else:
#		Tower is out of mana so stop shooting
		_battery_overload_is_active = false
