extends TowerBehavior


# NOTE: [ORIGINAL_GAME_DEVIATION] Renamed
# "Nerubian Queen"=>"Spider Queen"


var multiboard: MultiboardValues
var parasite_bt: BuffType
var spider_pt: ProjectileType


func load_triggers(triggers: BuffType):
	triggers.add_event_on_damage(on_damage)


func tower_init():
	parasite_bt = BuffType.new("parasite_bt", 10, 0, false, self)
	var mod: Modifier = Modifier.new()
	parasite_bt.set_buff_modifier(mod)
	parasite_bt.add_periodic_event(parasite_bt_periodic, 1.0)
	parasite_bt.add_event_on_death(parasite_bt_on_death)
	parasite_bt.set_buff_icon("res://resources/icons/generic_icons/amber_mosquito.tres")
	parasite_bt.set_buff_tooltip(tr("GBJV"))

	spider_pt = ProjectileType.create_interpolate("path_to_projectile_sprite", 500, self)
	spider_pt.set_event_on_cleanup(spider_pt_on_cleanup)
	spider_pt.disable_explode_on_hit()

	multiboard = MultiboardValues.new(1)
	multiboard.set_key(0, "Damage Gained")


func on_damage(event: Event):
	var target: Unit = event.get_target()
	var chance: float = 0.30 + 0.004 * tower.get_level()

	if !tower.calc_chance(chance):
		return

	CombatLog.log_ability(tower, target, "Inject Parasite")

	parasite_bt.apply(tower, target, tower.get_level())


func on_create(_preceding_tower: Tower):
	tower.user_real = 0


func on_tower_details() -> MultiboardValues:
	var damage_gained: String = Utils.format_percent(tower.user_real, 0)
	multiboard.set_value(0, damage_gained)

	return multiboard


func parasite_bt_periodic(event: Event):
	var buff: Buff = event.get_buff()
	var target: Unit = buff.get_buffed_unit()
	var level: int = buff.get_level()
	var damage: float = 500 + 100 * level
	var mod_armor: float = -(0.02 + 0.0008 * level)

	tower.do_spell_damage(target, damage, tower.calc_spell_crit_no_bonus())
	target.modify_property(Modification.Type.MOD_ARMOR_PERC, mod_armor)


func parasite_bt_on_death(event: Event):
	var buff: Buff = event.get_buff()
	var creep: Unit = buff.get_buffed_unit()
	var it: Iterate = Iterate.over_units_in_range_of_unit(tower, TargetType.new(TargetType.CREEPS), creep, 500)

	Effect.create_simple("res://src/effects/crypt_fiend_eggsack.tscn", Vector2(creep.get_x(), creep.get_y()))

	tower.modify_property(Modification.Type.MOD_DAMAGE_ADD_PERC, 0.0075)
	tower.user_real += 0.0075

	var new_host: Unit = it.next()
	var temp: Unit = null
	while true:
		if new_host == null || new_host.get_buff_of_type(parasite_bt) == null:
			break

		if new_host != creep:
			temp = new_host

		new_host = it.next()

#	Find a new host! Prefers targets that aren't carrying
#	parasites already.
	if new_host == null:
		if temp == null:
#			No one to jump to! parasite dies :(
			Effect.create_scaled("res://src/effects/frost_armor_damage_purple.tscn", Vector3(creep.get_x(), creep.get_y(), 0), 0, 1)
			
			return
		else:
#			Can only jump to a target that already has a
#			parasite. Do it anyway, to refresh the buff
#			duration.
			new_host = temp

	var projectile: Projectile = Projectile.create_linear_interpolation_from_unit_to_unit(spider_pt, tower, 0, 0, creep, new_host, 0.5, true)
	projectile.set_projectile_scale(0.2)


func spider_pt_on_cleanup(projectile: Projectile):
	var creep: Creep = projectile.get_target()
	var caster: Unit = projectile.get_caster()

	if !Utils.unit_is_valid(creep):
		return
	
	parasite_bt.apply(caster, creep, caster.get_level())
