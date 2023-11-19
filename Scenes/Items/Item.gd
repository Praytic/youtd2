class_name Item
extends Node


# Item represents item when it's attached to a tower.
# Implements application of item effects on tower.

signal charges_changed()
signal consumed()


enum CsvProperty {
	ID,
	NAME,
	OLD_NAME,
	SCRIPT_NAME,
	TYPE,
	AUTHOR,
	RARITY,
	COST,
	DESCRIPTION,
	REQUIRED_WAVE_LEVEL,
	ICON_ATLAS_FAMILY,
	ICON_ATLAS_NUM,
}

const PRINT_SCRIPT_NOT_FOUND_ERROR: bool = false
const FAILLBACK_SCRIPT: String = "res://Scenes/Items/Instances/Item105.gd"

# NOTE: this is used in Creep.gd to determine which items
# will not drop.
static var disabled_item_list: Array[int] = [140, 198, 254]

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
var _uses_charges: bool = false
var _is_oil_and_was_applied_already: bool = false

# Call add_modification() on _modifier in subclass to add item effects
var _modifier: Modifier = Modifier.new()
var _autocast: Autocast = null
var _aura_carrier_buff: BuffType = BuffType.new("", 0, 0, true, self)
var _triggers_buff_type: BuffType = BuffType.new("", 0, 0, true, self)
var _triggers_buff: Buff = null
var _inherited_periodic_timers: Dictionary = {}


@onready var _hud: Control = get_tree().get_root().get_node("GameScene").get_node("UI").get_node("HUD")
@onready var _owner: Player = get_tree().get_root().get_node("GameScene/Player")


#########################
### Code starts here  ###
#########################


func _init(id: int):
#	NOTE: fix "unused variable" warning
	_is_oil_and_was_applied_already = _is_oil_and_was_applied_already

	_id = id
	load_modifier(_modifier)
	item_init()

	load_triggers(_triggers_buff_type)


# NOTE: need to call on_create() because some item scripts
# access the scene tree inside on_create()
func _ready():
	on_create()


# Creates item on the ground. Item is stored inside an
# ItemDrop object.
# NOTE: Item.create() in JASS
static func create(_player: Player, item_id: int, position: Vector2) -> Item:
	var item: Item = Item.make(item_id)
	Item._create_item_drop(item, position)
	
	return item


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


static func _create_item_drop(item: Item, position: Vector2) -> ItemDrop:
	var id: int = item.get_id()
	var rarity: Rarity.enm = ItemProperties.get_rarity(id)
	var rarity_string: String = Rarity.convert_to_string(rarity)
	var item_drop_scene_path: String
	if ItemProperties.get_is_oil(id):
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


# NOTE: SetItemVisible() in JASS
func set_visible(visible: bool):
	_visible = visible

	var item_drop: ItemDrop = get_parent() as ItemDrop
	if item_drop != null:
		item_drop.visible = visible


func set_autocast(autocast: Autocast):
	autocast._is_item_autocast = true
	_autocast = autocast
	add_child(autocast)


func get_autocast() -> Autocast:
	return _autocast


func add_aura(aura: AuraType):
	_aura_carrier_buff.add_aura(aura)


# Sets the charge count that is displayed on the item icon.
# NOTE: item.setCharges() in JASS
func set_charges(new_count: int):
	var old_count: int = _charge_count
	CombatLog.log_item_charge(self, old_count, new_count)

	_charge_count = new_count
	_uses_charges = true
	charges_changed.emit()


# NOTE: item.getCharges() in JASS
func get_charges() -> int:
	return _charge_count


# Returns whether this item uses charges. Used to determine
# whether to draw charges label.
func uses_charges() -> bool:
	return _uses_charges


# NOTE: override this in subclass to attach trigger handlers
# to triggers buff passed in the argument.
func load_triggers(_triggers: BuffType):
	pass


# Override in subclass to add define the modifier that will
# be added to carrier of the item
func load_modifier(_modifier_arg: Modifier):
	pass


func get_specials_tooltip_text() -> String:
	var text: String = _modifier.get_tooltip_text()

	return text


# Override in subclass to define the description of item
# abilities. String can contain rich text format(BBCode).
# NOTE: by default all numbers in this text will be colored
# but you can also define your own custom color tags.
func get_ability_description() -> String:
	return ""


# Override in subclass to initialize subclass item
func item_init():
	pass


# Consume item. Only applicable to items of consumable type.
func consume():
	on_consume()

	print_verbose("Item was consumed. Removing item from game.")
	
#	NOTE: workaround for bug where consuming an item causes
#	no mouse exited signal to be emitted. That causes the
#	tooltip to not disappear even though the item is gone.
	EventBus.item_button_mouse_exited.emit()

	consumed.emit()


# Override in subclass script to implement the effect that
# should happen when the item is consumed.
func on_consume():
	pass


# Override this in tower subclass to implement the "On Item
# Creation" trigger. This is the analog of "onCreate"
# function from original API.
func on_create():
	pass


# Override this in tower subclass to implement the "On Item
# Pickup" trigger. Called after item is picked up by tower.
func on_pickup():
	pass


# Override this in tower subclass to implement the "On Item
# Drop" trigger. Called before item is dropped by tower.
func on_drop():
	pass


# Override in subclass to define an extra multiboard for the
# carrier tower.
func on_tower_details() -> MultiboardValues:
	return null


# NOTE: item.getItemType() in JASS
# In JASS engine, getItemType() returns the id.
# Note that in youtd2 engine, "item type" refers to the
# ItemType enm, not the item id.
func get_id() -> int:
	return _id


# NOTE: item.getCarrier() in JASS
func get_carrier() -> Tower:
	return _carrier


# NOTE: for now just returning the one single player
# instance since multiplayer isn't implemented.
# NOTE: item.getOwner() in JASS
# Node.get_owner() is a built-in godot f-n
func get_player() -> Player:
	return _owner


func get_rarity() -> Rarity.enm:
	var rarity: Rarity.enm = ItemProperties.get_rarity(_id)

	return rarity


func get_item_type() -> ItemType.enm:
	return ItemProperties.get_type(_id)


func get_required_wave_level() -> int:
	return ItemProperties.get_required_wave_level(_id)


func is_consumable() -> bool:
	return ItemProperties.is_consumable(_id)


# Picks up an item from the ground and moves it to a tower.
# Item must be in "dropped" state before this f-n is called.
# Returns true if item was picked up successfully.
# NOTE: item.pickup() in JASS
func pickup(tower: Tower) -> bool:
	var item_drop: ItemDrop = get_parent() as ItemDrop
	if item_drop == null:
		push_error("Called pickup() on item which is not in ItemDrop!")

		return false

	var is_oil: bool = ItemProperties.get_is_oil(get_id())
	var can_add: bool = tower.have_item_space() || is_oil

	if !can_add:
		return false

	item_drop.remove_child(self)
	item_drop.queue_free()

	var tower_container: ItemContainer = tower.get_item_container()
	var slot_index: int = tower_container.get_item_count()
	tower_container.add_item(self, slot_index)
	
	return true


# Drops item from tower inventory onto the ground. This f-n
# does nothing if item is currently not in tower inventory.
# NOTE: item.drop() in JASS
func drop():
	if _carrier == null:
		return

# 	NOTE: save drop_pos before removing because _carrier
# 	will not be available after removal
	var drop_pos: Vector2 = _carrier.get_visual_position()

	var carrier_container: ItemContainer = _carrier.get_item_container()
	carrier_container.remove_item(self)
	Item._create_item_drop(self, drop_pos)


# Item starts flying to the stash and will get added to
# stash once the animation finishes. Does nothing if item is
# not on the ground.
# NOTE: item.flyToStash() in JASS
func fly_to_stash(_mystery_float: float):
	var parent_item_drop: ItemDrop = get_parent() as ItemDrop
	var is_on_ground: bool = parent_item_drop != null
	
	if !is_on_ground:
		return

	var item_drop_screen_pos: Vector2 = parent_item_drop.get_screen_transform().get_origin()

	parent_item_drop.remove_child(self)
	parent_item_drop.queue_free()

	fly_to_stash_from_pos(item_drop_screen_pos)


# Same as fly_to_stash() but can be used on unparented item
func fly_to_stash_from_pos(screen_pos: Vector2):
	var flying_item: FlyingItem = FlyingItem.create(_id, screen_pos)
	flying_item.finished_flying.connect(_on_flying_item_finished_flying)
	flying_item.add_child(self)
	flying_item.visible = _visible
	_hud.add_child(flying_item)


# NOTE: this f-n only applies the effects. Use Item.pickup()
# or Tower.add_item() to fully add an item to a tower.
func _add_to_tower(tower: Tower):
	_carrier = tower

# 	NOTE: call on_pick() after setting carrier so that it's
# 	available inside on_pickup() implementations.
	on_pickup()

	_carrier.add_modifier(_modifier)

	if _autocast != null:
		_autocast.set_caster(_carrier)

	_triggers_buff_type._inherited_periodic_timers = _inherited_periodic_timers.duplicate()

	_triggers_buff = _triggers_buff_type.apply_to_unit_permanent(_carrier, _carrier, 0)
	_aura_carrier_buff.apply_to_unit_permanent(_carrier, _carrier, 0)


# NOTE: this f-n only removes the effects. Use Item.drop()
# or Tower.remove_item() to fully remove an item from a
# tower.
# 
# NOTE: buffs applied by Item will be automatically removed
# via Buff._on_buff_type_tree_exited(). This includes
# _triggers_buff_type and _aura_carrier_buff.
# 
# NOTE: the code for _inherited_periodic_timers is a hack to
# preserve item cooldowns when item is removed from tower.
# It works like this:
# 1. When item is first added to a tower, it creates a
#    "triggers" buff which creates timers for periodic
#    events.
# 2. When that item is removed from the tower, triggers buff
#    is deleted but the timers are saved in the item
#    instance.
# 3. When the item is added back to a tower, the new
#    triggers buff "inherits" timers from previous buff.
# 4. Repeat.
# 
# In other cases, buffs do not inherit timers.
func _remove_from_tower():
	if _carrier == null:
		return

	on_drop()

	_carrier.remove_modifier(_modifier)

	if _autocast != null:
		_autocast.set_caster(null)

	_inherited_periodic_timers = _triggers_buff._inherited_periodic_timers.duplicate()
	for timer in _inherited_periodic_timers.values():
		timer.reparent(self)
		timer.set_paused(true)

	_carrier = null


func _on_flying_item_finished_flying():
	var parent: Node = get_parent()
	parent.remove_child(self)
	parent.queue_free()
	var item_stash_container: ItemContainer = ItemStash.get_item_container()
	item_stash_container.add_item(self)
