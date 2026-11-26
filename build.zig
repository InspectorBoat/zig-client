const ModuleSet = struct {
    main: *std.Build.Module,
    render: *std.Build.Module,
    quarantine: *std.Build.Module,
};

fn createModules(
    b: *std.Build,
    target: std.Build.ResolvedTarget,
    optimize: std.builtin.OptimizeMode,
    tracy_enabled: bool,
    options: *std.Build.Module,
    mach_glfw: *std.Build.Module,
    zgl: *std.Build.Module,
    zalgebra: *std.Build.Module,
    zigimg: *std.Build.Module,
    tracy: *std.Build.Module,
    tracy_options: *std.Build.Module,
    assembly_helper: *std.Build.Module,
) ModuleSet {
    const main = b.createModule(.{
        .root_source_file = b.path("main/main.zig"),
        .target = target,
        .optimize = optimize,
        .omit_frame_pointer = optimize == .fast and !tracy_enabled,
        .strip = optimize == .fast and !tracy_enabled,
        .imports = &.{
            .{ .name = "build_options", .module = options },
            .{ .name = "localasm", .module = assembly_helper },
            .{ .name = "tracy", .module = tracy },
            .{ .name = "tracy_options", .module = tracy_options },
        },
    });
    const quarantine = b.createModule(.{
        .root_source_file = b.path("quarantine/quarantine.zig"),
        .target = target,
        .optimize = optimize,
        .imports = &.{
            .{ .name = "zalgebra", .module = zalgebra },
        },
    });
    const render = b.createModule(.{
        .root_source_file = b.path("render/render.zig"),
        .target = target,
        .optimize = optimize,
        .imports = &.{
            .{ .name = "build_options", .module = options },
            .{ .name = "localasm", .module = assembly_helper },
            .{ .name = "tracy", .module = tracy },
            .{ .name = "zgl", .module = zgl },
            .{ .name = "mach-glfw", .module = mach_glfw },
            .{ .name = "zalgebra", .module = zalgebra },
            .{ .name = "zigimg", .module = zigimg },
        },
    });

    quarantine.addImport("main", main);

    render.addImport("main", main);
    render.addImport("render", render);
    render.addImport("llm-code-quarantine", quarantine);

    main.addImport("main", main);
    main.addImport("render", render);
    main.addImport("llm-code-quarantine", quarantine);

    return .{
        .main = main,
        .render = render,
        .quarantine = quarantine,
    };
}

pub fn build(b: *std.Build) !void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const tracy_options_pkg = @import("tracy_options");
    var tracy_defs: tracy_options_pkg.Defs = .standard(b);
    const tracy_enabled = b.option(bool, "tracy", "Enable Tracy profiling") orelse false;
    tracy_defs.TRACY_ENABLE = tracy_enabled;

    const tracy = b.dependency("tracy", .{
        .target = target,
        .optimize = optimize,
    }).module("tracy");
    const tracy_options = b.dependency("tracy_options", tracy_defs.toArgs(.{
        .target = target,
        .optimize = optimize,
    })).module("tracy_options");
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

    const GraphicsMode = enum(u8) { normal, headless, silent };

    const graphics = b.option(GraphicsMode, "graphics", "Graphics mode: normal (default), headless (no rendering), silent (hidden window)") orelse .normal;
    const single_threaded = b.option(bool, "singlethreaded", "Build as single threaded") orelse false;
    const use_llvm = b.option(bool, "llvm", "Use llvm");
    const auth = b.option(bool, "auth", "Compile with auth support (requires http & crypto)") orelse (optimize == .debug);

    const options = b.addOptions();
    options.addOption(GraphicsMode, "graphics", graphics);
    options.addOption(bool, "auth", auth);
    options.addOption(bool, "tracy", tracy_enabled);
    const options_module = options.createModule();
    // Create main executable
    const mods = createModules(
        b,
        target,
        optimize,
        tracy_enabled,
        options_module,
        mach_glfw,
        zgl,
        zalgebra,
        zigimg,
        tracy,
        tracy_options,
        b.dependency("localasm", .{}).module("localasm"),
    );
    mods.main.single_threaded = single_threaded;
    const client = b.addExecutable(.{
        .name = "zig-client",
        .root_module = mods.main,
    });
    client.use_llvm = use_llvm;

    // Emit cleaned assembly via localasm
    const asm_file = localasm.addAsm(b, client, .prefix, "asm/asm.s");
    const asm_step = b.step("asm", "Emit cleaned assembly");
    asm_step.dependOn(&asm_file.step);

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
    const test_quarantine = b.addTest(.{ .root_module = mods.quarantine });

    const test_step = b.step("test", "Run unit tests");
    test_step.dependOn(&b.addRunArtifact(test_render).step);
    test_step.dependOn(&b.addRunArtifact(test_quarantine).step);
    test_step.dependOn(&b.addRunArtifact(test_main).step);

    const zsort = (try b.dependencyLazy("zsort", .{
        .target = b.graph.host,
        .optimize = .debug,
    })).artifact("zsort");

    const run_fix = b.addRunArtifact(zsort);
    run_fix.setCwd(b.path("."));
    run_fix.addArgs(&.{ "fix", ".", "--remove-unused", "--bottom" });
    b.step("fix", "Fix imports").dependOn(&run_fix.step);

    const run_check = b.addRunArtifact(zsort);
    run_check.setCwd(b.path("."));
    run_check.addArgs(&.{ "check", ".", "--remove-unused", "--bottom" });
    b.step("check", "Check imports").dependOn(&run_check.step);
}

const std = @import("std");

const localasm = @import("localasm");
