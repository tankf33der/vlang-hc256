module hc256

import math.bits

pub struct Hc256 {
mut:
	p           [1024]u32
	q           [1024]u32
	x           [16]u32
	y           [16]u32
	used        int = -1
	state       [16]u32
	counter2048 u32
}

// Helpers for initialization()
@[direct_array_access; inline]
fn f1(x u32) u32 {
	return bits.rotate_left_32(x, -7) ^ bits.rotate_left_32(x, -18) ^ (x >> 3)
}

@[direct_array_access; inline]
fn f2(x u32) u32 {
	return bits.rotate_left_32(x, -17) ^ bits.rotate_left_32(x, -19) ^ (x >> 10)
}

@[direct_array_access; inline]
fn f(a u32, b u32, c u32, d u32) u32 {
	return f2(a) + b + f1(c) + d
}

@[direct_array_access; inline]
fn (mut h Hc256) feedback_1(mut u &u32, v u32, b u32, c u32) {
	mut temp0 := bits.rotate_left_32(v, -23)
	mut temp1 := bits.rotate_left_32(c, -10)
	mut temp2 := (v ^ c) & 0x3ff
	u[0] += b + (temp0 ^ temp1) + h.q[temp2]
}

@[direct_array_access; inline]
fn (mut h Hc256) feedback_2(mut u &u32, v u32, b u32, c u32) {
	mut temp0 := bits.rotate_left_32(v, -23)
	mut temp1 := bits.rotate_left_32(c, -10)
	mut temp2 := (v ^ c) & 0x3ff
	u[0] += b + (temp0 ^ temp1) + h.p[temp2]
}

// Helpers for encrypt()
@[direct_array_access; inline]
fn (mut h Hc256) h1(x u32, mut y &u32) {
	mut a := int(u8(x))
	mut b := int(u8(x >> 8))
	mut c := int(u8(x >> 16))
	mut d := int(u8(x >> 24))
	y = h.q[a] + h.q[256 + b] + h.q[512 + c] + h.q[768 + d]
}

@[direct_array_access; inline]
fn (mut h Hc256) h2(x u32, mut y &u32) {
	mut a := int(u8(x))
	mut b := int(u8(x >> 8))
	mut c := int(u8(x >> 16))
	mut d := int(u8(x >> 24))
	y = h.p[a] + h.p[256 + b] + h.p[512 + c] + h.p[768 + d]
}

@[direct_array_access; inline]
fn (mut h Hc256) step_a(mut u &u32, v u32, mut a &u32, b u32, c u32, d u32, mut m &u32) {
	mut temp0 := bits.rotate_left_32(v, -23)
	mut temp1 := bits.rotate_left_32(c, -10)
	mut temp2 := (v ^ c) & 0x3ff
	mut temp3 := u32(0)
	u[0] += b + (temp0 ^ temp1) + h.q[temp2]
	a[0] = u[0]
	h.h1(d, mut &temp3)
	m[0] ^= temp3 ^ u[0]
}

@[direct_array_access; inline]
fn (mut h Hc256) step_b(mut u &u32, v u32, mut a &u32, b u32, c u32, d u32, mut m &u32) {
	mut temp0 := bits.rotate_left_32(v, -23)
	mut temp1 := bits.rotate_left_32(c, -10)
	mut temp2 := (v ^ c) & 0x3ff
	mut temp3 := u32(0)
	u[0] += b + (temp0 ^ temp1) + h.p[temp2]
	a[0] = u[0]
	h.h2(d, mut &temp3)
	m[0] ^= temp3 ^ u[0]
}

pub fn (mut h Hc256) seed(key []u32, iv []u32) {
	for i := 0; i < 8; i++ {
		h.p[i] = key[i]
	}
	for i := 8; i < 16; i++ {
		h.p[i] = iv[i - 8]
	}
	for i := u32(16); i < 528; i++ {
		h.p[i] = f(h.p[i - 2], h.p[i - 7], h.p[i - 15], h.p[i - 16]) + i
	}
	for i := 0; i < 16; i++ {
		h.p[i] = h.p[i + 512]
	}
	for i := u32(16); i < 1024; i++ {
		h.p[i] = f(h.p[i - 2], h.p[i - 7], h.p[i - 15], h.p[i - 16]) + 512 + i
	}
	for i := 0; i < 16; i++ {
		h.q[i] = h.p[1024 - 16 + i]
	}
	for i := u32(16); i < 32; i++ {
		h.q[i] = f(h.q[i - 2], h.q[i - 7], h.q[i - 15], h.q[i - 16]) + 1520 + i
	}
	for i := 0; i < 16; i++ {
		h.q[i] = h.q[i + 16]
	}
	for i := u32(16); i < 1024; i++ {
		h.q[i] = f(h.q[i - 2], h.q[i - 7], h.q[i - 15], h.q[i - 16]) + 1536 + i
	}
	// run the cipher 4096 steps without generating output
	for i := 0; i < 2; i++ {
		for j := 0; j < 10; j++ {
			h.feedback_1(mut &h.p[j], h.p[j + 1], h.p[(j - 10) & 0x3ff], h.p[(j - 3) & 0x3ff])
		}
		for j := 10; j < 1023; j++ {
			h.feedback_1(mut &h.p[j], h.p[j + 1], h.p[j - 10], h.p[j - 3])
		}
		h.feedback_1(mut &h.p[1023], h.p[0], h.p[1013], h.p[1020])

		for j := 0; j < 10; j++ {
			h.feedback_2(mut &h.q[j], h.q[j + 1], h.q[(j - 10) & 0x3ff], h.q[(j - 3) & 0x3ff])
		}
		for j := 10; j < 1023; j++ {
			h.feedback_2(mut &h.q[j], h.q[j + 1], h.q[j - 10], h.q[j - 3])
		}
		h.feedback_2(mut &h.q[1023], h.q[0], h.q[1013], h.q[1020])
	}
	h.counter2048 = 0
	for i := 0; i < 16; i++ {
		h.x[i] = h.p[1008 + i]
	}
	for i := 0; i < 16; i++ {
		h.y[i] = h.q[1008 + i]
	}
	h.used = 0
	h.shuffle()
}

fn (mut h Hc256) shuffle() {
	cc := h.counter2048 & 0x3ff
	dd := (cc + 16) & 0x3ff
	if h.counter2048 < 1024 {
		h.counter2048 = (h.counter2048 + u32(16)) & 0x7ff
		h.step_a(mut &h.p[cc + 0], h.p[cc + 1], mut &h.x[0], h.x[6], h.x[13], h.x[4], mut
			&h.state[0])
		h.step_a(mut &h.p[cc + 1], h.p[cc + 2], mut &h.x[1], h.x[7], h.x[14], h.x[5], mut
			&h.state[1])
		h.step_a(mut &h.p[cc + 2], h.p[cc + 3], mut &h.x[2], h.x[8], h.x[15], h.x[6], mut
			&h.state[2])
		h.step_a(mut &h.p[cc + 3], h.p[cc + 4], mut &h.x[3], h.x[9], h.x[0], h.x[7], mut
			&h.state[3])
		h.step_a(mut &h.p[cc + 4], h.p[cc + 5], mut &h.x[4], h.x[10], h.x[1], h.x[8], mut
			&h.state[4])
		h.step_a(mut &h.p[cc + 5], h.p[cc + 6], mut &h.x[5], h.x[11], h.x[2], h.x[9], mut
			&h.state[5])
		h.step_a(mut &h.p[cc + 6], h.p[cc + 7], mut &h.x[6], h.x[12], h.x[3], h.x[10], mut
			&h.state[6])
		h.step_a(mut &h.p[cc + 7], h.p[cc + 8], mut &h.x[7], h.x[13], h.x[4], h.x[11], mut
			&h.state[7])
		h.step_a(mut &h.p[cc + 8], h.p[cc + 9], mut &h.x[8], h.x[14], h.x[5], h.x[12], mut
			&h.state[8])
		h.step_a(mut &h.p[cc + 9], h.p[cc + 10], mut &h.x[9], h.x[15], h.x[6], h.x[13], mut
			&h.state[9])
		h.step_a(mut &h.p[cc + 10], h.p[cc + 11], mut &h.x[10], h.x[0], h.x[7], h.x[14], mut
			&h.state[10])
		h.step_a(mut &h.p[cc + 11], h.p[cc + 12], mut &h.x[11], h.x[1], h.x[8], h.x[15], mut
			&h.state[11])
		h.step_a(mut &h.p[cc + 12], h.p[cc + 13], mut &h.x[12], h.x[2], h.x[9], h.x[0], mut
			&h.state[12])
		h.step_a(mut &h.p[cc + 13], h.p[cc + 14], mut &h.x[13], h.x[3], h.x[10], h.x[1], mut
			&h.state[13])
		h.step_a(mut &h.p[cc + 14], h.p[cc + 15], mut &h.x[14], h.x[4], h.x[11], h.x[2], mut
			&h.state[14])
		h.step_a(mut &h.p[cc + 15], h.p[dd + 0], mut &h.x[15], h.x[5], h.x[12], h.x[3], mut
			&h.state[15])
	} else {
		h.counter2048 = (h.counter2048 + u32(16)) & 0x7ff
		h.step_b(mut &h.q[cc + 0], h.q[cc + 1], mut &h.y[0], h.y[6], h.y[13], h.y[4], mut
			&h.state[0])
		h.step_b(mut &h.q[cc + 1], h.q[cc + 2], mut &h.y[1], h.y[7], h.y[14], h.y[5], mut
			&h.state[1])
		h.step_b(mut &h.q[cc + 2], h.q[cc + 3], mut &h.y[2], h.y[8], h.y[15], h.y[6], mut
			&h.state[2])
		h.step_b(mut &h.q[cc + 3], h.q[cc + 4], mut &h.y[3], h.y[9], h.y[0], h.y[7], mut
			&h.state[3])
		h.step_b(mut &h.q[cc + 4], h.q[cc + 5], mut &h.y[4], h.y[10], h.y[1], h.y[8], mut
			&h.state[4])
		h.step_b(mut &h.q[cc + 5], h.q[cc + 6], mut &h.y[5], h.y[11], h.y[2], h.y[9], mut
			&h.state[5])
		h.step_b(mut &h.q[cc + 6], h.q[cc + 7], mut &h.y[6], h.y[12], h.y[3], h.y[10], mut
			&h.state[6])
		h.step_b(mut &h.q[cc + 7], h.q[cc + 8], mut &h.y[7], h.y[13], h.y[4], h.y[11], mut
			&h.state[7])
		h.step_b(mut &h.q[cc + 8], h.q[cc + 9], mut &h.y[8], h.y[14], h.y[5], h.y[12], mut
			&h.state[8])
		h.step_b(mut &h.q[cc + 9], h.q[cc + 10], mut &h.y[9], h.y[15], h.y[6], h.y[13], mut
			&h.state[9])
		h.step_b(mut &h.q[cc + 10], h.q[cc + 11], mut &h.y[10], h.y[0], h.y[7], h.y[14], mut
			&h.state[10])
		h.step_b(mut &h.q[cc + 11], h.q[cc + 12], mut &h.y[11], h.y[1], h.y[8], h.y[15], mut
			&h.state[11])
		h.step_b(mut &h.q[cc + 12], h.q[cc + 13], mut &h.y[12], h.y[2], h.y[9], h.y[0], mut
			&h.state[12])
		h.step_b(mut &h.q[cc + 13], h.q[cc + 14], mut &h.y[13], h.y[3], h.y[10], h.y[1], mut
			&h.state[13])
		h.step_b(mut &h.q[cc + 14], h.q[cc + 15], mut &h.y[14], h.y[4], h.y[11], h.y[2], mut
			&h.state[14])
		h.step_b(mut &h.q[cc + 15], h.q[dd + 0], mut &h.y[15], h.y[5], h.y[12], h.y[3], mut
			&h.state[15])
	}
}

pub fn (mut h Hc256) u32() !u32 {
	if h.used == -1 {
		return error('no seed')
	}
	if h.used == 16 {
		h.shuffle()
		h.used = 0
	}
	defer {
		h.used++
	}
	return h.state[h.used]
}

@[unsafe]
pub fn (mut h Hc256) free() {
	unsafe { free(h) }
}
