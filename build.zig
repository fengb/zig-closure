const Builder = @import("std").build.Builder;

pub fn build(b: *Builder) void {
    const mode = b.standardReleaseOptions();
    const lib = b.addStaticLibrary("zig-closure", "src/main.zig");
    lib.setBuildMode(mode);
    lib.install();

    var main_tests = b.addTest("src/main.zig");
    main_tests.setBuildMode(mode);
    main_tests.addIncludeDir("src");
    main_tests.addCSourceFile("src/test.c", &[_][]const u8{});

    const test_step = b.step("test", "Run library tests");
    test_step.dependOn(&main_tests.step);
}
