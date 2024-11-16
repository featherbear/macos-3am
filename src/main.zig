const std = @import("std");
const c = @cImport({
    @cInclude("IOKit/pwr_mgt/IOPMLib.h");
});

fn createAssertion(assertionType: [*c]const u8) c.IOPMAssertionID {
    var assertion_id: c.IOPMAssertionID = 0;

    _ = c.IOPMAssertionCreateWithName(
        c.CFStringCreateWithCString(null, assertionType, c.kCFStringEncodingUTF8),
        c.kIOPMAssertionLevelOn,
        c.CFStringCreateWithCString(null, "awong6 test no sleep", c.kCFStringEncodingUTF8),
        &assertion_id,
    );

    return assertion_id;
}

pub fn main() !void {
    var allocatorBacking = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = allocatorBacking.allocator();

    var cmdline = std.ArrayList([]const u8).init(allocator);
    defer cmdline.deinit();

    var flags: struct { displayWake: bool, sleepWakeOnAC: bool, verbose: bool } = undefined;

    {
        var argsIter = try std.process.argsWithAllocator(allocator);
        defer argsIter.deinit();

        var captureCmdline = false;
        _ = argsIter.skip();
        while (argsIter.next()) |arg| {
            if (captureCmdline) {
                try cmdline.append(arg);
            } else {
                if (std.mem.eql(u8, arg, "-h") or std.mem.eql(u8, arg, "--help")) {
                    const stderr = std.io.getStdErr().writer();
                    try stderr.print("Usage: [OPTIONS] [-- [CMD]]\n", .{});
                    try stderr.print("\nPrevents the system from sleeping\n", .{});
                    try stderr.print("\nOptions:\n", .{});
                    try stderr.print("  -d, --display-wake   Keep display active\n", .{});
                    try stderr.print("  -s, --ac-wake        (On AC) Keep system active if lid closed or sleep requested\n", .{});
                    try stderr.print("  -h, --help           Display this help message\n", .{});
                    try stderr.print("\nOptions when CMD is present:\n", .{});
                    try stderr.print("  -v, --verbose        Output status information (optionally uses fd=3)\n", .{});
                    return;
                } else if (std.mem.eql(u8, arg, "-d") or std.mem.eql(u8, arg, "--display-wake")) {
                    flags.displayWake = true;
                } else if (std.mem.eql(u8, arg, "-s") or std.mem.eql(u8, arg, "--ac-wake")) {
                    flags.sleepWakeOnAC = true;
                } else if (std.mem.eql(u8, arg, "-v") or std.mem.eql(u8, arg, "--verbose")) {
                    flags.verbose = true;
                } else if (std.mem.eql(u8, arg, "--")) {
                    captureCmdline = true;
                }
            }
        }
    }

    // Either output to stderr, or to file descriptor 3 if it's open
    const stdlog = (std.fs.File{ .handle = if (std.c.fcntl(3, 1) != -1) 3 else std.io.getStdErr().handle }).writer();
    const isCmdline = cmdline.items.len != 0;

    if (flags.displayWake) {
        _ = createAssertion("NoDisplaySleepAssertion");
        if (!isCmdline or flags.verbose) {
            try stdlog.print("Display wake lock set.\n", .{});
        }
    } else {
        _ = createAssertion("NoIdleSleepAssertion");
        if (!isCmdline or flags.verbose) {
            try stdlog.print("Idle wake lock set.\n", .{});
        }
    }

    if (flags.sleepWakeOnAC) {
        _ = createAssertion("PreventSystemSleep");
        if (!isCmdline or flags.verbose) {
            try stdlog.print("AC wake lock set.\n", .{});
        }
    }

    if (!isCmdline) {
        try stdlog.print("Press [ENTER] to clear wake locks...", .{});
        _ = try std.io.getStdIn().reader().readByte();
    } else {
        const pid = try std.posix.fork();

        if (pid == 0) {
            // I think it's an illegal convention to use std.process.execv here but oh well
            switch (std.process.execv(allocator, cmdline.items)) {
                error.FileNotFound => {
                    try stdlog.print("Command not found.\n", .{});
                    return;
                },
                error.AccessDenied => {
                    try stdlog.print("Permission denied.\n", .{});
                    return;
                },
                else => {
                    try stdlog.print("Could not execute.\n", .{});
                    return;
                },
            }

            unreachable;
        } else if (pid > 0) {
            if (flags.verbose) {
                try stdlog.print("Waiting for process completion...\n", .{});
            }
            _ = std.posix.waitpid(pid, 0);
        }
    }

    if (!isCmdline or flags.verbose) {
        try stdlog.print("Wake locks cleared.\n", .{});
    }

    // _ = c.IOPMAssertionRelease(assertion_id);
}
