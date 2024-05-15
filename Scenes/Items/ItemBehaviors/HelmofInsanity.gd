extends ItemBehavior


func load_triggers(triggers: BuffType):
	triggers.add_event_on_damage(on_damage)


func on_autocast(_event: Event):
	item.user_int = 0


func on_damage(event: Event):
	var tower: Tower = item.get_carrier()

	if item.user_int >= 12 && item.user_int < 28:
		event.damage = event.damage * 0.5

		if event.is_main_target():
			tower.get_player().display_small_floating_text("Exhausted!", tower, Color8(255, 150, 0), 30)
			item.user_int = item.user_int + 1

	if item.user_int < 12:
		event.damage = event.damage * 2

		if event.is_main_target():
			tower.get_player().display_small_floating_text("Insane!", tower, Color8(255, 150, 0), 30)
			item.user_int = item.user_int + 1
			

func item_init():
	var autocast: Autocast = Autocast.make()
	autocast.title = "Insane Strength"
	autocast.description = "When this item is activated the next 12 attacks will deal 200% damage but the user becomes exhausted. When the user is exhausted it deals only 50% attack damage on the next 16 attacks.\n"
	autocast.icon = "res://Resources/Icons/hud/gold.tres"
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
	item.set_autocast(autocast)


func on_create():
	item.user_int = 50


func on_drop():
	item.user_int = 50
