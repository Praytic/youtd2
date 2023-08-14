class_name UnitButton
extends Button


@onready var _rarity_container: PanelContainer = %RarityContainer
@onready var _counter_label: Label = %CounterLabel


var _count: int: set = set_count
var _rarity: Rarity.enm: get = get_rarity, set = set_rarity


func _ready():
	set_count(1)


func get_rarity() -> Rarity.enm:
	return _rarity

func set_rarity(value: Rarity.enm):
	_rarity = value
	match _rarity:
		Rarity.enm.COMMON:
			_rarity_container.theme_type_variation = "CommonRarityPanelContainer"
		Rarity.enm.UNCOMMON:
			_rarity_container.theme_type_variation = "UncommonRarityPanelContainer"
		Rarity.enm.RARE:
			_rarity_container.theme_type_variation = "RareRarityPanelContainer"
		Rarity.enm.UNIQUE:
			_rarity_container.theme_type_variation = "UniqueRarityPanelContainer"
		_:
			_rarity_container.theme_type_variation = ""

func set_icon(value: Texture2D):
	icon = value

func set_count(value: int):
	_count = value
	_counter_label.text = str(value)
	if _count > 1:
		_counter_label.show()
	else:
		_counter_label.hide()


func get_count() -> int:
	return _count
