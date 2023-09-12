# Spellbook of Item Mastery
extends Item


var Maj_spellbook: MultiboardValues


func get_extra_tooltip_text() -> String:
	var text: String = ""

	text += "[color=GOLD]Cast a Spell[/color]\n"
	text += "Casts one of these spells on attack:\n"
	text += "-Target drops a very high quality item\n"
	text += "-Two high quality items\n"
	text += "-Three normal quality items\n"
	text += "-Two low quality items and spellbook gains +10% item chance and item quality\n"
	text += "-Spellbook gains +25% item quality or item chance\n"
	text += " \n"
	text += "Cooldown of 15 waves.\n"

	return text


func load_triggers(triggers: BuffType):
	triggers.add_event_on_attack(on_attack)
	triggers.add_periodic_event(periodic, 5)


func item_init():
	Maj_spellbook = MultiboardValues.new(3)
	Maj_spellbook.set_key(0, "Waves Left")
	Maj_spellbook.set_key(1, "Item Quality")
	Maj_spellbook.set_key(2, "Item Chance")


func on_attack(event: Event):
	var itm: Item = self

	var choose: int
	var target: Creep
	var tower: Tower
	var player: Player

	if itm.user_int <= 0:
		tower = itm.get_carrier()
		player = itm.get_player()
		choose = randi_range(1, 6)

		if choose <= 4:
			target = event.get_target()

		if choose == 1:
			tower.modify_property(Modification.Type.MOD_ITEM_QUALITY_ON_KILL, 1)
			target.drop_item(tower, false)
			tower.modify_property(Modification.Type.MOD_ITEM_QUALITY_ON_KILL, -1)
			player.display_floating_text("One Item", tower, 0, 0, 255)
		elif choose == 2:
			tower.modify_property(Modification.Type.MOD_ITEM_QUALITY_ON_KILL, 0.5)
			target.drop_item(tower, false)
			target.drop_item(tower, false)
			tower.modify_property(Modification.Type.MOD_ITEM_QUALITY_ON_KILL, -0.5)
			player.display_floating_text("Two Items", tower, 0, 0, 255)
		elif choose == 3:
			tower.modify_property(Modification.Type.MOD_ITEM_QUALITY_ON_KILL, 0.25)
			target.drop_item(tower, false)
			target.drop_item(tower, false)
			target.drop_item(tower, false)
			tower.modify_property(Modification.Type.MOD_ITEM_QUALITY_ON_KILL, -0.25)
			player.display_floating_text("Three Items", tower, 0, 0, 255)
		elif choose == 4:
			tower.modify_property(Modification.Type.MOD_ITEM_QUALITY_ON_KILL, 0.25)
			target.drop_item(tower, false)
			target.drop_item(tower, false)
			tower.modify_property(Modification.Type.MOD_ITEM_QUALITY_ON_KILL, -0.25)
			tower.modify_property(Modification.Type.MOD_ITEM_CHANCE_ON_KILL, 0.1)
			itm.user_real = itm.user_real + 0.1
			itm.user_real2 = itm.user_real2 + 0.1
			player.display_floating_text("Two Items + Bonus!", tower, 0, 0, 255)
		elif choose == 5:
			tower.modify_property(Modification.Type.MOD_ITEM_CHANCE_ON_KILL, 0.25)
			itm.user_real2 = itm.user_real2 + 0.25
			player.display_floating_text("Item Chance", tower, 0, 255, 0)
		elif choose == 6:
			tower.modify_property(Modification.Type.MOD_ITEM_QUALITY_ON_KILL, 0.25)
			itm.user_real = itm.user_real + 0.25
			player.display_floating_text("Item Quality", tower, 0, 255, 0)

	itm.user_int = 15


func on_create():
	var itm: Item = self
	itm.user_int = 0
	itm.user_int2 = itm.get_player().get_level()
	itm.user_real = 0
	itm.user_real2 = 0


func on_drop():
	var itm: Item = self
	var tower: Tower = itm.get_carrier()
	tower.modify_property(Modification.Type.MOD_ITEM_QUALITY_ON_KILL, -itm.user_real)
	tower.modify_property(Modification.Type.MOD_ITEM_CHANCE_ON_KILL, -itm.user_real2)


func on_pickup():
	var itm: Item = self
	var tower: Tower = itm.get_carrier()
	tower.modify_property(Modification.Type.MOD_ITEM_QUALITY_ON_KILL, itm.user_real)
	tower.modify_property(Modification.Type.MOD_ITEM_CHANCE_ON_KILL, itm.user_real2)


func on_tower_details() -> MultiboardValues:
	var itm: Item = self
	Maj_spellbook.set_value(0, str(itm.user_int))
	Maj_spellbook.set_value(1, Utils.format_percent(itm.user_real, 0))
	Maj_spellbook.set_value(2, Utils.format_percent(itm.user_real2, 0))
	
	return Maj_spellbook


func periodic(_event: Event):
	var itm: Item = self
	var level: int = itm.get_player().get_level()

	if itm.user_int2 < level:
		itm.user_int = itm.user_int - (level - itm.user_int2)
		itm.user_int2 = level
