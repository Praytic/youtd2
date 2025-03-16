extends TowerBehavior


# NOTE: original script uses a built-in "laser" ability. Had
# to re-implement it here using a periodic event and
# lightning visual.

# NOTE: added display of DPS for Dark Shroud ability in
# tower details.


var multiboard: MultiboardValues
var aura_bt: BuffType
var orb_pt: ProjectileType
var lesser_orb_pt: ProjectileType
var _tower_creation_time: float = 0.0
var _dark_shroud_damage_dealt: float = 0.0

const AURA_RANGE: int = 300


func get_ability_info_list_DELETEME() -> Array[AbilityInfo]:
	var list: Array[AbilityInfo] = []
	
	var dark_orbs: AbilityInfo = AbilityInfo.new()
	dark_orbs.name = "Dark Orbs"
	dark_orbs.icon = "res://resources/icons/tower_icons/dark_battery.tres"
	dark_orbs.description_short = "Whenever this tower attacks, it has a chance to spawn orbs that fire off dark rays at enemies in range, dealing spell damage.\n"
	dark_orbs.description_full = "Whenever this tower attacks, it has a 20% chance to spawn 3 orbs that travel outwards in all directions from Shadow. Orbs travel for 8 seconds, firing off dark rays at enemies within 450 range, which deal 15% of this tower's attack damage as spell damage per second.\n" \
	+ " \n" \
	+ "[color=ORANGE]Level Bonus:[/color]\n" \
	+ "+1 orb every 5 levels\n" \
	+ "+0.6% damage per second\n"
	list.append(dark_orbs)

	var soul_conversion: AbilityInfo = AbilityInfo.new()
	soul_conversion.name = "Soul Conversion"
	soul_conversion.icon = "res://resources/icons/shields/shield_with_emblem.tres"
	soul_conversion.description_short = "On kill a lesser orb is spawned where the creep died.\n"
	soul_conversion.description_full = "On kill a lesser orb is spawned where the creep died. Lesser orbs last for 3 seconds, firing off lesser dark rays at enemies within 450 range, which deal 9% of this tower's attack damage as spell damage per second.\n" \
	+ " \n" \
	+ "[color=ORANGE]Level Bonus:[/color]\n" \
	+ "+0.36% damage per second\n"
	list.append(soul_conversion)

	return list


func load_triggers(triggers: BuffType):
	triggers.add_event_on_attack(on_attack)
	triggers.add_event_on_kill(on_kill)


func tower_init():
	aura_bt = BuffType.create_aura_effect_type("aura_bt", true, self)
	aura_bt.set_buff_icon("res://resources/icons/generic_icons/alien_skull.tres")
	aura_bt.set_buff_tooltip("Dark Shroud Aura\nA portion of attack damage is stolen and dealt as Decay damage instead.")
	aura_bt.add_event_on_damage(aura_bt_on_damage)

	orb_pt = ProjectileType.create("path_to_projectile_sprite", 8, 200, self)
	orb_pt.enable_periodic(orb_pt_periodic, 1.0)

	lesser_orb_pt = ProjectileType.create("path_to_projectile_sprite", 3, 0, self)
	lesser_orb_pt.enable_periodic(lesser_orb_pt_periodic, 1.0)

	multiboard = MultiboardValues.new(1)
	multiboard.set_key(0, "Dark Shroud DPS")


func get_aura_types() -> Array[AuraType]:
	var aura: AuraType = AuraType.new()

	var decay_string: String = AttackType.convert_to_colored_string(AttackType.enm.DECAY)

	aura.name = "Dark Shroud"
	aura.icon = "res://resources/icons/tower_icons/shadow.tres"
	aura.description_short = "Towers in range have 10%% of their attack damage output stolen by Shadow. Shadow deals stolen damage as %s damage.\n" % decay_string
	aura.description_full = "Towers within %d range have 10%% of their attack damage output stolen by Shadow. This tower then deals that damage back at its original targets in the form of %s damage. This damage cannot crit.\n" % [AURA_RANGE, decay_string] \
	+ " \n" \
	+ "[color=ORANGE]Level Bonus:[/color]\n" \
	+ "+0.5% damage dealt\n"

	aura.aura_range = AURA_RANGE
	aura.target_type = TargetType.new(TargetType.TOWERS)
	aura.target_self = true
	aura.level = 0
	aura.level_add = 1
	aura.aura_effect = aura_bt

	return [aura]


func on_create(_preceding: Tower):
	_tower_creation_time = Utils.get_time()


func on_tower_details() -> MultiboardValues:
	var tower_lifetime: float = Utils.get_time() - _tower_creation_time
	var dark_shroud_dps: float = Utils.divide_safe(_dark_shroud_damage_dealt, tower_lifetime)
	var dark_shroud_dps_string: String = Utils.format_float(dark_shroud_dps, 0)
	multiboard.set_value(0, dark_shroud_dps_string)

	return multiboard


func on_attack(_event: Event):
	var level: int = tower.get_level()
	var projectile_count: int = 3 + level / 5
	var x: float = tower.get_x()
	var y: float = tower.get_y()
	var damage_ratio: float = tower.get_current_attack_damage_with_bonus() * (0.05 + 0.002 * level)

	var dark_orbs_chance: float = 0.20

	if !tower.calc_chance(dark_orbs_chance):
		return

	CombatLog.log_ability(tower, null, "Dark Orbs")

	for i in range(0, projectile_count):
		var facing: float = i * 360.0 / projectile_count
		var p: Projectile = Projectile.create(orb_pt, tower, damage_ratio, tower.calc_spell_crit_no_bonus(), Vector3(x, y, 80.0), facing)
		p.set_projectile_scale(1.75)


func on_kill(event: Event):
	var level: int = tower.get_level()
	var creep: Creep = event.get_target()
	var x: float = creep.get_x()
	var y: float = creep.get_y()
	var damage_ratio: float = tower.get_current_attack_damage_with_bonus() * (0.03 + 0.0012 * level)
	var p: Projectile = Projectile.create(lesser_orb_pt, tower, damage_ratio, tower.calc_spell_crit_no_bonus(), Vector3(x, y, 80.0), 0)
	p.set_projectile_scale(1.25)


func aura_bt_on_damage(event: Event):
	var buff: Buff = event.get_buff()
	var caster: Tower = buff.get_caster()
	var target: Unit = event.get_target()
	var damage: float = event.damage * (0.10 + 0.005 * caster.get_level())

	_dark_shroud_damage_dealt += damage

	event.damage *= 0.9

	caster.do_custom_attack_damage(target, damage, 1, AttackType.enm.DECAY)


func orb_pt_periodic(p: Projectile):
	orb_pt_periodic_generic(p)


func lesser_orb_pt_periodic(p: Projectile):
	orb_pt_periodic_generic(p)


func orb_pt_periodic_generic(p: Projectile):
	var caster: Unit = p.get_caster()
	var it: Iterate = Iterate.over_units_in_range_of(caster, TargetType.new(TargetType.CREEPS), Vector2(p.get_x(), p.get_y()), 450)

	while true:
		var next: Unit = it.next()

		if next == null:
			break

		var start_pos: Vector3 = Vector3(p.get_x(), p.get_y(), 0)
		var lightning: InterpolatedSprite = InterpolatedSprite.create_from_point_to_unit(InterpolatedSprite.LIGHTNING, start_pos, next)
		lightning.modulate = Color.PURPLE
		lightning.set_lifetime(0.1)

		p.do_spell_damage(next, 1.0)

		var effect: int = Effect.create_simple_at_unit("res://src/effects/zombify_target.tscn", next)
		Effect.set_color(effect, Color.PURPLE)
