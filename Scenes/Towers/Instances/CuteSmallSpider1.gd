extends Tower

# NOTE: in original an EventTypeList is used to add
# "on_damage" event handler. Changed script to add handler
# directly to tower.


var D1000_Spider_Poison: BuffType


func get_tier_stats() -> Dictionary:
	return {
		1: {damage = 30, damage_add = 1.5, max_damage = 150, max_damage_add = 7.5},
		2: {damage = 90, damage_add = 4.5, max_damage = 450, max_damage_add = 22.5},
		3: {damage = 270, damage_add = 13.5, max_damage = 1350, max_damage_add = 67.5},
		4: {damage = 750, damage_add = 37.5, max_damage = 3750, max_damage_add = 187.5},
	}


func get_extra_tooltip_text() -> String:
	var damage: String = String.num(_stats.damage, 2)
	var damage_add: String = String.num(_stats.damage_add, 2)

	var text: String = ""

	text += "[color=GOLD]Poisonous Spittle[/color]\n"
	text += "Units damaged by the spider become infected and receive %s spell damage per second for 5 seconds. Further attacks on the same unit will increase the potency of the infection, stacking the damage and refreshing duration. Limit of 5 stacks. The highest stack amount of any spider that has infected a unit will be used.\n" % damage
	text += "[color=ORANGE]Level Bonus:[/color]\n"
	text += "+%s damage per second\n" % damage_add
	text += "+0.05 second duration\n"
	text += "+1 stack every 5 levels"

	return text


func load_specials(modifier: Modifier):
	modifier.add_modification(Modification.Type.MOD_DMG_TO_NATURE, -0.30, 0.0)
	modifier.add_modification(Modification.Type.MOD_DMG_TO_ORC, 0.10, 0.0)
	modifier.add_modification(Modification.Type.MOD_DMG_TO_HUMANOID, 0.20, 0.0)


func load_triggers(triggers_buff_type: BuffType):
	triggers_buff_type.add_event_on_damage(hit, 1.0, 0.0)


func D1000_Spider_Damage(event: Event):
	var b: Buff = event.get_buff()

	var caster: Unit = b.get_caster()
	caster.do_spell_damage(b.get_buffed_unit(), b.user_real, caster.calc_spell_crit_no_bonus())


func hit(event: Event):
	var tower: Tower = self

	var target: Unit = event.get_target()
	var b: Buff = target.get_buff_of_type(D1000_Spider_Poison)
	var level: int = tower.get_level()
	var add_dam: float = tower.user_int + tower.user_real * level
	var max_dam: float = tower.user_int2 + tower.user_real2 * level + add_dam * (int(float(level) / 5))

	if b == null:
		b = D1000_Spider_Poison.apply(tower, target, level)
		b.user_real = add_dam
		b.user_real2 = max_dam
		b.user_real3 = tower.get_prop_spell_damage_dealt()
	else:
		if b.user_real2 >= max_dam:
			max_dam = b.user_real2

		if b.user_real + add_dam >= max_dam:
			add_dam = max_dam
		else:
			add_dam = b.user_real + add_dam

		if b.user_real3 < tower.get_prop_spell_damage_dealt():
			b.remove_buff()
			b = D1000_Spider_Poison.apply(tower, target, level)
			b.user_real3 = tower.get_prop_spell_damage_dealt()
		else:
			b.set_remaining_duration(tower.user_int3 + tower.user_real3 * level)

		b.user_real = add_dam
		b.user_real2 = max_dam


func tower_init():
	D1000_Spider_Poison = BuffType.new("D1000_Spider_Poison", 5, 0.05, false, self)
	D1000_Spider_Poison.set_buff_icon("@@0@@")
	D1000_Spider_Poison.add_periodic_event(D1000_Spider_Damage, 1)
	D1000_Spider_Poison.set_buff_tooltip("Poison\nThis unit is poisoned and is suffering damage over time.")


func on_create(_preceding_tower: Tower):
	var tower: Tower = self

	tower.user_int = _stats.damage
	tower.user_real = _stats.damage_add
	tower.user_int2 = _stats.max_damage
	tower.user_real2 = _stats.max_damage_add
	tower.user_int3 = 5
	tower.user_real3 = 0.05
