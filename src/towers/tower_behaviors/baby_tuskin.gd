extends TowerBehavior


# NOTE: [ORIGINAL_GAME_DEVIATION] Renamed
# "Baby Tuskar"=>"Baby Tuskin"


var snowball_pt: ProjectileType
var stun_bt: BuffType


func get_tier_stats() -> Dictionary:
	return {
		1: {stun_temple_duration = 0.6, stun_knockdown_duration = 0.4, hit_chance_add = 0.01},
		2: {stun_temple_duration = 0.8, stun_knockdown_duration = 0.6, hit_chance_add = 0.0125},
		3: {stun_temple_duration = 1.0, stun_knockdown_duration = 0.8, hit_chance_add = 0.014},
	}


func load_triggers(triggers: BuffType):
	triggers.add_event_on_attack(on_attack)


func snowball_pt_on_hit(p: Projectile, target: Unit):
	if target == null:
		return

	var t: Unit = p.get_caster()

	if p.user_int == 0:
		CombatLog.log_ability(t, target, "Snow Ball miss")

		var miss_text: String = tr("FLOATING_TEXT_MISS")
		t.get_player().display_floating_text_x_2(miss_text, target, Color8(150, 50, 0, 155), 0.07, 1, 2, 0.018, 0)
	else:
		t.do_spell_damage(target, p.user_real, t.calc_spell_crit_no_bonus())
		stun_bt.apply_only_timed(t, target, p.user_real2)
		Effect.create_simple_at_unit("res://src/effects/frost_bolt_missile.tscn", target)
		SFX.sfx_at_unit(SfxPaths.POW, target)

		if p.user_int2 == 1:
			CombatLog.log_ability(t, target, "Snow Ball Temple Crusher")
			
			var temple_crusher_text: String = tr("IQQP")
			t.get_player().display_floating_text_x_2(temple_crusher_text, target, Color8(150, 50, 255, 200), 0.07, 2, 3, 0.026, 0)
		else:
			CombatLog.log_ability(t, target, "Snow Ball Knockdown")
			
			var knockdown_text: String = tr("IM7N")
			t.get_player().display_floating_text_x_2(knockdown_text, target, Color8(0, 0, 255, 155), 0.07, 1.5, 3, 0.022, 0)


func tower_init():
	snowball_pt = ProjectileType.create("path_to_projectile_sprite", 0.0, 2000, self)
	snowball_pt.enable_homing(snowball_pt_on_hit, 0)

	stun_bt = BuffType.new("stun_bt", 0, 0, false, self)


func on_attack(event: Event):
	var u: Unit = event.get_target()
	var facing_delta: float
	var unit_to_tower_vector: float = rad_to_deg(atan2(tower.get_y() - u.get_y(), tower.get_x() - u.get_x()))
	var p: Projectile

	if unit_to_tower_vector < 0:
		unit_to_tower_vector += 360

	facing_delta = unit_to_tower_vector - u.get_unit_facing()

	if facing_delta < 0:
		facing_delta += 360

	if facing_delta > 180:
		facing_delta = 360 - facing_delta

	if facing_delta >= 80:
		p = Projectile.create_from_unit_to_unit(snowball_pt, tower, 100, 0, tower, event.get_target(), true, false, true)
		p.set_projectile_scale(0.8)

		if facing_delta <= 100:
#			Temple shot
			CombatLog.log_ability(tower, u, "Create Snow Ball Temple Crusher")

			p.user_int2 = 1
			p.user_real = tower.get_current_attack_damage_with_bonus() * 1.2
			p.user_real2 = _stats.stun_temple_duration
		else:
#			Back of the head
			CombatLog.log_ability(tower, u, "Create Snow Ball back of the head")
			p.user_int2 = 2
			p.user_real = tower.get_current_attack_damage_with_bonus() * 0.5
			p.user_real2 = _stats.stun_knockdown_duration

#		Decide hit/miss
		if tower.calc_chance(0.20 + tower.get_level() * _stats.hit_chance_add):
#			Hit
			CombatLog.log_ability(tower, u, "Create Snow Ball hit")
			p.user_int = 1
		else:
#			Miss
			CombatLog.log_ability(tower, u, "Create Snow Ball miss")
			p.user_int = 0
