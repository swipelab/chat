const std = @import("std");
const Allocator = std.mem.Allocator;
const jwt = @import("zig-jwt");
const pem = @import("pem.zig");
const percent_encoding = @import("percent_encoding.zig");

pub fn createJwtToken(allocator: Allocator, opts: struct {
    key_json_file: []const u8,
    scope: []const u8,
    valid_for_sec: u32,
}) ![]const u8 {
    var alloc = std.heap.ArenaAllocator.init(allocator);
    defer alloc.deinit();
    const arena = alloc.allocator();

    const key_json_file = try std.fs.cwd().openFile(opts.key_json_file, .{});
    defer key_json_file.close();

    var json_reader = std.json.reader(arena, key_json_file.reader());
    const key = try std.json.parseFromTokenSourceLeaky(struct {
        private_key: []const u8,
        client_email: []const u8,
    }, arena, &json_reader, .{ .ignore_unknown_fields = true });

    const private = try pem.decode(arena, key.private_key);

    const token = try jwt.SigningMethodRS256.init(arena).sign(.{
        .iss = key.client_email,
        .scope = opts.scope,
        .aud = "https://www.googleapis.com/oauth2/v4/token",
        .exp = std.time.timestamp() + opts.valid_for_sec,
        .iat = std.time.timestamp(),
    }, try jwt.rsa.rsa.SecretKey.fromDerAuto(private.bytes));

    const KeyValue = struct { key: []const u8, value: []const u8 };
    const data: [2]KeyValue = .{ .{
        .key = "grant_type",
        .value = "urn:ietf:params:oauth:grant-type:jwt-bearer",
    }, .{
        .key = "assertion",
        .value = token,
    } };

    var encodedData = std.ArrayList(u8).init(allocator);
    defer encodedData.deinit();
    var first = true;
    for (data) |entry| {
        if (first) {
            first = false;
        } else {
            try encodedData.append('&');
        }

        try percent_encoding.encode_append(&encodedData, entry.key, .{});
        try encodedData.append('=');
        try percent_encoding.encode_append(&encodedData, entry.value, .{});
    }

    const uri = try std.Uri.parse("https://www.googleapis.com/oauth2/v4/token");
    var client = std.http.Client{
        .allocator = arena,
    };

    var server_header_buffer: [4096]u8 = undefined;
    var server_body_buffer: [65536]u8 = undefined;
    var req = try client.open(.POST, uri, .{
        .server_header_buffer = &server_header_buffer,
        .headers = .{
            .content_type = .{ .override = "application/x-www-form-urlencoded" },
        },
    });

    req.transfer_encoding = .{ .content_length = encodedData.items.len };

    try req.send();
    try req.writeAll(encodedData.items);
    try req.finish();
    try req.wait();

    const len = try req.readAll(&server_body_buffer);

    const result = try std.json.parseFromSliceLeaky(
        struct { access_token: []const u8 },
        arena,
        server_body_buffer[0..len],
        .{ .ignore_unknown_fields = true },
    );
    return allocator.dupe(u8, result.access_token);
}

fn isValid(_: u8) bool {
    return true;
}
