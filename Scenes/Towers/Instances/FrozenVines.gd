extends Tower


func _init_tower():
	var frozen_thorn_buff = FrozenThorn.new(750, 30)
	frozen_thorn_buff.apply_to_unit_permanent(self, self, 0, false)
