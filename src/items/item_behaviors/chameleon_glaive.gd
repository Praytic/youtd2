extends ItemBehavior


var chameleon_pt: ProjectileType


func get_ability_description() -> String:
	var text: String = ""

	text += "[color=GOLD]Launch Glaive[/color]\n"
	text += "Whenever the carrier attacks, it has a 40% chance to fire an extra projectile at the target. The projectile deals the same amount of damage as a normal attack and can crit.\n"
	text += " \n"
	text += "[color=ORANGE]Level Bonus:[/color]\n"
	text += "+0.4% chance\n"

	return text


func load_triggers(triggers: BuffType):
	triggers.add_event_on_attack(on_attack)


# NOTE: hit() in original script
func chameleon_pt_on_hit(p: Projectile, creep: Unit):
	if creep == null:
		return

	var tower: Tower = p.get_caster()
	tower.do_attack_damage(creep, tower.get_current_attack_damage_with_bonus(), tower.calc_attack_multicrit(0, 0, 0))


func item_init():
	chameleon_pt = ProjectileType.create("path_to_projectile_sprite", 4, 1000, self)
	chameleon_pt.enable_homing(chameleon_pt_on_hit, 0)


func on_attack(event: Event):
	var tower: Tower = item.get_carrier()
	var creep: Unit = event.get_target()
	var p: Projectile

	if !tower.calc_chance(0.4 + 0.004 * tower.get_level()):
		return

	CombatLog.log_item_ability(item, null, "Launch Glaive!")

	await Utils.create_manual_timer(0.1, self).timeout

	if !Utils.unit_is_valid(tower) || !Utils.unit_is_valid(creep):
		return

	p = Projectile.create_from_unit_to_unit(chameleon_pt, tower, 1, 0, tower, creep, true, false, false)
	p.set_projectile_scale(0.75)
