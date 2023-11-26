extends Tower


# NOTE: original script appears to have a bug where it
# doesn't check if tower has enough mana to do rift ability.
# So it will spend 20 mana and do nothing. Fixed it.


var mock_rift_aura_bt: BuffType
var mock_rift_slow_bt: BuffType


func get_ability_description() -> String:
	var text: String = ""

	text += "[color=GOLD]Spacial Rift[/color]\n"
	text += "Whenever this tower damages a creep it has a 10% chance to move that creep back by 175 units. Upon triggering there is a further 15% chance that all creeps in 175 AoE of the target will also be moved back 175 units. Costs 30 mana. Chance is halved for bosses.  The original target and creeps around it will get startled and become slowed by 30% for 2 seconds in a 250 AoE.\n"
	text += " \n"
	text += "[color=ORANGE]Level Bonus:[/color]\n"
	text += "+0.4% chance to move creep\n"
	text += "+1 units moved\n"
	text += "+1 units moved\n"
	text += "+1 slow and unit move AoE\n"
	text += "+1% slow\n"
	text += " \n"

	text += "[color=GOLD]Presence of the Rift - Aura[/color]\n"
	text += "The Astral Rift's presence is so powerful that it damages creeps equal to 200% of their movement speed every second in an area of 750.\n"
	text += " \n"
	text += "[color=ORANGE]Level Bonus:[/color]\n"
	text += "+16% damage increase\n"

	return text


func get_ability_description_short() -> String:
	var text: String = ""

	text += "[color=GOLD]Spacial Rift[/color]\n"
	text += "This tower has chance to move damaged creeps back by 175 units.\n"
	text += " \n"

	text += "[color=GOLD]Presence of the Rift - Aura[/color]\n"
	text += "Deals periodic damage to creeps in range, scaled by their movement speed.\n"

	return text


func load_triggers(triggers: BuffType):
	triggers.add_event_on_damage(on_damage)


func tower_init():
	mock_rift_slow_bt = BuffType.new("mock_rift_slow_bt", 2, 0, false, self)
	var mod: Modifier = Modifier.new()
	mod.add_modification(Modification.Type.MOD_MOVESPEED, -0.3, -0.01)
	mock_rift_slow_bt.set_buff_modifier(mod)
	mock_rift_slow_bt.set_buff_icon("@@1@@")
	mock_rift_slow_bt.set_buff_tooltip("Startled\nThis unit is startled; it has reduced movement speed.")

	mock_rift_aura_bt = BuffType.create_aura_effect_type("mock_rift_aura_bt", false, self)
	mock_rift_aura_bt.set_buff_icon("@@0@@")
	mock_rift_aura_bt.add_periodic_event(mock_rift_aura_bt_periodic, 1.0)
	mock_rift_aura_bt.set_buff_tooltip("Presence of the Rift Aura\nThis creep is affected by Presence of the Rift Aura; it will take periodic damage.")


func get_aura_types() -> Array[AuraType]:
	var aura: AuraType = AuraType.new()
	aura.aura_range = 750
	aura.target_type = TargetType.new(TargetType.CREEPS)
	aura.target_self = false
	aura.level = 0
	aura.level_add = 1
	aura.power = 0
	aura.power_add = 1
	aura.aura_effect = mock_rift_aura_bt

	return [aura]


func on_damage(event: Event):
	var tower: Tower = self
	var level: int = tower.get_level()
	var target: Creep = event.get_target()
	var target_is_boss: bool = target.get_size() >= CreepSize.enm.BOSS
	var enough_mana: bool = tower.get_mana() >= 30

	if !enough_mana:
		return

	var rift_chance: float = 0.10 + 0.004 * level
	if target_is_boss:
		rift_chance *= 0.5

	if !tower.calc_chance(rift_chance):
		return

	tower.subtract_mana(30, false)

	var tower_effect: int = Effect.create_scaled("ReplenishManaCaster.mdl", tower.get_visual_x(), tower.get_visual_y(), 10, 0, 30)
	Effect.set_lifetime(tower_effect, 1.0)

	var target_effect: int = Effect.create_simple("AIilTarget.mdl", target.get_visual_x(), target.get_visual_y())
	Effect.destroy_effect_after_its_over(target_effect)

	var move_aoe: bool = tower.calc_chance(0.15)

	if move_aoe:
		CombatLog.log_ability(tower, target, "Spacial Rift AoE")

		var it: Iterate = Iterate.over_units_in_range_of_unit(tower, TargetType.new(TargetType.CREEPS), target, 175 + level)

		while true:
			var next: Unit = it.next()

			if next == null:
				break

			move_creep_back(next)
	else:
		CombatLog.log_ability(tower, target, "Spacial Rift")

		move_creep_back(target)

	var slow_effect: int = Effect.create_simple("SilenceAreaBirth.mdl", target.get_visual_x(), target.get_visual_y())
	Effect.set_lifetime(slow_effect, 1.0)

	var it: Iterate = Iterate.over_units_in_range_of_unit(tower, TargetType.new(TargetType.CREEPS), target, 250 + level)

	while true:
		var next: Unit = it.next()

		if next == null:
			break

		mock_rift_slow_bt.apply(tower, next, level)


func mock_rift_aura_bt_periodic(event: Event):
	var buff: Buff = event.get_buff()
	var creep: Creep = buff.get_buffed_unit()
	var tower: Tower = buff.get_caster()
	var damage: float = creep.get_current_movespeed() * (2.0 + 0.16 * tower.get_level())

	tower.do_spell_damage(creep, damage, tower.calc_spell_crit_no_bonus())


func move_creep_back(creep: Unit):
	var tower: Tower = self
	var facing: float = creep.get_unit_facing()
	var facing_reversed: float = facing - 180
	var teleport_offset_top_down: Vector2 = Vector2(175 + tower.get_level(), 0).rotated(deg_to_rad(facing_reversed))
	var teleport_offset: Vector2 = Isometric.top_down_vector_to_isometric(teleport_offset_top_down)
	creep.position += teleport_offset
