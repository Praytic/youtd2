extends TowerBehavior


var entangle_bt: BuffType
var aura_bt: BuffType


func tower_init():
	entangle_bt = CbStun.new("entangle_bt", 1.2, 0, false, self)
	entangle_bt.set_buff_icon("res://resources/icons/generic_icons/ophiucus.tres")
	entangle_bt.add_periodic_event(entangle_bt_periodic, 1.0)
	entangle_bt.set_buff_tooltip(tr("VCJ3"))

	aura_bt = BuffType.create_aura_effect_type("aura_bt", true, self)
	aura_bt.set_buff_icon("res://resources/icons/generic_icons/holy_grail.tres")
	aura_bt.add_event_on_attack(aura_bt_on_attack)
	aura_bt.set_buff_tooltip(tr("VWLB"))


func aura_bt_on_attack(event: Event):
	var buff: Buff = event.get_buff()
	var caster: Tower = buff.get_caster()
	var buffed_tower: Tower = buff.get_buffed_unit()
	var target: Creep = event.get_target()
	var entangle_chance: float = (0.10 + 0.002 * caster.get_level()) * buffed_tower.get_base_attack_speed()
	var target_is_boss: bool = target.get_size() >= CreepSize.enm.BOSS
	var target_is_air: bool = target.get_size() == CreepSize.enm.AIR

	if !caster.calc_chance(entangle_chance):
		return

	if target_is_boss || target_is_air:
		return

	CombatLog.log_ability(caster, target, "Sacred Altar Entangle")

	entangle_bt.apply(caster, target, caster.get_level())


func entangle_bt_periodic(event: Event):
	var buff: Buff = event.get_buff()
	var caster: Tower = buff.get_caster()
	var creep: Unit = buff.get_buffed_unit()
	var damage: float = 700 + 35 * buff.get_level()

	caster.do_spell_damage(creep, damage, caster.calc_spell_crit_no_bonus())
