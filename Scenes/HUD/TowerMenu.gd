class_name TowerMenu
extends Control


const SELL_BUTTON_RESET_TIME: float = 5.0

@export var _upgrade_button: Button
@export var _sell_button: Button
@export var _info_button: Button
@export var _reset_sell_button_timer: Timer
@export var _items_box_container: HBoxContainer
@export var _tower_name_label: Label
@export var _tower_info_label: RichTextLabel
@export var _tower_icon_texture: TextureRect
@export var _tower_specials_container: VBoxContainer
@export var _tower_level_label: Label
@export var _tower_control_menu: VBoxContainer
@export var _tower_stats_menu: ScrollContainer


var _moved_item_button: ItemButton = null
var _selling_for_real: bool = false


func _ready():
	hide()
	
	SelectUnit.selected_unit_changed.connect(_on_selected_unit_changed)
	
	_on_selected_unit_changed()
	
	ItemMovement.item_move_from_tower_done.connect(_on_item_move_from_tower_done)
	WaveLevel.changed.connect(_on_wave_or_element_level_changed)
	ElementLevel.changed.connect(_on_wave_or_element_level_changed)
	
	_sell_button.pressed.connect(_on_sell_button_pressed)
	_upgrade_button.pressed.connect(_on_upgrade_button_pressed)
	_info_button.toggled.connect(_on_info_button_pressed)


func _on_wave_or_element_level_changed():
	if get_selected_tower() != null:
		_update_upgrade_button()


func _on_selected_unit_changed(prev_unit = null):
	var tower: Tower = get_selected_tower()
	
	visible = tower != null

	if prev_unit != null and prev_unit is Tower:
		prev_unit.items_changed.disconnect(on_tower_items_changed)

	if tower != null:
		tower.items_changed.connect(on_tower_items_changed)
		on_tower_items_changed()
		_update_upgrade_button()
		_update_tower_name_label()
		_update_tower_level_label()
		
		show()

	_set_selling_for_real(false)


func get_selected_tower() -> Tower:
	var selected_unit = SelectUnit.get_selected_unit()
	if selected_unit is Tower:
		return selected_unit as Tower
	else:
		return null


func on_tower_items_changed():
	for button in _items_box_container.get_children():
		button.queue_free()

	var items: Array[Item] = get_selected_tower().get_items()

	for item in items:
		var item_button = ItemButton.make(item)
		item_button.theme_type_variation = "SmallButton"
		var button_container = UnitButtonContainer.make()
		button_container.add_child(item_button)
		_items_box_container.add_child(button_container)
		item_button.pressed.connect(_on_item_button_pressed.bind(item_button))


func _update_tower_name_label():
	var tower = get_selected_tower()
	_tower_name_label.text = tower.get_display_name()


func _update_tower_level_label():
	var tower = get_selected_tower()
	_tower_level_label.text = str(tower.get_level())


func _on_item_button_pressed(item_button: ItemButton):
	var item: Item = item_button.get_item()
	var started_move: bool = ItemMovement.start_move_from_tower(item)

	if !started_move:
		return

#	Disable button to gray it out to indicate that it's
#	getting moved
	item_button.set_disabled(true)
	_moved_item_button = item_button


func _on_item_move_from_tower_done(_success: bool):
	_moved_item_button.set_disabled(false)
	_moved_item_button = null


func _on_upgrade_button_pressed():
	var tower: Tower = get_selected_tower()
	var upgrade_id: int = _get_upgrade_id_for_tower(tower)

	if upgrade_id == -1:
		print_debug("Failed to find upgrade id")

		return

	var upgrade_tower: Tower = TowerManager.get_tower(upgrade_id)
	upgrade_tower.position = tower.position
	upgrade_tower._temp_preceding_tower = tower
	Utils.add_object_to_world(upgrade_tower)
	tower.queue_free()

	SelectUnit.set_selected_unit(upgrade_tower)

	_update_upgrade_button()

#	Refresh tooltip for upgrade button
	_on_upgrade_button_mouse_entered()


func _get_upgrade_id_for_tower(tower: Tower) -> int:
	var family_id: int = tower.get_family()
	var family_list: Array = Properties.get_tower_id_list_by_filter(Tower.CsvProperty.FAMILY_ID, str(family_id))
	var next_tier: int = tower.get_tier() + 1

	for id in family_list:
		var this_tier: int = TowerProperties.get_tier(id)

		if this_tier == next_tier:
			return id
	
	return -1


func _update_upgrade_button():
	var tower = get_selected_tower()
	var upgrade_id: int = _get_upgrade_id_for_tower(tower)

	var can_upgrade: bool
	if upgrade_id != -1:
		can_upgrade = TowerProperties.requirements_are_satisfied(upgrade_id) || Config.ignore_requirements()
	else:
		can_upgrade = false

	_upgrade_button.set_disabled(!can_upgrade)


func _on_reset_sell_button_timer_timeout():
	_set_selling_for_real(false)


func _on_sell_button_pressed():
	if !_selling_for_real:
		_set_selling_for_real(true)

		return

	var tower: Tower = get_selected_tower()

# 	Return tower items to storage
	var item_list: Array[Item] = tower.get_items()

	for item in item_list:
		item.drop()
		item.fly_to_stash(0.0)

	var build_cost: float = TowerProperties.get_cost(tower.get_id())
	var sell_ratio: float = GameMode.get_sell_ratio(Globals.game_mode)
	var sell_price: int = floor(build_cost * sell_ratio)
	tower.getOwner().give_gold(sell_price, tower, false, true)
	BuildTower.tower_was_sold(tower.position)
	tower.queue_free()

	SelectUnit.set_selected_unit(null)

	FoodManager.remove_tower()


func _set_selling_for_real(value: bool):
	_selling_for_real = value

	if _selling_for_real:
		_sell_button.theme_type_variation = "WarningButton"
	else:
		_sell_button.theme_type_variation = ""

	if _selling_for_real:
		_reset_sell_button_timer.start(SELL_BUTTON_RESET_TIME)
	else:
		_reset_sell_button_timer.stop()


func _on_info_button_pressed(button_pressed: bool):
	if button_pressed:
		_tower_control_menu.hide()
		_tower_stats_menu.show()
	else:
		_tower_control_menu.show()
		_tower_stats_menu.hide()


func _on_upgrade_button_mouse_entered():
	var tower: Tower = get_selected_tower()
	var upgrade_id: int = _get_upgrade_id_for_tower(tower)

	if upgrade_id == -1:
		return

	EventBus.tower_button_mouse_entered.emit(upgrade_id)


func _on_upgrade_button_mouse_exited():
	EventBus.tower_button_mouse_exited.emit()
