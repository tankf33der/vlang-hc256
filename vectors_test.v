module hc256

fn test_vectors() {
	mut key := []u32{len: 8}
	mut iv := []u32{len: 8}

	mut h := hc256.Hc256{}
	h.seed(key, iv)
	assert h.u32()! == 2240350043
	for _ in 0 .. 14 {
		h.u32()!
	}
	assert h.u32()! == 2171174450
	assert h.u32()! == 3134664310
	unsafe { h.free() }

	h = hc256.Hc256{}
	iv[0] = 1
	h.seed(key, iv)
	assert h.u32()! == 3215123119
	unsafe { h.free() }

	h = hc256.Hc256{}
	iv[0] = 0
	key[0] = 0x55
	h.seed(key, iv)
	assert h.u32()! == 4266278940
	unsafe { h.free() }
}

fn test_long() {
	mut key := []u32{len: 8}
	mut iv := []u32{len: 8}

	mut h := hc256.Hc256{}
	h.seed(key, iv)
	for _ in 0..160000 {
		h.u32()!
	}
	assert h.u32()! == 1178169499
}
