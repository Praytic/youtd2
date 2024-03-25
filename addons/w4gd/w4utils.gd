extends RefCounted
class_name W4Utils

## Internal class used internally to generate v4 UUIDs.
class UUIDGenerator extends RefCounted:
	var crypto := Crypto.new()
	var rng := RandomNumberGenerator.new()

	func generate_v4() -> String:
		var b := PackedByteArray()
		if crypto == null:
			b.resize(16)
			for i in range(16):
				b[i] = rng.randi() % 256
		else:
			b = crypto.generate_random_bytes(16)
		b[6] = (b[6] & 0x0f) | 0x40
		b[8] = (b[8] & 0x3f) | 0x80
		return "%02x%02x%02x%02x-%02x%02x-%02x%02x-%02x%02x-%02x%02x%02x%02x%02x%02x" % [
			b[0], b[1], b[2], b[3],
			b[4], b[5],
			b[6], b[7],
			b[8], b[9],
			b[10], b[11], b[12], b[13], b[14], b[15],
		]
