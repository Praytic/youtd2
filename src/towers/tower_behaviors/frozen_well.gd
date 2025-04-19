extends TowerBehavior


var aura_bt: BuffType
var mist_bt: BuffType


func load_triggers(triggers: BuffType):
	triggers.add_event_on_damage(on_damage)


func tower_init():
	aura_bt = BuffType.create_aura_effect_type("aura_bt", true, self)
	var boekie_frozen_well_aura_mod: Modifier = Modifier.new()
	boekie_frozen_well_aura_mod.add_modification(ModificationType.enm.MOD_BUFF_DURATION, 0.25, 0.004)
	aura_bt.set_buff_modifier(boekie_frozen_well_aura_mod)
	aura_bt.set_buff_icon("res://resources/icons/generic_icons/star_swirl.tres")
	aura_bt.set_buff_tooltip(tr("X6EY"))

	mist_bt = BuffType.new("mist_bt", 10, 0, false, self)
	var boekie_freezing_mist_mod: Modifier = Modifier.new()
	boekie_freezing_mist_mod.add_modification(ModificationType.enm.MOD_MOVESPEED, -0.15, -0.004)
	mist_bt.set_buff_modifier(boekie_freezing_mist_mod)
	mist_bt.set_buff_icon("res://resources/icons/generic_icons/azul_flake.tres")
	mist_bt.set_buff_tooltip(tr("R38D"))


func on_damage(event: Event):
	mist_bt.apply(tower, event.get_target(), tower.get_level())
