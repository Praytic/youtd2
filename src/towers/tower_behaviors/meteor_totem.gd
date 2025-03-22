extends TowerBehavior


# NOTE: [ORIGINAL_GAME_DEVIATION] The autocast target_self in original script is set
# to true BUT the autocast callback does a check "if target
# != tower:", so the final behavior is Meteor Totem does NOT
# apply the Attraction buff to itself.
# 
# I set autocast target_self to false to make it less
# confusing.

# NOTE: [ORIGINAL_GAME_DEVIATION] Changed autocast type
# AC_TYPE_ALWAYS_BUFF->AC_TYPE_ALWAYS_IMMEDIATE because it
# buffs multiple towers.


var attraction_bt: BuffType
var torture_bt: BuffType
var missile_pt: ProjectileType



func load_triggers(triggers: BuffType):
	triggers.add_event_on_damage(on_damage)


func tower_init():
	attraction_bt = BuffType.new("attraction_bt", 2.5, 0.05, true, self)
	attraction_bt.add_event_on_attack(attraction_bt_on_attack)
	attraction_bt.add_event_on_spell_casted(attraction_bt_on_spell_casted)
	attraction_bt.set_buff_icon("res://resources/icons/generic_icons/burning_meteor.tres")
	attraction_bt.set_buff_tooltip(tr("TNB5"))

	torture_bt = BuffType.new("torture_bt", 2.5, 0.05, false, self)
	torture_bt.set_buff_icon("res://resources/icons/generic_icons/animal_skull.tres")
	torture_bt.add_event_on_damaged(torture_bt_on_damaged)
	torture_bt.set_buff_tooltip(tr("SUFS"))

	missile_pt = ProjectileType.create_interpolate("path_to_projectile_sprite", 950, self)
	missile_pt.set_event_on_interpolation_finished(missile_pt_on_hit)


func on_damage(event: Event):
	var target: Unit = event.get_target()
	torture_bt.apply(tower, target, tower.get_level())


func on_autocast(_event: Event):
	var it: Iterate = Iterate.over_units_in_range_of_caster(tower, TargetType.new(TargetType.TOWERS), 500)
	var number: int = 4 + int(tower.get_level() / 5)

	while true:
		var target: Unit = it.next_random()

		if target == null || number == 0:
			break

		if target != tower:
			var buff: Buff = attraction_bt.apply(tower, target, tower.get_level())
			buff.user_int = 0
			number -= 1


func missile_pt_on_hit(projectile: Projectile, target: Unit):
	var buffed_tower: Tower = projectile.get_caster()
	buffed_tower.do_spell_damage_aoe(Vector2(projectile.get_x(), projectile.get_y()), 220, projectile.user_int, buffed_tower.calc_spell_crit_no_bonus(), 0)
	
	if target != null:
		var effect: int = Effect.create_simple_at_unit("res://src/effects/doom_death.tscn", target, Unit.BodyPart.ORIGIN)
		Effect.set_z_index(effect, Effect.Z_INDEX_BELOW_CREEPS)


func attraction_bt_on_attack(event: Event):
	var buff: Buff = event.get_buff()
	var buffed: Tower = buff.get_buffed_unit()

	if buffed.calc_chance(buffed.get_base_attack_speed() * 0.35):
		var triggered_by_attack: bool = true
		release_meteor(buff, triggered_by_attack)


func attraction_bt_on_spell_casted(event: Event):
	var buff: Buff = event.get_buff()
	var triggered_by_attack: bool = false
	release_meteor(buff, triggered_by_attack)


func release_meteor(buff: Buff, triggered_by_attack: bool):
	var buffed: Tower = buff.get_buffed_unit()
	var it: Iterate = Iterate.over_units_in_range_of_caster(buffed, TargetType.new(TargetType.CREEPS), 1000)
	var result: Unit = it.next_random()
	var level: int = tower.get_level()

	if result != null:
		var projectile: Projectile = Projectile.create_bezier_interpolation_from_unit_to_unit(missile_pt, buffed, 1.0, 1.0, buffed, result, 0.0, 0, 0.0, true)
		
		var projectile_damage: int
		if triggered_by_attack:
			projectile_damage = 200 + 8 * level
		else:
			projectile_damage = 500 + 20 * level

		projectile.user_int = projectile_damage

	buff.remove_buff()


func torture_bt_on_damaged(event: Event):
	var buff: Buff = event.get_buff()
	var caster: Tower = buff.get_caster()
	var damage: float = event.damage * (0.08 + 0.001 * caster.get_level())
	var target: Creep = buff.get_buffed_unit()

	if event.damage >= 500 && !event.is_spell_damage():
		caster.do_spell_damage(target, damage, 1.0)
		var floating_text: String = Utils.format_float(damage * caster.get_prop_spell_damage_dealt(), 0)
		caster.get_player().display_small_floating_text(floating_text, target, Color8(255, 150, 150), 20)
