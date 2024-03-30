# Commander
extends ItemBehavior


var stern_Commander_Attack: BuffType


func get_ability_description() -> String:
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
	m.add_modification(Modification.Type.MOD_ATTACKSPEED, 0.50, 0) 
	stern_Commander_Attack = BuffType.new("stern_Commander_Attack", 4, 0.1, true, self)
	stern_Commander_Attack.set_buff_modifier(m) 
	stern_Commander_Attack.set_stacking_group("stern_Commander_Attack")
	stern_Commander_Attack.set_buff_icon("@@0@@")
	stern_Commander_Attack.set_buff_tooltip("Attack!\nIncreases attack speed.")


func on_attack(_event: Event):
	var tower: Tower = item.get_carrier() 
	var in_range: Iterate
	var nxt: Tower
	var spieler: Player = tower.get_player()
	var speed: float = tower.get_base_attackspeed()

	if tower.calc_chance(speed * (0.02 + 0.001 * tower.get_level())):
		CombatLog.log_item_ability(item, null, "Attack!")
		
		spieler.display_floating_text("Attack!", tower, Color8(255, 0, 0))
		SFX.sfx_on_unit("RoarCaster.mdl", tower, Unit.BodyPart.ORIGIN)
		in_range = Iterate.over_units_in_range_of_caster(tower, TargetType.new(TargetType.TOWERS), 350)

		while true:
			nxt = in_range.next()

			if nxt == null:
				break

			stern_Commander_Attack.apply_custom_timed(tower, nxt, tower.get_level(), 4 + 0.2 * tower.get_level())
