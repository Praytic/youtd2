extends Tower


var shockwave_cast: Cast
var mock_warrior_of_light_bt: BuffType



func get_tier_stats() -> Dictionary:
	return {
		1: {shockwave_chance = 0.20, shockwave_chance_add = 0.005, shockwave_damage = 1000, shockwave_damage_add = 50, mod_dmg_to_undead = 0.15, mod_dmg_to_undead_add = 0.006},
		2: {shockwave_chance = 0.23, shockwave_chance_add = 0.007, shockwave_damage = 2000, shockwave_damage_add = 100, mod_dmg_to_undead = 0.20, mod_dmg_to_undead_add = 0.008},
		3: {shockwave_chance = 0.25, shockwave_chance_add = 0.010, shockwave_damage = 3000, shockwave_damage_add = 150, mod_dmg_to_undead = 0.25, mod_dmg_to_undead_add = 0.010},
	}


const SHOCKWAVE_START_RADIUS: float = 100
const SHOCKWAVE_END_RADIUS: float = 300
const SHOCKWAVE_RANGE_FROM_TARGET: float = 500
const AURA_RADIUS: float = 300


func get_ability_description() -> String:
	var shockwave_chance: String = Utils.format_percent(_stats.shockwave_chance, 2)
	var shockwave_chance_add: String = Utils.format_percent(_stats.shockwave_chance_add, 2)
	var shockwave_range_from_target: String = Utils.format_float(SHOCKWAVE_RANGE_FROM_TARGET, 2)
	var shockwave_damage: String = Utils.format_float(_stats.shockwave_damage, 2)
	var shockwave_damage_add: String = Utils.format_float(_stats.shockwave_damage_add, 2)
	var mod_dmg_to_undead: String = Utils.format_percent(_stats.mod_dmg_to_undead, 2)
	var mod_dmg_to_undead_add: String = Utils.format_percent(_stats.mod_dmg_to_undead_add, 2)
	var aura_radius: String = Utils.format_float(AURA_RADIUS, 2)

	var text: String = ""

	text += "[color=GOLD]Ain Soph Aur[/color]\n"
	text += "This tower has a %s chance on every attack to create a shockwave of light that starts at the targeted creep and travels %s units behind that creep dealing %s spell damage to all creeps in its path.\n" % [shockwave_chance, shockwave_range_from_target, shockwave_damage]
	text += " \n"
	text += "[color=ORANGE]Level Bonus:[/color]\n"
	text += "+%s chance\n" % shockwave_chance_add
	text += "+%s damage\n" % shockwave_damage_add
	text += " \n"
	text += "[color=GOLD]Aura of Light - Aura[/color]\n"
	text += "Towers in %s range deal %s more damage to undead creeps.\n" % [aura_radius, mod_dmg_to_undead]
	text += " \n"
	text += "[color=ORANGE]Level Bonus:[/color]\n"
	text += "+%s damage\n" % mod_dmg_to_undead_add

	return text


func load_triggers(triggers: BuffType):
	triggers.add_event_on_attack(on_attack)


func tower_init():
	mock_warrior_of_light_bt = BuffType.create_aura_effect_type("mock_warrior_of_light_bt", true, self)
	var mod: Modifier = Modifier.new()
	mod.add_modification(Modification.Type.MOD_DMG_TO_UNDEAD, 0.0, 0.001)
	mock_warrior_of_light_bt.set_buff_modifier(mod)
	mock_warrior_of_light_bt.set_buff_icon("@@1@@")
	mock_warrior_of_light_bt.set_buff_tooltip("Aura of Light\nThis tower is under the effect of Aura of Light; it deals extra damage to undead creeps.")

#	NOTE: original script and tooltip don't mention the
#	radius of swarm so made it the same as for "Hell Bat"
#	tower
	shockwave_cast = Cast.new("@@0@@", "carrionswarm", 1, self)
	shockwave_cast.data.swarm.damage = 1.0
	shockwave_cast.data.swarm.start_radius = SHOCKWAVE_START_RADIUS
	shockwave_cast.data.swarm.end_radius = SHOCKWAVE_END_RADIUS

	var aura_level: int = int(_stats.mod_dmg_to_undead * 1000)
	var aura_level_add: int = int(_stats.mod_dmg_to_undead_add * 1000)

	var aura: AuraType = AuraType.new()
	aura.aura_range = AURA_RADIUS
	aura.target_type = TargetType.new(TargetType.TOWERS)
	aura.target_self = true
	aura.level = aura_level
	aura.level_add = aura_level_add
	aura.power = aura_level
	aura.power_add = aura_level_add
	aura.aura_effect = mock_warrior_of_light_bt
	add_aura(aura)


func on_attack(event: Event):
	var tower: Tower = self
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

	var effect: int = Effect.create_simple("HolyBoltSpecialArt.mdl", creep.get_visual_x(), creep.get_visual_y())
	Effect.destroy_effect_after_its_over(effect)
	shockwave_cast.point_cast_from_unit_on_point(tower, event.get_target(), x, y, shockwave_damage, tower.calc_spell_crit_no_bonus())
