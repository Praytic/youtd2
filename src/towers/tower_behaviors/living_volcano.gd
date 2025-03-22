extends TowerBehavior


var aura_bt: BuffType
var lava_pt: ProjectileType


func load_triggers(triggers: BuffType):
	triggers.add_event_on_attack(on_attack)


func tower_init():
	aura_bt = BuffType.create_aura_effect_type("aura_bt", false, self)
	aura_bt.set_buff_icon("res://resources/icons/generic_icons/flame.tres")
	aura_bt.set_buff_tooltip(tr("WMGO"))
	aura_bt.add_periodic_event(aura_bt_periodic, 1.0)
	aura_bt.add_event_on_death(aura_bt_on_death)

	lava_pt = ProjectileType.create_interpolate("path_to_projectile_sprite", 650, self)
	lava_pt.set_event_on_cleanup(lava_pt_on_cleanup)


func on_attack(event: Event):
	var target: Unit = event.get_target()
	var lvl: int = tower.get_level()
	var aoe_radius: float = 300 + 5 * lvl
	var aoe_damage: float = 3500 + 100 * lvl
	var lava_attack_chance: float = 0.25

	if !tower.calc_chance(lava_attack_chance):
		return

	CombatLog.log_ability(tower, target, "Lava Attack")

	var p: Projectile = Projectile.create_linear_interpolation_from_unit_to_point(lava_pt, tower, 1.0, tower.calc_spell_crit_no_bonus(), tower, Vector3(target.get_x(), target.get_y(), 0), 0.45)
	p.user_real = aoe_radius
	p.user_real2 = aoe_damage


func lava_pt_on_cleanup(p: Projectile):
	var aoe_radius: float = p.user_real
	var aoe_damage: float = p.user_real2
	Effect.add_special_effect("res://src/effects/incinerate.tscn", Vector2(p.get_x(), p.get_y()))
	tower.do_spell_damage_aoe(Vector2(p.get_x(), p.get_y()), aoe_radius, aoe_damage, tower.calc_spell_crit_no_bonus(), 0.25)


func aura_bt_periodic(event: Event):
	var buff: Buff = event.get_buff()
	var creep: Creep = buff.get_buffed_unit()
	var life: float = creep.get_health()
	var dmg: float = life * 0.03 * tower.get_damage_to_category(creep.get_category())

#	Gex meant it is okay so...
	if life < 2.0:
		CombatLog.log_ability(tower, creep, "Heat Aura instant kill")
		
		tower.kill_instantly(creep)
	else:
		creep.set_health(life - dmg)


func aura_bt_on_death(event: Event):
	var buff: Buff = event.get_buff()
	var creep: Creep = buff.get_buffed_unit()
	var heat_stroke_chance: float = 0.40
	var aoe_radius: float = 300
	var aoe_damage: float = 4500 + 100 * tower.get_level()

	if !tower.calc_chance(heat_stroke_chance):
		return

	CombatLog.log_ability(tower, creep, "Heat Stroke")

	Effect.create_simple_at_unit("res://src/effects/firelord_death_explode.tscn", creep)
	tower.do_spell_damage_aoe_unit(creep, aoe_radius, aoe_damage, tower.calc_spell_crit_no_bonus(), 0.33)
