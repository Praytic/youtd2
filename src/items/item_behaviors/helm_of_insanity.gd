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


func on_create():
	item.user_int = 50


func on_drop():
	item.user_int = 50
