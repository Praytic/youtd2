extends TowerBehavior


var phoenix_pt: ProjectileType
var phoenix_fire_bt: BuffType
var buff_was_purged: bool = false


func get_tier_stats() -> Dictionary:
	return {
		1: {target_count = 2, mod_armor = 0.50, mod_armor_add = 0.010, erupt_damage = 100, armor_regain = 0.70, armor_regain_add = 0.010, damage_per_buff_level = 1.0},
		2: {target_count = 3, mod_armor = 0.60, mod_armor_add = 0.015, erupt_damage = 260, armor_regain = 0.60, armor_regain_add = 0.015, damage_per_buff_level = 2.6},
		3: {target_count = 4, mod_armor = 0.70, mod_armor_add = 0.020, erupt_damage = 440, armor_regain = 0.50, armor_regain_add = 0.020, damage_per_buff_level = 4.4},
	}


const DEBUFF_DURATION: float = 5.0
const ERUPT_RANGE: float = 200


func load_triggers(triggers: BuffType):
	triggers.add_event_on_attack(on_attack)
	triggers.add_event_on_damage(on_damage)


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
	var buff_level: int = buff.get_level()
	var level: int = tower.get_level()
	var damage_multiplier: float = tower.get_current_attack_damage_with_bonus() / tower.get_base_damage()
	var eruption_damage: float = buff_level * _stats.damage_per_buff_level * damage_multiplier
	var armor_regain_factor: float = _stats.armor_regain + _stats.armor_regain_add * level
	var armor_regain: float = -buff_level / 100.0 * (1 - armor_regain_factor)

	if !buff_was_purged:
		tower.do_attack_damage_aoe_unit(target, ERUPT_RANGE, eruption_damage, tower.calc_attack_multicrit(0, 0, 0), 0.5)
		Effect.create_simple_at_unit("res://src/effects/firelord_death_explode.tscn", target)

	target.modify_property(ModificationType.enm.MOD_ARMOR, armor_regain)

	buff_was_purged = false


func tower_init():
	var mod: Modifier = Modifier.new()
	mod.add_modification(ModificationType.enm.MOD_ARMOR, 0.0, -0.01)

	phoenix_fire_bt = BuffType.new("phoenix_fire_bt", 5, 0, false, self)
	phoenix_fire_bt.set_buff_icon("res://resources/icons/generic_icons/flame.tres")
	phoenix_fire_bt.set_buff_modifier(mod)
	phoenix_fire_bt.add_event_on_cleanup(phoenix_fire_bt_on_cleanup)
	phoenix_fire_bt.add_event_on_purge(phoenix_fire_bt_on_purge)
	phoenix_fire_bt.set_buff_tooltip(tr("C1QL"))

	phoenix_pt = ProjectileType.create_interpolate("path_to_projectile_sprite", 800, self)
	phoenix_pt.set_event_on_interpolation_finished(tomy_phoenix_attack_hit)


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
		phoenix_fire_bt.apply(tower, target, buff.get_level() + int(armor_loss * 100))
	else:
		phoenix_fire_bt.apply(tower, target, int(armor_loss * 100))

	buff = target.get_buff_of_type(phoenix_fire_bt)
	if buff != null:
		var stack_count: int = roundi(Utils.divide_safe(buff.get_level(), armor_loss * 100))
		buff.set_displayed_stacks(stack_count)
