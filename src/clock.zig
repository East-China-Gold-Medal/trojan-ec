// @file clock.zig
//
//  Reset & Clock (RCC) driver for trojan EC.
//  SPDX-License-Identifier: WTFPL
//

const ResetClockControl = struct {
    reset_reg_offset: u9,
    enable_reg_offset: u9,
    offset: u5,
};
const RCC_BASE = 0x44020C00;

pub const GPIOF = ResetClockControl{ .reset_reg_offset = 0x64, .enable_reg_offset = 0x8C, .offset = 5 };
pub const GPIOD = ResetClockControl{ .reset_reg_offset = 0x64, .enable_reg_offset = 0x8C, .offset = 3 };
pub const USART3 = ResetClockControl{ .reset_reg_offset = 0x74, .enable_reg_offset = 0x9C, .offset = 3 };

pub fn enable(clock: ResetClockControl, val: bool) void {
    var reg = @as(* volatile u32, @ptrFromInt(@as(usize,RCC_BASE) + clock.enable_reg_offset)).*;
    reg &= ~(@as(u32, 1) << clock.offset);
    reg |= (@as(u32, @intFromBool(val)) << clock.offset);
    @as(* volatile u32, @ptrFromInt(@as(usize,RCC_BASE) + clock.enable_reg_offset)).* = reg;
}

pub fn reset(clock: ResetClockControl, val: bool) void {
    var reg = @as(* volatile u32, @ptrFromInt(@as(usize,RCC_BASE) + clock.reset_reg_offset)).*;
    reg &= ~(@as(u32, 1) << clock.offset);
    reg |= (@as(u32, @intFromBool(val)) << clock.offset);
    @as(* volatile u32, @ptrFromInt(@as(usize,RCC_BASE) + clock.reset_reg_offset)).* = reg;
}

pub fn sysclk() u32 {
    // TODO: Auto Detection.
    return 32000000;
}

pub fn apb1clk() u32 {
    // TODO: Auto Detection.
    return 32000000;
}

pub fn apb2clk() u32 {
    // TODO: Auto Detection.
    return 32000000;
}

pub fn apb3clk() u32 {
    // TODO: Auto Detection.
    return 32000000;
}
