const std = @import("std");
const Build = std.Build;

const c_flags = &.{};

pub fn build(b: *Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const liburing = b.addStaticLibrary(.{
        .name = "uring",
        .target = target,
        .optimize = optimize,
        .link_libc = true,
    });
    liburing.addCSourceFiles(&.{
        "src/setup.c",
        "src/queue.c",
        "src/register.c",
        "src/syscall.c",
        "src/version.c",
    }, c_flags);
    liburing.addIncludePath(.{ .path = "src/include" });
    liburing.addIncludePath(.{ .path = "vendor" });
    liburing.installHeader("src/include/liburing.h", "liburing.h");
    liburing.installHeader("src/include/liburing/io_uring.h", "liburing/io_uring.h");
    liburing.installHeader("src/include/liburing/barrier.h", "liburing/barrier.h");
    liburing.installHeader("vendor/compat.h", "liburing/compat.h");
    liburing.installHeader("vendor/io_uring_version.h", "liburing/io_uring_version.h");
    b.installArtifact(liburing);
}
