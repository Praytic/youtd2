extends ButtonStatusCard

# NOTE: this file is unused

@export var _towers_status_panel: ShortResourceStatusPanel
@export var _ice_towers_status_panel: ShortResourceStatusPanel
@export var _nature_towers_status_panel: ShortResourceStatusPanel
@export var _fire_towers_status_panel: ShortResourceStatusPanel
@export var _astral_towers_status_panel: ShortResourceStatusPanel
@export var _darkness_towers_status_panel: ShortResourceStatusPanel
@export var _iron_towers_status_panel: ShortResourceStatusPanel
@export var _storm_towers_status_panel: ShortResourceStatusPanel


#########################
###       Public      ###
#########################

func connect_to_local_player(local_player: Player):
	var tower_stash: TowerStash = local_player.get_tower_stash()
	tower_stash.changed.connect(_on_tower_stash_changed)


#########################
###      Private      ###
#########################

func _get_towers_count(tower_list: Array, element: Element.enm) -> int:
	var count: int = 0

	for tower_id in tower_list:
		var tower_element: Element.enm = TowerProperties.get_element(tower_id)
		var element_match: bool = tower_element == element

		if element_match:
			count += 1

	return count


#########################
###     Callbacks     ###
#########################

func _on_tower_stash_changed():
	var local_player: Player = PlayerManager.get_local_player()
	var tower_stash: TowerStash = local_player.get_tower_stash()
	var tower_map: Dictionary = tower_stash.get_towers()
	var tower_list: Array = tower_map.keys()

	var fire_count: int = _get_towers_count(tower_list, Element.enm.FIRE)
	var astral_count: int = _get_towers_count(tower_list, Element.enm.ASTRAL)
	var nature_count: int = _get_towers_count(tower_list, Element.enm.NATURE)
	var ice_count: int = _get_towers_count(tower_list, Element.enm.ICE)
	var iron_count: int = _get_towers_count(tower_list, Element.enm.IRON)
	var storm_count: int = _get_towers_count(tower_list, Element.enm.STORM)
	var darkness_count: int = _get_towers_count(tower_list, Element.enm.DARKNESS)
	var towers_count: int = tower_list.size()
	
	_towers_status_panel.set_count(towers_count)
	_fire_towers_status_panel.set_count(fire_count)
	_astral_towers_status_panel.set_count(astral_count)
	_nature_towers_status_panel.set_count(nature_count)
	_ice_towers_status_panel.set_count(ice_count)
	_iron_towers_status_panel.set_count(iron_count)
	_storm_towers_status_panel.set_count(storm_count)
	_darkness_towers_status_panel.set_count(darkness_count)
