extends Node

# Class for global events. Emitters can use this to emit
# global events. Subscribers can connect to global signals.
# EventBus is useful for cases where connecting signals
# normally would require a long chain of connections.
# 
# For example:
# 
# ButtonTooltip needs to react to ItemButton's
# mouse_entered() and mouse_exited() signals. Connecting
# these two components normally would require the following
# chain:
# 
# ItemButton->ItemStashMenu->BottomMenuBar->HUD->ButtonTooltip
# 
# Connecting using Eventbus shortens the chain down to:
# 
# ItemButton->EventBus->ButtonTooltip
# 
# One way to think about EventBus is that it is like a
# middle man available from anywhere in the code. If there
# are two components which are "far away" from each other in
# the tree, EventBus can act as a middle man to shorten the
# distance between the components


signal item_button_mouse_entered(item: Item)
signal item_button_mouse_exited()
signal tower_button_mouse_entered(tower_id: int)
signal tower_button_mouse_exited()
signal research_button_mouse_entered(element: Element.enm)
signal research_button_mouse_exited()
signal autocast_button_mouse_entered(autocast: Autocast)
signal autocast_button_mouse_exited()
signal game_over()
signal game_mode_was_chosen()
signal horadric_menu_visibility_changed()
