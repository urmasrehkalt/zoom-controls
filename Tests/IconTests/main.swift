import AppKit

let bundle = URL(fileURLWithPath: CommandLine.arguments[1])
let plistURL = bundle.appendingPathComponent("Contents/Info.plist")
let plist = NSDictionary(contentsOf: plistURL)!
precondition(plist["CFBundleIconFile"] as? String == "Zooom", "Bundle must declare its icon")
let icon = NSImage(contentsOf: bundle.appendingPathComponent("Contents/Resources/Zooom.icns"))
precondition(icon != nil && icon!.isValid, "App icon must decode")
let menu = MenuIcon.make()
precondition(menu.isTemplate, "Menu icon must adapt to light and dark mode")
precondition(menu.size == NSSize(width: 22, height: 18), "Menu icon must fit the status bar")
precondition(menu.accessibilityDescription == "Zooom", "Menu icon needs an accessible label")
let bitmap = NSBitmapImageRep(data: menu.tiffRepresentation!)!
try bitmap.representation(using: .png, properties: [:])!.write(to: URL(fileURLWithPath: "/tmp/zooom-menu-icon.png"))
print("PASS: Bundle icon, template rendering, dimensions and accessibility")
