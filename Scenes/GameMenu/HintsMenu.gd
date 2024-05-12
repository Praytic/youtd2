extends TabContainer


# Displays hints for the game. Loads the list of hints from
# a CSV file. Left side of the menu contains a list of
# titles, while the right side of the menu displays the text
# of the selected hint.


signal closed()


#########################
###     Built-in      ###
#########################

func _ready():
	var tab_node_list: Array[Node] = get_children()
	
	for tab_node in tab_node_list:
		var tab: HintsMenuTab = tab_node as HintsMenuTab
		
		if tab == null:
			continue
		
		tab.closed.connect(_on_tab_closed)


#########################
###     Callbacks     ###
#########################

func _on_tab_closed():
	closed.emit()
