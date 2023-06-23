extends Tower


var cedi_love_potion: BuffType
var cedi_soul_buff: BuffType
var cedi_love_missile: ProjectileType


func get_tier_stats() -> Dictionary:
	return {
		1: {item_chance = 200, soul_chance = 30, soul_damage = 50, soul_damage_add = 2, soul_duration = 10, soul_chance_decrease = 10, mod_attackspeed = 0.10},
		2: {item_chance = 256, soul_chance = 36, soul_damage = 400, soul_damage_add = 16, soul_duration = 12, soul_chance_decrease = 9, mod_attackspeed = 0.15},
		3: {item_chance = 288, soul_chance = 39, soul_damage = 800, soul_damage_add = 32, soul_duration = 13, soul_chance_decrease = 8.5, mod_attackspeed = 0.20},
		4: {item_chance = 336, soul_chance = 42, soul_damage = 2000, soul_damage_add = 80, soul_duration = 15, soul_chance_decrease = 8, mod_attackspeed = 0.25},
	}


func get_extra_tooltip_text() -> String:
	var potion_slow: String = Utils.format_percent(_stats.item_chance * 0.00125, 0)
	var potion_item_chance: String = Utils.format_percent(_stats.item_chance * 0.001, 0)
	var soul_chance: String = Utils.format_percent(_stats.soul_chance * 0.001, 0)
	var soul_damage: String = Utils.format_float(_stats.soul_damage, 0)
	var soul_damage_add: String = Utils.format_float(_stats.soul_damage_add, 0)
	var mod_attackspeed: String = Utils.format_percent(_stats.mod_attackspeed, 0)
	var soul_chance_decrease: String = Utils.format_percent(_stats.soul_chance_decrease * 0.001, 0)

	var text: String = ""

	text += "[color=GOLD]Love Potion[/color]\n"
	text += "The witch throws a bottle of love potion on the target, slowing it by %s and increasing its item drop chance by %s. The potion lasts 7 seconds.\n" % [potion_slow, potion_item_chance]
	text += " \n"
	text += "[color=ORANGE]Level Bonus:[/color]\n"
	text += "+0.375% slow\n"
	text += "+0.3% Item drop chance\n"
	text += " \n"
	text += "Mana cost: 25, 1100 range, 3s cooldown\n"
	text += " \n"
	text += "[color=GOLD]Soul Split[/color]\n"
	text += "When the witch attacks, it has a %s chance to deal %s spell damage to its target, increasing the witch's attackspeed by %s and decreasing the chance to trigger this spell by %s. These effects last 10 seconds and stack. If the target is under the influence of a Love Potion, the attackspeed bonus, the damage and the duration of this spell are doubled.\n" % [soul_chance, soul_damage, mod_attackspeed, soul_chance_decrease]
	text += " \n"
	text += "[color=ORANGE]Level Bonus:[/color]\n"
	text += "+%s spell damage\n" % soul_damage_add

	return text


func load_triggers(triggers: BuffType):
	triggers.add_event_on_damage(on_damage)


func load_specials(modifier: Modifier):
	modifier.add_modification(Modification.Type.MOD_MANA, 0.0, 1)
	modifier.add_modification(Modification.Type.MOD_MANA_REGEN, 0.0, 0.1)


func on_autocast(event: Event):
	var tower: Tower = self
	var projectile: Projectile = Projectile.create_from_unit_to_unit(cedi_love_missile, tower, 1.00, tower.calc_spell_crit_no_bonus(), tower, event.get_target(), true, false, false)
	projectile.user_int = _stats.item_chance + tower.get_level() * 3


func cedi_love(p: Projectile, target: Unit):
	var tower: Unit = p.get_caster()
	cedi_love_potion.apply(tower, target, p.user_int)

func tower_init():
	var mod: Modifier = Modifier.new()
	
	cedi_love_potion = BuffType.new("cedi_love_potion", 7, 0, false, self)
	mod.add_modification(Modification.Type.MOD_ITEM_CHANCE_ON_DEATH, 0.0, 0.001)
	mod.add_modification(Modification.Type.MOD_MOVESPEED, 0.0, -0.00125)
	cedi_love_potion.set_buff_modifier(mod)
	cedi_love_potion.set_buff_icon("@@0@@")
	cedi_love_potion.set_buff_tooltip("In Love\nThis unit's movement speed is slowed and item drop chance is increased.")

	cedi_soul_buff = BuffType.new("cedi_soul_buff", 10, 0, true, self)
	cedi_soul_buff.set_buff_icon("@@1@@")

	cedi_love_missile = ProjectileType.create("BottleMissile.mdl", 999.99, 1100)
	cedi_love_missile.enable_homing(cedi_love, 0.0)

	var autocast: Autocast = Autocast.make()
	autocast.caster_art = ""
	autocast.num_buffs_before_idle = 1
	autocast.autocast_type = Autocast.Type.AC_TYPE_OFFENSIVE_UNIT
	autocast.cast_range = 1100
	autocast.target_self = false
	autocast.target_art = ""
	autocast.cooldown = 3
	autocast.is_extended = false
	autocast.mana_cost = 25
	autocast.buff_type = cedi_love_potion
	autocast.target_type = TargetType.new(TargetType.CREEPS)
	autocast.auto_range = 1100
	autocast.handler = on_autocast
	add_autocast(autocast)


func on_damage(event: Event):
	var tower: Tower = self
	var multiplier: float = 1.00
	var UID: int = tower.get_instance_id()

	if tower.calc_chance(tower.user_real / 100.0):
		if event.get_target().get_buff_of_type(cedi_love_potion) != null:
			multiplier = 2.0
			tower.getOwner().display_floating_text_x("Double", tower, 255, 0, 0, 255, 64, 1, 2)

		SFX.sfx_at_unit("UndeadDissipate.mdl", tower)
		tower.do_spell_damage(event.get_target(), (_stats.soul_damage + _stats.soul_damage_add * tower.get_level()) * multiplier, tower.calc_spell_crit_no_bonus())
		cedi_soul_buff.apply_custom_timed(tower, tower, 1, _stats.soul_duration * multiplier)
		tower.user_real = tower.user_real - _stats.soul_chance_decrease
		tower.modify_property(Modification.Type.MOD_ATTACKSPEED, _stats.mod_attackspeed * multiplier)

		await get_tree().create_timer(10.0 * multiplier).timeout

		if is_instance_valid(tower) && tower.get_instance_id() == UID:
			tower.modify_property(Modification.Type.MOD_ATTACKSPEED, -_stats.mod_attackspeed * multiplier)
			tower.user_real = tower.user_real + 10


func on_create(_preceding_tower: Tower):
	var tower: Tower = self
	tower.user_real = _stats.soul_chance
