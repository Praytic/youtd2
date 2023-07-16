extends Tower


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

	text += "[color=GOLD]Dark Curse[/color]\n"
	text += "Increases the attack damage target creep receives by %s, the curse lasts 5 seconds.\n" % [damage_increase]
	text += " \n"
	text += "[color=ORANGE]Level Bonus:[/color]\n"
	text += "+0.6% bonusdamage\n"
	text += "+0.1 second duration\n"
	text += " \n"
	text += "Mana cost: 30, 900 range, 5s cooldown\n"

	return text


func on_autocast(event: Event):
	var tower: Tower = self
	var lvl: int = tower.get_level()
	boekie_amp_damage.apply(tower, event.get_target(), _stats.buff_level + 6 * lvl)


func tower_init():
	var m: Modifier = Modifier.new()
	m.add_modification(Modification.Type.MOD_ATK_DAMAGE_RECEIVED, 0.15, 0.001)
	boekie_amp_damage = BuffType.new("boekie_amp_damage", 5, 0.1, false, self)
	boekie_amp_damage.set_buff_modifier(m)
	boekie_amp_damage.set_stacking_group("boekie_amp_damage")
	boekie_amp_damage.set_buff_icon("@@0@@")
	boekie_amp_damage.set_buff_tooltip("Dark Curse\nThis unit is receiving extra attack damage.")

	var autocast: Autocast = Autocast.make()
	autocast.description = get_dark_curse_description()
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
