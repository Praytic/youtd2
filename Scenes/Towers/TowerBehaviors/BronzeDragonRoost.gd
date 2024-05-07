extends TowerBehavior


var bronze_bt: BuffType


func get_ability_info_list() -> Array[AbilityInfo]:
	var list: Array[AbilityInfo] = []
	
	var ability: AbilityInfo = AbilityInfo.new()
	ability.name = "Bronzefication"
	ability.description_short = "Each time this tower damages a unit it has a chance to turn the target's flesh into bronze. The unit is slowed, loses half of its health regeneration, has higher item quality and has more armor.\n"
	ability.description_full = "Each time this tower damages a unit it has a 10% chance to turn the target's flesh into bronze for 5 seconds. The unit is slowed by 50%, loses 50% of its health regeneration, has a 25% higher item quality and has 50% more armor.\n" \
	+ " \n" \
	+ "[color=ORANGE]Level Bonus:[/color]\n" \
	+ "-1% hp regen\n" \
	+ "-0.8% armor\n" \
	+ "+1% item quality\n" \
	+ "+0.4% chance\n"
	list.append(ability)

	return list


func load_triggers(triggers: BuffType):
	triggers.add_event_on_damage(on_damage)


func load_specials(_modifier: Modifier):
	tower.set_attack_style_bounce(6, 0.10)


func tower_init():
	bronze_bt = BuffType.new("bronze_bt", 5, 0.1, false, self)
	var mod: Modifier = Modifier.new()
	mod.add_modification(Modification.Type.MOD_MOVESPEED, -0.5, 0.0)
	mod.add_modification(Modification.Type.MOD_HP_REGEN_PERC, -0.5, -0.01)
	mod.add_modification(Modification.Type.MOD_ARMOR_PERC, 0.5, -0.008)
	mod.add_modification(Modification.Type.MOD_ITEM_QUALITY_ON_DEATH, 0.25, 0.01)
	bronze_bt.set_buff_modifier(mod)
	bronze_bt.set_buff_icon("res://Resources/Textures/GenericIcons/gold_bar.tres")
	bronze_bt.add_event_on_create(bronze_bt_on_create)
	bronze_bt.add_event_on_cleanup(bronze_bt_on_cleanup)
	bronze_bt.set_buff_tooltip("Bronzefication\nReduces movement speed and health regeneration. Increases item quality and armor.")


func on_damage(event: Event):
	var chance: float = 0.1 + 0.004 * tower.get_level()

	if !tower.calc_chance(chance):
		return

	CombatLog.log_ability(tower, event.get_target(), "Bronzefication")

	bronze_bt.apply(tower, event.get_target(), tower.get_level())


func bronze_bt_on_create(event: Event):
	var buff: Buff = event.get_buff()
	var unit: Unit = buff.get_buffed_unit()
	unit.set_sprite_color(Color8(255, 255, 125, 255))


func bronze_bt_on_cleanup(event: Event):
	var buff: Buff = event.get_buff()
	var unit: Unit = buff.get_buffed_unit()
	unit.set_sprite_color(Color8(255, 255, 255, 255))
