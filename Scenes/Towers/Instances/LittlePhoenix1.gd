extends Tower


var tomy_phoenix_pt: ProjectileType
var tomy_phoenix_fire_buff: BuffType
var buff_was_purged: bool = false


func get_tier_stats() -> Dictionary:
	return {
		1: {target_count = 2, mod_armor = 0.50, mod_armor_add = 0.010, erupt_damage = 100, armor_regain = 0.70, armor_regain_add = 0.010, damage_per_power = 1.0},
		2: {target_count = 3, mod_armor = 0.60, mod_armor_add = 0.015, erupt_damage = 260, armor_regain = 0.60, armor_regain_add = 0.015, damage_per_power = 2.6},
		3: {target_count = 4, mod_armor = 0.70, mod_armor_add = 0.020, erupt_damage = 440, armor_regain = 0.50, armor_regain_add = 0.020, damage_per_power = 4.4},
	}


const DEBUFF_DURATION: float = 5.0
const ERUPT_RANGE: float = 200


func get_extra_tooltip_text() -> String:
	var target_count: String = Utils.format_float(_stats.target_count, 2)
	var mod_armor: String = Utils.format_float(_stats.mod_armor, 2)
	var mod_armor_add: String = Utils.format_float(_stats.mod_armor_add, 3)
	var debuff_duration: String = Utils.format_float(DEBUFF_DURATION, 2)

	var text: String = ""

	text += "[color=GOLD]Phoenixfire[/color]\n"
	text += "The Phoenix attacks up to %s targets at once. If there are less creeps than attacks, the remaining attacks will hit the main target. The armor of attacked creeps melts, reducing it by %s for %s seconds. This buff is stackable.\n" % [target_count, mod_armor, debuff_duration]
	text += " \n"
	text += "[color=ORANGE]Level Bonus:[/color]\n"
	text += "+%s armor reduction\n" % mod_armor_add
	text += "+1 target at level 15\n"

	return text


func get_autocast_description() -> String:
	var erupt_damage: String = Utils.format_float(_stats.erupt_damage, 2)
	var erupt_range: String = Utils.format_float(ERUPT_RANGE, 2)
	var armor_regain: String = Utils.format_percent(_stats.armor_regain, 2)
	var armor_regain_add: String = Utils.format_percent(_stats.armor_regain_add, 2)

	var text: String = ""

	text += "When Phoenixfire expires, it erupts and deals %s elemental damage per armor point the creep is missing in %s range around its target. Additionally the target regains only %s of its armor. Creeps further away recieve less damage. This ability can be cast to make Phoenixfire expire immediately.\n" % [erupt_damage, erupt_range, armor_regain]
	text += " \n"
	text += "[color=ORANGE]Level Bonus:[/color]\n"
	text += "-%s armor regain\n" % armor_regain_add

	return text


func load_triggers(triggers: BuffType):
	triggers.add_event_on_attack(on_attack)
	triggers.add_event_on_damage(on_damage)


func load_specials(modifier: Modifier):
	modifier.add_modification(Modification.Type.MOD_DMG_TO_NATURE, 0.20, 0.01)


func tomy_phoenix_attack_hit(_p: Projectile, target: Unit):
	var tower: Tower = self
	
	_apply_phoenix_fire_buff(target)

	tower.do_attack_damage(target, tower.get_current_attack_damage_with_bonus(), tower.calc_attack_multicrit(0, 0, 0))


func phoenix_fire_buff_on_purge(_event: Event):
	buff_was_purged = true


func phoenix_fire_buff_on_cleanup(event: Event):
	var tower: Tower = self
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

	tomy_phoenix_fire_buff = BuffType.new("tomy_phoenix_fire_buff", 5, 0, false, self)
	tomy_phoenix_fire_buff.set_buff_icon("@@0@@")
	tomy_phoenix_fire_buff.set_buff_modifier(mod)
	tomy_phoenix_fire_buff.add_event_on_cleanup(phoenix_fire_buff_on_cleanup)
	tomy_phoenix_fire_buff.add_event_on_purge(phoenix_fire_buff_on_purge)
	tomy_phoenix_fire_buff.set_buff_tooltip("Title\nDescription.")

	tomy_phoenix_pt = ProjectileType.create_interpolate("Phoenix_Missile.mdl", 800, self)
	tomy_phoenix_pt.set_event_on_interpolation_finished(tomy_phoenix_attack_hit)

	var autocast: Autocast = Autocast.make()
	autocast.title = "Eruption"
	autocast.description = get_autocast_description()
	autocast.icon = "res://path/to/icon.png"
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
	add_autocast(autocast)


func on_attack(event: Event):
	var tower: Tower = self
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

		var projectile: Projectile = Projectile.create_bezier_interpolation_from_unit_to_unit(tomy_phoenix_pt, tower, 0, 0, tower, target, 0, sidearc, 0, true)
		projectile.setScale(0.4)

		current_target_count -= 1


func on_damage(event: Event):
	var target: Unit = event.get_target()

	_apply_phoenix_fire_buff(target)


func on_autocast(_event: Event):
	var tower: Tower = self
	var it: Iterate = Iterate.over_units_in_range_of_caster(tower, TargetType.new(TargetType.CREEPS), 3000)

	while it.count() > 0:
		var creep: Unit = it.next()

		var buff: Buff = creep.get_buff_of_type(tomy_phoenix_fire_buff)

		if buff != null:
			buff.remove_buff()


func _apply_phoenix_fire_buff(target: Unit):
	var tower: Tower = self
	var level: int = tower.get_level()
	var armor_loss: float = _stats.mod_armor + _stats.mod_armor_add * level
	var buff: Buff = target.get_buff_of_type(tomy_phoenix_fire_buff)

	if buff != null:
		tomy_phoenix_fire_buff.apply(tower, target, buff.get_power() + int(armor_loss * 100))
	else:
		tomy_phoenix_fire_buff.apply(tower, target, int(armor_loss * 100))

