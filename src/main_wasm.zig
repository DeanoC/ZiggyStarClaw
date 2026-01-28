const std = @import("std");
const zemscripten = @import("zemscripten");

pub const panic = zemscripten.panic;

pub const std_options = std.Options{
    .logFn = zemscripten.log,
};

export fn main() c_int {
    std.log.info("MoltBot client stub (wasm) loaded.", .{});
    return 0;
}
