const Self = @This();
const std = @import("std");
const Allocator = std.mem.Allocator;
const ArrayList = std.ArrayList;

sessions: ArrayList(Session),

pub const Session = struct {
    id: []const u8,
};

pub fn init(allocator: Allocator) !Self {
    return .{
        .sessions = ArrayList(Session).init(allocator),
    };
}

pub fn deinit(self: *Self) !void {
    self.sessions.deinit();
}

pub fn call(self: *Self) !Session {
    if (self.sessions.items.len == 0) {
        self.sessions.append(.{ .id = "42" });
    }
    return self.sessions.items[0];
}
