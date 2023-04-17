extends Control

# Container for buttons that perform actions on selected tower.

# TODO: sell button
# TODO: info button (shows info for tower like the build button)
# TODO: show info when hovering over upgrade button (info for next tier)
# TODO: upgrade requirements, cost, current level, research level (show this in tooltip as well)
# TODO: feature flag that disables upgrade requirements to be able to upgrade tower any time


@onready var _upgrade_button: Button = $VBoxContainer/UpgradeButton


func _ready():
	SelectUnit.selected_unit_changed.connect(_on_selected_unit_changed)
	_on_selected_unit_changed()


func _on_selected_unit_changed():
	var selected_unit: Unit = SelectUnit.get_selected_unit()
	
	visible = selected_unit != null && selected_unit is Tower

	if selected_unit is Tower:
		var tower: Tower = selected_unit as Tower
		_update_upgrade_button(tower)


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
	var can_upgrade: bool = upgrade_id != -1
	_upgrade_button.set_disabled(!can_upgrade)
