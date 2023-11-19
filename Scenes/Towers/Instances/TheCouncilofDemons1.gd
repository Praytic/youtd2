extends Tower


# NOTE: original script has a bug where the projectile
# created by aura deals 2 damage because do_spell_damage()
# is called on tower instead of projectile. It was intended
# that projectile stores damage ratio and then deals damage
# using that ratio. Fixed bug by not using damage ratio (not
# needed really) and storing damage in user_real of
# projectile.


var dave_council_aura_bt: BuffType
var dave_council_mana_bt: BuffType
var dave_council_maledict_bt: BuffType
var dave_council_darkness_bt: BuffType
var dave_council_pt: ProjectileType


func get_ability_description() -> String:
	var text: String = ""

	text += "[color=GOLD]Maledict[/color]\n"
	text += "Whenever this tower damages a unit, it has a 20% chance to increase the damage that unit receives from spells by 20% for 5 seconds. Every time the buffed unit is targeted by a spell this tower deals additional spell damage equal to 3 times the caster goldcost to it.\n"
	text += " \n"
	text += "[color=ORANGE]Level Bonus:[/color]\n"
	text += "+0.4% chance\n"
	text += "+0.6% spell damage received\n"
	text += " \n"

	text += "[color=GOLD]Demonic Edict - Aura[/color]\n"
	text += "Whenever a tower in 400 range casts a spell on a creep, this tower fires a projectile from the casting unit to its current target, dealing [2 x caster goldcost x spell cd] spell damage. The casting tower also has its mana regeneration increased by 100% for 3 seconds.\n"
	text += " \n"
	text += "[color=ORANGE]Level Bonus:[/color]\n"
	text += "+2% mana regeneration\n"

	return text


func get_ability_description_short() -> String:
	var text: String = ""
	
	text += "[color=GOLD]Maledict[/color]\n"
	text += "Chance to increase spell vulnerability of damaged units.\n"
	text += " \n"

	text += "[color=GOLD]Demonic Edict - Aura[/color]\n"
	text += "Whenever a tower in range casts a spell on a creep, this tower fires an extra projectile and increases mana regeneration of casting tower.\n"

	return text


func get_autocast_description() -> String:
	var text: String = ""

	text += "Shrouds an enemy in darkness, slowing it by 40% for 5 seconds and reducing the damage it takes from attacks by 95%. The affected unit takes 1000 spell damage per second and additional spell damage equal to 75% of the damage it received during the effect when the buff expires. This damage can't be a critical hit.\n"
	text += " \n"
	text += "[color=ORANGE]Level Bonus:[/color]\n"
	text += "+40 damage per second\n"
	text += "+1% damage on expire \n"
	text += "+0.8% slow\n"

	return text


func get_autocast_description_short() -> String:
	return "Shrouds an enemy in darkness, slowing it and converting attack damage it takes into spell damage.\n"


func load_triggers(triggers: BuffType):
	triggers.add_event_on_damage(on_damage)


func tower_init():
	dave_council_darkness_bt = BuffType.new("dave_council_darkness_bt", 5, 0, false, self)
	var dave_council_darkness_mod: Modifier = Modifier.new()
	dave_council_darkness_mod.add_modification(Modification.Type.MOD_MOVESPEED, -0.4, -0.006)
	dave_council_darkness_mod.add_modification(Modification.Type.MOD_ATK_DAMAGE_RECEIVED, -0.95, 0.0)
	dave_council_darkness_bt.set_buff_modifier(dave_council_darkness_mod)
	dave_council_darkness_bt.set_buff_icon("@@0@@")
	dave_council_darkness_bt.add_periodic_event(dave_council_darkness_periodic, 1.0)
	dave_council_darkness_bt.add_event_on_damaged(dave_council_darkness_on_damaged)
	dave_council_darkness_bt.add_event_on_expire(dave_council_darkness_on_expire)
	dave_council_darkness_bt.set_buff_tooltip("Impenetrable Darkness\nThis unit is affected by Impenetrable Darkness; it will receive extra spell damage but less attack damage and it will also take extra damage when the debuff expires.")

	dave_council_maledict_bt = BuffType.new("dave_council_maledict_bt", 5, 0, false, self)
	var dave_council_maledict_mod: Modifier = Modifier.new()
	dave_council_maledict_mod.add_modification(Modification.Type.MOD_SPELL_DAMAGE_RECEIVED, 0.2, 0.006)
	dave_council_maledict_bt.set_buff_modifier(dave_council_maledict_mod)
	dave_council_maledict_bt.set_buff_icon("@@1@@")
	dave_council_maledict_bt.add_event_on_spell_targeted(dave_council_maledict_on_spell_targeted)
	dave_council_maledict_bt.set_buff_tooltip("Maledict\nThis unit is affected by Maledict; it will receive extra spell damage.")

	dave_council_mana_bt = BuffType.new("dave_council_mana_bt", 3, 0, true, self)
	var dave_council_mana_mod: Modifier = Modifier.new()
	dave_council_mana_mod.add_modification(Modification.Type.MOD_MANA_REGEN_PERC, 1.0, 0.02)
	dave_council_mana_bt.set_buff_modifier(dave_council_mana_mod)
	dave_council_mana_bt.set_buff_icon("@@3@@")
	dave_council_mana_bt.set_buff_tooltip("Demonic Mana\nThis tower is gaining Demonic Mana; it has increased mana regeneration.")

	dave_council_aura_bt = BuffType.create_aura_effect_type("dave_council_aura_bt", true, self)
	dave_council_aura_bt.set_buff_icon("@@2@@")
	dave_council_aura_bt.add_event_on_spell_casted(dave_council_aura_bt_on_spell_casted)
	dave_council_aura_bt.set_buff_tooltip("Demonic Edict Aura\nThis tower is under the effect of Demonic Edict Aura; it will fire an extra projectile when casting spells.")

	dave_council_pt = ProjectileType.create("DemonHunterMissile.mdl", 4, 1300, self)
	dave_council_pt.enable_homing(dave_council_pt_on_hit, 0)

	var autocast: Autocast = Autocast.make()
	autocast.title = "Impenetrable Darkness"
	autocast.description = get_autocast_description()
	autocast.description_short = get_autocast_description_short()
	autocast.icon = "res://path/to/icon.png"
	autocast.caster_art = ""
	autocast.target_art = "AvengerMissile.mdl"
	autocast.autocast_type = Autocast.Type.AC_TYPE_OFFENSIVE_BUFF
	autocast.num_buffs_before_idle = 1
	autocast.cast_range = 850
	autocast.auto_range = 850
	autocast.cooldown = 8
	autocast.mana_cost = 90
	autocast.target_self = false
	autocast.is_extended = false
	autocast.buff_type = dave_council_darkness_bt
	autocast.target_type = TargetType.new(TargetType.CREEPS)
	autocast.handler = on_autocast
	add_autocast(autocast)


func get_aura_types() -> Array[AuraType]:
	var aura: AuraType = AuraType.new()
	aura.aura_range = 400
	aura.target_type = TargetType.new(TargetType.TOWERS)
	aura.target_self = true
	aura.level = 1
	aura.level_add = 0
	aura.power = 1
	aura.power_add = 0
	aura.aura_effect = dave_council_aura_bt

	return [aura]


func on_damage(event: Event):
	var tower: Tower = self
	var creep: Unit = event.get_target()
	var level: int = tower.get_level()
	var maledict_chance: float = 0.2 + 0.004 * level

	if !tower.calc_chance(maledict_chance):
		return

	CombatLog.log_ability(tower, creep, "Maledict")

	dave_council_maledict_bt.apply(tower, creep, level)


func on_autocast(event: Event):
	var tower: Tower = self
	var target: Unit = event.get_target()
	var level: int = tower.get_level()
	dave_council_darkness_bt.apply(tower, target, level)


func dave_council_aura_bt_on_spell_casted(event: Event):
	var buff: Buff = event.get_buff()
	var tower: Tower = buff.get_caster()
	var target: Unit = event.get_target()
	var caster: Tower = buff.get_buffed_unit()
	var goldcost: float = caster.get_gold_cost()
	var cd: float = event.get_autocast_type().get_cooldown()
	var projectile_damage: float = 2 * goldcost * cd

	if !target is Creep:
		return
	
	CombatLog.log_ability(tower, target, "Demonic Edict on spell casted")
	
	SFX.sfx_at_unit("SleepSpecialArt.mdl", caster)
	var p: Projectile = Projectile.create_from_unit_to_unit(dave_council_pt, tower, 1.0, 1.0, caster, target, true, false, true)
	p.user_real = projectile_damage
	dave_council_mana_bt.apply(tower, caster, tower.get_level())


func dave_council_pt_on_hit(p: Projectile, creep: Unit):
	var tower: Tower = p.get_caster()
	var projectile_damage: float = p.user_real
	tower.do_spell_damage(creep, projectile_damage, tower.calc_spell_crit_no_bonus())


func dave_council_maledict_on_spell_targeted(event: Event):
	var buff: Buff = event.get_buff()
	var tower: Tower = buff.get_caster()
	var caster: Tower = event.get_target()
	var target: Unit = buff.get_buffed_unit()
	var gold: float = caster.get_gold_cost()
	var maledict_damage: float = 3 * gold

	if target.is_immune():
		return

	CombatLog.log_ability(tower, target, "Impenetrable Darkness periodic")
	
	tower.do_spell_damage(target, maledict_damage, tower.calc_spell_crit_no_bonus())
	SFX.sfx_at_unit("DeathandDecayTarget.mdl", target)


func dave_council_darkness_periodic(event: Event):
	var buff: Buff = event.get_buff()
	var tower: Tower = buff.get_caster()
	var target: Unit = event.get_target()
	var level: int = tower.get_level()
	var damage: float = 1000 + 40 * level

	CombatLog.log_ability(tower, target, "Maledict on spell targeted")
	
	tower.do_spell_damage(target, damage, tower.calc_spell_crit_no_bonus())


func dave_council_darkness_on_damaged(event: Event):
	var buff: Buff = event.get_buff()
	var stored_damage: float = buff.user_real
	stored_damage += event.damage
	buff.user_real += stored_damage


func dave_council_darkness_on_expire(event: Event):
	var buff: Buff = event.get_buff()
	var tower: Tower = buff.get_caster()
	var level: int = tower.get_level()
	var target: Unit = buff.get_buffed_unit()
	var stored_damage: float = buff.user_real
	var damage_multiplier: float = 0.75 + 0.01 * level
	var final_damage: float = stored_damage * damage_multiplier

	CombatLog.log_ability(tower, target, "Impenetrable Darkness on expire")

	tower.do_spell_damage(target, final_damage, 1)
	SFX.sfx_at_unit("DeathCoilSpecialArt.mdl", target)

	var floating_text: String = Utils.format_float(final_damage, 0)
	tower.get_player().display_floating_text(floating_text, target, 50, 50, 50)
