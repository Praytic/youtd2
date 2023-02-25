extends Tower

# TODO: visual

# NOTE: the original script sets "timeLevelAdd" parameter
# for stun debuff to 0.75 but then also passes 0 for "level"
# so duration never changes. Leaving it as in original.


func _get_tier_stats() -> Dictionary:
	return {
		1: {entangle_duration = 1.50, base_entangle_dps = 120},
		2: {entangle_duration = 2.25, base_entangle_dps = 660},
		3: {entangle_duration = 3.00, base_entangle_dps = 1800},
		4: {entangle_duration = 3.75, base_entangle_dps = 4300},
	}


func _ready():
	var triggers_buff: Buff = TriggersBuff.new()
	triggers_buff.add_event_on_create(self, "_on_create")
	triggers_buff.add_event_on_damage(self, "_on_damage", 0.125, 0.002)
	triggers_buff.apply_to_unit_permanent(self, self, 0)


func _on_create(_event: Event):
	var tower = self

	#	base entangle dps
	tower.user_int = _stats.base_entangle_dps


func _on_damage(event: Event):
	var tower = self

	var target: Mob = event.get_target()

	if target.get_size() < Mob.Size.BOSS && target.get_size() != Mob.Size.AIR:
		var chasm_entangle = CbStun.new("chasm_entangle", _stats.entangle_duration, 0.75, false)
		chasm_entangle.set_buff_icon('@@0@@')
		chasm_entangle.add_periodic_event(self, "_chasm_entangle_damage", 1.0)
		chasm_entangle.apply(tower, target, 0)

#		TODO: not sure what reorder() does
#		target.reorder()


func _chasm_entangle_damage(event: Event):
	var buff: Buff = event.get_buff()

	var t = buff.get_caster()
	var c: Mob = buff.get_buffed_unit()
	t.do_spell_damage(c, t.user_int + t.user_int * t.get_level() / 20, t.calc_spell_crit_no_bonus())
