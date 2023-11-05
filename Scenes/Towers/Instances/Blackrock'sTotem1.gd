extends Tower


var poussix_blackrock_physique_bt: BuffType
var poussix_blackrock_damage_bt: BuffType
var poussix_blackrock_spell_bt: BuffType


func get_ability_description() -> String:
	var text: String = ""

	text += "[color=GOLD]Shamanic Totem[/color]\n"
	text += "Upon casting Demonic Fire there is a 30% chance to buff towers in 500 range, increasing their spell damage dealt by 10% for 5 seconds and restoring 7.5% of their max mana.\n"
	text += " \n"
	text += "[color=ORANGE]Level Bonus:[/color]\n"
	text += "+0.4% spell damage\n"
	text += "+0.3% max mana\n"
	text += "+0.2 seconds duration\n"
	text += "+0.4% trigger chance\n"
	text += " \n"

	text += "[color=GOLD]Fighter Totem[/color]\n"
	text += "On attack there is a 15% chance to buff towers in 500 range, increasing their damage dealt by 10%, their crit chance by 5% and their crit damage by 50% for 5 seconds.\n"
	text += " \n"
	text += "[color=ORANGE]Level Bonus:[/color]\n"
	text += "+0.4% damage\n"
	text += "+0.2% crit chance\n"
	text += "+2% crit damage\n"
	text += "+0.2 seconds duration\n"
	text += "+0.2% trigger chance\n"

	return text


func get_ability_description_short() -> String:
	var text: String = ""

	text += "[color=GOLD]Shamanic Totem[/color]\n"
	text += "Upon casting Demonic Fire there is a chance to buff towers in range, increasing their spell damage dealt and restoring some of their mana.\n"
	text += " \n"

	text += "[color=GOLD]Fighter Totem[/color]\n"
	text += "On attack there is a chance to buff towers in range, increasing their damage dealt, crit chance and crit damage.\n"

	return text


func get_autocast_description() -> String:
	var text: String = ""

	text += "Places a buff on a creep for 7 seconds. When a tower damages the buffed creep, there is a 20% chance to permanently increase the damage it takes from fire towers by 3% (1% for bosses).\n"
	text += " \n"
	text += "[color=ORANGE]Level Bonus:[/color]\n"
	text += "+0.08% damage from fire (on non boss)\n"
	text += "+0.04% damage from fire (on bosses)\n"

	return text


func get_autocast_description_short() -> String:
	return "Places a buff on a creep. When a tower damages the buffed creep, there is a chance to permanently increase the damage it takes from fire towers.\n"


func load_triggers(triggers: BuffType):
	triggers.add_event_on_attack(on_attack)


func tower_init():
	poussix_blackrock_physique_bt = BuffType.new("poussix_blackrock_physique_bt", 5, 0.2, true, self)
	var poussix_blackrock_physique_mod: Modifier = Modifier.new()
	poussix_blackrock_physique_mod.add_modification(Modification.Type.MOD_DAMAGE_ADD_PERC, 0.10, 0.004)
	poussix_blackrock_physique_mod.add_modification(Modification.Type.MOD_ATK_CRIT_CHANCE, 0.05, 0.002)
	poussix_blackrock_physique_mod.add_modification(Modification.Type.MOD_ATK_CRIT_DAMAGE, 0.50, 0.020)
	poussix_blackrock_physique_bt.set_buff_modifier(poussix_blackrock_physique_mod)
	poussix_blackrock_physique_bt.set_buff_icon("@@0@@")
	poussix_blackrock_physique_bt.set_buff_tooltip("Fighter Totem\nThis tower is empowered by a nearby totem; it deals extra damage, has increased crit chance and crit damage.")

	poussix_blackrock_spell_bt = BuffType.new("poussix_blackrock_spell_bt", 5, 0.2, true, self)
	var poussix_blackrock_spell_mod: Modifier = Modifier.new()
	poussix_blackrock_spell_mod.add_modification(Modification.Type.MOD_SPELL_DAMAGE_DEALT, 0.10, 0.004)
	poussix_blackrock_spell_bt.set_buff_modifier(poussix_blackrock_spell_mod)
	poussix_blackrock_spell_bt.set_buff_icon("@@2@@")
	poussix_blackrock_spell_bt.set_buff_tooltip("Shamanic Totem\nThis tower is empowered by a nearby totem; it deals extra spell damage.")

	poussix_blackrock_damage_bt = BuffType.new("poussix_blackrock_damage_bt", 5, 0.2, true, self)
	poussix_blackrock_damage_bt.set_buff_icon("@@1@@")
	poussix_blackrock_damage_bt.set_buff_tooltip("Demonic Fire\nThis creep is affected by Demonic Fire; it has a chance to become permanently weaker to fire towers.")
	poussix_blackrock_damage_bt.add_event_on_damage(poussix_blackrock_damage_bt_on_damaged)

	var autocast: Autocast = Autocast.make()
	autocast.title = "Demonic Fire"
	autocast.description = get_autocast_description()
	autocast.description_short = get_autocast_description_short()
	autocast.icon = "res://path/to/icon.png"
	autocast.caster_art = ""
	autocast.target_art = ""
	autocast.autocast_type = Autocast.Type.AC_TYPE_OFFENSIVE_BUFF
	autocast.num_buffs_before_idle = 3
	autocast.cast_range = 1200
	autocast.auto_range = 1200
	autocast.cooldown = 4
	autocast.mana_cost = 0
	autocast.target_self = false
	autocast.is_extended = false
	autocast.buff_type = poussix_blackrock_damage_bt
	autocast.target_type = TargetType.new(TargetType.CREEPS)
	autocast.handler = on_autocast
	add_autocast(autocast)


func on_attack(_event: Event):
	var tower: Tower = self
	var level: int = tower.get_level()
	var chance: float = 0.15 + 0.002 * level

	if !tower.calc_chance(chance):
		return

	var it: Iterate = Iterate.over_units_in_range_of_caster(tower, TargetType.new(TargetType.TOWERS), 500)

	while true:
		var other_tower: Tower = it.next()

		if other_tower == null:
			break

		poussix_blackrock_physique_bt.apply(tower, other_tower, level)


func on_autocast(event: Event):
	var tower: Tower = self
	var level: int = tower.get_level()
	var target: Creep = event.get_target()
	var target_is_boss: bool = target.get_size() >= CreepSize.enm.BOSS
	var shamanic_totem_chance: float = 0.30 + 0.004 * level
	var restore_mana_ratio: float = 0.075 + 0.003 * level

	var mod_dmg_from_fire_value: float
	if target_is_boss:
		mod_dmg_from_fire_value = 0.01 + 0.0004 * level
	else:
		mod_dmg_from_fire_value = 0.03 + 0.0008 * level

	var buff: Buff = poussix_blackrock_damage_bt.apply(tower, target, level)
	buff.user_real = mod_dmg_from_fire_value

	if !tower.calc_chance(shamanic_totem_chance):
		return

	var it: Iterate = Iterate.over_units_in_range_of_caster(tower, TargetType.new(TargetType.TOWERS), 500)

	while true:
		var other_tower: Tower = it.next()

		if other_tower == null:
			break

		poussix_blackrock_spell_bt.apply(tower, other_tower, level)

		if other_tower != tower:
			other_tower.add_mana_perc(restore_mana_ratio)


func poussix_blackrock_damage_bt_on_damaged(event: Event):
	var buff: Buff = event.get_buff()
	var creep: Creep = buff.get_buffed_unit()
	var mod_value: float = buff.user_real

	if creep.calc_chance(0.2):
		creep.modify_property(Modification.Type.MOD_DMG_FROM_FIRE, mod_value)
