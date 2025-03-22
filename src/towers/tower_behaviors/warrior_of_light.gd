extends TowerBehavior


var shockwave_st: SpellType
var aura_bt: BuffType



func get_tier_stats() -> Dictionary:
	return {
		1: {shockwave_chance = 0.20, shockwave_chance_add = 0.005, shockwave_damage = 1000, shockwave_damage_add = 50, mod_dmg_to_undead = 0.15, mod_dmg_to_undead_add = 0.006},
		2: {shockwave_chance = 0.23, shockwave_chance_add = 0.007, shockwave_damage = 2000, shockwave_damage_add = 100, mod_dmg_to_undead = 0.20, mod_dmg_to_undead_add = 0.008},
		3: {shockwave_chance = 0.25, shockwave_chance_add = 0.010, shockwave_damage = 3000, shockwave_damage_add = 150, mod_dmg_to_undead = 0.25, mod_dmg_to_undead_add = 0.010},
	}


const SHOCKWAVE_START_RADIUS: float = 100
const SHOCKWAVE_END_RADIUS: float = 300
const SHOCKWAVE_RANGE_FROM_TARGET: float = 500


func load_triggers(triggers: BuffType):
	triggers.add_event_on_attack(on_attack)


func tower_init():
	aura_bt = BuffType.create_aura_effect_type("aura_bt", true, self)
	var mod: Modifier = Modifier.new()
	mod.add_modification(Modification.Type.MOD_DMG_TO_UNDEAD, _stats.mod_dmg_to_undead, _stats.mod_dmg_to_undead_add)
	aura_bt.set_buff_modifier(mod)
	aura_bt.set_buff_icon("res://resources/icons/generic_icons/shiny_omega.tres")
	aura_bt.set_buff_tooltip(tr("HZID"))

#	NOTE: original script and tooltip don't mention the
#	radius of swarm so made it the same as for "Hell Bat"
#	tower
	shockwave_st = SpellType.new(SpellType.Name.CARRION_SWARM, 1, self)
	shockwave_st.data.swarm.damage = 1.0
	shockwave_st.data.swarm.start_radius = SHOCKWAVE_START_RADIUS
	shockwave_st.data.swarm.end_radius = SHOCKWAVE_END_RADIUS
	shockwave_st.data.swarm.travel_distance = SHOCKWAVE_RANGE_FROM_TARGET
	shockwave_st.data.swarm.effect_path = "res://src/effects/shockwave_missile.tscn"


func on_attack(event: Event):
	var creep: Unit = event.get_target()
	var level: int = tower.get_level()
	var shockwave_chance: float = _stats.shockwave_chance + _stats.shockwave_chance_add * level
	var shockwave_damage: float = _stats.shockwave_damage + _stats.shockwave_damage_add * level
	var facing_deg: float = creep.get_unit_facing() - 180
	var facing_rad: float = deg_to_rad(facing_deg)
	var x: float = creep.get_x() + 50 * cos(facing_rad)
	var y: float = creep.get_y() + 50 * sin(facing_rad)

	if !tower.calc_chance(shockwave_chance):
		return

	CombatLog.log_ability(tower, creep, "Ain Soph Aur")

	var effect: int = Effect.create_simple_at_unit_attached("res://src/effects/holy_bolt.tscn", creep, Unit.BodyPart.CHEST)
	Effect.set_color(effect, Color.GOLD)
	shockwave_st.point_cast_from_unit_on_point(tower, event.get_target(), Vector2(x, y), shockwave_damage, tower.calc_spell_crit_no_bonus())
