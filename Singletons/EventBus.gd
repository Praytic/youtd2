extends Node

# Class for global events. Emitters can use this to emit
# global events. Subscribers can connect to global signals.
# EventBus is useful for cases where connecting signals
# normally would require a long chain of connections.


signal game_over()
signal game_mode_was_chosen()
signal horadric_menu_visibility_changed()
