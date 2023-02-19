extends Tower


# TODO: implement visual


const _stats_map: Dictionary = {
	1: {exp_bonus = 0.05, exp_bonus_add = 0.002},
	2: {exp_bonus = 0.10, exp_bonus_add = 0.004},
	3: {exp_bonus = 0.15, exp_bonus_add = 0.006},
	4: {exp_bonus = 0.20, exp_bonus_add = 0.008},
	5: {exp_bonus = 0.25, exp_bonus_add = 0.010},
	6: {exp_bonus = 0.30, exp_bonus_add = 0.012},
}


func _ready():
	var on_damage_buff: Buff = Buff.new("")
	on_damage_buff.add_event_handler(Buff.EventType.DAMAGE, self, "_on_damage")
	on_damage_buff.apply_to_unit_permanent(self, self, 0, false)


func _on_damage(event: Event):
	var tower = self
	var tier: int = get_tier()
	var stats = _stats_map[tier]

	var astral_mod: Modifier = Modifier.new()
	var drol_magic_ruin = Buff.new("drol_magic_ruin")
	astral_mod.add_modification(Modification.Type.MOD_EXP_GRANTED, stats.exp_bonus, stats.exp_bonus_add)
	drol_magic_ruin.set_buff_modifier(astral_mod)
	drol_magic_ruin.set_buff_icon("@@0@@")

	drol_magic_ruin.apply_to_unit(tower, event.get_target(), tower.get_level(), 5 + tower.get_level() * 0.2, 0.0, false)
