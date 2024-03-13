extends Node

# Class for global events. Emitters can use this to emit
# global events. Subscribers can connect to global signals.
# EventBus is useful for cases where connecting signals
# normally would require a long chain of connections.


# When user does a specific action to acknowledge the highlighted
# area, this signal should be emitted.
signal highlight_target_ack(highlight_target: String)
signal selected_backpacker_builder()
signal player_requested_transmute()
signal player_requested_autofill(recipe: HoradricCube.Recipe, rarity_filter: Array)
signal player_requested_to_research_element(element: Element.enm)
signal player_requested_to_build_tower(tower_id: int)
signal player_requested_to_upgrade_tower(tower: Tower)
signal player_requested_to_sell_tower(tower: Tower)
signal player_clicked_item_in_tower_inventory(item: Item)
signal player_clicked_item_in_main_stash(item: Item)
signal player_clicked_item_in_horadric_stash(item: Item)
signal player_clicked_main_stash(item: Item)
signal player_clicked_horadric_stash(item: Item)
signal player_clicked_tower_inventory(item: Item)
signal item_flew_to_item_stash(item: Item)
signal player_requested_to_roll_towers()
signal wave_finished(level: int)
signal player_requested_start_game()
signal player_requested_next_wave()
signal creep_reached_portal(creep: Creep)
