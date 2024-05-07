class_name Tower
extends Unit


signal items_changed()


enum AttackStyle {
	NORMAL,
	SPLASH,
	BOUNCE,
}


const TOWER_SELECTION_VISUAL_SIZE: int = 128
var TARGET_TYPE_GROUND_ONLY: TargetType = TargetType.new(TargetType.CREEPS + TargetType.SIZE_MASS + TargetType.SIZE_NORMAL + TargetType.SIZE_CHAMPION + TargetType.SIZE_BOSS)
var TARGET_TYPE_AIR_ONLY: TargetType = TargetType.new(TargetType.CREEPS + TargetType.SIZE_AIR)

@export var _id: int = 0
var _splash_map: Dictionary = {}
var _bounce_count_max: int = 0
var _bounce_damage_multiplier: float = 0.0
var _attack_style: AttackStyle = AttackStyle.NORMAL
# NOTE: _target_list must be an untyped Array because it may
# contain invalid instances.
var _target_list: Array = []
var _target_count_from_tower: int = 1
var _target_count_from_item: int = 0
var _default_projectile_type: ProjectileType
var _current_attack_cooldown: float = 0.0
var _was_ordered_to_stop_attack: bool = false
var _was_ordered_to_change_target: bool = false
var _new_target_from_order: Unit
var _item_container: TowerItemContainer
# NOTE: preceding tower reference is valid only during
# creation. It is also always null for first tier towers.
var _temp_preceding_tower: Tower = null
# This attack type determines which targets will be picked
# for attacking.
var _attack_target_type: TargetType = TargetType.new(TargetType.CREEPS)
var _range_indicator_list: Array[RangeIndicator] = []
var _tower_behavior: TowerBehavior = null
var _sprite: Sprite2D = null


@export var _mana_bar: ProgressBar
@export var _tower_selection_area: Area2D
@export var _visual: Node2D


#########################
###     Built-in      ###
#########################

func _ready():
	super()

	_set_visual_node(_visual)
	var outline_thickness: float = 6.0
	_set_sprite_node(_sprite, outline_thickness)

#	NOTE: set z to this value to position tower on 2nd floor
	var tower_z: float = Constants.TILE_SIZE_WC3
	set_z(tower_z)
#	NOTE: need to adjust y position of selection visual
# 	because it's placed at ground position in Unit.gd but
# 	needs to be at visual position for towers (which is 2nd
# 	floor).
	_selection_indicator.position.y -= Constants.TILE_SIZE.y

	var base_mana: int = TowerProperties.get_mana(_id)
	set_base_mana(base_mana)
	set_mana(0)

	var base_mana_regen: int = TowerProperties.get_mana_regen(_id)
	set_base_mana_regen(base_mana_regen)

	var inventory_capacity: int = get_inventory_capacity()
	_item_container = TowerItemContainer.new(inventory_capacity, self)
	add_child(_item_container)
	_item_container.items_changed.connect(_on_item_container_items_changed)

	GroupManager.add("towers", self, get_uid())

	mana_changed.connect(_on_mana_changed)
	_on_mana_changed()
	_mana_bar.visible = get_base_mana() > 0

	var missile_speed: int = TowerProperties.get_missile_speed(get_id())
	_default_projectile_type = ProjectileType.create_interpolate("", missile_speed, self)
	_default_projectile_type.set_event_on_interpolation_finished(_on_projectile_target_hit)

	var missile_uses_lightning_visual: bool = TowerProperties.get_missile_use_lightning_visual(get_id())
	if missile_uses_lightning_visual:
		_default_projectile_type.switch_to_lightning_visual()

# 	Carry over some properties and all items from preceding
# 	tower
	if _temp_preceding_tower != null:
		var preceding_item_list: Array = _temp_preceding_tower.get_items()
		var preceding_oil_list: Array = _temp_preceding_tower.get_oils()

		for oil_item in preceding_oil_list:
			_temp_preceding_tower.get_item_container().remove_item(oil_item)
			_item_container.add_item(oil_item)

#		Remove items from preceding tower
#		NOTE: need to use drop() and pickup() for consistent
#		logic, instead of directly manipulating item
#		containers.
		for item in preceding_item_list:
			item.drop()

#		NOTE: must set level and experience after removing
#		items from preceding tower and before adding items
#		to new tower. This is to correctly handle items
#		which grant experience while carried.
		set_level(_temp_preceding_tower._level)
		_experience = _temp_preceding_tower._experience

#		Add items to new tower
#		NOTE: for upgrade case, inventory will always be
#		same size or bigger but for transform case inventory
#		may be smaller. Handle transform case by returning
#		any extra items to stash.
		for item in preceding_item_list:
			if have_item_space():
				item.pickup(self)
			else:
				item.fly_to_stash(0.0)

		_kill_count = _temp_preceding_tower._kill_count
		_best_hit = _temp_preceding_tower._best_hit
		_damage_dealt_total = _temp_preceding_tower._damage_dealt_total
		
#		Transition all buff groups from preceding tower
		_buff_groups = _temp_preceding_tower._buff_groups.duplicate()
	else:
#		NOTE: only apply builder tower lvl bonus if tower is
#		"fresh". When tower is transformed or upgraded, it
#		inherits level of preceding tower and this builder
#		lvl bonus can't be applied.
		var builder: Builder = get_player().get_builder()
		var tower_lvl_bonus: int = builder.get_tower_lvl_bonus()

		if tower_lvl_bonus > 0:
			set_level(tower_lvl_bonus)
			var experience_for_level: int = Experience.get_exp_for_level(tower_lvl_bonus)
			_experience = experience_for_level

	var wisdom_modifier: Modifier = get_player().get_wisdom_modifier()
	add_modifier(wisdom_modifier)

#	NOTE: some stats have an innate level-based modifier
	var innate_modifier: Modifier = Modifier.new()
	innate_modifier.add_modification(Modification.Type.MOD_ATK_CRIT_CHANCE, 0, Constants.INNATE_MOD_ATK_CRIT_CHANCE_LEVEL_ADD)
	innate_modifier.add_modification(Modification.Type.MOD_ATK_CRIT_DAMAGE, 0, Constants.INNATE_MOD_ATK_CRIT_DAMAGE_LEVEL_ADD)
	innate_modifier.add_modification(Modification.Type.MOD_SPELL_CRIT_DAMAGE, 0, Constants.INNATE_MOD_SPELL_CRIT_CHANCE_LEVEL_ADD)
	innate_modifier.add_modification(Modification.Type.MOD_SPELL_CRIT_DAMAGE, 0, Constants.INNATE_MOD_SPELL_CRIT_DAMAGE_LEVEL_ADD)
	innate_modifier.add_modification(Modification.Type.MOD_DAMAGE_BASE_PERC, 0, Constants.INNATE_MOD_DAMAGE_BASE_PERC_LEVEL_ADD)
	innate_modifier.add_modification(Modification.Type.MOD_ATTACKSPEED, 0, Constants.INNATE_MOD_ATTACKSPEED_LEVEL_ADD)
	add_modifier(innate_modifier)

	_tower_behavior.init(self, _temp_preceding_tower)

#	NOTE: add aura range indicators to "visual" for correct
#	positioning on y axis.
	var range_data_list: Array[RangeData] = TowerProperties.get_range_data_list(get_id())
	_range_indicator_list = Utils.setup_range_indicators(range_data_list, _visual, get_player())

#	NOTE: hide range indicators until unit is selected
	for range_indicator in _range_indicator_list:
		range_indicator.hide()

	_setup_selection_signals(_tower_selection_area)

	var sprite_dimensions: Vector2 = Utils.get_sprite_dimensions(_sprite)
	_set_unit_dimensions(sprite_dimensions)

#	NOTE: we want size of selection visual to be the same
#	for all towers. That's why we're not using sprite
#	dimensions here like for creeps.
	_set_selection_size(TOWER_SELECTION_VISUAL_SIZE)

	_temp_preceding_tower = null
	

# NOTE: need to do attack timing without Timer because Timer
# doesn't handle short durations well (<0.5s)
func update(delta: float):
	var attack_enabled: bool = get_attack_enabled()
	if !attack_enabled:
		return

	if is_stunned():
		return

#	NOTE: reduce current tracked cooldown to overall
#	cooldown if overall cooldown is smaller. This handles
#	cases where tower's attackspeed was significantly
#	reduced and then returns to normal.
# 
#	For example, let's say tower's attackspeed gets reduced
#	by some debuff so much that the attack cooldown becomes
#	100 seconds. The debuff expires after 10 seconds and
#	tower would be doing nothing for 90 seconds. Instead of
#	that, we recalculate the cooldown so that tower can
#	start attacking normally again.
	var attackspeed: float = get_current_attackspeed()
	if _current_attack_cooldown > attackspeed:
		_current_attack_cooldown = attackspeed

	if _current_attack_cooldown > 0.0:
		_current_attack_cooldown -= delta

	if _current_attack_cooldown <= 0.0:
		var attack_success: bool = _try_to_attack()

# 		NOTE: important to add, not set! So that if game is
# 		lagging, all of the attacks fire instead of skipping.
		if attack_success:
			_current_attack_cooldown += attackspeed


#########################
###       Public      ###
#########################

func get_ability_description() -> String:
	return _tower_behavior.get_ability_description()


func get_ability_description_short() -> String:
	return _tower_behavior.get_ability_description_short()


func get_ability_ranges() -> Array[RangeData]:
	return _tower_behavior.get_ability_ranges()


func get_aura_types() -> Array[AuraType]:
	return _tower_behavior.get_aura_types()


func on_tower_details() -> MultiboardValues:
	return _tower_behavior.on_tower_details()


func remove_from_game():
	_tower_behavior.on_destruct()

	super()


func force_attack_target(forced_target: Creep):
	var type_ok: bool = _attack_target_type.match(forced_target)
	if !type_ok:
		return

#	NOTE: if tower can attack 1 target, then we simply stop
#	attacking current target. If tower can attack multiple
#	targets, then we substitute one of the targets with the
#	forced target. Note that if the forced target is out of
#	range, we add it anyway and the tower will later
#	automatically remove out of range forced target find a
#	new valid target before next attack.
	if !_target_list.is_empty():
		_remove_target(_target_list[0])

	_add_target(forced_target)


# NOTE: tower.orderStop() in JASS
func order_stop():
	_was_ordered_to_stop_attack = true


# Forces tower to attack a particular target. Works only if
# called during ATTACK event callback.
# NOTE: tower.issueTargetOrder() in JASS
func issue_target_order(target: Unit):
	if target == null:
		return

	_was_ordered_to_change_target = true
	_new_target_from_order = target


#########################
###      Private      ###
#########################

func _do_damage_from_projectile(projectile: Projectile, target: Unit, damage: float, is_main_target: bool):
	if target == null:
		return

	var crit_count: int = projectile.get_tower_crit_count()
	var crit_ratio: float = projectile.get_tower_crit_ratio()
	var emit_damage_event: bool = true

	do_attack_damage(target, damage, crit_ratio, crit_count, is_main_target, emit_damage_event)


# NOTE: this f-n does some unnecessary work in some cases
# but it's simpler this way. For example, it checks if
# target is invisible even though the get_units_in_range()
# f-n already filters out invisible creeps.
# NOTE: arg needs to be untyped because it may be an invalid
# instance.
func _target_is_valid(target) -> bool:
#	NOTE: return early here, so that if unit instance is
#	invalid, we don't call f-ns on it - that would cause
#	errors
	var unit_is_valid: bool = Utils.unit_is_valid(target)
	if !unit_is_valid:
		return false

	var attack_range: float = get_range()
	var in_range = VectorUtils.in_range(get_position_wc3_2d(), target.get_position_wc3_2d(), attack_range)

	var target_is_invisible: bool = target.is_invisible()

	var target_is_immune: bool = target.is_immune()
	var tower_is_magic: bool = get_attack_type() == AttackType.enm.MAGIC
	var is_immune_valid: bool = !(target_is_immune && tower_is_magic)

	var target_is_valid: bool = in_range && !target_is_invisible && is_immune_valid

	return target_is_valid


# NOTE: change color of projectile according to tower's
# element. Note that this overrides projectile's natural color so
# will need to rework this if we decide to make separate
# projectile sprites for each element.
func _make_projectile(from_pos_base: Vector3, target: Unit) -> Projectile:
	var z_arc: float = TowerProperties.get_missile_arc(get_id())
	var from_pos: Vector3 = from_pos_base + Projectile.UNIT_Z_OFFSET
	var projectile: Projectile = Projectile.create_linear_interpolation_from_point_to_unit(_default_projectile_type, self, 0, 0, from_pos, target, z_arc, true)

	var element_color: Color
	var element: Element.enm = get_element()

	match element:
		Element.enm.ICE: element_color = Color.LIGHT_BLUE
		Element.enm.NATURE: element_color = Color.FOREST_GREEN
		Element.enm.FIRE: element_color = Color.TOMATO
		Element.enm.ASTRAL: element_color = Color.GOLD
		Element.enm.DARKNESS: element_color = Color.PURPLE
		Element.enm.IRON: element_color = Color.SLATE_GRAY
		Element.enm.STORM: element_color = Color.TEAL
		Element.enm.NONE: element_color = Color.PINK

	projectile.modulate = element_color

	return projectile


func _try_to_attack() -> bool:
	_update_target_list()

# 	NOTE: have to do this weird stuff instead of just
# 	iterating over target list because attacks can modify
# 	the target list by killing creeps (and not just the
# 	current target)
	var attack_count: int = 0
	var already_attacked_list: Array = []

	while attack_count < get_target_count():
		var target: Creep = null

		for the_target in _target_list:
#			NOTE: need to check for unit validy here because
#			targets during multishot attacks may become
#			invalid. For example, if a previously attacked
#			creep has a debuff which makes it explode and it
#			kills another target nearby.
			if !Utils.unit_is_valid(the_target):
				continue

			var already_attacked: bool = already_attacked_list.has(the_target)

			if !already_attacked:
				target = the_target

				break

		if target == null:
			break

		var original_target: Unit = target

		var target_is_first: bool = attack_count == 0
		target = _attack_target(target, target_is_first)
		already_attacked_list.append(target)

#		NOTE: manually swap targets if target was changed
#		via issue_target_order() during _attack_target().
		var was_ordered_to_change_target: bool = original_target != target

		if was_ordered_to_change_target:
			_remove_target(original_target)
			_add_target(target)

		attack_count += 1

#		NOTE: handlers for attack event (inside
#		_attack_target) may order the tower to stop
#		attacking or switch to a different target. Process
#		the orders here. This part is to stop attacking if
#		tower has multishot.
		if _was_ordered_to_stop_attack:
			_was_ordered_to_stop_attack = false

			break

	var attack_success: bool = attack_count > 0

	return attack_success


# NOTE: returns the target which was actually attacked. May
# be different from input target if tower was ordered to
# switch to new target.
func _attack_target(target: Unit, target_is_first: bool) -> Unit:
#	NOTE: need to generate crit number here early instead of
#	right before dealing damage, so that for attacks like
#	splash damage and bounce attacks all of the damage dealt
#	has the same crit values. Also so that attack and damage
#	event handlers have access to crit count.
	var crit_count: int = _generate_crit_count(0.0, 0.0)
	var crit_ratio: float = _calc_attack_multicrit_from_crit_count(crit_count, 0.0)

#	NOTE: emit attack event only for the "first" target so
#	that if the tower has multishot ability, the attack
#	event is emitted only once per series of attacks. This
#	is the way it works in original game.
	if target_is_first:
		var attack_event: Event = Event.new(target)
		attack_event._number_of_crits = crit_count
		attack.emit(attack_event)

#	NOTE: process crit bonuses after attack event so that if
#	any attack event handlers added crit bonuses, we apply
#	these bonuses to current attack.
	crit_count += _bonus_crit_count_for_next_attack
	_bonus_crit_count_for_next_attack = 0

	crit_ratio += _bonus_crit_ratio_for_next_attack
	_bonus_crit_ratio_for_next_attack = 0.0

#	NOTE: handlers for attack event may order the tower to
#	stop attacking or switch to a different target. Process
#	the orders here.
	if _was_ordered_to_stop_attack:
		return target

	if _was_ordered_to_change_target:
		_was_ordered_to_change_target = false

		target = _new_target_from_order

	if target == null:
		return target

	var attacked_event: Event = Event.new(self)
	attacked_event._number_of_crits = crit_count
	target.attacked.emit(attacked_event)

	var tower_pos: Vector3 = get_position_wc3()
	var projectile: Projectile = _make_projectile(tower_pos, target)
	projectile.set_tower_crit_count(crit_count)
	projectile.set_tower_crit_ratio(crit_ratio)

	if _attack_style == AttackStyle.BOUNCE:
		var randomize_damage: bool = true
		var damage: float = get_current_attack_damage_with_bonus(randomize_damage)

		projectile.user_real = damage
		projectile.user_int = 0

	var sfx_path: String
	match get_element():
		Element.enm.NATURE: sfx_path = "res://Assets/SFX/swosh-08.mp3"
		Element.enm.STORM: sfx_path = "res://Assets/SFX/foom_02.mp3"
		Element.enm.FIRE: sfx_path = "res://Assets/SFX/fire_attack1.mp3"
		Element.enm.ICE: sfx_path = "res://Assets/SFX/iceball.mp3"
		Element.enm.ASTRAL: sfx_path = "res://Assets/SFX/attack_sound1.mp3"
		Element.enm.DARKNESS: sfx_path = "res://Assets/SFX/swosh-11.mp3"
		Element.enm.IRON: sfx_path = "res://Assets/SFX/iron_attack1.mp3"
		_: sfx_path = "res://Assets/SFX/swosh-08.mp3"

	SFX.sfx_at_unit(sfx_path, self, -20.0)

	return target


func _update_target_list():
#	Remove targets that have become invalid. Targets can
#	become invalid by moving out of range, becoming
#	invisible
	var removed_target_list: Array = []

	for target in _target_list:
		var target_is_valid: bool = _target_is_valid(target)

		if !target_is_valid:
			removed_target_list.append(target)

	for target in removed_target_list:
		_remove_target(target)

# 	Remove targets if target list size is too large. For
# 	example, if a tower ability temporarily increased target
# 	count to 3 and then it went back down to 1.
	while _target_list.size() > get_target_count():
		var target = _target_list.back()
		_remove_target(target)

# 	Add new targets that have entered into range
	var attack_range: float = get_range()
	var creeps_in_range: Array = Utils.get_units_in_range(_attack_target_type, get_position_wc3_2d(), attack_range)

	if Config.smart_targeting():
		Utils.sort_creep_list_for_targeting(creeps_in_range, get_position_wc3_2d())
	else:
		Utils.sort_unit_list_by_distance(creeps_in_range, get_position_wc3_2d())

	for target in _target_list:
		creeps_in_range.erase(target)

	while creeps_in_range.size() > 0 && _target_list.size() < get_target_count():
		var new_target: Creep = creeps_in_range.pop_front()
		var target_is_valid: bool = _target_is_valid(new_target)

		if target_is_valid:
			_add_target(new_target)


func _add_target(target: Creep):
	if _target_list.has(target):
		return

	_target_list.append(target)
	target.tree_exited.connect(_on_target_tree_exited.bind(target))


# NOTE: arg needs to be untyped because it may be an invalid
# instance.
func _remove_target(target):
	if !_target_list.has(target):
		return

	if is_instance_valid(target):
		target.tree_exited.disconnect(_on_target_tree_exited)

	_target_list.erase(target)


func _get_splash_attack_description() -> String:
	var text: String = ""

	var splash_range_list: Array = _splash_map.keys()
	splash_range_list.sort()

	for splash_range in splash_range_list:
		var splash_ratio: float = _splash_map[splash_range]
		var splash_percentage: int = floor(splash_ratio * 100)
		text += "[color=GOLD]%d[/color] AoE: [color=GOLD]%d%%[/color] damage\n" % [splash_range, splash_percentage]

	return text


func _get_bounce_attack_description() -> String:
	var bounce_dmg_percent: String = Utils.format_percent(_bounce_damage_multiplier, 0)
	var text: String = "[color=GOLD]%d[/color] targets\n" % _bounce_count_max \
	+ "[color=GOLD]-%s[/color] damage per bounce\n" % bounce_dmg_percent

	return text


func _get_next_bounce_target(bounce_pos: Vector3, visited_list: Array[Unit]) -> Creep:
	var bounce_pos_2d: Vector2 = Vector2(bounce_pos.x, bounce_pos.y)
	var creep_list: Array = Utils.get_units_in_range(_attack_target_type, bounce_pos_2d, Constants.BOUNCE_ATTACK_RANGE)

	for visited_creep in visited_list:
		if !Utils.unit_is_valid(visited_creep):
			continue

		creep_list.erase(visited_creep)

	Utils.sort_unit_list_by_distance(creep_list, bounce_pos_2d)

	if !creep_list.is_empty():
		var next_target = creep_list[0]

		return next_target
	else:
		return null


#########################
###     Callbacks     ###
#########################

func _on_selected_changed():
	var selected_value: bool = is_selected()
	
	for indicator in _range_indicator_list:
		indicator.visible = selected_value


func _on_target_tree_exited(target: Creep):
	_remove_target(target)


func _on_item_container_items_changed():
	items_changed.emit()
	EventBus.player_performed_tutorial_advance_action.emit("place_item_in_tower")


func _on_mana_changed():
	var mana_ratio: float = get_mana_ratio()
	_mana_bar.ratio = mana_ratio


func _on_projectile_target_hit(projectile: Projectile, target: Unit):
	match _attack_style:
		AttackStyle.NORMAL:
			_on_projectile_target_hit_normal(projectile, target)
		AttackStyle.SPLASH:
			_on_projectile_target_hit_splash(projectile, target)
		AttackStyle.BOUNCE:
			_on_projectile_target_hit_bounce(projectile, target)


func _on_projectile_target_hit_normal(projectile: Projectile, target: Unit):
	var randomize_damage: bool = true
	var damage: float = get_current_attack_damage_with_bonus(randomize_damage)
	var is_main_target: bool = true
	
	_do_damage_from_projectile(projectile, target, damage, is_main_target)


func _on_projectile_target_hit_splash(projectile: Projectile, main_target: Unit):
	if _splash_map.is_empty():
		return

	var randomize_damage: bool = true
	var damage: float = get_current_attack_damage_with_bonus(randomize_damage)
	var is_main_target: bool = true

	_do_damage_from_projectile(projectile, main_target, damage, is_main_target)

	var splash_pos: Vector2
	if main_target != null:
		splash_pos = main_target.get_position_wc3_2d()
	else:
		splash_pos = projectile.get_position_wc3_2d()

#	Process splash ranges from closest to furthers,
#	so that strongest damage is applied
	var splash_range_list: Array = _splash_map.keys()
	splash_range_list.sort()

	var splash_range_max: float = splash_range_list.back()

	var creep_list: Array = Utils.get_units_in_range(_attack_target_type, splash_pos, splash_range_max)

	if main_target != null:
		creep_list.erase(main_target)

	for neighbor in creep_list:
#		NOTE: need to check validity because splash attack
#		may trigger an exploding creep ability which will
#		kill other splash attack targets before they are
#		processed.
		if !Utils.unit_is_valid(neighbor):
			continue

		var neighbor_pos: Vector2 = neighbor.get_position_wc3_2d()
		var distance: float = splash_pos.distance_to(neighbor_pos)

		for splash_range in splash_range_list:
			var creep_is_in_range: bool = distance < splash_range

			if creep_is_in_range:
				var splash_damage_ratio: float = _splash_map[splash_range]
				var splash_damage: float = damage * splash_damage_ratio
				var splash_is_main_target: bool = true
				_do_damage_from_projectile(projectile, neighbor, splash_damage, splash_is_main_target)

				break


func _on_projectile_target_hit_bounce(projectile: Projectile, current_target: Unit):
	var current_damage: float = projectile.user_real
	var current_bounce_index: int = projectile.user_int
	var bounce_visited_list: Array[Unit] = projectile.get_tower_bounce_visited_list()
	if current_target != null:
		bounce_visited_list.append(current_target)

	var is_first_bounce: bool = current_bounce_index == 0
	var is_main_target: bool = is_first_bounce

	var bounce_pos: Vector3
	if current_target != null:
		bounce_pos = current_target.get_position_wc3()
	else:
		bounce_pos = projectile.get_position_wc3()

	_do_damage_from_projectile(projectile, current_target, current_damage, is_main_target)

# 	Launch projectile for next bounce, if bounce isn't over
	var bounce_end: bool = current_bounce_index == _bounce_count_max - 1

	if bounce_end:
		return

	var next_damage: float = current_damage * (1.0 - _bounce_damage_multiplier)

	var next_target: Creep = _get_next_bounce_target(bounce_pos, bounce_visited_list)

	if next_target == null:
		return

	var next_projectile: Projectile = _make_projectile(bounce_pos, next_target)
	next_projectile.user_real = next_damage
	next_projectile.user_int = current_bounce_index + 1
	next_projectile._tower_bounce_visited_list = bounce_visited_list
#	NOTE: save crit count in projectile so that it can be
#	used when projectile reaches the target to calculate
#	damage
	next_projectile.set_tower_crit_count(projectile.get_tower_crit_count())
	next_projectile.set_tower_crit_ratio(projectile.get_tower_crit_ratio())


#########################
### Setters / Getters ###
#########################


# NOTE: call this in load_specials() of tower instance
func set_attack_ground_only():
	_attack_target_type = TARGET_TYPE_GROUND_ONLY


# NOTE: call this in load_specials() of tower instance
func set_attack_air_only():
	_attack_target_type = TARGET_TYPE_AIR_ONLY


# NOTE: call this in load_specials() of tower instance
func set_attack_style_splash(splash_map: Dictionary):
	_attack_style = AttackStyle.SPLASH
	_splash_map = splash_map


# NOTE: call this in load_specials() of tower instance
func set_attack_style_bounce(bounce_count_max: int, bounce_damage_multiplier: float):
	_attack_style = AttackStyle.BOUNCE
	_bounce_count_max = bounce_count_max
	_bounce_damage_multiplier = bounce_damage_multiplier


# NOTE: call this in load_specials() of tower instance
func set_target_count(count: int):
	_target_count_from_tower = count


func set_target_count_from_item(count: int):
	_target_count_from_item = count


func get_target_count_from_item() -> int:
	return _target_count_from_item


# NOTE: tower.getTargetCount() in JASS
func get_target_count() -> int:
	return _target_count_from_tower + _target_count_from_item


# Tower is attacking while it has valid targets in range.
func is_attacking() -> bool:
	var attacking: bool = !_target_list.is_empty()

	return attacking


# NOTE: tower.countFreeSlots() in JASS
func count_free_slots() -> int:
	var item_count: int = _item_container.get_item_count()
	var capacity: int = _item_container.get_capacity()
	var free_slots = capacity - item_count

	return free_slots


# NOTE: tower.haveItemSpace() in JASS
func have_item_space() -> bool:
	return _item_container.have_item_space()


func get_oils() -> Array[Item]:
	return _item_container.get_oil_list()


func get_items() -> Array[Item]:
	return _item_container.get_item_list()


func get_item_count() -> int:
	return _item_container.get_item_count()


# NOTE: slot_number starts at 1 instead of 0
# NOTE: tower.getHeldItem() in JASS
func get_held_item(slot_number: int) -> Item:
	var slot_index: int = slot_number - 1
	return _item_container.get_item_at_index(slot_index)


func get_item_tower_details() -> Array[MultiboardValues]:
	var out: Array[MultiboardValues] = []

	var item_list: Array[Item] = _item_container.get_item_list()
	
	for item in item_list:
		var board: MultiboardValues = item.on_tower_details()

		if board != null:
			out.append(board)

	return out


func get_log_name() -> String:
	return get_display_name()


func get_item_container() -> ItemContainer:
	return _item_container


# This function automatically generates a description for
# specials that tower instance defined in load_specials().
func _get_specials_description() -> String:
	var text: String = ""

	var attacks_ground_only: bool = _attack_target_type == TARGET_TYPE_GROUND_ONLY
	var attacks_air_only: bool = _attack_target_type == TARGET_TYPE_AIR_ONLY
	if attacks_ground_only:
		text += "[color=RED]Attacks GROUND only[/color]\n"
	elif attacks_air_only:
		text += "[color=RED]Attacks AIR only[/color]\n"
	
	var specials_modifier: Modifier = _tower_behavior.get_specials_modifier()
	var modifier_text: String = specials_modifier.get_tooltip_text()
	modifier_text = RichTexts.add_color_to_numbers(modifier_text)

	if !modifier_text.is_empty():
		if !text.is_empty():
			text += " \n"
		text += modifier_text

	return text


func get_ability_info_list() -> Array[AbilityInfo]:
	var list: Array[AbilityInfo] = []

	var specials_description: String = _get_specials_description()
	if !specials_description.is_empty():
		var specials: AbilityInfo = AbilityInfo.new()
		specials.name = "Specials"
		specials.icon = "res://Resources/Icons/mechanical/rocket_04.tres"
		specials.description_full = specials_description
		specials.description_short = specials_description
		list.append(specials)

	if _attack_style == AttackStyle.SPLASH:
		var splash_attack: AbilityInfo = AbilityInfo.new()
		splash_attack.name = "Splash Attack"
		splash_attack.icon = "res://Resources/Icons/mechanical/rocket_with_fire.tres"
		splash_attack.description_full = _get_splash_attack_description()
		splash_attack.description_short = splash_attack.description_full
		list.append(splash_attack)

	if _attack_style == AttackStyle.BOUNCE:
		var bounce_attack: AbilityInfo = AbilityInfo.new()
		bounce_attack.name = "Bounce Attack"
		bounce_attack.icon = "res://Resources/Icons/mechanical/rocket_05.tres"
		bounce_attack.description_full = _get_bounce_attack_description()
		bounce_attack.description_short = bounce_attack.description_full
		list.append(bounce_attack)

#	NOTE: need to use _target_count_from_tower without
#	adding _target_count_from_item so that item's bonus is
#	not displayed in tower info.
	if _target_count_from_tower > 1:
		var multishot: AbilityInfo = AbilityInfo.new()
		multishot.name = "Multishot"
		multishot.icon = "res://Resources/Icons/AbilityIcons/multishot.tres"
		var multishot_tooltip: String = "Attacks up to [color=GOLD]%d[/color] targets at the same time.\n" % _target_count_from_tower
		multishot.description_short = multishot_tooltip
		multishot.description_full = multishot_tooltip
		list.append(multishot)
	
	var extra_abilities: Array[AbilityInfo] = _tower_behavior.get_ability_info_list()
	list.append_array(extra_abilities)
	
	return list


func get_current_target() -> Unit:
	if !_target_list.is_empty():
		return _target_list.front()
	else:
		return null


# NOTE: this must be called once after the tower is created
# but before it's added to game scene
func set_id(id: int):
	_id = id


func get_id() -> int:
	return _id


func get_tier() -> int:
	return TowerProperties.get_tier(_id)

# NOTE: tower.getFamily() in JASS
func get_family() -> int:
	return TowerProperties.get_family(_id)


# NOTE: tower.getElement() in JASS
func get_element() -> Element.enm:
	return TowerProperties.get_element(_id)

# NOTE: in tower scripts getCategory() is called to get
# tower's element instead of getElement(), for some reason,
# so make this wrapper over get_element()
# 
# NOTE: tower.getCategory() in JASS
func get_category() -> int:
	return get_element()

# This is the base time between tower attacks, before
# applying modifications. Do not confuse this value with
# MOD_ATTACKSPEED.
# attackspeed = time in seconds
# MOD_ATTACKSPEED = multiplier which reduces/increases the time
# NOTE: tower.getBaseAttackspeed() in JASS
func get_base_attackspeed() -> float:
	return TowerProperties.get_base_attackspeed(_id)

# This is the actual time between tower attacks, after
# applying modifications.
# Example: If the base attackspeed is 2.0 seconds and the
# tower has 1.25 attackspeed, then the real attack cooldown
# will be 2.0/1.25 == 1.6 seconds.
# NOTE: tower.getCurrentAttackSpeed() in JASS
func get_current_attackspeed() -> float:
	var attackspeed: float = get_base_attackspeed()
	var attackspeed_mod: float = get_attackspeed_modifier()
	var current_attackspeed: float = attackspeed / attackspeed_mod

	return current_attackspeed


func get_remaining_cooldown() -> float:
	return max(0, _current_attack_cooldown)

func get_damage_min() -> int:
	return TowerProperties.get_damage_min(_id)

func get_damage_max() -> int:
	return TowerProperties.get_damage_max(_id)

func get_base_damage() -> int:
	return TowerProperties.get_base_damage(_id)

# NOTE: tower.getCurrentAttackDamageBase() in JASS
# NOTE: by default this value is based on the average of
# tower's min and max damage. When tower is calculating
# attack damage, the randomize_damage arg is set to true so
# that this f-n returns random value between min and max.
func get_current_attack_damage_base(randomize_damage: bool = false) -> float:
	var damage_min: float = get_damage_min()
	var damage_max: float = get_damage_max()

	var damage: float
	if randomize_damage:
		damage = Globals.synced_rng.randf_range(damage_min, damage_max)
	else:
		damage = floori((damage_min + damage_max) / 2)

	return damage

# NOTE: tower.getCurrentAttackDamageWithBonus() in JASS
func get_current_attack_damage_with_bonus(randomize_damage: bool = false) -> float:
	var base_damage: float = get_current_attack_damage_base(randomize_damage)
	var base_bonus: float = get_base_damage_bonus()
	var base_bonus_percent: float = get_base_damage_bonus_percent()
	var damage_add: float = get_damage_add()
	var damage_add_percent: float = get_damage_add_percent()
	var dps_bonus: float = get_dps_bonus()
	var attackspeed: float = get_current_attackspeed()
	var dps_mod: float = dps_bonus * attackspeed

	var overall_base_damage: float = (base_damage + base_bonus) * base_bonus_percent
	var overall_damage: float = (overall_base_damage + damage_add) * damage_add_percent + dps_mod

	overall_damage = max(0, overall_damage)

	return overall_damage


func get_overall_damage() -> float:
	return get_current_attack_damage_with_bonus()


# How much damage the tower deals with its attack per second on average (not counting in any crits). 
func get_overall_dps() -> float:
	var damage: float = get_overall_damage()
	var attackspeed: float = get_current_attackspeed()
	var dps: float = damage / attackspeed

	return dps


# How much damage the tower deals with its attack per second on average when 
# counting attack crits and multicrits.
func get_dps_with_crit() -> float:
	return get_overall_dps() * get_crit_multiplier()

# How much damage the tower dealt in total
func get_damage() -> float:
	return _damage_dealt_total

# How much kills the tower has in total
func get_kills() -> int:
	return _kill_count

# What was the max hit damage the tower dealt
func get_best_hit() -> float:
	return _best_hit

# NOTE: tower.getRange() in JASS
func get_range() -> float:
	var original_range: float = TowerProperties.get_range(_id)
	var builder: Builder = get_player().get_builder()
	var builder_range_bonus: float = builder.get_range_bonus()
	var total_range: float = original_range + builder_range_bonus

	return total_range


# NOTE: tower.getRarity() in JASS
func get_rarity() -> Rarity.enm:
	return TowerProperties.get_rarity(_id)
	
func get_display_name() -> String:
	return TowerProperties.get_display_name(_id)

# NOTE: tower.getAttackType() in JASS
func get_attack_type() -> AttackType.enm:
	return TowerProperties.get_attack_type(_id)

# NOTE: tower.getGoldCost() in JASS
func get_gold_cost() -> int:
	return TowerProperties.get_cost(_id)

func get_inventory_capacity() -> int:
	var original_capacity: int = TowerProperties.get_inventory_capacity(_id)
	var builder: Builder = get_player().get_builder()
	var builder_item_slots_bonus: int = builder.get_item_slots_bonus()
	var total_capacity: int = original_capacity + builder_item_slots_bonus
	total_capacity = clampi(total_capacity, 1, Constants.INVENTORY_CAPACITY_MAX)

	return total_capacity

func get_attack_enabled() -> bool:
	return TowerProperties.get_attack_enabled(_id)


#########################
###       Static      ###
#########################

# Return new unique instance of the Tower by its ID. Get
# script for tower and attach to scene. Script name matches
# with scene name so this can be done automatically instead
# of having to do it by hand in scene editor.
static func make(id: int, player: Player, preceding_tower: Tower = null) -> Tower:
	var tower: Tower = Preloads.tower_scene.instantiate()
	var script_path: String = TowerProperties.get_script_path(id)
	var tower_behavior_script: Script = load(script_path)
	var tower_behavior: TowerBehavior = tower_behavior_script.new()
	tower._tower_behavior = tower_behavior
	tower.add_child(tower_behavior)
	var tower_sprite: Sprite2D = TowerSprites.get_sprite(id)
	var visual_node: Node2D = tower.get_node("Visual")
	
	if visual_node == null:
		push_error("visual node is null")
		
		return null

	visual_node.add_child(tower_sprite)
	visual_node.move_child(tower_sprite, 0)
	tower._sprite = tower_sprite
	
	tower._temp_preceding_tower = preceding_tower

	tower.set_id(id)
	tower.set_player(player)

	return tower
