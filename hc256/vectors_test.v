import hc256

fn test_vectors () {
    key := [8]u32{}
    iv := [8]u32{}
    mut data := [16]u32{}

    mut h := hc256.Hc256{}
    h.seed(key, iv)
    h.encrypt(mut data)

    assert data[0] == 2240350043
    assert data[15] == 2171174450
}
