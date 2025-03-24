extends TowerBehavior

# NOTE: [ORIGINAL_GAME_DEVIATION] Renamed
# "Cenarius"=>"Cenarion"

# NOTE: deduced the wave count of leaf storm cast like this:
# 1. tooltip says it deals 2100dmg over time.
# 2. dmg ratio for the cast is 700dmg base.
# 3. 2100 / 700 = 3 waves


var roots_pt: ProjectileType
var entangle_bt: BuffType
var thorned_bt: BuffType
var tranquility_bt: BuffType
var leaf_storm_bt: BuffType
var leaf_storm_st: SpellType


const AURA_RANGE: int = 450


func load_triggers(triggers: BuffType):
	triggers.add_event_on_damage(on_damage)
	triggers.add_event_on_unit_comes_in_range(on_unit_in_range, 950, TargetType.new(TargetType.CREEPS))


func tower_init():
	tranquility_bt = BuffType.create_aura_effect_type("tranquility_bt", true, self)
	var tranquility_mod: Modifier = Modifier.new()
	tranquility_mod.add_modification(Modification.Type.MOD_ATTACKSPEED, -0.2, 0.004)
	tranquility_mod.add_modification(Modification.Type.MOD_DAMAGE_ADD_PERC, 0.4, 0.004)
	tranquility_bt.set_buff_modifier(tranquility_mod)
	tranquility_bt.set_buff_icon("res://resources/icons/generic_icons/angel_wings.tres")
	tranquility_bt.set_buff_tooltip(tr("I4NZ"))

	entangle_bt = CbStun.new("entangle_bt", 1.5, 0.02, false, self)
	entangle_bt.set_buff_icon("res://resources/icons/generic_icons/root_tip.tres")
	entangle_bt.add_periodic_event(entangle_bt_periodic, 1.0)
	entangle_bt.set_buff_tooltip(tr("ZXE9"))

	roots_pt = ProjectileType.create_ranged("", 1000, 600, self)
	roots_pt.enable_collision(roots_pt_on_hit, 175, TargetType.new(TargetType.CREEPS), false)
	roots_pt.enable_periodic(roots_pt_periodic, 0.2)

	leaf_storm_st = SpellType.new(SpellType.Name.BLIZZARD, 4.00, self)
	leaf_storm_st.set_damage_event(leaf_storm_st_on_damage)
	leaf_storm_st.data.blizzard.damage = 1.0
	leaf_storm_st.data.blizzard.radius = 200
	leaf_storm_st.data.blizzard.wave_count = 3

	var leaf_storm_mod: Modifier = Modifier.new()
	leaf_storm_bt = BuffType.new("leaf_storm_bt", 1.0, 0.04, false, self)
	leaf_storm_mod.add_modification(Modification.Type.MOD_MOVESPEED, -0.3, -0.006)
	leaf_storm_bt.set_buff_modifier(leaf_storm_mod)
	leaf_storm_bt.set_buff_icon("res://resources/icons/generic_icons/atomic_slashes.tres")
	leaf_storm_bt.set_buff_tooltip(tr("BCDD"))

	thorned_bt = BuffType.new("thorned_bt", 3.0, 0.06, false, self)
	var thorned_mod: Modifier = Modifier.new()
	thorned_mod.add_modification(Modification.Type.MOD_DMG_FROM_NATURE, 0.3, 0.006)
	thorned_bt.set_buff_modifier(thorned_mod)
	thorned_bt.set_buff_icon("res://resources/icons/generic_icons/polar_star.tres")
	thorned_bt.set_buff_tooltip(tr("AB6M"))


func on_damage(event: Event):
	var target: Unit = event.get_target()
	var leaf_storm_chance: float = 0.15 + 0.006 * tower.get_level()
	var damage_ratio: float = 700 + 30 * tower.get_level()

	if !tower.calc_chance(leaf_storm_chance):
		return

	CombatLog.log_ability(tower, target, "Leaf Storm")

	leaf_storm_st.target_cast_from_caster(tower, target, damage_ratio, tower.calc_spell_crit_no_bonus())


func on_unit_in_range(event: Event):
	var target: Unit = event.get_target()
	thorned_bt.apply(tower, target, tower.get_level())


func on_autocast(event: Event):
	var target: Unit = event.get_target()
	var angle: float = rad_to_deg((target.get_position_wc3_2d() - tower.get_position_wc3_2d()).angle())

	Projectile.create_from_unit(roots_pt, tower, tower, angle, 1.0, tower.calc_spell_crit_no_bonus())
	Projectile.create_from_unit(roots_pt, tower, tower, angle + 15.0, 1.0, tower.calc_spell_crit_no_bonus())
	Projectile.create_from_unit(roots_pt, tower, tower, angle - 15.0, 1.0, tower.calc_spell_crit_no_bonus())


func roots_pt_on_hit(p: Projectile, target: Unit):
	var caster: Unit = p.get_caster()
	entangle_bt.apply(caster, target, caster.get_level())


# NOTE: WWPeriodic() in original script
func roots_pt_periodic(p: Projectile):
	var effect: int = Effect.create_scaled("res://src/effects/roots.tscn", Vector3(p.get_x(), p.get_y(), 0), 0, 0.5)
	Effect.set_lifetime(effect, 2.0)


func entangle_bt_periodic(event: Event):
	var buff: Buff = event.get_buff()
	var caster: Unit = buff.get_caster()
	var target: Unit = buff.get_buffed_unit()
	var damage: float = 1100 + 44 * caster.get_level()

	caster.do_spell_damage(target, damage, caster.calc_spell_crit_no_bonus())


func leaf_storm_st_on_damage(event: Event, _dummy_unit: DummyUnit):
	var target: Unit = event.get_target()
	leaf_storm_bt.apply(tower, target, tower.get_level())
