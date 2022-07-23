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

    fn innerBlock(self: *State) void {
        // column rounds
        self.quarterRound(0, 4, 8, 12);
        self.quarterRound(1, 5, 9, 13);
        self.quarterRound(2, 6, 10, 14);
        self.quarterRound(3, 7, 11, 15);

        // diagonal rounds
        self.quarterRound(0, 5, 10, 15);
        self.quarterRound(1, 6, 11, 12);
        self.quarterRound(2, 7, 8, 13);
        self.quarterRound(3, 4, 9, 14);
    }

    fn quarterRound(self: *State, a: usize, b: usize, c: usize, d: usize) void {
        self.operation(a, b, d, 16);
        self.operation(c, d, b, 12);
        self.operation(a, b, d, 8);
        self.operation(c, d, b, 7);
    }

    fn operation(self: *State, x: usize, y: usize, z: usize, shift: u5) void {
        self.s[x] +%= self.s[y];
        self.s[z] ^= self.s[x];

        self.s[z] = (self.s[z]>>(31-shift+1)) | self.s[z] << shift;
    }

    fn add(self: *State, other: State) void {
        // const l = self.s.len;
        // while (i < l) : (i += 1) {
        //     self.s[i] += other.s[i];
        // }
        for (self.s) |*s, i| {
            s.* +%= other.s[i];
        }
    }

    fn clone(self: State) State {
        var s: [16]u32 = undefined;
        std.mem.copy(u32, s[0..], self.s[0..]);
        return State{ .s = s };
    }
};

fn block(key: [32]u8, nonce: [12]u8, counter: u32) [64]u8 {
    // debug.print("\n", .{});
    var s = State.init(key, nonce, counter);
    // debug.print("init\t={x}\n", .{s.s});
    const init = s.clone();
    // debug.print("init\t={x}\n", .{init.s});

    comptime var i = 0;
    inline while (i < 10) : (i += 1) {
        s.innerBlock();
    }
    // debug.print("loop\t={x}\n", .{s.s});
    s.add(init);
    // debug.print("last\t={x}\n", .{s.s});
    return @bitCast([64]u8, s.s);
}

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

test "chacha.state quarterRound" {
    // inline for (.{})|tc|{}
    var key: [32]u8 = undefined;
    var nonce: [12]u8 = undefined;
    var s = State.init(key, nonce, 1);
    s.s = [_]u32{
        0x879531e0, 0xc5ecf37d, 0x516461b1, 0xc9a62f8a,
        0x44c20ef3, 0x3390af7f, 0xd9fc690b, 0x2a5f714c,
        0x53372767, 0xb00a5631, 0x974c541a, 0x359e9963,
        0x5c971061, 0x3d631689, 0x2098d9d6, 0x91dbd320,
    };

    s.quarterRound(2, 7, 8, 13);

    var want = [_]u32{
        0x879531e0, 0xc5ecf37d, 0xbdb886dc, 0xc9a62f8a,
        0x44c20ef3, 0x3390af7f, 0xd9fc690b, 0xcfacafd2,
        0xe46bea80, 0xb00a5631, 0x974c541a, 0x359e9963,
        0x5c971061, 0xccc07c79, 0x2098d9d6, 0x91dbd320,
    };

    try std.testing.expectEqualSlices(u32, &want, &s.s);
}

test "chacha.block" {
    inline for (.{
        .{
            .key = [_]u8{
                0x00, 0x01, 0x02, 0x03,
                0x04, 0x05, 0x06, 0x07,
                0x08, 0x09, 0x0a, 0x0b,
                0x0c, 0x0d, 0x0e, 0x0f,
                0x10, 0x11, 0x12, 0x13,
                0x14, 0x15, 0x16, 0x17,
                0x18, 0x19, 0x1a, 0x1b,
                0x1c, 0x1d, 0x1e, 0x1f,
            },
            .nonce = [_]u8{
                0x00, 0x00, 0x00, 0x09,
                0x00, 0x00, 0x00, 0x4a,
                0x00, 0x00, 0x00, 0x00,
            },
            .counter = 1,
            .want = [_]u8{
                0x10, 0xf1, 0xe7, 0xe4, 0xd1, 0x3b, 0x59, 0x15, 0x50, 0x0f, 0xdd, 0x1f, 0xa3, 0x20, 0x71, 0xc4, //.....;Y.P.... q.
                0xc7, 0xd1, 0xf4, 0xc7, 0x33, 0xc0, 0x68, 0x03, 0x04, 0x22, 0xaa, 0x9a, 0xc3, 0xd4, 0x6c, 0x4e, //....3.h.."....lN
                0xd2, 0x82, 0x64, 0x46, 0x07, 0x9f, 0xaa, 0x09, 0x14, 0xc2, 0xd7, 0x05, 0xd9, 0x8b, 0x02, 0xa2, //..dF............
                0xb5, 0x12, 0x9c, 0xd1, 0xde, 0x16, 0x4e, 0xb9, 0xcb, 0xd0, 0x83, 0xe8, 0xa2, 0x50, 0x3c, 0x4e, //......N......P<N
            },
        },
    }) |tc| {
        var got = block(tc.key, tc.nonce, tc.counter);

        // debug.print("\n", .{});
        // // debug.print("got={x}\n", .{std.fmt.fmtSliceHexLower(&got)});
        // // debug.print("tc.want={x}\n", .{std.fmt.fmtSliceHexLower(&tc.want)});
        // debug.print("got={any}\n", .{got});
        // debug.print("tc.want={any}\n", .{tc.want});
        try std.testing.expectEqualSlices(u8, &got, &tc.want);
    }
}
