import hc256

fn test_vectors () {
    mut key := []u32{}
    mut iv := [8]u32{}
    mut data := [16]u32{}
    mut rng32 := u32(0)

    mut h := hc256.Hc256{}
    h.seed(key, iv)
    rng32 = h.u32()
    assert rng32 == 2240350043

    /*
    assert data[0] == 2240350043
    assert data[15] == 2171174450
    h.free()

    for i in 0 .. data.len {
        data[i] = 0
    }
    h = hc256.Hc256{}
    iv[0] = 1
    h.seed(key, iv)
    h.encrypt(mut data)
    assert data[0] == 3215123119
    h.free()

    for i in 0 .. data.len {
        data[i] = 0
    }
    h = hc256.Hc256{}
    iv[0] = 0
    key[0] = 0x55
    h.seed(key, iv)
    h.encrypt(mut data)
    assert data[0] == 4266278940
    h.free()

*/

}
