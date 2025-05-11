const std = @import("std");
const Allocator = std.mem.Allocator;
const Storage = @import("storage.zig");
const pg = @import("pg");
const jwt = @import("zig-jwt");
const httpz = @import("httpz");
const google = @import("vendor/google.zig");
const Auth = @import("auth.zig");
const core = @import("core.zig");

pub const Config = struct {
    identity: []const u8 = "chat.swipelab.com",
    http_host: []const u8 = "0.0.0.0",
    http_port: u16 = 3000,
    pg_host: []const u8 = "127.0.0.1",
    pg_port: u16 = 5432,
    pg_db: []const u8 = "postgres",
    pg_user: []const u8 = "postgres",
    pg_pass: []const u8 = "postgres",
    gcp_service_account_file: []const u8 = "service_account.json",

    pub fn initFromArgs() !Config {
        var result: @This() = .{};

        var args = std.process.args();
        while (args.next()) |arg| {
            if (std.mem.eql(u8, "-port", arg)) result.http_port = core.tryParseInt(u16, args.next().?).?;
            if (std.mem.eql(u8, "-pg-host", arg)) result.pg_host = args.next().?;
            if (std.mem.eql(u8, "-pg-port", arg)) result.pg_port = core.tryParseInt(u16, args.next().?).?;
            if (std.mem.eql(u8, "-pg-db", arg)) result.pg_db = args.next().?;
            if (std.mem.eql(u8, "-pg-user", arg)) result.pg_user = args.next().?;
            if (std.mem.eql(u8, "-pg-pass", arg)) result.pg_pass = args.next().?;
            if (std.mem.eql(u8, "-gcp-service-account", arg)) result.gcp_service_account_file = args.next().?;
        }

        return result;
    }
};

pub const Context = struct {
    server: *Server,
    storage: Storage,
    arena: Allocator,
    user: ?Auth.User,

    pub fn ensureUser(self: *Context) !Auth.User {
        if (self.user) |user| return user else return error.InvalidUser;
    }
};

pub const Server = struct {
    allocator: std.mem.Allocator,
    db: *pg.Pool,
    google: struct {
        m: std.Thread.Mutex = .{},
        accessToken: ?[]const u8 = null,
        accessExpiresAt: i64 = 0,
    },
    auth: Auth,
    config: Config,

    pub fn dispatch(self: *Server, action: httpz.Action(*Context), req: *httpz.Request, res: *httpz.Response) !void {
        std.log.info("{s} {s}", .{ @tagName(req.method), req.url.path });
        var ctx = Context{
            .server = self,
            .storage = Storage.init(req.arena, self.db),
            .arena = req.arena,
            .user = self.decodeUser(
                req.arena,
                req.header("authorization"),
            ),
        };
        try action(&ctx, req, res);
    }

    fn decodeUser(self: *Server, arena: std.mem.Allocator, authorization: ?[]const u8) ?Auth.User {
        const auth = authorization orelse return null;
        var split = std.mem.splitScalar(u8, auth, ' ');
        if (!std.mem.eql(u8, split.first(), "Bearer")) return null;
        const bearerToken = split.next() orelse return null;

        return self.auth.decodeUser(arena, bearerToken) catch |e| {
            std.log.err("{any}", .{e});
            return null;
        };
    }

    pub fn gcpAccessToken(self: *Server) ?[]const u8 {
        const time = std.time.timestamp();
        const token = self.google.accessToken;
        if (time < self.google.accessExpiresAt and token != null) return token;

        std.log.info("Aquiring GCP Token...", .{});

        self.google.m.lock();
        defer self.google.m.unlock();

        if (self.google.accessToken) |currentToken| {
            self.allocator.free(currentToken);
            self.google.accessToken = null;
        }
        const gcp_firebase_messaging_scope: []const u8 = "https://www.googleapis.com/auth/firebase.messaging";
        const accessToken = google.createJwtToken(.{
            .allocator = self.allocator,
            .key_json_file = self.config.gcp_service_account_file,
            .scope = gcp_firebase_messaging_scope,
            .valid_for_sec = 3600,
        }) catch return null;

        self.google.accessToken = accessToken;
        self.google.accessExpiresAt = time + 3500;

        std.log.info("GCP Token {?s}", .{accessToken});

        return accessToken;
    }
};
