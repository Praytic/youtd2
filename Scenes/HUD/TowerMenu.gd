class_name TowerMenu
extends Control


const SELL_BUTTON_RESET_TIME: float = 5.0

@export var _upgrade_button: Button
@export var _sell_button: Button
@export var _reset_sell_button_timer: Timer
@export var _items_box_container: HBoxContainer


var _tower: Tower = null
var _moved_item_button: ItemButton = null
var _selling_for_real: bool = false


func _ready():
	SelectUnit.selected_unit_changed.connect(_on_selected_unit_changed)
	
	_on_selected_unit_changed()
	
	ItemMovement.item_move_from_tower_done.connect(_on_item_move_from_tower_done)
	WaveLevel.changed.connect(_on_wave_or_element_level_changed)
	ElementLevel.changed.connect(_on_wave_or_element_level_changed)


func _on_wave_or_element_level_changed():
	var selected_unit: Unit = SelectUnit.get_selected_unit()

	if selected_unit != null && selected_unit is Tower:
		var tower: Tower = selected_unit as Tower
		_update_upgrade_button(tower)


func _on_selected_unit_changed():
	var selected_unit: Unit = SelectUnit.get_selected_unit()
	
	visible = selected_unit != null && selected_unit is Tower

	if selected_unit is Tower:
		var tower: Tower = selected_unit as Tower
		set_tower(tower)
		_update_upgrade_button(tower)

	_set_selling_for_real(false)


func set_tower(tower: Tower):
	var prev_tower: Tower = _tower
	var new_tower: Tower = tower
	_tower = new_tower

	if prev_tower != null:
		prev_tower.items_changed.disconnect(on_tower_items_changed)

	if new_tower != null:
		new_tower.items_changed.connect(on_tower_items_changed)
		on_tower_items_changed()


func on_tower_items_changed():
	for button in _items_box_container.get_children():
		button.queue_free()

	var items: Array[Item] = _tower.get_items()

	for item in items:
		var item_button = ItemButton.make(item)
		item_button.theme_type_variation = "SmallButton"
		var button_container = UnitButtonContainer.make()
		button_container.add_child(item_button)
		_items_box_container.add_child(button_container)
		item_button.pressed.connect(_on_item_button_pressed.bind(item_button))


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
	var tower: Tower = SelectUnit.get_selected_unit() as Tower
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

	_update_upgrade_button(upgrade_tower)

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


func _update_upgrade_button(tower: Tower):
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

	var tower: Tower = SelectUnit.get_selected_unit() as Tower

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
		_sell_button.modulate = Color(255, 108, 108)
	else:
		_sell_button.modulate = Color(255, 255, 255)

	if _selling_for_real:
		_reset_sell_button_timer.start(SELL_BUTTON_RESET_TIME)
	else:
		_reset_sell_button_timer.stop()


func _on_info_button_mouse_entered():
	var tower: Tower = SelectUnit.get_selected_unit() as Tower
	var tower_id: int = tower.get_id()
	EventBus.tower_button_mouse_entered.emit(tower_id)


func _on_info_button_mouse_exited():
	EventBus.tower_button_mouse_exited.emit()


func _on_upgrade_button_mouse_entered():
	var tower: Tower = SelectUnit.get_selected_unit() as Tower
	var upgrade_id: int = _get_upgrade_id_for_tower(tower)

	if upgrade_id == -1:
		return

	EventBus.tower_button_mouse_entered.emit(upgrade_id)


func _on_upgrade_button_mouse_exited():
	EventBus.tower_button_mouse_exited.emit()
