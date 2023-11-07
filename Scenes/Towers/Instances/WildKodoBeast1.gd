extends Tower


var sir_kodo_aura_bt: BuffType
var devour_count: int = 1


func get_ability_description() -> String:
	var text: String = ""

	text += "[color=GOLD]Devour[/color]\n"
	text += "On attack the Kodo has a 6% chance to take a bite out of its target dealing 5000 spell damage and increasing the multiplier for bonuses granted by 'Kodo Dung' by 1 for 6 seconds.\n"
	text += " \n"
	text += "[color=ORANGE]Level Bonus:[/color]\n"
	text += "+0.1% chance\n"
	text += "+400 spell damage\n"
	text += " \n"

	text += "[color=GOLD]Kodo Dung - Aura[/color]\n"
	text += "The dung of this kodo grants towers in 400 range:\n"
	text += "  +10% damage\n"
	text += "  +10% attackspeed\n"
	text += "  +3% critical strike chance\n"
	text += "  +15% critical strike damage\n"
	text += " \n"
	text += "[color=ORANGE]Level Bonus:[/color]\n"
	text += "+0.2% damage\n"
	text += "+0.2% attackspeed\n"
	text += "+0.06% critical strike chance\n"
	text += "+0.3% critical strike damage\n"

	return text


func get_ability_description_short() -> String:
	var text: String = ""

	text += "[color=GOLD]Devour[/color]\n"
	text += "On attack the Kodo has a chance to take a bite out of its target.\n"
	text += " \n"

	text += "[color=GOLD]Kodo Dung - Aura[/color]\n"
	text += "The dung of this kodo empowers nearby towers.\n"
	
	return text


func load_triggers(triggers: BuffType):
	triggers.add_event_on_attack(on_attack)


func tower_init():
	sir_kodo_aura_bt = BuffType.create_aura_effect_type("sir_kodo_aura_bt", true, self)
	var mod: Modifier = Modifier.new()
	mod.add_modification(Modification.Type.MOD_ATK_CRIT_CHANCE, 0.0, 0.0003)
	mod.add_modification(Modification.Type.MOD_ATK_CRIT_DAMAGE, 0.0, 0.0015)
	mod.add_modification(Modification.Type.MOD_ATTACKSPEED, 0.0, 0.0010)
	mod.add_modification(Modification.Type.MOD_DAMAGE_ADD_PERC, 0.0, 0.0010)
	sir_kodo_aura_bt.set_buff_modifier(mod)
	sir_kodo_aura_bt.set_buff_icon("@@0@@")
	sir_kodo_aura_bt.add_event_on_refresh(sir_kodo_aura_bt_on_refresh)
	sir_kodo_aura_bt.set_buff_tooltip("Kodo Dung\nThis tower smells Kodo Dung; it has increased damage, attack speed, crit chance and crit damage.")


func get_aura_types() -> Array[AuraType]:
	var aura: AuraType = AuraType.new()
	aura.aura_range = 400
	aura.target_type = TargetType.new(TargetType.TOWERS)
	aura.target_self = true
	aura.level = 0
	aura.level_add = 1
	aura.power = 100
	aura.power_add = 2
	aura.aura_effect = sir_kodo_aura_bt
	return [aura]


func on_attack(event: Event):
	var tower: Tower = self
	var target: Unit = event.get_target()
	var level: int = tower.get_level()
	var chance: float = 0.06 + 0.001 * level
	var devour_damage: float = 5000 + 400 * level

	if !tower.calc_chance(chance):
		return

	tower.do_spell_damage(target, devour_damage, tower.calc_spell_crit_no_bonus())
	SFX.sfx_at_unit("DevourEffectArt.mdl", target)
	devour_count += 1
	tower.refresh_auras()

	var devour_stack_duration: float = 6.0 * tower.get_prop_buff_duration()

	await get_tree().create_timer(devour_stack_duration).timeout

	if !Utils.unit_is_valid(tower):
		return

	tower.devour_count -= 1
	tower.refresh_auras()


func sir_kodo_aura_bt_on_refresh(event: Event):
	var buff: Buff = event.get_buff()
	var tower: Tower = buff.get_caster()
	var new_power: int = (100 + 2 * tower.get_level()) * tower.devour_count
	buff.set_power(new_power)
