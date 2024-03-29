extends TowerBehavior


# NOTE: original script does weird things with putting
# creeps into list/hashtable and counting creeps in range.
# Removed that, same behavior can be achieved without it.
# What's the point of checking that creeps are in range? The
# aura does that already and removes the buff when creeps go
# out of range.


var cedi_flux_aura_bt: BuffType
var cedi_flux_link_bt: BuffType
var flux_pt: ProjectileType
var multiboard: MultiboardValues
var linked_tower: Tower = null
var saved_lightning: InterpolatedSprite = null
var spell_damage_by_linked_tower: float = 0.0
var link_time: float = 0.0
var logged_link_ability: bool = false


func get_ability_description() -> String:
	var text: String = ""

	text += "[color=GOLD]Dimensional Distortion Field[/color]\n"
	text += "Each second this tower attacks a creep within 800 range, dealing 25% of the linked tower's spell damage per second as energy damage to the target creep. This tower can only attack if a link exists for at least 10 seconds. Benefits from attackspeed bonuses.\n"
	text += " \n"
	text += "[color=ORANGE]Level Bonus:[/color]\n"
	text += "+1% of spell dps as damage\n"

	return text


func get_ability_description_short() -> String:
	var text: String = ""

	text += "[color=GOLD]Dimensional Distortion Field[/color]\n"
	text += "Each second this tower attacks a creep in range, dealing damage based on linked tower's spell damage per second.\n"

	return text


func get_autocast_description() -> String:
	var text: String = ""

	text += "Creates a link between this tower and the target tower. This tower will now monitor any spell damage dealt by the linked tower to creeps within 2000 range of this tower. If the linked tower is sold, replaced or upgraded the link will dissolve.\n"

	return text


func get_autocast_description_short() -> String:
	var text: String = ""

	text += "Creates a link between this tower and the target tower.\n"

	return text


func load_triggers(triggers: BuffType):
	triggers.add_periodic_event(periodic, 1.0)


func get_ability_ranges() -> Array[RangeData]:
	return [RangeData.new("Dimensional Link", 800, TargetType.new(TargetType.TOWERS)), RangeData.new("Dimensional Monitor", 2000, TargetType.new(TargetType.CREEPS))]


func tower_init():
	cedi_flux_aura_bt = BuffType.create_aura_effect_type("cedi_flux_aura_bt", false, self)
	cedi_flux_aura_bt.add_event_on_damaged(cedi_flux_aura_bt_on_damaged)
	cedi_flux_aura_bt.set_buff_icon("@@0@@")
	cedi_flux_aura_bt.set_buff_tooltip("Dimensional Distortion Field\nThis creep is inside the field of the Flux Collector.")

	cedi_flux_link_bt = BuffType.new("cedi_flux_link_bt", -1, 0, true, self)
	cedi_flux_link_bt.add_event_on_create(cedi_flux_aura_bt_on_create)
	cedi_flux_link_bt.add_event_on_cleanup(cedi_flux_aura_bt_on_cleanup)
	cedi_flux_link_bt.set_buff_icon("@@1@@")
	cedi_flux_link_bt.set_buff_tooltip("Dimensional Link\nLinks to Flux Collector.")

	multiboard = MultiboardValues.new(1)
	multiboard.set_key(0, "DPS")

	flux_pt = ProjectileType.create_interpolate("OrbOfDeathMissile.mdl", 1000, self)
	flux_pt.set_event_on_interpolation_finished(flux_pt_on_hit)

	var autocast: Autocast = Autocast.make()
	autocast.title = "Dimensional Link"
	autocast.description = get_autocast_description()
	autocast.description_short = get_autocast_description_short()
	autocast.icon = "res://path/to/icon.png"
	autocast.caster_art = ""
	autocast.target_art = ""
	autocast.autocast_type = Autocast.Type.AC_TYPE_NOAC_PLAYER_TOWER
	autocast.num_buffs_before_idle = 0
	autocast.cast_range = 800
	autocast.auto_range = 800
	autocast.cooldown = 1
	autocast.mana_cost = 0
	autocast.target_self = false
	autocast.is_extended = false
	autocast.buff_type = null
	autocast.target_type = TargetType.new(TargetType.PLAYER_TOWERS)
	autocast.handler = on_autocast
	tower.add_autocast(autocast)


func get_aura_types() -> Array[AuraType]:
	var aura: AuraType = AuraType.new()
	aura.aura_range = 2150
	aura.target_type = TargetType.new(TargetType.CREEPS)
	aura.target_self = false
	aura.level = 0
	aura.level_add = 1
	aura.power = 0
	aura.power_add = 1
	aura.aura_effect = cedi_flux_aura_bt

	return [aura]


func on_destruct():
#	Remove link on destroy of this tower
	if linked_tower != null:
		var buff: Buff = linked_tower.get_buff_of_type(cedi_flux_link_bt)
		buff.remove_buff()


func on_autocast(event: Event):
	var target: Unit = event.get_target()
	var buff_on_new_target: Buff = target.get_buff_of_type(cedi_flux_link_bt)

	if buff_on_new_target != null:
#		Target is linked to another one of these towers.
#		Destroy that link
		buff_on_new_target.remove_buff()

#	It should be impossible for this to create a double free as this can only be true if the
#	linked tower and the target aren't the same. Else the buff is destroyed before this
#	-> linked_tower == null (buff cleanup)
	if linked_tower != null:
		var buff_on_old_target: Buff = linked_tower.get_buff_of_type(cedi_flux_link_bt)
		buff_on_old_target.remove_buff()

	linked_tower = target
	cedi_flux_link_bt.apply(tower, target, 0)


func on_tower_details() -> MultiboardValues:
	var dps: float = get_dps_from_link()
	var dps_string: String = Utils.format_float(dps, 0)

	multiboard.set_value(0, dps_string)

	return multiboard


func periodic(event: Event):
	var attackspeed: float = tower.get_current_attackspeed()

	event.enable_advanced(attackspeed, false)

	if linked_tower == null:
#		NOT LINKED! Do nothing!
		link_time = 0.0
		logged_link_ability = false

		return

	if spell_damage_by_linked_tower <= 0.0:
#		No dmg to deal! Do nothing!
		return

	link_time += attackspeed

	var linked_for_10_sec: bool = link_time >= 10.0

	if !linked_for_10_sec:
		return

	if linked_for_10_sec && !logged_link_ability:
		CombatLog.log_ability(tower, null, "Link damage active")
		logged_link_ability = true

	var it: Iterate = Iterate.over_units_in_range_of_caster(tower, TargetType.new(TargetType.CREEPS), 800)
	var next: Unit = it.next_random()

	if next != null:
		Projectile.create_bezier_interpolation_from_unit_to_unit(flux_pt, tower, 1.0, 1.0, tower, next, 0.35, 0, 0, true)


# NOTE: "ProjHit()" in original script
func flux_pt_on_hit(_p: Projectile, target: Unit):
	if target == null:
		return

	var damage: float = get_dps_from_link()
	tower.do_custom_attack_damage(target, damage, tower.calc_attack_multicrit_no_bonus(), AttackType.enm.ENERGY)


# NOTE: "BuffTrigger()" in original script
func cedi_flux_aura_bt_on_damaged(event: Event):
	var attacker: Unit = event.get_target()

	if event.is_spell_damage() && attacker == linked_tower:
		spell_damage_by_linked_tower += event.damage


# NOTE: "LinkCreate()" in original script
func cedi_flux_aura_bt_on_create(event: Event):
	var buff: Buff = event.get_buff()
	var caster: Tower = buff.get_caster()
	var lightning: InterpolatedSprite = InterpolatedSprite.create_from_point_to_unit(InterpolatedSprite.LIGHTNING, Vector3(caster.get_visual_x(), caster.get_visual_y(), 220), linked_tower)
	lightning.modulate = Color.LIGHT_BLUE
	saved_lightning = lightning


# NOTE: "LinkEnd()" in original script
func cedi_flux_aura_bt_on_cleanup(_event: Event):
	if saved_lightning != null:
		saved_lightning.queue_free()
		saved_lightning = null

	linked_tower = null


func get_dps_from_link() -> float:
	if link_time <= 0.0:
		return 0.0

	var spell_dps_by_linked_tower: float = spell_damage_by_linked_tower / link_time
	var multiplier: float = 0.25 + 0.01 * tower.get_level()
	var dps: float = spell_dps_by_linked_tower * multiplier

	return dps
