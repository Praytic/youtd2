# Hippogryph Egg
extends ItemBehavior


# NOTE: fixed bug in original script where it used incorrect
# order of args for do_spell_damage_aoe()


var hippo_pt: ProjectileType


func get_ability_description() -> String:
	var text: String = ""

	text += "[color=GOLD]Hippogryph Young[/color]\n"
	text += "Grants a 15% attackspeed adjusted chance on attack to release a hippogryph that attacks the target, dealing 1250 spell damage in 200 range of the target.\n"
	text += " \n"
	text += "Level Bonus:\n"
	text += "+50 spell damage\n"

	return text


func load_triggers(triggers: BuffType):
	triggers.add_event_on_attack(on_attack)


# NOTE: hippoHit() in original script
func hippo_pt_on_hit(p: Projectile, creep: Unit):
	if creep == null:
		return

	var caster: Unit = p.get_caster()

	if creep.is_immune() == false:
		caster.do_spell_damage_aoe(p.get_x(), p.get_y(), 200, 1250 + caster.get_level() * 50, caster.calc_spell_crit_no_bonus(), 1.0)
		var effect: int = Effect.create_scaled("AncientProtectorMissile", p.get_x(), p.get_y(), 0, 0, 5)
		Effect.destroy_effect_after_its_over(effect)


func item_init():
	hippo_pt = ProjectileType.create("Hippogryph.mdl", 20, 800, self)
	hippo_pt.disable_explode_on_hit()
	hippo_pt.disable_explode_on_expiration()
	hippo_pt.enable_homing(hippo_pt_on_hit, 0)


func on_attack(event: Event):
	var twr: Tower = item.get_carrier()
	var p: Projectile

	if twr.calc_chance((0.15 * twr.get_base_attackspeed())):
		CombatLog.log_item_ability(item, event.get_target(), "Hippogryph Young")
		p = Projectile.create_from_unit_to_unit(hippo_pt, twr, 1, twr.calc_spell_crit_no_bonus(), twr, event.get_target(), true, false, false)
		p.setScale(0.6)
