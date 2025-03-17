extends TowerBehavior


var aura_bt: BuffType
var teachings_bt: BuffType

const AURA_RANGE: int = 900


func get_ability_info_list_DELETEME() -> Array[AbilityInfo]:
	var list: Array[AbilityInfo] = []
	
	var divine_knowledge: AbilityInfo = AbilityInfo.new()
	divine_knowledge.name = "Divine Knowledge"
	divine_knowledge.icon = "res://resources/icons/holy/white_trinket.tres"
	divine_knowledge.description_short = "This tower periodically grants experience to a random tower in range.\n"
	divine_knowledge.description_full = "Every 5 seconds this tower grants 2 experience to a random tower in 500 range.\n" \
	+ " \n" \
	+ "[color=ORANGE]Level Bonus:[/color]\n" \
	+ "+0.2 experience\n"
	divine_knowledge.radius = 500
	divine_knowledge.target_type = TargetType.new(TargetType.TOWERS)
	list.append(divine_knowledge)

	return list


func load_triggers(triggers: BuffType):
	triggers.add_periodic_event(periodic, 5.0)


func load_specials_DELETEME(modifier: Modifier):
	modifier.add_modification(Modification.Type.MOD_MANA_REGEN_PERC, 0.0, 0.04)


func tower_init():
	aura_bt = BuffType.create_aura_effect_type("aura_bt", true, self)
	var library_aura_mod: Modifier = Modifier.new()
	library_aura_mod.add_modification(Modification.Type.MOD_EXP_GRANTED, 0.30, 0.01)
	aura_bt.set_buff_modifier(library_aura_mod)
	aura_bt.set_buff_icon("res://resources/icons/generic_icons/spell_book.tres")
	aura_bt.set_buff_tooltip("Divine Research Aura\nIncreases experience granted.")

	teachings_bt = BuffType.new("teachings_bt", 10, 0.2, true, self)
	var library_divine_teachings_mod: Modifier = Modifier.new()
	library_divine_teachings_mod.add_modification(Modification.Type.MOD_EXP_RECEIVED, 1.0, 0.02)
	teachings_bt.set_buff_modifier(library_divine_teachings_mod)
	teachings_bt.set_buff_icon("res://resources/icons/generic_icons/spell_book.tres")
	teachings_bt.set_buff_tooltip("Divine Teachings\nIncreases experience received.")


func create_autocasts_DELETEME() -> Array[Autocast]:
	var autocast: Autocast = Autocast.make()

	autocast.title = "Divine Teachings"
	autocast.icon = "res://resources/icons/books/book_02.tres"
	autocast.description_short = "Adds a buff to the target tower which increases the amount of experience the tower gains.\n"
	autocast.description = "Adds a buff to the targeted tower which lasts 10 seconds. The buff increases the amount of experience the tower gains by 100%. This tower gains 2 experience every time it casts this buff.\n" \
	+ " \n" \
	+ "[color=ORANGE]Level Bonus:[/color]\n" \
	+ "+0.2 seconds duration \n" \
	+ "+2% experience gain.\n"
	autocast.caster_art = "res://src/effects/spell_aire.tscn"
	autocast.target_art = "res://src/effects/charm_target.tscn"
	autocast.autocast_type = Autocast.Type.AC_TYPE_ALWAYS_BUFF
	autocast.num_buffs_before_idle = 0
	autocast.cast_range = 500
	autocast.auto_range = 500
	autocast.cooldown = 5
	autocast.mana_cost = 30
	autocast.target_self = false
	autocast.is_extended = false
	autocast.buff_type = teachings_bt
	autocast.buff_target_type = TargetType.new(TargetType.TOWERS)
	autocast.handler = on_autocast

	return [autocast]


func get_aura_types_DELETEME() -> Array[AuraType]:
	var aura: AuraType = AuraType.new()

	aura.name = "Divine Research"
	aura.icon = "res://resources/icons/books/book_08.tres"
	aura.description_short = "Increases experience gain from creeps in range.\n"
	aura.description_full = "Increases the experience gain from creeps in %d range by 30%%.\n" % AURA_RANGE \
	+ " \n" \
	+ "[color=ORANGE]Level Bonus:[/color]\n" \
	+ "+1% experience\n"

	aura.aura_range = AURA_RANGE
	aura.target_type = TargetType.new(TargetType.CREEPS)
	aura.target_self = false
	aura.level = 0
	aura.level_add = 1
	aura.aura_effect = aura_bt
	return [aura]


func periodic(_event: Event):
	var lvl: int = tower.get_level()
	var towers_in_range: Iterate = Iterate.over_units_in_range_of_caster(tower, TargetType.new(TargetType.TOWERS), 500)
	var random_tower: Tower = towers_in_range.next_random()

	if random_tower == null:
		return

	random_tower.add_exp(2 + lvl * 0.2)
	Effect.create_simple_at_unit("res://src/effects/spell_alim.tscn", random_tower)


func on_autocast(event: Event):
	var target: Unit = event.get_target()
	tower.add_exp(2)
	teachings_bt.apply(tower, target, tower.get_level())
