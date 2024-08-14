const std = @import("std");
const tools = @import("tools");
const URL = tools.URL;
const Provider = @import("Provider.zig");

const allocator = std.heap.page_allocator;

// CLIENT_ID=xxx CLIENT_SECRET=yyy OAUTH2_HOST=http://x.x.x.x:8082 OAUTH2_STATE=xyz zig build run
pub fn main() !void {
    var env_map = try std.process.getEnvMap(allocator);

    const oauth2_host = env_map.get("OAUTH2_HOST") orelse "http://localhost:8080";
    const client_id = env_map.get("CLIENT_ID") orelse "";
    const client_secret = env_map.get("CLIENT_SECRET") orelse "";

    // const redirect_uri = env_map.get("REDIRECT_URI") orelse "http://localhost:8080/callback";
    const redirect_uri = env_map.get("REDIRECT_URI") orelse "http://localhost:8080/callback?code=1234&state=xyz";

    var provider = Provider{
        .client_id = client_id,
        .client_secret = client_secret,
        .redirect_uri = redirect_uri,
        .scopes = &.{
            "openid",
            "email",
        },
        .endpoint = .{
            .authorize_url = std.fmt.allocPrint(allocator, "{s}/oauth/authorize", .{oauth2_host}) catch "",
            .token_url = std.fmt.allocPrint(allocator, "{s}/oauth/token", .{oauth2_host}) catch "",
            .userinfo_url = std.fmt.allocPrint(allocator, "{s}/oauth/userinfo", .{oauth2_host}) catch "",
        },
    };

    // const callback_url = std.Uri.parse("http://localhost:8080/callback?code=1234&state=xyz") catch unreachable;
    const callback_url = std.Uri.parse(redirect_uri) catch unreachable;

    // Assuming you have a query parameter 'code'
    const code = getCode(callback_url);

    if (code == null) {
        // 'code' is not set, handle the case accordingly
        std.debug.print("Parameter 'code' is not set\n", .{});
        const authUrl = provider.getAuthorizationUrl() catch {
            std.debug.print("Failed to get authorization URL\n", .{});
            return;
        };
        std.debug.print("Location: {s}\n", .{authUrl});
        std.process.exit(1);
    }

    // Check given state against previously stored one to mitigate CSRF attack
    const state = getState(callback_url) orelse "";
    const oauth2state = env_map.get("OAUTH2_STATE") orelse "";
    if (!std.mem.eql(u8, state, oauth2state)) {
        std.debug.print("Invalid state {s} {s}\n", .{ state, oauth2state });
        std.process.exit(1);
    }

    // Try to get an access token (using the authorization code grant)
    const token = provider.getAccessToken(code.?) catch {
        std.debug.print("Failed to get access token\n", .{});
        return;
    };

    // Optional: Now you have a token you can look up a user's profile data
    const user = provider.getResourceOwner(token.access_token) catch {
        std.debug.print("Failed to get user details\n", .{});
        return;
    };

    // Use these details to create a new profile
    std.debug.print("Hello {s}!\n", .{user});
}

fn getCode(uri: std.Uri) ?[]const u8 {
    const query = uri.query orelse return null;
    const queryMap = URL.parseQuery(query.percent_encoded);
    return queryMap.get("code");
}

fn getState(uri: std.Uri) ?[]const u8 {
    const query = uri.query orelse return null;
    const queryMap = URL.parseQuery(query.percent_encoded);
    return queryMap.get("state");
}
