class_name CreepSlowAura extends BuffType


var slow_aura_effect: BuffType


func _init(parent: Node):
	super("creep_slow_aura", 0, 0, true, parent)

	var draw_below_unit: bool = true
	set_special_effect("res://src/effects/spell_aire_flat.tscn", 0, 1.0, Color.ORANGE, draw_below_unit)
	
	slow_aura_effect = BuffType.create_aura_effect_type("creep_slow_aura_effect", false, self)
	var modifier: Modifier = Modifier.new()
	modifier.add_modification(Modification.Type.MOD_ATTACKSPEED, -0.50, 0.0)
	slow_aura_effect.set_buff_modifier(modifier)
	slow_aura_effect.set_buff_tooltip(tr("ZW9E"))

	add_aura(108, self)
