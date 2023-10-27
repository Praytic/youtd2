# Frog Pipe
extends Item

# NOTE: in original script, collision range was defined by
# calling setCollisionParameters. Removed that because it's
# not needed. Can define when set_collision_enabled() is
# called.

# TODO: disabled until complete. Need to implement periodic
# events for Projectile.

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


func daem_frog_attack(_tower: Tower, _target: Unit, _temp: int):
	pass


func daem_frog_collision(p: Projectile, target: Unit):
	var tower: Tower = p.get_caster()
	tower.do_attack_damage(target, p.user_real, p.user_real2)


func item_init():
	daem_frog_PT = ProjectileType.create_ranged("Frog.mdl", 3700.0, 500.0, self)
#    daem_frog_PT.enable_collision(daem_frog_home, 190, TargetType.new(TargetType.CREEPS), false)
	daem_frog_PT.enable_homing(daem_frog_collision, 0)
	# daem_frog_PT.enable_periodic(daem_frog_periodic, 0.60)
	daem_frog_PT.set_acceleration(-36)
	daem_frog_PT.disable_explode_on_hit()


func on_attack(event: Event):
	var itm: Item = self
	var target: Unit = event.get_target()

	if target.get_size() != CreepSize.enm.AIR:
		daem_frog_attack(itm.get_carrier(), target, randi_range(-40, -20))
		daem_frog_attack(itm.get_carrier(), target, randi_range(-20, -0))
		daem_frog_attack(itm.get_carrier(), target, randi_range(0, 20))
		daem_frog_attack(itm.get_carrier(), target, randi_range(20, 40))
