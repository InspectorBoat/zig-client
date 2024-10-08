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

    {
        // Create main executable
        const client = b.addExecutable(.{
            .name = "zig-client",
            .root_source_file = b.path("main/main.zig"),
            .target = target,
            .optimize = optimize,
        });
        client.want_lto = false;

        // Declare used modules
        const root = &client.root_module;
        const render = b.addModule("render", .{ .root_source_file = b.path("render/render.zig") });
        const logging = b.addModule("log", .{ .root_source_file = b.path("logging/logging.zig") });
        const util = b.addModule("util", .{ .root_source_file = b.path("util/util.zig") });

        // Add imports to main module
        root.addImport("network", network);
        root.addImport("log", logging);
        root.addImport("render", render);
        root.addImport("util", util);

        // Add imports to other modules
        render.addImport("zgl", zgl);
        render.addImport("mach-glfw", mach_glfw);
        render.addImport("zalgebra", zalgebra);
        render.addImport("util", util);
        render.addImport("log", logging);

        util.addImport("log", logging);

        // Install exe
        const install = b.addInstallArtifact(client, .{});
        b.getInstallStep().dependOn(&install.step);

        // Install shader source
        const install_shader = b.addInstallDirectory(.{
            .source_dir = b.path("render/shader"),
            .install_dir = .bin,
            .install_subdir = "shader",
        });
        b.getInstallStep().dependOn(&install_shader.step);

        // Run exe
        const run_exe = b.addRunArtifact(client);
        run_exe.setCwd(b.path("zig-out/bin"));
        run_exe.step.dependOn(b.getInstallStep());

        const run_step = b.step("run", "Run the application");
        run_step.dependOn(&run_exe.step);

        // Run unit tests
        // Unit tests for main module
        const test_main = b.addTest(.{ .root_source_file = b.path("main/main.zig") });
        test_main.root_module.addImport("log", logging);
        test_main.root_module.addImport("util", util);

        // Unit tests for render module
        const test_render = b.addTest(.{ .root_source_file = b.path("render/render.zig") });
        test_render.root_module.addImport("log", logging);
        test_render.root_module.addImport("util", util);

        const test_util = b.addTest(.{ .root_source_file = b.path("util/util.zig") });

        const test_step = b.step("test", "Run unit tests");
        test_step.dependOn(&b.addRunArtifact(test_main).step);
        test_step.dependOn(&b.addRunArtifact(test_render).step);
        test_step.dependOn(&b.addRunArtifact(test_util).step);
    }

    // Add check step to see if client compiles without doing any codegen
    // https://github.com/tigerbeetle/tigerbeetle/pull/1538/commits/840308a4c5155f4af88257b8fc8143bf10e1a91a
    {
        const client = b.addExecutable(.{
            .name = "zig-client",
            .root_source_file = b.path("main/main.zig"),
            .target = target,
            .optimize = optimize,
        });
        client.want_lto = false;

        // Declare used modules
        const root = &client.root_module;
        const render = b.addModule("render", .{ .root_source_file = b.path("render/render.zig") });
        const logging = b.addModule("log", .{ .root_source_file = b.path("logging/logging.zig") });
        const util = b.addModule("util", .{ .root_source_file = b.path("util/util.zig") });

        // Add imports to main module
        root.addImport("network", network);
        root.addImport("log", logging);
        root.addImport("render", render);
        root.addImport("util", util);

        // Add imports to other modules
        render.addImport("zgl", zgl);
        render.addImport("mach-glfw", mach_glfw);
        render.addImport("zalgebra", zalgebra);
        render.addImport("util", util);
        render.addImport("log", logging);

        util.addImport("log", logging);

        const check = b.step("check", "Check if client compiles");
        check.dependOn(&client.step);

        // Install shader source
        const install_shader = b.addInstallDirectory(.{
            .source_dir = b.path("render/shader"),
            .install_dir = .bin,
            .install_subdir = "shader",
        });
        check.dependOn(&install_shader.step);
    }
}
