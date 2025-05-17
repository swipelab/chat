const Self = @This();
const std = @import("std");
const server = @import("server.zig");
const jwt = @import("zig-jwt");

const key_length = 32;
const salt_length = 32;

identity: []const u8,
key: jwt.eddsa.Ed25519.KeyPair,

const AuthToken = struct {
    user_id: i32,
    token: []const u8,
};

pub fn register(_: *Self, ctx: *server.Context, args: struct {
    alias: []const u8,
    password: []const u8,
}) !void {
    var key: [key_length]u8 = undefined;
    var salt: [salt_length]u8 = undefined;
    std.crypto.random.bytes(&salt);

    try std.crypto.pwhash.pbkdf2(
        &key,
        args.password,
        &salt,
        42,
        std.crypto.auth.hmac.sha2.HmacSha256,
    );

    try ctx.storage.auth.insert(.{
        .alias = args.alias,
        .password_salt = &salt,
        .password_hash = &key,
    });
}

pub fn login(self: *Self, ctx: *server.Context, args: struct {
    alias: []const u8,
    password: []const u8,
}) !AuthToken {
    const auth = try ctx.storage.auth.selectByAlias(ctx.arena, args.alias);

    var key: [key_length]u8 = undefined;
    try std.crypto.pwhash.pbkdf2(
        &key,
        args.password,
        auth.password_salt,
        42,
        std.crypto.auth.hmac.sha2.HmacSha256,
    );

    if (!std.mem.eql(u8, &key, auth.password_hash)) return error.Nope;

    const claims = .{
        .aud = self.identity,
        .sub = auth.auth_id,
        .name = auth.alias,
        .iss = self.identity,
        .auth_id = auth.auth_id,
    };

    const s = jwt.SigningMethodEdDSA.init(ctx.arena);

    const token = try s.sign(claims, self.key.secret_key);

    return .{
        .token = token,
        .user_id = auth.auth_id,
    };
}

pub fn fcmDelete(_: *Self, ctx: *server.Context) !void {
    const user = try ctx.ensureUser();
    try ctx.storage.fcm.delete(.{ .auth_id = user.auth_id });
}

pub fn logout(self: *Self, ctx: *server.Context) !void {
    try self.fcmDelete(ctx);
}

pub fn delete(_: *Self, ctx: *server.Context) !void {
    const user = try ctx.ensureUser();
    try ctx.storage.auth.delete(.{ .auth_id = user.auth_id });
}

pub const User = struct {
    auth_id: i32,
    name: []const u8,
};

pub fn decodeUser(self: *Self, allocator: std.mem.Allocator, bearerToken: []const u8) !User {
    const signing = jwt.SigningMethodEdDSA.init(allocator);
    var token = signing.parse(bearerToken, self.key.public_key) catch return error.InvalidToken;
    defer token.deinit();
    var validator = jwt.Validator.init(token) catch return error.InvalidToken;
    defer validator.deinit();

    if (!validator.hasBeenIssuedBy(self.identity)) return error.ClaimIssuer;
    if (!validator.isPermittedFor(self.identity)) return error.ClaimPermission;

    return try std.json.parseFromValueLeaky(User, allocator, validator.claims, .{
        .ignore_unknown_fields = true,
    });
}
