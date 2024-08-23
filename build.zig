const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const module = b.addModule("oauth2", .{
        .root_source_file = b.path("src/oauth2.zig"),
        .target = target,
        .optimize = optimize,
    });

    const url = b.dependency("url", .{
        .target = target,
        .optimize = optimize,
    });

    module.addImport("url", url.module("url"));

    const unit_tests = b.addTest(.{
        .root_source_file = b.path("src/oauth2_test.zig"),
        .target = target,
        .optimize = optimize,
    });
    unit_tests.root_module.addImport("oauth2", module);
    const run_unit_tests = b.addRunArtifact(unit_tests);

    const test_step = b.step("test", "Run unit tests");
    test_step.dependOn(&run_unit_tests.step);
}
