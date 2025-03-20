extends ItemBehavior


var chain_lightning_st: SpellType
var stun_bt: BuffType


func load_triggers(triggers: BuffType):
	triggers.add_event_on_attack(on_attack)


# NOTE: drol_chainStun() in original script
func chain_lightning_st_on_damage(event: Event, d: DummyUnit):
	var creep: Creep = event.get_target()
	var creep_category: CreepCategory.enm = creep.get_category()

	if creep_category == CreepCategory.enm.UNDEAD || creep_category == CreepCategory.enm.ORC:
		stun_bt.apply_only_timed(d.get_caster(), event.get_target(), 0.5)


func item_init():
	stun_bt = CbStun.new("stun_bt", 0, 0, false, self)
	
	chain_lightning_st = SpellType.new(SpellType.Name.CHAIN_LIGHTNING, 5.0, self)
	chain_lightning_st.set_damage_event(chain_lightning_st_on_damage)
	chain_lightning_st.data.chain_lightning.damage = 250
	chain_lightning_st.data.chain_lightning.damage_reduction = 0.25
	chain_lightning_st.data.chain_lightning.chain_count = 3


func on_attack(event: Event):
	var tower: Tower = item.get_carrier()
	var speed: float = tower.get_base_attack_speed()

	if tower.calc_chance(0.125 * speed):
		CombatLog.log_item_ability(item, event.get_target(), "Purify")
		chain_lightning_st.target_cast_from_caster(tower, event.get_target(), 1, tower.calc_spell_crit_no_bonus())
