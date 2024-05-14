extends TowerBehavior


# NOTE: original script makes the roots projectiles make
# root effect every 0.2s. Didn't implement periodic events
# for Projectiles yet so didn't do this effect.

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


func get_ability_info_list() -> Array[AbilityInfo]:
	var nature_string: String = Element.convert_to_colored_string(Element.enm.NATURE)
	
	var list: Array[AbilityInfo] = []
	
	var leaf_storm: AbilityInfo = AbilityInfo.new()
	leaf_storm.name = "Leaf Storm"
	leaf_storm.icon = "res://Resources/Icons/plants/leaf_01.tres"
	leaf_storm.description_short = "Chance to summon a leaf storm at the target's position, slowing creeps inside and dealing damage over time.\n"
	leaf_storm.description_full = "Each time this tower attacks it has a 15% chance to summon a 200 AoE leaf storm at the target's position, slowing creeps inside by 30% for 1 second and dealing 2100 spell damage over time.\n" \
	+ " \n" \
	+ "[color=ORANGE]Level Bonus:[/color]\n" \
	+ "+0.6% chance\n" \
	+ "+90 spell damage\n" \
	+ "+0.6% slow\n" \
	+ "+0.04 seconds slow duration\n"
	list.append(leaf_storm)

	var thorned: AbilityInfo = AbilityInfo.new()
	thorned.name = "Thorned!"
	thorned.icon = "res://Resources/Icons/TowerIcons/QuillboarThornweaver.tres"
	thorned.description_short = "When a unit comes in range it receives the thorned debuff. The debuff increases the damage taken from nature towers.\n"
	thorned.description_full = "When a unit comes in 950 range to this tower it receives the thorned debuff. The debuff lasts 3 seconds and increases the damage taken from %s towers by 30%%.\n" % nature_string \
	+ " \n" \
	+ "[color=ORANGE]Level Bonus:[/color]\n" \
	+ "+0.06 seconds duration\n" \
	+ "+0.6% damage taken\n"
	thorned.radius = 950
	thorned.target_type = TargetType.new(TargetType.CREEPS)
	list.append(thorned)

	return list


func load_triggers(triggers: BuffType):
	triggers.add_event_on_damage(on_damage)
	triggers.add_event_on_unit_comes_in_range(on_unit_in_range, 950, TargetType.new(TargetType.CREEPS))


func tower_init():
	tranquility_bt = BuffType.create_aura_effect_type("tranquility_bt", true, self)
	var cenarius_tranquility_mod: Modifier = Modifier.new()
	cenarius_tranquility_mod.add_modification(Modification.Type.MOD_ATTACKSPEED, -0.2, 0.004)
	cenarius_tranquility_mod.add_modification(Modification.Type.MOD_DAMAGE_ADD_PERC, 0.4, 0.004)
	tranquility_bt.set_buff_modifier(cenarius_tranquility_mod)
	tranquility_bt.set_buff_icon("res://Resources/Icons/GenericIcons/angel_wings.tres")
	tranquility_bt.set_buff_tooltip("Tranquility Aura\nReduces attack speed and increases attack damage.")

	entangle_bt = CbStun.new("entangle_bt", 1.5, 0.02, false, self)
	entangle_bt.set_buff_icon("res://Resources/Icons/GenericIcons/root_tip.tres")
	entangle_bt.add_periodic_event(entangle_bt_periodic, 1.0)
	entangle_bt.set_buff_tooltip("Entangle\nPrevents movement and deals damage over time.")

	roots_pt = ProjectileType.create_ranged("", 1000, 600, self)
	roots_pt.enable_collision(roots_pt_on_hit, 175, TargetType.new(TargetType.CREEPS), false)
	roots_pt.enable_periodic(roots_pt_periodic, 0.2)

	leaf_storm_st = SpellType.new("@@0@@", "blizzard", 4.00, self)
	leaf_storm_st.set_damage_event(leaf_storm_st_on_damage)
	leaf_storm_st.data.blizzard.damage = 1.0
	leaf_storm_st.data.blizzard.radius = 200
	leaf_storm_st.data.blizzard.wave_count = 3

	var cenarius_leaf_storm_mod: Modifier = Modifier.new()
	leaf_storm_bt = BuffType.new("leaf_storm_bt", 1.0, 0.04, false, self)
	cenarius_leaf_storm_mod.add_modification(Modification.Type.MOD_MOVESPEED, -0.3, -0.006)
	leaf_storm_bt.set_buff_modifier(cenarius_leaf_storm_mod)
	leaf_storm_bt.set_buff_icon("res://Resources/Icons/GenericIcons/atomic_slashes.tres")
	leaf_storm_bt.set_buff_tooltip("Leaf Storm\nThis creep is inside a Leaf Storm; it has reduced movement speed.")

	thorned_bt = BuffType.new("thorned_bt", 3.0, 0.06, false, self)
	var cenarius_thorned_mod: Modifier = Modifier.new()
	cenarius_thorned_mod.add_modification(Modification.Type.MOD_DMG_FROM_NATURE, 0.3, 0.006)
	thorned_bt.set_buff_modifier(cenarius_thorned_mod)
	thorned_bt.set_buff_icon("res://Resources/Icons/GenericIcons/polar_star.tres")
	thorned_bt.set_buff_tooltip("Thorned\nIncreases damage taken from Nature towers.")

func create_autocasts() -> Array[Autocast]:
	var autocast: Autocast = Autocast.make()

	autocast.title = "Entangling Roots"
	autocast.icon = "res://Resources/Icons/plants/branch_01.tres"
	autocast.description_short = "Launches roots towards the target which will entangle creeps.\n"
	autocast.description = "Launches 3 rows of roots towards the target which will travel a distance of 1000, entangling creeps hit for 1.5 seconds, causing them to become immobilized and take 1100 spell damage per second.\n" \
	+ " \n" \
	+ "[color=ORANGE]Level Bonus:[/color]\n" \
	+ "+44 spell damage\n" \
	+ "+0.02 seconds\n"
	autocast.caster_art = ""
	autocast.target_art = ""
	autocast.autocast_type = Autocast.Type.AC_TYPE_OFFENSIVE_UNIT
	autocast.num_buffs_before_idle = 0
	autocast.cast_range = 950
	autocast.auto_range = 950
	autocast.cooldown = 10.0
	autocast.mana_cost = 90
	autocast.target_self = true
	autocast.is_extended = false
	autocast.buff_type = null
	autocast.target_type = TargetType.new(TargetType.CREEPS)
	autocast.handler = on_autocast

	return [autocast]


func get_aura_types() -> Array[AuraType]:
	var aura: AuraType = AuraType.new()

	aura.name = "Tranquility"
	aura.icon = "res://Resources/Icons/misc/flag_03.tres"
	aura.description_short = "Decreases the attack speed of all nearby towers and increases their attack damage.\n"
	aura.description_full = "Decreases the attack speed of all towers in a %d AoE by 20%% and increases their attack damage by 40%%.\n" % AURA_RANGE\
	+ " \n" \
	+ "[color=ORANGE]Level Bonus:[/color]\n" \
	+ "+0.4% attack damage\n" \
	+ "+0.4% attack speed\n"

	aura.aura_range = AURA_RANGE
	aura.target_type = TargetType.new(TargetType.TOWERS)
	aura.target_self = true
	aura.level = 0
	aura.level_add = 1
	aura.power = 0
	aura.power_add = 1
	aura.aura_effect = tranquility_bt

	return [aura]


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
	var effect: int = Effect.create_scaled("EntanglingRootsTarget.mdl", Vector3(p.get_x(), p.get_y(), 0), 0, 4.0)
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
