extends Tower


# NOTE: changed the script a bit. Original script
# implementes nova delay via periodic events. Changed to use
# await instead.


var boekie_icy_spirit_buff: BuffType


func get_tier_stats() -> Dictionary:
	return {
		1: {nova_dmg = 350, nova_dmg_add = 17.5},
		2: {nova_dmg = 910, nova_dmg_add = 45.5},
		3: {nova_dmg = 2100, nova_dmg_add = 105},
	}


func get_extra_tooltip_text() -> String:
	var nova_dmg: String = Utils.format_float(_stats.nova_dmg, 2)
	var nova_dmg_add: String = Utils.format_float(_stats.nova_dmg_add, 2)

	var text: String = ""

	text += "[color=GOLD]Nova Storm[/color]\n"
	text += "When this tower attacks there is a 25%% chance to hit 3 creeps in 900 range around it with ice novas. A nova hits all creeps in 200 AoE dealing %s spelldamage at the centre, dropping off to 50%% at the sides. Also slows by 12.5%% for 4 seconds.\n" % nova_dmg
	text += " \n"
	text += "[color=ORANGE]Level Bonus:[/color]\n"
	text += "+%s spelldamage\n" % nova_dmg_add
	text += "+0.5% chance\n"
	text += "+0.5% slow \n"
	text += "+1 nova at lvl 15 and 25\n"

	return text


func load_triggers(triggers: BuffType):
	triggers.add_event_on_attack(on_attack)


func tower_init():
	var m: Modifier = Modifier.new()
	m.add_modification(Modification.Type.MOD_MOVESPEED, 0.0, -0.001)

	boekie_icy_spirit_buff = BuffType.new("boekie_icy_spirit_buff", 5, 0, false, self)
	boekie_icy_spirit_buff.set_buff_icon("@@0@@")
	boekie_icy_spirit_buff.set_buff_modifier(m)
	boekie_icy_spirit_buff.set_buff_tooltip("Frozen\nThis unit is frozen; it has reduced movement speed.")


func on_attack(_event: Event):
	var tower: Tower = self

	if !tower.calc_chance(0.25 + 0.005 * tower.get_level()):
		return

	var level: int = tower.get_level()

	var nova_count: int
	if level < 15:
		nova_count = 3
	elif level < 25:
		nova_count = 4
	else:
		nova_count = 5

	for i in range(0, nova_count):
#		Check that tower still exists, could have been sold
#		during await.
		if !Utils.unit_is_valid(tower):
			return

		var creeps_near_tower: Iterate = Iterate.over_units_in_range_of_caster(tower, TargetType.new(TargetType.CREEPS), 900)
		var target: Unit = creeps_near_tower.next_random()

		if target != null:
			tower.do_spell_damage_aoe_unit(target, 200, _stats.nova_dmg + (level * _stats.nova_dmg_add), tower.calc_spell_crit_no_bonus(), 0.5)
			SFX.sfx_on_unit("FrostNovaTarget.mdl", target, "origin")

			var creeps_near_target: Iterate = Iterate.over_units_in_range_of_caster(tower, TargetType.new(TargetType.CREEPS), 200)

			while true:
				target = creeps_near_target.next()

				if target == null:
					break

				boekie_icy_spirit_buff.apply(tower, target, 125 + level * 5)


		await get_tree().create_timer(0.1).timeout
