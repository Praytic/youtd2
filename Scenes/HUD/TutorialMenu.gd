class_name TutorialMenu extends PanelContainer


# Tutorial menu shows a sequence of tutorials loaded from a
# CSV file. Some tutorial sections highlight UI elements.
# Tutorial is opened after the pregame settings if the
# player decides that they want it.

# NOTE: UI targets for highlighting are mapped using
# HighlightUI.register_target() in scenes which contain
# those targets.


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
const TUTORIAL_RANDOM_PATH: String = "res://Data/tutorial_random.csv"

var _section_list: Array[Section]
var _current_section: int


@export var _text_label: RichTextLabel
@export var _back_button: Button
@export var _next_button: Button


func _ready():
	EventBus.game_mode_was_chosen.connect(_on_game_mode_was_chosen)


func _on_game_mode_was_chosen():
	var tutorial_path: String
	if Globals.game_mode == GameMode.enm.BUILD:
		tutorial_path = TUTORIAL_BUILD_PATH
	else:
		tutorial_path = TUTORIAL_RANDOM_PATH

	var csv: Array[PackedStringArray] = Utils.load_csv(tutorial_path)
	
	_section_list = []
	
	for csv_line in csv:
		var section: Section = Section.new()
		section.title = csv_line[TutorialColumn.TITLE]
		section.highlight_target = csv_line[TutorialColumn.HIGHLIGHT_TARGET]
		section.text = csv_line[TutorialColumn.TEXT]

		_section_list.append(section)
	
	_current_section = 0
	_change_section(0)


func _change_section(change_amount: int):
	var prev_section: Section = _section_list[_current_section]

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

	var prev_highlight_target: String = prev_section.highlight_target
	if !prev_highlight_target.is_empty():
		HighlightUI.stop_highlight(prev_highlight_target)
	
	var new_highlight_target: String = section.highlight_target
	if !new_highlight_target.is_empty():
		HighlightUI.start_highlight(new_highlight_target)


func _on_close_button_pressed():
	finished.emit()

	var section: Section = _section_list[_current_section]
	var highlight_target: String = section.highlight_target
	if !highlight_target.is_empty():
		HighlightUI.stop_highlight(highlight_target)


func _on_next_button_pressed():
	_change_section(1)


func _on_back_button_pressed():
	_change_section(-1)
