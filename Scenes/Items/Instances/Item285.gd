# Helm of Insanity
extends Item


# TODO: currently doesn't work because
# AC_TYPE_NOAC_IMMEDIATE is not implemented.


func get_extra_tooltip_text() -> String:
	var text: String = ""

	text += "[color=GOLD]Insane Strength[/color]\n"
	text += "When this item is activated the next 12 attacks will deal 200% damage but the user becomes exhausted. When the user is exhausted it deals only 50% damage on the next 16 attacks.\n"
	text += " \n"
	text += "120s cooldown\n"

	return text


func load_triggers(triggers: BuffType):
	triggers.add_event_on_damage(on_damage)


func on_autocast(_event: Event):
	var itm: Item = self
	itm.user_int = 0


func on_damage(event: Event):
	var itm: Item = self
	var tower: Tower = itm.get_carrier()

	if itm.user_int >= 12 && itm.user_int < 28:
		event.damage = event.damage * 0.5

		if event.is_main_target():
			tower.getOwner().display_small_floating_text("Exhausted!", tower, 255, 150, 0, 30)
			itm.user_int = itm.user_int + 1

	if itm.user_int < 12:
		event.damage = event.damage * 2

		if event.is_main_target():
			tower.getOwner().display_small_floating_text("Insane!", tower, 255, 150, 0, 30)
			itm.user_int = itm.user_int + 1
			

func item_init():
	var autocast: Autocast = Autocast.make()
	autocast.display_name = "Insane Strength"
	autocast.caster_art = ""
	autocast.target_art = ""
	autocast.num_buffs_before_idle = 0
	autocast.autocast_type = Autocast.Type.AC_TYPE_NOAC_IMMEDIATE
	autocast.target_self = true
	autocast.cooldown = 120
	autocast.is_extended = false
	autocast.mana_cost = 0
	autocast.buff_type = null
	autocast.target_type = null
	autocast.cast_range = 0
	autocast.auto_range = 0
	autocast.handler = on_autocast
	add_autocast(autocast)


func on_create():
	var itm: Item = self
	itm.user_int = 50


func on_drop():
	var itm: Item = self
	itm.user_int = 50
