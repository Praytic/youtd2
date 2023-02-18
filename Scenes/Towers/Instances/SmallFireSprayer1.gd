extends Tower

# TODO: implement visual

const _stats_map: Dictionary = {
	1: {attack_speed = 0.03, miss_chance_add = 0.008},
	2: {attack_speed = 0.03, miss_chance_add = 0.009},
	3: {attack_speed = 0.03, miss_chance_add = 0.010},
	4: {attack_speed = 0.03, miss_chance_add = 0.011},
	5: {attack_speed = 0.03, miss_chance_add = 0.012},
	6: {attack_speed = 0.03, miss_chance_add = 0.013},
}


func _ready():
	var tier: int = get_tier()
	var stats = _stats_map[tier]

	var spray_and_pray = Buff.new("spray_and_pray")
	spray_and_pray.add_event_handler(Buff.EventType.DAMAGE, self, "on_damage")
	spray_and_pray.apply_to_unit_permanent(self, self, 0, true)

	var specials_modifier: Modifier = Modifier.new()
	specials_modifier.add_modification(Modification.Type.MOD_ATTACK_SPEED, 0, -stats.attack_speed)
	add_modifier(specials_modifier)


func on_damage(event: Event):
	var tower = self
	var tier: int = get_tier()
	var stats = _stats_map[tier]

	if tower.calc_bad_chance(0.33 - stats.miss_chance_add * tower.get_level()):
		event.damage = 0
		Utils.display_floating_text_x("Miss", tower, Color.red, 0.05, 0.0, 2.0)
