// @file usart.zig
//
//  USART driver for trojan EC.
//  SPDX-License-Identifier: WTFPL
//

const std = @import("std");
const gpio = @import("gpio.zig");
const clock = @import("clock.zig");

pub const device = enum (usize) {
    USART1  = 0x50013800,
    USART2  = 0x50004400, 
    USART3  = 0x50004800,
    UART4   = 0x50004C00,
    UART5   = 0x50005000, 
    USART6  = 0x50006400,
    UART7   = 0x50007800,
    UART8   = 0x50007C00,
    UART9   = 0x50008000,
    USART10 = 0x50006800,
    USART11 = 0x50006C00,
    UART12  = 0x50008400,
    LPUART1 = 0x54002400, 
};

// We assume the FIFO is enabled, and does not generate interrupts.

const Cr1 = packed union {
    raw: u32,
    field: packed struct {
        usart_enable: bool,
        usart_enable_in_low_power_mode: bool,
        receiver_enable: bool,
        transmitter_enable: bool,
        idle_interrupt_enable: bool,
        receive_fifo_not_empty_interrupt_enable: bool,
        transmission_complete_interrupt_enable: bool,
        transmit_fifo_not_full_interrupt_enable: bool,
        parity_error_interrupt_enable: bool,
        parity_selection: bool,
        parity_control_enable: bool,
        receiver_wakeup_method: enum(u1) {
            IdleLine = 0,
            AddressMark = 1,
        },
        word_length_0: u1,
        mute_mode_enable: bool,
        character_match_interrupt_enable: bool,
        oversampling_mode: enum(u1) {
            Oversampling16 = 0,
            Oversampling8 = 1,
        },
        driver_enable_deassertion_time: u5,
        driver_enable_assertion_time: u5,
        receiver_timeout_interrupt_enable: bool,
        end_of_block_interrupt_enable: bool,
        word_length_1: u1,
        fifo_mode_enable: bool,
        txfifo_empty_interrupt_enable: bool,
        rxfifo_full_interrupt_enable: bool,
    },
};

const Cr2 = packed union {
    raw: u32,
    field: packed struct {
        synchronous_slave_mode_enable: bool,
        reserved0: u2,
        ignore_nss_input_pin: bool,
        address_detection: enum(u1) {
            Address4Bit = 0,
            Address7Bit = 1,
        },
        lin_break_detection_length: enum(u1) {
            Break10Bit = 0,
            Break11Bit = 1,
        },
        lin_break_detection_interrupt_enable: bool,
        reserved1: u1,
        last_bit_clock_pulse: bool,
        clock_phase: enum(u1) {
            FirstClock = 0,
            SecondClock = 1,
        },
        clock_polarity: enum(u1) {
            IdleLow = 0,
            IdleHigh = 1,
        },
        clock_enable: bool,
        stop_bits: enum(u2) {
            Stop1 = 0,
            Stop0_5 = 1,
            Stop2 = 2,
            Stop1_5 = 3,
        },
        lin_mode_enable: bool,
        swap_rx_tx: bool,
        rx_pin_active_level_invert: bool,
        tx_pin_active_level_invert: bool,
        data_invert: bool,
        msb_first: bool,
        auto_baud_rate_enable: bool,
        auto_baud_rate_mode: enum(u2) {
            StartBit = 0,
            FallingEdge = 1,
            Frame7F = 2,
            Frame55 = 3,
        },
        receiver_timeout_interrupt_enable: bool,
        address: u8,
    },
};

const Cr3 = packed union {
    raw: u32,
    field: packed struct {
        error_interrupt_enable: bool,
        irda_mode_enable: bool,
        irda_low_power: bool,
        half_duplex_selection: bool,
        smartcard_nack_enable: bool,
        smartcard_mode_enable: bool,
        dma_enable_for_receiver: bool,
        dma_enable_for_transmitter: bool,
        rts_enable: bool,
        cts_enable: bool,
        cts_interrupt_enable: bool,
        one_sample_bit_method_enable: bool,
        overrun_disable: bool,
        dma_disable_on_error: bool,
        driver_enable_mode: bool,
        driver_emable_polarity: enum(u1) {
            ActiveHigh = 0,
            ActiveLow = 1,
        },
        reserved: u1,
        smartcard_auto_retry_count: u3,
        wakeup_from_stop_mode_interrupt_flag: enum(u2) {
            AddressMatch = 0,
            Reserved = 1,
            StartBit = 2,
            RXNERXFNE = 3,
        },
        wakeup_from_stop_mode_interrupt_enable: bool,
        txfifo_threshold_interrupt_enable: bool,
        transmission_completion_interrupt_enable: bool,
        receiver_fifo_threshold_configuration: enum(u3) {
            OneEigth = 0,
            OneQuarter = 1,
            Half = 2,
            ThreeQuarters = 3,
            SevenEigths = 4,
            Full = 5,
        },
        rxfifo_threshold_interrupt_enable: bool,
        txfifo_threshold_configuration: enum(u3) {
            OneEigth = 0,
            OneQuarter = 1,
            Half = 2,
            ThreeQuarters = 3,
            SevenEigths = 4,
            Full = 5,
        },
    },
};

const Brr = packed union {
    raw: u32,
    field: packed struct {
        brr: u16,
        reserved: u16,
    },
};

const Gtpr = packed union {
    raw: u32,
    field: packed struct {
        prescaler: u8,
        guard_time: u8,
        reserved: u16,
    },
};

const Rtor = packed union {
    raw: u32,
    field: packed struct {
        receiver_timeout: u24,
        block_length: u8,
    },
};

const Rqr = packed union {
    raw: u32,
    field: packed struct {
        auto_baud_rate_request: bool,
        send_break_request: bool,
        mute_mode_request: bool,
        receive_data_flush_request: bool,
        transmit_data_flush_request: bool,
        reserved: u27,
    },
};

const Isr = packed union {
    raw: u32,
    field: packed struct {
        parity_error: bool,
        framing_error: bool,
        noise_detected: bool,
        overrun_error: bool,
        idle_line: bool,
        receive_fifo_not_empty: bool,
        transmission_complete: bool,
        transmit_fifo_not_full: bool,
        lin_break_detection: bool,
        cts_interrupt: bool,
        cts: bool,
        receiver_timeout: bool,
        end_of_block: bool,
        spi_slave_underrun_error: bool,
        auto_baud_rate_error: bool,
        auto_baud_rate: bool,
        busy: bool,
        character_match: bool,
        send_break: bool,
        receiver_wakeup_from_mute_mode: bool,
        wakeup_from_low_power_mode: bool,
        transmit_enable_acknowledge: bool,
        receive_enable_acknowledge: bool,
        txfifo_empty: bool,
        rxfifo_full: bool,
        transmission_complete_before_guard_time: bool,
        rxfifo_threshold: bool,
        txfifo_threshold: bool,
        reserved: u4,
    },
};

const Icr = packed union {
    raw: u32,
    field: packed struct {
        parity_error_clear: bool,
        framing_error_clear: bool,
        noise_detected_clear: bool,
        overrun_error_clear: bool,
        idle_line_clear: bool,
        txfifo_empty_clear: bool,
        transmission_complete_clear: bool,
        trasmission_complete_before_guard_time_clear: bool,
        lin_break_detection_clear: bool,
        cts_interrupt_clear: bool,
        reserved_0:u1,
        receiver_timeout_clear: bool,
        end_of_block_clear: bool,
        spi_slave_underrun_error_clear: bool,
        reserved_1:u3,
        character_match_clear: bool,
        reserved_2:u2,
        wakeup_from_low_power_mode_clear: bool,
        reserved_3:u11,
    },
};

const Rdr = packed union {
    raw: u32,
    field: packed struct {
        rdr: u8,
        reserved: u24,
    },
};

const Tdr = packed union {
    raw: u32,
    field: packed struct {
        tdr: u8,
        reserved: u24,
    },
};

const Presc = packed union {
    raw: u32,
    field: packed struct {
        prescaler: enum(u4) {
            Div1 = 0,
            Div2 = 1,
            Div4 = 2,
            Div6 = 3,
            Div8 = 4,
            Div10 = 5,
            Div12 = 6,
            Div16 = 7,
            Div32 = 8,
            Div64 = 9,
            Div128 = 10,
            Div256 = 11,
        },
        reserved: u28,
    },
};

const Usart = packed struct {
    cr1: Cr1,
    cr2: Cr2,
    cr3: Cr3,
    brr: Brr,
    gtpr: Gtpr,
    rtor: Rtor,
    rqr: Rqr,
    isr: Isr,
    icr: Icr,
    rdr: Rdr,
    tdr: Tdr,
    presc: Presc,
};

comptime {
    if(@sizeOf(Usart) != 0x30) {
        @compileError("Usart struct size is not correct");
    }
}

pub fn configure(usart: device, baud_rate: u32) void {
    const usart_ptr: * volatile Usart = @as(* volatile Usart, @ptrFromInt(@as(usize, @intFromEnum(usart))));

    var bus_clk: u32 = 0;
    if (usart == device.LPUART1) {
        bus_clk = clock.apb3clk();
    }
    else {
        if (usart == device.USART1) {
            bus_clk = clock.apb2clk();
        }
        else {
            bus_clk = clock.apb1clk();
        }
    }

    const brr_val: u16 = @truncate(bus_clk / baud_rate);
    var brr = Brr{ .raw = usart_ptr.brr.raw };
    brr.field.brr = brr_val;
    usart_ptr.brr.raw = brr.raw;

    var cr1 = Cr1{ .raw = usart_ptr.cr1.raw };
    cr1.field.usart_enable = true;
    cr1.field.transmitter_enable = true;
    cr1.field.receiver_enable = true;
    cr1.field.fifo_mode_enable = true;
    usart_ptr.cr1.raw = cr1.raw;
}

pub fn putchar(usart: device, data: u8) void {
    const usart_ptr: * volatile Usart = @as(* volatile Usart, @ptrFromInt(@as(usize, @intFromEnum(usart))));
    while (!usart_ptr.isr.field.transmit_fifo_not_full) {}
    var tdr = Tdr{ .raw = 0 };
    tdr.field.tdr = data;
    usart_ptr.tdr.raw = tdr.raw;
}
