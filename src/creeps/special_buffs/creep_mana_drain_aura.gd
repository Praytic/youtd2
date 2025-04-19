class_name CreepManaDrainAura extends BuffType


var slow_aura_effect: BuffType


func _init(parent: Node):
	super("creep_mana_drain_aura", 0, 0, true, parent)

	var draw_below_unit: bool = true
	set_special_effect("res://src/effects/spell_aire_flat.tscn", 0, 1.0, Color.SKY_BLUE, draw_below_unit)

	slow_aura_effect = BuffType.create_aura_effect_type("creep_slow_aura_effect", false, self)
	var modifier: Modifier = Modifier.new()
	modifier.add_modification(ModificationType.enm.MOD_MANA_REGEN_PERC, -2.0, 0.0)
	slow_aura_effect.set_buff_modifier(modifier)
	slow_aura_effect.set_buff_tooltip(tr("RTAD"))

	add_aura(105, self)
