extends TowerBehavior


var aura_bt: BuffType
var lava_pt: ProjectileType

const AURA_RANGE: int = 700


func get_ability_info_list() -> Array[AbilityInfo]:
	var list: Array[AbilityInfo] = []

	var heat_stroke: AbilityInfo = AbilityInfo.new()
	heat_stroke.name = "Heat Stroke"
	heat_stroke.icon = "res://resources/icons/tower_icons/fire_star.tres"
	heat_stroke.description_short = "Whenever a creep dies while under the effect of [color=GOLD]Heat Aura[/color], there is a chance that it will explode and deal AoE spell damage.\n"
	heat_stroke.description_full = "Whenever a creep dies while under the effect of [color=GOLD]Heat Aura[/color], there is a 40% chance that it will explode, dealing 4500 spell damage in 300 AoE.\n" \
	+ " \n" \
	+ "[color=ORANGE]Level Bonus:[/color]\n" \
	+ "+100 damage\n"
	list.append(heat_stroke)

	var lava_attack: AbilityInfo = AbilityInfo.new()
	lava_attack.name = "Lava Attack"
	lava_attack.icon = "res://resources/icons/orbs/orb_fire.tres"
	lava_attack.description_short = "Whenever this tower attacks, it has a chance to throw a burning lava ball towards the main target, dealing AoE spell damage.\n"
	lava_attack.description_full = "Whenever this tower attacks, it has a 25% chance to throw a burning lava ball towards the main target, dealing 3500 spell damage to creeps in 300 AoE.\n" \
	+ " \n" \
	+ "[color=ORANGE]Level Bonus:[/color]\n" \
	+ "+5 AoE\n" \
	+ "+100 spell damage\n"
	list.append(lava_attack)

	return list


func load_triggers(triggers: BuffType):
	triggers.add_event_on_attack(on_attack)


func load_specials(modifier: Modifier):
	modifier.add_modification(Modification.Type.MOD_DMG_TO_NATURE, 0.45, 0.02)
	modifier.add_modification(Modification.Type.MOD_DAMAGE_BASE_PERC, 0.0, 0.075)
	modifier.add_modification(Modification.Type.MOD_SPELL_DAMAGE_DEALT, 0.0, 0.015)


func tower_init():
	aura_bt = BuffType.create_aura_effect_type("aura_bt", false, self)
	aura_bt.set_buff_icon("res://resources/icons/generic_icons/flame.tres")
	aura_bt.set_buff_tooltip("Heat Aura\nDeals damage over time.")
	aura_bt.add_periodic_event(aura_bt_periodic, 1.0)
	aura_bt.add_event_on_death(aura_bt_on_death)

	lava_pt = ProjectileType.create_interpolate("path_to_projectile_sprite", 650, self)
	lava_pt.set_event_on_cleanup(lava_pt_on_cleanup)


func get_aura_types() -> Array[AuraType]:
	var aura: AuraType = AuraType.new()

	aura.name = "Heat Aura"
	aura.icon = "res://resources/icons/tower_icons/fire_battery.tres"
	aura.description_short = "Burns every enemy in range, making them lose life every second.\n"
	aura.description_full = "Burns every enemy in %d range, making them lose 3%% of their current life every second.\n" % AURA_RANGE

	aura.aura_range = AURA_RANGE
	aura.target_type = TargetType.new(TargetType.CREEPS)
	aura.target_self = false
	aura.level = 0
	aura.level_add = 1
	aura.aura_effect = aura_bt

	return [aura]


func on_attack(event: Event):
	var target: Unit = event.get_target()
	var lvl: int = tower.get_level()
	var aoe_radius: float = 300 + 5 * lvl
	var aoe_damage: float = 3500 + 100 * lvl
	var lava_attack_chance: float = 0.25

	if !tower.calc_chance(lava_attack_chance):
		return

	CombatLog.log_ability(tower, target, "Lava Attack")

	var p: Projectile = Projectile.create_linear_interpolation_from_unit_to_point(lava_pt, tower, 1.0, tower.calc_spell_crit_no_bonus(), tower, Vector3(target.get_x(), target.get_y(), 0), 0.45)
	p.user_real = aoe_radius
	p.user_real2 = aoe_damage


func lava_pt_on_cleanup(p: Projectile):
	var aoe_radius: float = p.user_real
	var aoe_damage: float = p.user_real2
	var effect: int = Effect.add_special_effect("NeutralBuildingExplosion", Vector2(p.get_x(), p.get_y()))
	Effect.destroy_effect_after_its_over(effect)
	tower.do_spell_damage_aoe(Vector2(p.get_x(), p.get_y()), aoe_radius, aoe_damage, tower.calc_spell_crit_no_bonus(), 0.25)


func aura_bt_periodic(event: Event):
	var buff: Buff = event.get_buff()
	var creep: Creep = buff.get_buffed_unit()
	var life: float = creep.get_health()
	var dmg: float = life * 0.03 * tower.get_damage_to_category(creep.get_category())

#	Gex meant it is okay so...
	if life < 2.0:
		CombatLog.log_ability(tower, creep, "Heat Aura instant kill")
		
		tower.kill_instantly(creep)
	else:
		creep.set_health(life - dmg)


func aura_bt_on_death(event: Event):
	var buff: Buff = event.get_buff()
	var creep: Creep = buff.get_buffed_unit()
	var heat_stroke_chance: float = 0.40
	var aoe_radius: float = 300
	var aoe_damage: float = 4500 + 100 * tower.get_level()

	if !tower.calc_chance(heat_stroke_chance):
		return

	CombatLog.log_ability(tower, creep, "Heat Stroke")

	SFX.sfx_at_unit(SfxPaths.FIRE_BALL, creep)
	tower.do_spell_damage_aoe_unit(creep, aoe_radius, aoe_damage, tower.calc_spell_crit_no_bonus(), 0.33)
