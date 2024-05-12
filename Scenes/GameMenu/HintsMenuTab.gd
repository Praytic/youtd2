class_name HintsMenuTab extends VBoxContainer


signal closed()


var _text_list: Array[String] = []

@export var csv_path: String
@export var _tree: Tree
@export var _hints_text_label: RichTextLabel


#########################
###     Built-in      ###
#########################

# Called when the node enters the scene tree for the first time.
func _ready():
	var csv: Array[PackedStringArray] = UtilsStatic.load_csv(csv_path)
	
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


#########################
###     Callbacks     ###
#########################

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


func _on_close_button_pressed():
	closed.emit()
