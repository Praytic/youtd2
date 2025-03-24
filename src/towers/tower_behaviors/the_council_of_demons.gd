extends TowerBehavior


# NOTE: [ORIGINAL_GAME_BUG] Original script has a bug where
# the projectile created by aura deals 2 damage because
# do_spell_damage() is called on tower instead of
# projectile. It was intended that projectile stores damage
# ratio and then deals damage using that ratio. Fixed bug by
# not using damage ratio (not needed really) and storing
# damage in user_real of projectile.


var aura_bt: BuffType
var demonic_mana_bt: BuffType
var maledict_bt: BuffType
var darkness_bt: BuffType
var missile_pt: ProjectileType


func load_triggers(triggers: BuffType):
	triggers.add_event_on_damage(on_damage)


func tower_init():
	darkness_bt = BuffType.new("darkness_bt", 5, 0, false, self)
	var dave_council_darkness_mod: Modifier = Modifier.new()
	dave_council_darkness_mod.add_modification(Modification.Type.MOD_MOVESPEED, -0.4, -0.006)
	dave_council_darkness_mod.add_modification(Modification.Type.MOD_ATK_DAMAGE_RECEIVED, -0.95, 0.0)
	darkness_bt.set_buff_modifier(dave_council_darkness_mod)
	darkness_bt.set_buff_icon("res://resources/icons/generic_icons/fire_dash.tres")
	darkness_bt.add_periodic_event(dave_council_darkness_periodic, 1.0)
	darkness_bt.add_event_on_damaged(dave_council_darkness_on_damaged)
	darkness_bt.add_event_on_expire(dave_council_darkness_on_expire)
	darkness_bt.set_buff_tooltip(tr("XJLT"))

	maledict_bt = BuffType.new("maledict_bt", 5, 0, false, self)
	var dave_council_maledict_mod: Modifier = Modifier.new()
	dave_council_maledict_mod.add_modification(Modification.Type.MOD_SPELL_DAMAGE_RECEIVED, 0.2, 0.006)
	maledict_bt.set_buff_modifier(dave_council_maledict_mod)
	maledict_bt.set_buff_icon("res://resources/icons/generic_icons/fire_dash.tres")
	maledict_bt.add_event_on_spell_targeted(dave_council_maledict_on_spell_targeted)
	maledict_bt.set_buff_tooltip(tr("Q488"))

	demonic_mana_bt = BuffType.new("demonic_mana_bt", 3, 0, true, self)
	var dave_council_mana_mod: Modifier = Modifier.new()
	dave_council_mana_mod.add_modification(Modification.Type.MOD_MANA_REGEN_PERC, 1.0, 0.02)
	demonic_mana_bt.set_buff_modifier(dave_council_mana_mod)
	demonic_mana_bt.set_buff_icon("res://resources/icons/generic_icons/star_swirl.tres")
	demonic_mana_bt.set_buff_tooltip(tr("LN06"))

	aura_bt = BuffType.create_aura_effect_type("aura_bt", true, self)
	aura_bt.set_buff_icon("res://resources/icons/generic_icons/burning_meteor.tres")
	aura_bt.add_event_on_spell_casted(aura_bt_on_spell_casted)
	aura_bt.set_buff_tooltip(tr("RTYZ"))

	missile_pt = ProjectileType.create("path_to_projectile_sprite", 4, 1300, self)
	missile_pt.enable_homing(missile_pt_on_hit, 0)


func on_damage(event: Event):
	var creep: Unit = event.get_target()
	var level: int = tower.get_level()
	var maledict_chance: float = 0.2 + 0.004 * level

	if !tower.calc_chance(maledict_chance):
		return

	CombatLog.log_ability(tower, creep, "Maledict")

	maledict_bt.apply(tower, creep, level)


func on_autocast(event: Event):
	var target: Unit = event.get_target()
	var level: int = tower.get_level()
	darkness_bt.apply(tower, target, level)


func aura_bt_on_spell_casted(event: Event):
	var buff: Buff = event.get_buff()
	var target: Unit = event.get_target()
	var caster: Tower = buff.get_buffed_unit()
	var goldcost: float = caster.get_gold_cost()
	var cd: float = event.get_autocast_type().get_cooldown()
	var projectile_damage: float = 2 * goldcost * cd

	if !target is Creep:
		return
	
	CombatLog.log_ability(tower, target, "Demonic Edict on spell casted")
	
	Effect.create_simple_at_unit("res://src/effects/death_coil.tscn", target)
	var p: Projectile = Projectile.create_from_unit_to_unit(missile_pt, tower, 1.0, 1.0, caster, target, true, false, true)
	p.user_real = projectile_damage
	demonic_mana_bt.apply(tower, caster, tower.get_level())


func missile_pt_on_hit(p: Projectile, creep: Unit):
	if creep == null:
		return

	var projectile_damage: float = p.user_real
	tower.do_spell_damage(creep, projectile_damage, tower.calc_spell_crit_no_bonus())


func dave_council_maledict_on_spell_targeted(event: Event):
	var buff: Buff = event.get_buff()
	var caster: Tower = event.get_target()
	var target: Unit = buff.get_buffed_unit()
	var gold: float = caster.get_gold_cost()
	var maledict_damage: float = 3 * gold

	if target.is_immune():
		return

	CombatLog.log_ability(tower, target, "Impenetrable Darkness periodic")
	
	tower.do_spell_damage(target, maledict_damage, tower.calc_spell_crit_no_bonus())
	Effect.create_simple_at_unit("res://src/effects/death_and_decay.tscn", target)
	SFX.sfx_at_unit(SfxPaths.GHOST_EXHALE, target)


func dave_council_darkness_periodic(event: Event):
	var target: Unit = event.get_target()
	var level: int = tower.get_level()
	var damage: float = 1000 + 40 * level

	CombatLog.log_ability(tower, target, "Maledict on spell targeted")
	
	tower.do_spell_damage(target, damage, tower.calc_spell_crit_no_bonus())


func dave_council_darkness_on_damaged(event: Event):
	var buff: Buff = event.get_buff()
	var stored_damage: float = buff.user_real
	stored_damage += event.damage
	buff.user_real = stored_damage


func dave_council_darkness_on_expire(event: Event):
	var buff: Buff = event.get_buff()
	var level: int = tower.get_level()
	var target: Unit = buff.get_buffed_unit()
	var stored_damage: float = buff.user_real
	var damage_multiplier: float = 0.75 + 0.01 * level
	var final_damage: float = stored_damage * damage_multiplier

	CombatLog.log_ability(tower, target, "Impenetrable Darkness on expire")

	tower.do_spell_damage(target, final_damage, 1)
	Effect.create_simple_at_unit("res://src/effects/death_coil.tscn", target)

	var floating_text: String = Utils.format_float(final_damage, 0)
	tower.get_player().display_floating_text(floating_text, target, Color8(50, 50, 50))
