class_name Item
extends Node


# Item represents item when it's attached to a tower.
# Implements application of item effects on tower.

signal charges_changed()


enum CsvProperty {
	ID = 0,
	NAME = 1,
	SCRIPT_NAME = 2,
	AUTHOR = 3,
	RARITY = 4,
	COST = 5,
	DESCRIPTION = 6,
	REQUIRED_WAVE_LEVEL = 7,
	ICON_ATLAS_FAMILY = 8,
	ICON_ATLAS_NUM = 9,
	IS_OIL = 10,
}

const PRINT_SCRIPT_NOT_FOUND_ERROR: bool = false
const FAILLBACK_SCRIPT: String = "res://Scenes/Items/Instances/Item105.gd"

# NOTE: this is used in Creep.gd to determine which items
# will not drop.
const disabled_item_list: Array[int] = [50, 140, 162, 198, 201, 250, 254, 262]

static var _item_drop_scene_map: Dictionary = {
	"res://Scenes/Items/CommonItem.tscn": preload("res://Scenes/Items/CommonItem.tscn"),
	"res://Scenes/Items/UncommonItem.tscn": preload("res://Scenes/Items/UncommonItem.tscn"),
	"res://Scenes/Items/RareItem.tscn": preload("res://Scenes/Items/RareItem.tscn"),
	"res://Scenes/Items/UniqueItem.tscn": preload("res://Scenes/Items/UniqueItem.tscn"),
	"res://Scenes/Items/RedOil.tscn": preload("res://Scenes/Items/RedOil.tscn"),
}


var user_int: int = 0
var user_int2: int = 0
var user_int3: int = 0
var user_real: float = 0.0
var user_real2: float = 0.0
var user_real3: float = 0.0

var _id: int = 0
var _carrier: Tower = null
var _charge_count: int = -1
var _visible: bool = true

# Call add_modification() on _modifier in subclass to add item effects
var _modifier: Modifier = Modifier.new()
var _buff_type_list: Array[BuffType] = []
var _applied_buff_list: Array[Buff] = []
var _autocast: Autocast = null
var _aura_carrier_buff: BuffType = BuffType.new("", 0, 0, true, self)


@onready var _hud: Control = get_tree().get_root().get_node("GameScene").get_node("UI").get_node("HUD")
@onready var _owner: Player = get_tree().get_root().get_node("GameScene/Player")


#########################
### Code starts here  ###
#########################


# Creates item on the ground. Item is stored inside an
# ItemDrop object.
# NOTE: Item.create() in JASS
static func create(_player: Player, item_id: int, position: Vector2) -> Item:
	return create_without_player(item_id, position)


static func create_without_player(item_type: int, position: Vector2) -> Item:
	var item: Item = Item.make(item_type)
	Item._create_item_drop(item, position)

	return item


static func _create_item_drop(item: Item, position: Vector2) -> ItemDrop:
	var item_type: int = item.get_id()
	var rarity: Rarity.enm = ItemProperties.get_rarity_num(item_type)
	var rarity_string: String = Rarity.convert_to_string(rarity)
	var item_drop_scene_path: String
	if ItemProperties.get_is_oil(item_type):
		item_drop_scene_path = "res://Scenes/Items/RedOil.tscn"
	else:
		item_drop_scene_path = "res://Scenes/Items/%sItem.tscn" % rarity_string.capitalize()
	var item_drop_scene = _item_drop_scene_map[item_drop_scene_path]
	var item_drop: ItemDrop = item_drop_scene.instantiate()
	item_drop.position = position
	item_drop.visible = item._visible

	item_drop.set_item(item)
	item_drop.add_child(item)

	Utils.add_object_to_world(item_drop)
	
	return item_drop


static func make(id: int) -> Item:
	var item_script_path: String = get_item_script_path(id)
	var script_exists: bool = ResourceLoader.exists(item_script_path)
	
	if !script_exists:
		if PRINT_SCRIPT_NOT_FOUND_ERROR:
			print_debug("No item script found for id:", id, ". Tried at path:", item_script_path)

		item_script_path = FAILLBACK_SCRIPT

	var item_script = load(item_script_path)

	if item_script == null:
		return null

	var item: Item = item_script.new(id)

	return item


static func get_item_script_path(item_id: int):
	var path: String = "res://Scenes/Items/Instances/Item%d.gd" % item_id

	return path


# NOTE: SetItemVisible() in JASS
static func set_item_visible(item: Item, visible: bool):
	item._visible = visible


func _init(id: int):
	_id = id
	load_modifier(_modifier)
	item_init()

	var triggers_buff_type: BuffType = BuffType.new("", 0, 0, true, self)
	load_triggers(triggers_buff_type)
	_buff_type_list.append(triggers_buff_type)

	_buff_type_list.append(_aura_carrier_buff)


# NOTE: need to call on_create() because some item scripts
# access the scene tree inside on_create()
func _ready():
	on_create()


# Drops item from tower inventory onto the ground. This f-n
# does nothing if item is currently not in tower inventory.
# NOTE: item.drop() in JASS
func drop():
	if _carrier == null:
		return

	var drop_pos: Vector2 = _carrier.get_visual_position()

	on_drop()

	_carrier._remove_item(self)
	_carrier.remove_modifier(_modifier)

	if _autocast != null:
		_autocast.set_caster(null)

	for buff in _applied_buff_list:
		buff.remove_buff()

	_applied_buff_list.clear()

	_carrier.remove_child(self)
	_carrier = null

	Item._create_item_drop(self, drop_pos)


# NOTE: item.pickup() in JASS
func pickup(tower: Tower) -> bool:
	if tower.have_item_space():
		_pickup_internal(tower)
		
		return true
	else:
		return false


# NOTE: this f-n adds item to tower even if tower doesn't
# have space. Used for adding oils to tower.
func _pickup_internal(tower: Tower):
	var parent: Node = get_parent()
	if parent != null:
		parent.remove_child(self)

	var parent_item_drop: ItemDrop = parent as ItemDrop
	if parent_item_drop != null:
		parent_item_drop.queue_free()

	_carrier = tower

# 	NOTE: call on_pick() after setting carrier so that it's
# 	available inside on_pickup() implementations.
	on_pickip()

	_carrier.add_modifier(_modifier)

	if _autocast != null:
		_autocast.set_caster(_carrier)

	for buff_type in _buff_type_list:
		var buff: Buff = buff_type.apply_to_unit_permanent(_carrier, _carrier, 0)
		_applied_buff_list.append(buff)

	tower._add_item(self)
	tower.add_child(self)


# Item starts flying to the stash and will get added to
# stash once the animation finishes. Does nothing if item is
# not on the ground.
# NOTE: item.flyToStash() in JASS
func fly_to_stash(_mystery_float: float):
	var parent_item_drop: ItemDrop = get_parent() as ItemDrop
	var is_on_ground: bool = parent_item_drop != null
	
	if !is_on_ground:
		return	

	var start_pos: Vector2 = parent_item_drop.get_screen_transform().get_origin()
	parent_item_drop.remove_child(self)
	parent_item_drop.queue_free()

	var flying_item: FlyingItem = FlyingItem.create(_id, start_pos)
	flying_item.finished_flying.connect(_on_flying_item_finished_flying)
	flying_item.add_child(self)
	flying_item.visible = _visible
	_hud.add_child(flying_item)


func _on_flying_item_finished_flying():
	move_to_stash()


# Moves item to stash immediately, without flying animation.
func move_to_stash():
	var flying_item: Node = get_parent()
	flying_item.remove_child(self)
	flying_item.queue_free()

	EventBus.item_drop_picked_up.emit(self)


func set_autocast(autocast: Autocast):
	autocast._is_item_autocast = true
	_autocast = autocast
	add_child(autocast)


func get_autocast() -> Autocast:
	return _autocast


# Add buffs that will be applied to carrier while it is
# carrying this item. This must be called in item_init().
func add_buff(buff: BuffType):
	_buff_type_list.append(buff)


func add_aura(aura: AuraType):
	_aura_carrier_buff.add_aura(aura)


# Sets the charge count that is displayed on the item icon.
# NOTE: item.setCharges() in JASS
func set_charges(new_count: int):
	_charge_count = new_count
	charges_changed.emit()


func get_charges_text() -> String:
	if _charge_count != -1:
		return str(_charge_count)
	else:
		return ""

# NOTE: item.getCharges() in JASS
func get_charges() -> int:
	return _charge_count

# NOTE: override this in subclass to attach trigger handlers
# to triggers buff passed in the argument.
func load_triggers(_triggers_buff_type: BuffType):
	pass


# Override in subclass to add define the modifier that will
# be added to carrier of the item
func load_modifier(_modifier_arg: Modifier):
	pass


func get_specials_tooltip_text() -> String:
	var text: String = _modifier.get_tooltip_text()

	return text


# Override in subclass to define item's extra tooltip text.
# This should contain description of special abilities.
# String can contain rich text format(BBCode).
# NOTE: by default all numbers in this text will be colored
# but you can also define your own custom color tags.
func get_extra_tooltip_text() -> String:
	return ""


# Override in subclass to initialize subclass item
func item_init():
	pass


# Override this in tower subclass to implement the "On Item
# Creation" trigger. This is the analog of "onCreate"
# function from original API.
func on_create():
	pass


# Override this in tower subclass to implement the "On Item
# Pickup" trigger. Called after item is picked up by tower.
func on_pickip():
	pass


# Override this in tower subclass to implement the "On Item
# Drop" trigger. Called before item is dropped by tower.
func on_drop():
	pass


# Override in subclass to define an extra multiboard for the
# carrier tower.
func on_tower_details() -> MultiboardValues:
	return null


#########################
### Setters / Getters ###
#########################

func get_id() -> int:
	return _id

# NOTE: item.getCarrier() in JASS
func get_carrier() -> Tower:
	return _carrier

# NOTE: for now just returning the one single player
# instance since multiplayer isn't implemented.
# NOTE: item.getOwner() in JASS
func getOwner() -> Player:
	return _owner

# NOTE: item.getItemType() in JASS
func get_item_type() -> int:
	return get_id()
