import AppKit
import ZooomCore
import ApplicationServices

struct ZoomWindow {
    let element: AXUIElement
    let frame: CGRect
    let kind: ZoomWindowKind
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
    static func sharingButtons(_ element: AXUIElement, deadline: Date, remaining: inout Int, depth: Int = 0) -> Set<String> {
        guard depth < 6, remaining > 0, Date() < deadline else { return [] }
        remaining -= 1
        AXUIElementSetMessagingTimeout(element, 0.03)
        var result = Set<String>()
        if value(element, kAXRoleAttribute) as? String == kAXButtonRole {
            for key in [kAXTitleAttribute, kAXDescriptionAttribute, kAXHelpAttribute] {
                if let text = value(element, key) as? String { result.insert(text.lowercased()) }
            }
        }
        for child in value(element, kAXChildrenAttribute) as? [AXUIElement] ?? [] {
            guard remaining > 0, Date() < deadline else { break }
            result.formUnion(sharingButtons(child, deadline: deadline, remaining: &remaining, depth: depth + 1))
        }
        return result
    }
    static var app: NSRunningApplication? {
        NSRunningApplication.runningApplications(withBundleIdentifier: "us.zoom.xos").first
    }

    // nil denotes an unreadable snapshot, not the end of sharing.
    static func windows(classify: Bool = true) -> [ZoomWindow]? {
        guard let app else { return [] }
        let root = AXUIElementCreateApplication(app.processIdentifier)
        AXUIElementSetMessagingTimeout(root, 0.03)
        guard let elements = value(root, kAXWindowsAttribute) as? [AXUIElement] else { return nil }
        let deadline = Date().addingTimeInterval(0.15)
        var remaining = 150
        var result: [ZoomWindow] = []
        for window in elements {
            guard Date() < deadline else { return nil }
            AXUIElementSetMessagingTimeout(window, 0.03)
            guard let rect = frame(window) else { continue }
            let identifier = value(window, "AXIdentifier") as? String ?? ""
            let standard = value(window, kAXSubroleAttribute) as? String == kAXStandardWindowSubrole
            let inspectButtons = classify && identifier != "zm.meeting.window.main" &&
                !(standard && rect.height > 220)
            let buttons = inspectButtons ?
                sharingButtons(window, deadline: deadline, remaining: &remaining) : Set<String>()
            guard remaining > 0, Date() < deadline else { return nil }
            let kind: ZoomWindowKind
            if identifier != "zm.meeting.window.main",
               SharingToolbar.matches(rect.size, buttons: buttons) {
                kind = rect.height < 30 ? .strip : .toolbar
            } else if buttons.contains(where: {
                $0.contains("hide video panel") || $0.contains("show small active speaker video")
                    || $0.contains("show thumbnail video")
            }) {
                kind = .camera
            } else {
                kind = .other
            }
            result.append(ZoomWindow(element: window, frame: rect, kind: kind))
        }
        return result
    }

    static func visibleFrames() -> [CGRect]? {
        guard let app,
              let info = CGWindowListCopyWindowInfo(.optionOnScreenOnly, kCGNullWindowID) as? [[String: Any]]
        else { return nil }
        return info.compactMap { entry in
            guard entry[kCGWindowOwnerPID as String] as? Int == Int(app.processIdentifier),
                  let bounds = entry[kCGWindowBounds as String] as? [String: Any] else { return nil }
            return CGRect(dictionaryRepresentation: bounds as CFDictionary)
        }
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
