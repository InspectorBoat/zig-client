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
    options: *std.Build.Module,
    mach_glfw: *std.Build.Module,
    zgl: *std.Build.Module,
    zalgebra: *std.Build.Module,
    zigimg: *std.Build.Module,
) ModuleSet {
    const main = b.createModule(.{
        .root_source_file = b.path("main/main.zig"),
        .target = target,
        .optimize = optimize,
        .omit_frame_pointer = optimize == .fast,
        .strip = optimize == .fast,
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

    quarantine.addImport("main", main);
    quarantine.addImport("zalgebra", zalgebra);

    util.addImport("llm-code-quarantine", quarantine);

    render.addImport("main", main);
    render.addImport("render", render);
    render.addImport("build_options", options);

    render.addImport("zgl", zgl);
    render.addImport("mach-glfw", mach_glfw);
    render.addImport("zalgebra", zalgebra);
    render.addImport("util", util);
    render.addImport("llm-code-quarantine", quarantine);
    render.addImport("zigimg", zigimg);

    main.addImport("main", main);
    main.addImport("render", render);
    main.addImport("build_options", options);

    main.addImport("util", util);
    main.addImport("llm-code-quarantine", quarantine);

    return .{
        .main = main,
        .render = render,
        .util = util,
        .quarantine = quarantine,
    };
}

pub fn build(b: *std.Build) !void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});
    // Declare external dependencies
    const mach_glfw = b.dependency("mach_glfw", .{
        .optimize = optimize,
        .target = target,
    }).module("mach_glfw");
    const zgl = b.dependency("zgl", .{
        .optimize = optimize,
        .target = target,
    }).module("zgl");
    const zalgebra = b.dependency("zalgebra", .{
        .optimize = optimize,
        .target = target,
    }).module("zalgebra");
    const zigimg = b.dependency("zigimg", .{
        .optimize = optimize,
        .target = target,
    }).module("zigimg");

    const graphics = b.option(enum { normal, headless, silent }, "graphics", "Graphics mode: normal (default), headless (no rendering), silent (hidden window)") orelse .normal;
    const single_threaded = b.option(bool, "singlethreaded", "Build as single threaded") orelse false;
    const use_llvm = b.option(bool, "llvm", "Use llvm");
    const auth = b.option(bool, "auth", "Compile with auth support (requires http & crypto)") orelse (optimize == .debug);

    const options = b.addOptions();
    options.addOption(@TypeOf(graphics), "graphics", graphics);
    options.addOption(bool, "auth", auth);
    const options_module = options.createModule();
    {
        // Create main executable
        const mods = createModules(b, target, optimize, options_module, mach_glfw, zgl, zalgebra, zigimg);
        mods.main.single_threaded = single_threaded;
        const client = b.addExecutable(.{
            .name = "zig-client",
            .root_module = mods.main,
        });
        client.use_llvm = use_llvm;

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

    const zsort = (try b.dependencyLazy("zsort", .{
        .target = b.graph.host,
        .optimize = .debug,
    })).artifact("zsort");

    const run_fix = b.addRunArtifact(zsort);
    run_fix.setCwd(b.path("."));
    run_fix.addArgs(&.{ "fix", ".", "--remove-unused", "--bottom" });
    b.step("fix", "Fix imports").dependOn(&run_fix.step);
}

const std = @import("std");
