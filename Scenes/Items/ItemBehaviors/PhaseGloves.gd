extends ItemBehavior


func get_ability_description() -> String:
	var text: String = ""

	text += "[color=GOLD]Phase Powers[/color]\n"
	text += "The carrier of this item deals 30% of its attack damage as spell damage. This is no bonus damage, the tower will deal less attack damage!\n"

	return text


func load_triggers(triggers: BuffType):
	triggers.add_event_on_damage(on_damage)


func on_damage(event: Event):
	var damage: float = event.damage
	var creep: Unit = event.get_target()
	var tower: Tower = item.get_carrier()

	event.damage = damage * 0.7
	tower.do_spell_damage(creep, damage * 0.3, tower.calc_spell_crit_no_bonus())
