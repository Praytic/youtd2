class_name Tower
extends Unit


signal items_changed()


enum AttackStyle {
	NORMAL,
	SPLASH,
	BOUNCE,
}

const ELEMENT_TO_EXPLOSION_ART: Dictionary = {
	Element.enm.ICE: "res://src/effects/projectile_explosion_ice.tscn",
	Element.enm.NATURE: "res://src/effects/projectile_explosion_nature.tscn",
	Element.enm.FIRE: "res://src/effects/projectile_explosion_fire.tscn",
	Element.enm.ASTRAL: "res://src/effects/projectile_explosion_astral.tscn",
	Element.enm.DARKNESS: "res://src/effects/projectile_explosion_darkness.tscn",
	Element.enm.IRON: "res://src/effects/projectile_explosion_iron.tscn",
	Element.enm.STORM: "res://src/effects/projectile_explosion_storm.tscn",
	Element.enm.NONE: "res://src/effects/projectile_explosion_storm.tscn",
}


const TOWER_SELECTION_VISUAL_SIZE: int = 128
static var TARGET_TYPE_GROUND_ONLY: TargetType = TargetType.new(TargetType.CREEPS + TargetType.SIZE_MASS + TargetType.SIZE_NORMAL + TargetType.SIZE_CHAMPION + TargetType.SIZE_BOSS)
static var TARGET_TYPE_AIR_ONLY: TargetType = TargetType.new(TargetType.CREEPS + TargetType.SIZE_AIR)

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
# NOTE: preceding tower reference is used only during
# Tower._ready() and TowerBehavior.init(). It becomes null
# forever after that and it is also always null for first
# tier towers.
var _temp_preceding_tower: Tower = null
# This attack type determines which targets will be picked
# for attacking.
var _attack_target_type: TargetType = TargetType.new(TargetType.CREEPS)
var _range_indicator_list: Array[RangeIndicator] = []
var _tower_behavior: TowerBehavior = null
var _sprite: Sprite2D = null
var _hide_attack_projectiles: bool = false
var _current_crit_count: int = 0
var _current_crit_damage: float = 0
var _transform_is_allowed: bool = true
var _is_in_combat: bool = false


@export var _mana_bar: ProgressBar
@export var _tower_selection_area: Area2D
@export var _visual: Node2D
@export var _range_indicator_parent: Node2D
@export var _sprite_parent: Node2D


#########################
###     Built-in      ###
#########################

func _ready():
	super()

# 	NOTE: see explanation of z_index setup in map.gd
	z_index = 20

	_set_visual_node(_visual)
	var outline_thickness: float = 6.0
	_setup_unit_sprite(_sprite, _sprite_parent, outline_thickness)

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
	_item_container.set_player(get_player())
	add_child(_item_container)
	_item_container.items_changed.connect(_on_item_container_items_changed)

	GroupManager.add("towers", self, get_uid())

	mana_changed.connect(_on_mana_changed)
	_on_mana_changed()
	_mana_bar.visible = get_base_mana() > 0

	var missile_speed: int = TowerProperties.get_missile_speed(get_id())
	_default_projectile_type = ProjectileType.create_interpolate("", missile_speed, self)
	_default_projectile_type.set_event_on_interpolation_finished(_on_projectile_target_hit)
	var explosion_art: String = ELEMENT_TO_EXPLOSION_ART[get_element()]
	_default_projectile_type.set_explosion_art(explosion_art)

	var missile_uses_lightning_visual: bool = TowerProperties.get_missile_use_lightning_visual(get_id())
	if missile_uses_lightning_visual:
		_default_projectile_type.switch_to_lightning_visual()

# 	Carry over some properties and all items from preceding
# 	tower
	if _temp_preceding_tower != null:
		get_player().transfer_autooils(_temp_preceding_tower, self)
		
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
		_damage_dealt_to_wave_map = _temp_preceding_tower._damage_dealt_to_wave_map
		
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
	innate_modifier.add_modification(ModificationType.enm.MOD_ATK_CRIT_CHANCE, 0, Constants.INNATE_MOD_ATK_CRIT_CHANCE_LEVEL_ADD)
	innate_modifier.add_modification(ModificationType.enm.MOD_ATK_CRIT_DAMAGE, 0, Constants.INNATE_MOD_ATK_CRIT_DAMAGE_LEVEL_ADD)
	innate_modifier.add_modification(ModificationType.enm.MOD_SPELL_CRIT_DAMAGE, 0, Constants.INNATE_MOD_SPELL_CRIT_CHANCE_LEVEL_ADD)
	innate_modifier.add_modification(ModificationType.enm.MOD_SPELL_CRIT_DAMAGE, 0, Constants.INNATE_MOD_SPELL_CRIT_DAMAGE_LEVEL_ADD)
	innate_modifier.add_modification(ModificationType.enm.MOD_DAMAGE_BASE_PERC, 0, Constants.INNATE_MOD_DAMAGE_BASE_PERC_LEVEL_ADD)
	innate_modifier.add_modification(ModificationType.enm.MOD_ATTACKSPEED, 0, Constants.INNATE_MOD_ATTACKSPEED_LEVEL_ADD)
	add_modifier(innate_modifier)

	var tower_id: int = get_id()

	var multishot_count: int = TowerProperties.get_multishot(tower_id)
	set_target_count(multishot_count)

	var bounce_attack_values: Array = TowerProperties.get_bounce_attack(tower_id)
	var splash_attack_values: Dictionary = TowerProperties.get_splash_attack(tower_id)
	if !bounce_attack_values.is_empty():
		_attack_style = AttackStyle.BOUNCE
		_bounce_count_max = bounce_attack_values[0]
		_bounce_damage_multiplier = bounce_attack_values[1]
	elif !splash_attack_values.is_empty():
		_attack_style = AttackStyle.SPLASH
		_splash_map = splash_attack_values

	var attack_target_type: TargetType = TowerProperties.get_attack_target_type(tower_id)
	_attack_target_type = attack_target_type

	var specials_modifier = TowerProperties.get_specials_modifier(tower_id)
	add_modifier(specials_modifier)

	_tower_behavior.init(self, _temp_preceding_tower)

#	NOTE: add aura range indicators to "visual" for correct
#	positioning on y axis.
	var range_data_list: Array[RangeData] = TowerProperties.get_range_data_list(get_id())
	_range_indicator_list = Utils.setup_range_indicators(range_data_list, _range_indicator_parent, get_player())

#	Hide all range indicators by default, they get shown
#	when mousing over ability
	for range_indicator in _range_indicator_list:
		range_indicator.visible = false

	_setup_selection_signals(_tower_selection_area)

	var sprite_dimensions: Vector2 = Utils.get_sprite_dimensions(_sprite)
	_set_unit_dimensions(sprite_dimensions)

#	NOTE: we want size of selection visual to be the same
#	for all towers. That's why we're not using sprite
#	dimensions here like for creeps.
	_set_selection_size(TOWER_SELECTION_VISUAL_SIZE)

#	Reset preceding tower var to avoid having dangling
#	reference
#	NOTE: need to reset this reference at this point and not
#	any earlier because it's used in previous operations.
	_temp_preceding_tower = null
	

# NOTE: need to do attack timing without Timer because Timer
# doesn't handle short durations well (<0.5s)
func update(delta: float):
	super.update(delta)

	if is_stunned():
		return

#	NOTE: reduce current tracked cooldown to overall
#	cooldown if overall cooldown is smaller. This handles
#	cases where tower's attack speed was significantly
#	reduced and then returns to normal.
# 
#	For example, let's say tower's attack speed gets reduced
#	by some debuff so much that the attack cooldown becomes
#	100 seconds. The debuff expires after 10 seconds and
#	tower would be doing nothing for 90 seconds. Instead of
#	that, we recalculate the cooldown so that tower can
#	start attacking normally again.
	var attack_speed: float = get_current_attack_speed()
	if _current_attack_cooldown > attack_speed:
		_current_attack_cooldown = attack_speed

	if _current_attack_cooldown > 0.0:
		_current_attack_cooldown -= delta

	if _current_attack_cooldown <= 0.0:
#		NOTE: need to update target list even if tower is
#		not attacking, to have targets for offensive
#		abilities and items.
		_update_target_list()
		
		var attack_enabled: bool = get_attack_enabled()

		var should_reset_attack_cooldown: bool
		if attack_enabled:
			should_reset_attack_cooldown = _try_to_attack()
		else:
			should_reset_attack_cooldown = true

# 		NOTE: important to add, not set! So that if game is
# 		lagging, all of the attacks fire instead of skipping.
		if should_reset_attack_cooldown:
			_current_attack_cooldown += attack_speed


#########################
###       Public      ###
#########################

func set_transform_is_allowed(value: bool):
	_transform_is_allowed = value


func get_transform_is_allowed() -> bool:
	return _transform_is_allowed


# NOTE: resetAttackCrits() in JASS
func reset_attack_crits():
	_current_crit_count = 0
	_current_crit_damage = 0.0


func set_range_indicator_visible(ability_name_english: String, value: bool):
	for range_indicator in _range_indicator_list:
		var name_match: bool = range_indicator.ability_name_english == ability_name_english
		
		if name_match:
			range_indicator.visible = value


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
	if !Utils.unit_is_valid(target):
		return

	_was_ordered_to_change_target = true
	_new_target_from_order = target


#########################
###      Private      ###
#########################

func _get_attack_ability_description() -> String:
	var tower_id: int = get_id()

	var attack_range: int = floor(TowerProperties.get_range(tower_id))
	var attack_type: AttackType.enm = TowerProperties.get_attack_type(tower_id)
	var damage_dealt_string: String = AttackType.get_rich_text_for_damage_dealt(attack_type)
	var attack_type_string: String = AttackType.convert_to_colored_string(attack_type)

	var text: String = tr("TOWER_ATTACK_ABILITY_TEXT").format({ATTACK_TYPE = attack_type_string, RANGE = attack_range, DAMAGE_TO_TEXT = damage_dealt_string})

	return text


func _do_damage_from_projectile(projectile: Projectile, target: Unit, damage: float, is_main_target: bool):
	if !Utils.unit_is_valid(target):
		return

	var crit_count: int = projectile.get_tower_crit_count()
	var crit_ratio: float = projectile.get_tower_crit_ratio()
	var emit_damage_event: bool = true

	do_attack_damage(target, damage, crit_ratio, crit_count, is_main_target, emit_damage_event)


# NOTE: this f-n does some unnecessary work in some cases
# but it's simpler this way.
# NOTE: arg needs to be untyped because it may be an invalid
# instance.
func _target_is_valid(target) -> bool:
#	NOTE: return early here, so that if unit instance is
#	invalid, we don't call f-ns on it - that would cause
#	errors
	var unit_is_valid: bool = Utils.unit_is_valid(target)
	if !unit_is_valid:
		return false

# 	NOTE: need to extend attack range by "tower radius".
# 	This is how it works in the original game.
	var attack_range: float = get_range() + Constants.RANGE_CHECK_BONUS_FOR_TOWERS
	attack_range = Utils.apply_unit_range_extension(attack_range, _attack_target_type)
	
	var in_range = VectorUtils.in_range(get_position_wc3_2d(), target.get_position_wc3_2d(), attack_range)

	var target_is_immune: bool = target.is_immune()
	var attack_type_is_arcane: bool = get_attack_type() == AttackType.enm.ARCANE
	var target_is_immune_to_attack_type: bool = target_is_immune && attack_type_is_arcane

	var target_is_valid: bool = in_range && !target_is_immune_to_attack_type

	return target_is_valid


# NOTE: change color of projectile according to tower's
# element. Note that this overrides projectile's natural color so
# will need to rework this if we decide to make separate
# projectile sprites for each element.
func _make_projectile(from_pos_base: Vector3, target: Unit) -> Projectile:
	var z_arc: float = TowerProperties.get_missile_arc(get_id())
	var from_pos: Vector3 = from_pos_base + Projectile.UNIT_Z_OFFSET
	var projectile: Projectile = Projectile.create_linear_interpolation_from_point_to_unit(_default_projectile_type, self, 0, 0, from_pos, target, z_arc, true)

	if _hide_attack_projectiles:
		projectile.hide()

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

		if !Utils.unit_is_valid(target):
			break

		var original_target: Unit = target

		var target_is_first: bool = attack_count == 0
		target = _attack_target(target, target_is_first)
		already_attacked_list.append(target)

#		NOTE: manually swap targets if target was changed
#		via issue_target_order() during _attack_target().
		var was_ordered_to_change_target: bool = original_target != target

		if was_ordered_to_change_target:
			var new_target_is_valid: bool = Utils.unit_is_valid(target)

			if new_target_is_valid:
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
# 
# 	NOTE: these variables need to be member vars instead of
# 	local vars because some ATTACK callbacks in tower
# 	scripts need to modify them.
	_current_crit_count = _generate_crit_count(0.0, 0.0)
	_current_crit_damage = _calc_attack_multicrit_from_crit_count(_current_crit_count, 0.0)

#	NOTE: emit attack event only for the "first" target so
#	that if the tower has multishot ability, the attack
#	event is emitted only once per series of attacks. This
#	is the way it works in original game.
	if target_is_first:
		var attack_event: Event = Event.new(target)
		attack_event._number_of_crits = _current_crit_count
		attack.emit(attack_event)

#	NOTE: process crit bonuses after attack event so that if
#	any attack event handlers added crit bonuses, we apply
#	these bonuses to current attack.
	_current_crit_count += _bonus_crit_count_for_next_attack
	_bonus_crit_count_for_next_attack = 0

	_current_crit_damage += _bonus_crit_ratio_for_next_attack
	_bonus_crit_ratio_for_next_attack = 0.0

#	NOTE: handlers for attack event may order the tower to
#	stop attacking or switch to a different target. Process
#	the orders here.
	if _was_ordered_to_stop_attack:
		return target

	if _was_ordered_to_change_target:
		_was_ordered_to_change_target = false

		var new_target_is_valid: bool = Utils.unit_is_valid(_new_target_from_order)
		if new_target_is_valid:
			target = _new_target_from_order

	var attacked_event: Event = Event.new(self)
	attacked_event._number_of_crits = _current_crit_count
	target.attacked.emit(attacked_event)

	var tower_pos: Vector3 = get_position_wc3()
	var projectile: Projectile = _make_projectile(tower_pos, target)
	projectile.set_tower_crit_count(_current_crit_count)
	projectile.set_tower_crit_ratio(_current_crit_damage)

#	NOTE: need to save some variables to be used later when
#	projectile reaches target
	if _attack_style == AttackStyle.BOUNCE:
		var randomize_damage: bool = true
		var damage: float = get_current_attack_damage_with_bonus(randomize_damage)
		var current_bounce_index: int = 0

		projectile.user_real = damage
		projectile.user_int = current_bounce_index
	elif _attack_style == AttackStyle.NORMAL:
		if target_is_first:
			projectile.user_int2 = 1
		else:
			projectile.user_int2 = 0

	var element: Element.enm = get_element()
	var sfx_path: String = SfxPaths.TOWER_ATTACK_MAP[element]
	var random_pitch: float = Globals.local_rng.randf_range(1.0, 1.1)
	SFX.sfx_at_unit(sfx_path, self, 0.0, random_pitch)

	return target


func _update_target_list():	
# 	NOTE: need to extend attack range by "tower radius".
# 	This is how it works in the original game.
	var attack_range: float = get_range() + Constants.RANGE_CHECK_BONUS_FOR_TOWERS

#	NOTE: get_units_in_range() is one of the most expensive
#	calls in the gameplay logic. Call it here once right
#	before attacking and no more.
	var creeps_in_range: Array = Utils.get_units_in_range(self, _attack_target_type, get_position_wc3_2d(), attack_range)

# 	NOTE: need to consider tower to be in combat if there
# 	are *any* creeps in attack range, even if the tower is
# 	not able to attack for whatever reason. This is so that
# 	towers use their offensive abilities and items as
# 	expected.
	_is_in_combat = !creeps_in_range.is_empty()

#	Remove targets that have become invalid. Targets can
#	become invalid for multiple reasons: moving out of
#	range, dying and other.
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
	Utils.sort_creep_list_for_targeting(creeps_in_range, get_position_wc3_2d())

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


func _get_next_bounce_target(bounce_pos: Vector3, visited_list: Array[Unit]) -> Creep:
	var bounce_pos_2d: Vector2 = Vector2(bounce_pos.x, bounce_pos.y)
	var creep_list: Array = Utils.get_units_in_range(self, _attack_target_type, bounce_pos_2d, Constants.BOUNCE_ATTACK_RANGE)

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
	_range_indicator_parent.visible = is_selected()


func _on_target_tree_exited(target: Creep):
	_remove_target(target)


func _on_item_container_items_changed():
	items_changed.emit()


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


# NOTE: only the first target is considered to be the "main
# target" in case of multishot. This is how it works in
# original game.
func _on_projectile_target_hit_normal(projectile: Projectile, target: Unit):
	var randomize_damage: bool = true
	var damage: float = get_current_attack_damage_with_bonus(randomize_damage)
	var target_is_first: bool = projectile.user_int2 == 1
	var is_main_target: bool = target_is_first
	
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

	var creep_list: Array = Utils.get_units_in_range(self, _attack_target_type, splash_pos, splash_range_max)

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
				var splash_is_main_target: bool = false
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

	if !Utils.unit_is_valid(next_target):
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

# Makes all future attack projectiles invisible. Useful in
# rare cases.
func hide_attack_projectiles():
	_hide_attack_projectiles = true


# This f-n changes how many targets the tower can attack at
# the same time. Note that the default value of this
# property is loaded from tower properties CSV when tower is
# created. After that, if this f-n is called from tower
# script the original value is overwritten.
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
# NOTE: for towers which don't attack, the target list is
# always empty, so treat such towers as always attacking.
# This is to ensure that items with offensive autocasts
# still get triggered when equipped on such towers.
func is_in_combat() -> bool:
	return _is_in_combat


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


func get_ability_button_data_list() -> Array[AbilityButton.Data]:
	var list: Array[AbilityButton.Data] = []

	var tower_id: int = get_id()

	var attack_enabled: bool = TowerProperties.get_attack_enabled(get_id())
	if attack_enabled:
		var attack_ability: AbilityButton.Data = AbilityButton.Data.new()
		var attack_description: String = _get_attack_ability_description()
		attack_ability.name_english = Constants.TOWER_ATTACK_ABILITY_NAME_ENGLISH
		attack_ability.ability_name = tr("TOWER_ATTACK_ABILITY_TITLE")
		attack_ability.icon = "res://resources/icons/rockets/rocket_01.tres"
		attack_ability.description_long = attack_description
		list.append(attack_ability)

	var specials_description: String = RichTexts.get_tower_specials_text(tower_id)
	if !specials_description.is_empty():
		var specials: AbilityButton.Data = AbilityButton.Data.new()
		specials.ability_name = tr("TOWER_SPECIALS_TITLE")
		specials.icon = "res://resources/icons/rockets/rocket_04.tres"
		specials.description_long = specials_description
		list.append(specials)

	if _attack_style == AttackStyle.SPLASH:
		var splash_attack: AbilityButton.Data = AbilityButton.Data.new()
		splash_attack.ability_name = tr("TOWER_SPLASH_ATTACK_TITLE")
		splash_attack.icon = "res://resources/icons/rockets/rocket_05.tres"
		var splash_attack_text: String = RichTexts.get_tower_splash_attack_text(tower_id)
		splash_attack.description_long = splash_attack_text
		list.append(splash_attack)

	if _attack_style == AttackStyle.BOUNCE:
		var bounce_attack: AbilityButton.Data = AbilityButton.Data.new()
		bounce_attack.ability_name = tr("TOWER_BOUNCE_ATTACK_TITLE")
		bounce_attack.icon = "res://resources/icons/daggers/dagger_09.tres"
		var bounce_attack_text: String = RichTexts.get_tower_bounce_attack_text(tower_id)
		bounce_attack.description_long = bounce_attack_text
		list.append(bounce_attack)

#	NOTE: need to use _target_count_from_tower without
#	adding _target_count_from_item so that item's bonus is
#	not displayed in tower info.
	if _target_count_from_tower > 1:
		var multishot: AbilityButton.Data = AbilityButton.Data.new()
		multishot.ability_name = tr("TOWER_MULTISHOT_TITLE")
		multishot.icon = "res://resources/icons/spears/many_spears_01.tres"
		var multishot_tooltip: String = RichTexts.get_tower_multishot_text(tower_id)
		multishot.description_long = multishot_tooltip
		list.append(multishot)

	return list


func get_current_target() -> Unit:
	if !_target_list.is_empty():
		var target: Unit = _target_list.front()

#		NOTE: need to check validity here because target may
#		be in list but become invalid because it just died
		if Utils.unit_is_valid(target):
			return target
		else:
			return null
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


# This is the base time between tower attacks, before
# applying modifications. Do not confuse this value with
# MOD_ATTACKSPEED.
# attack speed = time in seconds
# MOD_ATTACKSPEED = multiplier which reduces/increases the time
# NOTE: tower.getBaseAttackspeed() in JASS
func get_base_attack_speed() -> float:
	return TowerProperties.get_base_attack_speed(_id)

# This is the actual time between tower attacks, after
# applying modifications.
# Example: If the base attack speed is 2.0 seconds and the
# tower has 1.25 attack speed, then the real attack cooldown
# will be 2.0/1.25 == 1.6 seconds.
# NOTE: tower.getCurrentAttackSpeed() in JASS
func get_current_attack_speed() -> float:
	var attack_speed: float = get_base_attack_speed()
	var attack_speed_mod: float = get_attack_speed_modifier()
	var current_attack_speed: float = attack_speed / attack_speed_mod

	return current_attack_speed


func get_remaining_cooldown() -> float:
	return max(0, _current_attack_cooldown)

func get_damage_min() -> int:
	return TowerProperties.get_damage_min(_id)

func get_damage_max() -> int:
	return TowerProperties.get_damage_max(_id)

# Returns the base damage, without bonuses to base damage
# NOTE: tower.getBaseDamage() in JASS
func get_base_damage() -> int:
	return TowerProperties.get_base_damage(_id)


# NOTE: this value is sum of MOD_DAMAGE_ADD and bonus
# derived from MOD_DPS_ADD. Doesn't include
# MOD_DAMAGE_ADD_PERC.
func get_damage_add_overall() -> float:
	var damage_add: float = get_damage_add()
	var dps_bonus: float = get_dps_bonus()
	var base_attack_speed: float = get_base_attack_speed()
	var dps_mod: float = dps_bonus * base_attack_speed
	var result: float = damage_add + dps_mod

	return result


# Returns base damage, including bonuses to base damage
# NOTE: tower.getCurrentAttackDamageBase() in JASS
func get_current_attack_damage_base() -> float:
	var base_damage: float = get_base_damage()
	var base_bonus: float = get_base_damage_bonus()
	var base_bonus_percent: float = get_base_damage_bonus_percent()
	var base_damage_with_bonus: float = (base_damage + base_bonus) * base_bonus_percent

	return base_damage_with_bonus


# NOTE: by default this value is based on the average of
# tower's min and max damage. When tower is calculating
# attack damage, the randomize_damage arg is set to true so
# that this f-n returns random value between min and max.
# NOTE: tower.getCurrentAttackDamageWithBonus() in JASS
func get_current_attack_damage_with_bonus(randomize_damage: bool = false) -> float:
	var base_damage: float
	var damage_min: float = get_damage_min()
	var damage_max: float = get_damage_max()
	if randomize_damage:
		base_damage = Globals.synced_rng.randf_range(damage_min, damage_max)
	else:
		base_damage = floori((damage_min + damage_max) / 2)

	var base_bonus: float = get_base_damage_bonus()
	var base_bonus_percent: float = get_base_damage_bonus_percent()
	var damage_add_total: float = get_damage_add_overall()
	var damage_add_percent: float = get_damage_add_percent()

	var overall_base_damage: float = (base_damage + base_bonus) * base_bonus_percent
	var overall_damage: float = (overall_base_damage + damage_add_total) * damage_add_percent

	overall_damage = max(0, overall_damage)

	return overall_damage


# How much damage the tower deals with its attack per second on average (not counting in any crits). 
func get_overall_dps() -> float:
	var damage: float = get_current_attack_damage_with_bonus()
	var attack_speed: float = get_current_attack_speed()
	var dps: float = damage / attack_speed

	return dps


# How much damage the tower deals with its attack per second on average when 
# counting attack crits and multicrits.
func get_dps_with_crit() -> float:
	# Extra crit damage per successful crit:
	# if crit_damage = 1.5x, then extra = 0.5
	var extra_per_crit: float = get_prop_atk_crit_damage() - 1.0
	
	# Loop parameters
	var remaining_multicrits: int = get_prop_multicrit_count()      # M
	var current_crit_chance: float = get_prop_atk_crit_chance()     # initial p_1

	# Probability that the chain survives to stage k (P[crits ≥ k])
	var chain_prob_at_least_k: float = 1.0

	# Expected crit multiplier:
	# E[multiplier] = 1 + extra * Σ_{k=1..M} P(crits ≥ k)
	var expected_crit_multiplier: float = 1.0

	while remaining_multicrits > 0:
		# Compute effective crit probability for this stage, clamped to cap
		# and update chain -> probability of reaching at least this stage
		chain_prob_at_least_k *= clampf(current_crit_chance, 0.0, Constants.ATK_CRIT_CHANCE_CAP)

		# Add contribution of this stage
		expected_crit_multiplier += extra_per_crit * chain_prob_at_least_k

		# Prepare for next stage: diminish chance
		current_crit_chance *= Constants.ATK_MULTICRIT_DIMISHING
		remaining_multicrits -= 1

	var dps: float = get_overall_dps()
	var dps_with_crit: float = dps * crit_multiplier
	
	return dps_with_crit


# How much damage the tower dealt in total
# NOTE: getOverallDamage() in JASS, renamed to avoid confusion
func get_total_damage() -> float:
	return _damage_dealt_total

# How much damage the tower dealt in total, during last 5 min
func get_total_damage_recent() -> float:
	var total_damage_recent: float = 0
	
	var team: Team = _player.get_team()
	var current_wave_level: int = team.get_level()
	
	for i in range(current_wave_level, current_wave_level - 5, -1):
		var damage_to_wave: float = _damage_dealt_to_wave_map.get(i, 0)
		total_damage_recent += damage_to_wave
	
	return total_damage_recent

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
	var sprite_parent_node: Node2D = tower.get_node("Visual/SpriteParent")
	
	if visual_node == null:
		push_error("visual node is null")
		
		return null

	sprite_parent_node.add_child(tower_sprite)
	tower._sprite = tower_sprite
	
	tower._temp_preceding_tower = preceding_tower

	tower.set_id(id)
	tower.set_player(player)

	return tower
