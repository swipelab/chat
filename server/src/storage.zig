const Self = @This();
const std = @import("std");
const pg = @import("pg");
const Allocator = std.mem.Allocator;

allocator: Allocator,
db: *pg.Pool,
auth: AuthTable,
message: MessageTable,
room: RoomTable,

pub const Auth = struct {
    auth_id: i32,
    alias: []const u8,
    password_hash: []const u8,
    password_salt: []const u8,
};

pub const Message = struct {
    message_id: i32,
    room_id: i32,
    sender_auth_id: i32,
    payload: []const u8,

    pub fn jsonStringify(self: @This(), jws: anytype) !void {
        try jws.beginObject();

        try jws.objectField("message_id");
        try jws.write(self.message_id);
        try jws.objectField("room_id");
        try jws.write(self.room_id);
        try jws.objectField("sender_auth_id");
        try jws.write(self.sender_auth_id);

        try jws.objectField("payload");
        try jws.print("{s}", .{self.payload});

        try jws.endObject();
    }
};

pub const Room = struct {
    room_id: i32,
    alias: []const u8,
};

pub fn init(allocator: Allocator, db: *pg.Pool) Self {
    return .{
        .allocator = allocator,
        .db = db,
        .auth = .{ .db = db },
        .message = .{ .db = db },
        .room = .{ .db = db },
    };
}

const RoomTable = struct {
    db: *pg.Pool,

    pub fn select(self: *RoomTable, allocator: Allocator) ![]Room {
        var query = try self.db.queryOpts(
            "SELECT room_id, alias FROM public.room",
            .{},
            .{ .column_names = true },
        );
        defer query.deinit();

        var result = std.ArrayList(Room).init(allocator);
        var mapper = query.mapper(Room, .{ .allocator = allocator });
        while (try mapper.next()) |entry| {
            try result.append(entry);
        }
        return result.items;
    }
};

const MessageTable = struct {
    db: *pg.Pool,

    pub fn insert(self: *MessageTable, entry: struct {
        sender_auth_id: i32,
        room_id: i32,
        payload: []const u8,
    }) !void {
        _ = try self.db.exec("INSERT INTO public.message (sender_auth_id, room_id, payload) VALUES ($1, $2, $3)", .{
            entry.sender_auth_id,
            entry.room_id,
            entry.payload,
        });
    }

    pub fn selectByRoom(self: *MessageTable, allocator: Allocator, room_id: i32) ![]Message {
        var query = try self.db.queryOpts(
            "SELECT message_id, room_id, sender_auth_id, payload FROM public.message WHERE room_id = $1",
            .{room_id},
            .{ .column_names = true },
        );
        defer query.deinit();

        var result = std.ArrayList(Message).init(allocator);
        var mapper = query.mapper(Message, .{ .allocator = allocator });
        while (try mapper.next()) |entry| {
            try result.append(entry);
        }
        return result.items;
    }
};

const AuthTable = struct {
    db: *pg.Pool,

    pub fn delete(self: *AuthTable, entry: struct {
        auth_id: i32,
    }) !void {
        _ = try self.db.exec("UPDATE public.auth SET password_hash = $1 WHERE auth_id = $2", .{
            "",
            entry.auth_id,
        });
    }

    pub fn insert(self: *AuthTable, entry: struct {
        alias: []const u8,
        password_salt: []const u8,
        password_hash: []const u8,
    }) !void {
        _ = try self.db.exec("INSERT INTO public.auth (alias, password_salt, password_hash) VALUES ($1, $2, $3)", .{
            entry.alias,
            entry.password_salt,
            entry.password_hash,
        });
    }

    pub fn selectByAlias(self: *AuthTable, allocator: Allocator, alias: []const u8) !Auth {
        var row = try self.db.row(
            "SELECT auth_id, alias, password_hash, password_salt FROM public.auth WHERE alias = $1",
            .{alias},
        ) orelse return error.NotFound;
        defer row.deinit() catch {};

        return try row.to(Auth, .{ .allocator = allocator });
    }
};
