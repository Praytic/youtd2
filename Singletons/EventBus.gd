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
signal player_clicked_item_in_tower_inventory(item: Item)
signal player_clicked_item_in_main_stash(item: Item)
signal player_clicked_item_in_horadric_stash(item: Item)
signal player_clicked_main_stash(item: Item)
signal player_clicked_horadric_stash(item: Item)
signal player_clicked_tower_inventory(item: Item)
signal item_flew_to_item_stash(item: Item)
signal player_requested_to_roll_towers()
signal wave_finished(level: int)
signal tower_created(tower: Tower)
signal tower_removed(tower: Tower)
