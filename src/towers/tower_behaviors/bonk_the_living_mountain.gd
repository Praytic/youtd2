extends TowerBehavior


# NOTE: changed values for growth scale a bit.


# NOTE: SCALE_MIN should match the value in tower sprite
# scene
const SCALE_MIN: float = 0.5
const SCALE_MAX: float = 1.0

var stun_bt: BuffType
var morale_bt: BuffType
var grow_bt: BuffType
var rock_pt: ProjectileType
var multiboard: MultiboardValues
var grow_count: int = 0


func get_ability_info_list() -> Array[AbilityInfo]:
	var list: Array[AbilityInfo] = []
	
	var grow: AbilityInfo = AbilityInfo.new()
	grow.name = "Grow!"
	grow.icon = "res://resources/icons/trinkets/trinket_09.tres"
	grow.description_short = "Bonk will periodically grow, gaining experience and bonus attack damage.\n"
	grow.description_full = "Every 25 seconds Bonk grows, gaining 4 experience and 3% bonus attack damage. Bonk can grow 160 times.\n" \
	+ " \n" \
	+ "[color=ORANGE]Level Bonus:[/color]\n" \
	+ "+0.1% bonus attack damage\n"
	list.append(grow)

	var landslide: AbilityInfo = AbilityInfo.new()
	landslide.name = "Landslide!"
	landslide.icon = "res://resources/icons/food/lard.tres"
	landslide.description_short = "Chance to throw rocks at creeps around the main target. These rocks deal spell damage and stun.\n"
	landslide.description_full = "This ability works only after Bonk has grown 20 times.\n" \
	+ " \n" \
	+ "25% chance to throw rocks at all creeps in 300 AoE around the main target. These rocks deal 700 spell damage and stun for 0.5 seconds. [color=GOLD]Landslide[/color] deals 15 bonus spell damage per grow.\n" \
	+ " \n" \
	+ "[color=ORANGE]Level Bonus:[/color]\n" \
	+ "+50 spell damage\n"
	list.append(landslide)

	var crush: AbilityInfo = AbilityInfo.new()
	crush.name = "Crush!"
	crush.icon = "res://resources/icons/tower_icons/black_rock_totem.tres"
	crush.description_short = "When hitting stunned creeps, Bonk deals extra spell damage and gives a morale boost to nearby towers.\n"
	crush.description_full = "This ability works only after Bonk has grown 10 times.\n" \
	+ " \n" \
	+ "When hitting stunned creeps, Bonk deals 5000 extra spell damage. In addition, towers in 500 range will gain 10% attack speed and damage for 10 seconds. [color=GOLD]Crush[/color] deals 50 bonus spell damage per grow.\n" \
	+ " \n" \
	+ "[color=ORANGE]Level Bonus:[/color]\n" \
	+ "+250 spell damage\n" \
	+ "+0.4% attack speed and damage\n"
	crush.radius = 500
	crush.target_type = TargetType.new(TargetType.TOWERS)
	list.append(crush)

	return list


func load_triggers(triggers: BuffType):
	triggers.add_event_on_attack(on_attack)
	triggers.add_event_on_damage(on_damage)
	triggers.add_periodic_event(periodic, 25)


func load_specials(modifier: Modifier):
	tower.set_attack_style_splash({100: 1.0})
	modifier.add_modification(Modification.Type.MOD_DMG_TO_MASS, 0.25, 0.005)


func tower_init():
	stun_bt = CbStun.new("stun_bt", 0, 0, false, self)
	
	morale_bt = BuffType.new("morale_bt", 10, 0, true, self)
	morale_bt.set_buff_icon("res://resources/icons/generic_icons/mighty_force.tres")
	morale_bt.set_buff_tooltip("Morale Boost\nIncreases attack speed and attack damage.")
	var mod: Modifier = Modifier.new()
	mod.add_modification(Modification.Type.MOD_DAMAGE_ADD_PERC, 0.10, 0.004)
	mod.add_modification(Modification.Type.MOD_ATTACKSPEED, 0.10, 0.004)
	morale_bt.set_buff_modifier(mod)

	grow_bt = BuffType.new("grow_bt", -1, 0, true, self)
	grow_bt.set_buff_icon("res://resources/icons/generic_icons/biceps.tres")
	grow_bt.set_buff_tooltip("Grow\nPermanently increases attack damage.")

	rock_pt = ProjectileType.create("path_to_projectile_sprite", 4, 700, self)
	rock_pt.enable_homing(rock_pt_on_hit, 0)

	multiboard = MultiboardValues.new(1)
	multiboard.set_key(0, "Number of Grows")


func on_create(_preceding: Tower):
	var grow_buff: Buff = grow_bt.apply_to_unit_permanent(tower, tower, 0)
	grow_buff.set_displayed_stacks(grow_count)


func on_attack(event: Event):
	var target: Unit = event.get_target()
	var chance: float = 0.25
	var enough_grow_count_for_landslide: bool = grow_count >= 20

	if !tower.calc_chance(chance):
		return

	if !enough_grow_count_for_landslide:
		return

	CombatLog.log_ability(tower, target, "Landslide")

	var it: Iterate = Iterate.over_units_in_range_of_unit(tower, TargetType.new(TargetType.CREEPS), target, 300)

	while true:
		var next: Unit = it.next()

		if next == null:
			break

		Projectile.create_from_unit_to_unit(rock_pt, tower, 1.0, 0.0, tower, next, true, false, false)


func on_damage(event: Event):
	var creep: Unit = event.get_target()
	var level: int = tower.get_level()
	var crush_damage: float = 5000 + 250 * level + 50 * grow_count

	var enough_grow_count_for_crush: bool = grow_count >= 10
	if !enough_grow_count_for_crush:
		return

	if !creep.is_stunned():
		return

	tower.do_spell_damage(creep, crush_damage, tower.calc_spell_crit_no_bonus())
	var effect: int = Effect.create_scaled("res://src/effects/bdragon_25_dust_cloud.tscn", Vector3(creep.get_x(), creep.get_y(), 0.0), 0, 2)
	Effect.destroy_effect_after_its_over(effect)

	var it: Iterate = Iterate.over_units_in_range_of_unit(tower, TargetType.new(TargetType.TOWERS), tower, 500)

	while true:
		var next: Unit = it.next()

		if next == null:
			break

		morale_bt.apply(tower, next, level)


func on_tower_details() -> MultiboardValues:
	multiboard.set_value(0, str(grow_count))

	return multiboard

func periodic(_event: Event):
	var level: int = tower.get_level()
	var reached_max_growth: bool = grow_count >= 160

	if reached_max_growth:
		return

	var effect: int = Effect.create_scaled("EntanglingRootsTarget.mdl", tower.get_position_wc3(), 0, 5)
	Effect.set_lifetime(effect, 1.0)

	tower.modify_property(Modification.Type.MOD_DAMAGE_ADD_PERC, 0.03 + 0.001 * level)
	tower.add_exp(4)

	grow_count += 1

	var grow_buff: Buff = tower.get_buff_of_type(grow_bt)
	grow_buff.set_displayed_stacks(grow_count)

	var tower_scale: float = Utils.get_scale_from_grows(SCALE_MIN, SCALE_MAX, grow_count, 160)
	tower.set_unit_scale(tower_scale)


func rock_pt_on_hit(_projectile: Projectile, creep: Unit):
	if creep == null:
		return

	var damage: float = 700 + 50 * tower.get_level() + 15 * grow_count

	tower.do_spell_damage(creep, damage, tower.calc_spell_crit_no_bonus())
	stun_bt.apply_only_timed(tower, creep, 0.5)
