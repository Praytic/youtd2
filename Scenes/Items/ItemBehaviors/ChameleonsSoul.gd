extends ItemBehavior


func get_ability_description() -> String:
	var astral_string: String = Element.convert_to_colored_string(Element.enm.ASTRAL)
	var darkness_string: String = Element.convert_to_colored_string(Element.enm.DARKNESS)
	var nature_string: String = Element.convert_to_colored_string(Element.enm.NATURE)
	var fire_string: String = Element.convert_to_colored_string(Element.enm.FIRE)
	var ice_string: String = Element.convert_to_colored_string(Element.enm.ICE)
	var storm_string: String = Element.convert_to_colored_string(Element.enm.STORM)
	var iron_string: String = Element.convert_to_colored_string(Element.enm.IRON)

	var text: String = ""

	text += "[color=GOLD]Transform[/color]\n"
	text += "+100%% experience for %s\n" % astral_string
	text += "+45%% spell damage for %s\n" % darkness_string
	text += "+10%% crit chance for %s\n" % nature_string
	text += "+40%% attack damage for %s\n" % fire_string
	text += "+50%% buff duration for %s\n" % ice_string
	text += "+25%% attack speed for %s\n" % storm_string
	text += "+30%% item chance for %s\n" % iron_string

	return text


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
