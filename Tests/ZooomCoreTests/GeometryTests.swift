import Foundation
import CoreGraphics
import ZooomCore
var failures = 0
func check(_ condition: @autoclosure () -> Bool, _ name: String) {
    if condition() { print("PASS: \(name)") }
    else { print("FAIL: \(name)"); failures += 1 }
}
let screens = [CGRect(x: 0, y: 0, width: 1920, height: 1080),
               CGRect(x: -1440, y: -900, width: 1440, height: 900)]
let point = Geometry.hiddenOrigin(screens: screens)!
let toolbar = CGRect(origin: point, size: CGSize(width: 900, height: 100))
check(screens.allSatisfy { !$0.intersects(toolbar) }, "Parking avoids all displays")
check(Geometry.hiddenOrigin(screens: []) == nil, "No display means no parking")
let original = CGRect(x: 200, y: 100, width: 900, height: 100)
let controller = VisibilityController()
var actual = original
var moves = 0
func move(_ point: CGPoint) -> CGRect? {
    moves += 1
    actual.origin = point
    return actual
}
check(controller.hide(frame: original, screens: screens, move: move), "Hide succeeds offscreen")
check(controller.savedFrame == original, "Original position retained")
let moveCount = moves
check(!controller.hide(frame: original, screens: screens, move: move), "Repeated hide rejected")
check(moves == moveCount, "Repeated hide does not overwrite recovery")
check(controller.restore(screens: screens, move: move), "Restore succeeds")
check(actual == original && controller.savedFrame == nil, "Toggle restores original position")
check(!controller.hide(frame: original, screens: screens, move: { _ in original }), "Clamped move is rejected")
check(controller.savedFrame == nil, "Clamped visible window needs no recovery")
check(!controller.hide(frame: original, screens: screens, move: { _ in nil }), "Move failure is reported")
check(controller.savedFrame == original, "Failed recovery retains original position")
check(!controller.restore(screens: [], move: move), "No display does not discard recovery")
check(controller.savedFrame != nil, "Recovery survives disconnected displays")
let smaller = [CGRect(x: 0, y: 0, width: 1024, height: 768)]
check(controller.restore(screens: smaller, move: move), "Restore clamps to remaining display")
check(smaller[0].contains(actual), "Restored toolbar is entirely visible")
check(controller.hide(frame: actual, screens: smaller, move: move), "Can hide again")
controller.forgetDestroyedWindow()
check(controller.savedFrame == nil, "Destroyed window clears stale recovery")
let oversized = CGRect(x: 0, y: 0, width: 2000, height: 100)
check(!controller.hide(frame: oversized, screens: [], move: move), "No screens prevents mutation")
let remote = CGRect(x: -1400, y: -850, width: 900, height: 100)
let restored = Geometry.restoreFrame(remote, screens: smaller)!
check(smaller[0].contains(restored), "Removed negative-coordinate display recovers on primary")
let strip = CGSize(width: 354, height: 22)
check(SharingToolbar.matches(strip, buttons: ["stop share", "dock to top"]), "Recognize compact strip")
check(!SharingToolbar.matches(strip, buttons: ["stop share"]), "Reject unrelated strip")
check(SharingToolbar.matches(original.size, buttons: ["stop share", "pause share"]), "Recognize full toolbar")
check(!SharingToolbar.matches(CGSize(width: 1200, height: 800), buttons: ["stop share", "pause share"]), "Reject meeting-sized window")
var prefs = HidePreferences()
check(prefs.automatic && prefs.allWindows, "Defaults automatically hide all windows")
check(prefs.includes(.camera) && prefs.includes(.other), "All includes camera and other windows")
prefs.allWindows = false
prefs.camera = false
check(!prefs.includes(.camera) && !prefs.includes(.other), "Selective scope excludes unselected windows")
check(prefs.includes(.strip) && prefs.includes(.toolbar), "Selected sharing controls included")
let encoded = try! JSONEncoder().encode(prefs)
let decoded = try! JSONDecoder().decode(HidePreferences.self, from: encoded)
check(!decoded.camera && !decoded.allWindows, "Preferences survive persistence")
var session = SharingSession()
check(!session.update(sharing: false, automatic: true), "No auto hide before sharing")
check(session.update(sharing: true, automatic: true), "Auto hide at sharing start")
session.reveal()
check(!session.update(sharing: true, automatic: true) && !session.hidden, "Manual reveal survives observation")
_ = session.update(sharing: false, automatic: true)
check(session.sharing, "Transient missing toolbar does not end session")
_ = session.update(sharing: true, automatic: true)
check(!session.hidden, "Transient absence does not undo manual reveal")
for _ in 0..<3 { _ = session.update(sharing: false, automatic: true) }
check(!session.sharing, "Sharing end confirmed")
check(session.update(sharing: true, automatic: true), "Next session hides again")
session.toggle()
check(!session.hidden, "Shortcut reveals")
session.toggle()
check(session.hidden, "Shortcut hides again")
var manual = SharingSession()
check(!manual.update(sharing: true, automatic: false) && !manual.hidden, "Automatic mode can be disabled")
let largeController = VisibilityController()
let largeWindow = CGRect(x: 0, y: 39, width: 1710, height: 1017)
let workArea = [CGRect(x: 0, y: 39, width: 1710, height: 978)]
var largeActual = largeWindow
func moveLarge(_ point: CGPoint) -> CGRect? {
    largeActual.origin = point
    return largeActual
}
check(largeController.hide(frame: largeWindow, screens: workArea, move: moveLarge), "Park tall meeting window")
check(largeController.restore(screens: workArea, move: moveLarge), "Restore window larger than work area")
check(largeController.savedFrame == nil, "Accessible oversized window releases recovery")
exit(failures == 0 ? 0 : 1)
