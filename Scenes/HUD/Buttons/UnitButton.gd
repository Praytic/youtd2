class_name UnitButton
extends Button


@onready var _disabled_lock: TextureRect = $%LockTexture
@onready var _rarity_container: TextureRect = $%RarityContainer


var _rarity: String: get = get_rarity, set = set_rarity


func _draw():
	if disabled:
		_disabled_lock.show()
	else:
		_disabled_lock.hide()


func get_rarity() -> String:
	return _rarity

func set_rarity(value: String):
	_rarity = value
	match Rarity.convert_from_string(value):
		Rarity.enm.COMMON:
			_rarity_container.theme_type_variation = "CommonRarityPanelContainer"
		Rarity.enm.UNCOMMON:
			_rarity_container.theme_type_variation = "UncommonRarityPanelContainer"
		Rarity.enm.RARE:
			_rarity_container.theme_type_variation = "RareRarityPanelContainer"
		Rarity.enm.UNIQUE:
			_rarity_container.theme_type_variation = "UniqueRarityPanelContainer"

func set_icon(value: Texture2D):
	icon = value
