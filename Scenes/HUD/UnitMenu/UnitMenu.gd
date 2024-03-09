class_name UnitMenu
extends PanelContainer


const SELL_BUTTON_RESET_TIME: float = 5.0
const _default_buff_icon: Texture2D = preload("res://Assets/Buffs/question_mark.png")
const ITEMS_CONTAINER_BUTTON_SIZE = 82

@export var _upgrade_button: Button
@export var _sell_button: Button
@export var _info_button: Button
@export var _reset_sell_button_timer: Timer
@export var _items_box_container: HBoxContainer
@export var _title_label: Label
@export var _unit_info_label: RichTextLabel
@export var _unit_icon_texture: TextureRect
@export var _unit_level_label: Label
@export var _unit_control_menu: VBoxContainer
@export var _unit_stats_menu: ScrollContainer
@export var _creep_stats_menu: ScrollContainer
@export var _buffs_container: GridContainer
@export var _info_label: RichTextLabel
@export var _tier_icon_texture: TextureRect
@export var _specials_label: RichTextLabel
@export var _inventory_empty_slots: HBoxContainer
@export var _inventory: PanelContainer
@export var _main_container: VBoxContainer
@export var _specials_scroll_container: ScrollContainer
@export var _creep_specials_container: Container
@export var _tower_specials_container: Container

var _selling_for_real: bool = false


#########################
###     Built-in      ###
#########################

func _ready():
#	NOTE: fix unused warnings
	_unit_info_label = _unit_info_label
	
	SelectUnit.selected_unit_changed.connect(_on_selected_unit_changed)
	
	_on_selected_unit_changed(null)
	
	WaveLevel.changed.connect(_on_update_requirements_changed)
	ElementLevel.changed.connect(_on_update_requirements_changed)
	GoldControl.changed.connect(_on_update_requirements_changed)
	KnowledgeTomesManager.changed.connect(_on_update_requirements_changed)
	
	_sell_button.pressed.connect(_on_sell_button_pressed)
	_upgrade_button.pressed.connect(_on_upgrade_button_pressed)
	_info_button.pressed.connect(_on_info_button_pressed)
	_upgrade_button.mouse_entered.connect(_on_tower_upgrade_button_mouse_entered)
	_items_box_container.child_entered_tree.connect(_on_items_box_container_child_entered_tree)

	for i in range(0, Constants.INVENTORY_CAPACITY_MAX):
		var empty_slot_button: EmptyUnitButton = EmptyUnitButton.make()
		_inventory_empty_slots.add_child(empty_slot_button)


#########################
###       Public      ###
#########################

func _process(_delta: float):
	var selected_unit: Unit = SelectUnit.get_selected_unit()

	if selected_unit != null:
		_update_info_label(selected_unit)


func close():
	SelectUnit.set_selected_unit(null)


func is_visibility_mode_expanded() -> bool:
	return _main_container.visible


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


#########################
###      Private      ###
#########################


func _update_unit_icon(unit: Unit):
	if unit is Tower:
		_unit_icon_texture.texture = UnitIcons.get_tower_icon(unit.get_id())
		_tier_icon_texture.texture = UnitIcons.get_tower_tier_icon(unit.get_id())
	elif unit is Creep:
		_unit_icon_texture.texture = UnitIcons.get_creep_icon(unit)
	else:
		assert(unit != null, "Unit is of unknown type. Can't get info label for it.")


func _update_info_label(unit: Unit):
	var contents
	if unit is Tower:
		contents = RichTexts.get_tower_info(unit)
	elif unit is Creep:
		contents = RichTexts.get_creep_info(unit)
	else:
		assert(unit != null, "Unit is of unknown type. Can't get info label for it.")
	_info_label.text = contents


func _update_info_label_tooltip(unit: Unit):
	if unit == null:
		return

	var tooltip_for_info_label: String = _get_tooltip_for_info_label(unit)
	_info_label.set_tooltip_text(tooltip_for_info_label)


func _update_creep_specials_container(creep: Creep):
	var special_list: Array[int] = creep.get_special_list()
	for special_container in _creep_specials_container.get_children():
		special_container.queue_free()

	for special in special_list:
		var special_name: String = WaveSpecialProperties.get_special_name(special)
		var special_description: String = WaveSpecialProperties.get_description(special)
		var special_icon: TextureRect = WaveSpecialProperties.get_special_icon(special)
		var creep_special: SpecialContainer = SpecialContainer.make(special_name, special_icon, special_description)
		
		_creep_specials_container.add_child(creep_special)


func _update_specials_label(unit: Tower):
	var text: String = ""
	var specials_text: String = unit.get_specials_tooltip_text()
	var extra_text: String = unit.get_ability_description()

	if !specials_text.is_empty():
		text += specials_text
		text += " \n"

	if !extra_text.is_empty():
		text += extra_text
		text += " \n"

	for autocast in unit.get_autocast_list():
		var autocast_text: String = RichTexts.get_autocast_text(autocast)
		text += autocast_text
		text += " \n"
	
	text = RichTexts.add_color_to_numbers(text)

	_specials_label.clear()
	_specials_label.append_text(text)


func _update_unit_name_label(unit: Unit):
	_title_label.text = unit.get_display_name()


func _update_unit_level_label():
	var unit: Unit = SelectUnit.get_selected_unit()

	if unit == null:
		return

	_unit_level_label.text = str(unit.get_level())


# Show the number of empty slots equal to tower's inventory
# capacity
func _update_inventory_empty_slots(tower: Tower):
	var inventory_capacity: int = tower.get_inventory_capacity()

	var inventory_slots: Array[Node] = _inventory_empty_slots.get_children()

	for i in range(0, inventory_slots.size()):
		var slot: Control = inventory_slots[i] as Control
		slot.visible = i < inventory_capacity


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
		var requirements_are_satisfied: bool = TowerProperties.requirements_are_satisfied(upgrade_id) || Config.ignore_requirements()
		var enough_gold: bool = GoldControl.enough_gold_for_tower(upgrade_id)
		var enough_tomes: bool = KnowledgeTomesManager.enough_tomes_for_tower(upgrade_id)
		can_upgrade = requirements_are_satisfied && enough_gold && enough_tomes
	else:
		can_upgrade = false

	_upgrade_button.set_disabled(!can_upgrade)


func _update_sell_tooltip(tower: Tower):
	var game_mode: GameMode.enm = PregameSettings.get_game_mode()
	var sell_ratio: float = GameMode.get_sell_ratio(game_mode)
	var sell_ratio_string: String = Utils.format_percent(sell_ratio, 0)
	var sell_price: int = TowerProperties.get_sell_price(tower.get_id())
	var tooltip: String = "Sell tower\nYou will receive %d gold (%s of original cost)." % [sell_price, sell_ratio_string]

	_sell_button.set_tooltip_text(tooltip)


func _get_specials_text_for_creep(unit: Unit):
	var text: String = ""

	var creep: Creep = unit as Creep

	var special_list: Array[int] = creep.get_special_list()

	for special in special_list:
		var special_name: String = WaveSpecialProperties.get_special_name(special)
		var special_description: String = WaveSpecialProperties.get_description(special)
		text += "[color=GOLD]%s[/color]\n" % special_name
		text += "%s\n" % special_description
		text += " \n"

	return text


func _is_showing_main_page() -> bool:
	var showing_main_page: bool = _unit_control_menu.visible

	return showing_main_page


func _get_tooltip_for_info_label(unit: Unit) -> String:
	if unit is Tower:
		var tower: Tower = unit as Tower
		var attack_type: AttackType.enm = tower.get_attack_type()
		var attack_type_name: String = AttackType.convert_to_string(attack_type).capitalize()
		var text_for_damage_against: String = AttackType.get_text_for_damage_dealt(attack_type)

		var tooltip: String = ""
		tooltip += "%s attacks deal this much damage\nagainst armor types:\n" % attack_type_name
		tooltip += text_for_damage_against

		return tooltip
	else:
		var creep: Creep = unit as Creep
		var armor_type: ArmorType.enm = creep.get_armor_type()
		var armor_type_name: String = ArmorType.convert_to_string(armor_type).capitalize()
		var text_for_damage_taken: String = ArmorType.get_text_for_damage_taken(armor_type)
	
		var tooltip: String = ""
		tooltip += "%s armor takes this much damage\nfrom attack types:\n" % armor_type_name
		tooltip += text_for_damage_taken

		return tooltip


func _set_selling_for_real(value: bool):
	_selling_for_real = value

	if _selling_for_real:
		_sell_button.modulate = Color(Color.CRIMSON)
	else:
		_sell_button.modulate = Color(Color.WHITE)

	if _selling_for_real:
		_reset_sell_button_timer.start(SELL_BUTTON_RESET_TIME)
	else:
		_reset_sell_button_timer.stop()


#########################
###     Callbacks     ###
#########################

func _on_update_requirements_changed():
	var tower = get_selected_tower()
	if tower != null:
		_update_upgrade_button(tower)


func _on_items_box_container_child_entered_tree(node):
	node.custom_minimum_size = Vector2(ITEMS_CONTAINER_BUTTON_SIZE, ITEMS_CONTAINER_BUTTON_SIZE)


func _on_selected_unit_changed(prev_unit: Unit):
#	Reset all scroll positions when switching to a different unit
	Utils.reset_scroll_container(_specials_scroll_container)
	Utils.reset_scroll_container(_unit_stats_menu)
	Utils.reset_scroll_container(_creep_stats_menu)

	var tower: Tower = get_selected_tower()
	var creep: Creep = get_selected_creep()
	var selected_tower: bool = tower != null
	var selected_creep: bool = creep != null
	assert(not (tower != null and creep != null), "Both tower and creep are selected.")
	
	if prev_unit != null and prev_unit is Tower:
		prev_unit.items_changed.disconnect(_on_tower_items_changed)
		prev_unit.buff_list_changed.disconnect(_on_unit_buff_list_changed)
		prev_unit.level_up.disconnect(_on_unit_level_up)

	if prev_unit != null and prev_unit is Creep:
		prev_unit.buff_list_changed.disconnect(_on_unit_buff_list_changed)
	
	if selected_tower:
		tower.items_changed.connect(_on_tower_items_changed.bind(tower))
		tower.buff_list_changed.connect(_on_unit_buff_list_changed.bind(tower))
		tower.level_up.connect(_on_unit_level_up)
		_on_tower_items_changed(tower)
		_update_upgrade_button(tower)
		_update_unit_name_label(tower)
		_update_unit_level_label()
		_on_unit_buff_list_changed(tower)
		_update_info_label(tower)
		_update_info_label_tooltip(tower)
#		NOTE: Towers still don't have icons for their specials.
#		Once we introduce icons, we'd have to switch to _update_creep_specials_container
		_update_specials_label(tower)
		_update_unit_icon(tower)
		_update_inventory_empty_slots(tower)
		_update_sell_tooltip(tower)
		
		_inventory.show()
		_tier_icon_texture.show()
		var upgrade_button_should_be_visible: bool = PregameSettings.get_game_mode() == GameMode.enm.BUILD || PregameSettings.get_game_mode() == GameMode.enm.RANDOM_WITH_UPGRADES
		_upgrade_button.set_visible(upgrade_button_should_be_visible)
		_sell_button.show()
		_creep_specials_container.hide()
		_tower_specials_container.show()
	elif selected_creep:
		creep.buff_list_changed.connect(_on_unit_buff_list_changed.bind(creep))
		_update_unit_name_label(creep)
		_on_unit_buff_list_changed(creep)
		_update_info_label(creep)
		_update_info_label_tooltip(creep)
		_update_creep_specials_container(creep)
		_update_unit_icon(creep)
		_update_unit_level_label()
		
		_inventory.hide()
		_tier_icon_texture.hide()
		_upgrade_button.hide()
		_sell_button.hide()
		_creep_specials_container.show()
		_tower_specials_container.hide()

	if !_is_showing_main_page():
		_unit_stats_menu.visible = selected_tower
		_creep_stats_menu.visible = selected_creep

	_set_selling_for_real(false)


func _on_tower_items_changed(tower: Tower):
	for unit_button_container in _items_box_container.get_children():
		unit_button_container.queue_free()

	var items: Array[Item] = tower.get_items()

	for item in items:
		var item_button: ItemButton = ItemButton.make(item)
		item_button.show_cooldown_indicator()
		item_button.show_auto_mode_indicator()
		item_button.theme_type_variation = "TinyUnitButton"
		item_button.show_charges()
		_items_box_container.add_child(item_button)
		item_button.pressed.connect(_on_item_button_pressed.bind(item_button))


func _on_item_button_pressed(item_button: ItemButton):
	var item: Item = item_button.get_item()
	ItemMovement.item_was_clicked_in_tower_inventory(item)


func _on_upgrade_button_pressed():
	var tower: Tower = get_selected_tower()
	if tower == null:
		return

	var prev_id: int = tower.get_id()
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

	var refund_for_prev_tier: float = TowerProperties.get_cost(prev_id)
	var upgrade_cost: float = TowerProperties.get_cost(upgrade_id)
	GoldControl.add_gold(refund_for_prev_tier)
	GoldControl.spend_gold(upgrade_cost)

	_update_upgrade_button(upgrade_tower)

#	NOTE: hide and show upgrade button to trigger
#	mouse_entered() signal to refresh the button tooltip.
#	Note that we cannot manually call
#	_on_tower_upgrade_button_mouse_entered() because it
#	doesn't work correctly for the case where upgrade button
#	was pressed using the keyboard shortcut.
	_upgrade_button.hide()
	_upgrade_button.show()


func _on_reset_sell_button_timer_timeout():
	_set_selling_for_real(false)


func _on_sell_button_pressed():
	var tower: Tower = get_selected_tower()
	if tower == null:
		return

	if !_selling_for_real:
		_set_selling_for_real(true)
		return

	var tower_id: int = tower.get_id()
	
# 	Return tower items to storage
	var item_list: Array[Item] = tower.get_items()

	for item in item_list:
		item.drop()
		item.fly_to_stash(0.0)

	BuildTower.clear_space_occupied_by_tower(tower)

	var sell_price: int = TowerProperties.get_sell_price(tower_id)
	tower.get_player().give_gold(sell_price, tower, false, true)
	tower.queue_free()

	SelectUnit.set_selected_unit(null)

	FoodManager.remove_tower(tower_id)


func _on_info_button_pressed():
	var was_showing_main_page: bool = _is_showing_main_page()
	var selected_unit: Unit = SelectUnit.get_selected_unit()
	var show_tower_stats: bool = selected_unit is Tower && was_showing_main_page
	var show_creep_stats: bool = selected_unit is Creep && was_showing_main_page

	_unit_control_menu.visible = !was_showing_main_page
	_unit_stats_menu.visible = show_tower_stats
	_creep_stats_menu.visible = show_creep_stats


func _on_unit_buff_list_changed(unit: Unit):
	var friendly_buff_list: Array[Buff] = unit._get_buff_list(true)
	var unfriendly_buff_list: Array[Buff] = unit._get_buff_list(false)

	var buff_list: Array[Buff] = []
	buff_list.append_array(friendly_buff_list)
	buff_list.append_array(unfriendly_buff_list)

	var hidden_buff_list: Array[Buff] = []

	for buff in buff_list:
		if buff.is_hidden():
			hidden_buff_list.append(buff)

	if !Config.show_hidden_buffs():
		for buff in hidden_buff_list:
			buff_list.erase(buff)

	for buff_icon in _buffs_container.get_children():
		buff_icon.queue_free()

	for buff in buff_list:
		var tooltip: String = buff.get_tooltip_text()
		var buff_icon: TextureRectWithRichTooltip = TextureRectWithRichTooltip.new()
		buff_icon.set_tooltip_text(tooltip)

		var texture_path: String = buff.get_buff_icon()

		if !ResourceLoader.exists(texture_path):
			if buff.is_hidden():
				texture_path = "res://Assets/Buffs/question_mark.png"
			elif buff.is_friendly():
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

	var tooltip: String = RichTexts.get_tower_text(upgrade_id)
	ButtonTooltip.show_tooltip(_upgrade_button, tooltip)


func _on_items_container_gui_input(event):
	var left_click: bool = event.is_action_released("left_click")
	var tower: Tower = get_selected_tower()

	if left_click && tower != null:
		ItemMovement.tower_was_clicked(tower)


# When tower menu is closed, deselect the unit which will
# also close the menu
func _on_close_button_pressed():
	close()


func _on_unit_level_up(_level_increased: bool):
	_update_unit_level_label()
