extends Tower

# TODO: visual


func _get_tier_stats() -> Dictionary:
	return {
		1: {apply_level = 1, periodic_damage = 20, periodic_damage_add = 0.8},
		2: {apply_level = 2, periodic_damage = 60, periodic_damage_add = 2.4},
		3: {apply_level = 3, periodic_damage = 120, periodic_damage_add = 4.8},
		4: {apply_level = 4, periodic_damage = 240, periodic_damage_add = 10},
		5: {apply_level = 5, periodic_damage = 480, periodic_damage_add = 20},
		6: {apply_level = 6, periodic_damage = 960, periodic_damage_add = 40},
	}


func _ready():
	var triggers_buff: Buff = TriggersBuff.new()
	triggers_buff.add_event_on_damage(self, "_on_damage", 0.25, 0.01)
	triggers_buff.apply_to_unit_permanent(self, self, 0)


func drol_tentacleDamage(event: Event):
	var b: Buff = event.get_buff()

	if !b.get_buffed_unit().is_immune():
		b.get_caster().do_spell_damage(b.get_buffed_unit(), b.user_real, b.get_caster().calc_spell_crit_no_bonus())
		Utils.sfx_on_unit("Objects/Spawnmodels/Human/HumanBlood/HumanBloodRifleman.mdl", b.get_buffed_unit(), "chest")


func _on_damage(event: Event):
	var tower = self

	var m: Modifier = Modifier.new()
	m.add_modification(Unit.ModType.MOD_SPELL_DAMAGE_RECEIVED, 0.02, 0.01)

	var drol_tentacleDot = Buff.new("drol_tentacleDot", 6, 0, false)
	drol_tentacleDot.set_buff_icon("@@0@@")
	drol_tentacleDot.add_periodic_event(self, "drol_tentacleDamage", 1)
	drol_tentacleDot.set_buff_modifier(m)

	drol_tentacleDot.apply(tower, event.get_target(), 1)
	drol_tentacleDot.user_real = _stats.periodic_damage + _stats.periodic_damage_add * tower.get_level()
