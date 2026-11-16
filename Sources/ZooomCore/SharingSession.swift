import Foundation

public struct HidePreferences: Codable {
    public var automatic = true
    public var allWindows = true
    public var toolbar = true
    public var strip = true
    public var camera = true

    public init() {}
    public func includes(_ kind: ZoomWindowKind) -> Bool {
        if allWindows { return true }
        switch kind {
        case .toolbar: return toolbar
        case .strip: return strip
        case .camera: return camera
        case .other: return false
        }
    }
}

public enum ZoomWindowKind {
    case toolbar, strip, camera, other
}

/// A manual reveal lasts for the current sharing session.
public struct SharingSession {
    public private(set) var sharing = false
    public private(set) var hidden = false
    private var absentSamples = 0
    public init() {}

    public mutating func update(sharing detected: Bool, automatic: Bool) -> Bool {
        if detected {
            absentSamples = 0
            if !sharing {
                sharing = true
                hidden = automatic
                return automatic
            }
        } else if sharing {
            absentSamples += 1
            if absentSamples >= 3 {
                sharing = false
                hidden = false
            }
        }
        return false
    }

    public mutating func toggle() { hidden.toggle() }
    public mutating func reveal() { hidden = false }
}
