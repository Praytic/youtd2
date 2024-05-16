extends TowerBehavior


# NOTE: changed how the "mirror image" VFX is implemented by
# a lot. Original script uses Effect with models and attack
# animations. Don't have access to those things so used a
# moving projectile instead with sprite of tower.


var omnislashed_bt: BuffType
var mirror_image_pt: ProjectileType


func get_ability_info_list() -> Array[AbilityInfo]:
	var physical_string: String = AttackType.convert_to_colored_string(AttackType.enm.PHYSICAL)

	var list: Array[AbilityInfo] = []
	
	var ability: AbilityInfo = AbilityInfo.new()
	ability.name = "Omnislash"
	ability.icon = "res://resources/Icons/daggers/dagger_07.tres"
	ability.description_short = "On each attack the Omnislasher moves with insane speed towards the battlefield.\n"
	ability.description_full = "On each attack the Omnislasher moves with insane speed towards the battlefield. There, he deals attack damage up to 10 times before returning to his triumphant pedestal. Each such damage instance deals 10%% of this tower's normal attack damage and permanently increases the damage its target takes from %s type attacks by 4%%.\n" % physical_string \
	+ " \n" \
	+ "Note: Omnislasher won't trigger any \"on hit\" abilities from items or other towers.\n" \
	+ " \n" \
	+ "[color=ORANGE]Level Bonus:[/color]\n" \
	+ "+2 slashes every 5 levels\n"
	list.append(ability)

	return list


func load_triggers(triggers: BuffType):
	triggers.add_event_on_attack(on_attack)


func load_specials(modifier: Modifier):
	modifier.add_modification(Modification.Type.MOD_DAMAGE_BASE_PERC, 0.0, 0.10)


func tower_init():
	omnislashed_bt = BuffType.new("omnislashed_bt", -1, 0, false, self)
	omnislashed_bt.set_buff_icon("res://resources/Icons/GenericIcons/triple_scratches.tres")
	omnislashed_bt.set_buff_tooltip("Omnislashed\nIncreases damage taken from Physical attacks.")
	omnislashed_bt.add_event_on_damaged(omnislashed_bt_on_damaged)

	mirror_image_pt = ProjectileType.create_interpolate("res://Scenes/Projectiles/ProjectileVisuals/OmnislasherMirrorImage.tscn", 1000.0, self)
	mirror_image_pt.set_event_on_interpolation_finished(mirror_image_pt_on_interpolation_finished)
	mirror_image_pt.disable_explode_on_hit()


# NOTE: implemented this slightly differently than original
# script. Using "await" instead of timer.
func on_attack(event: Event):
	var target: Unit = event.get_target()
	var attack_count: int = 10 + 2 / 5 * tower.get_level()
	var time_between_attacks: float = tower.get_current_attack_speed() / attack_count
	var it: Iterate = Iterate.over_units_in_range_of_unit(tower, TargetType.new(TargetType.CREEPS), target, 1200)

	SFX.sfx_on_unit("MirrorImageCaster.mdl", tower, Unit.BodyPart.ORIGIN)
	
	tower.set_sprite_color(Color8(255, 255, 255, 100))

# 	NOTE: original script calls PauseUnit() here and after
# 	the end of the Omnislash ability. This means that the
# 	tower never actually shoots the attack projectile.
# 	Replicate this behavior by calling order_stop().
	tower.order_stop()

	var fun_text: String
	var fun_value: float = Globals.synced_rng.randf_range(0, 1.0)
	if fun_value < 0.03:
		fun_text = "I'm faster than LIGHT!"
	elif fun_value < 0.02:
		fun_text = "Don't listen to Einstein's lies!"
	elif fun_value < 0.01:
		fun_text = "I'm debunking relativity. Just watch me!"
	else:
		fun_text = ""

	if !fun_text.is_empty():
		tower.get_player().display_floating_text_x(fun_text, tower, Color8(50, 150, 255, 255), 0.05, 2, 3)

	var p: Projectile = Projectile.create_linear_interpolation_from_unit_to_unit(mirror_image_pt, tower, 0, 0, tower, target, 0.1, true)
#	NOTE: set a very high speed for first movement from tower to target so that projectile reaches the target on time
	p.set_speed(5000)

	for i in range(0, attack_count):
		await Utils.create_timer(time_between_attacks, self).timeout

		if !Utils.unit_is_valid(tower):
			break

		if !Utils.unit_is_valid(target):
			target = it.next()
			
		if target == null:
			break

		var random_angle: float = deg_to_rad(Globals.synced_rng.randf_range(0, 360))
		var random_offset: Vector2 = Vector2(80, 0).rotated(random_angle)
		var projectile_pos: Vector3 = Vector3(
			target.get_x() + random_offset.x,
			target.get_y() + random_offset.y,
			target.get_z())
		p.start_interpolation_to_point(projectile_pos, 0.1)
#		NOTE: reduce speed to normal value for moves after first one
		p.set_speed(1000)

		damage(target)

	p.remove_from_game()
	tower.set_sprite_color(Color8(255, 255, 255, 255))


func damage(target: Unit):
	var buff: Buff = target.get_buff_of_type(omnislashed_bt)

	tower.do_attack_damage(target, tower.get_current_attack_damage_with_bonus() / 10, tower.calc_attack_multicrit_no_bonus())

	if buff == null:
		buff = omnislashed_bt.apply(tower, target, tower.get_level())
		var damage_multiplier: float = 1.0
		buff.user_real = damage_multiplier
	else:
		var damage_multiplier: float = buff.user_real + 0.04
		buff.user_real = damage_multiplier


func omnislashed_bt_on_damaged(event: Event):
	var buff: Buff = event.get_buff()
	var caster: Tower = event.get_target()

	if caster.get_attack_type() != AttackType.enm.PHYSICAL:
		return

	if event.is_spell_damage():
		return

	var damage_multiplier: float = buff.user_real
	event.damage *= damage_multiplier


func mirror_image_pt_on_interpolation_finished(projectile: Projectile, _target: Unit):
	projectile.avert_destruction()
