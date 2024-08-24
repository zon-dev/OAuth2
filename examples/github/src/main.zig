const std = @import("std");
const URL = @import("url");
const oauth2 = @import("oauth2");
const Provider = oauth2.Provider;
const Providers = oauth2.Providers;
const zinc = @import("zinc");

const allocator = std.heap.page_allocator;

// CLIENT_ID=xxx CLIENT_SECRET=yyy zig build run
pub fn main() !void {
    var z = try zinc.init(.{
        .allocator = allocator,
        .addr = "0.0.0.0",
        .port = 8082,
        .read_buffer_len = 1024 * 10,
    });

    var router = z.getRouter();
    try router.get("/oauth2", oauth2process);

    try z.run();
}

pub fn oauth2provider() Provider {
    var env_map = std.process.getEnvMap(allocator) catch unreachable;
    const client_id = env_map.get("CLIENT_ID") orelse "x";
    const client_secret = env_map.get("CLIENT_SECRET") orelse "xxx";
    const redirect_uri = env_map.get("REDIRECT_URI") orelse "http://localhost:8082/oauth2";
    const scopes: []const []const u8 = &.{"read:user"};

    return Provider{
        .client_id = client_id,
        .client_secret = client_secret,
        .redirect_uri = redirect_uri,
        .scopes = scopes,
        .endpoint = Providers.github,
    };
}

// CLIENT_ID=xxx CLIENT_SECRET=yyy OAUTH2_HOST=http://x.x.x.x:8082 OAUTH2_STATE=xyz zig build run
pub fn oauth2process(ctx: *zinc.Context) !void {
    var env_map = std.process.getEnvMap(allocator) catch unreachable;

    var provider = oauth2provider();
    const callback_url = ctx.request.target;
    // Assuming you have a query parameter 'code'
    const code = getCode(callback_url);
    if (code == null) {
        const OAUTH2_STATE = "12345";
        // 'code' is not set, handle the case accordingly
        const authUrl = try provider.getAuthorizationUrl();

        try env_map.put("OAUTH2_STATE", OAUTH2_STATE);
        // std.process.execve(allocator,.{},env_map);

        const location = try std.fmt.allocPrint(allocator, "{s}&state={s}", .{ authUrl, OAUTH2_STATE });

        std.debug.print("Location: {s}\n", .{location});
        try ctx.redirect(.found, location);
        return;
    }

    std.debug.print("Parameter 'code' {s}\n", .{code.?});

    // Check given state against previously stored one to mitigate CSRF attack
    // const state = getState(callback_url) orelse "";
    // const oauth2state = env_map.get("OAUTH2_STATE") orelse "";
    // if (!std.mem.eql(u8, state, oauth2state)) {
    //     std.debug.print("Invalid state {s} | {s}\n", .{ state, oauth2state });
    //     try ctx.text("Invalid state", .{});
    //     return;
    // }

    // Try to get an access token (using the authorization code grant)
    const token = try provider.getAccessToken(code.?);
    std.debug.print("Access token: {s}\n", .{token.access_token});

    // Optional: Now you have a token you can look up a user's profile data
    const body_buffer = try provider.getResourceOwner(token.access_token);
    const parsed = try std.json.parseFromSlice(struct {
        login: []const u8,
    }, allocator, body_buffer, .{
        .ignore_unknown_fields = true,
    });

    std.debug.print("Hello {s}!\n", .{parsed.value.login});
    try ctx.json(parsed.value, .{});
}

fn getCode(redirect_uri: []const u8) ?[]const u8 {
    var url = URL.init(.{});
    const target = url.parseUrl(redirect_uri) catch return null;
    var queryMap = target.querymap.?;
    return queryMap.get("code");
}

fn getState(redirect_uri: []const u8) ?[]const u8 {
    var url = URL.init(.{});
    const target = url.parseUrl(redirect_uri) catch return null;
    var queryMap = target.querymap.?;
    return queryMap.get("state");
}
