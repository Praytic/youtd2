extends TowerBehavior


# NOTE: this script uses chain lightning cast weirdly. It
# uses it only to create a single chain between two units,
# doesn't deal damage with them - basically it's a visual
# only. The reason why is that this tower's ability is
# supposed to have a chance for each chain jump. Using the
# chain lighting cast normally would make this not possible
# because chain lightning cast always jumps up to the
# defined number of jumps.

# NOTE: changed missile speed in csv for this tower.
# 5000->9001. This tower uses "lightning" projectile visual
# so slow speed looks weird because it makes the damage
# delayed compared to the lightning visual.


var attraction_bt: BuffType
var manastorm_bt: BuffType
var surge_st: SpellType
var manastorm_st: SpellType


func load_triggers(triggers: BuffType):
	triggers.add_event_on_damage(on_damage)


func tower_init():
	attraction_bt = BuffType.new("attraction_bt", -1, 0, false, self)
	attraction_bt.set_buff_icon("res://resources/icons/generic_icons/star_swirl.tres")
	attraction_bt.set_buff_tooltip(tr("M22D"))
	attraction_bt.add_event_on_death(attraction_bt_on_death)

	manastorm_bt = BuffType.new("manastorm_bt", 2.0, 0, true, self)
	manastorm_bt.set_buff_icon("res://resources/icons/generic_icons/rolling_energy.tres")
	manastorm_bt.set_buff_tooltip(tr("ME8L"))
	var manastorm_bt_mod: Modifier = Modifier.new()
	manastorm_bt_mod.add_modification(ModificationType.enm.MOD_MULTICRIT_COUNT, 3, 0)
	manastorm_bt.set_buff_modifier(manastorm_bt_mod)

	surge_st = SpellType.new(SpellType.Name.CHAIN_LIGHTNING, 1.0, self)
	surge_st.data.chain_lightning.damage = 0
	surge_st.data.chain_lightning.damage_reduction = 0
	surge_st.data.chain_lightning.chain_count = 1
	surge_st.set_source_height(90.0)

	manastorm_st = SpellType.new(SpellType.Name.CHAIN_LIGHTNING, 1.0, self)
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

	if mana >= 1:
		manastorm_bt.apply(tower, tower, 1)
		var effect: int = Effect.create_simple_at_unit("res://src/effects/holy_bolt.tscn", tower)
		Effect.set_color(effect, Color.AQUAMARINE)
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


func ashbringer_attraction_apply(target: Unit, applied_stacks: int) -> int:
	if applied_stacks < 1:
		applied_stacks = 1

	var buff: Buff = target.get_buff_of_type(attraction_bt)

	var active_stacks: int
	if buff != null:
		active_stacks = buff.user_int
	else:
		active_stacks = 0

	var new_stacks: int = active_stacks + applied_stacks

	buff = attraction_bt.apply(tower, target, 1)
	buff.user_int = new_stacks
	buff.set_displayed_stacks(new_stacks)

	return new_stacks


# NOTE: "ashbringer_attraction_ondeath()" in original script
func attraction_bt_on_death(event: Event):
	var buff: Buff = event.get_buff()
	var target: Unit = buff.get_buffed_unit()
	var it_range: float = 500 + 10 * tower.get_level()
	var it: Iterate = Iterate.over_units_in_range_of_unit(tower, TargetType.new(TargetType.CREEPS), target, it_range)
	var count: int = it.count()
	var stacks: int = buff.user_int
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
		var effect: int = Effect.create_simple_at_unit_attached("res://src/effects/arcane_tower_attack.tscn", next, Unit.BodyPart.ORIGIN)
		Effect.set_color(effect, Color.AQUAMARINE)


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

		var active_stacks: int = attraction_buff.user_int
		var jump_chance: float = active_stacks * chance_per_stack

		if !tower.calc_chance(jump_chance):
			continue

		surge_st.target_cast_from_caster(prev, next, 0.0, 0.0)
		tower.do_attack_damage(next, damage, tower.calc_attack_multicrit_no_bonus())
		prev = next
