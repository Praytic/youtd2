class_name TutorialMenu extends PanelContainer


# Tutorial menu shows a sequence of tutorials loaded from a
# CSV file. Some tutorial sections highlight UI elements.
# Tutorial is opened after the pregame settings if the
# player decides that they want it.


signal finished()

class Section:
	var title: String
	var highlight_target: String
	var text: String


enum TutorialColumn {
	TITLE = 0,
	HIGHLIGHT_TARGET,
	TEXT,
}

const TUTORIAL_BUILD_PATH: String = "res://Data/tutorial_build.csv"
const HIGHLIGHT_PERIOD: float = 0.5

var _section_list: Array[Section]
var _current_section: int
var _active_tween: Tween = null
var _current_highlight_target: Control = null


@export var _text_label: RichTextLabel
@export var _back_button: Button
@export var _next_button: Button
@onready var _bottom_menu_bar: Control = get_tree().get_root().get_node("GameScene/UI/HUD/BottomMenuBar")
@onready var _research_button: Control = _bottom_menu_bar.get_research_button()
@onready var _elements_container: Control = _bottom_menu_bar.get_elements_container()
@onready var _tomes_status: Control = _bottom_menu_bar.get_tomes_status()
@onready var _gold_status: Control = _bottom_menu_bar.get_gold_status()

@onready var _highlight_map = {
	"research_button": _research_button,
	"element_buttons": _elements_container,
	"tomes_status": _tomes_status,
	"gold_status": _gold_status,
}

func _ready():
	var csv: Array[PackedStringArray] = Utils.load_csv(TUTORIAL_BUILD_PATH)
	
	_section_list = []
	
	for csv_line in csv:
		var section: Section = Section.new()
		section.title = csv_line[TutorialColumn.TITLE]
		section.highlight_target = csv_line[TutorialColumn.HIGHLIGHT_TARGET]
		section.text = csv_line[TutorialColumn.TEXT]

		_section_list.append(section)
	
	_current_section = 0
	_change_section(0)


func _set_highlight_target(target: Control):
#	Stop highlighting previous target
	if _current_highlight_target != null:
		_current_highlight_target.modulate = Color.WHITE
		_active_tween.kill()

	_current_highlight_target = target

# 	Start highlighting new target
	if target != null:
		_active_tween = create_tween()
		_active_tween.tween_property(target, "modulate", Color.YELLOW.darkened(0.2), HIGHLIGHT_PERIOD)
		_active_tween.tween_property(target, "modulate", Color.WHITE, HIGHLIGHT_PERIOD)
		_active_tween.set_loops()


func _change_section(change_amount: int):
	_current_section += change_amount
	
	var section: Section = _section_list[_current_section]
	
	var text: String = ""
	text += "[color=GOLD]%s[/color]\n" % section.title
	text += " \n"
	text += section.text

	_text_label.clear()
	_text_label.append_text(text)
	
	var can_go_back: bool = _current_section > 0
	_back_button.set_disabled(!can_go_back)
	
	var can_go_forward: bool = _current_section < _section_list.size() - 1
	_next_button.set_disabled(!can_go_forward)

	var highlight_target_string: String = section.highlight_target
	var highlight_target: Control = _highlight_map.get(highlight_target_string, null)
	_set_highlight_target(highlight_target)


func _on_close_button_pressed():
	finished.emit()


func _on_next_button_pressed():
	_change_section(1)


func _on_back_button_pressed():
	_change_section(-1)
