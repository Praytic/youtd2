extends Tower


var boekie_stim_bt: BuffType
var boekie_grenade_bt: BuffType
var boekie_shard_pt: ProjectileType


func get_tier_stats() -> Dictionary:
	return {
		1: {grenade_chance = 0.20, grenade_chance_add = 0.003, grenade_count = 6, grenade_damage = 1200, grenade_damage_add = 100},
		2: {grenade_chance = 0.25, grenade_chance_add = 0.004, grenade_count = 8, grenade_damage = 1800, grenade_damage_add = 150},
	}

const STIM_ATTACKSPEED: float = 1.5
const STIM_ATTACK_DMG: float = 0.5
const STIM_DURATION: float = 5
const STIM_DURATION_ADD: float = 0.08
const GRENADE_MOD_DMG_RECEIVED: float = 0.02
const GRENADE_MOD_DMG_RECEIVED_ADD: float = 0.001
const GRENADE_MOD_DMG_RECEIVED_MAX: float = 0.50


func get_extra_tooltip_text() -> String:
	var grenade_chance: String = Utils.format_percent(_stats.grenade_chance, 2)
	var grenade_chance_add: String = Utils.format_percent(_stats.grenade_chance_add, 2)
	var grenade_count: String = Utils.format_float(_stats.grenade_count, 2)
	var grenade_damage: String = Utils.format_float(_stats.grenade_damage, 2)
	var grenade_damage_add: String = Utils.format_float(_stats.grenade_damage_add, 2)
	var grenade_mod_dmg_received: String = Utils.format_percent(GRENADE_MOD_DMG_RECEIVED, 2)
	var grenade_mod_dmg_received_add: String = Utils.format_percent(GRENADE_MOD_DMG_RECEIVED_ADD, 2)
	var grenade_mod_dmg_received_max: String = Utils.format_percent(GRENADE_MOD_DMG_RECEIVED_MAX, 2)

	var text: String = ""

	text += "[color=GOLD]Frag Grenade[/color]\n"
	text += "When this tower damages a creep it has a %s chance to fire a frag grenade that will split into %s smaller grenades after a short delay. When a grenade collides with a creep it deals %s spelldamage and increases the damage the target takes from attacks by %s, stacking up to a maximum of %s.\n" % [grenade_chance, grenade_count, grenade_damage, grenade_mod_dmg_received, grenade_mod_dmg_received_max]
	text += " \n"
	text += "[color=ORANGE]Level Bonus:[/color]\n"
	text += "+%s chance\n" % grenade_chance_add
	text += "+%s damage\n" % grenade_damage_add
	text += "+%s damage increase\n" % grenade_mod_dmg_received_add

	return text


func get_autocast_description() -> String:
	var stim_attackspeed: String = Utils.format_percent(STIM_ATTACKSPEED, 2)
	var stim_attack_dmg: String = Utils.format_percent(STIM_ATTACK_DMG, 2)
	var stim_duration: String = Utils.format_float(STIM_DURATION, 2)
	var stim_duration_add: String = Utils.format_float(STIM_DURATION_ADD, 2)

	var text: String = ""

	text += "This marine uses a stimpack, increasing its attackspeed by %s and decreasing its attackdamage by %s. This buff lasts %s seconds.\n" % [stim_attackspeed, stim_attack_dmg, stim_duration]
	text += " \n"
	text += "[color=ORANGE]Level Bonus:[/color]\n"
	text += "+%s seconds duration\n" % stim_duration_add

	return text


func load_triggers(triggers: BuffType):
	triggers.add_event_on_damage(on_damage)


func tower_init():
	boekie_stim_bt = BuffType.new("boekie_stim_bt", STIM_DURATION, STIM_DURATION_ADD, true, self)
	var boekie_stim_mod: Modifier = Modifier.new()
	boekie_stim_mod.add_modification(Modification.Type.MOD_ATTACKSPEED, STIM_ATTACKSPEED, 0.0)
	boekie_stim_mod.add_modification(Modification.Type.MOD_DAMAGE_ADD_PERC, -STIM_ATTACK_DMG, 0.0)
	boekie_stim_bt.set_buff_modifier(boekie_stim_mod)
	boekie_stim_bt.set_buff_icon("@@0@@")
	boekie_stim_bt.set_buff_tooltip("Stimpack\nThis tower has been injected with a Stimpack; it has increased attackspeed but deals less damage.")

	boekie_grenade_bt = BuffType.new("boekie_grenade_bt", STIM_DURATION, STIM_DURATION_ADD, true, self)
	var boekie_grenade_mod: Modifier = Modifier.new()
	boekie_grenade_mod.add_modification(Modification.Type.MOD_ATK_DAMAGE_RECEIVED, GRENADE_MOD_DMG_RECEIVED, GRENADE_MOD_DMG_RECEIVED_ADD)
	boekie_grenade_bt.set_buff_modifier(boekie_grenade_mod)
	boekie_grenade_bt.set_buff_icon("@@1@@")
	boekie_grenade_bt.set_buff_tooltip("Fragged\nThis unit has been hit by a Frag Grenade; it will take extra attack damage.")

	boekie_shard_pt = ProjectileType.create_ranged("GyroCopterMissile.mdl", 400, 500, self)
	boekie_shard_pt.set_event_on_expiration(boekie_shard_on_expiration)
	boekie_shard_pt.enable_collision(boekie_shard_on_collide, 75, TargetType.new(TargetType.CREEPS), true)

	var autocast: Autocast = Autocast.make()
	autocast.title = "Stim"
	autocast.description = get_autocast_description()
	autocast.icon = "res://path/to/icon.png"
	autocast.caster_art = "AvatarCaster.mdl"
	autocast.target_art = ""
	autocast.autocast_type = Autocast.Type.AC_TYPE_OFFENSIVE_IMMEDIATE
	autocast.num_buffs_before_idle = 0
	autocast.cast_range = 1200
	autocast.auto_range = 1200
	autocast.cooldown = 1
	autocast.mana_cost = 25
	autocast.target_self = true
	autocast.is_extended = false
	autocast.buff_type = null
	autocast.target_type = TargetType.new(TargetType.TOWERS)
	autocast.handler = on_autocast
	add_autocast(autocast)


func on_damage(event: Event):
	var tower: Tower = self
	var grenade_chance: float = _stats.grenade_chance + _stats.grenade_chance_add * tower.get_level()

	if !tower.calc_chance(grenade_chance):
		return

	var projectile: Projectile = Projectile.create_from_unit_to_unit(boekie_shard_pt, tower, 1.0, tower.calc_spell_crit_no_bonus(), tower, event.get_target(), false, true, false)
#	Set user_int to 1 to mark this grenade as "main grenade"
	projectile.user_int = 1


func on_autocast(_event: Event):
	var tower: Tower = self
	var level: int = tower.get_level()
	boekie_stim_bt.apply(tower, tower, level)


func boekie_shard_on_collide(projectile: Projectile, target: Unit):
	var tower: Tower = projectile.get_caster()
	var level: int = tower.get_level()
	var buff: Buff = target.get_buff_of_type(boekie_grenade_bt)

	var grenade_damage: float = _stats.grenade_damage + _stats.grenade_damage_add * level
	projectile.do_spell_damage(target, grenade_damage)

	SFX.sfx_at_unit("FragBoomSpawn.mdl", target)

	if buff != null:
		var buff_level: int = int(min(480, buff.get_level() + 20 + level))
		boekie_grenade_bt.apply(tower, target, buff_level)
	else:
		boekie_grenade_bt.apply(tower, target, level)


func boekie_shard_on_expiration(projectile: Projectile):
	var tower: Tower = projectile.get_caster()
	var CONE_WIDTH: float = 120
	var num_projectiles: float = _stats.grenade_count
	var angle: float = projectile.get_direction() - CONE_WIDTH / 2
	var dmg_ratio: float = projectile.get_dmg_ratio()
	var is_main_grenade: bool = projectile.user_int == 1

	if !is_main_grenade:
		return

	for i in range(0, num_projectiles):
		var small_grenade: Projectile = Projectile.create(boekie_shard_pt, tower, dmg_ratio, tower.calc_spell_crit_no_bonus(), projectile.get_x(), projectile.get_y(), projectile.get_z(), angle + randf_range(-8, 8))
#		Set user_int to 0 to mark this grenade as "not main"
#		and stop recursion
		small_grenade.user_int = 0
		angle += CONE_WIDTH / (num_projectiles - 1)
