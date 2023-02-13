extends Tower


const _tier_stats_map: Dictionary = {
	1: {value = 0.15, value_add = 0.01},
	2: {value = 0.17, value_add = 0.011},
	3: {value = 0.19, value_add = 0.012},
	4: {value = 0.21, value_add = 0.013},
	5: {value = 0.23, value_add = 0.014},
	6: {value = 0.25, value_add = 0.016},
}


func _ready():
#	NOTE: splash values are the same for all tiers
	var warming_up = Buff.new("warming_up")
	warming_up.add_event_handler(Buff.EventType.DAMAGE, self, "on_damage")
	warming_up.apply_to_unit_permanent(self, self, 0, true)


func on_damage(event: Event):
	if true:
	# if calc_bad_chance(0.3 - get_level() * 0.006):
		event.damage = 0
		Utils.display_floating_text_x("Miss", self, Color.red, 0.05, 0.0, 2.0)
