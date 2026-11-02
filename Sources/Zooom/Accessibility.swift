import AppKit
import ApplicationServices

struct ZoomWindow {
    let element: AXUIElement
    let frame: CGRect
}

enum Accessibility {
    static func value(_ element: AXUIElement, _ key: String) -> CFTypeRef? {
        var result: CFTypeRef?
        guard AXUIElementCopyAttributeValue(element, key as CFString, &result) == .success else { return nil }
        return result
    }
    static func frame(_ element: AXUIElement) -> CGRect? {
        guard let p = value(element, kAXPositionAttribute),
              let s = value(element, kAXSizeAttribute),
              CFGetTypeID(p) == AXValueGetTypeID(), CFGetTypeID(s) == AXValueGetTypeID() else { return nil }
        var point = CGPoint.zero
        var size = CGSize.zero
        guard AXValueGetValue(p as! AXValue, .cgPoint, &point),
              AXValueGetValue(s as! AXValue, .cgSize, &size) else { return nil }
        return CGRect(origin: point, size: size)
    }
    // English Zoom only until other locales are verified. Never match the meeting window by size alone.
    static func sharingButtons(_ element: AXUIElement, depth: Int = 0) -> Set<String> {
        guard depth < 6 else { return [] }
        var result = Set<String>()
        if value(element, kAXRoleAttribute) as? String == kAXButtonRole {
            for key in [kAXTitleAttribute, kAXDescriptionAttribute, kAXHelpAttribute] {
                if let text = value(element, key) as? String { result.insert(text.lowercased()) }
            }
        }
        for child in value(element, kAXChildrenAttribute) as? [AXUIElement] ?? [] {
            result.formUnion(sharingButtons(child, depth: depth + 1))
        }
        return result
    }
    static func toolbar() -> ZoomWindow? {
        guard let app = NSRunningApplication.runningApplications(withBundleIdentifier: "us.zoom.xos").first else { return nil }
        let root = AXUIElementCreateApplication(app.processIdentifier)
        AXUIElementSetMessagingTimeout(root, 0.5)
        let windows = value(root, kAXWindowsAttribute) as? [AXUIElement] ?? []
        let candidates = windows.compactMap { window -> ZoomWindow? in
            guard let rect = frame(window), rect.width >= 250, rect.height >= 30,
                  rect.height <= 220,
                  value(window, "AXIdentifier") as? String != "zm.meeting.window.main" else { return nil }
            let buttons = sharingButtons(window)
            guard buttons.contains("stop share"), buttons.contains("pause share") else { return nil }
            var settable = DarwinBoolean(false)
            guard AXUIElementIsAttributeSettable(window, kAXPositionAttribute as CFString, &settable) == .success,
                  settable.boolValue else { return nil }
            return ZoomWindow(element: window, frame: rect)
        }
        return candidates.count == 1 ? candidates[0] : nil
    }
    static func move(_ window: AXUIElement, to point: CGPoint) -> CGRect? {
        var position = point
        guard let value = AXValueCreate(.cgPoint, &position),
              AXUIElementSetAttributeValue(window, kAXPositionAttribute as CFString, value) == .success else { return nil }
        return frame(window)
    }
    static var screens: [CGRect] {
        // AX uses a top-left origin, AppKit a bottom-left origin. The primary display is first.
        guard let primary = NSScreen.screens.first else { return [] }
        return NSScreen.screens.map {
            CGRect(x: $0.visibleFrame.minX, y: primary.frame.maxY - $0.visibleFrame.maxY,
                   width: $0.visibleFrame.width, height: $0.visibleFrame.height)
        }
    }
    static var displayBounds: [CGRect] {
        guard let primary = NSScreen.screens.first else { return [] }
        return NSScreen.screens.map {
            CGRect(x: $0.frame.minX, y: primary.frame.maxY - $0.frame.maxY,
                   width: $0.frame.width, height: $0.frame.height)
        }
    }
}
