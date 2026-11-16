import AppKit

let root = URL(fileURLWithPath: CommandLine.arguments[1])
let iconset = root.appendingPathComponent("Zooom.iconset")
try FileManager.default.createDirectory(at: iconset, withIntermediateDirectories: true)

func drawWindows() {
    NSColor.white.withAlphaComponent(0.55).setStroke()
    let back = NSBezierPath(roundedRect: NSRect(x: 232, y: 386, width: 460, height: 324), xRadius: 48, yRadius: 48)
    back.lineWidth = 38
    back.stroke()
    NSColor(calibratedRed: 0.12, green: 0.23, blue: 0.40, alpha: 1).setFill()
    let front = NSBezierPath(roundedRect: NSRect(x: 338, y: 280, width: 460, height: 324), xRadius: 48, yRadius: 48)
    front.fill()
    NSColor.white.setStroke()
    front.lineWidth = 38
    front.stroke()
    let line = NSBezierPath()
    line.move(to: NSPoint(x: 365, y: 518))
    line.line(to: NSPoint(x: 771, y: 518))
    line.lineWidth = 28
    line.stroke()
    // A small minus denotes hiding a window.
    let minus = NSBezierPath()
    minus.move(to: NSPoint(x: 512, y: 405))
    minus.line(to: NSPoint(x: 624, y: 405))
    minus.lineWidth = 32
    minus.lineCapStyle = .round
    minus.stroke()
}
func png(size: Int) -> Data {
    let bitmap = NSBitmapImageRep(bitmapDataPlanes: nil, pixelsWide: size, pixelsHigh: size,
        bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true, isPlanar: false,
        colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0)!
    NSGraphicsContext.saveGraphicsState()
    NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: bitmap)
    let transform = NSAffineTransform()
    transform.scale(by: CGFloat(size) / 1024)
    transform.concat()
    NSColor(calibratedRed: 0.12, green: 0.23, blue: 0.40, alpha: 1).setFill()
    NSBezierPath(roundedRect: NSRect(x: 64, y: 64, width: 896, height: 896), xRadius: 200, yRadius: 200).fill()
    drawWindows()
    NSGraphicsContext.restoreGraphicsState()
    return bitmap.representation(using: .png, properties: [:])!
}
for size in [16, 32, 128, 256, 512] {
    try png(size: size).write(to: iconset.appendingPathComponent("icon_\(size)x\(size).png"))
    try png(size: size * 2).write(to: iconset.appendingPathComponent("icon_\(size)x\(size)@2x.png"))
}
try png(size: 1024).write(to: root.appendingPathComponent("Zooom.png"))
