extends TowerBehavior


# NOTE: fixed error in original script where "Time Field"
# buff was unfriendly.


var aura_bt: BuffType
var time_field_bt: BuffType
var multiboard: MultiboardValues
var exp_exchanged: int


func get_ability_info_list() -> Array[AbilityInfo]:
	var list: Array[AbilityInfo] = []
	
	var future: AbilityInfo = AbilityInfo.new()
	future.name = "Future Knowledge"
	future.description_short = "The Manipulator travels into the future to learn more and returns to where he left every 10 seconds.\n"
	future.description_full = "The Manipulator travels into the future to learn more and returns to where he left every 10 seconds, increasing his experience by 2. If he has 700 or more exp then he will exchange 50 experience for 5% extra spell damage. If the Manipulator is replaced by another tower, this process is reversed and all experience refunded.\n"
	list.append(future)

	var time_twist: AbilityInfo = AbilityInfo.new()
	time_twist.name = "Time Twist - Aura"
	time_twist.description_short = "The Manipulator reaches into the timestream and brings bonuses to nearby towers.\n"
	time_twist.description_full = "The Manipulator reaches into the timestream and twists it causing future and past events to occur in the present, granting towers in 240 range:\n" \
	+ "+10% experience gain\n" \
	+ "+10% attack speed\n" \
	+ "+5% mana regen\n" \
	+ "+12.5% buff duration \n" \
	+ " \n" \
	+ "[color=ORANGE]Level Bonus:[/color]\n" \
	+ "+1.6% exp gain\n" \
	+ "+1% attack speed\n" \
	+ "+2% mana regen\n" \
	+ "+1.5% buff duration\n"
	list.append(time_twist)

	return list


func get_autocast_description() -> String:
	var text: String = ""

	text += "The Manipulator creates a field of time that inflicts future injuries upon creatures around him dealing 1500 damage every second for 10 seconds. This ability benefits from the buff duration bonus of Time Twist."

	return text


func get_autocast_description_short() -> String:
	var text: String = ""

	text += "The Manipulator creates a field of time that inflicts future injuries upon creatures around him."

	return text


func load_triggers(triggers: BuffType):
	triggers.add_periodic_event(periodic, 10)


func tower_init():
	time_field_bt = BuffType.new("time_field_bt", 10, 0, true, self)
	time_field_bt.set_special_effect("EnergyField.mdl", 150, 5.0)
	time_field_bt.add_periodic_event(time_field_bt_periodic, 1.0)
	time_field_bt.set_buff_icon("res://Resources/Textures/GenericIcons/rss.tres")
	time_field_bt.set_buff_tooltip("Time Field\nDeals future damage to nearby creeps.")

	aura_bt = BuffType.create_aura_effect_type("aura_bt", true, self)
	var aura_bt_mod: Modifier = Modifier.new()
	aura_bt_mod.add_modification(Modification.Type.MOD_EXP_RECEIVED, 0.1, 0.016)
	aura_bt_mod.add_modification(Modification.Type.MOD_ATTACKSPEED, 0.1, 0.01)
	aura_bt_mod.add_modification(Modification.Type.MOD_MANA_REGEN_PERC, 0.05, 0.02)
	aura_bt_mod.add_modification(Modification.Type.MOD_BUFF_DURATION, 0.125, 0.015)
	aura_bt.set_buff_modifier(aura_bt_mod)
	aura_bt.set_buff_icon("res://Resources/Textures/GenericIcons/electric.tres")
	aura_bt.set_buff_tooltip("Time Twist Aura\nIncreases experience gained, attack speed, mana regen and buff duration.")

	multiboard = MultiboardValues.new(1)
	multiboard.set_key(0, "Exp Exchanged")

	var autocast: Autocast = Autocast.make()
	autocast.title = "Time Field"
	autocast.description = get_autocast_description()
	autocast.description_short = get_autocast_description_short()
	autocast.icon = "res://Resources/Textures/AutocastIcons/compass.tres"
	autocast.caster_art = "DrainCaster.mdl"
	autocast.target_art = ""
	autocast.autocast_type = Autocast.Type.AC_TYPE_OFFENSIVE_IMMEDIATE
	autocast.num_buffs_before_idle = 1
	autocast.cast_range = 950
	autocast.auto_range = 925
	autocast.cooldown = 30
	autocast.mana_cost = 500
	autocast.target_self = true
	autocast.is_extended = false
	autocast.buff_type = time_field_bt
	autocast.target_type = TargetType.new(TargetType.CREEPS)
	autocast.handler = on_autocast
	tower.add_autocast(autocast)


func get_aura_types() -> Array[AuraType]:
	var aura: AuraType = AuraType.new()
	aura.aura_range = 240
	aura.target_type = TargetType.new(TargetType.TOWERS)
	aura.target_self = true
	aura.level = 0
	aura.level_add = 1
	aura.power = 0
	aura.power_add = 1
	aura.aura_effect = aura_bt

	return [aura]


func on_create(_preceding: Tower):
	exp_exchanged = 0


func on_destruct():
	tower.add_exp_flat(exp_exchanged)


func on_tower_details() -> MultiboardValues:
	var exp_exchanged_string: String = str(exp_exchanged)
	multiboard.set_value(0, exp_exchanged_string)

	return multiboard


func periodic(_event: Event):
	if tower.get_exp() >= 700:
		tower.remove_exp_flat(50)
		exp_exchanged += 50
		tower.modify_property(Modification.Type.MOD_SPELL_DAMAGE_DEALT, 0.05)
		SFX.sfx_on_unit("CharmTarget.mdl", tower, Unit.BodyPart.OVERHEAD)
	else:
		tower.add_exp(2)
		SFX.sfx_on_unit("BlinkTarget.mdl", tower, Unit.BodyPart.ORIGIN)


func on_autocast(_event: Event):
	time_field_bt.apply(tower, tower, tower.get_level())


# NOTE: "MajFieldDamage()" in original script
func time_field_bt_periodic(event: Event):
	var buff: Buff = event.get_buff()
	var caster: Tower = buff.get_caster()
	var damage: float = 1500 + 75 * buff.get_level()

	caster.do_spell_damage_pb_aoe(950, damage, caster.calc_spell_crit_no_bonus(), 0.0)
