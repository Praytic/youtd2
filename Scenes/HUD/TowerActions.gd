extends Control

# Container for buttons that perform actions on selected tower.

# TODO: sell button
# TODO: info button (shows info for tower like the build button)
# TODO: show info when hovering over upgrade button (info for next tier)
# TODO: upgrade requirements, cost, current level, research level (show this in tooltip as well)
# TODO: feature flag that disables upgrade requirements to be able to upgrade tower any time


const BUILD_COST_TO_SELL_PRICE: float = 0.5
const SELL_BUTTON_RESET_TIME: float = 5.0

@onready var _upgrade_button: Button = $VBoxContainer/UpgradeButton
@onready var _sell_button: Button = $VBoxContainer/SellButton
@onready var _reset_sell_button_timer: Timer = $ResetSellButtonTimer

var _selling_for_real: bool = false


func _ready():
	SelectUnit.selected_unit_changed.connect(_on_selected_unit_changed)
	_on_selected_unit_changed()

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
		_update_upgrade_button(tower)

	_set_selling_for_real(false)


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
		EventBus.item_drop_picked_up.emit(item)

	var build_cost: float = TowerProperties.get_cost(tower.get_id())
	var sell_price: int = floor(build_cost * BUILD_COST_TO_SELL_PRICE)
	tower.getOwner().give_gold(sell_price, tower, false, true)
	BuildTower.tower_was_sold(tower.position)
	tower.queue_free()

	SelectUnit.set_selected_unit(null)


func _set_selling_for_real(value: bool):
	_selling_for_real = value

	var sell_button_text: String
	if _selling_for_real:
		sell_button_text = "Sell (for real)"
	else:
		sell_button_text = "Sell"

	_sell_button.set_text(sell_button_text)

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
