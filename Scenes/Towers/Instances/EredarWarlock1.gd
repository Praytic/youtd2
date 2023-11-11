extends Tower


var cb_stun: BuffType
var sir_eredar_siphon_bt: BuffType
var sir_eredar_aura_bt: BuffType
var wave_shadowbolt_pt: ProjectileType
var attack_shadowbolt_pt: ProjectileType

var last_autocast_triggered_bolt_wave: bool = false


func get_tier_stats() -> Dictionary:
	return {
		1: {autocast_cooldown = 2.5, bolt_count = 10, bolt_damage = 1050, bolt_damage_add = 21},
		2: {autocast_cooldown = 1.5, bolt_count = 12, bolt_damage = 1700, bolt_damage_add = 34},
	}


func get_ability_description() -> String:
	var bolt_count: String = Utils.format_float(_stats.bolt_count, 2)
	var bolt_damage: String = Utils.format_float(_stats.bolt_damage, 2)
	var bolt_damage_add: String = Utils.format_float(_stats.bolt_damage_add, 2)

	var text: String = ""

	text += "[color=GOLD]Shadowbolt Wave[/color]\n"
	text += "Every autocast of this tower has a 20%% chance to release %s shadowbolts. Every shadowbolt flies towards a random target in 1000 range and deals %s spell damage. This Spell has a 40%% chance to trigger if the last autocast released a shadowboltwave.\n" % [bolt_count, bolt_damage]
	text += " \n"
	text += "[color=ORANGE]Level Bonus:[/color]\n"
	text += "+%s spell damage\n" % bolt_damage_add

	if get_tier() == 2:
		text += " \n"
		text += "[color=GOLD]Slow Decay - Aura[/color]\n"
		text += "Non Boss units in 750 range around the Eredar Diabolist with less then 5.5% of their healthpoints will be killed.\n"
		text += " \n"
		text += "[color=ORANGE]Level Bonus:[/color]\n"
		text += "+0.06% healthpoints needed for instantkill\n"

	return text


func get_ability_description_short() -> String:
	var text: String = ""

	text += "[color=GOLD]Shadowbolt Wave[/color]\n"
	text += "Has a chance to release a wave of shadowbolts.\n"

	if get_tier() == 2:
		text += " \n"
		text += "[color=GOLD]Slow Decay - Aura[/color]\n"
		text += "Eredar Diabolist will instantly kill all low health creeps in range.\n"

	return text


func get_autocast_description() -> String:
	var text: String = ""

	text += "Casts a buff on a nearby tower, if that tower tries to attack in the next 5 seconds it will be stunned for 2.5 seconds and this tower will deal [stunned tower's DPS x 3] as essence damage to the target of the buffed tower.\n"
	text += " \n"
	text += "[color=ORANGE]Level Bonus:[/color]\n"
	text += "-0.02 seconds stun duration\n"

	return text


func get_autocast_description_short() -> String:
	return "Stuns nearby towers and steals their damage.\n"


func tower_init():
	cb_stun = CbStun.new("eredar_warlock_stun", 0, 0, false, self)

	sir_eredar_siphon_bt = BuffType.new("sir_eredar_siphon_bt", 5, 0, true, self)
	sir_eredar_siphon_bt.set_buff_icon("@@0@@")
	sir_eredar_siphon_bt.add_event_on_attack(sir_eredar_siphon_bt_on_attack)
	sir_eredar_siphon_bt.set_buff_tooltip("Siphon Essence\nThis tower's essence has been siphoned; it will get stunned if it tries to attack.")

	sir_eredar_aura_bt = BuffType.create_aura_effect_type("sir_eredar_aura_bt", false, self)
	sir_eredar_aura_bt.set_buff_icon("@@1@@")
	sir_eredar_aura_bt.add_periodic_event(sir_eredar_aura_bt_periodic, 1.0)
	sir_eredar_aura_bt.set_buff_tooltip("Slow Decay - Aura\nThis unit is under the effect o Slow Decay Aura; it will get get instantly if it reaches low health.")

#	NOTE: this tower uses two separate projectile types.
#	1. The first one is launched from the tower in all
#	   directions - not targeted at creeps.
#  	2. When the first projectiles expire, they transform
#  	   into homing projectiles, which are now targeted at
#  	   creeps.
	wave_shadowbolt_pt = ProjectileType.create_ranged("BlackArrowMissile.mdl", 300, 600, self)
	wave_shadowbolt_pt.set_event_on_expiration(wave_shadowbolt_pt_on_expire)

	attack_shadowbolt_pt = ProjectileType.create("BlackArrowMissile.mdl", 4, 1000, self)
	attack_shadowbolt_pt.enable_homing(attack_shadowbolt_pt_on_hit, 0)

	var autocast: Autocast = Autocast.make()
	autocast.title = "Siphon Essence"
	autocast.description = get_autocast_description()
	autocast.description_short = get_autocast_description_short()
	autocast.icon = "res://path/to/icon.png"
	autocast.caster_art = ""
	autocast.target_art = ""
	autocast.autocast_type = Autocast.Type.AC_TYPE_ALWAYS_BUFF
	autocast.num_buffs_before_idle = 1
	autocast.cast_range = 400
	autocast.auto_range = 400
	autocast.cooldown = _stats.autocast_cooldown
	autocast.mana_cost = 0
	autocast.target_self = false
	autocast.is_extended = true
	autocast.buff_type = null
	autocast.target_type = TargetType.new(TargetType.TOWERS)
	autocast.handler = on_autocast
	add_autocast(autocast)


func get_aura_types() -> Array[AuraType]:
#	NOTE: only tier 2 of this family has the aura
	if get_tier() == 1:
		return []

	var aura: AuraType = AuraType.new()
	aura.aura_range = 750
	aura.target_type = TargetType.new(TargetType.CREEPS)
	aura.target_self = false
	aura.level = 0
	aura.level_add = 0
	aura.power = 0
	aura.power_add = 0
	aura.aura_effect = sir_eredar_aura_bt

	return [aura]


func on_autocast(event: Event):
	var tower: Tower = self
	var target: Tower = event.get_target()
	sir_eredar_siphon_bt.apply(tower, target, 1)
	roll_for_shadow_wave()


func roll_for_shadow_wave():
	var tower: Tower = self

	var wave_chance: float
	if last_autocast_triggered_bolt_wave:
		wave_chance = 0.20
	else:
		wave_chance = 0.40

	if !tower.calc_chance(wave_chance):
		last_autocast_triggered_bolt_wave = false

		return
	else:
		last_autocast_triggered_bolt_wave = true

	var it: Iterate = Iterate.over_units_in_range_of_caster(tower, TargetType.new(TargetType.CREEPS), 1000)

	if it.count() == 0:
		return

	var angle: float = 0.0

#	Create projectiles which radiate around the tower
	for i in range(0, _stats.bolt_count):
		angle += 360 / _stats.bolt_count
		Projectile.create_from_unit(wave_shadowbolt_pt, tower, tower, angle, 1.0, 1.0)	


func sir_eredar_siphon_bt_on_attack(event: Event):
	var buff: Buff = event.get_buff()
	var eredar: Tower = buff.get_caster()
	var attacker: Tower = buff.get_buffed_unit()
	var target: Unit = event.get_target()
	var dmg: float = 3 * attacker.get_current_attack_damage_with_bonus() / attacker.get_current_attack_speed()
	var stun_duration: float = 2.5 - 0.02 * eredar.get_level()

	cb_stun.apply_only_timed(eredar, attacker, stun_duration)

# 	NOTE: need to separately call order_stop() to stop
# 	current attack of buffed tower. Note that applying
# 	cb_stun will not stop an attack which is already in
# 	progress.
	attacker.order_stop()

#	NOTE: calc_spell_crit_no_bonus() is used in original
#	script even though this is do_attack_damage(). Maybe on
#	purpose?
	eredar.do_attack_damage(target, dmg, eredar.calc_spell_crit_no_bonus())

	var attacker_effect: int = Effect.create_simple("ImpaleHitTarget.mdl", attacker.get_visual_x(), attacker.get_visual_y())
	Effect.destroy_effect_after_its_over(attacker_effect)

	var floating_text: String = Utils.format_float(dmg, 0)
	eredar.get_player().display_floating_text_x(floating_text, target, 255, 0, 150, 255, 0.05, 0.0, 2.0)

	var target_effect: int = Effect.create_simple("ImpaleHitTarget.mdl", target.get_visual_x(), target.get_visual_y())
	Effect.destroy_effect_after_its_over(target_effect)


func sir_eredar_aura_bt_periodic(event: Event):
	var buff: Buff = event.get_buff()
	var caster: Unit = buff.get_caster()
	var target: Unit = buff.get_buffed_unit()
	var is_less_than_boss: bool = target.get_size() < CreepSize.enm.BOSS
	var low_health_threshold: float = 0.055 + 0.0006 * caster.get_level()
	var is_low_health: bool = target.get_health_ratio() <= low_health_threshold

	if is_low_health && is_less_than_boss:
		caster.kill_instantly(target)
		SFX.sfx_at_unit("DeathCoilSpecialArt", target)


func wave_shadowbolt_pt_on_expire(projectile: Projectile):
	var tower: Tower = projectile.get_caster()
	var it: Iterate = Iterate.over_units_in_range_of_caster(tower, TargetType.new(TargetType.CREEPS), 1000)

	if it.count() != 0:
		var random_creep: Unit = it.next_random()
		Projectile.create_from_point_to_unit(attack_shadowbolt_pt, tower, 1.0, 1.0, projectile.position, random_creep, true, false, false)


func attack_shadowbolt_pt_on_hit(p: Projectile, target: Unit):
	var tower: Tower = p.get_caster()
	var damage: float = _stats.bolt_damage + _stats.bolt_damage_add * tower.get_level()
	tower.do_spell_damage(target, damage, tower.calc_spell_crit_no_bonus())
