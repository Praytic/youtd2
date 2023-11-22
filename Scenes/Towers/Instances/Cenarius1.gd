extends Tower


# NOTE: original script makes the roots projectiles make
# root effect every 0.2s. Didn't implement periodic events
# for Projectiles yet so didn't do this effect.

# NOTE: deduced the wave count of leaf storm cast like this:
# 1. tooltip says it deals 2100dmg over time.
# 2. dmg ratio for the cast is 700dmg base.
# 3. 2100 / 700 = 3 waves


var roots_pt: ProjectileType
var cenarius_entangle_bt: BuffType
var cenarius_thorned_bt: BuffType
var cenarius_tranquility_bt: BuffType
var cenarius_leaf_storm_bt: BuffType
var cenarius_leaf_storm_st: SpellType


func get_ability_description() -> String:
	var text: String = ""

	text += "[color=GOLD]Leaf Storm[/color]\n"
	text += "Each time this tower attacks it has a 15% chance to summon a 200 AoE leaf storm at the target's position, slowing enemy units inside by 30% for 1 second and dealing 2100 spell damage over time.\n"
	text += " \n"
	text += "[color=ORANGE]Level Bonus:[/color]\n"
	text += "+0.6% chance\n"
	text += "+90 spell damage\n"
	text += "+0.6% slow\n"
	text += "+0.04 seconds slow duration\n"
	text += " \n"

	text += "[color=GOLD]Thorned![/color]\n"
	text += "When a unit comes in 950 range to this tower it recieves the thorned debuff. The debuff lasts 3 seconds and increases the damage taken from nature towers by 30%.\n"
	text += " \n"
	text += "[color=ORANGE]Level Bonus:[/color]\n"
	text += "+0.06 seconds duration\n"
	text += "+0.6% damage taken\n"
	text += " \n"

	text += "[color=GOLD]Tranquility - Aura[/color]\n"
	text += "Decreases the attackspeed of all towers in a 450 AoE by 20% and increases their attackdamage by 40%.\n"
	text += " \n"
	text += "[color=ORANGE]Level Bonus:[/color]\n"
	text += "+0.4% attack damage\n"
	text += "+0.4% attackspeed\n"

	return text


func get_ability_description_short() -> String:
	var text: String = ""

	text += "[color=GOLD]Leaf Storm[/color]\n"
	text += "Chance to summon a leaf storm at the target's position, slowing enemy units inside and dealing damage over time.\n"
	text += " \n"

	text += "[color=GOLD]Thorned![/color]\n"
	text += "When a unit comes in range it recieves the thorned debuff. The debuff increases the damage taken from nature towers.\n"
	text += " \n"

	text += "[color=GOLD]Tranquility - Aura[/color]\n"
	text += "Decreases the attackspeed of all nearby towers and increases their attackdamage.\n"

	return text


func get_autocast_description() -> String:
	var text: String = ""

	text += "Launches 3 rows of roots towards the target which will travel a distance of 1000, entangling creeps hit for 1.5 seconds, causing them to become immobilized and take 1100 spell damage per second.\n"
	text += " \n"
	text += "[color=ORANGE]Level Bonus:[/color]\n"
	text += "+44 spell damage\n"
	text += "+0.02 seconds\n"

	return text


func get_autocast_description_short() -> String:
	return "Launches roots towards the target which will entangle creeps.\n"


func load_triggers(triggers: BuffType):
	triggers.add_event_on_damage(on_damage)
	triggers.add_event_on_unit_comes_in_range(on_unit_in_range, 950, TargetType.new(TargetType.CREEPS))


func tower_init():
	cenarius_tranquility_bt = BuffType.create_aura_effect_type("cenarius_tranquility_bt", true, self)
	var cenarius_tranquility_mod: Modifier = Modifier.new()
	cenarius_tranquility_mod.add_modification(Modification.Type.MOD_ATTACKSPEED, -0.2, 0.004)
	cenarius_tranquility_mod.add_modification(Modification.Type.MOD_DAMAGE_ADD_PERC, 0.4, 0.004)
	cenarius_tranquility_bt.set_buff_modifier(cenarius_tranquility_mod)
	cenarius_tranquility_bt.set_buff_icon("@@2@@")
	cenarius_tranquility_bt.set_buff_tooltip("Tranquility Aura\nThis tower is under the effect of Tranquility Aura; it has reduced attack speed but will deal extra damage.")

	cenarius_entangle_bt = CbStun.new("cenarius_entangle_bt", 1.5, 0.02, false, self)
	cenarius_entangle_bt.set_buff_icon("@@4@@")
	cenarius_entangle_bt.add_periodic_event(cenarius_entangle_bt_periodic, 1.0)
	cenarius_entangle_bt.set_buff_tooltip("Entangle\nThis creep is entangled; it can't move and will take periodic damage.")

	roots_pt = ProjectileType.create_ranged("", 1000, 600, self)
	roots_pt.enable_collision(roots_pt_on_hit, 175, TargetType.new(TargetType.CREEPS), false)
	# TODO: implement this when
	# ProjectileType.add_periodic_event() is implemented.
	# roots_pt.add_periodic_event(roots_pt_periodic, 0.2)

	cenarius_leaf_storm_st = SpellType.new("@@0@@", "blizzard", 4.00, self)
	cenarius_leaf_storm_st.set_damage_event(cenarius_leaf_storm_st_on_damage)
	cenarius_leaf_storm_st.data.blizzard.damage = 1.0
	cenarius_leaf_storm_st.data.blizzard.radius = 200
	cenarius_leaf_storm_st.data.blizzard.wave_count = 3

	var cenarius_leaf_storm_mod: Modifier = Modifier.new()
	cenarius_leaf_storm_bt = BuffType.new("cenarius_leaf_storm_bt", 1.0, 0.04, false, self)
	cenarius_leaf_storm_mod.add_modification(Modification.Type.MOD_MOVESPEED, -0.3, -0.006)
	cenarius_leaf_storm_bt.set_buff_modifier(cenarius_leaf_storm_mod)
	cenarius_leaf_storm_bt.set_buff_icon("@@5@@")
	cenarius_leaf_storm_bt.set_buff_tooltip("Leaf Storm\nThis creep is inside a Leaf Storm; it has reduced movement speed.")

	cenarius_thorned_bt = BuffType.new("cenarius_thorned_bt", 3.0, 0.06, false, self)
	var cenarius_thorned_mod: Modifier = Modifier.new()
	cenarius_thorned_mod.add_modification(Modification.Type.MOD_DMG_FROM_NATURE, 0.3, 0.006)
	cenarius_thorned_bt.set_buff_modifier(cenarius_thorned_mod)
	cenarius_thorned_bt.set_buff_icon("@@7@@")
	cenarius_thorned_bt.set_buff_tooltip("Thorned\nThis creep has been thorned; it will take extra damage from Nature towers.")

	var autocast: Autocast = Autocast.make()
	autocast.title = "Entangling Roots"
	autocast.description = get_autocast_description()
	autocast.description_short = get_autocast_description_short()
	autocast.icon = "res://path/to/icon.png"
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
	add_autocast(autocast)


func get_aura_types() -> Array[AuraType]:
	var aura: AuraType = AuraType.new()
	aura.aura_range = 450
	aura.target_type = TargetType.new(TargetType.TOWERS)
	aura.target_self = true
	aura.level = 0
	aura.level_add = 1
	aura.power = 0
	aura.power_add = 1
	aura.aura_effect = cenarius_tranquility_bt

	return [aura]


func on_damage(event: Event):
	var tower: Tower = self
	var target: Unit = event.get_target()
	var leaf_storm_chance: float = 0.15 + 0.006 * tower.get_level()
	var damage_ratio: float = 700 + 30 * tower.get_level()

	if !tower.calc_chance(leaf_storm_chance):
		return

	cenarius_leaf_storm_st.target_cast_from_caster(tower, target, damage_ratio, tower.calc_spell_crit_no_bonus())


func on_unit_in_range(event: Event):
	var tower: Tower = self
	var target: Unit = event.get_target()
	cenarius_thorned_bt.apply(tower, target, tower.get_level())


func on_autocast(event: Event):
	var tower: Tower = self
	var target: Unit = event.get_target()
	var angle: float = rad_to_deg((target.global_position - tower.global_position).angle())

	Projectile.create_from_unit(roots_pt, tower, tower, angle, 1.0, tower.calc_spell_crit_no_bonus())
	Projectile.create_from_unit(roots_pt, tower, tower, angle + 15.0, 1.0, tower.calc_spell_crit_no_bonus())
	Projectile.create_from_unit(roots_pt, tower, tower, angle - 15.0, 1.0, tower.calc_spell_crit_no_bonus())


func roots_pt_on_hit(p: Projectile, target: Unit):
	var caster: Unit = p.get_caster()
	cenarius_entangle_bt.apply(caster, target, caster.get_level())


func cenarius_entangle_bt_periodic(event: Event):
	var buff: Buff = event.get_buff()
	var caster: Unit = buff.get_caster()
	var target: Unit = buff.get_buffed_unit()
	var damage: float = 1100 + 44 * caster.get_level()

	caster.do_spell_damage(target, damage, caster.calc_spell_crit_no_bonus())


func cenarius_leaf_storm_st_on_damage(event: Event, dummy_unit: DummyUnit):
	var tower: Tower = dummy_unit.get_caster()
	var target: Unit = event.get_target()
	cenarius_leaf_storm_bt.apply(tower, target, tower.get_level())
