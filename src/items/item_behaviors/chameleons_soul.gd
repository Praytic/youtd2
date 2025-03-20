extends ItemBehavior


func on_drop():
	var tower: Tower = item.get_carrier()

	if tower.get_element() == Element.enm.ASTRAL:
		tower.modify_property(Modification.Type.MOD_EXP_RECEIVED, -1.00)
	elif tower.get_element() == Element.enm.DARKNESS:
		tower.modify_property(Modification.Type.MOD_SPELL_DAMAGE_DEALT, -0.45)
	elif tower.get_element() == Element.enm.NATURE:
		tower.modify_property(Modification.Type.MOD_ATK_CRIT_CHANCE, -0.10)
	elif tower.get_element() == Element.enm.FIRE:
		tower.modify_property(Modification.Type.MOD_DAMAGE_ADD_PERC, -0.40)
	elif tower.get_element() == Element.enm.ICE:
		tower.modify_property(Modification.Type.MOD_BUFF_DURATION, -0.50)
	elif tower.get_element() == Element.enm.STORM:
		tower.modify_property(Modification.Type.MOD_ATTACKSPEED, -0.25)
	elif tower.get_element() == Element.enm.IRON:
		tower.modify_property(Modification.Type.MOD_ITEM_CHANCE_ON_KILL, -0.30)


func on_pickup():
	var tower: Tower = item.get_carrier()

	if tower.get_element() == Element.enm.ASTRAL:
		tower.modify_property(Modification.Type.MOD_EXP_RECEIVED, 1.00)
	elif tower.get_element() == Element.enm.DARKNESS:
		tower.modify_property(Modification.Type.MOD_SPELL_DAMAGE_DEALT, 0.45)
	elif tower.get_element() == Element.enm.NATURE:
		tower.modify_property(Modification.Type.MOD_ATK_CRIT_CHANCE, 0.10)
	elif tower.get_element() == Element.enm.FIRE:
		tower.modify_property(Modification.Type.MOD_DAMAGE_ADD_PERC, 0.40)
	elif tower.get_element() == Element.enm.ICE:
		tower.modify_property(Modification.Type.MOD_BUFF_DURATION, 0.50)
	elif tower.get_element() == Element.enm.STORM:
		tower.modify_property(Modification.Type.MOD_ATTACKSPEED, 0.25)
	elif tower.get_element() == Element.enm.IRON:
		tower.modify_property(Modification.Type.MOD_ITEM_CHANCE_ON_KILL, 0.30)
