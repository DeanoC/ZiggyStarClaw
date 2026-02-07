const profile = @import("profile.zig");
const style_sheet = @import("style_sheet.zig");
const theme = @import("../theme.zig");

pub const PlatformCaps = profile.PlatformCaps;
pub const ProfileId = profile.ProfileId;
pub const Profile = profile.Profile;

pub const StyleSheet = style_sheet.StyleSheet;

var active_profile: Profile = profile.defaultsFor(.desktop, profile.PlatformCaps.defaultForTarget());
var active_styles_light: StyleSheet = .{};
var active_styles_dark: StyleSheet = .{};

pub fn setProfile(p: Profile) void {
    active_profile = p;
}

pub fn getProfile() Profile {
    return active_profile;
}

pub fn setStyleSheet(sheet: StyleSheet) void {
    setStyleSheets(sheet, sheet);
}

pub fn setStyleSheets(light: StyleSheet, dark: StyleSheet) void {
    active_styles_light = light;
    active_styles_dark = dark;
}

pub fn getStyleSheet() StyleSheet {
    return switch (theme.getMode()) {
        .light => active_styles_light,
        .dark => active_styles_dark,
    };
}
