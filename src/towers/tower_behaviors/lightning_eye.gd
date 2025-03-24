extends TowerBehavior


var aura_bt: BuffType
var forklight_st: SpellType


func load_triggers(triggers: BuffType):
	triggers.add_event_on_attack(on_attack)


func tower_init():
	aura_bt = BuffType.create_aura_effect_type("aura_bt", true, self)
	aura_bt.set_buff_icon("res://resources/icons/generic_icons/rss.tres")
	aura_bt.add_event_on_damage(aura_bt_on_damage)
	aura_bt.set_buff_tooltip(tr("AUDO"))

	forklight_st = SpellType.new(SpellType.Name.FORKED_LIGHTNING, 1, self)
	forklight_st.data.forked_lightning.damage = 1.0
	forklight_st.data.forked_lightning.target_count = 3


func on_attack(event: Event):
	var creep: Creep = event.get_target()
	var creep_health: float = creep.get_health()
	var tower_mana: float = tower.get_mana()
	var level: int = tower.get_level()
	var glare_damage: float = 500 + 120 * level + 0.015 * creep_health

	if tower_mana < 40:
		return

	tower.subtract_mana(40, false)

	forklight_st.target_cast_from_caster(tower, creep, glare_damage, tower.calc_spell_crit_no_bonus())


func aura_bt_on_damage(event: Event):
	var target: Unit = event.get_target()
	var damage_multiplier: float = 1.2 + 0.01 * tower.get_level()

	if target.is_immune():
		event.damage *= damage_multiplier
