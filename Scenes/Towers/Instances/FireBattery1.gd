extends Tower


# NOTE: rewrote script a bit. Instead of enabling/disabling
# periodic event I added a flag.


var fire_battery_incinerate: BuffType
var pt: ProjectileType

var _battery_overload_is_active: bool = false


func get_tier_stats() -> Dictionary:
	return {
		1: {projectile_damage = 300, projectile_damage_add = 12, periodic_damage = 120, periodic_damage_add = 5, mod_dmg_from_fire = 0.05, debuff_level = 1, debuff_level_add = 0},
		2: {projectile_damage = 750, projectile_damage_add = 30, periodic_damage = 300, periodic_damage_add = 12, mod_dmg_from_fire = 0.10, debuff_level = 26, debuff_level_add = 2},
		3: {projectile_damage = 1800, projectile_damage_add = 72, periodic_damage = 800, periodic_damage_add = 32, mod_dmg_from_fire = 0.15, debuff_level = 52, debuff_level_add = 3},
	}


func get_extra_tooltip_text() -> String:
	var periodic_damage: String = Utils.format_float(_stats.periodic_damage, 2)
	var periodic_damage_add: String = Utils.format_float(_stats.periodic_damage_add, 2)
	var mod_dmg_from_fire: String = Utils.format_percent(_stats.mod_dmg_from_fire, 2)

	var text: String = ""

	text += "[color=GOLD]Incinerate[/color]\n"
	text += "This tower's attacks set the target on fire. A burning creep takes %s more damage from Fire towers and receives %s spelldamage every second for 9 seconds.\n" % [mod_dmg_from_fire, periodic_damage]
	text += " \n"
	text += "[color=ORANGE]Level Bonus:[/color]\n"
	text += "+%s damage\n" % periodic_damage_add
	text += "+0.3 seconds duration\n"

	return text


func get_autocast_description() -> String:
	var projectile_damage: String = Utils.format_float(_stats.projectile_damage, 2)
	var projectile_damage_add: String = Utils.format_float(_stats.projectile_damage_add, 2)

	var text: String = ""

	text += "The tower attacks creeps in a range of 1200 every 0.2 seconds till all mana is gone. Each attack (or try to attack) costs 10 mana, deals %s damage and incinerates the target.\n" % [projectile_damage]
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


func damage_periodic(event: Event):
	var b: Buff = event.get_buff()
	var tower: Tower = b.get_caster()
	tower.do_spell_damage(b.get_buffed_unit(), b.get_power() * _stats.periodic_damage_add + _stats.periodic_damage, tower.calc_spell_crit_no_bonus())


func hit(p: Projectile, creep: Unit):
	var tower: Tower = p.get_caster()
	tower.do_spell_damage(creep, tower.get_level() * _stats.projectile_damage_add + _stats.projectile_damage, tower.calc_spell_crit_no_bonus())
	fire_battery_incinerate.apply_custom_power(tower, creep, _stats.debuff_level_add * tower.get_level() + _stats.debuff_level, tower.get_level())


func tower_init():
	var modifier: Modifier = Modifier.new()
	modifier.add_modification(Modification.Type.MOD_DMG_FROM_FIRE, _stats.mod_dmg_from_fire, 0)

	fire_battery_incinerate = BuffType.new("fire_battery_incinerate", 9, 0.3, false, self)
	fire_battery_incinerate.set_buff_modifier(modifier)
	fire_battery_incinerate.set_buff_icon("@@0@@")
	fire_battery_incinerate.add_periodic_event(damage_periodic, 1)
	fire_battery_incinerate.set_stacking_group("FireBattery")
	fire_battery_incinerate.set_buff_tooltip("Incinerate\nThis creep has been incinerated; it will take extra damage from fire towers and it will take damage over time.")

	pt = ProjectileType.create("FireBallMissile.mdl", 10, 1200)
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
	fire_battery_incinerate.apply(tower, event.get_target(), tower.get_level())


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
