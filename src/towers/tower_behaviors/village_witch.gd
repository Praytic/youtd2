extends TowerBehavior


var love_bt: BuffType
var soul_split_bt: BuffType
var missile_pt: ProjectileType
var current_soul_split_stacks: int = 0


func get_tier_stats() -> Dictionary:
	return {
		1: {item_chance = 200, soul_chance = 30, soul_damage = 50, soul_damage_add = 2, soul_duration = 10, soul_chance_decrease = 10, mod_attack_speed = 0.10},
		2: {item_chance = 256, soul_chance = 36, soul_damage = 400, soul_damage_add = 16, soul_duration = 12, soul_chance_decrease = 9, mod_attack_speed = 0.15},
		3: {item_chance = 288, soul_chance = 39, soul_damage = 800, soul_damage_add = 32, soul_duration = 13, soul_chance_decrease = 8.5, mod_attack_speed = 0.20},
		4: {item_chance = 336, soul_chance = 42, soul_damage = 2000, soul_damage_add = 80, soul_duration = 15, soul_chance_decrease = 8, mod_attack_speed = 0.25},
	}


func get_ability_info_list() -> Array[AbilityInfo]:
	var soul_chance: String = Utils.format_percent(_stats.soul_chance * 0.01, 0)
	var soul_damage: String = Utils.format_float(_stats.soul_damage, 0)
	var soul_damage_add: String = Utils.format_float(_stats.soul_damage_add, 0)
	var mod_attack_speed: String = Utils.format_percent(_stats.mod_attack_speed, 0)
	var soul_chance_decrease: String = Utils.format_percent(_stats.soul_chance_decrease * 0.01, 0)

	var list: Array[AbilityInfo] = []
	
	var ability: AbilityInfo = AbilityInfo.new()
	ability.name = "Soul Split"
	ability.icon = "res://resources/icons/undead/skull_phazing.tres"
	ability.description_short = "Whenever this tower hits a creep, it has a chance to deal extra spell damage and increase Witch's attack speed.\n"
	ability.description_full = "Whenever this tower hits a creep, it has a %s chance to deal %s spell damage to the target, increasing the Witch's attack speed by %s and decreasing the chance to trigger this spell by %s. These effects last 10 seconds and stack. If the target is under the influence of [color=GOLD]Love Potion[/color], the attack speed bonus, the damage and the duration of this spell are doubled.\n" % [soul_chance, soul_damage, mod_attack_speed, soul_chance_decrease] \
	+ " \n" \
	+ "[color=ORANGE]Level Bonus:[/color]\n" \
	+ "+%s spell damage\n" % soul_damage_add
	list.append(ability)

	return list


func load_triggers(triggers: BuffType):
	triggers.add_event_on_damage(on_damage)


func load_specials(modifier: Modifier):
	modifier.add_modification(Modification.Type.MOD_MANA, 0.0, 1)
	modifier.add_modification(Modification.Type.MOD_MANA_REGEN, 0.0, 0.1)


func on_autocast(event: Event):
	var projectile: Projectile = Projectile.create_from_unit_to_unit(missile_pt, tower, 1.00, tower.calc_spell_crit_no_bonus(), tower, event.get_target(), true, false, false)
	projectile.user_int = _stats.item_chance + tower.get_level() * 3


func cedi_love(p: Projectile, target: Unit):
	if target == null:
		return

	love_bt.apply(tower, target, p.user_int)

func tower_init():
	var mod: Modifier = Modifier.new()
	
	love_bt = BuffType.new("love_bt", 7, 0, false, self)
	mod.add_modification(Modification.Type.MOD_ITEM_CHANCE_ON_DEATH, 0.0, 0.001)
	mod.add_modification(Modification.Type.MOD_MOVESPEED, 0.0, -0.00125)
	love_bt.set_buff_modifier(mod)
	love_bt.set_buff_icon("res://resources/icons/generic_icons/charm.tres")
	love_bt.set_buff_tooltip("In Love\nReduces movement speed and increases chance of dropping items.")

#	NOTE: this buff is needed to display the effect of the
#	"Soul Split" ability. The actual effect of the ability
#	is implemented via modify_property().
	soul_split_bt = BuffType.new("soul_split_bt", 10, 0, true, self)
	soul_split_bt.set_buff_icon("res://resources/icons/generic_icons/rss.tres")
	soul_split_bt.set_buff_tooltip("Soul Split\nIncreases attack speed and reduces chance to trigger Soul Split.")

	missile_pt = ProjectileType.create("BottleMissile.mdl", 999.99, 1100, self)
	missile_pt.enable_homing(cedi_love, 0.0)


func create_autocasts() -> Array[Autocast]:
	var autocast: Autocast = Autocast.make()

	var potion_slow: String = Utils.format_percent(_stats.item_chance * 0.00125, 0)
	var potion_item_chance: String = Utils.format_percent(_stats.item_chance * 0.001, 0)
	
	autocast.title = "Love Potion"
	autocast.icon = "res://resources/icons/potions/potion_heart_02.tres"
	autocast.description_short = "The Witch throws a love potion on the target, applying a slow and increasing target's item chance.\n"
	autocast.description = "The Witch throws a love potion on the target, slowing it by %s and increasing its item chance by %s. The potion lasts 7 seconds.\n" % [potion_slow, potion_item_chance] \
	+ " \n" \
	+ "[color=ORANGE]Level Bonus:[/color]\n" \
	+ "+0.375% slow\n" \
	+ "+0.3% item drop chance\n"
	autocast.caster_art = ""
	autocast.num_buffs_before_idle = 1
	autocast.autocast_type = Autocast.Type.AC_TYPE_OFFENSIVE_UNIT
	autocast.cast_range = 1100
	autocast.target_self = false
	autocast.target_art = ""
	autocast.cooldown = 3
	autocast.is_extended = false
	autocast.mana_cost = 25
	autocast.buff_type = love_bt
	autocast.target_type = TargetType.new(TargetType.CREEPS)
	autocast.auto_range = 1100
	autocast.handler = on_autocast

	return [autocast]


func on_damage(event: Event):
	var multiplier: float = 1.00

	if tower.calc_chance(tower.user_real / 100.0):
		if event.get_target().get_buff_of_type(love_bt) != null:
			CombatLog.log_ability(tower, event.get_target(), "Soul Split x2")
			
			multiplier = 2.0
			tower.get_player().display_floating_text_x("Double", tower, Color8(255, 0, 0, 255), 64, 1, 2)
		else:
			CombatLog.log_ability(tower, event.get_target(), "Soul Split")

		SFX.sfx_at_unit("UndeadDissipate.mdl", tower)
		tower.do_spell_damage(event.get_target(), (_stats.soul_damage + _stats.soul_damage_add * tower.get_level()) * multiplier, tower.calc_spell_crit_no_bonus())
		var soul_split_buff: Buff = soul_split_bt.apply_custom_timed(tower, tower, 1, _stats.soul_duration * multiplier)
		tower.user_real = tower.user_real - _stats.soul_chance_decrease
		tower.modify_property(Modification.Type.MOD_ATTACKSPEED, _stats.mod_attack_speed * multiplier)
		current_soul_split_stacks += 1

		soul_split_buff.set_displayed_stacks(current_soul_split_stacks)

		await Utils.create_timer(10.0 * multiplier, self).timeout

		if Utils.unit_is_valid(tower):
			tower.modify_property(Modification.Type.MOD_ATTACKSPEED, -_stats.mod_attack_speed * multiplier)
			tower.user_real = tower.user_real + _stats.soul_chance_decrease
			current_soul_split_stacks -= 1

			soul_split_buff = tower.get_buff_of_type(soul_split_bt)
			if soul_split_buff != null:
				soul_split_buff.set_displayed_stacks(current_soul_split_stacks)


func on_create(_preceding_tower: Tower):
	tower.user_real = _stats.soul_chance
