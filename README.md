Vlang implementation of HC-256 crypto RNG.

PracRand says (copy-paste):
```
HC256 is the highest quality recommended RNG and the most cryptographically secure.
Its biggest drawback is slow seeding time. It's also a little slow and a bit large,
but not so much of either of those as to hinder usability for typical purposes.

	actual name: HC-256 (not sure what that stands for)
	This algorithm is included because it is believed to be quite
	cryptographically secure.  It is a bit slow and rather heavy-weight,
	but it has excellent statistical properties and security.
	This RNG uses buffered output, so some calls to it take much longer
	than other calls to it.
	This algorithm is believed to have no bad cycles.
	--
	Basically, it's a very large high quality variant of a fibonacci-style
	RNG, with a little extra indirection-based stuff added.  It's all set
	up in a way that looks optimized for provability.
	--
	details:
		quality subscores (scored from 0 to 5 stars):
			empirical:     5?
			cycle length:  5
			statespace:    5
			trusted:       5
			overall:       5
		speed:            slow
		operations used:  addition, bitwise, fixed shifts, arrays
		full word output: yes
		buffered:         yes
		random access:    no
		entropy pooling:  no
		crypto security:  strong
		minimum cycle:    none (probably no bad cycles)
		word size:        32 bit
		size:             8580 bytes
		statespace:       2**65547
		multi-cyclic:     yes
		reversible:       yes?
```

My example of usage:
```v
import os
import tankf33der.hc256

fn main() {
        mut rng := hc256.Hc256{}
    	mut key := []u32{}
    	mut iv  := []u32{}
    	mut f   := os.open("/dev/urandom")!
    	for _ in 0..8 {
        	key << f.read_le[u32]()!
        	iv  << f.read_le[u32]()!
    	}
    	rng.seed(key, iv)
    	for _ in 0..5 {
        	println(rng.u32()!)
    	}
    	unsafe { rng.free() }
    	f.close()
}
```

Public API:
```v
module hc256

struct Hc256 {
mut:
        p           [1024]u32
        q           [1024]u32
        x           [16]u32
        y           [16]u32
        used        int = -1
        state       [16]u32
        counter2048 u32
}
fn (mut h Hc256) seed(key []u32, iv []u32)
fn (mut h Hc256) u32() !u32
fn (mut h Hc256) free()
```
