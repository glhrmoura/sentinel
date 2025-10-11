import Foundation
import IOKit.pwr_mgt

final class PowerAssertion {
    private var assertionID: IOPMAssertionID = 0
    private var heldType: String?

    var isHeld: Bool { heldType != nil }

    func hold(keepDisplayAwake: Bool, reason: String) {
        let type = keepDisplayAwake
            ? kIOPMAssertionTypePreventUserIdleDisplaySleep as String
            : kIOPMAssertionTypePreventUserIdleSystemSleep as String
        if heldType == type { return }
        release()
        var newID: IOPMAssertionID = 0
        let result = IOPMAssertionCreateWithName(
            type as CFString,
            IOPMAssertionLevel(kIOPMAssertionLevelOn),
            reason as CFString,
            &newID
        )
        if result == kIOReturnSuccess {
            assertionID = newID
            heldType = type
        }
    }

    func release() {
        guard heldType != nil else { return }
        IOPMAssertionRelease(assertionID)
        assertionID = 0
        heldType = nil
    }

    deinit {
        release()
    }
}
