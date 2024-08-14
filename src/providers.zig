const Provider = @import("Provider.zig").Provider;
const Endpoint = Provider.Endpoint;

pub const amazon = Endpoint{
    .authorize_url = "https://www.amazon.com/ap/oa",
    .token_url = "https://api.amazon.com/auth/o2/token",
    .userinfo_url = "https://api.amazon.com/user/profile",
    // .scope = "profile",
};

pub const battle_net = Endpoint{
    .id = "battle.net",
    .authorize_url = "https://us.battle.net/oauth/authorize",
    .token_url = "https://us.battle.net/oauth/token",
    .userinfo_url = "https://us.battle.net/oauth/userinfo",
    // .scope = "openid",
};

pub const discord = Endpoint{
    .id = "discord",
    .authorize_url = "https://discordapp.com/api/oauth2/authorize",
    .token_url = "https://discordapp.com/api/oauth2/token",
    .userinfo_url = "https://discordapp.com/api/users/@me",
    // .scope = "identify",
};

pub const facebook = Endpoint{
    .id = "facebook",
    .authorize_url = "https://graph.facebook.com/oauth/authorize",
    .token_url = "https://graph.facebook.com/oauth/access_token",
    .userinfo_url = "https://graph.facebook.com/me",
};

pub const github = Endpoint{
    .id = "github.com",
    .authorize_url = "https://github.com/login/oauth/authorize",
    .token_url = "https://github.com/login/oauth/access_token",
    .userinfo_url = "https://api.github.com/user",
    // .scope = "read:user",
};

pub const google = Endpoint{
    .id = "google",
    .authorize_url = "https://accounts.google.com/o/oauth2/v2/auth",
    .token_url = "https://www.googleapis.com/oauth2/v4/token",
    .userinfo_url = "https://www.googleapis.com/oauth2/v1/userinfo?alt=json",
    // .scope = "profile",
};

pub const microsoft = Endpoint{
    .authorize_url = "https://login.microsoftonline.com/common/oauth2/v2.0/authorize",
    .token_url = "https://login.microsoftonline.com/common/oauth2/v2.0/token",
    .userinfo_url = "https://graph.microsoft.com/v1.0/me/",
    // .scope = "https://graph.microsoft.com/user.read",
};
