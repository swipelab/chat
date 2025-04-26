pub const Message = struct {
    text: ?TextMessage = null,
    image: ?ImageMessage = null,
    // pub fn jsonParse(allocator: std.mem.Allocator, source: anytype, options: std.json.ParseOptions) !@This() {
    //     const json = try std.json.innerParse(std.json.Value, allocator, source, options);
    //     const kindString = json.object.get("kind") orelse return error.UnexpectedToken;
    //     const kind = std.meta.stringToEnum(std.meta.Tag(@This()), kindString.string) orelse return error.UnexpectedToken;
    //     const result: @This() = switch (kind) {
    //         .text => .{ .text = try std.json.innerParseFromValue(TextMessage, allocator, json, .{ .ignore_unknown_fields = true }) },
    //         .image => .{ .image = try std.json.innerParseFromValue(ImageMessage, allocator, json, .{ .ignore_unknown_fields = true }) },
    //     };
    //
    //     return result;
    // }
};

pub const TextMessage = []const u8;

pub const ImageMessage = struct {
    url: []const u8,
};
