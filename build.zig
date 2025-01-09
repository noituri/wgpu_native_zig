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
    },
    TargetQuery {
        .cpu_arch = .x86_64,
        .os_tag = .windows,
    },
};

const WGPUBuildContext = struct {
    target: std.Build.ResolvedTarget,
    optimize: std.builtin.OptimizeMode,
    is_windows: bool,
    wgpu_dep: *std.Build.Dependency,
    libwgpu_path: std.Build.LazyPath,
    install_lib_dir: []const u8,
    wgpu_mod: *std.Build.Module,
    wgpu_c_mod: *std.Build.Module,

    fn init(b: *std.Build) ?WGPUBuildContext {
        // Standard target options allows the person running `zig build` to choose
        // what target to build for. Here we do not override the defaults, which
        // means any target is allowed, and the default is native. Other options
        // for restricting supported target set are available.
        const target = b.standardTargetOptions(.{
            .whitelist = &target_whitelist,
        });

        // Standard optimization options allow the person running `zig build` to select
        // between Debug, ReleaseSafe, ReleaseFast, and ReleaseSmall. Here we do not
        // set a preferred release mode, allowing the user to decide how to optimize.
        const optimize = b.standardOptimizeOption(.{});

        const target_res = target.result;
        const os_str = @tagName(target_res.os.tag);
        const arch_str = @tagName(target_res.cpu.arch);
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
            .root_source_file = wgpu_dep.path("wgpu.h"),

            .target = target,
            .optimize = optimize,
        });
        const wgpu_c_mod = translate_step.addModule("wgpu-c");
        wgpu_c_mod.resolved_target = target;
        wgpu_c_mod.link_libcpp = true;

        var libwgpu_path: std.Build.LazyPath = undefined;
        var is_windows: bool = false;

        switch(target_res.os.tag) {
            .windows => {
                is_windows = true;
                libwgpu_path = wgpu_dep.path("wgpu_native.dll.lib");

                // TODO: Find out if this propagates through when another module depends on this one; if not we may need to muck about with addNamedWriteFiles/addCopyFile.
                const dll_install_file = b.addInstallLibFile(wgpu_dep.path("wgpu_native.dll"), "wgpu_native.dll");
                b.getInstallStep().dependOn(&dll_install_file.step);

                wgpu_mod.addLibraryPath(wgpu_dep.path(""));
                wgpu_c_mod.addLibraryPath(wgpu_dep.path(""));

                // TODO: I think this has to be done by the thing that uses this module and not by the module itself?
                // wgpu_mod.linkSystemLibrary("wgpu_native.dll", .{});
                // wgpu_c_mod.linkSystemLibrary("wgpu_native.dll", .{});
            },
            else => {
                // This only tries to account for linux/macos since we're using pre-compiled wgpu-native;
                // need to think harder about this if I get custom builds working.
                libwgpu_path = wgpu_dep.path("libwgpu_native.a");
            },
        }
        wgpu_mod.addObjectFile(libwgpu_path);
        wgpu_c_mod.addObjectFile(libwgpu_path);


        return WGPUBuildContext {
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

    if (context.is_windows) {
        triangle_example_exe.linkSystemLibrary2("wgpu_native.dll", .{});

        run_triangle_cmd.addPathDir(context.install_lib_dir);
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
        t.addObjectFile(context.libwgpu_path);
        t.linkLibCpp();

        const run_test = b.addRunArtifact(t);

        if (context.is_windows) {
            t.addLibraryPath(context.wgpu_dep.path(""));
            t.linkSystemLibrary2("wgpu_native.dll", .{});

            run_test.addPathDir(context.install_lib_dir);
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
    if (context.is_windows) {
        compute_test.linkSystemLibrary2("wgpu_native.dll", .{});
        compute_test_c.linkSystemLibrary2("wgpu_native.dll", .{});

        run_compute_test.addPathDir(context.install_lib_dir);
        run_compute_test_c.addPathDir(context.install_lib_dir);

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
