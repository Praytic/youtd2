class_name CreepSpellResistance extends BuffType


func _init(parent: Node):
	super("creep_spell_resistance", 0, 0, true, parent)
	var modifier: Modifier = Modifier.new()
	modifier.add_modification(Modification.Type.MOD_SPELL_DAMAGE_RECEIVED, -0.50, 0.0)
	set_buff_modifier(modifier)
