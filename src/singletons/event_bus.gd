extends Node

# Class for global events. Emitters can use this to emit
# global events. Subscribers can connect to global signals.
# EventBus is useful for cases where connecting signals
# normally would require a long chain of connections.


signal received_first_timeslot()
signal player_selected_builder()
signal player_requested_quit_to_title()
signal player_requested_transmute()
signal player_requested_return_from_horadric_cube()
signal player_requested_autofill(recipe: HoradricCube.Recipe, rarity_filter: Array)
signal player_requested_to_research_element(element: Element.enm)
signal player_requested_to_build_tower(tower_id: int)
signal player_requested_to_upgrade_tower(tower: Tower)
signal player_requested_to_sell_tower(tower: Tower)
signal player_requested_to_clear_combatlog()
signal player_requested_help()
signal player_clicked_autocast(autocast: Autocast)
signal player_right_clicked_autocast(autocast: Autocast)
signal player_shift_right_clicked_item(item: Item)
signal player_right_clicked_item(item: Item)
signal player_clicked_in_item_container(item_container: ItemContainer, clicked_index: int)
signal player_clicked_tower_buff_group(tower: Tower, buff_group: int)
signal item_flew_to_item_stash(item: Item)
signal player_requested_to_roll_towers()
signal player_requested_start_game()
signal player_requested_next_wave()
signal mouse_entered_unit(unit: Unit)
signal mouse_exited_unit(unit: Unit)
signal item_started_flying_to_item_stash(item: Item, canvas_pos: Vector2)

# NOTE: signals for triggering tutorials
signal finished_tutorial_section(tutorial_id: int)
signal item_dropped()
signal portal_received_damage()
signal built_a_tower()
signal unit_leveled_up()
