const build_options = @import("build_options");

pub usingnamespace @import(if (build_options.use_imgui)
    "main_wasm_legacy.zig"
else
    "main_wasm_wgpu.zig");
