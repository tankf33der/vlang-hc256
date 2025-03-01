import hc256

fn test_vectors () {
    key := [8]u32
     iv := [8]u32

    h := hc256.Hc256{}
    h.initialization(key, iv)
}
