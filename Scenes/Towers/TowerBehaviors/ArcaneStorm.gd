extends TowerBehavior


# NOTE: this script uses chain lightning cast weirdly. It
# uses it only to create a single chain between two units,
# doesn't deal damage with them - basically it's a visual
# only. The reason why is that this tower's ability is
# supposed to have a chance for each chain jump. Using the
# chain lighting cast normally would make this not possible
# because chain lightning cast always jumps up to the
# defined number of jumps.


var attraction_bt: BuffType
var manastorm_bt: BuffType
var surge_st: SpellType
var manastorm_st: SpellType


func get_ability_description() -> String:
	var text: String = ""

	text += "[color=GOLD]Surge[/color]\n"
	text += "The tower's main attacks have a 1% chance per Attraction stack on the target to send a surge of energy that deals 200% of attack damage to the target and then attempts to jump from enemy to enemy within 750 range of the original target. At each enemy, the chance to jump is calculated based on the next target's Attraction stacks. Can only hit each target once and benefits from Mana Storm's damage bonus.\n"
	text += " \n"
	text += "[color=ORANGE]Level Bonus:[/color]\n"
	text += "+0.02% chance per stack\n"
	text += "+4% attack damage\n"
	text += " \n"

	text += "[color=GOLD]Arcane Attraction[/color]\n"
	text += "Attacks apply a stack of Attraction on hit and generate 1 mana per stack on each target. Can only gain mana once per target hit on each attack. When an enemy dies, all stacks of Attraction on it will distribute evenly to nearby targets within 500 range and deal 20% attack damage per stack transferred. Attraction lasts indefinitely.\n"
	text += " \n"
	text += "[color=ORANGE]Level Bonus:[/color]\n"
	text += "+10 range\n"
	text += "+0.4% attack damage per stack\n"
	text += " \n"

	text += "[color=GOLD]Mana Storm[/color]\n"
	text += "Attacks hit up to 2 additional enemies within attack range and consume all mana to deal [mana consumed]% increased damage. Mana Storm gains an additional attack for every 75 mana consumed. If at least 100 mana is consumed, the tower's multicrit is increased by 3 for 2 seconds. If there are less creeps than attacks, the remaining attacks will hit the main target.\n"
	text += " \n"
	text += "[color=ORANGE]Level Bonus:[/color]\n"
	text += "-1 mana per extra attack\n"

	return text


func get_ability_description_short() -> String:
	var text: String = ""

	text += "[color=GOLD]Surge[/color]\n"
	text += "Chance to send a surge of energy that deals damage to the target and then attempts to jump to another enemy.\n"
	text += " \n"

	text += "[color=GOLD]Arcane Attraction[/color]\n"
	text += "Attacks apply a stack of Attraction on hit and generate mana.\n"
	text += " \n"

	text += "[color=GOLD]Mana Storm[/color]\n"
	text += "Attacks hit up to 2 additional enemies within attack range.\n"

	return text


func load_triggers(triggers: BuffType):
	triggers.add_event_on_damage(on_damage)


func tower_init():
	attraction_bt = BuffType.new("attraction_bt", -1, 0, false, self)
	attraction_bt.set_buff_icon("res://Resources/Textures/GenericIcons/star_swirl.tres")
	attraction_bt.set_buff_tooltip("Attraction\nSpreads Attraction and deals damage to nearby units when target dies.")
	attraction_bt.add_event_on_death(attraction_bt_on_death)

	manastorm_bt = BuffType.new("manastorm_bt", 2.0, 0, true, self)
	manastorm_bt.set_buff_icon("res://Resources/Textures/GenericIcons/rolling_energy.tres")
	manastorm_bt.set_buff_tooltip("Mana Storm\nIncreases multicrit.")
	var manastorm_bt_mod: Modifier = Modifier.new()
	manastorm_bt_mod.add_modification(Modification.Type.MOD_MULTICRIT_COUNT, 3, 0)
	manastorm_bt.set_buff_modifier(manastorm_bt_mod)

	surge_st = SpellType.new("@@0@@", "chainlightning", 1.0, self)
	surge_st.data.chain_lightning.damage = 0
	surge_st.data.chain_lightning.damage_reduction = 0
	surge_st.data.chain_lightning.chain_count = 1
	surge_st.set_source_height(90.0)

	manastorm_st = SpellType.new("@@1@@", "chainlightning", 1.0, self)
	manastorm_st.data.chain_lightning.damage = 0
	manastorm_st.data.chain_lightning.damage_reduction = 0
	manastorm_st.data.chain_lightning.chain_count = 1
	surge_st.set_source_height(90.0)


func on_damage(event: Event):
	var main_target: Unit = event.get_target()
	var chance_per_stack = 0.01 + 0.0002 * tower.get_level()
	var mana: float = tower.get_mana()
	var extra_per: float = 75 - 1 * tower.get_level()
	var extra_attacks: int = 2 + floori(mana / extra_per)
	var original_damage: float = event.damage
	var damage: float = original_damage * (1 + 0.01 * mana)
	var it: Iterate = Iterate.over_units_in_range_of_caster(tower, TargetType.new(TargetType.CREEPS), tower.get_range())
	var stacks: int = 0
	var total_stacks: int = 0
	var target: Unit
	var iterate_destroyed: bool = false

	event.damage = damage
	tower.subtract_mana(mana, true)

	if mana >= 100:
		manastorm_bt.apply(tower, tower, 1)
		var effect: int = Effect.create_colored("Lightningbolt.mdl", tower.get_position_wc3(), 270.0, 5, Color8(255, 90, 255, 255))
		Effect.set_lifetime(effect, 0.3)

	while true:
		if extra_attacks == 0:
			break

		if !iterate_destroyed:
			target = it.next_random()

			if target == null:
				iterate_destroyed = true
				target = main_target

		if iterate_destroyed || target != main_target:
			stacks = ashbringer_attraction_apply(target, 1)

			if target != main_target:
				manastorm_st.target_cast_from_caster(tower, target, 0.0, 0.0)
				total_stacks += stacks

				tower.do_attack_damage(target, damage, tower.calc_attack_multicrit_no_bonus())

			extra_attacks -= 1

	manastorm_st.target_cast_from_caster(tower, main_target, 0.0, 0.0)
	stacks = ashbringer_attraction_apply(main_target, 1)
	total_stacks += stacks

	if tower.calc_chance(stacks * chance_per_stack):
		ashbringer_surge_start(main_target, mana)

	tower.add_mana(total_stacks)


func ashbringer_attraction_apply(target: Unit, stacks: int):
	var i: int

	if stacks < 1:
		stacks = 1

	var attraction_buff: Buff = target.get_buff_of_type(attraction_bt)

	if attraction_buff != null:
		i = stacks + attraction_buff.get_power()
	else:
		i = 1

	attraction_bt.apply_custom_power(tower, target, 1, i)

	return i


# NOTE: "ashbringer_attraction_ondeath()" in original script
func attraction_bt_on_death(event: Event):
	var buff: Buff = event.get_buff()
	var target: Unit = buff.get_buffed_unit()
	var it_range: float = 500 + 10 * tower.get_level()
	var it: Iterate = Iterate.over_units_in_range_of_unit(tower, TargetType.new(TargetType.CREEPS), target, it_range)
	var count: int = it.count()
	var stacks: int = buff.get_power()
	var stacks_spare: int = 0
	var stacks_each: int = 0
	var applied: int = 0
	var damage_per_stack: float = tower.get_current_attack_damage_with_bonus() * (0.2 + 0.004 * tower.get_level())

	CombatLog.log_ability(tower, target, "Arcane Attraction Death Effect")

	if stacks < count:
		stacks_spare = stacks
	else:
		if count != 0:
			stacks_spare = stacks % count
			stacks_each = (stacks - stacks_spare) / count

	while true:
		var next: Unit = it.next()

		if next == null:
			break

		if stacks_spare > 0:
			applied = stacks_each + 1
			stacks_spare -= -1
		else:
			applied = stacks_each

		ashbringer_attraction_apply(next, applied)
		var damage: float = applied * damage_per_stack
		tower.do_attack_damage(next, damage, tower.calc_attack_multicrit_no_bonus())
		var effect: int = Effect.create_simple_on_unit("ArcaneTowerAttack.mdl", next, Unit.BodyPart.ORIGIN)
		Effect.destroy_effect_after_its_over(effect)


func ashbringer_surge_start(target: Unit, mana: float):
	var it: Iterate = Iterate.over_units_in_range_of_unit(tower, TargetType.new(TargetType.CREEPS), target, 750)
	var damage: float = tower.get_current_attack_damage_with_bonus() * (2.0 + 0.04 * tower.get_level()) * (1 + 0.01 * mana)
	var chance_per_stack: float = 0.01 + 0.0002 * tower.get_level()
	var prev: Unit = target

	CombatLog.log_ability(tower, target, "Surge")

	surge_st.target_cast_from_caster(tower, target, 0.0, 0.0)
	tower.do_attack_damage(target, damage, tower.calc_attack_multicrit_no_bonus())

	while true:
		var next: Unit = it.next()

		if next == null:
			break

		if next == target:
			continue

		var attraction_buff: Buff = next.get_buff_of_type(attraction_bt)

		if attraction_buff == null:
			continue

		var jump_chance: float = attraction_buff.get_power() * chance_per_stack

		if !tower.calc_chance(jump_chance):
			continue

		surge_st.target_cast_from_caster(prev, next, 0.0, 0.0)
		tower.do_attack_damage(next, damage, tower.calc_attack_multicrit_no_bonus())
		prev = next
