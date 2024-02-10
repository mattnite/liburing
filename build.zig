const std = @import("std");
const Build = std.Build;

const version = .{
    .major = "2",
    .minor = "5",
};

pub fn build(b: *Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const link_libc = b.option(bool, "link_libc", "Whether to link libc") orelse true;
    const have_kernel_rwf_t = b.option(bool, "have_kernel_rwf_t", "") orelse true;
    const have_kernel_timespec = b.option(bool, "have_kernel_timespec", "") orelse true;
    const have_open_how = b.option(bool, "have_open_how", "") orelse true;
    const have_futexv = b.option(bool, "have_futexv", "") orelse true;
    const have_idtype_t = b.option(bool, "have_idtype_t", "") orelse true;

    const generate_version_h = b.addExecutable(.{
        .name = "generate-version-h",
        .root_source_file = .{ .path = "zig/generate_version_h.zig" },
    });

    const run_version_h = b.addRunArtifact(generate_version_h);
    run_version_h.addArgs(&.{
        "--version-major", version.major,
        "--version-minor", version.minor,
    });
    run_version_h.addArg("-o");
    const version_h = run_version_h.addOutputFileArg("io_uring_version.h");
    const install_version_h = b.addInstallFile(version_h, "include/liburing/io_uring_version.h");

    const generate_compat_h = b.addExecutable(.{
        .name = "generate-compat-h",
        .root_source_file = .{ .path = "zig/generate_compat_h.zig" },
    });

    const run_compat_h = b.addRunArtifact(generate_compat_h);
    if (have_kernel_rwf_t)
        run_compat_h.addArg("--have-kernel-rwf-t");
    if (have_kernel_timespec)
        run_compat_h.addArg("--have-kernel-timespec");
    if (have_open_how)
        run_compat_h.addArg("--have-open-how");
    if (have_futexv)
        run_compat_h.addArg("--have-futexv");
    if (have_idtype_t)
        run_compat_h.addArg("--have-idtype-t");
    run_compat_h.addArg("-o");
    const compat_h = run_compat_h.addOutputFileArg("compat.h");
    const install_compat_h = b.addInstallFile(compat_h, "include/liburing/compat.h");

    const install_headers = b.addInstallDirectory(.{
        .source_dir = .{ .path = "src/include" },
        .install_dir = .{ .header = {} },
        .install_subdir = "",
    });

    const uring = b.addStaticLibrary(.{
        .name = "uring",
        .target = target,
        .optimize = optimize,
        .link_libc = link_libc,
    });
    uring.defineCMacro("_GNU_SOURCE", null);
    uring.addCSourceFiles(srcs, &.{});
    if (!link_libc)
        uring.addCSourceFile(.{
            .file = .{ .path = "src/nolibc.c" },
            .flags = &.{},
        });

    uring.addIncludePath(.{ .path = b.getInstallPath(.{ .header = {} }, "") });
    uring.step.dependOn(&install_version_h.step);
    uring.step.dependOn(&install_compat_h.step);
    uring.step.dependOn(&install_headers.step);
    b.installArtifact(uring);
}

const srcs = &.{
    "src/register.c",
    "src/queue.c",
    "src/syscall.c",
    "src/setup.c",
    "src/version.c",
};
