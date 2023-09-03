# Commander
extends Item


var stern_Commander_Attack: BuffType


func get_extra_tooltip_text() -> String:
	var text: String = ""

	text += "[color=GOLD]Attack![/color]\n"
	text += "Every attack there is a 2% attackspeed adjusted chance to issue an attack order. When this happens, all towers in 350 range gain +50% attack speed for 4 seconds.\n"
	text += " \n"
	text += "[color=ORANGE]Level Bonus:[/color]\n"
	text += "+0.01% chance\n"
	text += "+0.1 seconds duration\n"

	return text


func load_triggers(triggers: BuffType):
	triggers.add_event_on_attack(on_attack)


func item_init():
	var m: Modifier = Modifier.new() 
	m.add_modification(Modification.Type.MOD_MOVESPEED, -0.05, 0) 
	stern_Commander_Attack = BuffType.new("stern_Commander_Attack", 4, 0.1, false, self)
	stern_Commander_Attack.set_buff_modifier(m) 
	stern_Commander_Attack.set_stacking_group("stern_Commander_Attack")
	stern_Commander_Attack.set_buff_icon("@@0@@")
	stern_Commander_Attack.set_buff_tooltip("Attack!\nThis unit has been commanded to attack; it has increased attack speed.")


func on_attack(_event: Event):
	var itm: Item = self
	var tower: Tower = itm.get_carrier() 
	var in_range: Iterate
	var nxt: Tower
	var spieler: Player = tower.get_player()
	var speed: float = tower.get_base_attack_speed()

	if tower.calc_chance(speed * (0.02 + 0.001 * tower.get_level())):
		spieler.display_floating_text("Attack!", tower, 255, 0, 0)
		SFX.sfx_on_unit("RoarCaster.mdl", tower, "origin")
		in_range = Iterate.over_units_in_range_of_caster(tower, TargetType.new(TargetType.TOWERS), 350)

		while true:
			nxt = in_range.next()

			if nxt == null:
				break

			stern_Commander_Attack.apply_custom_timed(tower, nxt, tower.get_level(), 4 + 0.2 * tower.get_level())
