extends TowerBehavior


# NOTE: "Conduit" ability is exactly the same as "Evil
# Device" ability of "Soulflame Device" tower.


var ash_conduit_aura_bt: BuffType
var ash_conduit_unleash_bt: BuffType
var unleash_st: SpellType


func get_ability_description() -> String:
	var text: String = ""

	text += "[color=GOLD]Absorb Energy[/color]\n"
	text += "Attacks hit up to 10 enemies, but do no damage. There is a 10% chance per hit to gather energy, restoring 50 mana to the tower and the target will lose 50 mana if it has mana.\n"
	text += " \n"
	text += "[color=ORANGE]Level Bonus:[/color]\n"
	text += "+1 mana\n"
	text += "+0.2% chance\n"
	text += " \n"

	text += "[color=GOLD]Conduit - Aura[/color]\n"
	text += "Attack speed, trigger chances, spell damage, spell crit chance and spell crit damage bonuses on this tower are applied to Common and Uncommon Storm towers in 350 range at a rate of 50%.\n"
	text += " \n"
	text += "[color=ORANGE]Level Bonus:[/color]\n"
	text += "+2% stats\n"

	return text


func get_ability_description_short() -> String:
	var text: String = ""

	text += "[color=GOLD]Absorb Energy[/color]\n"
	text += "Attacks do no damage but have a chance to absorb mana from target.\n"
	text += " \n"

	text += "[color=GOLD]Conduit - Aura[/color]\n"
	text += "Half of attack bonuses on this tower are applied to nearby Common and Uncommon Storm towers.\n"

	return text


func get_autocast_description() -> String:
	var text: String = ""

	text += "Unleashes built up energy, dealing [400 x wave] spell damage to a single enemy and increasing the spell crit damage of nearby towers within 350 range by x0.75 for 5 seconds.\n"
	text += " \n"
	text += "[color=ORANGE]Level Bonus:[/color]\n"
	text += "+8 spell damage per wave\n"
	text += "+x0.03 spell crit damage\n"

	return text


func get_autocast_description_short() -> String:
	var text: String = ""

	text += "Unleashes built up energy, dealing spell damage to a single enemy and increasing the spell crit damage of nearby towers.\n"

	return text


func load_triggers(triggers: BuffType):
	triggers.add_event_on_damage(on_damage)


# NOTE: this tower's tooltip in original game includes
# innate stats in some cases
# spell crit chance = yes
# spell crit chance add = no
# spell crit damage = yes
# spell crit damage add = no
func load_specials(modifier: Modifier):
	tower.set_target_count(10)
	modifier.add_modification(Modification.Type.MOD_SPELL_CRIT_CHANCE, 0.0375, 0.005)
	modifier.add_modification(Modification.Type.MOD_SPELL_CRIT_DAMAGE, 0.25, 0.05)


func get_ability_ranges() -> Array[RangeData]:
	return [RangeData.new("Unleash Attack", 1200, TargetType.new(TargetType.CREEPS)), RangeData.new("Unleash Buff", 350, TargetType.new(TargetType.TOWERS))]


func tower_init():
	ash_conduit_aura_bt = BuffType.create_aura_effect_type("ash_conduit_aura_bt", true, self)
	ash_conduit_aura_bt.set_buff_icon("letter_s_lying_down.tres")
	ash_conduit_aura_bt.set_buff_tooltip("Conduit Aura\nIncreases attack speed, trigger chances, spell damage, spell crit chance and spell crit damage.")

	ash_conduit_unleash_bt = BuffType.new("ash_conduit_unleash_bt", 3, 0, false, self)
	var ash_conduit_unleash_bt_mod: Modifier = Modifier.new()
	ash_conduit_unleash_bt_mod.add_modification(Modification.Type.MOD_SPELL_CRIT_DAMAGE, 0.75, 0.03)
	ash_conduit_unleash_bt.set_buff_modifier(ash_conduit_unleash_bt_mod)
	ash_conduit_unleash_bt.set_buff_icon("mask_bat.tres")
	ash_conduit_unleash_bt.add_event_on_create(ash_conduit_unleash_bt_on_create)
	ash_conduit_unleash_bt.add_event_on_cleanup(ash_conduit_unleash_bt_on_cleanup)
	ash_conduit_unleash_bt.add_periodic_event(ash_conduit_unleash_bt_periodic, 5)
	ash_conduit_unleash_bt.set_buff_tooltip("Unleash\nIncreases spell crit damage.")

	unleash_st = SpellType.new("@@1@@", "chainlightning", 1.0, self)
#	TODO: implement SpellType.set_source_height()
	# unleash_st.set_source_height(220)
	unleash_st.data.chain_lightning.damage = 1.0
	unleash_st.data.chain_lightning.damage_reduction = 0.25
	unleash_st.data.chain_lightning.chain_count = 1

	var autocast: Autocast = Autocast.make()
	autocast.title = "Unleash"
	autocast.description = get_autocast_description()
	autocast.description_short = get_autocast_description_short()
	autocast.icon = "res://path/to/icon.png"
	autocast.caster_art = ""
	autocast.target_art = ""
	autocast.autocast_type = Autocast.Type.AC_TYPE_OFFENSIVE_BUFF
	autocast.num_buffs_before_idle = 1
	autocast.cast_range = 1200
	autocast.auto_range = 1200
	autocast.cooldown = 0.5
	autocast.mana_cost = 400
	autocast.target_self = false
	autocast.is_extended = false
	autocast.buff_type = null
	autocast.target_type = TargetType.new(TargetType.CREEPS)
	autocast.handler = on_autocast
	tower.add_autocast(autocast)


func get_aura_types() -> Array[AuraType]:
	var aura: AuraType = AuraType.new()
	aura.aura_range = 350
	aura.target_type = TargetType.new(TargetType.TOWERS + TargetType.ELEMENT_STORM + TargetType.RARITY_UNCOMMON + TargetType.RARITY_COMMON)
	aura.target_self = false
	aura.level = 1
	aura.level_add = 0
	aura.power = 1
	aura.power_add = 0
	aura.aura_effect = ash_conduit_aura_bt

	return [aura]


func on_damage(event: Event):
	var absorb_energy_chance: float = 0.1 + 0.002 * tower.get_level()

#	NOTE: in original script, damage was set to 0 only when
#	calc_chance() succeeded. Fixed this, now damage is 0
#	always.
	event.damage = 0

	if !tower.calc_chance(absorb_energy_chance):
		return

	var target: Unit = event.get_target()
	var mana: float = 50 + 1 * tower.get_level()
	tower.add_mana(mana)
	target.subtract_mana(mana, true)

	var lightning_end_pos: Vector3 = Vector3(tower.get_visual_x(), tower.get_visual_y(), 180)
	var interpolated_sprite: InterpolatedSprite = InterpolatedSprite.create_from_unit_to_point(InterpolatedSprite.LIGHTNING, target, lightning_end_pos)
	interpolated_sprite.set_lifetime(0.5)


func on_autocast(event: Event):
	var target: Unit = event.get_target()
	var it: Iterate = Iterate.over_units_in_range_of_unit(tower, TargetType.new(TargetType.TOWERS), tower, 350)
	var cast_damage: float = (400 + 8 * tower.get_level()) * tower.get_player().get_team().get_level()

	while true:
		var next: Unit = it.next()

		if next == null:
			break

		ash_conduit_unleash_bt.apply(tower, next, tower.get_level())

#	NOTE: original script does a weird thing where it casts
#	chain lightning (which deals damage) and also deals
#	damage using tower.doSpellDamage(). doSpellDamage() does
#	the actual damage amount. chain lightning deals a small
#	amount (like 6) which looks confusing.
# 
#	Changed it to deal damage only once, via chain
#	lightning.
	unleash_st.target_cast_from_caster(tower, target, cast_damage, tower.calc_spell_crit_no_bonus())


# NOTE: "ashbringer_conduit_create()" in original script
func ash_conduit_unleash_bt_on_create(event: Event):
	var buff: Buff = event.get_buff()

	buff.user_real = 0
	buff.user_real2 = 0
	buff.user_real3 = 0
	buff.user_int = 0
	buff.user_int2 = 0

	ash_conduit_unleash_bt_update(buff)


# NOTE: "ashbringer_conduit_cleanup()" in original script
func ash_conduit_unleash_bt_on_cleanup(event: Event):
	var buff: Buff = event.get_buff()
	var buffed_tower: Unit = buff.get_buffed_unit()
	
	buffed_tower.modify_property(Modification.Type.MOD_SPELL_DAMAGE_DEALT, -buff.user_real)
	buffed_tower.modify_property(Modification.Type.MOD_SPELL_CRIT_CHANCE, -buff.user_real2)
	buffed_tower.modify_property(Modification.Type.MOD_SPELL_CRIT_DAMAGE, -buff.user_real3)
	buffed_tower.modify_property(Modification.Type.MOD_ATTACKSPEED, -buff.user_int / 1000.0)
	buffed_tower.modify_property(Modification.Type.MOD_TRIGGER_CHANCES, -buff.user_int2 / 1000.0)


# NOTE: "ashbringer_conduit_update()" in original script
func ash_conduit_unleash_bt_periodic(event: Event):
	var buff: Buff = event.get_buff()
	
	ash_conduit_unleash_bt_update(buff)


func ash_conduit_unleash_bt_update(buff: Buff):
	var buffed_tower: Tower = buff.get_buffed_unit()
	var caster: Tower = buff.get_caster()
	var caster_level: int = caster.get_level()
	var caster_level_factor: float = 0.5 + 0.02 * caster_level

	buffed_tower.modify_property(Modification.Type.MOD_SPELL_DAMAGE_DEALT, -buff.user_real)
	buffed_tower.modify_property(Modification.Type.MOD_SPELL_CRIT_CHANCE, -buff.user_real2)
	buffed_tower.modify_property(Modification.Type.MOD_SPELL_CRIT_DAMAGE, -buff.user_real3)
	buffed_tower.modify_property(Modification.Type.MOD_ATTACKSPEED, -buff.user_int / 1000.0)
	buffed_tower.modify_property(Modification.Type.MOD_TRIGGER_CHANCES, -buff.user_int2 / 1000.0)

	var spell_crit_chance_innate: float = Constants.INNATE_MOD_SPELL_CRIT_CHANCE - caster_level * Constants.INNATE_MOD_SPELL_CRIT_CHANCE_LEVEL_ADD
	var spell_crit_dmg_innate: float = Constants.INNATE_MOD_SPELL_CRIT_DAMAGE - caster_level * Constants.INNATE_MOD_SPELL_CRIT_DAMAGE_LEVEL_ADD
	var attackspeed_innate: float = 0.0 + caster_level * Constants.INNATE_MOD_ATTACKSPEED_LEVEL_ADD

	buff.user_real = (caster.get_prop_spell_damage_dealt() - 1.0) * caster_level_factor
	buff.user_real2 = (caster.get_spell_crit_chance() - spell_crit_chance_innate) * caster_level_factor
	buff.user_real3 = (caster.get_spell_crit_damage() - spell_crit_dmg_innate) * caster_level_factor
	buff.user_int = int((caster.get_base_attackspeed() - attackspeed_innate) * caster_level_factor * 1000.0)
	buff.user_int2 = int((caster.get_prop_trigger_chances() - 1.0) * caster_level_factor * 1000.0)

	buffed_tower.modify_property(Modification.Type.MOD_SPELL_DAMAGE_DEALT, buff.user_real)
	buffed_tower.modify_property(Modification.Type.MOD_SPELL_CRIT_CHANCE, buff.user_real2)
	buffed_tower.modify_property(Modification.Type.MOD_SPELL_CRIT_DAMAGE, buff.user_real3)
	buffed_tower.modify_property(Modification.Type.MOD_ATTACKSPEED, buff.user_int / 1000.0)
	buffed_tower.modify_property(Modification.Type.MOD_TRIGGER_CHANCES, buff.user_int2 / 1000.0)
