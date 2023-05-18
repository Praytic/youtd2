extends Node

# Class for global events. Emitters should can use this to
# emit global events. Subscribes can connect to global
# signals.

signal item_button_mouse_entered(item_id: int)
signal item_button_mouse_exited()
signal tower_button_mouse_entered(tower_id: int)
signal tower_button_mouse_exited()
signal item_drop_picked_up(item_id: int)
signal research_button_mouse_entered(element: Element.enm)
signal research_button_mouse_exited()


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
