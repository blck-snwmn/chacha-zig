const std = @import("std");
const debug = std.debug;

const State = struct {
    s: [16]u32,
    fn init(key: [32]u8, nonce: [12]u8, counter: u32) State {
        var s: [16]u32 = undefined;
        // magic
        s[0] = 0x61707865;
        s[1] = 0x3320646e;
        s[2] = 0x79622d32;
        s[3] = 0x6b206574;

        var pkey = @bitCast([8]u32, key);
        // std.mem.reverse(u32, &pkey); // little endian only
        std.mem.copy(u32, s[4..12], pkey[0..]);

        s[12] = counter;

        var pnonce = @bitCast([3]u32, nonce);
        // std.mem.reverse(u32, &pnonce); // little endian only
        std.mem.copy(u32, s[13..16], pnonce[0..]);

        return State{ .s = s };
    }
};

test "chacha.state init" {
    // inline for (.{})|tc|{}
    var key = [_]u8{
        0x00, 0x01, 0x02, 0x03, 0x04, 0x05, 0x06, 0x07,
        0x08, 0x09, 0x0a, 0x0b, 0x0c, 0x0d, 0x0e, 0x0f,
        0x10, 0x11, 0x12, 0x13, 0x14, 0x15, 0x16, 0x17,
        0x18, 0x19, 0x1a, 0x1b, 0x1c, 0x1d, 0x1e, 0x1f,
    };
    var nonce = [_]u8{
        0x00, 0x00, 0x00, 0x09,
        0x00, 0x00, 0x00, 0x4a,
        0x00, 0x00, 0x00, 0x00,
    };
    var s = State.init(key, nonce, 1);
    var want = State{ .s = [_]u32{
        0x61707865, 0x3320646e, 0x79622d32, 0x6b206574,
        0x03020100, 0x07060504, 0x0b0a0908, 0x0f0e0d0c,
        0x13121110, 0x17161514, 0x1b1a1918, 0x1f1e1d1c,
        0x00000001, 0x09000000, 0x4a000000, 0x00000000,
    } };
    try std.testing.expectEqual(s, want);
}
