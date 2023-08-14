class_name UnitMenu
extends Control


const SELL_BUTTON_RESET_TIME: float = 5.0
const _default_buff_icon: Texture2D = preload("res://Assets/Buffs/question_mark.png")

@export var _upgrade_button: Button
@export var _sell_button: Button
@export var _info_button: Button
@export var _reset_sell_button_timer: Timer
@export var _items_box_container: HBoxContainer
@export var _unit_name_label: Label
@export var _unit_info_label: RichTextLabel
@export var _unit_icon_texture: TextureRect
@export var _unit_specials_container: VBoxContainer
@export var _unit_level_label: Label
@export var _unit_control_menu: VBoxContainer
@export var _unit_stats_menu: ScrollContainer
@export var _buffs_container: GridContainer
@export var _info_label: RichTextLabel
@export var _specials_container: VBoxContainer
@export var _tier_icon_texture: TextureRect
@export var _specials_label: RichTextLabel
@export var _inventory_empty_slots: HBoxContainer
@export var _inventory: PanelContainer

var _moved_item_button: ItemButton = null
var _selling_for_real: bool = false


func _ready():
	hide()
	
	SelectUnit.selected_unit_changed.connect(_on_selected_unit_changed)
	
	_on_selected_unit_changed(null)
	
	ItemMovement.item_move_from_tower_done.connect(_on_item_move_from_tower_done)
	WaveLevel.changed.connect(_on_wave_or_element_level_changed)
	ElementLevel.changed.connect(_on_wave_or_element_level_changed)
	
	_sell_button.pressed.connect(_on_sell_button_pressed)
	_upgrade_button.pressed.connect(_on_upgrade_button_pressed)
	_info_button.toggled.connect(_on_info_button_pressed)

	for i in range(0, Constants.INVENTORY_CAPACITY_MAX):
		var empty_slot_button: EmptySlotButton = EmptySlotButton.make()
		empty_slot_button.theme_type_variation = "SmallButton"
		_inventory_empty_slots.add_child(empty_slot_button)


func _on_wave_or_element_level_changed():
	var tower = get_selected_tower()
	if tower != null:
		_update_upgrade_button(tower)


func _on_selected_unit_changed(prev_unit: Unit):
	var tower: Tower = get_selected_tower()
	var creep: Creep = get_selected_creep()
	assert(not (tower != null and creep != null), "Both tower and creep are selected.")
	
	visible = tower != null or creep != null

	if prev_unit != null and prev_unit is Tower:
		prev_unit.items_changed.disconnect(on_tower_items_changed)
		prev_unit.buff_list_changed.disconnect(_on_unit_buff_list_changed)

	if prev_unit != null and prev_unit is Creep:
		prev_unit.buff_list_changed.disconnect(_on_unit_buff_list_changed)
	
	if tower != null:
		tower.items_changed.connect(on_tower_items_changed.bind(tower))
		tower.buff_list_changed.connect(_on_unit_buff_list_changed.bind(tower))
		on_tower_items_changed(tower)
		_update_upgrade_button(tower)
		_update_unit_name_label(tower)
		_update_unit_level_label(tower)
		_on_unit_buff_list_changed(tower)
		_update_info_label(tower)
		_update_specials_label(tower)
		_update_unit_icon(tower)
		_update_inventory_empty_slots(tower)
		
		_inventory.show()
		_tier_icon_texture.show()
		var upgrade_button_should_be_visible: bool = Globals.game_mode == GameMode.enm.BUILD || Globals.game_mode == GameMode.enm.RANDOM_WITH_UPGRADES
		_upgrade_button.set_visible(upgrade_button_should_be_visible)
		_sell_button.show()
		show()

	if creep != null:
		creep.buff_list_changed.connect(_on_unit_buff_list_changed.bind(creep))
		_update_unit_name_label(creep)
		_on_unit_buff_list_changed(creep)
		_update_info_label(creep)
		_update_specials_label(creep)
		_update_unit_icon(creep)
		_update_unit_level_label(creep)
		
		_inventory.hide()
		_tier_icon_texture.hide()
		_upgrade_button.hide()
		_sell_button.hide()
		show()
	
	_set_selling_for_real(false)


func get_selected_tower() -> Tower:
	var selected_unit = SelectUnit.get_selected_unit()
	if selected_unit is Tower:
		return selected_unit as Tower
	else:
		return null


func get_selected_creep() -> Creep:
	var selected_unit = SelectUnit.get_selected_unit()
	if selected_unit is Creep:
		return selected_unit as Creep
	else:
		return null


func on_tower_items_changed(tower: Tower):
	for button in _items_box_container.get_children():
		button.queue_free()

	var items: Array[Item] = tower.get_items()

	for item in items:
		var item_button = ItemButton.make(item)
		item_button.theme_type_variation = "SmallButton"
		var button_container = UnitButtonContainer.make()
		button_container.add_child(item_button)
		_items_box_container.add_child(button_container)
		item_button.pressed.connect(_on_item_button_pressed.bind(item_button))


func _update_unit_icon(unit: Unit):
	if unit is Tower:
		_unit_icon_texture.texture = TowerProperties.get_icon_texture(unit.get_id())
		_tier_icon_texture.texture = TowerProperties.get_tier_icon_texture(unit.get_id())
	elif unit is Creep:
		_unit_icon_texture.texture = CreepProperties.get_icon_texture(unit)
	else:
		assert(unit != null, "Unit is of unknown type. Can't get info label for it.")


func _update_info_label(unit: Unit):
	var contents
	if unit is Tower:
		contents = RichTexts.get_tower_info(unit.get_id())
	elif unit is Creep:
		contents = RichTexts.get_creep_info(unit)
	else:
		assert(unit != null, "Unit is of unknown type. Can't get info label for it.")
	_info_label.text = contents


func _update_specials_label(unit: Unit):
	var text: String = ""
	if unit is Tower:
		var specials_text: String = unit.get_specials_tooltip_text()
		var extra_text: String = unit.get_extra_tooltip_text()

		text += specials_text
		text += " \n"
		text += extra_text

		for autocast in unit.get_autocast_list():
			var autocast_text: String = RichTexts.get_autocast_text(autocast)
			text += " \n"
			text += autocast_text
	elif unit is Creep:
		text = ""
	else:
		assert(unit != null, "Unit is of unknown type. Can't get specials label for it.")
	
	text = RichTexts.add_color_to_numbers(text)

	_specials_label.clear()
	_specials_label.append_text(text)


func _update_unit_name_label(unit: Unit):
	_unit_name_label.text = unit.get_display_name()


func _update_unit_level_label(unit: Unit):
	_unit_level_label.text = str(unit.get_level())


# Show the number of empty slots equal to tower's inventory
# capacity
func _update_inventory_empty_slots(tower: Tower):
	var inventory_capacity: int = tower.get_inventory_capacity()

	var inventory_slots: Array[Node] = _inventory_empty_slots.get_children()

	for i in range(0, inventory_slots.size()):
		var slot: Control = inventory_slots[i] as Control
		slot.visible = i < inventory_capacity


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
	if tower == null:
		return

	var upgrade_id: int = _get_upgrade_id_for_tower(tower)

	if upgrade_id == -1:
		print_debug("Failed to find upgrade id")

		return

	var enough_gold: bool = GoldControl.enough_gold_for_tower(upgrade_id)

	if !enough_gold:
		Messages.add_error("Not enough gold.")

		return

	var upgrade_tower: Tower = TowerManager.get_tower(upgrade_id)
	upgrade_tower.position = tower.position
	upgrade_tower._temp_preceding_tower = tower
	Utils.add_object_to_world(upgrade_tower)
	tower.queue_free()

	SelectUnit.set_selected_unit(upgrade_tower)

	var upgrade_cost: float = TowerProperties.get_cost(upgrade_id)
	GoldControl.spend_gold(upgrade_cost)

	_update_upgrade_button(tower)


func _get_upgrade_id_for_tower(tower: Tower) -> int:
	var family_id: int = tower.get_family()
	var family_list: Array = TowerProperties.get_towers_in_family(family_id)
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
	var tower: Tower = get_selected_tower()
	if tower == null:
		return

	if !_selling_for_real:
		_set_selling_for_real(true)
		return
	
# 	Return tower items to storage
	var item_list: Array[Item] = tower.get_items()

	for item in item_list:
		item.drop()
		item.fly_to_stash(0.0)

	var sell_price: float = TowerProperties.get_sell_price(tower.get_id())
	var sell_ratio: float = GameMode.get_sell_ratio(Globals.game_mode)
	sell_price = floor(sell_price * sell_ratio)
	tower.getOwner().give_gold(sell_price, tower, false, true)
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
		_unit_control_menu.hide()
		_unit_stats_menu.show()
	else:
		_unit_control_menu.show()
		_unit_stats_menu.hide()


func _on_unit_buff_list_changed(unit: Unit):
	var friendly_buff_list: Array[Buff] = unit._get_buff_list(true)
	var unfriendly_buff_list: Array[Buff] = unit._get_buff_list(false)

	var buff_list: Array[Buff] = []
	buff_list.append_array(friendly_buff_list)
	buff_list.append_array(unfriendly_buff_list)

# 	NOTE: remove trigger buffs, they have empty type and
# 	shouldn't be displayed
	var trigger_buff_list: Array[Buff] = []

	for buff in buff_list:
		var is_trigger_buff: bool = buff.get_type().is_empty()
		if is_trigger_buff:
			trigger_buff_list.append(buff)

	for buff in trigger_buff_list:
		buff_list.erase(buff)

	for buff_icon in _buffs_container.get_children():
		buff_icon.queue_free()

	for buff in buff_list:
		var tooltip: String = buff.get_tooltip_text()
		var buff_icon = TextureRect.new()
		buff_icon.set_tooltip_text(tooltip)

		var texture_path: String = buff.get_buff_icon()

		if !ResourceLoader.exists(texture_path):
			if buff.is_friendly():
				texture_path = "res://Assets/Buffs/buff_plus.png"
			else:
				texture_path = "res://Assets/Buffs/buff_minus.png"

		var texture: Texture2D = load(texture_path)
		buff_icon.texture = texture
		_buffs_container.add_child(buff_icon)


func _on_tower_upgrade_button_mouse_entered():
	var tower: Tower = SelectUnit.get_selected_unit() as Tower
	var upgrade_id: int = _get_upgrade_id_for_tower(tower)

	if upgrade_id == -1:
		return

	EventBus.tower_button_mouse_entered.emit(upgrade_id)


func _on_tower_upgrade_button_mouse_exited():
	EventBus.tower_button_mouse_exited.emit()


func _on_items_container_gui_input(event):
	var left_click: bool = event.is_action_released("left_click")
	var tower: Tower = get_selected_tower()

	if left_click && tower != null:
		ItemMovement.finish_move_to_tower_menu(tower)
