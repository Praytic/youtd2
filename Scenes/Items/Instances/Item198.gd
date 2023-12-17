# Frog Pipe
extends Item

# NOTE: in original script, collision range was defined by
# calling setCollisionParameters. Removed that because it's
# not needed. Can define when set_collision_enabled() is
# called.

# NOTE: I modified the coloring of projectiles. Set initial
# color to blue and then when projectile starts homing make
# it bluer. Original script uses a green frog model which
# turns blueish later.


var daem_frog_PT: ProjectileType


func get_ability_description() -> String:
	var text: String = ""

	text += "[color=GOLD]Frog Piper[/color]\n"
	text += "Has a 20% chance on attack to summon 4 frogs that deal 100% attack damage when they hit an enemy.\n"
	text += " \n"
	text += "Frogs cannot hit air.\n"

	return text


func load_triggers(triggers: BuffType):
	triggers.add_event_on_attack(on_attack)


func daem_frog_attack(tower: Tower, target: Unit, temp: int):
	var x: float = tower.get_visual_x()
	var y: float = tower.get_visual_y()

	var angle: float = rad_to_deg(atan2(target.get_y() - y, target.get_x() - x))

	var p: Projectile = Projectile.create(daem_frog_PT, tower, 0, 0, x + randi_range(-40, 40), y + randi_range(-40, 40), 5.0, angle + temp)
	p.set_color(Color8(100, 255, 100, 255))
	p.user_int = temp
	p.user_real = tower.get_current_attack_damage_with_bonus()
	p.user_real2 = tower.calc_attack_multicrit_no_bonus()


func daem_frog_PT_on_hit(p: Projectile, target: Unit):
	if target == null:
		return

	var tower: Tower = p.get_caster()
	tower.do_attack_damage(target, p.user_real, p.user_real2)


func item_init():
	daem_frog_PT = ProjectileType.create_ranged("Frog.mdl", 3700.0, 500.0, self)
	daem_frog_PT.enable_collision(daem_frog_PT_on_collision, 190, TargetType.new(TargetType.CREEPS), false)
	daem_frog_PT.enable_homing(daem_frog_PT_on_hit, 0)
	daem_frog_PT.enable_periodic(daem_frog_PT_periodic, 0.60)
	daem_frog_PT.set_acceleration(-36)
	daem_frog_PT.disable_explode_on_hit()


func on_attack(event: Event):
	var itm: Item = self
	var tower: Tower = itm.get_carrier()
	var target: Unit = event.get_target()
	var frog_chance: float = 0.2

	if !tower.calc_chance(frog_chance):
		return

	if target.get_size() != CreepSize.enm.AIR:
		CombatLog.log_ability(tower, target, "Frog Piper")
		
		daem_frog_attack(itm.get_carrier(), target, randi_range(-40, -20))
		daem_frog_attack(itm.get_carrier(), target, randi_range(-20, -0))
		daem_frog_attack(itm.get_carrier(), target, randi_range(0, 20))
		daem_frog_attack(itm.get_carrier(), target, randi_range(20, 40))


func daem_frog_PT_on_collision(p: Projectile, target: Unit):
	if target.get_size() == CreepSize.enm.AIR:
		return

	p.set_speed(500)
	p.set_collision_enabled(false)
	p.set_homing_target(target)
	p.set_acceleration(8)
	p.set_color(Color8(100, 220, 150, 255))
	p.disable_periodic()
	p.set_remaining_lifetime(3.0)


func daem_frog_PT_periodic(projectile: Projectile):
	projectile.user_int *= -1
	projectile.set_speed(500)
	projectile.set_direction(projectile.get_direction() + projectile.user_int)
