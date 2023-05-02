class_name ItemButton 
extends Button


const ICON_SIZE_S = 64
const ICON_SIZE_M = 128
const TIER_ICON_SIZE_S = 32
const TIER_ICON_SIZE_M = 64

var tier_icon: Texture2D
var background: Texture2D
var _charges_label: Label
# Item instance that corresponds to this button. This is
# non-null only for item buttons in tower inventory.
var _item_instance: Item = null
var count: int = randi_range(1, 3)

var _item_id: int
@onready var _icon_size: String : set = set_icon_size
@onready var _tier_icons_s = preload("res://Assets/Towers/tier_icons_s.png")
@onready var _tier_icons_m = preload("res://Assets/Towers/tier_icons_m.png")
@onready var _tier_background_s = preload("res://Assets/UI/HUD/misc4.png")


func _ready():
	set_theme_type_variation("TowerButton")
	set_icon_size("S")
	
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)
	
	_charges_label = Label.new()
	_charges_label.set("theme_override_font_sizes/font_size", 14)
	_charges_label.set("layout_mode", 1)
	_charges_label.set("anchors_preset", LayoutPreset.PRESET_CENTER_BOTTOM)
	_charges_label.set("vertical_alignment", VerticalAlignment.VERTICAL_ALIGNMENT_BOTTOM)
	add_child(_charges_label)
	
	if _item_instance != null:
		_on_item_charges_changed(_item_instance)


func _draw():
	var current_glowing_rect: Rect2 = Rect2(2, -2, 66, 66)
	
	draw_texture_rect(background, current_glowing_rect, false)
	
	if count > 1:
		var current_charges_rect = Rect2(current_glowing_rect.position.x, current_glowing_rect.size.y - 14, current_glowing_rect.size.x, 14) 
		draw_rect(current_charges_rect, Color(0, 0, 0, 0.5))
	
	draw_texture(icon, Vector2(2, -2))
	
	if is_pressed() or is_disabled():
		draw_rect(current_glowing_rect, Color(1, 1, 1, 0.3), true)
	
	if count > 1:
		var current_charges_rect = Rect2(current_glowing_rect.position.x, current_glowing_rect.size.y - 14, current_glowing_rect.size.x, 14) 
		draw_rect(current_charges_rect, Color(0, 0, 0, 0.5))
		_charges_label.text = str(count)
	else:
		_charges_label.text = ""


func set_item_instance(item: Item):
	_item_instance = item
	_item_instance.charges_changed.connect(_on_item_charges_changed.bind(item))


func set_icon_size(icon_size: String):
	_icon_size = icon_size
	tier_icon = _get_item_button_tier_icon(icon_size)
	background = _get_item_button_background(icon_size)
	icon = ItemProperties.get_icon(_item_id, icon_size)

func set_item(item_id: int):
	_item_id = item_id


func get_item() -> int:
	return _item_id
	
func _get_item_button_tier_icon(icon_size_letter: String) -> Texture2D:
	var item_rarity = ItemProperties.get_rarity_num(_item_id)
	
	var icon_out = AtlasTexture.new()
	var icon_size: int
	if icon_size_letter == "S":
		icon_out.set_atlas(_tier_icons_s)
		icon_size = TIER_ICON_SIZE_S
	elif icon_size_letter == "M":
		icon_out.set_atlas(_tier_icons_m)
		icon_size = TIER_ICON_SIZE_M
	else:
		return null
	
	icon_out.set_region(Rect2(6 * icon_size, item_rarity * icon_size, icon_size, icon_size))
	return icon_out

func _get_item_button_background(icon_size_letter: String) -> Texture2D:
	var item_rarity = ItemProperties.get_rarity_num(_item_id)
	
	var background_out = AtlasTexture.new()
	var icon_size: int
	if icon_size_letter == "S":
		background_out.set_atlas(_tier_background_s)
		icon_size = ICON_SIZE_S
	else:
		return null
	
	background_out.set_region(Rect2(item_rarity * icon_size, 0, icon_size, icon_size))
	return background_out


func _on_mouse_entered():
	EventBus.emit_item_button_mouse_entered(_item_id)


func _on_mouse_exited():
	EventBus.emit_item_button_mouse_exited()


func _on_item_charges_changed(item: Item):
	var charges_text: String = item.get_charges_text()
	_charges_label.set_text(charges_text)
