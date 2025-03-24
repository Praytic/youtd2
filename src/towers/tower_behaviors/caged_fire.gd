extends TowerBehavior


var melt_bt: BuffType


func get_tier_stats() -> Dictionary:
	return {
		1: {mod_armor = 1, mod_armor_add = 0.04, periodic_mod_armor = 0.5, periodic_mod_armor_add = 0.02, melt_damage = 20, melt_damage_add = 0.8, periodic_melt_damage_increase = 20},
		2: {mod_armor = 2, mod_armor_add = 0.08, periodic_mod_armor = 1.0, periodic_mod_armor_add = 0.04, melt_damage = 40, melt_damage_add = 1.6, periodic_melt_damage_increase = 40},
	}

const AURA_RANGE: int = 900


func tower_init():
	melt_bt = BuffType.create_aura_effect_type("melt_bt", false, self)
	melt_bt.add_event_on_create(melt_bt_on_create)
	melt_bt.add_periodic_event(melt_bt_on_periodic, 1.0)
	melt_bt.add_event_on_cleanup(melt_bt_on_cleanup)
	melt_bt.set_buff_icon("res://resources/icons/generic_icons/open_wound.tres")
	melt_bt.set_buff_tooltip(tr("JD4J"))


func melt_bt_on_create(event: Event):
	var buff: Buff = event.get_buff()
	var caster: Unit = buff.get_caster()
	var target: Unit = buff.get_buffed_unit()
	var lvl: int = caster.get_level()
	var current_mod_armor: float = _stats.mod_armor + _stats.mod_armor_add * lvl
	var current_melt_damage: float = _stats.melt_damage + _stats.melt_damage_add * lvl
	buff.user_real = current_mod_armor
	buff.user_real2 = current_melt_damage
	target.modify_property(Modification.Type.MOD_ARMOR, -current_mod_armor)


func melt_bt_on_periodic(event: Event):
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


func melt_bt_on_cleanup(event: Event):
	var buff: Buff = event.get_buff()
	var target: Unit = buff.get_buffed_unit()
	var current_mod_armor: float = buff.user_real
	target.modify_property(Modification.Type.MOD_ARMOR, current_mod_armor)
