// @file build.zig
//
//  Program to control compiler behaviour.
//  SPDX-License-Identifier: WTFPL
//

const std = @import("std");

pub fn build(b: *std.Build) !void {
    const exe = b.addExecutable(.{
        .name = "trojan-ec",
        .root_module = b.createModule( .{
            .root_source_file = b.path("src/isr.zig"),
            .target = b.resolveTargetQuery(.{
                .cpu_arch = .thumb,
                .cpu_model = . {.explicit = &std.Target.arm.cpu.cortex_m33},
                .os_tag = .freestanding,
                .abi = .none
            }),
            .optimize = b.standardOptimizeOption(.{})
        }),
    });

    exe.setLinkerScript(b.path("image.ld"));
    exe.entry = .{.symbol_name="fakeEntry"};
    exe.is_linking_libc = false;
    exe.lto = .full;
    b.installArtifact(exe);

    const objcopy = b.addObjCopy(exe.getEmittedBin(), .{
        .format = .bin,
    });
    objcopy.step.dependOn(&exe.step);

    const install_bin = b.addInstallBinFile(objcopy.getOutput(), "trojan-ec.bin");
    b.getInstallStep().dependOn(&install_bin.step);
}
