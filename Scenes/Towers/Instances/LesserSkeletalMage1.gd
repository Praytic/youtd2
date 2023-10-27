extends Tower


# NOTE: fixed bug in original script where buff was lasting
# too long because level passed to apply() is much greater
# than tower.get_level() and was multiplied 0.1. Fixed by
# switching to apply_custom_timed().


var boekie_amp_damage: BuffType


func get_tier_stats() -> Dictionary:
	return {
		1: {buff_level = 0},
		2: {buff_level = 80},
		3: {buff_level = 140},
		4: {buff_level = 210},
	}


func get_dark_curse_description() -> String:
	var damage_increase: String = Utils.format_percent(0.15 + _stats.buff_level * 0.001, 0)

	var text: String = ""

	text += "Increases the attack damage target creep receives by %s, the curse lasts 5 seconds.\n" % [damage_increase]
	text += " \n"
	text += "[color=ORANGE]Level Bonus:[/color]\n"
	text += "+0.6% bonusdamage\n"
	text += "+0.1 second duration\n"

	return text


func get_dark_curse_description_short() -> String:
	var text: String = ""

	text += "Causes the target creep to receive more attack damage.\n"

	return text


func on_autocast(event: Event):
	var tower: Tower = self
	var lvl: int = tower.get_level()
	var buff_duration: float = 5 + 0.1 * lvl
	boekie_amp_damage.apply_custom_timed(tower, event.get_target(), _stats.buff_level + 6 * lvl, buff_duration)


func tower_init():
	var m: Modifier = Modifier.new()
	m.add_modification(Modification.Type.MOD_ATK_DAMAGE_RECEIVED, 0.15, 0.001)
	boekie_amp_damage = BuffType.new("boekie_amp_damage", 0, 0, false, self)
	boekie_amp_damage.set_buff_modifier(m)
	boekie_amp_damage.set_stacking_group("boekie_amp_damage")
	boekie_amp_damage.set_buff_icon("@@0@@")
	boekie_amp_damage.set_buff_tooltip("Dark Curse\nThis unit is under the effect of Dark Curse; it will receive more damage from attacks.")

	var autocast: Autocast = Autocast.make()
	autocast.title = "Dark Curse"
	autocast.description = get_dark_curse_description()
	autocast.description_short = get_dark_curse_description_short()
	autocast.icon = "res://Resources/Textures/UI/Icons/gold_icon.tres"
	autocast.caster_art = ""
	autocast.num_buffs_before_idle = 3
	autocast.autocast_type = Autocast.Type.AC_TYPE_OFFENSIVE_BUFF
	autocast.cast_range = 900
	autocast.target_self = false
	autocast.target_art = ""
	autocast.cooldown = 5
	autocast.is_extended = false
	autocast.mana_cost = 30
	autocast.buff_type = boekie_amp_damage
	autocast.target_type = TargetType.new(TargetType.CREEPS)
	autocast.auto_range = 900
	autocast.handler = on_autocast
	add_autocast(autocast)
