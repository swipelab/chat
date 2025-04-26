const std = @import("std");
const httpz = @import("httpz");
const pg = @import("pg");
const Storage = @import("storage.zig");
const Message = @import("models.zig").Message;
const jwt = @import("zig-jwt");

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
    var port: u16 = 3000;
    var pg_host: []const u8 = "127.0.0.1";
    var pg_port: u16 = 5432;
    var pg_db: []const u8 = "postgres";
    var pg_user: []const u8 = "postgres";
    var pg_pass: []const u8 = "postgres";

    var args = std.process.args();
    while (args.next()) |arg| {
        if (std.mem.eql(u8, "-port", arg)) port = parseInt(u16, args.next().?).?;
        if (std.mem.eql(u8, "-pg-host", arg)) pg_host = args.next().?;
        if (std.mem.eql(u8, "-pg-port", arg)) pg_port = parseInt(u16, args.next().?).?;
        if (std.mem.eql(u8, "-pg-db", arg)) pg_db = args.next().?;
        if (std.mem.eql(u8, "-pg-user", arg)) pg_user = args.next().?;
        if (std.mem.eql(u8, "-pg-pass", arg)) pg_pass = args.next().?;
    }

    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();

    var db = try pg.Pool.init(allocator, .{
        .connect = .{
            .port = pg_port,
            .host = pg_host,
        },
        .auth = .{
            .database = pg_db,
            .username = pg_user,
            .password = pg_pass,
        },
    });
    defer db.deinit();

    const secretSeed: []const u8 = "super secret key! really really!";
    var app = App{
        .meta = .{
            .identity = "swipe.home.ro",
        },
        .db = db,
        .jwt = .{
            .key = try jwt.eddsa.Ed25519.KeyPair.generateDeterministic(secretSeed[0..32].*),
        },
    };

    var server = try httpz.Server(*App).init(allocator, .{ .port = port, .address = "0.0.0.0" }, &app);
    var router = try server.router(.{});
    router.get("/", home, .{});
    router.get("/api/ping", ping, .{});
    router.post("/api/auth/register", register, .{});
    router.post("/api/auth/login", login, .{});
    router.post("/api/auth/delete", deleteAccount, .{});
    router.get("/api/room/:room_id/messages", getRoomMessages, .{});
    router.post("/api/room/:room_id/message", postRoomMessage, .{});
    router.get("/api/rooms", getRooms, .{});

    std.log.info("listening on {d}\n", .{port});
    try server.listen();
}

const App = struct {
    db: *pg.Pool,
    jwt: struct {
        key: jwt.eddsa.Ed25519.KeyPair,
    },
    meta: struct {
        identity: []const u8,
    },

    pub fn dispatch(self: *App, action: httpz.Action(*Context), req: *httpz.Request, res: *httpz.Response) !void {
        std.log.info("{s} {s}", .{ @tagName(req.method), req.url.path });
        var ctx = Context{
            .app = self,
            .storage = Storage.init(req.arena, self.db),
            .arena = req.arena,
            .user = self.loadAuthUser(
                req.arena,
                req.header("authorization"),
            ),
        };
        return action(&ctx, req, res);
    }

    fn loadAuthUser(self: *App, arena: std.mem.Allocator, authorization: ?[]const u8) ?User {
        const auth = authorization orelse return null;
        var split = std.mem.splitScalar(u8, auth, ' ');
        if (!std.mem.eql(u8, split.first(), "Bearer")) return null;
        const bearerToken = split.next() orelse return null;

        const p = jwt.SigningMethodEdDSA.init(arena);
        const token = p.parse(bearerToken, self.jwt.key.public_key) catch return null;

        var validator = jwt.Validator.init(token) catch return null;
        defer validator.deinit();
        if (!validator.hasBeenIssuedBy(self.meta.identity)) return null;
        if (!validator.isPermittedFor(self.meta.identity)) return null;

        return std.json.parseFromValueLeaky(User, arena, validator.claims, .{
            .ignore_unknown_fields = true,
        }) catch return null;
    }
};

const User = struct {
    auth_id: i32,
    name: []const u8,
};

const Context = struct {
    app: *App,
    storage: Storage,
    arena: std.mem.Allocator,
    user: ?User,

    pub fn ensureUser(self: *Context) !User {
        if (self.user) |user| return user else return error.InvalidUser;
    }
};

fn home(_: *Context, _: *httpz.Request, res: *httpz.Response) !void {
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

fn ping(ctx: *Context, _: *httpz.Request, res: *httpz.Response) !void {
    try res.json(.{ .user = ctx.user }, .{});
}

const key_length = 32;
const salt_length = 32;

fn deleteAccount(ctx: *Context, _: *httpz.Request, res: *httpz.Response) !void {
    const user = try ctx.ensureUser();
    try ctx.storage.auth.delete(.{ .auth_id = user.auth_id });
    try res.json(.{}, .{});
}

fn login(ctx: *Context, req: *httpz.Request, res: *httpz.Response) !void {
    const Request = struct {
        alias: []const u8,
        password: []const u8,
    };
    const request = try req.json(Request) orelse return error.Invalid;
    const auth = try ctx.storage.auth.selectByAlias(ctx.arena, request.alias);

    var key: [key_length]u8 = undefined;
    try std.crypto.pwhash.pbkdf2(
        &key,
        request.password,
        auth.password_salt,
        42,
        std.crypto.auth.hmac.sha2.HmacSha256,
    );

    if (!std.mem.eql(u8, &key, auth.password_hash)) return error.Nope;

    const claims = .{
        .aud = ctx.app.meta.identity,
        .sub = auth.auth_id,
        .name = auth.alias,
        .iss = ctx.app.meta.identity,
        .auth_id = auth.auth_id,
    };

    const s = jwt.SigningMethodEdDSA.init(ctx.arena);

    const token = try s.sign(claims, ctx.app.jwt.key.secret_key);

    try res.json(.{
        .alias = auth.alias,
        .token = token,
    }, .{});
}

fn register(ctx: *Context, req: *httpz.Request, res: *httpz.Response) !void {
    const Register = struct {
        alias: []const u8,
        password: []const u8,
    };

    const request = try req.json(Register) orelse return error.InvalidRequest;

    var key: [key_length]u8 = undefined;
    var salt: [salt_length]u8 = undefined;
    std.crypto.random.bytes(&salt);

    try std.crypto.pwhash.pbkdf2(
        &key,
        request.password,
        &salt,
        42,
        std.crypto.auth.hmac.sha2.HmacSha256,
    );

    try ctx.storage.auth.insert(.{
        .alias = request.alias,
        .password_salt = &salt,
        .password_hash = &key,
    });
    try res.json(.{ .ok = "ok" }, .{});
}

fn getRooms(ctx: *Context, req: *httpz.Request, res: *httpz.Response) !void {
    const rooms = try ctx.storage.room.select(req.arena);
    try res.json(rooms, .{});
}

fn getRoomMessages(ctx: *Context, req: *httpz.Request, res: *httpz.Response) !void {
    const room_id = parseInt(i32, req.param("room_id")) orelse return error.InvalidRoomId;
    const messages = try ctx.storage.message.selectByRoom(ctx.arena, room_id);
    try res.json(messages, .{});
}

fn postRoomMessage(ctx: *Context, req: *httpz.Request, res: *httpz.Response) !void {
    const user = try ctx.ensureUser();
    const room_id = parseInt(i32, req.param("room_id")) orelse return error.InvalidRoomId;
    const payload = try req.json(Message) orelse return error.InvalidPayload;

    try ctx.storage.message.insert(.{
        .sender_auth_id = user.auth_id,
        .room_id = room_id,
        .payload = try std.json.stringifyAlloc(
            ctx.arena,
            payload,
            .{
                .emit_null_optional_fields = false,
                .whitespace = .minified,
            },
        ),
    });

    try res.json(.{ .roomId = room_id, .payload = payload }, .{});
}

fn parseInt(comptime T: type, buf: ?[]const u8) ?T {
    if (buf) |e| {
        return std.fmt.parseInt(T, e, 10) catch return null;
    } else return null;
}
