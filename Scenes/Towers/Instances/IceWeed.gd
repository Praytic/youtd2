extends Tower


func _init_tower():
	var frozen_thorn_buff = FrozenThorn.new(125, 5)
	frozen_thorn_buff.apply_to_unit_permanent(self, self, 0, false)
