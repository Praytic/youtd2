extends Tower


# NOTE: the way this tower works is that the player cycles
# through modifications and then applies/removes current
# modification from the missiles. Missiles can have a
# combination of multiple modifications, not just the
# currently selected one! The amount of applied
# modifications is limited by missile damage - it cannot go
# below 0.

# NOTE: changed cd of autocasts to 0.25s because 0s cooldown
# is not supported by youtd2 engine.


enum MissileMod {
	SLOW,
	SILENCE,
	REGEN,
	ARMOR,
	SPELL,
	AOE,

	COUNT,
}


class Data:
	var slow: int = 0 # +0.05 slow%
	var silence: int = 0 # +5.0s duration
	var regen: int = 0 # +0.05 regen%
	var armor: int = 0 # +1 armor%
	var spell: int = 0 # +0.06 vuln%
	var aoe: int = 150 # No percentage, integer value! Equals to radius of aoe
	var dmg: int = 100 # damage dealt by missile


const missile_mod_to_string: Dictionary = {
	MissileMod.SLOW: "Slow",
	MissileMod.SILENCE: "Silence",
	MissileMod.REGEN: "Health Regen",
	MissileMod.ARMOR: "Armor",
	MissileMod.SPELL: "Spell Vuln",
	MissileMod.AOE: "AoE",
}

var cb_silence: BuffType
var cedi_sorc_slow_bt: BuffType
var cedi_sorc_armor_bt: BuffType
var cedi_sorc_spell_bt: BuffType
var cedi_sorc_hpregen_bt: BuffType
var missile_pt: ProjectileType
var multiboard: MultiboardValues
var data: Data
var current_missile_mod: MissileMod


func get_ability_description() -> String:
	var text: String = ""

	text += "[color=GOLD]Magic Missile[/color]\n"
	text += "Whenever this tower attacks it launches a magic missile in the target's direction. The missile hits all units in 150 AoE and deals 100% of the tower's attack damage as spell damage to the hit units. The missile travels 1200 units.\n"
	text += " \n"
	text += "[color=ORANGE]Level Bonus:[/color]\n"
	text += "+2% spell damage\n"

	return text


func get_ability_description_short() -> String:
	var text: String = ""

	text += "[color=GOLD]Magic Missile[/color]\n"
	text += "Whenever this tower attacks it launches a magic missile in the target's direction.\n"

	return text


func get_autocast_choose_description() -> String:
	var text: String = ""

	text += "Cycle through the modifications:\n"
	text += "Slow: 8% for 5 seconds, -20% dmg\n"
	text += "Silence: 5 seconds, 50% chance, -40% dmg\n"
	text += "Health Regeneration: -10% for 5 seconds, -25% dmg\n"
	text += "Armor: -6% for 5 seconds, -25% dmg\n"
	text += "Spell Vulnerability: 12% for 5 seconds, -25% dmg\n"
	text += "AoE: 50, -15% dmg\n"

	return text


func get_autocast_choose_description_short() -> String:
	var text: String = ""

	text += "Cycle through the modifications.\n"

	return text


func get_autocast_add_description() -> String:
	var text: String = ""

	text += "Adds the bonus to the missile if the tower has enough damage left.\n"

	return text


func get_autocast_add_description_short() -> String:
	var text: String = ""

	text += "Adds the bonus to the missile if the tower has enough damage left.\n"

	return text


func get_autocast_remove_description() -> String:
	var text: String = ""

	text += "Removes the bonus to the missile and returns the damage used.\n"

	return text


func get_autocast_remove_description_short() -> String:
	var text: String = ""

	text += "Removes the bonus to the missile and returns the damage used.\n"

	return text


func load_triggers(triggers: BuffType):
	triggers.add_event_on_attack(on_attack)
	triggers.add_event_on_damage(on_damage)
	triggers.add_event_on_level_up(on_level_up)


func tower_init():
	cb_silence = CbSilence.new("sorceress_silence", 0, 0, false, self)

	missile_pt = ProjectileType.create_ranged("FaerieDragonMissile.mdl", 1200, 1200, self)
	missile_pt.enable_collision(missile_pt_on_collision, 150, TargetType.new(TargetType.CREEPS), false)

	cedi_sorc_slow_bt = BuffType.new("cedi_sorc_slow_bt", 5, 0, false, self)
	var cedi_sorc_slow_bt_mod: Modifier = Modifier.new()
	cedi_sorc_slow_bt_mod.add_modification(Modification.Type.MOD_MOVESPEED, 0.0, -0.01)
	cedi_sorc_slow_bt.set_buff_modifier(cedi_sorc_slow_bt_mod)
	cedi_sorc_slow_bt.set_buff_icon("@@0@@")
	cedi_sorc_slow_bt.set_buff_tooltip("Magic Missile Slow\nThis unit has reduced movement speed.")

	cedi_sorc_armor_bt = BuffType.new("cedi_sorc_armor_bt", 5, 0, false, self)
	var cedi_sorc_armor_bt_mod: Modifier = Modifier.new()
	cedi_sorc_armor_bt_mod.add_modification(Modification.Type.MOD_ARMOR_PERC, 0.0, -0.01)
	cedi_sorc_armor_bt.set_buff_modifier(cedi_sorc_armor_bt_mod)
	cedi_sorc_armor_bt.set_buff_icon("@@1@@")
	cedi_sorc_armor_bt.set_buff_tooltip("Magic Missile Sunder\nThis unit has reduced armor.")

	cedi_sorc_spell_bt = BuffType.new("cedi_sorc_spell_bt", 5, 0, false, self)
	var cedi_sorc_spell_bt_mod: Modifier = Modifier.new()
	cedi_sorc_spell_bt_mod.add_modification(Modification.Type.MOD_SPELL_DAMAGE_RECEIVED, 0.0, 0.01)
	cedi_sorc_spell_bt.set_buff_modifier(cedi_sorc_spell_bt_mod)
	cedi_sorc_spell_bt.set_buff_icon("@@2@@")
	cedi_sorc_spell_bt.set_buff_tooltip("Magic Missile Vulnerability\nThis unit has increased spell vulnerability.")

	cedi_sorc_hpregen_bt = BuffType.new("cedi_sorc_hpregen_bt", 5, 0, false, self)
	var cedi_sorc_hpregen_bt_mod: Modifier = Modifier.new()
	cedi_sorc_hpregen_bt_mod.add_modification(Modification.Type.MOD_HP_REGEN_PERC, 0.0, -0.01)
	cedi_sorc_hpregen_bt.set_buff_modifier(cedi_sorc_hpregen_bt_mod)
	cedi_sorc_hpregen_bt.set_buff_icon("@@3@@")
	cedi_sorc_hpregen_bt.set_buff_tooltip("Magic Missile Cripple\nThis unit has reduced health regeneration.")

	multiboard = MultiboardValues.new(8)
	multiboard.set_key(0, "Damage %")
	multiboard.set_key(1, "Mod")
	multiboard.set_key(2, "Slow")
	multiboard.set_key(3, "Silence")
	multiboard.set_key(4, "Health Regen")
	multiboard.set_key(5, "Armor")
	multiboard.set_key(6, "Spell Vuln")
	multiboard.set_key(7, "AoE")

	var autocast_choose: Autocast = Autocast.make()
	autocast_choose.title = "Choose Modification"
	autocast_choose.description = get_autocast_choose_description()
	autocast_choose.description_short = get_autocast_choose_description_short()
	autocast_choose.icon = "res://path/to/icon.png"
	autocast_choose.caster_art = ""
	autocast_choose.target_art = ""
	autocast_choose.autocast_type = Autocast.Type.AC_TYPE_NOAC_IMMEDIATE
	autocast_choose.num_buffs_before_idle = 0
	autocast_choose.cast_range = 0
	autocast_choose.auto_range = 0
	autocast_choose.cooldown = 0.25
	autocast_choose.mana_cost = 0
	autocast_choose.target_self = true
	autocast_choose.is_extended = false
	autocast_choose.buff_type = null
	autocast_choose.target_type = TargetType.new(TargetType.TOWERS)
	autocast_choose.handler = on_autocast_choose
	add_autocast(autocast_choose)

	var autocast_add: Autocast = Autocast.make()
	autocast_add.title = "Add Modification"
	autocast_add.description = get_autocast_add_description()
	autocast_add.description_short = get_autocast_add_description_short()
	autocast_add.icon = "res://path/to/icon.png"
	autocast_add.caster_art = ""
	autocast_add.target_art = ""
	autocast_add.autocast_type = Autocast.Type.AC_TYPE_NOAC_IMMEDIATE
	autocast_add.num_buffs_before_idle = 0
	autocast_add.cast_range = 0
	autocast_add.auto_range = 0
	autocast_add.cooldown = 0.25
	autocast_add.mana_cost = 0
	autocast_add.target_self = 0
	autocast_add.is_extended = false
	autocast_add.buff_type = null
	autocast_add.target_type = TargetType.new(TargetType.TOWERS)
	autocast_add.handler = on_autocast_add
	add_autocast(autocast_add)

	var autocast_remove: Autocast = Autocast.make()
	autocast_remove.title = "Remove Modification"
	autocast_remove.description = get_autocast_remove_description()
	autocast_remove.description_short = get_autocast_remove_description_short()
	autocast_remove.icon = "res://path/to/icon.png"
	autocast_remove.caster_art = ""
	autocast_remove.target_art = ""
	autocast_remove.autocast_type = Autocast.Type.AC_TYPE_NOAC_IMMEDIATE
	autocast_remove.num_buffs_before_idle = 0
	autocast_remove.cast_range = 0
	autocast_remove.auto_range = 0
	autocast_remove.cooldown = 0.25
	autocast_remove.mana_cost = 0
	autocast_remove.target_self = 0
	autocast_remove.is_extended = false
	autocast_remove.buff_type = null
	autocast_remove.target_type = TargetType.new(TargetType.TOWERS)
	autocast_remove.handler = on_autocast_remove
	add_autocast(autocast_remove)


func on_attack(event: Event):
	var tower: Tower = self
	var target: Unit = event.get_target()
	var p: Projectile = Projectile.create_from_unit_to_unit(missile_pt, tower, 1.0, 1.0, tower, target, false, true, false)
	p.set_collision_parameters(data.aoe, TargetType.new(TargetType.CREEPS))
	p.set_z(60)


func on_damage(event: Event):
	event.damage = 0


func on_level_up(event: Event):
	var dmg_change: int
	if event.is_level_up():
		dmg_change = 2
	else:
		dmg_change = -2

	data.dmg += dmg_change


func on_create(_preceding_tower: Tower):
	var tower: Tower = self
	data = Data.new()
	data.dmg += 2 * tower.get_level()
	current_missile_mod = MissileMod.SLOW


func on_autocast_choose(_event: Event):
	var tower: Tower = self

	current_missile_mod = (current_missile_mod + 1) as MissileMod
	if current_missile_mod >= MissileMod.COUNT:
		current_missile_mod = 0 as MissileMod

	var floating_text: String = missile_mod_to_string[current_missile_mod]
	tower.get_player().display_small_floating_text(floating_text, tower, Color8(255, 255, 255), 40)


func on_autocast_add(_event: Event):
	var tower: Tower = self
	var dmg_before: int = data.dmg
	
	match current_missile_mod:
		MissileMod.SLOW:
			if data.dmg >= 20:
				data.slow += 8
				data.dmg -= 20
		MissileMod.SILENCE: 
			if data.dmg >= 40:
				data.silence += 5
				data.dmg -= 40
		MissileMod.REGEN: 
			if data.dmg >= 25:
				data.regen += 10
				data.dmg -= 25
		MissileMod.ARMOR:
			if data.dmg >= 25:
				data.armor += 6
				data.dmg -= 25
		MissileMod.SPELL:
			if data.dmg >= 25:
				data.spell += 12
				data.dmg -= 25
		MissileMod.AOE:
			if data.dmg >= 15:
				data.aoe += 50
				data.dmg -= 15

	var dmg_after: int = data.dmg
	var dmg_changed: bool = dmg_before != dmg_after

	if !dmg_changed:
		tower.get_player().display_small_floating_text("Can't increase modification any further!", tower, Color8(255, 0, 0), 40)


func on_autocast_remove(_event: Event):
	var dmg_before: int = data.dmg
	var tower: Tower = self

	match current_missile_mod:
		MissileMod.SLOW:
			if data.slow >= 8:
				data.slow -= 8
				data.dmg += 20
		MissileMod.SILENCE: 
			if data.silence >= 5:
				data.silence -= 5
				data.dmg += 40
		MissileMod.REGEN: 
			if data.regen >= 10:
				data.regen -= 10
				data.dmg += 25
		MissileMod.ARMOR:
			if data.armor >= 6:
				data.armor -= 6
				data.dmg += 25
		MissileMod.SPELL:
			if data.spell >= 12:
				data.spell -= 12
				data.dmg += 25
		MissileMod.AOE:
			if data.aoe > 150:
				data.aoe -= 50
				data.dmg += 15

	var dmg_after: int = data.dmg
	var dmg_changed: bool = dmg_before != dmg_after

	if !dmg_changed:
		tower.get_player().display_small_floating_text("Can't decrease modification any further!", tower, Color8(255, 0, 0), 40)


# NOTE: original script does a weird thing with multiple
# calls to displayTimedText(). Seems like in original
# engine, the "onTowerDetails()" callback is called once
# when tower details menu is opened. So what happened was
# player opened details and then some extra text was printed
# to the screen.
# 
# In youtd2 engine onTowerDetails() is called repeatedly to
# keep TowerInfo up to date.
# 
# So I changed the script to display these stats in details.
func on_tower_details() -> MultiboardValues:
	var damage_string: String = Utils.format_percent(data.dmg / 100.0, 0)
	var modification_string: String = missile_mod_to_string[current_missile_mod]
	var slow_string: String = Utils.format_percent(data.slow / 100.0, 0)
	var silence_string: String = Utils.format_float(data.silence, 0) + " seconds"
	var regen_string: String = Utils.format_percent(data.regen / 100.0, 0)
	var armor_string: String = Utils.format_percent(data.armor / 100.0, 0)
	var spell_string: String = Utils.format_percent(data.spell / 100.0, 0)
	var aoe_string: String = Utils.format_float(data.aoe, 0)

	multiboard.set_value(0, damage_string)
	multiboard.set_value(1, modification_string)
	multiboard.set_value(2, slow_string)
	multiboard.set_value(3, silence_string)
	multiboard.set_value(4, regen_string)
	multiboard.set_value(5, armor_string)
	multiboard.set_value(6, spell_string)
	multiboard.set_value(7, aoe_string)
	
	return multiboard


# NOTE: "coll()" in original script
func missile_pt_on_collision(p: Projectile, target: Unit):
	var tower: Tower = p.get_caster()
	var silence_chance: float = 0.50

	if data.slow > 0:
		cedi_sorc_slow_bt.apply(tower, target, data.slow)

	if data.silence > 0:
		if tower.calc_chance(silence_chance):
			cb_silence.apply_only_timed(tower, target, data.silence)

	if data.regen > 0:
		cedi_sorc_hpregen_bt.apply(tower, target, data.regen)

	if data.armor > 0:
		cedi_sorc_armor_bt.apply(tower, target, data.armor)

	if data.spell:
		cedi_sorc_spell_bt.apply(tower, target, data.spell)

	if data.dmg > 0:
		var damage: float = tower.get_current_attack_damage_with_bonus() * data.dmg / 100.0
		tower.do_spell_damage(target, damage, tower.calc_spell_crit_no_bonus())
