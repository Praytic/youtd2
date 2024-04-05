extends TowerBehavior


# NOTE: fixed error in original script where drake
# projectiles used Projectile API's for both interpolated
# and normal projectile types.
# For example:
# ProjectileType.create() - normal
# ProjectileType.setEventOnInterpolationFinished() - interpolated
# Switched to using exclusively interpolated API.
# Fixed slow buff being friendly.


enum DrakeState {
	IDLE,
	ATTACKING,
	COMING_BACK
};

class Drake:
	var projectile: Projectile
	var state: DrakeState
	var start_pos: Vector3


# NOTE: "maxFedDrakes" in original script
const FEED_COUNT_MAX: int = 5
const BLUE_I: int = 0
const GREEN_I: int = 1
const RED_I: int = 2

var stun_bt: BuffType
var versatile_bt: BuffType
var slow_bt: BuffType
var blue_drake_pt: ProjectileType
var green_drake_pt: ProjectileType
var red_drake_pt: ProjectileType
var bronze_drake_pt: ProjectileType
var bronze_drake_attack_pt: ProjectileType
var drake_list: Array[Drake] = []
var feed_count: int = 0


func get_ability_description() -> String:
	var text: String = ""

	text += "[color=GOLD]Versatile[/color]\n"
	text += "Every time this tower deals spell damage through its abilities, it increases its dps by 1.5% of the spell damage dealt. Lasts 2.5 seconds and stacks. Maximum bonus of [color=GOLD][200 x (current wave)][/color].\n"
	text += " \n"
	text += "[color=ORANGE]Level Bonus:[/color]\n"
	text += "+0.04% damage\n"
	text += " \n"

	text += "[color=GOLD]Unleash[/color]\n"
	text += "On attack, the Drake Whisperer has a 12.5% chance to unleash a bronze drake towards its target, dealing 1250 spell damage to a random creep in front of itself in 600 range every 0.2 seconds. Lasts 2 seconds.\n"
	text += " \n"
	text += "[color=ORANGE]Level Bonus:[/color]\n"
	text += "+40 spell damage\n"
	text += "+0.3% chance\n"
	text += " \n"

	text += "[color=GOLD]Feed the Drakes[/color]\n"
	text += "Every 1.5 seconds, the Drake Whisperer feeds a nearby corpse to one of his drakes and unleashes it to a random target in 1000 range. If there is no target, the drake will attack on the next feeding, with a maximum of 5 fed drakes. Each corpse has a 15% chance to feed 2 drakes.\n"
	text += " \n"
	text += "The [color=BLUE]Blue[/color] Drake deals 6000 spell damage in 125 AoE and slows by 25% for 3 seconds.\n"
	text += "The [color=RED]Red[/color] Drake deals 200% of the tower's attack damage and stuns for 3 seconds.\n"
	text += "The [color=GREEN]Green[/color] Drake deals 5000 spell damage and spreads Versatile's current dps bonus to towers in 175 range for 2.5 seconds.\n"
	text += " \n"
	text += "[color=ORANGE]Level Bonus:[/color]\n"
	text += "+0.4% double feed chance\n"
	text += "[color=BLUE]Blue[/color] Drake : +150 spell damage\n"
	text += "[color=RED]Red[/color] Drake : +8% damage\n"
	text += "[color=GREEN]Green[/color] Drake : +0.04 seconds duration\n"

	return text


func get_ability_description_short() -> String:
	var text: String = ""

	text += "[color=GOLD]Versatile[/color]\n"
	text += "Every time this tower deals spell damage through its abilities, it increases its dps.\n"
	text += " \n"

	text += "[color=GOLD]Unleash[/color]\n"
	text += "Chance to unleash a bronze drake towards its target.\n"
	text += " \n"

	text += "[color=GOLD]Feed the Drakes[/color]\n"
	text += "The Drake Whisperer feeds a nearby corpse to one of his drakes and unleashes it to a random target.\n"

	return text


func load_triggers(triggers: BuffType):
	triggers.add_event_on_attack(on_attack)
	triggers.add_periodic_event(periodic, 1.5)


func load_specials(modifier: Modifier):
	modifier.add_modification(Modification.Type.MOD_DMG_TO_AIR, 0.15, 0.004)


func tower_init():
	stun_bt = CbStun.new("stun_bt", 0, 0, false, self)

	versatile_bt = BuffType.new("versatile_bt", 2.5, 0, true, self)
	var versatile_bt_mod: Modifier = Modifier.new()
	versatile_bt_mod.add_modification(Modification.Type.MOD_DPS_ADD, 0.0, 1.0)
	versatile_bt.set_buff_modifier(versatile_bt_mod)
	versatile_bt.set_buff_icon("star.tres")
	versatile_bt.set_buff_tooltip("Versatile\nIncreases DPS.")

	slow_bt = BuffType.new("slow_bt", 3.0, 0, false, self)
	var slow_bt_mod: Modifier = Modifier.new()
	slow_bt_mod.add_modification(Modification.Type.MOD_MOVESPEED, -0.25, 0.0)
	slow_bt.set_buff_modifier(slow_bt_mod)
	slow_bt.set_buff_icon("fireball.tres")
	slow_bt.set_buff_tooltip("Blue Drake Breath\nReduces movement speed.")

	blue_drake_pt = ProjectileType.create_interpolate("AzureDragon.mdl", 1000, self)
	blue_drake_pt.disable_explode_on_hit()
	blue_drake_pt.disable_explode_on_expiration()
	blue_drake_pt.set_event_on_interpolation_finished(generic_drake_pt_on_hit)
	blue_drake_pt.enable_periodic(generic_drake_pt_periodic, 0.1)

	red_drake_pt = ProjectileType.create_interpolate("RedDragon.mdl", 900, self)
	red_drake_pt.disable_explode_on_hit()
	red_drake_pt.disable_explode_on_expiration()
	red_drake_pt.set_event_on_interpolation_finished(generic_drake_pt_on_hit)
	red_drake_pt.enable_periodic(generic_drake_pt_periodic, 0.1)

	green_drake_pt = ProjectileType.create_interpolate("GreenDragon.mdl", 900, self)
	green_drake_pt.disable_explode_on_hit()
	green_drake_pt.disable_explode_on_expiration()
	green_drake_pt.set_event_on_interpolation_finished(generic_drake_pt_on_hit)
	green_drake_pt.enable_periodic(generic_drake_pt_periodic, 0.1)

	bronze_drake_pt = ProjectileType.create_interpolate("BronzeDragon.mdl", 900, self)
	bronze_drake_pt.disable_explode_on_hit()
	bronze_drake_pt.disable_explode_on_expiration()
	bronze_drake_pt.enable_periodic(bronze_drake_pt_periodic, 0.2)

	bronze_drake_attack_pt = ProjectileType.create_interpolate("FireBallMissile.mdl", 900, self)
	bronze_drake_attack_pt.set_event_on_interpolation_finished(bronze_drake_attack_pt_on_hit)


func on_attack(event: Event):
	var target: Unit = event.get_target()
	var unleash_chance: float = 0.125 + 0.003 * tower.get_level()

	if !tower.calc_chance(unleash_chance):
		return

	CombatLog.log_ability(tower, target, "Unleash")

	var final_x: float = tower.get_x() + (target.get_x() - tower.get_x()) * 6
	var final_y: float = tower.get_y() + (target.get_y() - tower.get_y()) * 6

	var p: Projectile = Projectile.create_from_unit_to_point(bronze_drake_pt, tower, 0, 0, tower, Vector2(final_x, final_y), true, false)
	p.setScale(0.6)


func on_create(_preceding_tower: Tower):
	var blue_drake: Drake = Drake.new()
	var green_drake: Drake = Drake.new()
	var red_drake: Drake = Drake.new()
	
	blue_drake.projectile = Projectile.create_linear_interpolation_from_unit_to_point(blue_drake_pt, tower, 0, 0, tower, Vector2(tower.get_visual_x() + 36, tower.get_visual_y() - 30), 0.0)
	green_drake.projectile = Projectile.create_linear_interpolation_from_unit_to_point(green_drake_pt, tower, 0, 0, tower, Vector2(tower.get_visual_x() - 50, tower.get_visual_y() - 13), 0.0)
	red_drake.projectile = Projectile.create_linear_interpolation_from_unit_to_point(red_drake_pt, tower, 0, 0, tower, Vector2(tower.get_visual_x() + 27, tower.get_visual_y() + 59), 0.0)

	drake_list.resize(3)
	drake_list[BLUE_I] = blue_drake
	drake_list[GREEN_I] = green_drake
	drake_list[RED_I] = red_drake

	drake_list[BLUE_I].projectile.user_int2 = BLUE_I
	drake_list[GREEN_I].projectile.user_int2 = GREEN_I
	drake_list[RED_I].projectile.user_int2 = RED_I

	drake_list[BLUE_I].start_pos = Vector3(tower.get_visual_x() + 36, tower.get_visual_y() - 30, tower.get_z() - 30)
	drake_list[GREEN_I].start_pos = Vector3(tower.get_visual_x() - 50, tower.get_visual_y() - 13, tower.get_z() - 30)
	drake_list[RED_I].start_pos = Vector3(tower.get_visual_x() + 27, tower.get_visual_y() + 59, tower.get_z() - 30)

	for drake in drake_list:
		drake.projectile.disable_periodic()
		drake.projectile.setScale(0.25)
		drake.state = DrakeState.IDLE

	drake_list[BLUE_I].projectile.set_color(Color.LIGHT_BLUE)
	drake_list[GREEN_I].projectile.set_color(Color.DARK_GREEN)
	drake_list[RED_I].projectile.set_color(Color.DARK_RED)


func on_destruct():
	for drake in drake_list:
		drake.projectile.remove_from_game()

	drake_list.clear()


func periodic(_event: Event):
	feeding()


# NOTE: "allDrakesBusy()" in original script
func all_drakes_busy() -> bool:
	var all_busy: bool = true

	for drake in drake_list:
		if drake.state == DrakeState.IDLE:
			all_busy = false

			break

	return all_busy


# NOTE: "launchDrakeling()" in original script
func launch_drakeling(drake: Drake, target: Unit):
	drake.projectile.set_speed(600)
	drake.projectile.start_bezier_interpolation_to_unit(target, 0.15, 0.15, 0.17, true)
	drake.state = DrakeState.ATTACKING
	feed_count -= 1



# NOTE: "launchRandomDrakeling()" in original script
func launch_random_drakeling(target: Unit):
	var i: int = Globals.synced_rng.randi_range(0, 2)

	while true:
		var drake: Drake = drake_list[i]

		if drake.state == DrakeState.IDLE:
			launch_drakeling(drake, target)

			return

		i = (i + 1) % 3


# NOTE: "feeding()" in original script
func feeding():
	var it: Iterate = Iterate.over_units_in_range_of_caster(tower, TargetType.new(TargetType.CREEPS), 1000)
	var feed_two_chance: float = 0.15 + 0.004 * tower.get_level()

	if feed_count < FEED_COUNT_MAX:
		var it_corpse: Iterate = Iterate.over_units_in_range_of(tower, TargetType.new(TargetType.CORPSES), tower.get_x(), tower.get_y(), 1000)
		var corpse: CreepCorpse = it_corpse.next_corpse()

		if corpse != null:
			corpse.hide()

			var effect: int = Effect.create_scaled("HumanBloodFootman.mdl", tower.get_visual_x() + 10, tower.get_visual_y(), tower.get_z() - 120, 0, 5)
			Effect.set_lifetime(effect, 0.8)

			var feed_amount: int
			if tower.calc_chance(feed_two_chance):
				feed_amount = 2
			else:
				feed_amount = 1

			feed_count += feed_amount

			if feed_count > FEED_COUNT_MAX:
				feed_count = FEED_COUNT_MAX

	while true:
		if feed_count <= 0 || all_drakes_busy():
			return

		var next: Unit = it.next_random()

		if next == null:
			break

#		Only red drakes deal physical, so unleash only them vs immune
		if next.is_immune():
			var red_drake: Drake = drake_list[RED_I]

			if red_drake.state == DrakeState.IDLE:
				launch_drakeling(red_drake, next)
		else:
			launch_random_drakeling(next)


# NOTE: "refreshBuff()" in original script
func refresh_buff(damage_dealt: float):
	var versatile_buff: Buff = tower.get_buff_of_type(versatile_bt)
	var max_damage: float = 200 * tower.get_player().get_team().get_level()

	if damage_dealt <= 0:
		return

	var powerup: float = damage_dealt * (0.015 + 0.004 * tower.get_level())

	if versatile_buff != null:
		powerup = versatile_buff.get_power() + powerup

		if powerup > max_damage:
			powerup = max_damage

		versatile_buff.set_power(int(powerup))
		versatile_buff.refresh_duration()
	else:
		if powerup > max_damage:
			powerup = max_damage

		versatile_bt.apply_custom_power(tower, tower, 1, int(powerup))


# NOTE: "spreadBuff()" in original script
func spread_buff():
	var versatile_buff: Buff = tower.get_buff_of_type(versatile_bt)

	if versatile_buff == null:
		return

	var it: Iterate = Iterate.over_units_in_range_of_caster(tower, TargetType.new(TargetType.TOWERS), 175)

	while true:
		var next: Unit = it.next()

		if next == null:
			break

		if next != tower:
			versatile_bt.apply_advanced(tower, next, 1, versatile_buff.get_power(), 2.5 + 0.04 * tower.get_level())


# NOTE: "blueDrakeHit()" in original script
func blue_drake_on_hit(p: Projectile, _target: Unit):
	var damage_before: float = tower.get_overall_damage()

	var it: Iterate = Iterate.over_units_in_range_of(tower, TargetType.new(TargetType.CREEPS), p.get_x(), p.get_y(), 125)

	if it.count() == 0:
		return

	var effect: int = Effect.create_scaled("FrostNovaTarget.mdl", p.get_x(), p.get_y(), p.get_z(), 0, 5)
	Effect.set_lifetime(effect, 2.0)

	var drake_damage: float = 6000 + 150 * tower.get_level()

	while true:
		var next: Unit = it.next()

		if next == null:
			break

		slow_bt.apply(tower, next, 1)
		tower.do_spell_damage(next, drake_damage, tower.calc_spell_crit_no_bonus())

	var damage_after: float = tower.get_overall_damage()
	var damage_dealt: float = damage_after - damage_before
	refresh_buff(damage_dealt)


# NOTE: "greenDrakeHit()" in original script
func green_drake_on_hit(_p: Projectile, target: Unit):
	var damage_before: float = tower.get_overall_damage()

	if target == null:
		spread_buff()

		return

	tower.do_spell_damage(target, 5000, tower.calc_spell_crit_no_bonus())

	var damage_after: float = tower.get_overall_damage()
	var damage_dealt: float = damage_after - damage_before
	refresh_buff(damage_dealt)	
	spread_buff()


# NOTE: "redDrakeHit()" in original script
func red_drake_on_hit(_p: Projectile, target: Unit):
	if target == null:
		return

	var drake_damage: float = tower.get_current_attack_damage_with_bonus() * (2.0 + 0.08 * tower.get_level())
	stun_bt.apply_only_timed(tower, target, 3)
	tower.do_attack_damage(target, drake_damage, tower.calc_attack_crit_no_bonus())


# NOTE: "sendDrakelingHome ()" in original script
func send_drakeling_home(p: Projectile):
	var which: int = p.user_int2

	var drake: Drake = drake_list[which]
	drake.projectile.set_speed(600)
	drake.projectile.start_bezier_interpolation_to_point(Vector2(drake.start_pos.x, drake.start_pos.y), 0.15, 0.15, 0.17)
	drake.state = DrakeState.COMING_BACK


# NOTE: "onDrakelingEndInterpol()" in original script
func generic_drake_pt_on_hit(p: Projectile, target: Unit):
	p.avert_destruction()

	var which: int = p.user_int2
	var drake: Drake = drake_list[which]

	if drake.state == DrakeState.COMING_BACK:
#		Will be used to reset the drake, otherwise the code in Projectile messes with our position right after this event handler
		p.enable_periodic(1)
		p.set_remaining_lifetime(999999)

		return

	if target != null:
		if which == RED_I:
			red_drake_on_hit(p, target)
		elif which == BLUE_I:
			blue_drake_on_hit(p, target)
		else:
			green_drake_on_hit(p, target)

	send_drakeling_home(p)


# NOTE: "bronzeDrakeTick()" in original script
func bronze_drake_pt_periodic(p: Projectile):
	if p.get_age() > 2:
		var color: Color = Color8(255, 255, 255, 255 - int((p.get_age() - 2) / (3 - 2)) * 255)
		p.set_color(color)

		return

	var it: Iterate = Iterate.over_units_in_range_of(tower, TargetType.new(TargetType.CREEPS), p.get_x(), p.get_y(), 600)

	while true:
		var next: Unit = it.next_random()

		if next == null:
			break

		if next.is_immune():
			break

#		Test if the target is in a 90 degree cone in front
#		of the drake
		var vector_isometric: Vector2 = next.position - p.position
		var vector_top_down: Vector2 = Isometric.top_down_vector_to_isometric(vector_isometric)
		var angle_to_creep: float = rad_to_deg(vector_top_down.angle())
		var angle_diff: float = angle_to_creep - p.get_direction()

		var angle_diff_is_ok: bool = angle_diff <= -310 || angle_diff >= 310 || (angle_diff >= 50 && angle_diff <= 50)

		if !angle_diff_is_ok:
			break

		var offset_vector_top_down: Vector2 = Vector2(100, 0).rotated(rad_to_deg(p.get_direction()))
		var offset_vector_isometric: Vector2 = Isometric.top_down_vector_to_isometric(offset_vector_top_down)
		var from_pos: Vector2 = p.position + offset_vector_isometric

		var atk_proj: Projectile = Projectile.create_linear_interpolation_from_point_to_unit(bronze_drake_attack_pt, tower, 0, 0, from_pos, next, 0.30, true)
		atk_proj.setScale(0.55)


# NOTE: "onBronzeDrakeHit()" in original script
func bronze_drake_attack_pt_on_hit(_p: Projectile, target: Unit):
	var damage_before: float = tower.get_overall_damage()

	if target == null:
		return

	var drake_damage: float = 1250 + 40 * tower.get_level()
	tower.do_spell_damage(target, drake_damage, tower.calc_spell_crit_no_bonus())

	var damage_after: float = tower.get_overall_damage()
	var damage_dealt: float = damage_after - damage_before
	refresh_buff(damage_dealt)


# NOTE: "resetPosition()" in original script
func generic_drake_pt_periodic(p: Projectile):
	var which: int = p.user_int2

	var drake: Drake = drake_list[which]

	p.disable_periodic()

# 	TODO: process z component
	p.position = Vector2(drake.start_pos.x, drake.start_pos.y)
	p.set_speed(0)
	drake.state = DrakeState.IDLE

# 	TODO: implement Projectile.aim_at_point() Should change
# 	direction of projectile, remember to convert between
# 	isometric and top down projections.
#	var final_x: float = p.get_x() + (tower.get_visual_x() - p.get_x()) * 10
#	var final_y: float = p.get_y() + (tower.get_visual_y() - p.get_y()) * 10
#	p.aim_at_point(final_x, final_y, p.get_z(), false, false)
