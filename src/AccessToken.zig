const std = @import("std");
const time = @import("std").time;
///
/// Define the AccessToken struct implementing the interfaces
///
/// See more at http://tools.ietf.org/html/rfc6749#section-1.4 Access Token (RFC 6749, §1.4)
///
pub const AccessToken = struct {
    allocator: std.mem.Allocator = std.heap.page_allocator,

    access_token: []const u8 = "",
    expires: i64 = 0,
    refresh_token: []const u8 = "",
    resource_owner_id: []const u8 = "",
    // values: std.AutoHashMap([]const u8, []const u8),
    values: std.StringHashMap([]const u8) = std.StringHashMap([]const u8).init(std.heap.page_allocator),

    // Static variable to keep track of the current time
    const timeNow: i64 = time.milliTimestamp();

    pub fn init(self: AccessToken) !AccessToken {
        return .{
            .access_token = self.access_token,
            .expires = self.expires,
            .refresh_token = self.refresh_token,
            .resource_owner_id = self.resource_owner_id,
            .values = std.StringHashMap([]const u8).init(self.allocator),
        };
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
