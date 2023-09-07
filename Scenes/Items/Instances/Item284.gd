# Chameleon Glaive
extends Item


var boekie_multi_gun: ProjectileType


func get_extra_tooltip_text() -> String:
	var text: String = ""

	text += "[color=GOLD]Launch Glaive[/color]\n"
	text += "The carrier has a 40% chance on attack to fire an extra projectile that deals the same amount of damage as a normal attack. Can crit.\n"
	text += " \n"
	text += "[color=ORANGE]Level Bonus:[/color]\n"
	text += "+0.4% chance\n"

	return text


func load_triggers(triggers: BuffType):
	triggers.add_event_on_attack(on_attack)


func hit(p: Projectile, creep: Unit):
	var tower: Tower = p.get_caster()
	tower.do_attack_damage(creep, tower.get_current_attack_damage_with_bonus(), tower.calc_attack_multicrit(0, 0, 0))


func item_init():
	boekie_multi_gun = ProjectileType.create("GlaiveMissile.mdl", 4, 1000)
	boekie_multi_gun.enable_homing(hit, 0)


func on_attack(event: Event):
	var itm: Item = self
	var tower: Tower = itm.get_carrier()
	var creep: Unit = event.get_target()
	var p: Projectile

	if !tower.calc_chance(0.4 + 0.004 * tower.get_level()):
		return

	await get_tree().create_timer(0.1).timeout

	if !Utils.unit_is_valid(tower) || !Utils.unit_is_valid(creep):
		return

	p = Projectile.create_from_unit_to_unit(boekie_multi_gun, tower, 1, 0, tower, creep, true, false, false)
	p.setScale(0.75)
