# Hippogryph Egg
extends Item

var drol_hippo: ProjectileType


func get_extra_tooltip_text() -> String:
	var text: String = ""

	text += "[color=GOLD]Hippogryph Young[/color]\n"
	text += "Grants a 15% attackspeed adjusted chance on attack to release a hippogryph that attacks the target, dealing 1250 spell damage in 200 range of the target.\n"
	text += " \n"
	text += "Level Bonus:\n"
	text += "+50 spell damage\n"

	return text


func load_triggers(triggers: BuffType):
	triggers.add_event_on_attack(on_attack)


func hippo_hit(p: Projectile, creep: Unit):
	var caster: Unit = p.get_caster()

	if creep.is_immune() == false:
		caster.do_spell_damage_aoe(p.position.x, p.position.y, 200, 1250 + caster.get_level() * 50, 1.0, caster.calc_spell_crit_no_bonus())
		var effect: int = Effect.create_scaled("AncientProtectorMissile", p.global_position.x, p.global_position.y, 0, 0, 0.8)
		Effect.destroy_effect_after_its_over(effect)


func item_init():
	drol_hippo = ProjectileType.create("Hippogryph.mdl", 20, 800)
	drol_hippo.disable_explode_on_hit()
	drol_hippo.disable_explode_on_expiration()
	drol_hippo.enable_homing(hippo_hit, 0)


func on_attack(event: Event):
	var itm: Item = self
	var twr: Tower = itm.get_carrier()
	var p: Projectile

	if twr.calc_chance((0.15 * twr.get_base_attack_speed())):
		p = Projectile.create_from_unit_to_unit(drol_hippo, twr, 1, twr.calc_spell_crit_no_bonus(), twr, event.get_target(), true, false, false)
		p.setScale(0.6)
