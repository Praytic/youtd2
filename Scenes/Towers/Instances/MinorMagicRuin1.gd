extends Tower


var drol_magic_ruin: BuffType


func _get_tier_stats() -> Dictionary:
	return {
		1: {exp_bonus = 0.05, exp_bonus_add = 0.002},
		2: {exp_bonus = 0.10, exp_bonus_add = 0.004},
		3: {exp_bonus = 0.15, exp_bonus_add = 0.006},
		4: {exp_bonus = 0.20, exp_bonus_add = 0.008},
		5: {exp_bonus = 0.25, exp_bonus_add = 0.010},
		6: {exp_bonus = 0.30, exp_bonus_add = 0.012},
	}


func get_extra_tooltip_text() -> String:
	var exp_bonus: String = String.num(_stats.exp_bonus * 100, 2)
	var exp_bonus_add: String = String.num(_stats.exp_bonus_add * 100, 2)

	var text: String = ""

	text += "[color=GOLD]Illuminate[/color]\n"
	text += "Attacks debuff the target, making it grant %s%% more experience once killed. This effect last 5 seconds.\n" % exp_bonus
	text += "[color=ORANGE]Level Bonus:[/color]\n"
	text += "+%s%% experience\n" % exp_bonus_add
	text += "+0.2 seconds"

	return text


func load_triggers(triggers_buff_type: BuffType):
	triggers_buff_type.add_event_on_damage(_on_damage, 1.0, 0.0)


func tower_init():
	var astral_mod: Modifier = Modifier.new()
	drol_magic_ruin = BuffType.new("drol_magic_ruin", 5, 0, false)
	astral_mod.add_modification(Modification.Type.MOD_EXP_GRANTED, _stats.exp_bonus, _stats.exp_bonus_add)
	drol_magic_ruin.set_buff_modifier(astral_mod)
	drol_magic_ruin.set_buff_icon("@@0@@")
	
	drol_magic_ruin.set_buff_tooltip("Illuminated\nThis unit will grant more experience when killed.")


func _on_damage(event: Event):
	var tower = self

	drol_magic_ruin.apply_custom_timed(tower, event.get_target(), tower.get_level(), 5 + tower.get_level() * 0.2)
