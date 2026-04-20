// @file main.zig
//
//  Main entry of trojan EC.
//  SPDX-License-Identifier: WTFPL
//



const std = @import("std");
const isr = @import("isr.zig");

extern var data_begin: usize;
extern var data_end: usize;
extern var data_addr_in_flash: usize;
extern var bss_begin: usize;
extern var bss_end: usize;

comptime {
    @export(&start, .{ .name = "_start", .linkage = .strong });
}

pub fn start() callconv(.c) void {
    const data_len = @intFromPtr(&data_end) - @intFromPtr(&data_begin);
    const src = @as([*]u8, @ptrCast(&data_addr_in_flash));
    const dst = @as([*]u8, @ptrCast(&data_begin));
    @memcpy(dst[0..data_len], src[0..data_len]);

    const bss_len = @intFromPtr(&bss_end) - @intFromPtr(&bss_begin);
    const bss = @as([*]u8, @ptrCast(&bss_begin));
    @memset(bss[0..bss_len], 0);

    // Add logic here.

    while (true) {}
}
