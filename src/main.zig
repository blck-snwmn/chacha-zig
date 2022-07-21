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

    print("{}\n", .{std.mem.readIntSliceLittle([]u8, &[_]u8{ 0xfc, 0xff })});
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

    // fn mac(self: Polly, allocator: std.mem.Allocator, msg: []u8, key: []u8) void {}
};

// fn swap()void{
//     // std.builtin.Endian
//     std.mem.
// }

test "basic test" {
    try std.testing.expectEqual(10, 3 + 7);
}
