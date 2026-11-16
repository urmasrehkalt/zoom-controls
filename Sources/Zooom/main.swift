import AppKit
import Carbon
import ZooomCore

final class AppDelegate: NSObject, NSApplicationDelegate {
    let visibility = WindowVisibility()
    var session = SharingSession()
    var preferences = HidePreferences()
    var status: NSStatusItem!
    var message: NSMenuItem!
    var hotKey: EventHotKeyRef?
    var handler: EventHandlerRef?
    var timer: Timer?
    var lastDisplays: [CGRect] = []
    var shortcutAvailable = false
    var restorePending = false
    let preferenceKey = "hidePreferences"

    func applicationDidFinishLaunching(_ notification: Notification) {
        if let data = UserDefaults.standard.data(forKey: preferenceKey),
           let saved = try? JSONDecoder().decode(HidePreferences.self, from: data) {
            preferences = saved
        }
        status = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        status.button?.image = MenuIcon.make()
        status.button?.toolTip = "Zooom — hide / restore Zoom windows (⌃⌥Z)"
        status.button?.setAccessibilityLabel("Zooom")
        buildMenu()
        var eventType = EventTypeSpec(eventClass: OSType(kEventClassKeyboard), eventKind: UInt32(kEventHotKeyPressed))
        let result = InstallEventHandler(GetApplicationEventTarget(), { _, _, context in
            guard let context else { return OSStatus(eventNotHandledErr) }
            Unmanaged<AppDelegate>.fromOpaque(context).takeUnretainedValue().toggleControls()
            return noErr
        }, 1, &eventType, Unmanaged.passUnretained(self).toOpaque(), &handler)
        if result == noErr {
            let id = EventHotKeyID(signature: 0x5A4F4F4D, id: 1)
            shortcutAvailable = RegisterEventHotKey(UInt32(kVK_ANSI_Z), UInt32(controlKey | optionKey),
                id, GetApplicationEventTarget(), 0, &hotKey) == noErr
        }
        lastDisplays = Accessibility.displayBounds
        timer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { [weak self] _ in self?.checkEnvironment() }
        // Keep observing while the status menu is open.
        if let timer { RunLoop.main.add(timer, forMode: .common) }
        showStatus("Ready")
    }

    func buildMenu() {
        let menu = NSMenu()
        message = NSMenuItem(title: "Ready", action: nil, keyEquivalent: "")
        menu.addItem(message)
        add("Hide / restore selected windows (⌃⌥Z)", action: #selector(toggleControls), to: menu)
        add("Restore windows", action: #selector(restoreControls), to: menu)
        menu.addItem(.separator())
        let choices = [
            ("Hide automatically when sharing starts", preferences.automatic),
            ("All Zoom windows (including camera)", preferences.allWindows),
            ("Sharing toolbar", preferences.toolbar),
            ("Small Stop share strip", preferences.strip),
            ("Camera video panel", preferences.camera)
        ]
        for (index, choice) in choices.enumerated() {
            let item = add(choice.0, action: #selector(changePreference(_:)), to: menu)
            item.tag = index
            item.state = choice.1 ? .on : .off
            item.isEnabled = index < 2 || !preferences.allWindows
        }
        menu.autoenablesItems = false
        menu.addItem(.separator())
        add("Restore and quit", action: #selector(quitApp), to: menu)
        status.menu = menu
    }

    @discardableResult func add(_ title: String, action: Selector, to menu: NSMenu) -> NSMenuItem {
        let item = NSMenuItem(title: title, action: action, keyEquivalent: "")
        item.target = self
        menu.addItem(item)
        return item
    }

    func showStatus(_ text: String) {
        message.title = shortcutAvailable ? text : text + " — shortcut unavailable; use menu"
    }

    @objc func changePreference(_ item: NSMenuItem) {
        // Restore before changing scope so no window loses its recovery record.
        guard restoreControls() else { return }
        switch item.tag {
        case 0: preferences.automatic.toggle()
        case 1: preferences.allWindows.toggle()
        case 2: preferences.toolbar.toggle()
        case 3: preferences.strip.toggle()
        case 4: preferences.camera.toggle()
        default: return
        }
        if let data = try? JSONEncoder().encode(preferences) {
            UserDefaults.standard.set(data, forKey: preferenceKey)
        }
        buildMenu()
        showStatus("Settings saved")
    }

    @objc func toggleControls() {
        guard AXIsProcessTrusted() else {
            showStatus("Enable Zooom in System Settings → Accessibility")
            return
        }
        if session.hidden || visibility.hasRecovery {
            _ = restoreControls()
            return
        }
        guard let windows = Accessibility.windows(classify: !preferences.allWindows), !windows.isEmpty else {
            showStatus("No accessible Zoom windows")
            return
        }
        session.toggle()
        hide(windows)
    }

    func hide(_ windows: [ZoomWindow]) {
        let failures = visibility.hide(windows, preferences: preferences)
        if failures > 0 {
            session.reveal()
            showStatus("Could not hide \(failures) window(s); restoration remains available")
        } else if visibility.hasRecovery {
            showStatus("Hidden — ⌃⌥Z restores")
        } else {
            showStatus("No matching visible windows")
        }
    }

    @discardableResult @objc func restoreControls() -> Bool {
        session.reveal()
        let success = visibility.restore()
        restorePending = !success
        showStatus(success ? "Windows restored" : "Restore failed; retry before quitting")
        return success
    }

    func checkEnvironment() {
        guard AXIsProcessTrusted() else {
            showStatus("Enable Zooom in System Settings → Accessibility")
            return
        }
        if restorePending {
            _ = restoreControls()
            return
        }
        let displays = Accessibility.displayBounds
        if displays != lastDisplays {
            if restoreControls() { lastDisplays = displays }
            return
        }
        guard let windows = Accessibility.windows() else { return }
        let wasSharing = session.sharing
        let detected = windows.contains { $0.kind == .toolbar || $0.kind == .strip }
        // Hiding Zoom may remove its panels from AXWindows. That is not proof sharing ended.
        let sharing = detected || (session.sharing && visibility.hiddenApp?.isHidden == true)
        let shouldHide = session.update(sharing: sharing, automatic: preferences.automatic)
        if wasSharing && !session.sharing {
            _ = restoreControls()
        } else if shouldHide || session.hidden {
            hide(windows)
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
