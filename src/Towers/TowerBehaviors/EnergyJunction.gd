extends TowerBehavior


# NOTE: original function removed all buffs made by this
# tower in on_destruct() to remove visual effects. This is
# not needed in godot engine because buffs are already
# automatically removed when one of their event handlers is
# removed.


var jolt_bt: BuffType


func get_tier_stats() -> Dictionary:
	return {
		1: {attack_speed = 0.2, attack_speed_add = 0.002, damage_on_attack = 150},
		2: {attack_speed = 0.25, attack_speed_add = 0.004, damage_on_attack = 320},
		3: {attack_speed = 0.32, attack_speed_add = 0.0052, damage_on_attack = 500},
	}


func load_specials(_modifier: Modifier):
	tower.set_attack_air_only()


func junction_on_create(event: Event):
	var b: Buff = event.get_buff()
	var buffee: Tower = b.get_buffed_unit()

	b.user_int = 0

	if tower != buffee:
		var lightning: InterpolatedSprite = InterpolatedSprite.create_from_unit_to_unit(InterpolatedSprite.LIGHTNING, tower, buffee)
		lightning.modulate = Color.LIGHT_BLUE
		b.user_int = lightning.get_instance_id()

#	NOTE: add & save attack speed
	b.user_real = tower.user_real + tower.user_real2 * tower.get_level()
	buffee.modify_property(Modification.Type.MOD_ATTACKSPEED, b.user_real)


func junction_on_damage(event: Event):
	var b: Buff = event.get_buff()
	var caster: Tower = b.get_caster()
	var buffee: Tower = b.get_buffed_unit()
	var creep: Creep = event.get_target()
	var damage: float = caster.user_real3 * (1 + caster.get_level() / 25.0) * buffee.get_base_attack_speed()

	buffee.do_spell_damage(creep, damage, buffee.calc_spell_crit_no_bonus())
	buffee.do_attack_damage(creep, damage, buffee.calc_attack_multicrit(0, 0, 0))
	SFX.sfx_at_unit("PurgeBuffTarget.mdl", creep)


func junction_on_cleanup(event: Event):
	var b: Buff = event.get_buff()

	if b.user_int != 0:
		var lightning: InterpolatedSprite = instance_from_id(b.user_int) as InterpolatedSprite
		if lightning != null:
			lightning.queue_free()

	b.get_buffed_unit().modify_property(Modification.Type.MOD_ATTACKSPEED, -b.user_real)


func tower_init():
	var m: Modifier = Modifier.new()
	m.add_modification(Modification.Type.MOD_ARMOR, 0.0, 0.0)
	jolt_bt = BuffType.new("jolt_bt", 10, 0, true, self)
	jolt_bt.set_buff_icon("res://resources/Icons/GenericIcons/electric.tres")
	jolt_bt.add_event_on_create(junction_on_create)
	jolt_bt.add_event_on_attack(junction_on_damage)
	jolt_bt.add_event_on_cleanup(junction_on_cleanup)
	jolt_bt.set_buff_tooltip("Jolt\nIncreases attack speed and deals extra damage when attacking.")

	
func create_autocasts() -> Array[Autocast]:
	var autocast: Autocast = Autocast.make()

	var attack_speed: String = Utils.format_percent(_stats.attack_speed, 2)
	var attack_speed_add: String = Utils.format_percent(_stats.attack_speed_add, 2)
	var damage_on_attack: String = Utils.format_float(_stats.damage_on_attack, 2)
	var damage_on_attack_add: String = Utils.format_float(_stats.damage_on_attack / 25.0, 2)
	
	autocast.title = "Jolt"
	autocast.icon = "res://resources/Icons/electricity/electricity_yellow.tres"
	autocast.description_short = "Buffs a tower in range increasing its attack speed. The buffed tower deals extra attack damage and spell damage.\n"
	autocast.description = "Buffs a tower in 500 range for 10 seconds increasing its attack speed by %s. The buffed tower deals %s attack damage and %s spell damage on attack multiplied with its base attack speed.\n" % [attack_speed, damage_on_attack, damage_on_attack] \
	+ " \n" \
	+ "[color=ORANGE]Level Bonus:[/color]\n" \
	+ "+%s attack and spell damage\n" % damage_on_attack_add \
	+ "+%s attack speed\n" % attack_speed_add
	autocast.caster_art = ""
	autocast.num_buffs_before_idle = 0
	autocast.autocast_type = Autocast.Type.AC_TYPE_ALWAYS_BUFF
	autocast.cast_range = 500
	autocast.target_self = true
	autocast.target_art = ""
	autocast.cooldown = 8
	autocast.is_extended = false
	autocast.mana_cost = 15
	autocast.buff_type = jolt_bt
	autocast.target_type = TargetType.new(TargetType.TOWERS)
	autocast.auto_range = 500

	return [autocast]


func on_create(_preceding_tower: Tower):
# 	base attack_speed boost
	tower.user_real = _stats.attack_speed
# 	attack speed boost add
	tower.user_real2 = _stats.attack_speed_add
# 	base dmg & spelldmg per attack (/25 for level bonus)
	tower.user_real3 = _stats.damage_on_attack
