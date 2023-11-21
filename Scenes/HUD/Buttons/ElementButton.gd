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


func _ready():
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)
	ElementLevel.changed.connect(_on_element_level_changed)
	button_down.connect(_on_button_down)
	button_up.connect(_on_button_up)
	_button_down_timer.timeout.connect(_on_button_down_timeout)
	_research_timer.timeout.connect(_on_research_timer_timeout)
	
	_button_down_timer.wait_time = PRESS_DURATION_TO_START_RESEARCH
	_research_timer.wait_time = PRESS_DURATION_TO_COMPLETE_RESEARCH
	
	_on_mouse_exited()
	_on_element_level_changed()


func _process(_delta: float):
	if not _research_timer.is_stopped():
		var new_research_progress = (PRESS_DURATION_TO_COMPLETE_RESEARCH - _research_timer.time_left) * _research_element_progress_bar.max_value / PRESS_DURATION_TO_COMPLETE_RESEARCH
		_research_element_progress_bar.value = new_research_progress


func set_towers_counter(value: int):
	if value == 0:
		_counter_label.text = ""
	else:
		_counter_label.text = str(value)


func _is_able_to_research():
	var can_afford: bool = ElementLevel.can_afford_research(element)
	var current_level: int = ElementLevel.get_current(element)
	var reached_max_level: bool = current_level == ElementLevel.get_max()
	var button_is_enabled: bool = can_afford && !reached_max_level

	return button_is_enabled


func _make_custom_tooltip(for_text: String) -> Object:
	var label = RichTextLabel.new()
	label.append_text(for_text)
	return label


func _on_element_level_changed():
	var curent_element_level = ElementLevel.get_current(element)
	_texture_progress_bar.value = curent_element_level


func _on_mouse_entered():
	_texture_progress_bar.show()
	_counter_label.show()

	var tooltip: String = RichTexts.get_research_text(element)
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
			Messages.add_error("Can't research this element. Not enough tomes.")


func _on_research_timer_timeout():
	_research_timer.stop()
	# Second check that after research_timer player still has
	# tomes to research the element.
	if _is_able_to_research():
		var cost: int = ElementLevel.get_research_cost(element)
		KnowledgeTomesManager.spend(cost)
		ElementLevel.increment(element)
		
		if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
			_on_button_down_timeout()
		else:
			_research_element_progress_bar.hide()
			_research_element_progress_bar.value = 0
	# If player doesn't have enough tomes after research_timer,
	# show same error message as after button_down_timer.
	else:
		Messages.add_error("Can't research this element. Not enough tomes.")
