const std = @import("std");
const Allocator = std.mem.Allocator;
const jwt = @import("zig-jwt");
const pem = @import("pem.zig");
const core = @import("../core.zig");

pub fn createJwtToken(opts: struct {
    allocator: Allocator,
    key_json_file: []const u8,
    scope: []const u8,
    valid_for_sec: u32,
}) ![]const u8 {
    var arena = std.heap.ArenaAllocator.init(opts.allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    const key_json_file = try std.fs.cwd().openFile(opts.key_json_file, .{});
    defer key_json_file.close();

    var json_reader = std.json.reader(allocator, key_json_file.reader());
    const key = try std.json.parseFromTokenSourceLeaky(struct {
        private_key: []const u8,
        client_email: []const u8,
    }, allocator, &json_reader, .{ .ignore_unknown_fields = true });

    const private = try pem.decode(allocator, key.private_key);

    const token = try jwt.SigningMethodRS256.init(allocator).sign(.{
        .iss = key.client_email,
        .scope = opts.scope,
        .aud = "https://www.googleapis.com/oauth2/v4/token",
        .exp = std.time.timestamp() + opts.valid_for_sec,
        .iat = std.time.timestamp(),
    }, try jwt.rsa.rsa.SecretKey.fromDerAuto(private.bytes));

    const body = try core.encodePercent(allocator, &.{ .{
        .key = "grant_type",
        .value = "urn:ietf:params:oauth:grant-type:jwt-bearer",
    }, .{
        .key = "assertion",
        .value = token,
    } });

    const Result = struct { access_token: []const u8 };
    const result = try core.curl(Result, .{
        .method = .POST,
        .uri = "https://www.googleapis.com/oauth2/v4/token",
        .content_type = "application/x-www-form-urlencoded",
        .body = body,
        .allocator = allocator,
    });

    return opts.allocator.dupe(u8, result.access_token);
}
