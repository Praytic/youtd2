# Chameleons Soul
extends Item


func get_extra_tooltip_text() -> String:
	var text: String = ""

	text += "[color=GOLD]Transform[/color]\n"
	text += "+100% experience for Astral\n"
	text += "+45% spelldamage for Darkness\n"
	text += "+10% crit chance for Nature\n"
	text += "+40% damage for Fire\n"
	text += "+50% buff duration for Ice\n"
	text += "+25% attackspeed for Storm\n"
	text += "+30% item chance for Iron\n"

	return text


func on_drop():
	var itm: Item = self
	var tower: Tower = itm.get_carrier()

	if tower.get_element() == Element.ASTRAL:
		tower.modify_property(Modification.Type.MOD_EXP_RECEIVED, -1.00)
	elif tower.get_element() == Element.DARKNESS:
		tower.modify_property(Modification.Type.MOD_SPELL_DAMAGE_DEALT, -0.45)
	elif tower.get_element() == Element.NATURE:
		tower.modify_property(Modification.Type.MOD_ATK_CRIT_CHANCE, -0.10)
	elif tower.get_element() == Element.FIRE:
		tower.modify_property(Modification.Type.MOD_DAMAGE_ADD_PERC, -0.40)
	elif tower.get_element() == Element.ICE:
		tower.modify_property(Modification.Type.MOD_BUFF_DURATION, -0.50)
	elif tower.get_element() == Element.STORM:
		tower.modify_property(Modification.Type.MOD_ATTACKSPEED, -0.25)
	elif tower.get_element() == Element.IRON:
		tower.modify_property(Modification.Type.MOD_ITEM_CHANCE_ON_KILL, -0.30)


func on_pickup():
	var itm: Item = self
	var tower: Tower = itm.get_carrier()

	if tower.get_element() == Element.ASTRAL:
		tower.modify_property(Modification.Type.MOD_EXP_RECEIVED, 1.00)
	elif tower.get_element() == Element.DARKNESS:
		tower.modify_property(Modification.Type.MOD_SPELL_DAMAGE_DEALT, 0.45)
	elif tower.get_element() == Element.NATURE:
		tower.modify_property(Modification.Type.MOD_ATK_CRIT_CHANCE, 0.10)
	elif tower.get_element() == Element.FIRE:
		tower.modify_property(Modification.Type.MOD_DAMAGE_ADD_PERC, 0.40)
	elif tower.get_element() == Element.ICE:
		tower.modify_property(Modification.Type.MOD_BUFF_DURATION, 0.50)
	elif tower.get_element() == Element.STORM:
		tower.modify_property(Modification.Type.MOD_ATTACKSPEED, 0.25)
	elif tower.get_element() == Element.IRON:
		tower.modify_property(Modification.Type.MOD_ITEM_CHANCE_ON_KILL, 0.30)
