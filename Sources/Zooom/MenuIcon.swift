import AppKit

enum MenuIcon {
    static func make() -> NSImage {
        let image = NSImage(size: NSSize(width: 22, height: 18), flipped: false) { _ in
            NSColor.black.setStroke()
            let back = NSBezierPath(roundedRect: NSRect(x: 2, y: 6, width: 13, height: 10), xRadius: 2, yRadius: 2)
            back.lineWidth = 1.5
            back.stroke()
            // Knock out the overlap so the front window remains clear at menu-bar size.
            NSGraphicsContext.current?.compositingOperation = .clear
            NSBezierPath(roundedRect: NSRect(x: 6, y: 1, width: 15, height: 12), xRadius: 2, yRadius: 2).fill()
            NSGraphicsContext.current?.compositingOperation = .sourceOver
            let front = NSBezierPath(roundedRect: NSRect(x: 7, y: 2, width: 13, height: 10), xRadius: 2, yRadius: 2)
            front.lineWidth = 1.5
            front.stroke()
            let minus = NSBezierPath()
            minus.move(to: NSPoint(x: 11, y: 6))
            minus.line(to: NSPoint(x: 16, y: 6))
            minus.lineWidth = 1.5
            minus.lineCapStyle = .round
            minus.stroke()
            return true
        }
        image.isTemplate = true
        image.accessibilityDescription = "Zooom"
        return image
    }
}
