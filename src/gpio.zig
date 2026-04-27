// @file gpio.zig
//
//  GPIO driver for trojan EC.
//  SPDX-License-Identifier: WTFPL
//

const std = @import("std");
const GPIO_BASE = 0x52020000;
const GPIO_SHIFT: comptime_int = 10; //0x400
pub const Mode = enum(u2) {
    Input = 0,
    Output = 1,
    AlternateFunction = 2,
    Analog = 3,
};
pub const Type = enum(u1) {
    PushPull = 0,
    OpenDrain = 1,
};
pub const Speed = enum(u2) {
    Low = 0,
    Medium = 1,
    High = 2,
    VeryHigh = 3,
};
pub const Pull = enum(u2) {
    NoPull = 0,
    PullUp = 1,
    PullDown = 2,
    Reserved = 3,
};
pub const AlternateFunction = enum(u4) {
    AF0 = 0,
    AF1 = 1,
    AF2 = 2,
    AF3 = 3,
    AF4 = 4,
    AF5 = 5,
    AF6 = 6,
    AF7 = 7,
    AF8 = 8,
    AF9 = 9,
    AF10 = 10,
    AF11 = 11,
    AF12 = 12,
    AF13 = 13,
    AF14 = 14,
    AF15 = 15,
};
pub const Bank = enum(u3) {
    A = 0,
    B = 1,
    C = 2,
    D = 3,
    E = 4,
    F = 5,
    G = 6,
    H = 7,
};

pub fn set(bank: Bank, pin: u4, val: bool) void {
    const gpio_base: usize = GPIO_BASE + (@as(usize, @intFromEnum(bank)) << GPIO_SHIFT);
    var reg = @as(* volatile u32, @ptrFromInt(gpio_base + 0x18)).*;
    const pin_off = @as(u5, pin) | ((@as(u5, @intFromBool(val)) << 4));
    reg |= @as(u32,1) << pin_off;
    @as(* volatile u32, @ptrFromInt(gpio_base + 0x18)).* = reg;
}

pub fn read(bank: Bank, pin: u4) bool {
    const gpio_base: usize = GPIO_BASE + (@as(usize, @intFromEnum(bank)) << GPIO_SHIFT);
    return (@as(* volatile u32, @ptrFromInt(gpio_base + 0x10)).* & (1 << pin)) != 0;
}

pub fn reset(bank: Bank, pin: u4) void {
    const gpio_base: usize = GPIO_BASE + (@as(usize, @intFromEnum(bank)) << GPIO_SHIFT);
    @as(* volatile u32, @ptrFromInt(gpio_base + 0x18)).* = 1 << (pin + 16);
}

pub fn configure(bank: Bank, pin: u4, mode: Mode, type_: Type, speed: Speed, pull: Pull, alternate: AlternateFunction) void {
    const gpio_base: usize = GPIO_BASE + (@as(usize, @intFromEnum(bank)) << GPIO_SHIFT);
    var val: u32 = 0;
    const pin_val: u4 = @as(u4, pin);
    // moder.
    val = @as(* volatile u32, @ptrFromInt(gpio_base + 0x00)).*;
    val &= ~(@as(u32, 0b11) << (pin_val << 1));
    val |= @as(u32, @intFromEnum(mode)) << (pin_val << 1 );
    @as(* volatile u32, @ptrFromInt(gpio_base + 0x00)).* = val;

    // otyper.
    val = @as(* volatile u32, @ptrFromInt(gpio_base + 0x04)).*;
    val &= ~(@as(u32, 0b1) << pin_val);
    val |= @as(u32, @intFromEnum(type_)) << pin_val;
    @as(* volatile u32, @ptrFromInt(gpio_base + 0x04)).* = val;

    // ospeedr.
    val = @as(* volatile u32, @ptrFromInt(gpio_base + 0x08)).*;
    val &= ~(@as(u32, 0b11) << (pin_val << 1));
    val |= @as(u32, @intFromEnum(speed)) << (pin_val << 1);
    @as(* volatile u32, @ptrFromInt(gpio_base + 0x08)).* = val;

    // pupdr.
    val = @as(* volatile u32, @ptrFromInt(gpio_base + 0x0C)).*;
    val &= ~(@as(u32, 0b11) << (pin_val << 1));
    val |= @as(u32, @intFromEnum(pull)) << (pin_val << 1);
    @as(* volatile u32, @ptrFromInt(gpio_base + 0x0C)).* = val;
    
    if (mode == Mode.AlternateFunction) {
        if (pin < 8) {
            val = @as(* volatile u32, @ptrFromInt(gpio_base + 0x20)).*;
            val &= ~(@as(u32, 0b1111) << (pin_val << 2));
            val |= @as(u32, @intFromEnum(alternate)) << (pin_val << 2);
            @as(* volatile u32, @ptrFromInt(gpio_base + 0x20)).* = val;
        } else {
            val = @as(* volatile u32, @ptrFromInt(gpio_base + 0x24)).*;
            val &= ~(@as(u32, 0b1111) << ((pin_val - 8) << 2));
            val |= @as(u32, @intFromEnum(alternate)) << ((pin_val - 8) << 2);
            @as(* volatile u32, @ptrFromInt(gpio_base + 0x24)).* = val;
        }
    }
}
