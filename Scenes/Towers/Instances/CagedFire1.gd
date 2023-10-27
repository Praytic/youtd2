extends Tower


var cedi_melt_bt: BuffType


func get_tier_stats() -> Dictionary:
	return {
		1: {mod_armor = 1, mod_armor_add = 0.04, periodic_mod_armor = 0.5, periodic_mod_armor_add = 0.02, melt_damage = 20, melt_damage_add = 0.8, periodic_melt_damage_increase = 20},
		2: {mod_armor = 2, mod_armor_add = 0.08, periodic_mod_armor = 1.0, periodic_mod_armor_add = 0.04, melt_damage = 40, melt_damage_add = 1.6, periodic_melt_damage_increase = 40},
	}

const AURA_RANGE: float = 900


func get_ability_description() -> String:
	var aura_range: String = Utils.format_float(AURA_RANGE, 2)
	var mod_armor: String = Utils.format_float(_stats.mod_armor, 2)
	var mod_armor_add: String = Utils.format_float(_stats.mod_armor_add, 2)
	var periodic_mod_armor: String = Utils.format_float(_stats.periodic_mod_armor, 2)
	var periodic_mod_armor_add: String = Utils.format_float(_stats.periodic_mod_armor_add, 2)
	var melt_damage: String = Utils.format_float(_stats.melt_damage, 2)
	var melt_damage_add: String = Utils.format_float(_stats.melt_damage_add, 2)
	var periodic_melt_damage_increase: String = Utils.format_float(_stats.periodic_melt_damage_increase, 2)

	var text: String = ""

	text += "[color=GOLD]Melt[/color]\n"
	text += "The enormous heat of the caged fire decreases the armor of all creeps in %s range by %s and damages them by %s. Each second creeps in %s range around the caged fire lose %s extra armor and the fire damage will increase by %s.\n" % [aura_range, mod_armor, melt_damage, aura_range, periodic_mod_armor, periodic_melt_damage_increase]
	text += " \n"
	text += "[color=ORANGE]Level Bonus:[/color]\n"
	text += "+%s start armor reduction\n" % mod_armor_add
	text += "+%s armor reduction\n" % periodic_mod_armor_add
	text += "+%s damage\n" % melt_damage_add

	return text


func load_specials(modifier: Modifier):
	modifier.add_modification(Modification.Type.MOD_DMG_TO_MAGIC, -0.50, 0.0)
	modifier.add_modification(Modification.Type.MOD_DMG_TO_NATURE, 0.50, 0.01)


func tower_init():
	cedi_melt_bt = BuffType.create_aura_effect_type("cedi_melt_bt", false, self)
	cedi_melt_bt.add_event_on_create(cedi_melt_bt_on_create)
	cedi_melt_bt.add_periodic_event(cedi_melt_bt_on_periodic, 1.0)
	cedi_melt_bt.add_event_on_cleanup(cedi_melt_bt_on_cleanup)
	cedi_melt_bt.set_buff_icon("@@0@@")
	cedi_melt_bt.set_buff_tooltip("Melting\nThis unit is melting; it has decreased armor and is periodically taking damage.")

	var aura: AuraType = AuraType.new()
	aura.aura_range = AURA_RANGE
	aura.target_type = TargetType.new(TargetType.CREEPS)
	aura.target_self = false
	aura.level = 1
	aura.level_add = 0
	aura.power = 1
	aura.power_add = 0
	aura.aura_effect = cedi_melt_bt
	add_aura(aura)


func cedi_melt_bt_on_create(event: Event):
	var buff: Buff = event.get_buff()
	var caster: Unit = buff.get_caster()
	var target: Unit = buff.get_buffed_unit()
	var lvl: int = caster.get_level()
	var current_mod_armor: float = _stats.mod_armor + _stats.mod_armor_add * lvl
	var current_melt_damage: float = _stats.melt_damage + _stats.melt_damage_add * lvl
	buff.user_real = current_mod_armor
	buff.user_real2 = current_melt_damage
	target.modify_property(Modification.Type.MOD_ARMOR, -current_mod_armor)


func cedi_melt_bt_on_periodic(event: Event):
	var buff: Buff = event.get_buff()
	var caster: Unit = buff.get_caster()
	var target: Unit = buff.get_buffed_unit()
	var lvl: int = caster.get_level()
	var mod_armor_increase: float = _stats.periodic_mod_armor + _stats.periodic_mod_armor_add * lvl
	var melt_damage_increase: float = _stats.melt_damage + _stats.melt_damage_add * lvl
	var old_mod_armor: float = buff.user_real
	var current_mod_armor: float = buff.user_real + mod_armor_increase
	var current_melt_damage: float = buff.user_real2 + melt_damage_increase
	buff.user_real = current_mod_armor
	buff.user_real2 = current_melt_damage

	caster.do_spell_damage(target, current_melt_damage, caster.calc_spell_crit_no_bonus())
	target.modify_property(Modification.Type.MOD_ARMOR, old_mod_armor)
	target.modify_property(Modification.Type.MOD_ARMOR, -current_mod_armor)


func cedi_melt_bt_on_cleanup(event: Event):
	var buff: Buff = event.get_buff()
	var target: Unit = buff.get_buffed_unit()
	var current_mod_armor: float = buff.user_real
	target.modify_property(Modification.Type.MOD_ARMOR, current_mod_armor)
