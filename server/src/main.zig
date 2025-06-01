const std = @import("std");
const httpz = @import("httpz");
const pg = @import("pg");
const Storage = @import("storage.zig");
const Message = @import("models.zig").Message;
const jwt = @import("zig-jwt");
const google = @import("vendor/google.zig");
const core = @import("core.zig");
const server = @import("server.zig");

pub const std_options: std.Options = .{
    .log_level = .info,
    .logFn = logFn,
};

pub fn logFn(
    comptime level: std.log.Level,
    comptime scope: @TypeOf(.EnumLiteral),
    comptime format: []const u8,
    args: anytype,
) void {
    const writter = std.io.getStdOut().writer();
    writter.print("({any}) {s} :", .{ scope, @tagName(level) }) catch {};
    writter.print(format ++ "\n", args) catch {};
}

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();

    const config = try server.Config.initFromArgs();

    var db = try pg.Pool.init(allocator, .{
        .connect = .{
            .port = config.pg_port,
            .host = config.pg_host,
        },
        .auth = .{
            .database = config.pg_db,
            .username = config.pg_user,
            .password = config.pg_pass,
        },
    });
    defer db.deinit();

    var srv = try server.Server.init(.{
        .allocator = allocator,
        .config = config,
        .db = db,
    });

    var httpServer = try httpz.Server(*server.Server).init(
        allocator,
        .{
            .port = config.http_port,
            .address = config.http_host,
            .request = .{ .max_body_size = 2 * core.Mb },
        },
        &srv,
    );
    var router = try httpServer.router(.{});

    router.get("/", home, .{});
    router.get("/api/ping", ping, .{});
    router.post("/api/auth/register", auth_register, .{});
    router.post("/api/auth/login", auth_login, .{});
    router.post("/api/auth/logout", auth_logout, .{});
    router.delete("/api/auth", auth_delete, .{});
    router.post("/api/auth/fcm", auth_fcm_post, .{});
    router.delete("/api/auth/fcm", auth_fcm_delete, .{});
    router.get("/api/user/:auth_id/profile/picture", user_profile_picture_get, .{});
    router.get("/api/profile/picture", profile_picture_get, .{});
    router.post("/api/profile/picture", profile_picture_post, .{});
    router.get("/api/rooms", room_all, .{});
    router.get("/api/room/:room_id", room_by_id, .{});
    router.get("/api/room/:room_id/messages", room_messages, .{});
    router.post("/api/room/:room_id/message", room_message_post, .{});
    router.get("/api/call/:call_id", call, .{});

    std.log.info("listening on {d}\n", .{srv.config.http_port});
    try httpServer.listen();
}

fn call(ctx: *server.Context, req: *httpz.Request, res: *httpz.Response) !void {
    const call_id = core.tryParseInt(i32, req.param("call_id")) orelse return error.InvalidCallId;
    const user = try ctx.ensureUser();
    const callCtx = server.Server.WebsocketContext{
        .call_id = call_id,
        .user_id = user.auth_id,
        .server = ctx.server,
    };
    if (try httpz.upgradeWebsocket(server.Server.WebsocketHandler, req, res, callCtx) == false) {
        res.status = 400;
        res.body = "invalid websocket";
        return;
    }
}

fn home(_: *server.Context, _: *httpz.Request, res: *httpz.Response) !void {
    res.status = 200;
    res.header("content-type", "text/html; charset=utf-8");
    res.body =
        \\<html>
        \\<header>
        \\  <title>Chat Server @ SWIPELAB</title>
        \\</header>
        \\<body>
        \\  Chat Server
        \\</body>
        \\</html>
    ;
}

fn ping(ctx: *server.Context, _: *httpz.Request, res: *httpz.Response) !void {
    try res.json(.{ .user = ctx.user }, .{});
}

fn auth_delete(ctx: *server.Context, _: *httpz.Request, res: *httpz.Response) !void {
    try ctx.server.auth.delete(ctx);
    try res.json(.{}, .{});
}

fn auth_fcm_post(ctx: *server.Context, req: *httpz.Request, res: *httpz.Response) !void {
    const user = try ctx.ensureUser();
    const request = try req.json(struct { token: []const u8 }) orelse return error.Invalid;
    try ctx.storage.fcm.upsert(.{ .auth_id = user.auth_id, .token = request.token });
    try res.json(.{}, .{});
}

fn auth_fcm_delete(ctx: *server.Context, _: *httpz.Request, res: *httpz.Response) !void {
    try ctx.server.auth.fcmDelete(ctx);
    try res.json(.{}, .{});
}

fn profile_picture_post(ctx: *server.Context, req: *httpz.Request, res: *httpz.Response) !void {
    const user = try ctx.ensureUser();
    const body = req.body() orelse return error.MissingBody;
    try ctx.storage.auth.updateProfilePicture(.{ .auth_id = user.auth_id, .data = body });
    try res.json(.{}, .{});
}

fn user_profile_picture_get(ctx: *server.Context, req: *httpz.Request, res: *httpz.Response) !void {
    _ = try ctx.ensureUser();

    const auth_id = core.tryParseInt(i32, req.param("auth_id")) orelse return error.InvalidAuthId;

    res.status = 200;
    res.content_type = .JPG;
    res.body = try ctx.storage.auth.selectProfilePicture(.{
        .auth_id = auth_id,
        .allocator = res.arena,
    });
}

fn profile_picture_get(ctx: *server.Context, _: *httpz.Request, res: *httpz.Response) !void {
    const user = try ctx.ensureUser();

    res.status = 200;
    res.content_type = .JPG;
    res.body = try ctx.storage.auth.selectProfilePicture(.{
        .auth_id = user.auth_id,
        .allocator = res.arena,
    });
}

fn auth_logout(ctx: *server.Context, _: *httpz.Request, res: *httpz.Response) !void {
    try ctx.server.auth.logout(ctx);
    try res.json(.{}, .{});
}

fn auth_login(ctx: *server.Context, req: *httpz.Request, res: *httpz.Response) !void {
    const body = try req.json(struct {
        alias: []const u8,
        password: []const u8,
    }) orelse return error.Invalid;
    const auth = try ctx.server.auth.login(ctx, .{
        .alias = body.alias,
        .password = body.password,
    });
    try res.json(.{
        .alias = body.alias,
        .token = auth.token,
        .user_id = auth.user_id,
    }, .{});
}

fn auth_register(ctx: *server.Context, req: *httpz.Request, res: *httpz.Response) !void {
    const body = try req.json(struct {
        alias: []const u8,
        password: []const u8,
    }) orelse return error.InvalidRequest;
    try ctx.server.auth.register(ctx, .{
        .alias = body.alias,
        .password = body.password,
    });
    try res.json(.{}, .{});
}

fn room_all(ctx: *server.Context, req: *httpz.Request, res: *httpz.Response) !void {
    const rooms = try ctx.storage.room.select(req.arena);
    try res.json(rooms, .{});
}

fn room_by_id(ctx: *server.Context, req: *httpz.Request, res: *httpz.Response) !void {
    _ = try ctx.ensureUser();
    const room_id = core.tryParseInt(i32, req.param("room_id")) orelse return error.InvalidRoomId;
    const room = try ctx.storage.room.by_id(req.arena, room_id);
    try res.json(room, .{});
}

fn room_messages(ctx: *server.Context, req: *httpz.Request, res: *httpz.Response) !void {
    const room_id = core.tryParseInt(i32, req.param("room_id")) orelse return error.InvalidRoomId;
    const messages = try ctx.storage.message.selectByRoom(ctx.arena, room_id);
    try res.json(messages, .{});
}

fn room_message_post(ctx: *server.Context, req: *httpz.Request, res: *httpz.Response) !void {
    const user = try ctx.ensureUser();
    const room_id = core.tryParseInt(i32, req.param("room_id")) orelse return error.InvalidRoomId;
    const payload = try req.json(Message) orelse return error.InvalidPayload;

    const safePayload = try std.json.stringifyAlloc(
        ctx.arena,
        payload,
        .{
            .emit_null_optional_fields = false,
            .whitespace = .minified,
        },
    );

    try ctx.storage.message.insert(.{
        .sender_auth_id = user.auth_id,
        .room_id = room_id,
        .payload = safePayload,
    });

    const others = try ctx.storage.fcm.selectOthers(.{ .auth_id = user.auth_id, .allocator = ctx.arena });

    if (payload.stringify()) |body| {
        for (others) |other| {
            sendPushNotification(ctx, .{
                .body = body,
                .token = other.token,
            }) catch |e| {
                std.log.err("unable to send push {any}", .{e});
            };
        }
    }

    try res.json(.{ .roomId = room_id, .payload = payload }, .{});
}

fn sendPushNotification(ctx: *server.Context, opts: struct {
    token: []const u8,
    title: ?[]const u8 = null,
    body: []const u8,
}) !void {
    const MessageSend = struct {
        validate_only: bool = false,
        message: struct {
            token: []const u8,
            notification: struct {
                title: ?[]const u8,
                body: []const u8,
            },
        },
    };

    const arena = ctx.arena;
    var client = std.http.Client{
        .allocator = arena,
    };
    defer client.deinit();

    const uri = try std.Uri.parse("https://fcm.googleapis.com/v1/projects/chat-swipelab/messages:send");
    const accessToken = ctx.server.gcpAccessToken() orelse return;
    const authorization = try std.fmt.allocPrint(arena, "Bearer {s}", .{accessToken});

    var server_header_buffer: [4096]u8 = undefined;
    var req = try client.open(.POST, uri, .{
        .server_header_buffer = &server_header_buffer,
        .headers = .{
            .content_type = .{ .override = "application/json" },
            .authorization = .{ .override = authorization },
        },
    });
    defer req.deinit();

    const body = try std.json.stringifyAlloc(arena, MessageSend{
        .message = .{
            .token = opts.token,
            .notification = .{
                .title = opts.title,
                .body = opts.body,
            },
        },
    }, .{ .emit_null_optional_fields = false });
    req.transfer_encoding = .{ .content_length = body.len };

    try req.send();
    try req.writeAll(body);
    try req.finish();
    try req.wait();
}
