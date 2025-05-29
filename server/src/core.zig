const std = @import("std");

pub fn tryParseInt(comptime T: type, buf: ?[]const u8) ?T {
    if (buf) |e| {
        return std.fmt.parseInt(T, e, 10) catch return null;
    } else return null;
}

pub fn curl(comptime Result: type, args: struct {
    allocator: std.mem.Allocator,
    method: std.http.Method,
    uri: []const u8,
    content_type: ?[]const u8 = "application/json",
    authorization: ?[]const u8 = null,
    body: ?[]const u8 = null,
}) !Result {
    var arena = std.heap.ArenaAllocator.init(args.allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    var client = std.http.Client{
        .allocator = allocator,
    };
    defer client.deinit();

    var server_buffer_header: [4096]u8 = undefined;
    var server_buffer_body: [65536]u8 = undefined;

    const uri = try std.Uri.parse(args.uri);
    var headers: std.http.Client.Request.Headers = .{};
    if (args.content_type) |value| headers.content_type = .{ .override = value };
    if (args.authorization) |value| headers.authorization = .{ .override = value };

    var req = try client.open(args.method, uri, .{
        .server_header_buffer = &server_buffer_header,
        .headers = headers,
    });
    defer req.deinit();

    if (args.body) |value| req.transfer_encoding = .{ .content_length = value.len };

    try req.send();
    if (args.body) |value| try req.writeAll(value);
    try req.finish();
    try req.wait();

    const server_buffer_len = try req.readAll(&server_buffer_body);

    const result = try std.json.parseFromSliceLeaky(
        Result,
        args.allocator,
        server_buffer_body[0..server_buffer_len],
        .{ .ignore_unknown_fields = true },
    );
    return result;
}

pub fn encodePercent(allocator: std.mem.Allocator, entries: []const struct { key: []const u8, value: []const u8 }) ![]const u8 {
    var buf = std.ArrayList(u8).init(allocator);
    const writter = buf.writer();
    var first = true;
    for (entries) |entry| {
        if (first) {
            first = false;
        } else {
            _ = try writter.write("&");
        }
        try std.Uri.Component.percentEncode(writter, entry.key, isValidChar);
        _ = try writter.write("=");
        try std.Uri.Component.percentEncode(writter, entry.value, isValidChar);
    }
    return buf.items;
}

fn isValidChar(_: u8) bool {
    return true;
}

pub const Mb: usize = 1024 * 1024;
