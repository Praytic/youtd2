extends Tower

# TODO: implement visual

var cedi_acidarmor: BuffType

# NOTE: values here are pre-multiplied by 1000, so 600 = 0.6
# as final value. That's how it is in original script and we
# stick to original to avoid introducting bugs.
func _get_tier_stats() -> Dictionary:
	return {
		1: {armor_base = 600, armor_add = 24},
		2: {armor_base = 1200, armor_add = 48},
		3: {armor_base = 2400, armor_add = 96},
		4: {armor_base = 4800, armor_add = 192},
		5: {armor_base = 9600, armor_add = 384},
	}


func load_triggers(triggers_buff_type: BuffType):
	triggers_buff_type.add_event_on_damage(self, "_on_damage", 1.0, 0.0)


func tower_init():
	_set_attack_style_bounce(1, 0.15)

	var m: Modifier = Modifier.new()
	m.add_modification(Modification.Type.MOD_ARMOR, 0.0, -0.001)
	cedi_acidarmor = BuffType.new("cedi_acidarmor", 3.0, 0.12, false)
	cedi_acidarmor.set_buff_icon("@@0@@")
	cedi_acidarmor.set_buff_modifier(m)


func _on_damage(event: Event):
	var tower = self

	cedi_acidarmor.apply_custom_timed(tower, event.get_target(), _stats.armor_base + tower.get_level() * _stats.armor_add, 3.0 + 0.12 * tower.get_level())
