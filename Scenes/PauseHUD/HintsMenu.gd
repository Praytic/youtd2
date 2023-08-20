extends PanelContainer


# Displays hints for the game. Loads the list of hints from
# a CSV file. Left side of the menu contains a list of
# titles, while the right side of the menu displays the text
# of the selected hint.


signal closed()


const HINTS_CSV_PATH: String = "res://Data/hints.csv"

var _text_list: Array[String] = []

@export var _tree: Tree
@export var _hints_text_label: RichTextLabel


func _ready():
	var csv: Array[PackedStringArray] = Utils.load_csv(HINTS_CSV_PATH)
	
	var root: TreeItem = _tree.create_item()

	var index: int = 0
	
	for csv_line in csv:
		var title: String = "%d. %s" % [index, csv_line[0]]
		var text: String = csv_line[1]
	
		var child: TreeItem = _tree.create_item(root)
		child.set_text(0, title)
		
		_text_list.append(text)

		index += 1
	
	var first_item: TreeItem = root.get_child(0)
	_tree.set_selected(first_item, 0)


func _on_close_button_pressed():
	closed.emit()


func _on_tree_item_selected():
	var selected_item: TreeItem = _tree.get_selected()
	var index: int = selected_item.get_index()
	var text: String = _text_list[index]

	_hints_text_label.clear()

# 	NOTE: newlines don't work if you append the whole text.
# 	Have to append newlines separately to make it work.
	var lines: Array = text.split("\\n")

	for line in lines:
		_hints_text_label.append_text(line)
		_hints_text_label.append_text("\n")
	
