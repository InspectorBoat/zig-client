const std = @import("std");

pub fn build(b: *std.Build) void {
    // Declare external dependencies
    const network = b.dependency("network", .{}).module("network");
    const mach_glfw = b.dependency("mach_glfw", .{}).module("mach-glfw");
    const zgl = b.dependency("zgl", .{}).module("zgl");
    const zalgebra = b.dependency("zalgebra", .{}).module("zalgebra");

    // Target & optimize options
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    // Create main executable
    const client = b.addExecutable(.{
        .name = "zig-client",
        .root_source_file = .{ .path = "main/main.zig" },
        .target = target,
        .optimize = optimize,
    });
    client.want_lto = false;

    // Declare used modules
    const root = &client.root_module;
    const render = b.addModule("render", .{ .root_source_file = .{ .path = "render/render.zig" } });
    const logging = b.addModule("log", .{ .root_source_file = .{ .path = "logging/logging.zig" } });
    const events = b.addModule("events", .{ .root_source_file = .{ .path = "events/events.zig" } });

    // Add imports to main executable module
    root.addImport("network", network);
    root.addImport("log", logging);
    root.addImport("render", render);
    root.addImport("events", events);

    // Add imports to used modules
    render.addImport("zgl", zgl);
    render.addImport("mach-glfw", mach_glfw);
    render.addImport("zalgebra", zalgebra);

    // Add check step to see if client compiles without doing any codegen
    // https://github.com/tigerbeetle/tigerbeetle/pull/1538/commits/840308a4c5155f4af88257b8fc8143bf10e1a91a
    const check_client = b.addExecutable(.{
        .name = "zig-client",
        .root_source_file = .{ .path = "main/main.zig" },
        .target = target,
        .optimize = optimize,
    });
    check_client.want_lto = false;
    const check_root = &check_client.root_module;
    check_root.addImport("network", network);
    check_root.addImport("log", logging);
    check_root.addImport("render", render);
    check_root.addImport("events", events);

    const check = b.step("check", "Check if client compiles");
    check.dependOn(&check_client.step);

    // Install exe
    const install = b.addInstallArtifact(client, .{});
    b.getInstallStep().dependOn(&install.step);

    // Run exe
    const run_exe = b.addRunArtifact(client);
    run_exe.step.dependOn(b.getInstallStep());

    const run_step = b.step("run", "Run the application");
    run_step.dependOn(&run_exe.step);

    // Run unit tests
    // Unit tests for main module
    const test_main = b.addTest(.{ .root_source_file = .{ .path = "main/main.zig" } });
    test_main.root_module.addImport("log", logging);

    // Unit tests for render module
    const test_render = b.addTest(.{ .root_source_file = .{ .path = "render/render.zig" } });
    test_render.root_module.addImport("log", logging);

    const run_test_main = b.addRunArtifact(test_main);
    const run_test_render = b.addRunArtifact(test_render);

    const test_step = b.step("test", "Run unit tests");
    test_step.dependOn(&run_test_main.step);
    test_step.dependOn(&run_test_render.step);
}
