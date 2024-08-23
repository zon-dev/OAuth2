const std = @import("std");
const GrantType = @import("GrantType.zig").GrantType;
const AccessToken = @import("Accesstoken.zig").AccessToken;
pub const Provider = @This();
const http = std.http;
const Client = http.Client;
// const URL = @import("tools").URL;
const URL = @import("url");

// id: []const u8,

allocator: std.mem.Allocator = std.heap.page_allocator,

client_id: []const u8,
client_secret: []const u8 = "",
redirect_uri: []const u8 = "",
scopes: []const []const u8 = &.{},
grant_type: GrantType = .authorization_code,

endpoint: Endpoint,

// authorize_url: []const u8 = "",
// token_url: []const u8 = "",
// userinfo_url: []const u8 = "",
// device_auth_url: []const u8 = "",

name_prop: []const u8 = "",
name_prefix: []const u8 = "",

server_header_buffer: usize = 16 * 1024,
buffer_len: usize = 1024 * 10,

pub const Endpoint = struct {
    authorize_url: []const u8,
    token_url: []const u8,
    userinfo_url: []const u8 = "",
    device_auth_url: []const u8 = "",
};

fn scope(provider: *Provider) ?[]const u8 {
    var grant_scope: std.ArrayList(u8) = std.ArrayList(u8).init(provider.allocator);
    defer grant_scope.deinit();
    if (provider.scopes.len > 0) {
        for (provider.scopes) |s| {
            _ = grant_scope.appendSlice(s) catch null;
            _ = grant_scope.appendSlice(" ") catch null;
        }
    }

    // Remove the last space
    _ = grant_scope.pop();

    return grant_scope.toOwnedSlice() catch null;
}

pub fn getAccessToken(provider: *Provider, code: []const u8) anyerror!AccessToken {
    // Create an HTTP client.
    var client = std.http.Client{ .allocator = provider.allocator };
    // Release all associated resources with the client.
    defer client.deinit();

    const payload_str = std.fmt.allocPrint(provider.allocator, "grant_type=authorization_code&client_id={s}&client_secret={s}&redirect_uri={s}&code={s}", .{ provider.client_id, provider.client_secret, provider.redirect_uri, code }) catch unreachable;

    var req = try fetch(&client, .{
        .method = .POST,
        .location = .{
            .url = provider.endpoint.token_url,
        },
        .extra_headers = &.{
            .{ .name = "accpet", .value = "*/*" },
            .{ .name = "Content-Type", .value = "application/x-www-form-urlencoded" },
        },
        .payload = payload_str,
    });

    defer req.deinit();

    var body_buffer: []u8 = undefined;
    // body_buffer = try provider.allocator.alloc(u8, 16 * 1024);
    body_buffer = try provider.allocator.alloc(u8, req.response.content_length orelse 16 * 1024);
    _ = try req.read(body_buffer);

    var header_buffer: []u8 = undefined;
    header_buffer = try provider.allocator.alloc(u8, req.response.content_length orelse 10 * 1024);

    header_buffer = req.response.parser.get();
    const res_content_type = req.response.content_type;
    if (res_content_type != null) {
        const form_url = std.mem.indexOf(u8, res_content_type.?, "application/x-www-form-urlencoded");
        if (form_url != null) {
            return try AccessToken.parseUrlEncoded(body_buffer, provider.allocator);
        }

        const form_json = std.mem.indexOf(u8, res_content_type.?, "application/json");
        if (form_json != null) {
            return try AccessToken.parseJSON(body_buffer, provider.allocator);
        }
    }

    return error.Unreachable;
}

// pub fn getResourceOwner(provider: *Provider, token: []const u8, resource_struct: type) anyerror![]const u8 {
pub fn getResourceOwner(provider: *Provider, token: []const u8, comptime resource_struct: type,) anyerror! resource_struct {
    // Implement resource owner retrieval
    var client = std.http.Client{ .allocator = provider.allocator };
    var req = try fetch(&client, .{
        .location = .{
            .url = provider.endpoint.userinfo_url,
        },
        .extra_headers = &.{
            .{ .name = "accpet", .value = "*/*" },
            .{ .name = "Authorization", .value = std.fmt.allocPrint(provider.allocator, "Bearer {s}", .{token}) catch "" },
        },
    });

    defer req.deinit();

    var body_buffer: []u8 = undefined;
    body_buffer = try provider.allocator.alloc(u8, req.response.content_length orelse 16 * 1024);
    _ = try req.read(body_buffer);

    var header_buffer: []u8 = undefined;
    header_buffer = try provider.allocator.alloc(u8, req.response.content_length orelse 10 * 1024);
    header_buffer = req.response.parser.get();

    const res_content_type = req.response.content_type;
    if (res_content_type != null) {
        const form_json = std.mem.indexOf(u8, res_content_type.?, "application/json");
        if (form_json != null) {
            // parse JSON
            var parsed = try std.json.parseFromSlice(resource_struct, provider.allocator, body_buffer, .{
                .ignore_unknown_fields = true,
            });
            defer parsed.deinit();
            return parsed.value;
        }
    }

    // return body_buffer;
    return error.Unreachable;
}

pub fn getAuthorizationUrl(provider: *Provider) ![]const u8 {
    const grant_scope = provider.scope() orelse null;
    var authUrl: []u8 = undefined;
    if (grant_scope == null) {
        authUrl = std.fmt.allocPrint(provider.allocator, "{s}?client_id={s}&redirect_uri={s}&response_type=code", .{ provider.endpoint.authorize_url, provider.client_id, provider.redirect_uri }) catch unreachable;
    } else {
        authUrl = std.fmt.allocPrint(provider.allocator, "{s}?client_id={s}&redirect_uri={s}&response_type=code&scope={s}", .{ provider.endpoint.authorize_url, provider.client_id, provider.redirect_uri, grant_scope.? }) catch unreachable;
    }
    return authUrl;
}

/// see  std.http.Client.fetch
fn fetch(client: *std.http.Client, options: std.http.Client.FetchOptions) !std.http.Client.Request {
    const uri = switch (options.location) {
        .url => |u| try std.Uri.parse(u),
        .uri => |u| u,
    };
    // var server_header_buffer = options.server_header_buffer orelse (16 * 1024);
    var server_header_buffer: [16 * 1024]u8 = undefined;

    const method: std.http.Method = options.method orelse
        if (options.payload != null) .POST else .GET;

    var req = try std.http.Client.open(client, method, uri, .{
        .server_header_buffer = options.server_header_buffer orelse &server_header_buffer,
        .redirect_behavior = options.redirect_behavior orelse
            if (options.payload == null) @enumFromInt(3) else .unhandled,
        .headers = options.headers,
        .extra_headers = options.extra_headers,
        .privileged_headers = options.privileged_headers,
        .keep_alive = options.keep_alive,
    });
    // defer req.deinit();

    if (options.payload) |payload| req.transfer_encoding = .{ .content_length = payload.len };

    try req.send();

    if (options.payload) |payload| try req.writeAll(payload);

    try req.finish();
    try req.wait();
    return req;
}

pub fn getState() ![]const u8 {
    return "state";
}
const ResourceOwner = struct {
    // Add fields as necessary
};
