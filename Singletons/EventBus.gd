extends Node

# Class for global events. Emitters should can use this to
# emit global events. Subscribes can connect to global
# signals.

signal item_button_mouse_entered(item_id: int)
signal item_button_mouse_exited()
signal tower_button_mouse_entered(tower_id: int)
signal tower_button_mouse_exited()
signal item_drop_picked_up(item_id: int)
signal creep_reached_portal(damage: float, creep: Creep)
signal creep_died(event: Event, creep: Creep)


func emit_creep_died(event: Event, creep: Creep):
	Utils.log_debug("Creep [%s] has died." % creep)
	creep_died.emit(event, creep)

func emit_creep_reached_portal(damage: float, creep: Creep):
	Utils.log_debug("Creep [%s] reached portal. Damage to portal: %s" % [creep, damage])
	creep_reached_portal.emit(damage, creep)


func emit_item_button_mouse_entered(item_id: int):
	item_button_mouse_entered.emit(item_id)


func emit_item_button_mouse_exited():
	item_button_mouse_exited.emit()


func emit_tower_button_mouse_entered(tower_id: int):
	tower_button_mouse_entered.emit(tower_id)


func emit_tower_button_mouse_exited():
	tower_button_mouse_exited.emit()


func emit_item_drop_picked_up(item_id: int):
	item_drop_picked_up.emit(item_id)
