extends TowerBehavior


var cooldown_bt: BuffType
var stun_bt: BuffType
var coco_pt: ProjectileType


func get_tier_stats() -> Dictionary:
	return {
		1: {coconut_chance_decrease = 0.20, coconut_damage = 1625, coconut_damage_add = 162.5, coconut_aoe = 150},
		2: {coconut_chance_decrease = 0.17, coconut_damage = 2600, coconut_damage_add = 260.0, coconut_aoe = 190},
	}


const STUN_DURATION: float = 0.5
const STUN_CD: float = 1.5


func load_triggers(triggers: BuffType):
	triggers.add_event_on_damage(on_damage)


func tower_init():
	coco_pt = ProjectileType.create("path_to_projectile_sprite", 4, 0, self)
	coco_pt.enable_physics(coco_pt_on_impact, -15.0)

	stun_bt = CbStun.new("stun_bt", 0, 0, false, self)

	cooldown_bt = BuffType.new("cooldown_bt", STUN_CD, 0, false, self)
	cooldown_bt.set_buff_icon("res://resources/icons/generic_icons/turtle_shell.tres")
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

	var effect: int = Effect.add_special_effect("res://src/effects/warstomp_caster.tscn", pos)
	Effect.set_z_index(effect, Effect.Z_INDEX_BELOW_CREEPS)

	while true:
		var target: Unit = it.next()

		if target == null:
			break

		caster.do_spell_damage(target, dmg, caster.calc_spell_crit_no_bonus())

		if target.get_buff_of_type(cooldown_bt) == null:
			stun_bt.apply_only_timed(caster, target, STUN_DURATION)
			cooldown_bt.apply_only_timed(caster, target, STUN_CD)
