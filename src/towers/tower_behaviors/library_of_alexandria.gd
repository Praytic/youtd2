extends TowerBehavior


var aura_bt: BuffType
var teachings_bt: BuffType


func load_triggers(triggers: BuffType):
	triggers.add_periodic_event(periodic, 5.0)


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
