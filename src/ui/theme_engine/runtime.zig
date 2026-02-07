const profile = @import("profile.zig");
const style_sheet = @import("style_sheet.zig");

pub const PlatformCaps = profile.PlatformCaps;
pub const ProfileId = profile.ProfileId;
pub const Profile = profile.Profile;

pub const StyleSheet = style_sheet.StyleSheet;

var active_profile: Profile = profile.defaultsFor(.desktop, profile.PlatformCaps.defaultForTarget());
var active_styles: StyleSheet = .{};

pub fn setProfile(p: Profile) void {
    active_profile = p;
}

pub fn getProfile() Profile {
    return active_profile;
}

pub fn setStyleSheet(sheet: StyleSheet) void {
    active_styles = sheet;
}

pub fn getStyleSheet() StyleSheet {
    return active_styles;
}

