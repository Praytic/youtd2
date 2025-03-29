extends ItemBehavior


var attack_bt: BuffType


func load_triggers(triggers: BuffType):
	triggers.add_event_on_attack(on_attack)


func item_init():
	attack_bt = BuffType.new("attack_bt", 4, 0.1, true, self)
	attack_bt.set_buff_icon("res://resources/icons/generic_icons/hammer_drop.tres")
	attack_bt.set_buff_tooltip(tr("W1NC"))
	var mod: Modifier = Modifier.new() 
	mod.add_modification(Modification.Type.MOD_ATTACKSPEED, 0.50, 0) 
	attack_bt.set_buff_modifier(mod) 


func on_attack(_event: Event):
	var tower: Tower = item.get_carrier() 
	var in_range: Iterate
	var nxt: Tower
	var spieler: Player = tower.get_player()
	var speed: float = tower.get_base_attack_speed()

	if tower.calc_chance(speed * (0.02 + 0.001 * tower.get_level())):
		CombatLog.log_item_ability(item, null, "Attack!")
		
		var attack_text: String = tr("HY2D")
		spieler.display_floating_text(attack_text, tower, Color8(255, 0, 0))
		Effect.create_simple_at_unit_attached("res://src/effects/roar.tscn", tower, Unit.BodyPart.ORIGIN)
		in_range = Iterate.over_units_in_range_of_caster(tower, TargetType.new(TargetType.TOWERS), 350)

		while true:
			nxt = in_range.next()

			if nxt == null:
				break

			attack_bt.apply_custom_timed(tower, nxt, tower.get_level(), 4 + 0.2 * tower.get_level())
