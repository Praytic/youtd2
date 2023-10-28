extends Tower


var multiboard: MultiboardValues
var boekie_nerubian_queen_bt: BuffType
var boekie_nerubian_queen_pt: ProjectileType


func get_ability_description() -> String:
	var text: String = ""

	text += "[color=GOLD]Inject Parasite[/color]\n"
	text += "When the Queen damages a creep she has a 30% chance to inject a parasite that lives for 10 seconds. Each second the creep will suffer 500 spelldamage and will permanently lose 2% armor. When an infected creep dies, the Nerubian Queen will gain 0.75% permanent bonus attackdamage and the parasite will attempt to jump to another host in 500 range.\n"
	text += " \n"
	text += "[color=ORANGE]Level Bonus:[/color]\n"
	text += "+0.4% chance \n"
	text += "+100 spelldamage\n"
	text += "+0.08% armor reduction\n"

	return text


func get_ability_description_short() -> String:
	var text: String = ""

	text += "[color=GOLD]Inject Parasite[/color]\n"
	text += "When the Queen damages a creep she has a chance to inject a parasite. Each second the creep will suffer spell damage and will permanently lose a portion of its armor.\n"

	return text


func load_triggers(triggers: BuffType):
	triggers.add_event_on_damage(on_damage)


func tower_init():
	boekie_nerubian_queen_bt = BuffType.new("boekie_nerubian_queen_bt", 10, 0, false, self)
	var mod: Modifier = Modifier.new()
	boekie_nerubian_queen_bt.set_buff_modifier(mod)
	boekie_nerubian_queen_bt.add_periodic_event(boekie_nerubian_queen_bt_periodic, 1.0)
	boekie_nerubian_queen_bt.add_event_on_death(boekie_nerubian_queen_bt_on_death)
	boekie_nerubian_queen_bt.set_buff_icon("@@0@@")
	boekie_nerubian_queen_bt.set_buff_tooltip("Parasite\nThis unit is infected with a Parasite; it will suffer from periodic damage.")

	boekie_nerubian_queen_pt = ProjectileType.create_interpolate("Spider.mdl", 500, self)
	boekie_nerubian_queen_pt.set_event_on_cleanup(boekie_nerubian_queen_pt_on_cleanup)
	boekie_nerubian_queen_pt.disable_explode_on_hit()

	multiboard = MultiboardValues.new(1)
	multiboard.set_key(0, "Damage Gained")


func on_damage(event: Event):
	var tower: Tower = self
	var target: Unit = event.get_target()
	var chance: float = 0.30 + 0.004 * tower.get_level()

	if !tower.calc_chance(chance):
		return

	boekie_nerubian_queen_bt.apply(tower, target, tower.get_level())


func on_create(_preceding_tower: Tower):
	var tower: Tower = self
	tower.user_real = 0


func on_tower_details() -> MultiboardValues:
	var tower: Tower = self
	var damage_gained: String = Utils.format_percent(tower.user_real, 0)
	multiboard.set_value(0, damage_gained)

	return multiboard


func boekie_nerubian_queen_bt_periodic(event: Event):
	var buff: Buff = event.get_buff()
	var target: Unit = buff.get_buffed_unit()
	var tower: Unit = buff.get_caster()
	var level: int = buff.get_level()
	var damage: float = 500 + 100 * level
	var mod_armor: float = -(0.02 + 0.0008 * level)

	tower.do_spell_damage(target, damage, tower.calc_spell_crit_no_bonus())
	target.modify_property(Modification.Type.MOD_ARMOR_PERC, mod_armor)


func boekie_nerubian_queen_bt_on_death(event: Event):
	var buff: Buff = event.get_buff()
	var creep: Unit = buff.get_buffed_unit()
	var tower: Tower = buff.get_caster()
	var it: Iterate = Iterate.over_units_in_range_of_unit(tower, TargetType.new(TargetType.CREEPS), creep, 500)

	var old_host_effect: int = Effect.create_simple("UndeadBloodCryptFiend.mdl", creep.get_visual_x(), creep.get_visual_y())
	Effect.destroy_effect_after_its_over(old_host_effect)

	tower.modify_property(Modification.Type.MOD_DAMAGE_ADD_PERC, 0.0075)
	tower.user_real += 0.0075

	var new_host: Unit = it.next()
	var temp: Unit = null
	while true:
		if new_host == null || new_host.get_buff_of_type(boekie_nerubian_queen_bt) == null:
			break

		if new_host != creep:
			temp = new_host

		new_host = it.next()

#	Find a new host! Prefers targets that aren't carrying
#	parasites already.
	if new_host == null:
		if temp == null:
#			No one to jump to! parasite dies :(
			var death_effect: int = Effect.create_scaled("Spider.mdl", creep.get_visual_x(), creep.get_visual_y(), 0, 0, 0.2)
			Effect.destroy_effect_after_its_over(death_effect)
			
			return
		else:
#			Can only jump to a target that already has a
#			parasite. Do it anyway, to refresh the buff
#			duration.
			new_host = temp

	var projectile: Projectile = Projectile.create_linear_interpolation_from_unit_to_unit(boekie_nerubian_queen_pt, tower, 0, 0, creep, new_host, 0.5, true)
	projectile.setScale(0.2)


func boekie_nerubian_queen_pt_on_cleanup(projectile: Projectile):
	var creep: Creep = projectile.get_target()
	var caster: Unit = projectile.get_caster()

	if !Utils.unit_is_valid(creep):
		return
	
	boekie_nerubian_queen_bt.apply(caster, creep, caster.get_level())
