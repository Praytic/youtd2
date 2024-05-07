extends TowerBehavior


var electrify_bt: BuffType
var lightning_st: SpellType
var multiboard: MultiboardValues
var lightmare_is_active: bool = false
var i_scale_level: int = 0
var i_scale_value: int = 0


func get_ability_info_list() -> Array[AbilityInfo]:
	var list: Array[AbilityInfo] = []
	
	var i_scale: AbilityInfo = AbilityInfo.new()
	i_scale.name = "I Scale"
	i_scale.description_short = "This tower gains spell damage, spell crit damage and spell crit chance for each level the player survives.\n"
	i_scale.description_full = "This tower gains 1.66% spell damage, spell crit damage and 0.125% spell crit chance for each level the player survives.\n"
	list.append(i_scale)

	var electrify: AbilityInfo = AbilityInfo.new()
	electrify.name = "Electrify"
	electrify.description_short = "Chance to electrify creeps. Creeps in range of the electrified unit will take damage.\n"
	electrify.description_full = "Whenever this tower damages a creep, it has a 20% chance to electrify it for 5 seconds. Each second, all creeps in 225 range of the electrified unit take 900 spell damage.\n" \
	+ " \n" \
	+ "[color=ORANGE]Level Bonus:[/color]\n" \
	+ "+0.8% chance\n" \
	+ "+36 spell damage per second\n"
	list.append(electrify)

	var overcharge: AbilityInfo = AbilityInfo.new()
	overcharge.name = "I Overcharge"
	overcharge.description_short = "Chance to deal extra spell damage to the damaged unit.\n"
	overcharge.description_full = "Whenever this tower deals damage with its attacks or its other innate abilities it has a 25% chance to deal 900 spell damage to the damaged unit. Overcharge can trigger itself, but the chance to do so is decreased by 5% for each time it retriggers.\n" \
	+ " \n" \
	+ "[color=ORANGE]Level Bonus:[/color]\n" \
	+ "+36 spell damage\n" \
	+ "+1% chance\n"
	list.append(overcharge)

	return list


func get_autocast_description() -> String:
	var text: String = ""

	text += "Summons a storm cloud which attacks units in 1500 range. Every 0.33 seconds the cloud attacks up to 3 targets with forked lightning. Each lightning deals 1300 spell damage. Lightmare lasts 10 seconds and does not benefit from buff duration.\n"
	text += " \n"
	text += "[color=ORANGE]Level Bonus:[/color]\n"
	text += "+52 spell damage\n"

	return text


func get_autocast_description_short() -> String:
	var text: String = ""

	text += "Summons a storm cloud which attacks units in range.\n"

	return text


func load_triggers(triggers: BuffType):
	triggers.add_event_on_attack(on_attack)
	triggers.add_event_on_damage(on_damage_for_electrify)
	triggers.add_event_on_damage(on_damage_for_overcharge)
	triggers.add_periodic_event(periodic, 0.33)


func load_specials(modifier: Modifier):
	modifier.add_modification(Modification.Type.MOD_DMG_TO_AIR, 0.20, 0.008)


func get_ability_ranges() -> Array[RangeData]:
	return [RangeData.new("Lightmare", 1500, TargetType.new(TargetType.CREEPS))]


func tower_init():
	lightning_st = SpellType.new("@@0@@", "forkedlightning", 2.0, self)
	lightning_st.set_source_height(300.0)
	lightning_st.set_damage_event(mock_eye_glare_st_on_damage)
	lightning_st.data.forked_lightning.damage = 1.0
	lightning_st.data.forked_lightning.target_count = 3

	electrify_bt = BuffType.new("electrify_bt", 5, 0, false, self)
	electrify_bt.set_buff_icon("res://Resources/Textures/GenericIcons/electric.tres")
	electrify_bt.add_periodic_event(electrify_bt_periodic, 1.0)
	electrify_bt.set_buff_tooltip("Electrify\nDeals damage to nearby creeps.")

	multiboard = MultiboardValues.new(3)
	multiboard.set_key(0, "Spell Damage Bonus")
	multiboard.set_key(1, "Spell Crit Damage Bonus")
	multiboard.set_key(2, "Spell Crit Chance Bonus")

	var autocast: Autocast = Autocast.make()
	autocast.title = "Lightmare"
	autocast.description = get_autocast_description()
	autocast.description_short = get_autocast_description_short()
	autocast.icon = "res://Resources/Textures/AbilityIcons/thunder_swirl.tres"
	autocast.caster_art = ""
	autocast.target_art = ""
	autocast.autocast_type = Autocast.Type.AC_TYPE_OFFENSIVE_IMMEDIATE
	autocast.num_buffs_before_idle = 0
	autocast.cast_range = 1500
	autocast.auto_range = 1500
	autocast.cooldown = 10.5
	autocast.mana_cost = 1000
	autocast.target_self = true
	autocast.is_extended = false
	autocast.buff_type = null
	autocast.target_type = TargetType.new(TargetType.TOWERS)
	autocast.handler = on_autocast
	tower.add_autocast(autocast)


func on_create(_preceding: Tower):
	i_scale_level = tower.get_player().get_team().get_level()


func on_attack(_event: Event):
	var i: int = tower.get_player().get_team().get_level()
	var i2: = i

	if i > i_scale_level:
		i -= i_scale_level
		i_scale_value += i

		tower.modify_property(Modification.Type.MOD_SPELL_DAMAGE_DEALT, i / 60.0)
		tower.modify_property(Modification.Type.MOD_SPELL_CRIT_DAMAGE, i / 60.0)
		tower.modify_property(Modification.Type.MOD_SPELL_CRIT_CHANCE, i / 800.0)

		i_scale_level = i2


func on_damage_for_electrify(event: Event):
	var target: Unit = event.get_target()
	var level: int = tower.get_level()
	var electrify_chance: float = 0.2 + 0.008 * level

	if !tower.calc_chance(electrify_chance):
		return

	CombatLog.log_ability(tower, target, "Electrify")
	electrify_bt.apply(tower, target, level)


func on_damage_for_overcharge(event: Event):
	var target: Unit = event.get_target()
	var level: int = tower.get_level()

	overcharge_damage(target, level)


func periodic(_event: Event):
	if !lightmare_is_active:
		return

	var it: Iterate = Iterate.over_units_in_range_of_caster(tower, TargetType.new(TargetType.CREEPS), 1500)

	var next: Unit = it.next()

	if next != null:
		var damage: float = 1300 + 52 * tower.get_level()
		lightning_st.target_cast_from_caster(tower, next, damage, tower.calc_spell_crit_no_bonus())


func on_autocast(_event: Event):
	var effect: int = Effect.create_scaled("CloudOfFog.mdl", Vector3(tower.get_x(), tower.get_y(), tower.get_z() + 150), 0, 5)
	Effect.set_lifetime(effect, 10.0)

	lightmare_is_active = true

	await Utils.create_timer(10.0, self).timeout

	lightmare_is_active = false


func on_tower_details() -> MultiboardValues:
	var spell_damage: String = Utils.format_percent(i_scale_value * 1.66 / 100, 2)
	var spell_crit_damage: String = Utils.format_percent(i_scale_value * 1.66 / 100, 2)
	var spell_crit_chance: String = Utils.format_percent(i_scale_value * 0.125 / 100, 2)
	multiboard.set_value(0, spell_damage)
	multiboard.set_value(1, spell_crit_damage)
	multiboard.set_value(2, spell_crit_chance)

	return multiboard


# func example_pt_on_hit(p: Projectile, target: Unit):
# 	if target == null:
# 		return

# 	tower.do_spell_damage(target, 123, tower.calc_spell_crit_no_bonus())


# NOTE: "overchargeA()" in original script
func mock_eye_glare_st_on_damage(event: Event, _dummy: SpellDummy):
	var target: Unit = event.get_target()
	var level: int = tower.get_level()

	overcharge_damage(target, level)


func overcharge_damage(target: Unit, level: int):
	var i: int = 0
	var damage: float = 900 + 36 * level

	while true:
		var target_health_ratio: float = target.get_health_ratio()

		if target_health_ratio <= 0.405:
			break

		var overcharge_chance: float = 0.25 + 0.01 * level - 0.05 * i

		if !tower.calc_chance(overcharge_chance):
			break

		var effect: int = Effect.add_special_effect_target("MonsoonBoltTarget.mdl", target, Unit.BodyPart.ORIGIN)
		Effect.destroy_effect_after_its_over(effect)
		
		tower.do_spell_damage(target, damage, tower.calc_spell_crit_no_bonus() )

		i += 1


# NOTE: "elec()" in original script
func electrify_bt_periodic(event: Event):
	var buff: Buff = event.get_buff()
	var target: Unit = buff.get_buffed_unit()
	var it: Iterate = Iterate.over_units_in_range_of_caster(tower, TargetType.new(TargetType.CREEPS), 225)
	var damage: float = 900 + 36 * tower.get_level()

	while true:
		var next: Unit = it.next()

		if next == null:
			return

		if next != target:
			tower.do_spell_damage(next, damage, tower.calc_spell_crit_no_bonus())
			overcharge_damage(next, tower.get_level())
