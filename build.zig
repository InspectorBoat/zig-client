const std = @import("std");

const ModuleSet = struct {
    root: *std.Build.Module,
    render: *std.Build.Module,
    logging: *std.Build.Module,
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
) ModuleSet {
    const root = b.createModule(.{
        .root_source_file = b.path("main/main.zig"),
        .target = target,
        .optimize = optimize,
    });
    const logging = b.addModule("log", .{
        .root_source_file = b.path("logging/logging.zig"),
    });
    const quarantine = b.addModule("llm-code-quarantine", .{
        .root_source_file = b.path("quarantine/quarantine.zig"),
    });
    const util = b.addModule("util", .{
        .root_source_file = b.path("util/util.zig"),
    });
    const render = b.addModule("render", .{
        .root_source_file = b.path("render/render.zig"),
    });

    util.addImport("log", logging);
    util.addImport("llm-code-quarantine", quarantine);

    render.addImport("zgl", zgl);
    render.addImport("mach-glfw", mach_glfw);
    render.addImport("zalgebra", zalgebra);
    render.addImport("util", util);
    render.addImport("log", logging);
    render.addImport("llm-code-quarantine", quarantine);

    root.addImport("network", network);
    root.addImport("log", logging);
    root.addImport("render", render);
    root.addImport("util", util);
    root.addImport("llm-code-quarantine", quarantine);

    return .{
        .root = root,
        .render = render,
        .logging = logging,
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

    // Target & optimize options
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    {
        // Create main executable
        const mods = createModules(b, target, optimize, network, mach_glfw, zgl, zalgebra);
        const client = b.addExecutable(.{
            .name = "zig-client",
            .root_module = mods.root,
            .use_llvm = true,
            .use_lld = true,
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
        // Unit tests for main module
        const test_main = b.addTest(.{
            .root_module = b.createModule(.{
                .root_source_file = b.path("main/main.zig"),
                .target = target,
                .optimize = optimize,
            }),
            .use_llvm = true,
        });
        test_main.root_module.addImport("network", network);
        test_main.root_module.addImport("log", mods.logging);
        test_main.root_module.addImport("render", mods.render);
        test_main.root_module.addImport("util", mods.util);
        test_main.root_module.addImport("llm-code-quarantine", mods.quarantine);

        // Unit tests for render module
        const test_render = b.addTest(.{
            .root_module = b.createModule(.{
                .root_source_file = b.path("render/render.zig"),
                .target = target,
                .optimize = optimize,
            }),
            .use_llvm = true,
        });
        test_render.root_module.addImport("zgl", zgl);
        test_render.root_module.addImport("mach_glfw", mach_glfw);
        test_render.root_module.addImport("zalgebra", zalgebra);
        test_render.root_module.addImport("log", mods.logging);
        test_render.root_module.addImport("util", mods.util);
        test_render.root_module.addImport("llm-code-quarantine", mods.quarantine);

        const test_util = b.addTest(.{
            .root_module = b.createModule(.{
                .root_source_file = b.path("util/util.zig"),
                .target = target,
                .optimize = optimize,
            }),
            .use_llvm = true,
        });
        test_util.root_module.addImport("log", mods.logging);

        // Unit tests for llm generated shim modules
        const test_quarantine = b.addTest(.{
            .root_module = b.createModule(.{
                .root_source_file = b.path("quarantine/quarantine.zig"),
                .target = target,
                .optimize = optimize,
            }),
            .use_llvm = true,
        });

        const test_step = b.step("test", "Run unit tests");
        test_step.dependOn(&b.addRunArtifact(test_main).step);
        test_step.dependOn(&b.addRunArtifact(test_render).step);
        test_step.dependOn(&b.addRunArtifact(test_util).step);
        test_step.dependOn(&b.addRunArtifact(test_quarantine).step);
    }

    // Add check step to see if client compiles without doing any codegen
    // https://github.com/tigerbeetle/tigerbeetle/pull/1538/commits/840308a4c5155f4af88257b8fc8143bf10e1a91a
    {
        const mods = createModules(b, target, optimize, network, mach_glfw, zgl, zalgebra);
        const client = b.addExecutable(.{
            .name = "zig-client",
            .root_module = mods.root,
        });

        const check = b.step("check", "Check if client compiles");
        check.dependOn(&client.step);
    }
}
