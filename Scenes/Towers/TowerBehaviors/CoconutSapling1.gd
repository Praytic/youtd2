extends TowerBehavior


var cooldown_bt: BuffType
var stun_bt: BuffType
var coco_pt: ProjectileType


func get_tier_stats() -> Dictionary:
	return {
		1: {mod_dmg_to_orc = 0.30, mod_dmg_to_humanoid = 0.20, coconut_chance_decrease = 0.20, coconut_damage = 1625, coconut_damage_add = 162.5, coconut_aoe = 150},
		2: {mod_dmg_to_orc = 0.50, mod_dmg_to_humanoid = 0.40, coconut_chance_decrease = 0.17, coconut_damage = 2600, coconut_damage_add = 260.0, coconut_aoe = 190},
	}


const STUN_DURATION: float = 0.5
const STUN_CD: float = 1.5


func get_ability_description() -> String:
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


func get_ability_description_short() -> String:
	var text: String = ""

	text += "[color=GOLD]Coconut Rain[/color]\n"
	text += "Each time this tower attacks there is a chance to drop coconuts which deal AoE damage.\n"

	return text


func load_triggers(triggers: BuffType):
	triggers.add_event_on_damage(on_damage)


func load_specials(modifier: Modifier):
	modifier.add_modification(Modification.Type.MOD_DMG_TO_ORC, _stats.mod_dmg_to_orc, 0.01)
	modifier.add_modification(Modification.Type.MOD_DMG_TO_HUMANOID, _stats.mod_dmg_to_humanoid, 0.01)


func tower_init():
	coco_pt = ProjectileType.create("catapultmissile.mdl", 4, 0, self)
	coco_pt.enable_physics(coco_pt_on_impact, -15.0)

	stun_bt = CbStun.new("stun_bt", 0, 0, false, self)

	cooldown_bt = BuffType.new("cooldown_bt", STUN_CD, 0, false, self)
	cooldown_bt.set_buff_icon("res://Resources/Textures/GenericIcons/turtle_shell.tres")
	cooldown_bt.set_buff_tooltip("Coconut Cooldown\nRecently stunned by a coconut; temporarily immune to coconut stuns.")


func on_damage(event: Event):
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

	var target_pos: Vector2 = target.get_position_wc3_2d()

	for i in range(0, cast_count):
		var radius: float = Globals.synced_rng.randf_range(0, 300)
		var angle: float = deg_to_rad(Globals.synced_rng.randf_range(0, 360))
		var offset_vector: Vector2 = Vector2(radius, 0).rotated(angle)
		var coconut_pos: Vector2 = target_pos + offset_vector
		var projectile: Projectile = Projectile.create(coco_pt, tower, 1.0, tower.calc_spell_crit_no_bonus(), Vector3(coconut_pos.x, coconut_pos.y, 1000), 90)
		projectile.set_projectile_scale(0.30)
		var gravity: float = Globals.synced_rng.randf_range(1.0, 1.5)
		projectile.set_gravity(gravity)


# NOTE: cedi_Coco_Impact() in original script
func coco_pt_on_impact(p: Projectile):
	var caster: Unit = p.get_caster()
	var pos: Vector2 = p.get_position_wc3_2d()
	var it: Iterate = Iterate.over_units_in_range_of(caster, TargetType.new(TargetType.CREEPS), Vector2(pos.x, pos.y), 150)
	var dmg: float = _stats.coconut_damage + _stats.coconut_damage_add * caster.get_level()

	var effect: int = Effect.add_special_effect("WarStompCaster.mdl", pos)
	Effect.destroy_effect_after_its_over(effect)

	while true:
		var target: Unit = it.next()

		if target == null:
			break

		caster.do_spell_damage(target, dmg, caster.calc_spell_crit_no_bonus())

		if target.get_buff_of_type(cooldown_bt) == null:
			stun_bt.apply_only_timed(caster, target, STUN_DURATION)
			cooldown_bt.apply_only_timed(caster, target, STUN_CD)
