extends TowerBehavior


# TODO: look into "Storm Bolt" ability more. It creates a
# line of AoE when projectile hits. The angle of the line is
# equal to projectile's angle. Currently, that means the
# angle of the projectile's movement right before it hit the
# creep. This means that when projectile is turning fast at
# the end the angle can be something unexpected. Check in
# original youtd. Maybe this angle needs to be the angle
# between tower and creep if projectile is interpolated?


var stun_bt: BuffType
var hammer_fall_bt: BuffType
var stormbolt_pt: ProjectileType
var hammer_pt: ProjectileType


func load_triggers(triggers: BuffType):
	triggers.add_event_on_attack(on_attack)
	triggers.add_event_on_damage(on_damage)


func tower_init():
	tower.hide_attack_projectiles()

	stun_bt = CbStun.new("gryphon_rider_stun", 0, 0, false, self)
	
	hammer_fall_bt = BuffType.new("hammer_fall_bt", 6, 0, false, self)
	var hammer_fall_bt_mod: Modifier = Modifier.new()
	hammer_fall_bt_mod.add_modification(Modification.Type.MOD_DAMAGE_ADD_PERC, -0.1, 0.0)
	hammer_fall_bt.set_buff_modifier(hammer_fall_bt_mod)
	hammer_fall_bt.set_buff_icon("res://resources/icons/generic_icons/hammer_drop.tres")
	hammer_fall_bt.set_buff_tooltip("Hammer Fall\nReduces attack damage.")

	stormbolt_pt = ProjectileType.create_interpolate("path_to_projectile_sprite", 1100, self)
	stormbolt_pt.set_event_on_interpolation_finished(stormbolt_pt_on_hit)

	hammer_pt = ProjectileType.create("path_to_projectile_sprite", 90, 0, self)
	hammer_pt.enable_physics(hammer_pt_on_impact, -30)


func on_attack(event: Event):
	var target: Unit = event.get_target()
	Projectile.create_linear_interpolation_from_unit_to_unit(stormbolt_pt, tower, 1.0, 1.0, tower, target, 0.15, true)


func on_damage(event: Event):
	event.damage = 0


func on_autocast(event: Event):
	var target: Unit = event.get_target()

	var p: Projectile = Projectile.create_from_unit(hammer_pt, tower, target, 0, 1.0, 1.0)
	p.set_z(1000)

	var it: Iterate = Iterate.over_units_in_range_of_caster(tower, TargetType.new(TargetType.PLAYER_TOWERS), 2500.0)
	var damage_multiplier: float = 1.0
	var damage_multiplier_per_tower: float = 0.05 + 0.002 * tower.get_level()

	while true:
		var next: Tower = it.next()

		if next == null:
			break

		if next.get_element() == Element.enm.STORM:
			damage_multiplier += damage_multiplier_per_tower
			hammer_fall_bt.apply(tower, next, 0)

		if damage_multiplier >= 2.0:
			break

	p.user_real *= damage_multiplier


func stormbolt_pt_on_hit(p: Projectile, target: Unit):
	if target != null:
		var stormbolt_damage: float = tower.get_current_attack_damage_with_bonus()
		deal_damage(target, stormbolt_damage)

	line_damage(Vector2(p.get_x(), p.get_y()), p.get_direction())


# NOTE: impact() in original script
func hammer_pt_on_impact(p: Projectile):
	var it: Iterate = Iterate.over_units_in_range_of(tower, TargetType.new(TargetType.CREEPS), Vector2(p.get_x(), p.get_y()), 600.0)
	var hammer_damage: float = p.user_real

	while true:
		var next: Unit = it.next()

		if next == null:
			break

		deal_damage(next, hammer_damage)
		stun_bt.apply_only_timed(tower, next, 1.0)


func deal_damage(target: Unit, damage: float):
	var spell: float = target.get_prop_spell_damage_received()
	var phys: float = target.get_prop_atk_damage_received()
	var r: float = 0.0
	var crit: float = 0.0

#	calc spell damage taken
#	Immune?
	if target.is_immune():
#		0% spell damage
		spell = 0

#	calc physical damage taken
#	Ethereal?
	if target.is_ethereal():
#		0% physical damage
		phys = 0
	else:
#		armor
		phys *= target.get_current_armor_damage_reduction()

#	we don't want anything below zero!
	if spell < 0.0:
		spell = 0

	if phys < 0.0:
		phys = 0

#	Result are how much physical and spell damage the unit takes.
#	Probably adding these two wont result in 100% so we have to scale them
	r = spell + phys
	if r <= 0:
#		shit happened...
		return

	if r != 1.0:
		spell /= r
		phys /= r

#	crit bonus?
	if phys == 1.0 || spell == 1.0:
		crit = 0.05 + 0.018 * tower.get_level()

# 	Now we know what we need to know to deal damage
	tower.do_spell_damage(target, damage * spell, tower.calc_spell_crit(crit, 0.0))
	tower.do_attack_damage(target, damage * phys, tower.calc_attack_multicrit(crit, 0, 0))


func line_damage(origin_pos: Vector2, direction: float):
	var distance: float = 128.0
	var damage: float = tower.get_current_attack_damage_with_bonus()
	var i: int = 0
	var dmg_multiplier: float = 0.6 + 0.012 * tower.get_level()

	while true:
		if i >= 5 || !Utils.unit_is_valid(tower):
			break

		var current_distance: float = distance * i
		var offset: Vector2 = Vector2.from_angle(deg_to_rad(direction)) * current_distance
		var current_pos: Vector2 = origin_pos + offset

		var it: Iterate = Iterate.over_units_in_range_of(tower, TargetType.new(TargetType.CREEPS), Vector2(current_pos.x, current_pos.y), 85)

		while true:
			var next: Unit = it.next()

			if next == null:
				break

			deal_damage(next, damage)

		var clap_effect: int = Effect.create_animated("res://src/effects/thunder_clap.tscn", Vector3(current_pos.x, current_pos.y, 0.0), 0.0)
		Effect.set_scale(clap_effect, 0.5)
		var bolt_effect: int = Effect.create_animated("res://src/effects/holy_bolt.tscn", Vector3(current_pos.x, current_pos.y, 0.0), 0)
		Effect.set_color(bolt_effect, Color.SILVER)

		damage *= dmg_multiplier
		i += 1
		await Utils.create_manual_timer(0.15, self).timeout
