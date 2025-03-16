extends TowerBehavior

# NOTE: changed script to hide attack projectile and deal 0
# damage.

# NOTE: removed update of moth element triggered by "unit
# comes in range". Not necessary because can update this in
# periodic callback.

# NOTE: [ORIGINAL_GAME_BUG] Added moth periodic damage.
# Original script is missing it.

# NOTE: removed weird code for moth spell crit. Not needed
# because moth damage is dealt via tower.


var TARGET_TYPE_FOR_RARE_BREED: TargetType = TargetType.new(TargetType.TOWERS + TargetType.ELEMENT_DARKNESS + TargetType.ELEMENT_FIRE + TargetType.ELEMENT_STORM)


# var example_bt: BuffType
var moth_pt: ProjectileType
# var multiboard: MultiboardValues
var moth_list: Array[Projectile] = []
var element_for_moths: Element.enm = Element.enm.DARKNESS
var timer_to_return_to_tower: float = 0
var moth_target: Unit = null


const RARE_BREED_RADIUS: float = 110
const MOTH_DAMAGE_RADIUS: float = 375
const MOTH_DAMAGE_PERIOD: float = 0.5
const MANA_BURN_ADD: float = 0.08


func get_tier_stats() -> Dictionary:
	return {
		1: {moth_damage = 50, moth_damage_if_darkness = 75, moth_count = 6, mana_burn = 2, mana_burn_bonus_if_fire = 2},
		2: {moth_damage = 80, moth_damage_if_darkness = 120, moth_count = 6, mana_burn = 3, mana_burn_bonus_if_fire = 3},
		3: {moth_damage = 110, moth_damage_if_darkness = 165, moth_count = 7, mana_burn = 4, mana_burn_bonus_if_fire = 4},
	}


func get_ability_info_list_DELETEME() -> Array[AbilityInfo]:
	var moth_count: String = Utils.format_float(_stats.moth_count, 2)
	var mana_burn: String = Utils.format_float(_stats.mana_burn, 2)
	var mana_burn_add: String = Utils.format_float(MANA_BURN_ADD, 2)
	var mana_burn_bonus_if_fire: String = Utils.format_float(_stats.mana_burn_bonus_if_fire, 2)
	var rare_breed_radius: String = Utils.format_float(RARE_BREED_RADIUS, 2)
	var moth_damage: String = Utils.format_float(_stats.moth_damage, 2)
	var moth_damage_if_darkness: String = Utils.format_float(_stats.moth_damage_if_darkness, 2)
	var moth_damage_period: String = Utils.format_float(MOTH_DAMAGE_PERIOD, 2)
	var moth_damage_radius: String = Utils.format_float(MOTH_DAMAGE_RADIUS, 2)

	var darkness_string: String = Element.convert_to_colored_string(Element.enm.DARKNESS)
	var fire_string: String = Element.convert_to_colored_string(Element.enm.FIRE)
	var storm_string: String = Element.convert_to_colored_string(Element.enm.STORM)

	var list: Array[AbilityInfo] = []
	
	var moths: AbilityInfo = AbilityInfo.new()
	moths.name = "Moths of Prey"
	moths.icon = "res://resources/icons/animals/bat_03.tres"
	moths.description_short = "This tower controls %s magical moths which deal spell damage.\n" % moth_count
	moths.description_full = "This tower controls %s magical moths.\n" % moth_count \
	+ " \n" \
	+ "Each moth deals %s spell damage every %s seconds to a random creep within %s range of the moth. The moths also burn %s mana on damage.\n" % [moth_damage, moth_damage_period, moth_damage_radius, mana_burn] \
	+ " \n" \
	+ "[color=ORANGE]Level Bonus:[/color]\n" \
	+ "+%s mana burned\n" % mana_burn_add \
	+ ""
	list.append(moths)

	var rare_breed: AbilityInfo = AbilityInfo.new()
	rare_breed.name = "Rare Breed"
	rare_breed.icon = "res://resources/icons/magic/eyes_many.tres"
	rare_breed.description_short = "[color=GOLD]Moths of Prey[/color] will change their abilities depending on sum of gold costs of nearby towers.\n"
	rare_breed.description_full = "[color=GOLD]Moths of Prey[/color] will change their abilities depending on the sum of gold costs of towers in %s range. This also includes the gold cost of this tower. The ability is picked based on the element of the biggest gold cost sum.\n" % rare_breed_radius \
	+ " \n" \
	+ "%s: increases damage to %s.\n" % [darkness_string, moth_damage_if_darkness] \
	+ "%s: increases mana burn amount by %s.\n" % [fire_string, mana_burn_bonus_if_fire] \
	+ "%s: increases speed of the moths.\n" % storm_string \
	+ ""
	rare_breed.radius = RARE_BREED_RADIUS
	rare_breed.target_type = TargetType.new(TargetType.TOWERS)
	list.append(rare_breed)

	return list


func load_triggers(triggers: BuffType):
	triggers.add_event_on_attack(on_attack)
	triggers.add_event_on_damage(on_damage)
	triggers.add_periodic_event(periodic, 1.0)


func load_specials(modifier: Modifier):
	modifier.add_modification(Modification.Type.MOD_DMG_TO_UNDEAD, -0.3, 0.0)
	modifier.add_modification(Modification.Type.MOD_DMG_TO_MAGIC, 0.2, 0.0)
	modifier.add_modification(Modification.Type.MOD_SPELL_DAMAGE_DEALT, 0.0, 0.08)


func tower_init():
	tower.hide_attack_projectiles()

	moth_pt = ProjectileType.create_interpolate("path_to_projectile_sprite", 275, self)
	moth_pt.set_event_on_interpolation_finished(moth_pt_on_interpolation_finished)
	moth_pt.enable_periodic(moth_pt_periodic, MOTH_DAMAGE_PERIOD)


func on_create(_preceding_tower: Tower):
	for i in range(0, _stats.moth_count):
		var moth_pos: Vector3 = Vector3(
			tower.get_x() + Globals.synced_rng.randf_range(-100, 100),
			tower.get_y() + Globals.synced_rng.randf_range(-100, 100),
			175,
			)
		var p: Projectile = Projectile.create_bezier_interpolation_from_unit_to_point(moth_pt, tower, 1.0, 1.0, tower, moth_pos, 0.4, 0.4, 0.4)

		moth_list.append(p)

	update_element_for_moths()


func on_destruct():
	for moth in moth_list:
		moth.remove_from_game()


# Send moths at current attack target
func on_attack(event: Event):
	var target: Unit = event.get_target()
	moth_target = target
	timer_to_return_to_tower = 3.5


# NOTE: tower doesn't deal damage with normal attacks - only
# with moths
func on_damage(event: Event):
	event.damage = 0


func periodic(_event: Event):
#	Moths start to attempt returning to tower after a delay
	if timer_to_return_to_tower > 0:
		timer_to_return_to_tower -= 1
	else:
		moth_target = tower

	update_element_for_moths()


func moth_pt_on_interpolation_finished(p: Projectile, _hit_target: Unit):
	var spread: float = 280

#	Divides the difference between p and target; higher =
#	slower approach, below 0 = jump to opposite side
	var divider: float = 4

	var move_target: Unit
	if Utils.unit_is_valid(moth_target):
		move_target = moth_target
	else:
		move_target = tower

	var dx: float = move_target.get_x() - p.get_x()
	var dy: float = move_target.get_y() - p.get_y()

	var speed: float = 150

	if move_target is Creep:
		divider = 2

		var max_diff: float = max(dx, dy)

		if max_diff > 1200:
			spread = 150
			speed = 300
		elif max_diff > 400:
			spread = 175
			speed = 350
		else:
			spread = 200
			speed = 400
			divider = 0.85
	
	if element_for_moths == Element.enm.STORM:
		speed += 450
		spread = 150
		divider = 1

	p.set_speed(speed)

	var target_pos: Vector3 = Vector3(
		p.get_x() + Globals.synced_rng.randf_range(-spread, spread) + Utils.divide_safe(dx, divider),
		p.get_y() + Globals.synced_rng.randf_range(-spread, spread) + Utils.divide_safe(dy, divider),
		p.get_z() + Globals.synced_rng.randf_range(-min(35, p.get_z() - 35), 65) - Utils.divide_safe(p.get_z() / 10, divider)
		)

	var angle: float = rad_to_deg(atan2(target_pos.y - p.get_y(), target_pos.x - p.get_x()))
	var angle_diff: float = angle - p.get_direction()

	if angle_diff > 180:
		angle_diff -= 360
	elif angle_diff < -180:
		angle_diff += 360

	var steep: float = 0.2
	if angle_diff > 120 || angle_diff < -120:
		steep = 1.0

	p.start_bezier_interpolation_to_point(target_pos, 0.1, Globals.synced_rng.randf_range(-1, 1), steep)

	p.avert_destruction()


# NOTE: partially FireFly_Damage() in original script
func moth_pt_periodic(projectile: Projectile):
	var moth_pos: Vector2 = projectile.get_position_wc3_2d()
	var it: Iterate = Iterate.over_units_in_range_of(tower, TargetType.new(TargetType.CREEPS), moth_pos, MOTH_DAMAGE_RADIUS)

	var target: Unit = it.next_random()

	if target == null:
		return

	var mana_burn_amount: float = _stats.mana_burn + MANA_BURN_ADD * tower.get_level()
	if element_for_moths == Element.enm.FIRE:
		mana_burn_amount += _stats.mana_burn_bonus_if_fire

	var moth_damage: float
	if element_for_moths == Element.enm.DARKNESS:
		moth_damage = _stats.moth_damage_if_darkness
	else:
		moth_damage = _stats.moth_damage

	tower.do_spell_damage(target, moth_damage, tower.calc_spell_crit_no_bonus())
	target.subtract_mana(mana_burn_amount, false)


func update_element_for_moths():
	var it: Iterate = Iterate.over_units_in_range_of_caster(tower, TARGET_TYPE_FOR_RARE_BREED, RARE_BREED_RADIUS)

	var gold_cost_map: Dictionary = {}

	while true:
		var next: Unit = it.next()

		if next == null:
			break

		var element: Element.enm = next.get_element()
		var this_gold_cost: int = next.get_gold_cost()

		if !gold_cost_map.has(element):
			gold_cost_map[element] = 0

		gold_cost_map[element] += this_gold_cost

	var winning_element: Element.enm = Element.enm.DARKNESS
	var winning_sum: int = gold_cost_map.get(Element.enm.DARKNESS, 0)

	for element in gold_cost_map.keys():
		var this_sum: int = gold_cost_map[element]

		if this_sum > winning_sum:
			winning_element = element
			winning_sum = this_sum

	element_for_moths = winning_element

	var element_color: Color = Element.get_color(element_for_moths)

	for moth in moth_list:
		moth.set_color(element_color)
