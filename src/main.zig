const std = @import("std");
const heap = @import("std").heap;
const print = @import("std").debug.print;
const bint = @import("std").math.big.int;

pub fn main() anyerror!void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    const p = try Polly.init(allocator);

    print("{}\n", .{p.p});
    print("{}\n", .{p.clamper});

    var key = [_]u8{
        0x85, 0xd6, 0xbe, 0x78,
        0x57, 0x55, 0x6d, 0x33,
        0x7f, 0x44, 0x52, 0xfe,
        0x42, 0xd5, 0x06, 0xa8,
        0x01, 0x03, 0x80, 0x8a,
        0xfb, 0x0d, 0xb2, 0xfd,
        0x4a, 0xbf, 0xf6, 0xaf,
        0x41, 0x49, 0xf5, 0x1b,
    };
    var msg = [_]u8{
        0x43, 0x72, 0x79, 0x70, 0x74, 0x6f, 0x67, 0x72,
        0x61, 0x70, 0x68, 0x69, 0x63, 0x20, 0x46, 0x6f,
        0x72, 0x75, 0x6d, 0x20, 0x52, 0x65, 0x73, 0x65,
        0x61, 0x72, 0x63, 0x68, 0x20, 0x47, 0x72, 0x6f,
        0x75, 0x70,
    };
    try p.mac(allocator, &msg, &key);

    // var x = try bint.Managed.init(allocator);
    // // var base = try bint.Managed.initSet(allocator, 256);
    // try x.set(0);
    // for (input) |i| {
    //     //  print("{}\n", .{i});
    //     var ii = try bint.Managed.initSet(allocator, i);
    //     // try x.mul(&x, &base);
    //     try x.shiftLeft(&x, 8);
    //     try x.add(&x, &ii);
    //     //  print("{}:{} {}\n", .{i, ii, x});
    // }
    // print("{}\n", .{x});
    // // print("{}\n", .{std.mem.reverse(u8, &input)});
    // print("{any}\n", .{input});
    // // p.mac(allocator, &input, &input);
    // var xx: [16]u8 = undefined;
    // std.mem.copy(u8, &xx, input[0..3]);
    // print("{any}\n", .{xx});
}

const Polly = struct {
    p: bint.Managed,
    clamper: bint.Managed,

    fn init(allocator: std.mem.Allocator) anyerror!Polly {
        return Polly{
            .p = try p(allocator),
            .clamper = try clamper(allocator),
        };
    }

    fn p(allocator: std.mem.Allocator) anyerror!bint.Managed {
        var b = try bint.Managed.initSet(allocator, 2);
        var m = try bint.Managed.init(allocator);
        try m.pow(&b, 130);
        var x = try bint.Managed.initSet(allocator, 5);
        try m.sub(&m, &x);
        return m;
    }

    fn clamper(allocator: std.mem.Allocator) anyerror!bint.Managed {
        return try bint.Managed.initSet(allocator, 0x0ffffffc0ffffffc0ffffffc0fffffff);
    }

    fn mac(self: Polly, allocator: std.mem.Allocator, msg: []u8, key: []u8) anyerror!void {
        var rr = key[0..16];
        std.mem.reverse(u8, rr);
        var r = try toInt(allocator, rr);

        try r.bitAnd(&r, &self.clamper);

        var ss = key[16..32];
        std.mem.reverse(u8, ss);
        var s = try toInt(allocator, ss);

        print("r={x}\n", .{r});
        print("s={x}\n", .{s});

        var acc = try bint.Managed.init(allocator);

        var m = msg;
        var nnn: [17]u8 = undefined;
        while (m.len > 0) {
            var e: usize = 16;
            if (m.len < e) {
                e = m.len;
            }
            std.mem.copy(u8, &nnn, m[0..e]);
            nnn[e] = 0x01;
            std.mem.reverse(u8, nnn[0 .. e + 1]);
            var n = try toInt(allocator, nnn[0 .. e + 1]);

            try acc.add(&acc, &n);
            print("=============\n", .{});
            print("n={x}\n", .{n});
            print("acc={x}\n", .{acc});
            try acc.mul(&acc, &r);
            print("acc={x}\n", .{acc});
            try acc.divFloor(&acc, &acc, &self.p);
            print("acc={x}\n", .{acc});
            print("=============\n", .{});

            m = m[e..];
        }
        try acc.add(&acc, &s);
        var str = try acc.toString(allocator, 16, std.fmt.Case.lower);
        print("acc={s}\n", .{str});
        std.mem.reverse(u8, str);
        print("acc={s}\n", .{str});
        str = str[0..16];
        print("acc={s}\n", .{str});
        //末尾16byte取得してリトルエンディアンで読む
    }
};

test "init polly" {
    try std.testing.expectEqual(10, 3 + 7);
}

fn toInt(allocator: std.mem.Allocator, input: []u8) anyerror!bint.Managed {
    var x = try bint.Managed.init(allocator);
    // var base = try bint.Managed.initSet(allocator, 256);
    try x.set(0);
    for (input) |i| {
        //  print("{}\n", .{i});
        var ii = try bint.Managed.initSet(allocator, i);
        // try x.mul(&x, &base);
        try x.shiftLeft(&x, 8);
        try x.add(&x, &ii);
        //  print("{}:{} {}\n", .{i, ii, x});
    }
    return x;
}

fn toLittle(input: []u8) []u8 {
    if (input.len == 0) {
        return input;
    }
    // std.builtin.Endian
    var s: usize = 0;
    var e: usize = input.len - 1;
    while (s < e) {
        const tmp = input[s];
        input[s] = input[e];
        input[e] = tmp;
        s += 1;
        e -= 1;
    }

    return input;
}

test "to little endian" {
    {
        var input = [_]u8{};
        try std.testing.expectEqualSlices(u8, toLittle(&input), &[_]u8{});
    }
    {
        var input = [_]u8{0x32};
        try std.testing.expectEqualSlices(u8, toLittle(&input), &[_]u8{0x32});
    }
    {
        var input = [_]u8{ 0x12, 0x34 };
        try std.testing.expectEqualSlices(u8, toLittle(&input), &[_]u8{ 0x34, 0x12 });
    }
}
