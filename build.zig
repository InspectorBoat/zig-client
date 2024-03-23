const std = @import("std");

pub fn build(b: *std.Build) void {
    const network = b.dependency("network", .{}).module("network");
    const mach_glfw = b.dependency("mach_glfw", .{}).module("mach-glfw");
    const zgl = b.dependency("zgl", .{}).module("zgl");
    const zalgebra = b.dependency("zalgebra", .{}).module("zalgebra");

    const exe = b.addExecutable(.{
        .name = "zig-client",
        .root_source_file = .{ .path = "main/main.zig" },
        .target = b.standardTargetOptions(.{}),
        .optimize = b.standardOptimizeOption(.{}),
    });
    exe.want_lto = false;

    const root = &exe.root_module;
    const render = b.addModule("render", .{
        .root_source_file = .{ .path = "render/render.zig" },
    });
    const logging = b.addModule("log", .{
        .root_source_file = .{ .path = "logging/logging.zig" },
    });

    root.addImport("network", network);
    root.addImport("log", logging);
    root.addImport("render", render);

    render.addImport("zgl", zgl);
    render.addImport("mach-glfw", mach_glfw);
    render.addImport("zalgebra", zalgebra);

    const install = b.addInstallArtifact(exe, .{});
    b.getInstallStep().dependOn(&install.step);

    const run_exe = b.addRunArtifact(exe);
    run_exe.step.dependOn(b.getInstallStep());

    const run_step = b.step("run", "Run the application");
    run_step.dependOn(&run_exe.step);

    const test_ring_alloc = b.addTest(.{
        .root_source_file = .{ .path = "src/util/RingBuffer.zig" },
    });
    test_ring_alloc.root_module.addImport("log", logging);

    const test_step = b.step("test", "Run unit tests");
    test_step.dependOn(&test_ring_alloc.step);
}
