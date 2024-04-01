extends TowerBehavior


# TODO: need to implement visual. Currently using
# placeholder effect. Need to create an animation scene
# which contains tower's sprite as frames. But single frame?
# because tower has no animation. Maybe spin or something.


var khan_omni_bt: BuffType


func get_ability_description() -> String:
	var text: String = ""

	text += "[color=GOLD]Omnislash[/color]\n"
	text += "On each attack the Omnislasher moves with insane speed towards the battlefield. There, he deals damage up to 10 times before returning to his triumphant pedestal. Each such damage instance deals 10% of this tower's normal attack damage and permanently increases the damage its target takes from Physical type attacks by 4%.\n"
	text += " \n"
	text += "[color=ORANGE]Level Bonus:[/color]\n"
	text += "+2 slashes every 5 levels\n"

	return text


func get_ability_description_short() -> String:
	var text: String = ""

	text += "[color=GOLD]Omnislash[/color]\n"
	text += "On each attack the Omnislasher moves with insane speed towards the battlefield.\n"

	return text


func load_triggers(triggers: BuffType):
	triggers.add_event_on_attack(on_attack)


func load_specials(modifier: Modifier):
	modifier.add_modification(Modification.Type.MOD_DAMAGE_BASE_PERC, 0.0, 0.10)


func tower_init():
	khan_omni_bt = BuffType.new("khan_omni_bt", -1, 0, false, self)
	khan_omni_bt.set_buff_icon("claw.tres")
	khan_omni_bt.set_buff_tooltip("Omnislashed\nIncreases damage taken from Physical attacks.")
	khan_omni_bt.add_event_on_damaged(khan_omni_bt_on_damaged)


# NOTE: implemented this slightly differently than original
# script. Using "await" instead of timer.
func on_attack(event: Event):
	var target: Unit = event.get_target()
	var attack_count: int = 10 + 2 / 5 * tower.get_level()
	var time_between_attacks: float = tower.get_current_attackspeed() / attack_count
	var it: Iterate = Iterate.over_units_in_range_of_unit(tower, TargetType.new(TargetType.CREEPS), target, 1200)

	SFX.sfx_on_unit("MirrorImageCaster.mdl", tower, Unit.BodyPart.ORIGIN)
	
	# NOTE: original script here makes the tower invisible
	# and pauses it. This is because the tower creates an
	# effect that looks like the tower is moving around the
	# game world. In youtd2 there's no such effect model
	# yet, so will keep the tower visible for now.
	# tower.set_sprite_color(tower, Color8(255, 255, 255, 0)
	# PauseUnit(tower, true)

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

	for i in range(0, attack_count):
		await Utils.create_timer(time_between_attacks).timeout

		if !Utils.unit_is_valid(tower):
			return

		if !Utils.unit_is_valid(target):
			target = it.next()
			
		if target == null:
			return

		damage(target)


func damage(target: Unit):
	var the_range: float = 80
	var angle: float = deg_to_rad(Globals.synced_rng.randf_range(0, 360))
	var x: float = target.get_x() + cos(angle) * the_range
	var y: float = target.get_y() + sin(angle) * the_range
	var z: float = 0.0

	var blademaster: int = Effect.create_animated("HeroChaosBladeMaster.mdl", x, y, z, deg_to_rad(angle + 180))
	var mirrorimage: int = Effect.create_animated("MirrorImageCaster.mdl", x, y, z, angle + deg_to_rad(angle))
	var buff: Buff = target.get_buff_of_type(khan_omni_bt)

	Effect.set_lifetime(blademaster, 0.4)
	# Effect.set_animation(blademaster, "attack")
	Effect.set_scale(blademaster, 5)
	Effect.no_death_animation(blademaster)
	Effect.set_lifetime(mirrorimage, 0.4)
	Effect.set_scale(mirrorimage, 5)

	tower.do_attack_damage(target, tower.get_current_attack_damage_with_bonus() / 10, tower.calc_attack_multicrit_no_bonus())

	if buff == null:
		buff = khan_omni_bt.apply(tower, target, tower.get_level())
		var damage_multiplier: float = 1.0
		buff.user_real = damage_multiplier
	else:
		var damage_multiplier: float = buff.user_real + 0.04
		buff.user_real = damage_multiplier


func khan_omni_bt_on_damaged(event: Event):
	var buff: Buff = event.get_buff()
	var caster: Tower = event.get_target()

	if caster.get_attack_type() != AttackType.enm.PHYSICAL:
		return

	if event.is_spell_damage():
		return

	var damage_multiplier: float = buff.user_real
	event.damage *= damage_multiplier
