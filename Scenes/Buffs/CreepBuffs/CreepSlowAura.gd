class_name CreepSlowAura extends BuffType


var slow_aura_effect: BuffType


func _init(parent: Node):
	super("creep_slow_aura", 0, 0, true, parent)

	slow_aura_effect = BuffType.create_aura_effect_type("creep_slow_aura_effect", false, self)
	var modifier: Modifier = Modifier.new()
	modifier.add_modification(Modification.Type.MOD_ATTACKSPEED, -0.50, 0.0)
	slow_aura_effect.set_buff_modifier(modifier)
	slow_aura_effect.set_buff_tooltip("Slowed\nThis tower has been slowed by a nearby creep. It's attackspeed is reduced by 50%.")

	var aura: AuraType = AuraType.new()
	aura.power_add = 0
	aura.level_add = 0
	aura.target_type = TargetType.new(TargetType.TOWERS)
	aura.level = 0
	aura.aura_effect = slow_aura_effect
	aura.power = 0
	aura.target_self = false
	aura.aura_range = 800

	add_aura(aura)
