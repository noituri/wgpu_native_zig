const std = @import("std");

const TargetQuery = std.Target.Query;

// All the targets for which a pre-compiled build of wgpu-native is currently (as of July 9, 2024) available
const target_whitelist = [_] TargetQuery {
    TargetQuery {
        .cpu_arch = .aarch64,
        .os_tag = .linux,
    },
    TargetQuery {
        .cpu_arch = .aarch64,
        .os_tag = .macos,
    },
    TargetQuery {
        .cpu_arch = .x86_64,
        .os_tag = .linux,
    },
    TargetQuery {
        .cpu_arch = .x86_64,
        .os_tag = .macos,
    },
    TargetQuery {
        .cpu_arch = .x86,
        .os_tag = .windows,
        .abi = .msvc,
    },
    TargetQuery {
        .cpu_arch = .x86_64,
        .os_tag = .windows,
        .abi = .msvc,
    },
};

// The whitelist function in standardTargetOptionsQueryOnly matches *exact* targets,
// so unless you get extremely specific it will give false negatives and none of the targets will match when one of them should.
// This is a way to get around that while still not allowing just any target.
fn match_target_whitelist(target: std.Target) bool {
    var found = false;
    for (target_whitelist) |query| {
        if (target.os.tag == query.os_tag and target.cpu.arch == query.cpu_arch) {
            if (query.abi != null) {
                if (query.abi == target.abi) {
                    found = true;
                    break;
                }
            } else {
                found = true;
                break;
            }
        }
    }

    return found;
}

fn link_windows_system_libraries(comptime T: type, mod: *T) void {
    const linkSystemLibrary = switch (T) {
        std.Build.Module => std.Build.Module.linkSystemLibrary,
        std.Build.Step.Compile => std.Build.Step.Compile.linkSystemLibrary2,
        else => @compileError("Provided type must either be std.Build.Module or std.Build.Step.Compile"),
    };
    linkSystemLibrary(mod, "D3DCompiler", .{});
    linkSystemLibrary(mod, "opengl32", .{});
    linkSystemLibrary(mod, "user32", .{});
    linkSystemLibrary(mod, "gdi32", .{});
    linkSystemLibrary(mod, "ws2_32", .{});
    linkSystemLibrary(mod, "advapi32", .{});
    linkSystemLibrary(mod, "userenv", .{});
    linkSystemLibrary(mod, "bcrypt", .{});
}


const WGPUBuildContext = struct {
    link_mode: std.builtin.LinkMode,
    target: std.Build.ResolvedTarget,
    optimize: std.builtin.OptimizeMode,
    is_windows: bool,
    wgpu_dep: *std.Build.Dependency,
    libwgpu_path: ?std.Build.LazyPath,
    install_lib_dir: []const u8,
    wgpu_mod: *std.Build.Module,
    wgpu_c_mod: *std.Build.Module,

    fn init(b: *std.Build) ?WGPUBuildContext {
        const link_mode = b.option(std.builtin.LinkMode, "link_mode", "Use static linking instead of dynamic linking.") orelse .static;
        // Standard target options allows the person running `zig build` to choose
        // what target to build for. Here we do not override the defaults, which
        // means any target is allowed, and the default is native. Other options
        // for restricting supported target set are available.
        const target = b.standardTargetOptions(.{});

        // Standard optimization options allow the person running `zig build` to select
        // between Debug, ReleaseSafe, ReleaseFast, and ReleaseSmall. Here we do not
        // set a preferred release mode, allowing the user to decide how to optimize.
        const optimize = b.standardOptimizeOption(.{
            .preferred_optimize_mode = .Debug,
        });

        const target_res = target.result;
        const os_str = @tagName(target_res.os.tag);
        const arch_str = @tagName(target_res.cpu.arch);
        if (!match_target_whitelist(target_res)) {
            // TODO: Fail step here
            std.log.err("Target {s}-{s}-{s} does match any supported target", .{arch_str, os_str, @tagName(target_res.abi)});
        }
        const mode_str = switch (optimize) {
            .Debug => "debug",
            else => "release",
        };
        const target_name_slices = [_] [:0]const u8 {"wgpu_", os_str, "_", arch_str, "_", mode_str};
        const maybe_target_name = std.mem.concatWithSentinel(b.allocator, u8, &target_name_slices, 0);
        const target_name = maybe_target_name catch "wgpu_linux_x86_64_debug";

        const wgpu_mod = b.addModule("wgpu", .{
            .root_source_file = b.path("src/root.zig"),
            .target = target,
            .optimize = optimize,
            .link_libcpp = true,
        });

        const wgpu_dep = b.lazyDependency(target_name, .{}) orelse return null;

        const translate_step = b.addTranslateC(.{
            // wgpu.h imports webgpu.h, so we get the contents of both files, as well as a bunch of libc garbage.
            .root_source_file = wgpu_dep.path("include/wgpu/wgpu.h"),

            .target = target,
            .optimize = optimize,
        });

        // TODO: Zig 0.14 has a way to do this with a LazyPath, so not quite as messy.
        translate_step.addIncludeDir(wgpu_dep.path("include/webgpu").getPath2(b, &translate_step.step));

        const wgpu_c_mod = translate_step.addModule("wgpu-c");
        wgpu_c_mod.resolved_target = target;
        wgpu_c_mod.link_libcpp = true;

        var libwgpu_path: ?std.Build.LazyPath = null;
        var is_windows: bool = false;

        // TODO: When we upgrade wgpu-native, we'll need to at least switch on both os and abi, since the x86_64 build for Windows now supports both gnu and msvc.
        // There are also a number of new os and cpu architecture options, so this might need to be broken out into a separate function.
        switch(target_res.os.tag) {
            .windows => {
                is_windows = true;

                // I feel like libcpp should work, but it definitely does not on msvc. Fortunately libc does.
                wgpu_mod.link_libcpp = false;
                wgpu_c_mod.link_libcpp = false;
                wgpu_mod.link_libc = true;
                wgpu_c_mod.link_libc = true;

                if (link_mode == .static) {
                    if (target_res.abi != .msvc) {
                        // TODO: This should not be neccessary after we upgrade wgpu-native.
                        // Also this should really be a fail step, but I'd need Zig 0.14 for that, and there are other things that currently break in 0.14.
                        @panic("Static linking on Windows currently only supported for MSVC");
                    }
                    libwgpu_path = wgpu_dep.path("lib/wgpu_native.lib");


                    link_windows_system_libraries(std.Build.Module, wgpu_mod);
                    link_windows_system_libraries(std.Build.Module, wgpu_c_mod);
                } else {
                    libwgpu_path = wgpu_dep.path("lib/wgpu_native.dll.lib");

                    // Unfortunately, it seems only the local tests can access the dll this way.
                    // For dependees, it copies to the zig cache, which you can use for testing if you do some weird stuff with the install steps,
                    // but it never copies to the output folder. So not helpful if you need to distribute a binary with the dll alongside it.
                    const dll_install_file = b.addInstallLibFile(wgpu_dep.path("lib/wgpu_native.dll"), "wgpu_native.dll");
                    b.getInstallStep().dependOn(&dll_install_file.step);

                    // For dependees that need the dll file, this seems to be the only reliable way to propagate it through.
                    // In Zig 0.14 there seems to be some method for exposing LazyPaths to dependees, which might be a bit cleaner.
                    const writeFiles = b.addNamedWriteFiles("lib");
                    _ = writeFiles.addCopyFile(wgpu_dep.path("lib/wgpu_native.dll"), "wgpu_native.dll");
                }
            },

            // This only tries to account for linux/macos since we're using pre-compiled wgpu-native;
            // need to think harder about this if I get custom builds working.
            else => if (link_mode == .static) {
                libwgpu_path = wgpu_dep.path("lib/libwgpu_native.a");
            } else {
                const so_install_file = b.addInstallLibFile(wgpu_dep.path("lib/libwgpu_native.so"), "libwgpu_native.so");
                b.getInstallStep().dependOn(&so_install_file.step);

                const writeFiles = b.addNamedWriteFiles("lib");
                _ = writeFiles.addCopyFile(wgpu_dep.path("lib/libwgpu_native.so"), "libwgpu_native.so");
            },
        }

        if (libwgpu_path != null) {
            wgpu_mod.addObjectFile(libwgpu_path.?);
            wgpu_c_mod.addObjectFile(libwgpu_path.?);
        }


        return WGPUBuildContext {
            .link_mode = link_mode,
            .target = target,
            .optimize = optimize,
            .is_windows = is_windows,
            .wgpu_dep = wgpu_dep,
            .libwgpu_path = libwgpu_path,
            .install_lib_dir = b.getInstallPath(.lib, ""),
            .wgpu_mod = wgpu_mod,
            .wgpu_c_mod = wgpu_c_mod,
        };
    }
};

fn dynamic_link(context: *const WGPUBuildContext, c: *std.Build.Step.Compile, cmd: *std.Build.Step.Run) void {
        if (!context.is_windows) {
            c.addLibraryPath(context.wgpu_dep.path("lib"));
            c.linkSystemLibrary2("wgpu_native", .{});
        }
        cmd.addPathDir(context.install_lib_dir);
}

fn triangle_example(b: *std.Build, context: *const WGPUBuildContext) void {
    const bmp_mod = b.createModule(.{
        .root_source_file = b.path("examples/bmp.zig"),
    });

    const triangle_example_exe = b.addExecutable(.{
        .name = "triangle-example",
        .root_source_file = b.path("examples/triangle/triangle.zig"),
        .target = context.target,
        .optimize = context.optimize,
    });
    triangle_example_exe.root_module.addImport("wgpu", context.wgpu_mod);
    triangle_example_exe.root_module.addImport("bmp", bmp_mod);

    const run_triangle_cmd = b.addRunArtifact(triangle_example_exe);

    const run_triangle_step = b.step("run-triangle-example", "Run the triangle example");
    run_triangle_step.dependOn(&run_triangle_cmd.step);

    if (context.link_mode == .dynamic) {
        dynamic_link(context, triangle_example_exe, run_triangle_cmd);

        run_triangle_step.dependOn(b.getInstallStep());
    }
}

fn unit_tests(b: *std.Build, context: *const WGPUBuildContext) void {
    const unit_test_step = b.step("test", "Run unit tests");
    if (context.is_windows) {
        unit_test_step.dependOn(b.getInstallStep());
    }

    const test_files = [_] [:0]const u8 {
        "src/instance.zig",
        "src/adapter.zig",
        "src/pipeline.zig",
    };
    comptime var test_names: [test_files.len] [:0]const u8 = test_files;
    comptime for (test_files, 0..) |test_file, idx| {
        const test_name = test_file[4..(test_file.len - 4)] ++ "-test";
        test_names[idx] = test_name;
    };

    for (test_files, test_names) |test_file, test_name| {
        const t = b.addTest(.{
            .name = test_name,
            .root_source_file = b.path(test_file),
            .target = context.target,
            .optimize = context.optimize,
        });
        if (context.libwgpu_path != null) {
            t.addObjectFile(context.libwgpu_path.?);
        }
        if (context.is_windows) {
            t.linkLibC();
        } else {
            t.linkLibCpp();
        }

        const run_test = b.addRunArtifact(t);

        if (context.link_mode == .dynamic) {
            dynamic_link(context, t, run_test);
        } else if (context.is_windows) {
            link_windows_system_libraries(std.Build.Step.Compile, t);
        }

        unit_test_step.dependOn(&run_test.step);
    }
}

fn compute_tests(b: *std.Build, context: *const WGPUBuildContext) void {
    const compute_test = b.addTest(.{
        .name = "compute-test",
        .root_source_file = b.path("tests/compute.zig"),
        .target = context.target,
        .optimize = context.optimize,
    });
    compute_test.root_module.addImport("wgpu", context.wgpu_mod);

    const run_compute_test = b.addRunArtifact(compute_test);

    const compute_test_c = b.addTest(.{
        .name = "compute-test-c",
        .root_source_file = b.path("tests/compute_c.zig"),
        .target = context.target,
        .optimize = context.optimize,
    });
    compute_test_c.root_module.addImport("wgpu-c", context.wgpu_c_mod);

    const run_compute_test_c = b.addRunArtifact(compute_test_c);

    const compute_test_step = b.step("compute-tests", "Run compute shader tests");
    if (context.link_mode == .dynamic) {
        dynamic_link(context, compute_test, run_compute_test);
        dynamic_link(context, compute_test_c, run_compute_test_c);

        compute_test_step.dependOn(b.getInstallStep());
    }
    compute_test_step.dependOn(&run_compute_test.step);
    compute_test_step.dependOn(&run_compute_test_c.step);
}

// Although this function looks imperative, note that its job is to
// declaratively construct a build graph that will be executed by an external
// runner.
pub fn build(b: *std.Build) void {
    const context = WGPUBuildContext.init(b) orelse return;

    compute_tests(b, &context);
    unit_tests(b, &context);

    triangle_example(b, &context);
}
