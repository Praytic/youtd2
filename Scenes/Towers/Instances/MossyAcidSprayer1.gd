extends Tower

# TODO: implement visual


# NOTE: values here are pre-multiplied by 1000, so 600 = 0.6
# as final value. That's how it is in original script and we
# stick to original to avoid introducting bugs.
const _stats_map: Dictionary = {
	1: {armor_base = 600, armor_add = 24},
	2: {armor_base = 1200, armor_add = 48},
	3: {armor_base = 2400, armor_add = 96},
	4: {armor_base = 4800, armor_add = 192},
	5: {armor_base = 9600, armor_add = 384},
}


func _ready():
	var bounce_attack_buff = BounceAttack.new(3, 0.15)
	bounce_attack_buff.apply_to_unit_permanent(self, self, 0, true)

	var on_damage_buff: Buff = Buff.new("on_damage_buff")
	on_damage_buff.add_event_handler(Buff.EventType.DAMAGE, self, "_on_damage")
	on_damage_buff.apply_to_unit_permanent(self, self, 0, false)


func _on_damage(event: Event):
	var tower = self
	var tier: int = get_tier()
	var stats = _stats_map[tier]

	var m: Modifier = Modifier.new()
	m.add_modification(Modification.Type.MOD_ARMOR, 0.0, -0.001)
	var cedi_acidarmor = Buff.new("cedi_acidarmor")
	cedi_acidarmor.set_buff_icon("@@0@@")
	cedi_acidarmor.set_buff_modifier(m)

	cedi_acidarmor.apply_to_unit(tower, event.get_target(), stats.armor_base + tower.get_level() * stats.armor_add, 3.0 + 0.12 * tower.get_level(), 0.0, false)
