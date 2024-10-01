extends ItemBehavior


var roots_bt: BuffType
var cooldown_bt: BuffType
var blizzard_st: SpellType


func get_ability_description() -> String:
	var text: String = ""

	text += "[color=GOLD]Entangling Roots[/color]\n"
	text += "Whenever the carrier hits the main target, it has an 6% attack speed adjusted chance to create a field of overgrowth in 200 AoE around the target. Creeps entering the overgrowth will become entangled for 1.8 seconds, taking 4500 spell damage per second. Cannot entangle the same creep for 3 seconds afterwards. Bosses can only be hit once.\n"

	return text


func load_triggers(triggers: BuffType):
	triggers.add_event_on_damage(on_damage)


# NOTE: overgrowth_dmg() in original script
func blizzard_st_on_damage(event: Event, dummy: DummyUnit):
	var target: Creep = event.get_target()
	var tower: Tower = dummy.get_caster()
	event.damage = 0

	if target.get_buff_of_type(cooldown_bt) == null:
		roots_bt.apply(tower, target, 0)

		if target.get_size() < CreepSize.enm.BOSS:
			cooldown_bt.apply(tower, target, 0)
		else:
			cooldown_bt.apply_only_timed(tower, target, -1)


func periodic_dmg(event: Event):
	var B: Buff = event.get_buff()
	B.get_caster().do_spell_damage(B.get_buffed_unit(), 4500, B.get_caster().calc_spell_crit_no_bonus())


func item_init():
	roots_bt = CbStun.new("roots_bt", 1.8, 0, false, self)
	roots_bt.add_periodic_event(periodic_dmg, 1.0)
	roots_bt.set_buff_icon("res://resources/icons/generic_icons/perpendicular_rings.tres")

	cooldown_bt = BuffType.new("cooldown_bt", 4.8, 0.0, false, self)
	cooldown_bt.set_hidden()

	blizzard_st = SpellType.new(SpellType.Name.BLIZZARD, 4.0, self)
	blizzard_st.set_damage_event(blizzard_st_on_damage)
	blizzard_st.data.blizzard.damage = 0
	blizzard_st.data.blizzard.radius = 200
	blizzard_st.data.blizzard.wave_count = 3
	

func on_damage(event: Event):
	var target: Creep = event.get_target()
	var tower: Tower = item.get_carrier()

	if event.is_main_target() && tower.calc_chance(tower.get_base_attack_speed() * 0.06):
		CombatLog.log_item_ability(item, null, "Entangling Roots")
	
		blizzard_st.point_cast_from_target_on_target(tower, target, 1.0, 1.0)
		var effect: int = Effect.create_animated("res://src/effects/flower_aura.tscn", Vector3(target.get_x(), target.get_y(), 0), 0)
		Effect.set_scale(effect, 1.5)
		Effect.set_z_index(effect, Effect.Z_INDEX_BELOW_CREEPS)
		Effect.set_lifetime(effect, 2.5)
