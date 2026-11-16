import CoreGraphics

public enum SharingToolbar {
    public static func matches(_ size: CGSize, buttons: Set<String>) -> Bool {
        guard size.width >= 250, size.height > 0, size.height <= 220 else { return false }
        let companion = size.height < 30 ? "dock to top" : "pause share"
        return buttons.contains("stop share") && buttons.contains(companion)
    }
}
