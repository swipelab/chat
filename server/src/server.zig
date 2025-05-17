const std = @import("std");
const Allocator = std.mem.Allocator;
const Storage = @import("storage.zig");
const pg = @import("pg");
const jwt = @import("zig-jwt");
const httpz = @import("httpz");
const google = @import("vendor/google.zig");
const Auth = @import("auth.zig");
const core = @import("core.zig");
const ArrayList = std.ArrayList;

pub const Config = struct {
    identity: []const u8 = "chat.swipelab.com",
    http_host: []const u8 = "0.0.0.0",
    http_port: u16 = 3000,
    pg_host: []const u8 = "127.0.0.1",
    pg_port: u16 = 5432,
    pg_db: []const u8 = "postgres",
    pg_user: []const u8 = "postgres",
    pg_pass: []const u8 = "postgres",
    auth_key: []const u8 = "super secret key! really really!",
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
            if(std.mem.eql(u8, "-auth-key", arg)) result.auth_key = args.next().?;
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
    allocator: Allocator,
    db: *pg.Pool,
    google: struct {
        mutex: std.Thread.Mutex = .{},
        accessToken: ?[]const u8 = null,
        accessExpiresAt: i64 = 0,
    },
    auth: Auth,
    config: Config,
    p2p: P2P,

    pub fn init(opts: struct {
        allocator: Allocator,
        config: Config,
        db: *pg.Pool,
    }) !Server {
        return .{
            .allocator = opts.allocator,
            .db = opts.db,
            .config = opts.config,
            .google = .{},
            .auth = .{
                .key = try jwt.eddsa.Ed25519.KeyPair.generateDeterministic(opts.config.auth_key[0..32].*),
                .identity = opts.config.identity,
            },
            .p2p = .{
                .allocator = opts.allocator,
                .peers = ArrayList(*P2P.Peer).init(opts.allocator),
            },
        };
    }

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

        self.google.mutex.lock();
        defer self.google.mutex.unlock();

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

    pub const WebsocketContext = struct {
        call_id: i32,
        user_id: i32,
        server: *Server,
    };

    pub const WebsocketHandler = struct {
        peer: P2P.Peer,
        server: *Server,

        pub fn init(conn: *httpz.websocket.Conn, ctx: WebsocketContext) !WebsocketHandler {
            const peer = P2P.Peer{
                .conn = conn,
                .call_id = ctx.call_id,
                .user_id = ctx.user_id,
            };
            return .{
                .peer = peer,
                .server = ctx.server,
            };
        }

        pub fn afterInit(self: *WebsocketHandler) !void {
            try self.server.p2p.peers.append(&self.peer);
            try self.server.p2p.handleJoin(&self.peer);
            std.log.info("{} joined call {}", .{ self.peer.user_id, self.peer.call_id });
        }

        pub fn clientMessage(self: *WebsocketHandler, data: []const u8) !void {
            try self.server.p2p.broadcast(&self.peer, data);
        }

        pub fn close(self: *WebsocketHandler) void {
            for (self.server.p2p.peers.items, 0..) |peer, i| {
                if (peer.call_id == self.peer.call_id and peer.user_id == self.peer.user_id) {
                    _ = self.server.p2p.peers.swapRemove(i);
                    std.log.info("{} left call {}", .{ self.peer.user_id, self.peer.call_id });
                    break;
                }
            }
        }
    };
};

pub const P2P = struct {
    const Self = @This();

    pub const Peer = struct {
        conn: *httpz.websocket.Conn,
        call_id: i32,
        user_id: i32,
    };
    peers: ArrayList(*Peer),
    allocator: Allocator,

    pub fn handleJoin(self: *Self, peer: *Peer) !void {
        var arena = std.heap.ArenaAllocator.init(self.allocator);
        defer arena.deinit();
        const allocator = arena.allocator();

        // let everyone in the call know about the new member
        for (self.peers.items) |other| {
            if (peer.user_id == other.user_id or peer.call_id != other.call_id) continue;
            const output = try std.json.stringifyAlloc(allocator, .{
                .event = "peer",
                .data = .{ .user_id = other.user_id },
            }, .{ .emit_null_optional_fields = false });
            try peer.conn.write(output);
        }
    }

    // broadcast data to everyone else in the call
    pub fn broadcast(self: *Self, peer: *Peer, data: []const u8) !void {
        for (self.peers.items) |other| {
            if (peer.user_id == other.user_id or peer.call_id != other.call_id) continue;
            try other.conn.write(data);
        }
    }
};
