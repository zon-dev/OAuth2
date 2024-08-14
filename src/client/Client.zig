pub const Client = @This();

const Provider = @import("../Provider.zig");

provider: Provider,
id: []u8,
secret: []u8,
