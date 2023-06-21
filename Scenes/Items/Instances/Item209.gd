# Grounding Gloves
extends Item


var BT: BuffType
var CD: BuffType
var C: Cast


func get_extra_tooltip_text() -> String:
	var text: String = ""

	text += "[color=GOLD]Entangling Roots[/color]\n"
	text += "On attack the carrier has an 6% attackspeed adjusted chance to create a field of overgrowth in 200 AoE around the target. Creeps entering the overgrowth will become entangled for 1.8 seconds, taking 4500 spell damage per second. Cannot entangle the same creep for 3 seconds afterwards. Bosses can only be hit once.\n"

	return text


func load_triggers(triggers: BuffType):
	triggers.add_event_on_damage(on_damage)


func overgrowth_dmg(event: Event, C: DummyUnit):
	var U: Creep = event.get_target()
	var tower: Tower = C.get_caster()
	event.damage = 0

	if U.get_buff_of_type(CD) == null:
		BT.apply(tower, U, 0)

		if U.get_size() < CreepSize.enm.BOSS:
			CD.apply(tower, U, 0)
		else:
			CD.apply_only_timed(tower, U, -1)


func periodic_dmg(event: Event):
	var B: Buff = event.get_buff()
	B.get_caster().do_spell_damage(B.get_buffed_unit(), 4500, B.get_caster().calc_spell_crit_no_bonus())


func item_init():
	BT = CbStun.new("cb_stun", 1.8, 0, false, self)
	BT.add_periodic_event(periodic_dmg, 1.0)
	BT.set_buff_icon("@@1@@")

	CD = BuffType.new("Item209_CD", 4.8, 0.0, false, self)

	C = Cast.new("@@0@@", "blizzard", 4.0)
	C.set_damage_event(overgrowth_dmg)
	

func on_damage(event: Event):
	var itm: Item = self
	var target: Creep = event.get_target()
	var tower: Tower = itm.get_carrier()

	if event.is_main_target() && tower.calc_chance(tower.get_base_attack_speed() * 0.06):
		C.point_cast_from_target_on_target(tower, target, 1.0, 1.0)
		var effect: int = Effect.create_colored("Roots.mdl", target.get_visual_position().x, target.get_visual_position().y, 0.0, 270.0, 1.2, Color(210 / 255.0, 1.0, 180 / 255.0, 1.0))
		Effect.set_lifetime(effect, 2.5)
