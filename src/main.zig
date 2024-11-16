const std = @import("std");
const c = @cImport({
    @cInclude("IOKit/pwr_mgt/IOPMLib.h");
});

pub fn main() !void {
    var assertion_id: c.IOPMAssertionID = 0;

    for ([_][*c]const u8{
        // !!! Use this one
        // Description: This prevents the display from going to sleep, but does not prevent the system from entering full sleep mode.
        // Use Case: When you want to keep the display on (e.g., during media playback or presentations) but still allow the system to sleep in other respects, such as turning off the hard drive or putting the system to sleep after a period of inactivity.
        // Effect: The display stays awake, but the system may still sleep (e.g., the CPU or disk may go to sleep).
        // ! This one is used by video playback
        // "NoDisplaySleepAssertion", // screen stays on

        // This one is more specific, only for idle transitions
        // Description: This prevents the display from going to sleep when the user is idle.
        // Use Case: Useful in cases where you want to ensure that the display remains active even if the user is not interacting with the system (e.g., in kiosks, digital signage, or if the system is performing a task that requires visual feedback).
        // Effect: Display sleep is prevented when the user is idle, but the system could still go to sleep or enter other sleep states based on the system's own inactivity settings.
        // ! This one is used by audio devices
        // "PreventUserIdleDisplaySleep", // screen stays on

        //
        //
        //

        // !!! Use this one
        // Description: Prevents idle sleep, which is sleep triggered after a period of user inactivity.
        // Use Case: This would be used when you need to keep the system awake due to some activity (like a process running in the background) but don’t need to prevent display sleep or system sleep entirely.
        // Effect: The system will not go to sleep due to inactivity, but other sleep behaviors (such as display sleep) might still be allowed
        // ! This one is used by audio devices
        "NoIdleSleepAssertion", // screen goes off and asks for password

        // Description: Prevents the system from entering sleep due to user inactivity.
        // Use Case: This is often used in situations where you don’t want the system to sleep while the user isn’t actively interacting with it but are okay with other forms of system sleep or energy-saving behaviors.
        // Effect: Prevents system sleep triggered by user idle time, but other sleep or power-saving behaviors (like display sleep or disk sleep) may still occur.
        // "PreventUserIdleSystemSleep", // screen went off, kept running and asked for password

        //
        //
        //

        // Description: This assertion prevents the system from entering sleep mode entirely, regardless of user activity or inactivity.
        // Use Case: You would use this assertion when you want to make sure that the entire system remains awake, such as during long-running background tasks or when a critical application needs uninterrupted system resources.
        // Effect: System sleep is fully prevented.
        "PreventSystemSleep", // this works only on AC
        //
        //
        //
    }) |assertionType| {
        _ = c.IOPMAssertionCreateWithName(
            c.CFStringCreateWithCString(null, assertionType, c.kCFStringEncodingUTF8),
            c.kIOPMAssertionLevelOn,
            c.CFStringCreateWithCString(null, "awong6 test no sleep", c.kCFStringEncodingUTF8),
            &assertion_id,
        );
    }

    std.debug.print("Sleep blocked.\n", .{});
    _ = try std.io.getStdIn().reader().readByte();

    std.debug.print("System sleep allowed again.\n", .{});
    // _ = c.IOPMAssertionRelease(assertion_id);
}
