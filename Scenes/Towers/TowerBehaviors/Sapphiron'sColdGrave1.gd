extends TowerBehavior


var cedi_sapphiron_bt: BuffType
var shard_pt: ProjectileType


func get_ability_description() -> String:
	var text: String = ""

	text += "[color=GOLD]Ice Shard[/color]\n"
	text += "This tower fires an ice shard towards an enemy. After a distance of 300 the ice shard splits into 2 new shards which will split again. If a shard collides with an enemy it deals 2280 spell damage. There is a maximum of 4 splits.\n"
	text += " \n"
	text += "[color=ORANGE]Level Bonus:[/color]\n"
	text += "+85 damage\n"
	text += " \n"

	text += "[color=GOLD]Liquide Ice[/color]\n"
	text += "Each time an ice shard damages an enemy, it decreases the target's defense against ice towers. The target takes 15% more damage from attacks of ice towers. The effect lasts until the creep's death and stacks.\n"
	text += " \n"
	text += "[color=ORANGE]Level Bonus:[/color]\n"
	text += "+0.4% damage increase\n"

	return text


func get_ability_description_short() -> String:
	var text: String = ""

	text += "[color=GOLD]Ice Shard[/color]\n"
	text += "Fires an ice shard towards an enemy which splits into multiple shards.\n"
	text += " \n"

	text += "[color=GOLD]Liquide Ice[/color]\n"
	text += "Each time an ice shard damages an enemy, it decreases the target's defense against ice towers.\n"

	return text


func load_triggers(triggers: BuffType):
	triggers.add_event_on_damage(on_damage)


func tower_init():
	shard_pt = ProjectileType.create_ranged("LichMissile.mdl", 300, 400, self)
	shard_pt.set_event_on_expiration(shard_pt_on_expiration)
	shard_pt.enable_collision(shard_pt_on_collide, 75, TargetType.new(TargetType.CREEPS), true)

	cedi_sapphiron_bt = BuffType.new("cedi_sapphiron_bt", -1, 0, false, self)
	cedi_sapphiron_bt.set_buff_icon("fireball.tres")
	cedi_sapphiron_bt.set_buff_tooltip("Liquide Ice\nIncreases damage taken from Ice towers.")


func on_damage(event: Event):
	var target: Unit = event.get_target()

	var p: Projectile = Projectile.create_from_unit_to_unit(shard_pt, tower, 1.0, tower.calc_spell_crit_no_bonus(), tower, target, false, true, false)
	var splits_remaining: int = 4
	p.user_int = splits_remaining


func shard_pt_on_expiration(p: Projectile):
	var splits_remaining: int = p.user_int
	var angle: float = p.get_direction()

	if splits_remaining > 0:
		splits_remaining -= 1
		p.user_int = splits_remaining
		p = Projectile.create(shard_pt, tower, 1.0, tower.calc_spell_crit_no_bonus(), p.get_x(), p.get_y(), p.get_z(), angle + 15.0)
		p.user_int = splits_remaining
		p = Projectile.create(shard_pt, tower, 1.0, tower.calc_spell_crit_no_bonus(), p.get_x(), p.get_y(), p.get_z(), angle - 15.0)
		p.user_int = splits_remaining


func shard_pt_on_collide(p: Projectile, target: Unit):
	var caster: Unit = p.get_caster()
	var buff: Buff = target.get_buff_of_type(cedi_sapphiron_bt)
	var dmg_from_ice_add: float = 0.15 + 0.004 * caster.get_level()
	var damage: float = 2280 + 85 * caster.get_level()

	caster.do_spell_damage(target, damage, caster.calc_spell_crit_no_bonus())
	SFX.sfx_at_unit("FrostNovaTarget.mdl", target)
	target.modify_property(Modification.Type.MOD_DMG_FROM_ICE, dmg_from_ice_add)

	if buff == null:
		buff = cedi_sapphiron_bt.apply(caster, target, 1)
		buff.user_real = dmg_from_ice_add
	else:
		buff.set_level(buff.get_level() + 1)
		buff.user_real += dmg_from_ice_add

	# NOTE: removed this floating text because it happens too often
	# var total_dmg_from_ice: float = buff.user_real
	# var floating_text: String = Utils.format_percent(total_dmg_from_ice, 0)
	# caster.get_player().display_floating_text(floating_text, target, Color8(255, 191, 255))
