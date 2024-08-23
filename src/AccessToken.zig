const std = @import("std");
const time = @import("std").time;
///
/// Define the AccessToken struct implementing the interfaces
///
/// See more at http://tools.ietf.org/html/rfc6749#section-1.4 Access Token (RFC 6749, §1.4)
///
pub const AccessToken = struct {
    allocator: std.mem.Allocator = std.heap.page_allocator,

    token_type: []const u8 = "Bearer",
    access_token: []const u8 = "",
    refresh_token: []const u8 = "",

    expires: i64 = 0,
    expires_in: i64 = 0,

    resource_owner_id: []const u8 = "",
    raw: []const u8 = "",
    // values: std.AutoHashMap([]const u8, []const u8),
    values: std.StringHashMap([]const u8) = std.StringHashMap([]const u8).init(std.heap.page_allocator),

    // Static variable to keep track of the current time
    const timeNow: i64 = time.milliTimestamp();

    pub fn init(self: AccessToken) !AccessToken {
        return .{
            .token_type = self.token_type,
            .access_token = self.access_token,
            .refresh_token = self.refresh_token,

            .expires = self.expires,
            .expires_in = self.expires_in,
            .resource_owner_id = self.resource_owner_id,
            .raw = self.raw,
            .values = std.StringHashMap([]const u8).init(self.allocator),
        };
    }

    pub fn parseJSON(data: []const u8, allocator: std.mem.Allocator) anyerror!AccessToken {
        const at = struct {
            access_token: []const u8,
            refresh_token: []const u8,
            token_type: []const u8,
            expires_in: i64,
        };
        const parsed = try std.json.parseFromSlice(at, allocator, data, .{
            .ignore_unknown_fields = true,
        });
        defer parsed.deinit();
        // return parsed.value;
        const tok = parsed.value;
        return .{
            .token_type = tok.token_type,
            .access_token = tok.access_token,
            .refresh_token = tok.refresh_token,
            .expires = time.milliTimestamp() + tok.expires_in,
            .expires_in = tok.expires_in,
            .raw = data,
            .values = std.StringHashMap([]const u8).init(allocator),
        };

        // _ = data;
        // _ = allocator;
        // return error.Unreachable;
    }

    pub fn parseUrlEncoded(data: []const u8, allocator: std.mem.Allocator) anyerror!AccessToken {
        var it = std.mem.splitSequence(u8, data, "&");
        var values = std.StringHashMap([]const u8).init(allocator);
        defer values.deinit();

        while (it.next()) |slice| {
            var kv = std.mem.splitSequence(u8, slice, "=");
            if (kv.next()) |key| {
                if (kv.next()) |value| {
                    _ = try values.put(key, value);
                }
            }
        }

        if (values.get("access_token") == null) {
            return error.Unreachable;
        }
        return init(.{
            .access_token = values.get("access_token").?,
            .refresh_token = values.get("refresh_token").?,
            .token_type = values.get("token_type").?,
        });
    }

    test "parseUrlEncoded" {
        const data = "access_token=ghu_xtVvaVgGNS1UehoRdOC50Ha37&expires_in=28800&refresh_token=ghr_j6G4P04oY3rkI64nG2tFku9QY5GfHI5TZBu5RSnoLHKj95xMxOWGbnedSn3NFOWb&refresh_token_expires_in=15897600&scope=&token_type=bearer";
        const at = parseUrlEncoded(data, std.testing.allocator) catch {
            try std.testing.expect(false);
            return error.Unreachable;
        };
        try std.testing.expectEqualSlices(u8, "ghu_xtVvaVgGNS1UehoRdOC50Ha37", at.access_token);
        try std.testing.expectEqualSlices(u8, "ghr_j6G4P04oY3rkI64nG2tFku9QY5GfHI5TZBu5RSnoLHKj95xMxOWGbnedSn3NFOWb", at.refresh_token);
        try std.testing.expectEqualSlices(u8, "bearer", at.token_type);
    }

    pub fn setRefreshToken(self: *AccessToken, refreshToken: []const u8) void {
        self.refreshToken = refreshToken;
    }

    pub fn getCurrentTime() i64 {
        return time.milliTimestamp();
    }

    pub fn isExpired(self: *AccessToken) bool {
        return self.expires <= self.getCurrentTime();
    }
};
