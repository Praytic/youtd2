extends Tower


var billy_snowball: ProjectileType
var cb_stun: BuffType


func get_tier_stats() -> Dictionary:
	return {
		1: {dmg_to_champion = 0.08, dmg_to_champion_add = 0.006, dmg_to_boss = 0.10, dmg_to_boss_add = 0.01, stun_temple_duration = 0.6, stun_knockdown_duration = 0.4, hit_chance_add = 0.01},
		2: {dmg_to_champion = 0.10, dmg_to_champion_add = 0.007, dmg_to_boss = 0.125, dmg_to_boss_add = 0.012, stun_temple_duration = 0.8, stun_knockdown_duration = 0.6, hit_chance_add = 0.0125},
		3: {dmg_to_champion = 0.12, dmg_to_champion_add = 0.008, dmg_to_boss = 0.15, dmg_to_boss_add = 0.014, stun_temple_duration = 1.0, stun_knockdown_duration = 0.8, hit_chance_add = 0.014},
	}


func get_ability_description() -> String:
	var stun_temple_duration: String = Utils.format_float(_stats.stun_temple_duration, 2)
	var stun_knockdown_duration: String = Utils.format_float(_stats.stun_knockdown_duration, 2)
	var hit_chance_add: String = Utils.format_percent(_stats.hit_chance_add, 2)

	var text: String = ""

	text += "[color=GOLD]Vicious Snow Ball[/color]\n"
	text += "Throws a fast snowball on attack at the target's head when it's not facing this tower. But the snowball only has a 20% chance to hit, where it hits is decided by the angle of attack.\n"
	text += " \n"
	text += "Temple Crusher : If it hits side-on, does 120%% of its attack damage as spell damage and a %s second stun.\n" % stun_temple_duration
	text += " \n"
	text += "Knockdown : If it hits the back of the head, does 40%% of its attack damage as spell damage and a %s second stun.\n" % stun_knockdown_duration
	text += " \n"
	text += "[color=ORANGE]Level Bonus:[/color]\n"
	text += "+%s chance to hit\n" % hit_chance_add

	return text


func get_ability_description_short() -> String:
	var text: String = ""

	text += "[color=GOLD]Vicious Snow Ball[/color]\n"
	text += "Hurls snowballs at the enemies heads.\n"

	return text


func load_triggers(triggers: BuffType):
	triggers.add_event_on_attack(on_attack)


func load_specials(modifier: Modifier):
	modifier.add_modification(Modification.Type.MOD_DMG_TO_CHAMPION, _stats.dmg_to_champion, _stats.dmg_to_champion_add)
	modifier.add_modification(Modification.Type.MOD_DMG_TO_BOSS, _stats.dmg_to_boss, _stats.dmg_to_boss_add)
	modifier.add_modification(Modification.Type.MOD_DMG_TO_AIR, -0.20, 0.0)


func billy_snowball_hit(p: Projectile, target: Unit):
	var t: Unit = p.get_caster()

	if p.user_int == 0:
		t.get_player().display_floating_text_x_2("missed", target, 150, 50, 0, 155, 0.07, 1, 2, 0.018, 0)
	else:
		t.do_spell_damage(target, p.user_real, t.calc_spell_crit_no_bonus())
		cb_stun.apply_only_timed(t, target, p.user_real2)
		SFX.sfx_at_unit("FrostBoltMissile.mdl", target)

		if p.user_int2 == 1:
			t.get_player().display_floating_text_x_2("Temple Crusher!", target, 150, 50, 255, 200, 0.07, 2, 3, 0.026, 0)
		else:
			t.get_player().display_floating_text_x_2("Knockdown!", target, 0, 0, 255, 155, 0.07, 1.5, 3, 0.022, 0)


func tower_init():
	billy_snowball = ProjectileType.create_interpolate("AIobTarget.mdl", 2000, self)
	billy_snowball.enable_homing(billy_snowball_hit, 0)

	cb_stun = BuffType.new("cb_stun", 0, 0, false, self)


func on_attack(event: Event):
	var tower: Tower = self
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
		p = Projectile.create_from_unit_to_unit(billy_snowball, tower, 100, 0, tower, event.get_target(), true, false, true)
		p.setScale(0.8)

		if facing_delta <= 100:
#			Temple shot
			p.user_int2 = 1
			p.user_real = tower.get_current_attack_damage_with_bonus() * 1.2
			p.user_real2 = _stats.stun_temple_duration
		else:
#			Back of the head
			p.user_int2 = 2
			p.user_real = tower.get_current_attack_damage_with_bonus() * 0.5
			p.user_real2 = _stats.stun_knockdown_duration

#		Decide hit/miss
		if tower.calc_chance(0.20 + tower.get_level() * _stats.hit_chance_add):
#			Hit
			p.user_int = 1
		else:
#			Miss
			p.user_int = 0
