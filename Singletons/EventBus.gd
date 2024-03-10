extends Node

# Class for global events. Emitters can use this to emit
# global events. Subscribers can connect to global signals.
# EventBus is useful for cases where connecting signals
# normally would require a long chain of connections.


signal game_over()
# When user does a specific action to acknowledge the highlighted
# area, this signal should be emitted.
signal highlight_target_ack(highlight_target: String)
signal selected_backpacker_builder()
signal player_requested_transmute()
signal player_requested_autofill(recipe: HoradricCube.Recipe, rarity_filter: Array)
