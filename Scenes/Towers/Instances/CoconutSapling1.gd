extends Tower


# NOTE: original script uses ProjectileType.enablePhysics()
# to implement falling coconuts. This f-n hasn't been
# implemented in youtd2 because it's complex and is only
# used by two towers - bad ROI. Instead, I implemented
# falling coconuts by using ProjectileType.enableRanged()
# and making projectiles move along the y axis.


var cedi_coco_bt: BuffType
var cb_stun: BuffType
var cedi_coco_pt: ProjectileType


func get_tier_stats() -> Dictionary:
	return {
		1: {mod_dmg_to_orc = 0.30, mod_dmg_to_humanoid = 0.20, coconut_chance_decrease = 0.20, coconut_damage = 1625, coconut_damage_add = 162.5, coconut_aoe = 150},
		2: {mod_dmg_to_orc = 0.50, mod_dmg_to_humanoid = 0.40, coconut_chance_decrease = 0.17, coconut_damage = 2600, coconut_damage_add = 260.0, coconut_aoe = 190},
	}


const STUN_DURATION: float = 0.5
const STUN_CD: float = 1.5
# NOTE: divide by 2 to account for isometric projection
const COCONUT_INITIAL_Z: float = 1000 / 2.0


func get_extra_tooltip_text() -> String:
	var coconut_chance_decrease: String = Utils.format_percent(_stats.coconut_chance_decrease, 2)
	var coconut_damage: String = Utils.format_float(_stats.coconut_damage, 2)
	var coconut_damage_add: String = Utils.format_float(_stats.coconut_damage_add, 2)
	var coconut_aoe: String = Utils.format_float(_stats.coconut_aoe, 2)
	var stun_duration: String = Utils.format_float(STUN_DURATION, 2)
	var stun_cd: String = Utils.format_float(STUN_CD, 2)

	var text: String = ""

	text += "[color=GOLD]Coconut Rain[/color]\n"
	text += "Each time this tower attacks there is a chance to drop multiple coconuts. The chance to drop a coconut is 100%% for the 1st one and after each coconut the chance is decreased by %s. Each coconut deals %s spelldamage in %s AoE and stuns for %s seconds. Hit units are immune to the stun of this ability for the next %s seconds.\n" % [coconut_chance_decrease, coconut_damage, coconut_aoe, stun_duration, stun_cd]
	text += " \n"
	text += "[color=ORANGE]Level Bonus:[/color]\n"
	text += "+%s damage\n" % coconut_damage_add

	return text


func load_triggers(triggers: BuffType):
	triggers.add_event_on_damage(on_damage)


func load_specials(modifier: Modifier):
	modifier.add_modification(Modification.Type.MOD_DMG_TO_ORC, _stats.mod_dmg_to_orc, 0.01)
	modifier.add_modification(Modification.Type.MOD_DMG_TO_HUMANOID, _stats.mod_dmg_to_humanoid, 0.01)


func tower_init():
	var pt_range: float = COCONUT_INITIAL_Z
	var pt_speed: float = 1000
	cedi_coco_pt = ProjectileType.create_ranged("catapultmissile.mdl", pt_range, pt_speed, self)
	cedi_coco_pt.set_event_on_expiration(cedi_coco_pt_on_hit)

	cb_stun = CbStun.new("coconut_sapling_stun", 0, 0, false, self)

	cedi_coco_bt = CbStun.new("cedi_coco_bt", STUN_CD, 0, false, self)
	cedi_coco_bt.set_buff_icon("@@0@@")
	cedi_coco_bt.set_buff_tooltip("Coconut Cooldown\nThis unit has recently been stunned by a coconut; it is temporarily immune to coconut stuns.")


func on_damage(event: Event):
	var tower: Tower = self
	var target: Unit = event.get_target()

	var cast_count: int = 0
	var current_chance: float = 1.0
	while true:
		if cast_count > 100:
			break
		elif tower.calc_chance(current_chance):
			cast_count += 1
			current_chance *= (1.0 - _stats.coconut_chance_decrease)
		else:
			break

	for i in range(0, cast_count):
		var radius: float = randf_range(0, 300)
		var angle: float = deg_to_rad(randf_range(0, 360))
		var offset_vector_top_down: Vector2 = Vector2(radius, 0).rotated(angle)
		var offset_vector_isometric: Vector2 = Isometric.top_down_vector_to_isometric(offset_vector_top_down)
		var coconut_pos: Vector2 = target.position + offset_vector_isometric
		coconut_pos.y -= COCONUT_INITIAL_Z
		var projectile: Projectile = Projectile.create(cedi_coco_pt, tower, 1.0, tower.calc_spell_crit_no_bonus(), coconut_pos.x, coconut_pos.y, 0.0, 90)
		projectile.setScale(0.30)
		var random_speed: float = projectile.get_speed() * randf_range(0.75, 1.25)
		projectile.set_speed(random_speed)


func cedi_coco_pt_on_hit(p: Projectile):
	var caster: Unit = p.get_caster()
	var pos: Vector2 = p.position
	var it: Iterate = Iterate.over_units_in_range_of(caster, TargetType.new(TargetType.CREEPS), pos.x, pos.y, 150)
	var dmg: float = _stats.coconut_damage + _stats.coconut_damage_add * caster.get_level()

	var effect: int = Effect.add_special_effect("WarStompCaster.mdl", pos.x, pos.y)
	Effect.destroy_effect_after_its_over(effect)

	while true:
		var target: Unit = it.next()

		if target == null:
			break

		caster.do_spell_damage(target, dmg, caster.calc_spell_crit_no_bonus())

		if target.get_buff_of_type(cedi_coco_bt) == null:
			cb_stun.apply_only_timed(caster, target, STUN_DURATION)
			cedi_coco_bt.apply_only_timed(caster, target, STUN_CD)
