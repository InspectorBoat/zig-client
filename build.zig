const std = @import("std");

const ModuleSet = struct {
    main: *std.Build.Module,
    render: *std.Build.Module,
    util: *std.Build.Module,
    quarantine: *std.Build.Module,
};

fn createModules(
    b: *std.Build,
    target: std.Build.ResolvedTarget,
    optimize: std.builtin.OptimizeMode,
    network: *std.Build.Module,
    mach_glfw: *std.Build.Module,
    zgl: *std.Build.Module,
    zalgebra: *std.Build.Module,
    zigimg: *std.Build.Module,
) ModuleSet {
    const main = b.createModule(.{
        .root_source_file = b.path("main/main.zig"),
        .target = target,
        .optimize = optimize,
    });
    const quarantine = b.createModule(.{
        .root_source_file = b.path("quarantine/quarantine.zig"),
        .target = target,
        .optimize = optimize,
    });
    const util = b.createModule(.{
        .root_source_file = b.path("util/util.zig"),
        .target = target,
        .optimize = optimize,
    });
    const render = b.createModule(.{
        .root_source_file = b.path("render/render.zig"),
        .target = target,
        .optimize = optimize,
    });

    util.addImport("llm-code-quarantine", quarantine);

    render.addImport("main", main);
    render.addImport("render", render);

    render.addImport("zgl", zgl);
    render.addImport("mach-glfw", mach_glfw);
    render.addImport("zalgebra", zalgebra);
    render.addImport("util", util);
    render.addImport("llm-code-quarantine", quarantine);
    render.addImport("zigimg", zigimg);

    main.addImport("main", main);
    main.addImport("render", render);

    main.addImport("network", network);
    main.addImport("util", util);
    main.addImport("llm-code-quarantine", quarantine);

    return .{
        .main = main,
        .render = render,
        .util = util,
        .quarantine = quarantine,
    };
}

pub fn build(b: *std.Build) void {
    // Declare external dependencies
    const network = b.dependency("network", .{}).module("network");
    const mach_glfw = b.dependency("mach_glfw", .{}).module("mach_glfw");
    const zgl = b.dependency("zgl", .{}).module("zgl");
    const zalgebra = b.dependency("zalgebra", .{}).module("zalgebra");
    const zigimg = b.dependency("zigimg", .{}).module("zigimg");

    // Target & optimize options
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const headless = b.option(bool, "headless", "Run without a window") orelse false;
    const single_threaded = b.option(bool, "singlethreaded", "Build as single threaded") orelse false;

    const options = b.addOptions();
    options.addOption(bool, "headless", headless);

    {
        // Create main executable
        const mods = createModules(b, target, optimize, network, mach_glfw, zgl, zalgebra, zigimg);
        mods.main.addOptions("build_options", options);
        mods.main.single_threaded = single_threaded;
        const client = b.addExecutable(.{
            .name = "zig-client",
            .root_module = mods.main,
        });

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
        const test_main = b.addTest(.{ .root_module = mods.main });
        const test_render = b.addTest(.{ .root_module = mods.render });
        const test_util = b.addTest(.{ .root_module = mods.util });
        const test_quarantine = b.addTest(.{ .root_module = mods.quarantine });

        const test_step = b.step("test", "Run unit tests");
        test_step.dependOn(&b.addRunArtifact(test_render).step);
        test_step.dependOn(&b.addRunArtifact(test_util).step);
        test_step.dependOn(&b.addRunArtifact(test_quarantine).step);
        test_step.dependOn(&b.addRunArtifact(test_main).step);
    }

    // Add check step to see if client compiles without doing any codegen
    // https://github.com/tigerbeetle/tigerbeetle/pull/1538/commits/840308a4c5155f4af88257b8fc8143bf10e1a91a
    {
        const mods = createModules(b, target, optimize, network, mach_glfw, zgl, zalgebra, zigimg);
        mods.main.addOptions("build_options", options);
        const client = b.addExecutable(.{
            .name = "zig-client",
            .root_module = mods.main,
        });

        const check = b.step("check", "Check if client compiles");
        check.dependOn(&client.step);
    }
}
