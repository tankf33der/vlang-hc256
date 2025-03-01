module hc256

import math.bits

pub struct Hc256 {
mut:
    p               [1024]u32
    q               [1024]u32
    x               [16]u32
    y               [16]u32
    counter2048     u32
}

@[inline]
fn f1 (x u32) u32 {
    res := bits.rotate_left_32(x, -7) ^ bits.rotate_left_32(x, -18) ^ bits.rotate_left_32(x, -3)
    return res
}

@[inline]
fn f2 (x u32) u32 {
    res := bits.rotate_left_32(x, -17) ^ bits.rotate_left_32(x, -19) ^ bits.rotate_left_32(x, -10)
    return res
}

@[inline]
fn f (a u32, b u32, c u32, d u32) u32 {
    res := f2(a) + b + f1(c) + d
    return res
}

@[inline]
fn (mut h Hc256) feedback_1(mut u[] u32, v u32, b u32, c u32) {
    mut temp0 := u32(0)
    mut temp1 := u32(0)
    mut temp2 := u32(0)

    temp0 = bits.rotate_left_32(v, -23)
    temp1 = bits.rotate_left_32(c, -10)
    temp2 = (v ^ c) & 0x3ff
    u[0] += b + (temp0 ^ temp1) + h.q[temp2]
}

@[inline]
fn (mut h Hc256) feedback_2(mut u[] u32, v u32, b u32, c u32) {
    mut temp0 := u32(0)
    mut temp1 := u32(0)
    mut temp2 := u32(0)

    temp0 = bits.rotate_left_32(v, -23)
    temp1 = bits.rotate_left_32(c, -10)
    temp2 = (v ^ c) & 0x3ff
    u[0] += b + (temp0 ^ temp1) + h.p[temp2]
}


pub fn (mut h Hc256) initialization(key [8]u32, iv [8]u32) {
    for i := 0; i < 8;  i++ { h.p[i] = key[i] }
    for i := 8; i < 16; i++ { h.p[i] =  iv[i-8] }

    for i := u32(16); i < 528; i++ {
        h.p[i] = f(h.p[i-2],h.p[i-7],h.p[i-15],h.p[i-16])+i
    }
    for i := 0; i < 16; i++ {
        h.p[i] = h.p[i+512]
    }
    for i := u32(16); i < 1024; i++ {
        h.p[i] = f(h.p[i-2],h.p[i-7],h.p[i-15],h.p[i-16])+512+i
    }

    for i := 0; i < 16; i++ {
        h.q[i] = h.p[1024-16+i]
    }
    for i := u32(16); i < 32; i++ {
        h.q[i] = f(h.q[i-2],h.q[i-7],h.q[i-15],h.q[i-16])+1520+i
    }
    for i := 0; i < 16; i++ {
        h.q[i] = h.q[i+16]
    }
    for i := u32(16); i < 1024; i++ {
        h.q[i] = f(h.q[i-2],h.q[i-7],h.q[i-15],h.q[i-16])+1536+i
    }

    //run the cipher 4096 steps without generating output
    for i := 0; i < 2; i++ {
        for j := 0; j < 10; j++ {
            h.feedback_1(mut h.p[j..],h.p[j+1],h.p[(j-10)&0x3ff],h.p[(j-3)&0x3ff])
        }
        for j := 10; j < 1023; j++ {
            t := int(1023)

            h.feedback_1(mut h.p[j..],h.p[j+1],h.p[j-10],h.p[j-3])
            h.feedback_1(mut h.p[t..],h.p[0],h.p[1013],h.p[1020])
        }
        for j := 0; j < 10; j++ {
            h.feedback_2(mut h.q[j..],h.q[j+1],h.q[(j-10)&0x3ff],h.q[(j-3)&0x3ff])
        }
        for j := 10; j < 1023; j++ {
            t := int(1023)

            h.feedback_2(mut h.q[j..],h.q[j+1],h.q[j-10],h.q[j-3])
            h.feedback_2(mut h.q[t..],h.q[0],h.q[1013],h.q[1020])
        }
    }

    h.counter2048 = 0
    for i := 0; i < 16; i++ { h.x[i] = h.p[1008+i] }
    for i := 0; i < 16; i++ { h.y[i] = h.q[1008+i] }
}
