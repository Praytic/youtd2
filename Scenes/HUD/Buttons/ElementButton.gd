extends Button


signal trying_to_research()
signal research()
signal researched()


const PRESS_DURATION_TO_START_RESEARCH = 0.5
const PRESS_DURATION_TO_COMPLETE_RESEARCH = 2


@export var element: Element.enm
@export var texture_progress_bar: TextureProgressBar
@export var counter_label: Label
@export var research_element_progress_bar: TextureProgressBar


var research_in_progress: int = 0
var button_down_timer: Timer = Timer.new()
var research_timer: Timer = Timer.new()


func _ready():
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)
	ElementLevel.changed.connect(_on_element_level_changed)
	button_down.connect(_on_button_down)
	button_up.connect(_on_button_up)
	button_down_timer.timeout.connect(_on_button_down_timeout)
	research_timer.timeout.connect(_on_research_timer_timeout)
	
	_on_mouse_exited()
	_on_element_level_changed()


func _process(delta):
	if not research_timer.is_stopped():
		var new_research_progress = research_timer.time_left * research_element_progress_bar.max_value / PRESS_DURATION_TO_COMPLETE_RESEARCH
		research_element_progress_bar.value = new_research_progress


func set_towers_counter(value: int):
	if value == 0:
		counter_label.text = ""
	else:
		counter_label.text = str(value)


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
	texture_progress_bar.value = curent_element_level


func _on_mouse_entered():
	texture_progress_bar.show()
	counter_label.show()
	EventBus.research_button_mouse_entered.emit(element)


func _on_mouse_exited():
	texture_progress_bar.hide()
	counter_label.hide()
	EventBus.research_button_mouse_exited.emit(element)


func _on_button_down():
	button_down_timer.start(PRESS_DURATION_TO_START_RESEARCH)


func _on_button_up():
	research_timer.stop()


func _on_button_down_timeout(show_error: bool = true):
	if button_pressed:
		if _is_able_to_research():
			research_element_progress_bar.show()
			research_timer.start(PRESS_DURATION_TO_COMPLETE_RESEARCH)
		elif show_error:
			Messages.add_error("Can't research this element. Not enough tomes.")


func _on_research_timer_timeout():
	# Second check that after research_timer player still has
	# tomes to research the element.
	if _is_able_to_research():
		var cost: int = ElementLevel.get_research_cost(element)
		KnowledgeTomesManager.spend(cost)
		ElementLevel.increment(element)
	
		# If player still holds button down on the element,
		# we allow him to do next research without any additional
		# button_down event. But don't show error message in that case.
		_on_button_down_timeout(false)
	# If player doesn't have enough tomes after research_timer,
	# show same error message as after button_down_timer.
	else:
		Messages.add_error("Can't research this element. Not enough tomes.")
