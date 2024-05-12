class_name HintsMenuTab extends VBoxContainer


signal closed()

enum CsvProperty {
	ID = 0,
	TITLE,
	TEXT,
}

var _text_list: Array[String] = []

@export var csv_path: String
@export var _tree: Tree
@export var _hints_text_label: RichTextLabel

var _properties: Dictionary = {}


#########################
###     Built-in      ###
#########################

func _ready():
	UtilsStatic.load_csv_properties(csv_path, _properties, CsvProperty.ID)
	
	var root: TreeItem = _tree.create_item()

	var id_list: Array = _properties.keys()
	id_list.sort()
	
	for id in id_list:
		var entry: Dictionary = _properties[id]
		var title: String = entry[CsvProperty.TITLE]
		var text: String = entry[CsvProperty.TEXT]
		
		var tree_item_text: String = "%d. %s" % [id, title]
		var child: TreeItem = _tree.create_item(root)
		child.set_text(0, tree_item_text)
		
		_text_list.append(text)
	
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
