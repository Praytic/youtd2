class_name TowerButton
extends UnitButton


@export var _disabled_lock: TextureRect
@export var _tier_icon: TextureRect

@export var _tower_id: int: get = get_tower_id, set = set_tower_id


var _player: Player = null


#########################
###     Built-in      ###
#########################

func _ready():
	super._ready()
	set_rarity(TowerProperties.get_rarity(_tower_id))
	set_icon(UnitIcons.get_tower_icon(_tower_id))
	if PregameSettings.get_game_mode() == GameMode.enm.TOTALLY_RANDOM:
		set_tier_icon(_tower_id)
	else:
		_tier_icon.hide()
	
	# TODO: Just for testing
	if Config.random_button_counters() && randi()%3 == 0:
		set_count(randi_range(2, 20))
	
	mouse_entered.connect(_on_mouse_entered)
	pressed.connect(_on_pressed)

#	NOTE: start in locked state
	disabled = true
	_disabled_lock.show()


#########################
###       Public      ###
#########################

# NOTE: need to couple tower button with player to implement
# the feature of tooltips displaying red requirement
# numbers.
func set_player(player: Player):
	_player = player


func get_tower_id() -> int:
	return _tower_id


func set_tower_id(value: int):
	_tower_id = value


func set_tier_icon(tower_id: int):
	_tier_icon.texture = UnitIcons.get_tower_tier_icon(tower_id)


# NOTE: this function uses saved reference to player because
# requirements code needs to check all player resources
func unlock():
	_disabled_lock.hide()
	disabled = false


#########################
###     Callbacks     ###
#########################

func _on_mouse_entered():
	var tooltip: String = RichTexts.get_tower_text(_tower_id, _player)
	ButtonTooltip.show_tooltip(self, tooltip)


func _on_pressed():
	var enough_resources: bool = BuildTower.enough_resources_for_tower(_tower_id)

	if enough_resources:
		BuildTower.start(_tower_id)
	else:
		BuildTower.add_error_about_resources(_tower_id)


#########################
###       Static      ###
#########################

static func make(tower_id: int):
	var tower_button = Globals.tower_button_scene.instantiate()
	tower_button.set_tower_id(tower_id)
	return tower_button

