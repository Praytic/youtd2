extends TowerBehavior


var love_bt: BuffType
var soul_split_bt: BuffType
var missile_pt: ProjectileType
var current_soul_split_stacks: int = 0


const POTION_DURATION: float = 7.0
const MOD_MOVESPEED_ADD: float = 0.00375
const MOD_ITEM_CHANCE_ADD: float = 0.003


func get_tier_stats() -> Dictionary:
	return {
		1: {mod_movespeed = 0.25, mod_item_chance = 0.200, soul_chance = 30, soul_damage = 50, soul_damage_add = 2, soul_duration = 10, soul_chance_decrease = 10, mod_attack_speed = 0.10},
		2: {mod_movespeed = 0.32, mod_item_chance = 0.256, soul_chance = 36, soul_damage = 400, soul_damage_add = 16, soul_duration = 12, soul_chance_decrease = 9, mod_attack_speed = 0.15},
		3: {mod_movespeed = 0.36, mod_item_chance = 0.288, soul_chance = 39, soul_damage = 800, soul_damage_add = 32, soul_duration = 13, soul_chance_decrease = 8.5, mod_attack_speed = 0.20},
		4: {mod_movespeed = 0.42, mod_item_chance = 0.336, soul_chance = 42, soul_damage = 2000, soul_damage_add = 80, soul_duration = 15, soul_chance_decrease = 8, mod_attack_speed = 0.25},
	}



func load_triggers(triggers: BuffType):
	triggers.add_event_on_damage(on_damage)


func on_autocast(event: Event):
	var target: Unit = event.get_target()

	Projectile.create_from_unit_to_unit(missile_pt, tower, 1.00, 1.0, tower, target, true, false, false)


# NOTE: cedi_Love() in original script
func missile_pt_on_hit(_p: Projectile, target: Unit):
	if target == null:
		return

	var level: int = tower.get_level()

	love_bt.apply(tower, target, level)


func tower_init():
	love_bt = BuffType.new("love_bt", POTION_DURATION, 0, false, self)
	var mod: Modifier = Modifier.new()
	mod.add_modification(ModificationType.enm.MOD_ITEM_CHANCE_ON_DEATH, _stats.mod_item_chance, MOD_ITEM_CHANCE_ADD)
	mod.add_modification(ModificationType.enm.MOD_MOVESPEED, -_stats.mod_movespeed, -MOD_MOVESPEED_ADD)
	love_bt.set_buff_modifier(mod)
	love_bt.set_buff_icon("res://resources/icons/generic_icons/charm.tres")
	love_bt.set_buff_tooltip(tr("W4SL"))

#	NOTE: this buff is needed to display the effect of the
#	"Soul Split" ability. The actual effect of the ability
#	is implemented via modify_property().
	soul_split_bt = BuffType.new("soul_split_bt", 10, 0, true, self)
	soul_split_bt.set_buff_icon("res://resources/icons/generic_icons/rss.tres")
	soul_split_bt.set_buff_tooltip(tr("BNH6"))

	missile_pt = ProjectileType.create("path_to_projectile_sprite", 999.99, 1100, self)
	missile_pt.enable_homing(missile_pt_on_hit, 0.0)


func on_damage(event: Event):
	var multiplier: float = 1.00

	if tower.calc_chance(tower.user_real / 100.0):
		if event.get_target().get_buff_of_type(love_bt) != null:
			CombatLog.log_ability(tower, event.get_target(), "Soul Split x2")
			
			multiplier = 2.0
			tower.get_player().display_floating_text_x("Double", tower, Color8(255, 0, 0, 255), 64, 1, 2)
		else:
			CombatLog.log_ability(tower, event.get_target(), "Soul Split")

		Effect.create_simple_at_unit("res://src/effects/undead_dissipate.tscn", tower)
		tower.do_spell_damage(event.get_target(), (_stats.soul_damage + _stats.soul_damage_add * tower.get_level()) * multiplier, tower.calc_spell_crit_no_bonus())
		var soul_split_buff: Buff = soul_split_bt.apply_custom_timed(tower, tower, 1, _stats.soul_duration * multiplier)
		tower.user_real = tower.user_real - _stats.soul_chance_decrease
		tower.modify_property(ModificationType.enm.MOD_ATTACKSPEED, _stats.mod_attack_speed * multiplier)
		current_soul_split_stacks += 1

		soul_split_buff.set_displayed_stacks(current_soul_split_stacks)

		await Utils.create_manual_timer(10.0 * multiplier, self).timeout

		if Utils.unit_is_valid(tower):
			tower.modify_property(ModificationType.enm.MOD_ATTACKSPEED, -_stats.mod_attack_speed * multiplier)
			tower.user_real = tower.user_real + _stats.soul_chance_decrease
			current_soul_split_stacks -= 1

			soul_split_buff = tower.get_buff_of_type(soul_split_bt)
			if soul_split_buff != null:
				soul_split_buff.set_displayed_stacks(current_soul_split_stacks)


func on_create(_preceding_tower: Tower):
	tower.user_real = _stats.soul_chance
