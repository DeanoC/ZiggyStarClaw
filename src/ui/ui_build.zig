const build_options = @import("build_options");

// ImGui is legacy and is kept only for temporary fallback builds.
pub const use_imgui: bool = build_options.use_imgui;
