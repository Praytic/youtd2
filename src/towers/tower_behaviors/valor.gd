extends TowerBehavior


var wewillnotfall_bt: BuffType
var valor_light_bt: BuffType
var lastline_real_bt: BuffType
var lastline_dummy_bt: BuffType


func load_triggers(triggers: BuffType):
	triggers.add_event_on_unit_comes_in_range(on_unit_in_range, 800, TargetType.new(TargetType.CREEPS))


func tower_init():
#	Dummy Buff, to count the times a unit entered
	lastline_dummy_bt = BuffType.new("lastline_dummy_bt", -1.0, 0, false, self)
	lastline_dummy_bt.set_hidden()

#	Real buff, adding the damage bonus.
	lastline_real_bt = BuffType.new("lastline_real_bt", -1.0, 0, false, self)
	lastline_real_bt.set_buff_icon("res://resources/icons/generic_icons/semi_closed_eye.tres")
	lastline_real_bt.set_buff_tooltip("Last Line of Defense\nIncreases damage taken.")

	wewillnotfall_bt = BuffType.create_aura_effect_type("wewillnotfall_bt", true, self)
	wewillnotfall_bt.set_buff_icon("res://resources/icons/generic_icons/shiny_omega.tres")
	wewillnotfall_bt.add_event_on_create(wewillnotfall_bt_on_create)
	wewillnotfall_bt.add_periodic_event(wewillnotfall_bt_periodic, 15.0)
	wewillnotfall_bt.add_event_on_cleanup(wewillnotfall_bt_on_cleanup)
	wewillnotfall_bt.set_buff_tooltip("We Will Not Fall! Aura\nIncreases damage dealt based on lost portal lives.")

	valor_light_bt = BuffType.new("valor_light_bt", 5.0, 0, false, self)
	var cedi_valor_light_mod: Modifier = Modifier.new()
	cedi_valor_light_mod.add_modification(Modification.Type.MOD_MOVESPEED, 0.0, -0.001)
	valor_light_bt.set_buff_modifier(cedi_valor_light_mod)
	valor_light_bt.set_buff_icon("res://resources/icons/generic_icons/foot_trip.tres")
	valor_light_bt.add_periodic_event(valor_light_bt_periodic, 1.0)
	valor_light_bt.set_buff_tooltip("Valor's Light\nReduces movement speed.")


func on_unit_in_range(event: Event):
	var creep: Unit = event.get_target()

	var valor_buff_level: int = 300 + 12 * tower.get_level()
	var valor_buff: Buff = valor_light_bt.apply(tower, creep, valor_buff_level)
	valor_buff.user_real = 2000 + 80 * tower.get_level()
	valor_buff.user_int = 0

#	This function is normally called from periodic event
#	handler of buff but call it here for the first time to
#	ensure that the setup has already run.
	valor_light_bt_adjust_effect(valor_buff)

	var lastline_dummy_buff: Buff = creep.get_buff_of_type(lastline_dummy_bt)

#	Second time walking past?
	if lastline_dummy_buff != null:
		# Yes!
		lastline_dummy_buff.remove_buff()

		# Apply the last line buff. (Only visuals, effect is permanent, no cleanup required)
		lastline_real_bt.apply(tower, creep, tower.get_level())

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
		var lastline_real_buff: Buff = creep.get_buff_of_type(lastline_real_bt)

		if lastline_real_buff == null:
#			No? Okay, let's add the dummy.
			lastline_dummy_bt.apply(tower, creep, 0)


func wewillnotfall_bt_on_create(event: Event):
	var buff: Buff = event.get_buff()
	wewillnotfall_bt_adjust_effect(buff)


func wewillnotfall_bt_periodic(event: Event):
	var buff: Buff = event.get_buff()
	wewillnotfall_bt_adjust_effect(buff)


func wewillnotfall_bt_adjust_effect(buff: Buff):
	var caster: Unit = buff.get_caster()
	var buffed_unit: Unit = buff.get_buffed_unit()
	var current_bonus: float = buff.user_real
	var new_bonus: float = (100 - tower.get_player().get_team().get_lives_percent()) / 100.0 * (0.5 + 0.02 * caster.get_level())
	var delta: float = new_bonus - current_bonus

	if delta != 0:
		buffed_unit.modify_property(Modification.Type.MOD_SPELL_DAMAGE_DEALT, delta)
		buffed_unit.modify_property(Modification.Type.MOD_DAMAGE_ADD_PERC, delta)
		buff.user_real = new_bonus


func wewillnotfall_bt_on_cleanup(event: Event):
	var buff: Buff = event.get_buff()
	var buffed_unit: Unit = buff.get_buffed_unit()
	var current_bonus: float = buff.user_real
	buffed_unit.modify_property(Modification.Type.MOD_SPELL_DAMAGE_DEALT, -current_bonus)
	buffed_unit.modify_property(Modification.Type.MOD_DAMAGE_ADD_PERC, -current_bonus)


func valor_light_bt_periodic(event: Event):
	var buff: Buff = event.get_buff()
	valor_light_bt_adjust_effect(buff)


func valor_light_bt_adjust_effect(buff: Buff):
	var caster: Unit = buff.get_caster()
	var creep: Unit = buff.get_buffed_unit()

	if buff.user_int == 0:
#		First time, only slow, flag being first
		buff.user_int = 1
	else:
#		Additional times, decrease slow effect!
		buff.set_level(buff.get_level() / 2)

#	Deal the right amount of damage
	caster.do_spell_damage(creep, buff.user_real, caster.calc_spell_crit_no_bonus())
#	Adjust the amount of damage dealt.
	buff.user_real *= 0.5

#	Some sfx to pretty it up
	Effect.create_simple_at_unit_attached("res://src/effects/spell_aiil.tscn", creep, Unit.BodyPart.CHEST)
