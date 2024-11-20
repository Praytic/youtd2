extends TabContainer


# Contains help information and hints for the game. Loads
# data from a CSV file. Left side of the menu contains a
# list of titles, while the right side of the menu displays
# the text of the selected section.


signal closed()


#########################
###     Built-in      ###
#########################

func _ready():
	var tab_node_list: Array[Node] = get_children()
	
	for tab_node in tab_node_list:
		var tab: HelpMenuTab = tab_node as HelpMenuTab
		
		if tab == null:
			continue
		
		tab.closed.connect(_on_tab_closed)


#########################
###     Callbacks     ###
#########################

func _on_tab_closed():
	closed.emit()
