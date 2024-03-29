extends Button


signal trying_to_research()
signal research()
signal researched()


const PRESS_DURATION_TO_START_RESEARCH = 0.5
const PRESS_DURATION_TO_COMPLETE_RESEARCH = 1


@export var element: Element.enm
@export var _texture_progress_bar: TextureProgressBar
@export var _counter_label: Label
@export var _research_element_progress_bar: TextureProgressBar
@export var _button_down_timer: Timer
@export var _research_timer: Timer


#########################
###     Built-in      ###
#########################

func _ready():
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)
	button_down.connect(_on_button_down)
	button_up.connect(_on_button_up)
	_button_down_timer.timeout.connect(_on_button_down_timeout)
	_research_timer.timeout.connect(_on_research_timer_timeout)
	
	_button_down_timer.wait_time = PRESS_DURATION_TO_START_RESEARCH
	_research_timer.wait_time = PRESS_DURATION_TO_COMPLETE_RESEARCH
	
	_on_mouse_exited()


func _process(_delta: float):
	if not _research_timer.is_stopped():
		var new_research_progress = (PRESS_DURATION_TO_COMPLETE_RESEARCH - _research_timer.time_left) * _research_element_progress_bar.max_value / PRESS_DURATION_TO_COMPLETE_RESEARCH
		_research_element_progress_bar.value = new_research_progress

#########################
###       Public      ###
#########################

func set_towers_counter(value: int):
	if value == 0:
		_counter_label.text = ""
	else:
		_counter_label.text = str(value)


func set_element_level(level: int):
	_texture_progress_bar.value = level


#########################
###      Private      ###
#########################

func _is_able_to_research():
	var local_player: Player = PlayerManager.get_local_player()
	var can_afford: bool = local_player.can_afford_research(element)
	var current_level: int = local_player.get_element_level(element)
	var reached_max_level: bool = current_level == Constants.MAX_ELEMENT_LEVEL
	var button_is_enabled: bool = can_afford && !reached_max_level

	return button_is_enabled


func _make_custom_tooltip(for_text: String) -> Object:
	var label = RichTextLabel.new()
	label.append_text(for_text)
	return label


#########################
###     Callbacks     ###
#########################

func _on_mouse_entered():
	_texture_progress_bar.show()
	_counter_label.show()

	var local_player: Player = PlayerManager.get_local_player()
	var tooltip: String = RichTexts.get_research_text(element, local_player)
	ButtonTooltip.show_tooltip(self, tooltip)


func _on_mouse_exited():
	_texture_progress_bar.hide()
	_counter_label.hide()


func _on_button_down():
	_button_down_timer.start()


func _on_button_up():
	_button_down_timer.stop()
	_research_timer.stop()
	_research_element_progress_bar.hide()
	_research_element_progress_bar.value = 0


func _on_button_down_timeout():
	_button_down_timer.stop()
	if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		if _is_able_to_research():
			_research_element_progress_bar.show()
			_research_timer.start()
		else:
			var local_player: Player = PlayerManager.get_local_player()
			Messages.add_error(local_player, "Can't research this element. Not enough tomes.")


func _on_research_timer_timeout():
	_research_timer.stop()
	_research_element_progress_bar.hide()
	_research_element_progress_bar.value = 0

	EventBus.player_requested_to_research_element.emit(element)
