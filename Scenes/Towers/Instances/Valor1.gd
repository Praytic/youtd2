extends Tower


var cedi_valor_wewillnotfall_bt: BuffType
var cedi_valor_light_bt: BuffType
var cedi_valor_lastline_real_bt: BuffType
var cedi_valor_lastline_dummy_bt: BuffType


func get_ability_description() -> String:
	var text: String = ""

	text += "[color=GOLD]Valor's Light[/color]\n"
	text += "Whenever a creep comes within 800 range of this tower it takes an initial 2000 spell damage per second and its movement speed is decreased by 30%. The damage and slow of this ability decay by 50% every second. Lasts 5 seconds.\n"
	text += " \n"
	text += "[color=ORANGE]Level Bonus:[/color]\n"
	text += "+80 spell damage\n"
	text += "+1.2% slow\n"
	text += " \n"

	text += "[color=GOLD]Last Line of Defense[/color]\n"
	text += "Any creep passing this tower twice will take 1% more spell and attack damage for each tower within 400 range of this tower. This effect is goldcost adjusted, towers with a goldcost of 2500 provide the full bonus.\n"
	text += " \n"
	text += "[color=ORANGE]Level Bonus:[/color]\n"
	text += "+0.08% spell and attack damage taken per tower\n"
	text += " \n"

	text += "[color=GOLD]We Will Not Fall! - Aura[/color]\n"
	text += "Increases the attack and spell damage of all towers in 400 range by 0.5% for each percent of lost lives. If the team has more than 100% lives, towers will deal less damage!\n"
	text += " \n"
	text += "[color=ORANGE]Level Bonus:[/color]\n"
	text += "+0.02% more spell and attack damage\n"

	return text


func get_ability_description_short() -> String:
	var text: String = ""

	text += "[color=GOLD]Valor's Light[/color]\n"
	text += "Damages and slows creeps coming in range of this tower.\n"
	text += " \n"

	text += "[color=GOLD]Last Line of Defense[/color]\n"
	text += "Any creep passing this tower twice will take more spell and attack damage.\n"
	text += " \n"

	text += "[color=GOLD]We Will Not Fall! - Aura[/color]\n"
	text += "Increases the attack and spell damage of all towers in range.\n"

	return text


func load_triggers(triggers: BuffType):
	triggers.add_event_on_unit_comes_in_range(on_unit_in_range, 800, TargetType.new(TargetType.CREEPS))


func tower_init():
#	Dummy Buff, to count the times a unit entered
	cedi_valor_lastline_dummy_bt = BuffType.new("cedi_valor_lastline_dummy_bt", -1.0, 0, false, self)
	cedi_valor_lastline_dummy_bt.set_hidden()

#	Real buff, adding the damage bonus.
	cedi_valor_lastline_real_bt = BuffType.new("cedi_valor_lastline_real_bt", -1.0, 0, false, self)
	cedi_valor_lastline_real_bt.set_buff_icon("@@0@@")
	cedi_valor_lastline_real_bt.set_buff_tooltip("Last Line of Defense\nThis unit is going through the Last Line of Defense; it will take extra damage.")

	cedi_valor_wewillnotfall_bt = BuffType.create_aura_effect_type("cedi_valor_wewillnotfall_bt", true, self)
	var cedi_valor_aura_mod: Modifier = Modifier.new()
	cedi_valor_aura_mod.add_modification(Modification.Type.MOD_ARMOR, 0.0, 0.0)
	cedi_valor_wewillnotfall_bt.set_buff_modifier(cedi_valor_aura_mod)
	cedi_valor_wewillnotfall_bt.set_buff_icon("@@1@@")
	cedi_valor_wewillnotfall_bt.add_event_on_create(cedi_valor_wewillnotfall_bt_on_create)
	cedi_valor_wewillnotfall_bt.add_periodic_event(cedi_valor_wewillnotfall_bt_periodic, 15.0)
	cedi_valor_wewillnotfall_bt.add_event_on_cleanup(cedi_valor_wewillnotfall_bt_on_cleanup)
	cedi_valor_wewillnotfall_bt.set_buff_tooltip("We Will Not Fall! Aura\nThis tower is under the effect of We Will Not Fall! Aura; it will deal more damage based on lost portal lives.")

	cedi_valor_light_bt = BuffType.new("cedi_valor_light_bt", 5.0, 0, false, self)
	var cedi_valor_light_mod: Modifier = Modifier.new()
	cedi_valor_light_mod.add_modification(Modification.Type.MOD_MOVESPEED, 0.0, -0.001)
	cedi_valor_light_bt.set_buff_modifier(cedi_valor_light_mod)
	cedi_valor_light_bt.set_buff_icon("@@2@@")
	cedi_valor_light_bt.add_periodic_event(cedi_valor_light_bt_periodic, 1.0)
	cedi_valor_light_bt.set_buff_tooltip("Valor's Light\nThis unit is affected by Valor's Light; it will deal more damage based on lost portal lives.")

func get_aura_types() -> Array[AuraType]:
	var aura: AuraType = AuraType.new()
	aura.aura_range = 400
	aura.target_type = TargetType.new(TargetType.TOWERS)
	aura.target_self = false
	aura.level = 0
	aura.level_add = 1
	aura.power = 0
	aura.power_add = 1
	aura.aura_effect = cedi_valor_wewillnotfall_bt

	return [aura]


func on_unit_in_range(event: Event):
	var tower: Tower = self
	var creep: Unit = event.get_target()

	var valor_buff_level: int = 300 + 12 * tower.get_level()
	var valor_buff: Buff = cedi_valor_light_bt.apply(tower, creep, valor_buff_level)
	valor_buff.user_real = 2000 + 80 * tower.get_level()
	valor_buff.user_int = 0

#	This function is normally called from periodic event
#	handler of buff but call it here for the first time to
#	ensure that the setup has already run.
	cedi_valor_light_bt_adjust_effect(valor_buff)

	var lastline_dummy_buff: Buff = creep.get_buff_of_type(cedi_valor_lastline_dummy_bt)

#	Second time walking past?
	if lastline_dummy_buff != null:
		# Yes!
		lastline_dummy_buff.remove_buff()

		# Apply the last line buff. (Only visuals, effect is permanent, no cleanup required)
		cedi_valor_lastline_real_bt.apply(tower, creep, tower.get_level())

		var it: Iterate = Iterate.over_units_in_range_of_caster(tower, TargetType.new(TargetType.TOWERS), 400)

		# Calculate the amount of additional damage they should take.
		var amount: float = 0.0
		while true:
			var next: Tower = it.next()

			if next == null:
				break

			if next != tower:
				amount += min(next.get_gold_cost() / 2500.0, 1.0) * (0.01 + 0.0008 * tower.get_level())

#		Modify the damage they take.
		creep.modify_property(Modification.Type.MOD_SPELL_DAMAGE_RECEIVED, amount)
		creep.modify_property(Modification.Type.MOD_ATK_DAMAGE_RECEIVED, amount)
	else:
#		No, check if it already has the last line buff
		var lastline_real_buff: Buff = creep.get_buff_of_type(cedi_valor_lastline_real_bt)

		if lastline_real_buff == null:
#			No? Okay, let's add the dummy.
			cedi_valor_lastline_dummy_bt.apply(tower, creep, 0)


func cedi_valor_wewillnotfall_bt_on_create(event: Event):
	var buff: Buff = event.get_buff()
	cedi_valor_wewillnotfall_bt_adjust_effect(buff)


func cedi_valor_wewillnotfall_bt_periodic(event: Event):
	var buff: Buff = event.get_buff()
	cedi_valor_wewillnotfall_bt_adjust_effect(buff)


func cedi_valor_wewillnotfall_bt_adjust_effect(buff: Buff):
	var caster: Unit = buff.get_caster()
	var buffed_unit: Unit = buff.get_buffed_unit()
	var current_bonus: float = buff.user_real
	var new_bonus: float = (100 - PortalLives.get_current()) / 100.0 * (0.5 + 0.02 * caster.get_level())
	var delta: float = new_bonus - current_bonus

	if delta != 0:
		buffed_unit.modify_property(Modification.Type.MOD_SPELL_DAMAGE_DEALT, delta)
		buffed_unit.modify_property(Modification.Type.MOD_DAMAGE_ADD_PERC, delta)
		buff.user_real = new_bonus


func cedi_valor_wewillnotfall_bt_on_cleanup(event: Event):
	var buff: Buff = event.get_buff()
	var buffed_unit: Unit = buff.get_buffed_unit()
	var current_bonus: float = buff.user_real
	buffed_unit.modify_property(Modification.Type.MOD_SPELL_DAMAGE_DEALT, -current_bonus)
	buffed_unit.modify_property(Modification.Type.MOD_DAMAGE_ADD_PERC, -current_bonus)


func cedi_valor_light_bt_periodic(event: Event):
	var buff: Buff = event.get_buff()
	cedi_valor_light_bt_adjust_effect(buff)


func cedi_valor_light_bt_adjust_effect(buff: Buff):
	var caster: Unit = buff.get_caster()
	var creep: Unit = buff.get_buffed_unit()

	if buff.user_int == 0:
#		First time, only slow, flag being first
		buff.user_int = 1
	else:
#		Additional times, decrease slow effect!
		buff.set_power(buff.get_power() / 2)

#	Deal the right amount of damage
	caster.do_spell_damage(creep, buff.user_real, caster.calc_spell_crit_no_bonus())
#	Adjust the amount of damage dealt.
	buff.user_real *= 0.5

#	Some sfx to pretty it up
	var effect: int = Effect.add_special_effect_target("HealTarget.mdl", creep, Unit.BodyPart.ORIGIN)
	Effect.destroy_effect_after_its_over(effect)
