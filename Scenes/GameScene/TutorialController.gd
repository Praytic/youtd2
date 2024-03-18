class_name TutorialController extends Node


# Controls logic flow while tutorial is running and tells
# TutorialMenu what to show. Tutorial text is loaded from a
# CSV file. Some tutorial sections highlight UI elements.
# Tutorial is opened after the pregame settings if the
# player decides that they want it.

# NOTE: UI targets for highlighting are mapped using
# HighlightUI.register_target() in scenes which contain
# those targets.


signal finished()

enum TutorialColumn {
	TITLE = 0,
	HIGHLIGHT_TARGET,
	TEXT,
}

class Section:
	var title: String
	var highlight_target: String
	var text: String


const TUTORIAL_BUILD_PATH: String = "res://Data/tutorial_build.csv"
const TUTORIAL_RANDOM_PATH: String = "res://Data/tutorial_random.csv"

var _section_list: Array[Section]
var _current_section: int
var _tutorial_menu: TutorialMenu = null


#########################
###       Public      ###
#########################

func start(tutorial_menu: TutorialMenu, game_mode: GameMode.enm):
	_tutorial_menu = tutorial_menu
	_tutorial_menu.player_pressed_next.connect(_on_player_pressed_next)
	_tutorial_menu.player_pressed_back.connect(_on_player_pressed_back)
	_tutorial_menu.player_pressed_close.connect(_on_player_pressed_close)
	HighlightUI.highlight_target_ack.connect(_on_highlight_target_ack)
	
	var tutorial_path: String
	if game_mode == GameMode.enm.BUILD:
		tutorial_path = TUTORIAL_BUILD_PATH
	else:
		tutorial_path = TUTORIAL_RANDOM_PATH

	var csv: Array[PackedStringArray] = UtilsStatic.load_csv(tutorial_path)
	
	_section_list = []
	
	print(_section_list)
	
	for csv_line in csv:
		var section: Section = Section.new()
		section.title = csv_line[TutorialColumn.TITLE]
		section.highlight_target = csv_line[TutorialColumn.HIGHLIGHT_TARGET]
		section.text = csv_line[TutorialColumn.TEXT]

		_section_list.append(section)
	print(_section_list)
	
	_current_section = 0
	_change_section(0)


#########################
###      Private      ###
#########################

func _change_section(change_amount: int):
	var prev_section: Section = _section_list[_current_section]

	_current_section += change_amount
	
	var section: Section = _section_list[_current_section]
	
	var text: String = ""
	text += "[color=GOLD]%s[/color]\n" % section.title
	text += " \n"
	text += section.text

	_tutorial_menu.set_text(text)

	var can_go_back: bool = _current_section > 0
	_tutorial_menu.set_back_disabled(!can_go_back)
	var can_go_next: bool = _current_section < _section_list.size() - 1
	_tutorial_menu.set_next_disabled(!can_go_next)

	var prev_highlight_target: String = prev_section.highlight_target
	if !prev_highlight_target.is_empty():
		HighlightUI.stop_highlight(prev_highlight_target)
	
	var new_highlight_target: String = section.highlight_target
	if !new_highlight_target.is_empty():
		HighlightUI.start_highlight(new_highlight_target)


#########################
###     Callbacks     ###
#########################

func _on_player_pressed_next():
	_change_section(1)


func _on_player_pressed_back():
	_change_section(-1)


func _on_player_pressed_close():
	var section: Section = _section_list[_current_section]
	var highlight_target: String = section.highlight_target
	if !highlight_target.is_empty():
		HighlightUI.stop_highlight(highlight_target)

	finished.emit()


func _on_highlight_target_ack(highlight_target: String):
	if _section_list[_current_section].highlight_target == highlight_target:
		_change_section(1)
