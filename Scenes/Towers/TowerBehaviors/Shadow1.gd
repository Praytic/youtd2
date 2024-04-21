extends TowerBehavior


# NOTE: original script uses a built-in "laser" ability. Had
# to re-implement it here using a periodic event and
# lightning visual.

# TODO: this tower's abilities are setup in such a way that
# it will very often steal kills. Here's how it works:
# 1. Tower applies Dark Shroud Aura to tower Foo.
# 2. Tower Foo is about to deal damage.
# 3. Tower Foo emits DAMAGE event.
# 4. Shadow's DAMAGE event handler deals 10% of Foo's damage.
# 5. Shadow has a high chance to deal the killing blow,
#    unless 10% was not enough and the rest 90% of the Foo
#    tower is the killing blow.
# 
# Note sure if this is intentional, or if original youtd
# engine works in a different way so that issue doesn't come
# up. Need to investigate. For example, can build same setup
# of towers in original vs youtd2 and compare the amount of
# kills that Shadow tower gets.


var aura_bt: BuffType
var orb_pt: ProjectileType
var lesser_orb_pt: ProjectileType


func get_ability_description() -> String:
	var text: String = ""

	text += "[color=GOLD]Dark Orbs[/color]\n"
	text += "Each attack has a 20% chance to spawn 3 orbs that travel outwards in all directions from Shadow. Orbs travel for 8 seconds, firing off dark rays at enemies within 450 range, which deal 15% of this tower's attack damage as spell damage per second.\n"
	text += " \n"
	text += "[color=ORANGE]Level Bonus:[/color]\n"
	text += "+1 orb every 5 levels\n"
	text += "+0.6% damage per second\n"
	text += " \n"

	text += "[color=GOLD]Soul Conversion[/color]\n"
	text += "On kill a lesser orb is spawned where the creep died. Lesser orbs last for 3 seconds, firing off lesser dark rays at enemies within 450 range, which deal 9% of this tower's attack damage as spell damage per second.\n"
	text += " \n"
	text += "[color=ORANGE]Level Bonus:[/color]\n"
	text += "+0.36% damage per second\n"
	text += " \n"

	text += "[color=GOLD]Dark Shroud - Aura[/color]\n"
	text += "Towers within 300 range have 10% of their damage output stolen by Shadow. This tower then deals that damage back at its original targets in the form of Decay damage. This damage cannot crit.\n"
	text += " \n"
	text += "[color=ORANGE]Level Bonus:[/color]\n"
	text += "+0.5% damage dealt\n"

	return text


func get_ability_description_short() -> String:
	var text: String = ""

	text += "[color=GOLD]Dark Orbs[/color]\n"
	text += "Chance to spawn orbs that fire off dark rays at enemies in range.\n"
	text += " \n"

	text += "[color=GOLD]Soul Conversion[/color]\n"
	text += "On kill a lesser orb is spawned where the creep died.\n"
	text += " \n"

	text += "[color=GOLD]Dark Shroud - Aura[/color]\n"
	text += "Towers in range have 10% of their damage output stolen by Shadow.\n"

	return text


func load_triggers(triggers: BuffType):
	triggers.add_event_on_attack(on_attack)
	triggers.add_event_on_kill(on_kill)


func tower_init():
	aura_bt = BuffType.create_aura_effect_type("aura_bt", true, self)
	aura_bt.set_buff_icon("mask_occult.tres")
	aura_bt.set_buff_tooltip("Dark Shroud Aura\nA portion of attack damage is stolen and dealt as Decay damage instead.")
	aura_bt.add_event_on_damage(aura_bt_on_damage)

	orb_pt = ProjectileType.create("OrbDarkness.mdl", 8, 200, self)
	orb_pt.enable_periodic(orb_pt_periodic, 1.0)

	lesser_orb_pt = ProjectileType.create("OrbDarkness.mdl", 3, 0, self)
	lesser_orb_pt.enable_periodic(lesser_orb_pt_periodic, 1.0)


func get_aura_types() -> Array[AuraType]:
	var aura: AuraType = AuraType.new()
	aura.aura_range = 300
	aura.target_type = TargetType.new(TargetType.TOWERS)
	aura.target_self = true
	aura.level = 0
	aura.level_add = 1
	aura.power = 0
	aura.power_add = 1
	aura.aura_effect = aura_bt

	return [aura]


func on_attack(_event: Event):
	var level: int = tower.get_level()
	var projectile_count: int = 3 + level / 5
	var x: float = tower.get_x()
	var y: float = tower.get_y()
	var damage_ratio: float = tower.get_current_attack_damage_with_bonus() * (0.05 + 0.002 * level)

	var dark_orbs_chance: float = 0.20

	if !tower.calc_chance(dark_orbs_chance):
		return

	CombatLog.log_ability(tower, null, "Dark Orbs")

	for i in range(0, projectile_count):
		var facing: float = i * 360.0 / projectile_count
		var p: Projectile = Projectile.create(orb_pt, tower, damage_ratio, tower.calc_spell_crit_no_bonus(), Vector3(x, y, 80.0), facing)
		p.set_projectile_scale(1.75)


func on_kill(event: Event):
	var level: int = tower.get_level()
	var creep: Creep = event.get_target()
	var x: float = creep.get_x()
	var y: float = creep.get_y()
	var damage_ratio: float = tower.get_current_attack_damage_with_bonus() * (0.03 + 0.0012 * level)
	var p: Projectile = Projectile.create(lesser_orb_pt, tower, damage_ratio, tower.calc_spell_crit_no_bonus(), Vector3(x, y, 80.0), 0)
	p.set_projectile_scale(1.25)


func aura_bt_on_damage(event: Event):
	var buff: Buff = event.get_buff()
	var caster: Tower = buff.get_caster()
	var target: Unit = event.get_target()
	var damage: float = event.damage * (0.10 + 0.005 * caster.get_level())

	event.damage *= 0.9

	caster.do_custom_attack_damage(target, damage, 1, AttackType.enm.DECAY)


func orb_pt_periodic(p: Projectile):
	orb_pt_periodic_generic(p)


func lesser_orb_pt_periodic(p: Projectile):
	orb_pt_periodic_generic(p)


func orb_pt_periodic_generic(p: Projectile):
	var caster: Unit = p.get_caster()
	var it: Iterate = Iterate.over_units_in_range_of(caster, TargetType.new(TargetType.CREEPS), Vector2(p.get_x(), p.get_y()), 450)

	SFX.sfx_at_unit("SomeKindOfZappySound.mdl", caster)

	while true:
		var next: Unit = it.next()

		if next == null:
			break

		var start_pos: Vector3 = Vector3(p.get_x(), p.get_y(), 0)
		var lightning: InterpolatedSprite = InterpolatedSprite.create_from_point_to_unit(InterpolatedSprite.LIGHTNING, start_pos, next)
		lightning.modulate = Color.PURPLE
		lightning.set_lifetime(0.1)

		p.do_spell_damage(next, 1.0)
