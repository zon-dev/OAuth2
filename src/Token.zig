const std = @import("std");
const time = std.time;
const http = std.http;
const json = std.json;

pub const Token = @This();
const Self = @This();

const access_token: []const u8 = "";
const token_type: ?[]const u8 = null;
const refresh_token: ?[]const u8 = null;
const expiry: time.timestamp() = time.timestamp();
const raw: ?json.Value = null;
const expiry_delta: i64 = 3600;

pub fn Type(self: *Token) []const u8 {
    if (self.token_type) |tt| {
        if (std.mem.eql(u8, tt, "bearer")) return "Bearer";
        if (std.mem.eql(u8, tt, "mac")) return "MAC";
        if (std.mem.eql(u8, tt, "basic")) return "Basic";
        return tt;
    }
    return "Bearer";
}

pub fn extra(self: *Token, key: []const u8) ?json.Value {
    if (self.raw) |raw| {
        switch (raw) {
            .object => return raw.object.get(key),
            else => return null,
        }
    }
    return null;
}

pub fn expired(self: *Token) bool {
    return self.expiry < time.timestamp() + self.expiry_delta;
}

pub fn valid(self: *Token) bool {
    return self.access_token.len > 0 and !self.expired();
}

pub fn retrieveToken() !Token {
    return null;
}
