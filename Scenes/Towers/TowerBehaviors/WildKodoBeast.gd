extends TowerBehavior


var aura_bt: BuffType
var devour_count: int = 1

const AURA_RANGE: int = 400


func get_ability_info_list() -> Array[AbilityInfo]:
	var list: Array[AbilityInfo] = []
	
	var devour: AbilityInfo = AbilityInfo.new()
	devour.name = "Devour"
	devour.icon = "res://resources/Icons/animals/dragon_04.tres"
	devour.description_short = "On attack the Kodo has a chance to take a bite out of the main target, dealing spell damage and increasing effectiveness of [color=GOLD]Kodo Dung[/color].\n"
	devour.description_full = "On attack the Kodo has a 6% chance to take a bite out of the main target, dealing 5000 spell damage and increasing the multiplier for bonuses granted by [color=GOLD]Kodo Dung[/color] by 1 for 6 seconds.\n" \
	+ " \n" \
	+ "[color=ORANGE]Level Bonus:[/color]\n" \
	+ "+0.1% chance\n" \
	+ "+400 spell damage\n"
	list.append(devour)

	return list


func load_triggers(triggers: BuffType):
	triggers.add_event_on_attack(on_attack)


func tower_init():
	aura_bt = BuffType.create_aura_effect_type("aura_bt", true, self)
	var mod: Modifier = Modifier.new()
	mod.add_modification(Modification.Type.MOD_ATK_CRIT_CHANCE, 0.0, 0.0003)
	mod.add_modification(Modification.Type.MOD_ATK_CRIT_DAMAGE, 0.0, 0.0015)
	mod.add_modification(Modification.Type.MOD_ATTACKSPEED, 0.0, 0.0010)
	mod.add_modification(Modification.Type.MOD_DAMAGE_ADD_PERC, 0.0, 0.0010)
	aura_bt.set_buff_modifier(mod)
	aura_bt.set_buff_icon("res://resources/Icons/GenericIcons/poison_gas.tres")
	aura_bt.add_event_on_refresh(aura_bt_on_refresh)
	aura_bt.set_buff_tooltip("Kodo Dung\nIncreases attack damage, attack speed, crit chance and crit damage.")


func get_aura_types() -> Array[AuraType]:
	var aura: AuraType = AuraType.new()

	aura.name = "Kodo Dung"
	aura.icon = "res://resources/Icons/trinkets/trinket_03.tres"
	aura.description_short = "The dung of this kodo gives attack bonuses to nearby towers.\n"
	aura.description_full = "The dung of this kodo grants towers in %d range:\n" % AURA_RANGE \
	+ "  +10% attack damage\n" \
	+ "  +10% attack speed\n" \
	+ "  +3% critical strike chance\n" \
	+ "  +15% critical strike damage\n" \
	+ " \n" \
	+ "[color=ORANGE]Level Bonus:[/color]\n" \
	+ "+0.2% attack damage\n" \
	+ "+0.2% attack speed\n" \
	+ "+0.06% critical strike chance\n" \
	+ "+0.3% critical strike damage\n"

	aura.aura_range = AURA_RANGE
	aura.target_type = TargetType.new(TargetType.TOWERS)
	aura.target_self = true
	aura.level = 0
	aura.level_add = 1
	aura.power = 100
	aura.power_add = 2
	aura.aura_effect = aura_bt
	return [aura]


func on_attack(event: Event):
	var target: Unit = event.get_target()
	var level: int = tower.get_level()
	var chance: float = 0.06 + 0.001 * level
	var devour_damage: float = 5000 + 400 * level

	if !tower.calc_chance(chance):
		return

	CombatLog.log_ability(tower, target, "Devour")

	tower.do_spell_damage(target, devour_damage, tower.calc_spell_crit_no_bonus())
	SFX.sfx_at_unit("DevourEffectArt.mdl", target)
	devour_count += 1
	tower.refresh_auras()

	var devour_stack_duration: float = 6.0 * tower.get_prop_buff_duration()

	await Utils.create_timer(devour_stack_duration, self).timeout

	if !Utils.unit_is_valid(tower):
		return

	devour_count -= 1
	tower.refresh_auras()


func aura_bt_on_refresh(event: Event):
	var buff: Buff = event.get_buff()
	var new_power: int = (100 + 2 * tower.get_level()) * devour_count
	buff.set_power(new_power)
