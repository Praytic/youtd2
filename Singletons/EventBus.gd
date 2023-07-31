extends Node

# Class for global events. Emitters should can use this to
# emit global events. Subscribers can connect to global
# signals.

signal item_button_mouse_entered(item: Item)
signal item_button_mouse_exited()
signal tower_button_mouse_entered(tower_id: int)
signal tower_button_mouse_exited()
signal item_drop_picked_up(item: Item)
signal research_button_mouse_entered(element: Element.enm)
signal research_button_mouse_exited()
signal autocast_button_mouse_entered(autocast: Autocast)
signal autocast_button_mouse_exited()
signal consumable_item_was_consumed(item: Item)
signal waves_were_generated()
signal creep_reached_portal(damage_to_portal: float)
