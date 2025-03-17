extends TowerBehavior


# NOTE: the "Conduit Aura" ability has exactly the same
# logic as "Evil Device" ability of "Soulflame Device"
# tower.


var aura_bt: BuffType
var unleash_bt: BuffType
var chanlightning_st: SpellType


func load_triggers(triggers: BuffType):
	triggers.add_event_on_damage(on_damage)


func tower_init():
	aura_bt = BuffType.create_aura_effect_type("aura_bt", true, self)
	aura_bt.set_buff_icon("res://resources/icons/generic_icons/over_infinity.tres")
	aura_bt.add_event_on_create(aura_bt_on_create)
	aura_bt.add_event_on_cleanup(aura_bt_on_cleanup)
	aura_bt.add_periodic_event(aura_bt_periodic, 5)
	aura_bt.set_buff_tooltip("Conduit Aura\nIncreases attack speed, trigger chances, spell damage, spell crit chance and spell crit damage.")

	unleash_bt = BuffType.new("unleash_bt", 3, 0, false, self)
	var unleash_bt_mod: Modifier = Modifier.new()
	unleash_bt_mod.add_modification(Modification.Type.MOD_SPELL_CRIT_DAMAGE, 0.75, 0.03)
	unleash_bt.set_buff_modifier(unleash_bt_mod)
	unleash_bt.set_buff_icon("res://resources/icons/generic_icons/bat_mask.tres")
	unleash_bt.set_buff_tooltip("Unleash\nIncreases spell crit damage.")

	chanlightning_st = SpellType.new(SpellType.Name.CHAIN_LIGHTNING, 1.0, self)
	chanlightning_st.set_source_height(220)
	chanlightning_st.data.chain_lightning.damage = 1.0
	chanlightning_st.data.chain_lightning.damage_reduction = 0.25
	chanlightning_st.data.chain_lightning.chain_count = 1


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

	var lightning_end_pos: Vector3 = Vector3(tower.get_x(), tower.get_y(), 180)
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

		unleash_bt.apply(tower, next, tower.get_level())

#	NOTE: original script does a weird thing where it casts
#	chain lightning (which deals damage) and also deals
#	damage using tower.doSpellDamage(). doSpellDamage() does
#	the actual damage amount. chain lightning deals a small
#	amount (like 6) which looks confusing.
# 
#	Changed it to deal damage only once, via chain
#	lightning.
	chanlightning_st.target_cast_from_caster(tower, target, cast_damage, tower.calc_spell_crit_no_bonus())


# NOTE: "ashbringer_conduit_create()" in original script
func aura_bt_on_create(event: Event):
	var buff: Buff = event.get_buff()

	buff.user_real = 0
	buff.user_real2 = 0
	buff.user_real3 = 0
	buff.user_int = 0
	buff.user_int2 = 0

	unleash_bt_update(buff)


# NOTE: "ashbringer_conduit_cleanup()" in original script
func aura_bt_on_cleanup(event: Event):
	var buff: Buff = event.get_buff()
	var buffed_tower: Unit = buff.get_buffed_unit()
	
	buffed_tower.modify_property(Modification.Type.MOD_SPELL_DAMAGE_DEALT, -buff.user_real)
	buffed_tower.modify_property(Modification.Type.MOD_SPELL_CRIT_CHANCE, -buff.user_real2)
	buffed_tower.modify_property(Modification.Type.MOD_SPELL_CRIT_DAMAGE, -buff.user_real3)
	buffed_tower.modify_property(Modification.Type.MOD_ATTACKSPEED, -buff.user_int / 1000.0)
	buffed_tower.modify_property(Modification.Type.MOD_TRIGGER_CHANCES, -buff.user_int2 / 1000.0)


# NOTE: "ashbringer_conduit_update()" in original script
func aura_bt_periodic(event: Event):
	var buff: Buff = event.get_buff()
	
	unleash_bt_update(buff)


func unleash_bt_update(buff: Buff):
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
#	NOTE: 1.0 is 0.0 in original script. Changed it to 1.0
#	because in youtd2 get_attack_speed_modifier() is based
#	around 1.0.
	var attack_speed_innate: float = 1.0 + caster_level * Constants.INNATE_MOD_ATTACKSPEED_LEVEL_ADD

	buff.user_real = (caster.get_prop_spell_damage_dealt() - 1.0) * caster_level_factor
	buff.user_real2 = (caster.get_spell_crit_chance() - spell_crit_chance_innate) * caster_level_factor
	buff.user_real3 = (caster.get_spell_crit_damage() - spell_crit_dmg_innate) * caster_level_factor
	buff.user_int = int((caster.get_attack_speed_modifier() - attack_speed_innate) * caster_level_factor * 1000.0)
	buff.user_int2 = int((caster.get_prop_trigger_chances() - 1.0) * caster_level_factor * 1000.0)

	buffed_tower.modify_property(Modification.Type.MOD_SPELL_DAMAGE_DEALT, buff.user_real)
	buffed_tower.modify_property(Modification.Type.MOD_SPELL_CRIT_CHANCE, buff.user_real2)
	buffed_tower.modify_property(Modification.Type.MOD_SPELL_CRIT_DAMAGE, buff.user_real3)
	buffed_tower.modify_property(Modification.Type.MOD_ATTACKSPEED, buff.user_int / 1000.0)
	buffed_tower.modify_property(Modification.Type.MOD_TRIGGER_CHANCES, buff.user_int2 / 1000.0)
