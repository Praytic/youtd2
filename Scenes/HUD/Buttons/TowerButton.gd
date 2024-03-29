class_name TowerButton
extends UnitButton


@export var _disabled_lock: TextureRect
@export var _tier_icon: TextureRect

@export var _tower_id: int: get = get_tower_id, set = set_tower_id


#########################
###     Built-in      ###
#########################

func _ready():
	super._ready()
	set_rarity(TowerProperties.get_rarity(_tower_id))
	set_icon(UnitIcons.get_tower_icon(_tower_id))
	if Globals.get_game_mode() == GameMode.enm.TOTALLY_RANDOM:
		set_tier_icon(_tower_id)
	else:
		_tier_icon.hide()
	
	mouse_entered.connect(_on_mouse_entered)
	pressed.connect(_on_pressed)

#	NOTE: start in locked state
	disabled = true
	_disabled_lock.show()


#########################
###       Public      ###
#########################

func get_tower_id() -> int:
	return _tower_id


func set_tower_id(value: int):
	_tower_id = value


func set_tier_icon(tower_id: int):
	_tier_icon.texture = UnitIcons.get_tower_tier_icon(tower_id)


func unlock():
	_disabled_lock.hide()
	disabled = false


#########################
###     Callbacks     ###
#########################

func _on_mouse_entered():
	var local_player: Player = PlayerManager.get_local_player()
	var tooltip: String = RichTexts.get_tower_text(_tower_id, local_player)
	ButtonTooltip.show_tooltip(self, tooltip)


func _on_pressed():
	EventBus.player_requested_to_build_tower.emit(_tower_id)


#########################
###       Static      ###
#########################

static func make(tower_id: int):
	var tower_button = Preloads.tower_button_scene.instantiate()
	tower_button.set_tower_id(tower_id)
	return tower_button

