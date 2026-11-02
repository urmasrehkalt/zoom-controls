import Foundation
import CoreGraphics
public enum Geometry {
    public static func hiddenOrigin(screens: [CGRect]) -> CGPoint? {
        guard let right = screens.map(\.maxX).max(), let bottom = screens.map(\.maxY).max() else { return nil }
        return CGPoint(x: right + 100, y: bottom + 100)
    }
    public static func restoreFrame(_ original: CGRect, screens: [CGRect]) -> CGRect? {
        guard let screen = screens.first(where: { $0.contains(original) }) ?? screens.first else { return nil }
        let x = min(max(original.minX, screen.minX), max(screen.minX, screen.maxX - original.width))
        let y = min(max(original.minY, screen.minY), max(screen.minY, screen.maxY - original.height))
        return CGRect(origin: CGPoint(x: x, y: y), size: original.size)
    }
}

/// Keeps the recovery location until an actual visible position is verified.
public final class VisibilityController {
    public private(set) var savedFrame: CGRect?
    public init() {}
    public func hide(frame: CGRect, screens: [CGRect], move: (CGPoint) -> CGRect?) -> Bool {
        guard savedFrame == nil, screens.contains(where: { $0.intersects(frame) }),
              let target = Geometry.hiddenOrigin(screens: screens) else { return false }
        savedFrame = frame
        if let actual = move(target), screens.allSatisfy({ !$0.intersects(actual) }) { return true }
        _ = restore(screens: screens, move: move)
        return false
    }
    public func restore(screens: [CGRect], move: (CGPoint) -> CGRect?) -> Bool {
        guard let original = savedFrame else { return true }
        guard let target = Geometry.restoreFrame(original, screens: screens),
              let actual = move(target.origin), screens.contains(where: { $0.contains(actual) }) else { return false }
        savedFrame = nil
        return true
    }
    /// Only call after the original Zoom process has terminated or the tracked window was destroyed.
    public func forgetDestroyedWindow() { savedFrame = nil }
}
