import AppKit
import Carbon
import ZooomCore

final class AppDelegate: NSObject, NSApplicationDelegate {
    let controller = VisibilityController()
    var tracked: AXUIElement?
    var status: NSStatusItem!
    var message: NSMenuItem!
    var hotKey: EventHotKeyRef?
    var handler: EventHandlerRef?
    var timer: Timer?
    var lastDisplays: [CGRect] = []

    func applicationDidFinishLaunching(_ notification: Notification) {
        status = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        status.button?.title = "Zooom"
        let menu = NSMenu()
        message = NSMenuItem(title: "Ready (experimental)", action: nil, keyEquivalent: "")
        menu.addItem(message)
        let toggle = NSMenuItem(title: "Hide / restore controls (⌃Esc)", action: #selector(toggleControls), keyEquivalent: "")
        toggle.target = self
        menu.addItem(toggle)
        let restore = NSMenuItem(title: "Restore controls", action: #selector(restoreControls), keyEquivalent: "")
        restore.target = self
        menu.addItem(restore)
        let quit = NSMenuItem(title: "Restore and quit", action: #selector(quitApp), keyEquivalent: "")
        quit.target = self
        menu.addItem(quit)
        status.menu = menu
        var eventType = EventTypeSpec(eventClass: OSType(kEventClassKeyboard), eventKind: UInt32(kEventHotKeyPressed))
        let result = InstallEventHandler(GetApplicationEventTarget(), { _, _, context in
            guard let context else { return OSStatus(eventNotHandledErr) }
            Unmanaged<AppDelegate>.fromOpaque(context).takeUnretainedValue().toggleControls()
            return noErr
        }, 1, &eventType, Unmanaged.passUnretained(self).toOpaque(), &handler)
        guard result == noErr else { message.title = "Hotkey handler unavailable"; return }
        let id = EventHotKeyID(signature: 0x5A4F4F4D, id: 1)
        guard RegisterEventHotKey(UInt32(kVK_Escape), UInt32(controlKey), id,
                                 GetApplicationEventTarget(), 0, &hotKey) == noErr else {
            message.title = "Control + Escape is unavailable"
            return
        }
        lastDisplays = Accessibility.displayBounds
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in self?.checkEnvironment() }
        if !AXIsProcessTrusted() { message.title = "Accessibility permission required; see README" }
    }
    @objc func toggleControls() {
        guard AXIsProcessTrusted() else {
            message.title = "Enable Zooom in System Settings → Accessibility"
            return
        }
        if controller.savedFrame != nil { restoreControls(); return }
        guard let window = Accessibility.toolbar() else {
            message.title = "No unique English sharing toolbar found"
            return
        }
        tracked = window.element
        lastDisplays = Accessibility.displayBounds
        let hidden = controller.hide(frame: window.frame, screens: Accessibility.displayBounds) {
            Accessibility.move(window.element, to: $0)
        }
        message.title = hidden ? "Controls parked; ⌃Esc restores" : "Parking failed; check Zoom controls"
        if controller.savedFrame == nil { tracked = nil }
    }
    @discardableResult @objc func restoreControls() -> Bool {
        guard let window = tracked else { return true }
        let success = controller.restore(screens: Accessibility.screens) { Accessibility.move(window, to: $0) }
        if success { tracked = nil; message.title = "Controls restored" }
        else { message.title = "Restore failed; retry before quitting" }
        return success
    }
    func checkEnvironment() {
        guard let window = tracked else { return }
        // AX invalidUIElement proves the old window no longer exists. Other errors retain recovery state.
        var pid: pid_t = 0
        AXUIElementGetPid(window, &pid)
        if pid > 0, NSRunningApplication(processIdentifier: pid) == nil {
            controller.forgetDestroyedWindow(); tracked = nil; message.title = "Zoom closed"
            return
        }
        var role: CFTypeRef?
        let error = AXUIElementCopyAttributeValue(window, kAXRoleAttribute as CFString, &role)
        if error == .invalidUIElement {
            controller.forgetDestroyedWindow(); tracked = nil; message.title = "Sharing window closed"
            return
        }
        let displays = Accessibility.displayBounds
        if displays != lastDisplays {
            if restoreControls() { lastDisplays = displays }
        } else if let frame = Accessibility.frame(window), displays.contains(where: { $0.intersects(frame) }) {
            // Zoom moved the toolbar back itself. Do not repeatedly fight its window management.
            _ = restoreControls()
        }
    }
    @objc func quitApp() { NSApp.terminate(nil) }
    func applicationShouldTerminate(_ sender: NSApplication) -> NSApplication.TerminateReply {
        restoreControls() ? .terminateNow : .terminateCancel
    }
    func applicationWillTerminate(_ notification: Notification) {
        timer?.invalidate()
        if let hotKey { UnregisterEventHotKey(hotKey) }
        if let handler { RemoveEventHandler(handler) }
    }
}
let app = NSApplication.shared
let delegate = AppDelegate()
app.delegate = delegate
app.setActivationPolicy(.accessory)
app.run()
