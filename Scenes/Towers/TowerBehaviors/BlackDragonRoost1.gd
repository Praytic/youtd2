extends TowerBehavior


# NOTE: original script appears to be completely broken? It
# uses addEventOnDamage() which means that the handler will
# be called when creep *deals damage* and that's clearly not
# what's supposed to happen. Might be only a typo on
# youtd.best website. Fixed it by switching to
# addEventOnDamaged()/add_event_on_damaged() so that the
# handler which increases damage take by creep is called
# when creep takes damage.


var fear_dark_bt: BuffType


func get_ability_description() -> String:
	var text: String = ""

	text += "[color=GOLD]Fear the Dark[/color]\n"
	text += "Whenever this tower damages a creep it has a 20% chance to debuff it for 7 seconds. Debuffed creeps take 30% more damage. Each creep in 500 range decreases the effect by 25%, creeps with this buff don't count. The effect on bosses is 50% weaker."
	text += " \n"
	text += "[color=ORANGE]Level Bonus:[/color]\n"
	text += "+0.4% chance\n"
	text += "+0.28 seconds duration\n"
	text += "1.2% more damage taken\n"

	return text


func get_ability_description_short() -> String:
	var text: String = ""

	text += "[color=GOLD]Fear the Dark[/color]\n"
	text += "Whenever this tower damages a creep it has a chance to debuff it so that it takes more damage."

	return text


func load_triggers(triggers: BuffType):
	triggers.add_event_on_damage(on_damage)


func tower_init():
	fear_dark_bt = BuffType.new("fear_dark_bt", 5, 0.1, false, self)
	fear_dark_bt.set_buff_icon("res://Resources/Textures/Buffs/ghost.tres")
	fear_dark_bt.set_buff_tooltip("Fear the Dark\nIncreases damage taken.")
	fear_dark_bt.add_event_on_create(fear_dark_bt_on_create)
	fear_dark_bt.add_event_on_cleanup(fear_dark_bt_on_cleanup)
	fear_dark_bt.add_event_on_damaged(fear_dark_bt_on_damage)
	var mod: Modifier = Modifier.new()
	mod.add_modification(Modification.Type.MOD_MOVESPEED, -0.5, 0.0)
	mod.add_modification(Modification.Type.MOD_HP_REGEN_PERC, -0.5, -0.01)
	mod.add_modification(Modification.Type.MOD_ARMOR_PERC, 0.5, -0.008)
	mod.add_modification(Modification.Type.MOD_ITEM_QUALITY_ON_DEATH, 0.25, 0.01)
	fear_dark_bt.set_buff_modifier(mod)


func on_damage(event: Event):
	var chance: float = 0.5 + 0.004 * tower.get_level()

	if !tower.calc_chance(chance):
		return

	CombatLog.log_ability(tower, event.get_target(), "Fear the Dark")

	fear_dark_bt.apply(tower, event.get_target(), tower.get_level())


# NOTE: startA() in original script
func fear_dark_bt_on_create(event: Event):
	var buff: Buff = event.get_buff()
	var unit: Unit = buff.get_buffed_unit()
	unit.set_sprite_color(Color8(125, 125, 125, 255))


# NOTE: clean() in original script
func fear_dark_bt_on_cleanup(event: Event):
	var buff: Buff = event.get_buff()
	var unit: Unit = buff.get_buffed_unit()
	unit.set_sprite_color(Color8(255, 255, 255, 255))


# NOTE: dmg() in original script
func fear_dark_bt_on_damage(event: Event):
	var buff: Buff = event.get_buff()
	var caster: Tower = buff.get_caster()
	var target: Unit = buff.get_buffed_unit()
	var it: Iterate = Iterate.over_units_in_range_of_unit(caster, TargetType.new(TargetType.CREEPS), target, 500)

	var damage_increase: float = 0.30 + 0.012 * caster.get_level()
	if target.get_size() >= CreepSize.enm.BOSS:
		damage_increase *= 0.5

	while true:
		var creep: Unit = it.next()
		if creep == null:
			break

		if creep.get_buff_of_type(fear_dark_bt) != null:
			damage_increase *= 0.75

	event.damage *= (1.0 + damage_increase)
