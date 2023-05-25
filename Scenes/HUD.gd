class_name HUD extends Control


signal start_wave(wave_index)
signal stop_wave()


@onready var _wave_status: Control = $WaveStatus
@onready var _error_message_container: VBoxContainer = $MarginContainer2/ErrorMessageContainer
@onready var _normal_message_container: VBoxContainer = $MarginContainer3/NormalMessageContainer
@onready var _bottom_menu_bar: BottomMenuBar = $BottomMenuBar


func _ready():
	if Config.minimap_enabled():
		$Minimap.call_deferred("create_instance")
	
	if OS.is_debug_build() and Config.dev_controls_enabled():
		$DevControls.call_deferred("create_instance")
	
	SFX.connect_sfx_to_signal_in_group("res://Assets/SFX/menu_sound_5.wav", "pressed", "sfx_menu_click")

	EventBus.item_drop_picked_up_2.connect(_on_item_drop_picked_up_2)


# When item drop is picked up, make a visual effect of the
# item flying to the item stash button.
func _on_item_drop_picked_up_2(item_drop: ItemDrop):
	var item_menu_button: Control = _bottom_menu_bar.get_item_menu_button()
	var item_id: int = item_drop.get_id()
	var start_pos: Vector2 = item_drop.get_screen_transform().get_origin()
	var target_pos = item_menu_button.global_position + Vector2(45, 45)
	var flying_item: FlyingItem = FlyingItem.create(item_id, start_pos, target_pos)
	add_child(flying_item)


func get_error_message_container() -> VBoxContainer:
	return _error_message_container


func get_normal_message_container() -> VBoxContainer:
	return _normal_message_container


func _on_TooltipHeader_expanded(expand):
	if expand:
		$TowerTooltip.show()
		_wave_status.hide()
	else:
		$TowerTooltip.hide()
		_wave_status.show()


func _on_research_button_pressed():
	$ResearchMenu.visible = !$ResearchMenu.visible
