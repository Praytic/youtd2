extends TowerBehavior


var stun_bt: BuffType
var aura_bt: BuffType
var splash_bt: BuffType
var water_pt: ProjectileType
var stone_pt: ProjectileType


func get_ability_info_list() -> Array[AbilityInfo]:
	var list: Array[AbilityInfo] = []
	
	var spring: AbilityInfo = AbilityInfo.new()
	spring.name = "Spring Tide"
	spring.description_short = "Chance to launch a wave which deals spell damage to each creep it hits.\n"
	spring.description_full = "Whenever this tower attacks it has a 15% chance to launch a wave. The wave travels 1200 units and has a 200 AoE. It deals 2200 spell damage to each creep it hits. Every 0.4 seconds the wave has a 35% chance to drag a stone with it. The stone travels 500 units, deals 2200 spell damage on collision and stuns for 0.65 seconds.\n" \
	+ " \n" \
	+ "[color=ORANGE]Level Bonus:[/color]\n" \
	+ "+88 spell damage\n" \
	+ "+0.6% chance to launch a wave\n"
	list.append(spring)

	var splash: AbilityInfo = AbilityInfo.new()
	splash.name = "Splash"
	splash.description_short = "Chance to deal spell damage in AoE around the attacked unit.\n"
	splash.description_full = "Whenever this tower deals damage through attacks it has a 20% chance to deal 4000 spell damage in 175 AoE around the attacked unit. Also increases the spell damage the hit units take by 12.5% for 6 seconds.\n" \
	+ " \n" \
	+ "[color=ORANGE]Level Bonus:[/color]\n" \
	+ "+160 spell damage\n" \
	+ "+0.5% more spell damage taken\n"
	list.append(splash)

	var calming: AbilityInfo = AbilityInfo.new()
	calming.name = "Calming Noises - Aura"
	calming.description_short = "Increases the spell crit chance of nearby towers.\n"
	calming.description_full = "Increases the spell crit chance of towers in 250 range by 10%.\n" \
	+ " \n" \
	+ "[color=ORANGE]Level Bonus:[/color]\n" \
	+ "+0.4% spell crit chance\n"
	list.append(calming)

	return list


func load_triggers(triggers: BuffType):
	triggers.add_event_on_attack(on_attack)
	triggers.add_event_on_damage(on_damage)


func tower_init():
	stun_bt = CbStun.new("stun_bt", 0, 0, false, self)

	aura_bt = BuffType.create_aura_effect_type("aura_bt", true, self)
	var cedi_tidewater_aura_mod: Modifier = Modifier.new()
	cedi_tidewater_aura_mod.add_modification(Modification.Type.MOD_ARMOR, 0.1, 0.004)
	aura_bt.set_buff_modifier(cedi_tidewater_aura_mod)
	aura_bt.set_buff_icon("res://Resources/Icons/GenericIcons/rss.tres")
	aura_bt.set_buff_tooltip("Calming Noises Aura\nIncreases spell crit chance.")

	splash_bt = BuffType.new("splash_bt", 6.0, 0, false, self)
	var cedi_tidewater_splash_mod: Modifier = Modifier.new()
	cedi_tidewater_splash_mod.add_modification(Modification.Type.MOD_SPELL_DAMAGE_RECEIVED, 0.125, 0.005)
	splash_bt.set_buff_modifier(cedi_tidewater_splash_mod)
	splash_bt.set_buff_icon("res://Resources/Icons/GenericIcons/atomic_slashes.tres")
	splash_bt.set_buff_tooltip("Splash\nIncreases spell damage taken.")

	water_pt = ProjectileType.create_ranged("Waterfall.mdl", 1200, 700, self)
	water_pt.enable_collision(water_pt_on_hit, 200, TargetType.new(TargetType.CREEPS), false)
	water_pt.enable_periodic(water_pt_periodic, 0.4)
	water_pt.disable_explode_on_expiration()

	stone_pt = ProjectileType.create_ranged("RockBoltMissile.mdl", 500, 800, self)
	stone_pt.enable_collision(stone_pt_on_hit, 64, TargetType.new(TargetType.CREEPS), true)


func get_aura_types() -> Array[AuraType]:
	var aura: AuraType = AuraType.new()
	aura.aura_range = 250
	aura.target_type = TargetType.new(TargetType.TOWERS)
	aura.target_self = true
	aura.level = 1
	aura.level_add = 1
	aura.power = 1
	aura.power_add = 1
	aura.aura_effect = aura_bt

	return [aura]


func on_attack(event: Event):
	var target: Unit = event.get_target()
	var facing: float = rad_to_deg(atan2(target.get_y() - tower.get_y(), target.get_x() - tower.get_x()))
	var wave_chance: float = 0.15 + 0.006 * tower.get_level()

	if !tower.calc_chance(wave_chance):
		return

	CombatLog.log_ability(tower, target, "Spring Tide")

	var projectile: Projectile = Projectile.create_from_unit(water_pt, tower, tower, facing, 1.0, tower.calc_spell_crit_no_bonus())
	projectile.set_projectile_scale(0.8)


func on_damage(event: Event):
	var lvl: int = tower.get_level()
	var target: Unit = event.get_target()
	var splash_chance: float = 0.20 + 0.004 * lvl

	if !tower.calc_chance(splash_chance):
		return

	CombatLog.log_ability(tower, target, "Splash")

	var effect: int = Effect.create_scaled("NagaDeath.mdl", Vector3(target.get_x(), target.get_y(), 0), 0, 5)
	Effect.set_lifetime(effect, 3.0)
	var splash_damage: float = 4000 + 160 * lvl
	tower.do_spell_damage_aoe_unit(target, 175, splash_damage, tower.calc_spell_crit_no_bonus(), 0)

	var it: Iterate = Iterate.over_units_in_range_of_unit(tower, TargetType.new(TargetType.CREEPS), target, 175)
	while true:
		var next: Unit = it.next()

		if next == null:
			break

		splash_bt.apply(tower, next, lvl)


func water_pt_on_hit(p: Projectile, target: Unit):
	var effect: int = Effect.add_special_effect_target("CrushingWaveDamage.mdl", target, Unit.BodyPart.CHEST)
	Effect.destroy_effect_after_its_over(effect)
	var caster: Unit = p.get_caster()
	var wave_damage: float = 2200 + 88 * caster.get_level()
	caster.do_spell_damage(target, wave_damage, caster.calc_spell_crit_no_bonus())


func water_pt_periodic(p: Projectile):
	var caster: Unit = p.get_caster()

	var stone_chance: float = 0.35
	if !caster.calc_chance(stone_chance):
		return
		
	var stone_x: float = p.get_x() + Globals.synced_rng.randf_range(-30, 30)
	var stone_y: float = p.get_y() + Globals.synced_rng.randf_range(-30, 30)
	var stone_facing: float = p.get_direction() + Globals.synced_rng.randf_range(-30, 30)
	var stone_projectile: Projectile = Projectile.create(stone_pt, caster, 1.0, caster.calc_spell_crit_no_bonus(), Vector3(stone_x, stone_y, 0), stone_facing)

	var effect: int = Effect.add_special_effect("ImpaleTargetDust.mdl", Vector2(stone_projectile.get_x(), stone_projectile.get_y()))
	Effect.destroy_effect_after_its_over(effect)


func stone_pt_on_hit(p: Projectile, target: Unit):
	var caster: Unit = p.get_caster()
	var wave_damage: float = 2200 + 88 * caster.get_level()
	caster.do_spell_damage(target, wave_damage, caster.calc_spell_crit_no_bonus())
	stun_bt.apply_only_timed(caster, target, 0.65)
