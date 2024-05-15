extends TowerBehavior


var phoenix_pt: ProjectileType
var phoenix_fire_bt: BuffType
var buff_was_purged: bool = false


func get_tier_stats() -> Dictionary:
	return {
		1: {target_count = 2, mod_armor = 0.50, mod_armor_add = 0.010, erupt_damage = 100, armor_regain = 0.70, armor_regain_add = 0.010, damage_per_power = 1.0},
		2: {target_count = 3, mod_armor = 0.60, mod_armor_add = 0.015, erupt_damage = 260, armor_regain = 0.60, armor_regain_add = 0.015, damage_per_power = 2.6},
		3: {target_count = 4, mod_armor = 0.70, mod_armor_add = 0.020, erupt_damage = 440, armor_regain = 0.50, armor_regain_add = 0.020, damage_per_power = 4.4},
	}


const DEBUFF_DURATION: float = 5.0
const ERUPT_RANGE: float = 200


func get_ability_info_list() -> Array[AbilityInfo]:
	var target_count: String = Utils.format_float(_stats.target_count, 2)
	var mod_armor: String = Utils.format_float(_stats.mod_armor, 2)
	var mod_armor_add: String = Utils.format_float(_stats.mod_armor_add, 3)
	var debuff_duration: String = Utils.format_float(DEBUFF_DURATION, 2)

	var erupt_damage: String = Utils.format_float(_stats.erupt_damage, 2)
	var erupt_range: String = Utils.format_float(ERUPT_RANGE, 2)
	var armor_regain: String = Utils.format_percent(_stats.armor_regain, 2)
	var armor_regain_add: String = Utils.format_percent(_stats.armor_regain_add, 2)

	var element_string: String = AttackType.convert_to_colored_string(AttackType.enm.ELEMENTAL)

	var list: Array[AbilityInfo] = []
	
	var twin_attack: AbilityInfo = AbilityInfo.new()
	twin_attack.name = "Twin Attack"
	twin_attack.icon = "res://Resources/Icons/bows/arrow_02.tres"
	twin_attack.description_short = "The Phoenix attacks multiple targets at once.\n"
	twin_attack.description_full = "The Phoenix attacks up to %s targets at once. If there are less creeps than attacks, the remaining attacks will hit the main target. Each attack applies [color=GOLD]Phoenixfire[/color].\n" % [target_count] \
	+ " \n" \
	+ "Note: these extra attacks are not considered as a \"true multishot\" and do not trigger any \"on hit\" abilities, other than [color=GOLD]Phoenixfire[/color].\n" \
	+ " \n" \
	+ "[color=ORANGE]Level Bonus:[/color]\n" \
	+ "+1 target at level 15\n"
	list.append(twin_attack)

	var phoenixfire: AbilityInfo = AbilityInfo.new()
	phoenixfire.name = "Phoenixfire"
	phoenixfire.icon = "res://Resources/Icons/orbs/orb_molten.tres"
	phoenixfire.description_short = "Whenever this tower hits a creep, it reduces creep's armor.\n"
	phoenixfire.description_full = "Whenever this tower hits a creep, it reduces creep's armor by %s for %s seconds. This buff is stackable.\n" % [mod_armor, debuff_duration] \
	+ " \n" \
	+ "[color=ORANGE]Level Bonus:[/color]\n" \
	+ "+%s armor reduction\n" % mod_armor_add
	list.append(phoenixfire)

	var phoenix_explosion: AbilityInfo = AbilityInfo.new()
	phoenix_explosion.name = "Phoenix Explosion"
	phoenix_explosion.icon = "res://Resources/Icons/elements/fire.tres"
	phoenix_explosion.description_short = "When [color=GOLD]Phoenixfire[/color] expires, it erupts and deals AoE attack damage."
	phoenix_explosion.description_full = "When [color=GOLD]Phoenixfire[/color] expires, it erupts and deals %s %s damage per armor point the creep is missing in %s range around its target. Additionally the target regains only %s of its armor. Creeps further away receive less damage.\n" % [erupt_damage, element_string, erupt_range, armor_regain] \
	+ " \n" \
	+ "[color=ORANGE]Level Bonus:[/color]\n" \
	+ "-%s armor regain\n" % armor_regain_add
	list.append(phoenix_explosion)

	return list


func load_triggers(triggers: BuffType):
	triggers.add_event_on_attack(on_attack)
	triggers.add_event_on_damage(on_damage)


func load_specials(modifier: Modifier):
	modifier.add_modification(Modification.Type.MOD_DMG_TO_NATURE, 0.20, 0.01)


# NOTE: tomy_PhoenixAttackHit() in original script 
func tomy_phoenix_attack_hit(_p: Projectile, target: Unit):
	if target == null:
		return

	_apply_phoenix_fire_buff(target)

	tower.do_attack_damage(target, tower.get_current_attack_damage_with_bonus(), tower.calc_attack_multicrit(0, 0, 0))


# NOTE: tomy_PhoenixFireBuffPurged() in original script 
func phoenix_fire_bt_on_purge(_event: Event):
	buff_was_purged = true


# NOTE: tomy_PhoenixFireBuffExpired() in original script 
func phoenix_fire_bt_on_cleanup(event: Event):
	var target: Unit = event.get_target()
	var buff: Buff = event.get_buff()
	var power: int = buff.get_power()
	var level: int = tower.get_level()
	var damage_multiplier: float = tower.get_current_attack_damage_with_bonus() / tower.get_base_damage()
	var eruption_damage: float = power * _stats.damage_per_power * damage_multiplier
	var armor_regain_factor: float = _stats.armor_regain + _stats.armor_regain_add * level
	var armor_regain: float = -power / 100.0 * (1 - armor_regain_factor)

	if !buff_was_purged:
		tower.do_attack_damage_aoe_unit(target, ERUPT_RANGE, eruption_damage, tower.calc_attack_multicrit(0, 0, 0), 0.5)
		SFX.sfx_at_unit("FireLordDeathExplode.mdl", target)

	target.modify_property(Modification.Type.MOD_ARMOR, armor_regain)

	buff_was_purged = false


func tower_init():
	var mod: Modifier = Modifier.new()
	mod.add_modification(Modification.Type.MOD_ARMOR, 0.0, -0.01)

	phoenix_fire_bt = BuffType.new("phoenix_fire_bt", 5, 0, false, self)
	phoenix_fire_bt.set_buff_icon("res://Resources/Icons/GenericIcons/flame.tres")
	phoenix_fire_bt.set_buff_modifier(mod)
	phoenix_fire_bt.add_event_on_cleanup(phoenix_fire_bt_on_cleanup)
	phoenix_fire_bt.add_event_on_purge(phoenix_fire_bt_on_purge)
	phoenix_fire_bt.set_buff_tooltip("Phoenixfire\nReduces armor and makes the creep explode when the debuff expires.")

	phoenix_pt = ProjectileType.create_interpolate("Phoenix_Missile.mdl", 800, self)
	phoenix_pt.set_event_on_interpolation_finished(tomy_phoenix_attack_hit)


func create_autocasts() -> Array[Autocast]:
	var autocast: Autocast = Autocast.make()
	
	autocast.title = "Eruption"
	autocast.icon = "res://Resources/Icons/fire/fire_bowl_02.tres"
	autocast.description_short = "Explodes all creeps affected by [color=GOLD]Phoenixfire[/color].\n"
	autocast.description = "Explodes all creeps affected by [color=GOLD]Phoenixfire[/color], triggering the [color=GOLD]Phoenix Explosion[/color] ability. [color=GOLD]Phoenixfire[/color] debuff expires after explosion.\n"
	autocast.caster_art = ""
	autocast.num_buffs_before_idle = 0
	autocast.autocast_type = Autocast.Type.AC_TYPE_NOAC_IMMEDIATE
	autocast.cast_range = 0
	autocast.target_self = true
	autocast.target_art = ""
	autocast.cooldown = 1
	autocast.is_extended = false
	autocast.mana_cost = 0
	autocast.buff_type = null
	autocast.target_type = null
	autocast.auto_range = 0
	autocast.handler = on_autocast

	return [autocast]


func on_attack(event: Event):
	var main_target: Unit = event.get_target()
#	NOTE: subtract 1 from target_count because the normal
#	attack performed by tower is part of that count
	var current_target_count: int = _stats.target_count - 1
	var it: Iterate = Iterate.over_units_in_range_of_unit(tower, TargetType.new(TargetType.CREEPS), main_target, 450)
	var sidearc: float = 0.2

	if tower.get_level() >= 15:
		current_target_count += 1

	while current_target_count > 0:
		var target: Unit

		if it.count() > 0:
			target = it.next()
		else:
			target = main_target

		var projectile: Projectile = Projectile.create_bezier_interpolation_from_unit_to_unit(phoenix_pt, tower, 0, 0, tower, target, 0, sidearc, 0, true)
		projectile.set_projectile_scale(0.4)

		current_target_count -= 1


func on_damage(event: Event):
	var target: Unit = event.get_target()

	_apply_phoenix_fire_buff(target)


func on_autocast(_event: Event):
	var it: Iterate = Iterate.over_units_in_range_of_caster(tower, TargetType.new(TargetType.CREEPS), 3000)

	while it.count() > 0:
		var creep: Unit = it.next()

		var buff: Buff = creep.get_buff_of_type(phoenix_fire_bt)

		if buff != null:
			buff.remove_buff()


func _apply_phoenix_fire_buff(target: Unit):
	var level: int = tower.get_level()
	var armor_loss: float = _stats.mod_armor + _stats.mod_armor_add * level
	var buff: Buff = target.get_buff_of_type(phoenix_fire_bt)

	if buff != null:
		phoenix_fire_bt.apply(tower, target, buff.get_power() + int(armor_loss * 100))
	else:
		phoenix_fire_bt.apply(tower, target, int(armor_loss * 100))
