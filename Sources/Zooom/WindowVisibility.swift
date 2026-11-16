import AppKit
import ZooomCore

final class WindowVisibility {
    struct Parked {
        let element: AXUIElement
        let controller: VisibilityController
    }
    var parked: [Parked] = []
    var hiddenApp: NSRunningApplication?
    var hasRecovery: Bool { !parked.isEmpty || hiddenApp != nil }

    func hide(_ windows: [ZoomWindow], preferences: HidePreferences) -> Int {
        if preferences.allWindows, hiddenApp == nil, let app = Accessibility.app, !app.isHidden {
            // Keep recovery even if hide reports failure: Zoom can hide asynchronously.
            hiddenApp = app
            _ = app.hide()
        }
        let visibleFrames = Accessibility.visibleFrames()
        var failures = 0
        for window in windows where preferences.includes(window.kind) {
            if parked.contains(where: { CFEqual($0.element, window.element) }) { continue }
            // Zoom may keep floating panels visible even when the application is hidden.
            if hiddenApp?.isHidden == true, let visibleFrames,
               !visibleFrames.contains(where: { $0 == window.frame }) { continue }
            guard Accessibility.displayBounds.contains(where: { $0.intersects(window.frame) }) else { continue }
            let controller = VisibilityController()
            if !controller.hide(frame: window.frame, screens: Accessibility.displayBounds, move: {
                Accessibility.move(window.element, to: $0)
            }) { failures += 1 }
            if controller.savedFrame != nil {
                parked.append(Parked(element: window.element, controller: controller))
            }
        }
        return failures
    }

    @discardableResult func restore() -> Bool {
        // Unhide first: Zoom may refuse AX window movement while its application is hidden.
        if let app = hiddenApp ?? Accessibility.app {
            if app.isTerminated {
                hiddenApp = nil
                parked.removeAll()
                return true
            }
            if app.isHidden {
                hiddenApp = app
                _ = app.unhide()
                _ = app.activate(options: [.activateAllWindows])
                guard !app.isHidden else { return false }
            }
            hiddenApp = nil
        }
        parked.removeAll { item in
            var role: CFTypeRef?
            if AXUIElementCopyAttributeValue(item.element, kAXRoleAttribute as CFString, &role) == .invalidUIElement {
                return true
            }
            return item.controller.restore(screens: Accessibility.screens) {
                Accessibility.move(item.element, to: $0)
            }
        }
        return !hasRecovery
    }
}
