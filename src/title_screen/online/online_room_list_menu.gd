class_name OnlineRoomListMenu extends PanelContainer


signal join_pressed()
signal cancel_pressed()
signal create_room_pressed()


@export var _no_rooms_found_label: Label
@export var _item_list: ItemList


#########################
###       Public      ###
#########################

func update_room_display(room_map: Dictionary):
	pass


func get_selected_room_address() -> String:
	return ""


#########################
###     Callbacks     ###
#########################

func _on_join_button_pressed():
	join_pressed.emit()


func _on_cancel_button_pressed():
	cancel_pressed.emit()


func _on_create_room_button_pressed():
	create_room_pressed.emit()
