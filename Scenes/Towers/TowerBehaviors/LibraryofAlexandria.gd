extends TowerBehavior


var aura_bt: BuffType
var teachings_bt: BuffType


func get_ability_info_list() -> Array[AbilityInfo]:
	var list: Array[AbilityInfo] = []
	
	var divine_knowledge: AbilityInfo = AbilityInfo.new()
	divine_knowledge.name = "Divine Knowledge"
	divine_knowledge.description_short = "This tower periodically grants experience to a random tower in range.\n"
	divine_knowledge.description_full = "Every 5 seconds this tower grants 2 experience to a random tower in 500 range.\n" \
	+ " \n" \
	+ "[color=ORANGE]Level Bonus:[/color]\n" \
	+ "+0.2 experience\n"
	list.append(divine_knowledge)

	var divine_research: AbilityInfo = AbilityInfo.new()
	divine_research.name = "Divine Research - Aura"
	divine_research.description_short = "Increases experience gain from creeps in range.\n"
	divine_research.description_full = "Increases the experience gain from creeps in 900 range by 30%.\n" \
	+ " \n" \
	+ "[color=ORANGE]Level Bonus:[/color]\n" \
	+ "+1% experience\n"
	list.append(divine_research)

	return list


func get_autocast_description() -> String:
	var text: String = ""

	text += "Adds a buff to the targeted tower which lasts 10 seconds. The buff increases the amount of experience the tower gains by 100%. This tower gains 2 experience every time it casts this buff.\n"
	text += " \n"
	text += "[color=ORANGE]Level Bonus:[/color]\n"
	text += "+0.2 seconds duration \n"
	text += "+2% experience gain.\n"

	return text


func get_autocast_description_short() -> String:
	var text: String = ""

	text += "Adds a buff to the target tower which increases the amount of experience the tower gains.\n"

	return text


func load_triggers(triggers: BuffType):
	triggers.add_periodic_event(periodic, 5.0)


func load_specials(modifier: Modifier):
	modifier.add_modification(Modification.Type.MOD_MANA_REGEN_PERC, 0.0, 0.04)


func get_ability_ranges() -> Array[RangeData]:
	return [RangeData.new("Divine Teachings", 500, TargetType.new(TargetType.TOWERS)), RangeData.new("Divine Knowledge", 500, TargetType.new(TargetType.TOWERS))]


func tower_init():
	aura_bt = BuffType.create_aura_effect_type("aura_bt", true, self)
	var library_aura_mod: Modifier = Modifier.new()
	library_aura_mod.add_modification(Modification.Type.MOD_EXP_GRANTED, 0.30, 0.01)
	aura_bt.set_buff_modifier(library_aura_mod)
	aura_bt.set_buff_icon("res://Resources/Icons/GenericIcons/spell_book.tres")
	aura_bt.set_buff_tooltip("Divine Research Aura\nIncreases experience granted.")

	teachings_bt = BuffType.new("teachings_bt", 10, 0.2, true, self)
	var library_divine_teachings_mod: Modifier = Modifier.new()
	library_divine_teachings_mod.add_modification(Modification.Type.MOD_EXP_RECEIVED, 1.0, 0.02)
	teachings_bt.set_buff_modifier(library_divine_teachings_mod)
	teachings_bt.set_buff_icon("res://Resources/Icons/GenericIcons/spell_book.tres")
	teachings_bt.set_buff_tooltip("Divine Teachings\nIncreases experience received.")

	var autocast: Autocast = Autocast.make()
	autocast.title = "Divine Teachings"
	autocast.description = get_autocast_description()
	autocast.description_short = get_autocast_description_short()
	autocast.icon = "res://Resources/Icons/ItemIcons/arcane_book_of_power.tres"
	autocast.caster_art = "AIimTarget.mdl"
	autocast.target_art = "CharmTarget.mdl"
	autocast.autocast_type = Autocast.Type.AC_TYPE_ALWAYS_BUFF
	autocast.num_buffs_before_idle = 0
	autocast.cast_range = 500
	autocast.auto_range = 500
	autocast.cooldown = 5
	autocast.mana_cost = 30
	autocast.target_self = false
	autocast.is_extended = false
	autocast.buff_type = teachings_bt
	autocast.target_type = TargetType.new(TargetType.TOWERS)
	autocast.handler = on_autocast
	tower.add_autocast(autocast)


func get_aura_types() -> Array[AuraType]:
	var aura: AuraType = AuraType.new()
	aura.aura_range = 900
	aura.target_type = TargetType.new(TargetType.CREEPS)
	aura.target_self = false
	aura.level = 0
	aura.level_add = 1
	aura.power = 0
	aura.power_add = 1
	aura.aura_effect = aura_bt
	return [aura]


func periodic(_event: Event):
	var lvl: int = tower.get_level()
	var towers_in_range: Iterate = Iterate.over_units_in_range_of_caster(tower, TargetType.new(TargetType.TOWERS), 500)
	var random_tower: Tower = towers_in_range.next_random()

	if random_tower == null:
		return

	random_tower.add_exp(2 + lvl * 0.2)
	SFX.sfx_at_unit("InvisibilityTarget.mdl", random_tower)


func on_autocast(event: Event):
	var target: Unit = event.get_target()
	tower.add_exp(2)
	teachings_bt.apply(tower, target, tower.get_level())
