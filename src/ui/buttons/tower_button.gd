class_name TowerButton
extends Button

var _tower_id: int = 1
var _tooltip_is_enabled: bool = true

@export var _disabled_lock: TextureRect
@export var _tier_icon: TextureRect
@export var _freshness_timer: Timer
@export var _freshness_indicator: FreshnessIndicator
@export var _rarity_background: RarityBackground
@export var _counter_label: Label

@export var _tooltip_location: ButtonTooltip.Location
@export var _show_freshness: bool = true


#########################
###     Built-in      ###
#########################

func _ready():
	set_locked(false)

	if _show_freshness:
		_freshness_timer.start()
		
		if !visible:
			_freshness_timer.pause()
		
		_freshness_indicator.show()
		
		var game_mode_is_build: bool = Globals.get_game_mode() == GameMode.enm.BUILD
		if game_mode_is_build:
			_freshness_indicator.hide()


#########################
###       Public      ###
#########################

func set_tooltip_is_enabled(value: bool):
	_tooltip_is_enabled = value


func get_tower_id() -> int:
	return _tower_id


# NOTE: must be called after button is added to parent
func set_tower_id(tower_id: int):
	_tower_id = tower_id

	var rarity: Rarity.enm = TowerProperties.get_rarity(tower_id)
	_rarity_background.set_rarity(rarity)
	
	var tower_icon: Texture2D = TowerProperties.get_icon(tower_id)
	set_button_icon(tower_icon)
	
	var tier_icon: Texture2D = UnitIcons.get_tower_tier_icon(tower_id)
	_tier_icon.texture = tier_icon


func set_tier_visible(value: bool):
	_tier_icon.visible = value


func set_locked(value: bool):
	_disabled_lock.visible = value
	disabled = value


func set_count(count: int):
	_counter_label.text = str(count)
	_counter_label.visible = count > 1


#########################
###     Callbacks     ###
#########################

func _on_mouse_entered():
	if !_tooltip_is_enabled:
		return
	
	var local_player: Player = PlayerManager.get_local_player()
	var tooltip: String = RichTexts.get_tower_text(_tower_id, local_player)
	ButtonTooltip.show_tooltip(self, tooltip, _tooltip_location)
	
	_freshness_indicator.hide()


#########################
###       Static      ###
#########################

static func make():
	var tower_button: TowerButton = Preloads.tower_button_scene.instantiate()
	return tower_button


# Pause freshness timer while button is not visible
func _on_visibility_changed():
	if _freshness_timer.is_stopped():
		return
	
	_freshness_timer.set_paused(!visible)


func _on_freshness_timer_timeout():
	_freshness_indicator.hide()
