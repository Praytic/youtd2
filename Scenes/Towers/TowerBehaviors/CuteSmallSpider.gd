extends TowerBehavior

# NOTE: in original an EventTypeList is used to add
# "on_damage" event handler. Changed script to add handler
# directly to tower.


var poison_bt: BuffType


func get_tier_stats() -> Dictionary:
	return {
		1: {damage = 30, damage_add = 1.5, max_damage = 150, max_damage_add = 7.5},
		2: {damage = 90, damage_add = 4.5, max_damage = 450, max_damage_add = 22.5},
		3: {damage = 270, damage_add = 13.5, max_damage = 1350, max_damage_add = 67.5},
		4: {damage = 750, damage_add = 37.5, max_damage = 3750, max_damage_add = 187.5},
	}


func get_ability_info_list() -> Array[AbilityInfo]:
	var damage: String = Utils.format_float(_stats.damage, 2)
	var damage_add: String = Utils.format_float(_stats.damage_add, 2)

	var list: Array[AbilityInfo] = []
	
	var ability: AbilityInfo = AbilityInfo.new()
	ability.name = "Poisonous Spittle"
	ability.icon = "res://Resources/Icons/ItemIcons/toxic_chemicals.tres"
	ability.description_short = "Deals damage over time, increases with every attack.\n"
	ability.description_full = "Units damaged by the spider become infected and receive %s spell damage per second for 5 seconds. Further attacks on the same unit will increase the potency of the infection, stacking the damage and refreshing duration. Limit of 5 stacks. The highest stack amount of any spider that has infected a unit will be used.\n" % damage \
	+ " \n" \
	+ "[color=ORANGE]Level Bonus:[/color]\n" \
	+ "+%s damage per second\n" % damage_add \
	+ "+0.05 second duration\n" \
	+ "+1 stack every 5 levels\n"
	list.append(ability)

	return list


func load_specials(modifier: Modifier):
	modifier.add_modification(Modification.Type.MOD_DMG_TO_NATURE, -0.30, 0.0)
	modifier.add_modification(Modification.Type.MOD_DMG_TO_ORC, 0.10, 0.0)
	modifier.add_modification(Modification.Type.MOD_DMG_TO_HUMANOID, 0.20, 0.0)


func load_triggers(triggers_buff_type: BuffType):
	triggers_buff_type.add_event_on_damage(hit)


# NOTE: D1000_Spider_Damage() in original script
func poison_bt_periodic(event: Event):
	var b: Buff = event.get_buff()

	var caster: Unit = b.get_caster()
	caster.do_spell_damage(b.get_buffed_unit(), b.user_real, caster.calc_spell_crit_no_bonus())


func hit(event: Event):
	var target: Unit = event.get_target()
	var b: Buff = target.get_buff_of_type(poison_bt)
	var level: int = tower.get_level()
	var add_dam: float = tower.user_int + tower.user_real * level
	var max_dam: float = tower.user_int2 + tower.user_real2 * level + add_dam * (int(float(level) / 5))

	if b == null:
		b = poison_bt.apply(tower, target, level)
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
			b = poison_bt.apply(tower, target, level)
			b.user_real3 = tower.get_prop_spell_damage_dealt()
		else:
			b.set_remaining_duration(tower.user_int3 + tower.user_real3 * level)

		b.user_real = add_dam
		b.user_real2 = max_dam


func tower_init():
	poison_bt = BuffType.new("poison_bt", 5, 0.05, false, self)
	poison_bt.set_buff_icon("res://Resources/Icons/GenericIcons/poison_gas.tres")
	poison_bt.add_periodic_event(poison_bt_periodic, 1)
	poison_bt.set_buff_tooltip("Poison\nDeals damage over time.")


func on_create(_preceding_tower: Tower):
	tower.user_int = _stats.damage
	tower.user_real = _stats.damage_add
	tower.user_int2 = _stats.max_damage
	tower.user_real2 = _stats.max_damage_add
	tower.user_int3 = 5
	tower.user_real3 = 0.05
