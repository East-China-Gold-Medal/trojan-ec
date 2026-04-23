// @file main.zig
//
//  Main entry of trojan EC.
//  SPDX-License-Identifier: WTFPL
//



const std = @import("std");
const isr = @import("isr.zig");
const gpio = @import("gpio.zig");
const reset_clock = @import("reset_clock.zig");

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
    reset_clock.enable(reset_clock.GPIOF, true);
    gpio.configure(gpio.Bank.F, 4, gpio.Mode.Output, gpio.Type.PushPull,
            gpio.Speed.Low, gpio.Pull.NoPull, gpio.AlternateFunction.AF0);
    gpio.set(gpio.Bank.F, 4, false);

    while (true) {}
}
