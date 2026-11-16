# Zoom Controls

A small native macOS menu-bar app for moving Zoom's screen-sharing controls out of the way and bringing them back.

Zoom Controls hides Zoom windows automatically when screen sharing starts, or on command. It can hide the whole Zoom application or move selected sharing controls and the camera panel outside the visible displays, retaining their positions for restoration. The installed app is named **Zooom** and appears as a window icon in the menu bar.

**Experimental:** automated tests cover window geometry and recovery logic. A complete live Zoom screen-sharing session has not been verified. Try it in a disposable meeting before relying on it.

## Features

- **Control + Option + Z** toggles hiding and restoring the selected windows.
- Automatic hiding starts when an English sharing toolbar or compact sharing strip is detected.
- Hide all Zoom windows, or select the full sharing toolbar, compact strip and camera panel independently.
- Menu preferences persist locally between launches.
- A manual reveal keeps windows visible until another shortcut press or the next detected sharing session.

Automatic hiding and **All Zoom windows (including camera)** are enabled by default. Launching the helper during an active sharing session can therefore hide Zoom windows as soon as sharing is detected.

## Requirements

- macOS 13 or later.
- Swift 5.9 or later, available through Xcode or Xcode Command Line Tools.
- The Zoom desktop app with its interface set to English.
- Accessibility permission for **Zooom**.

The app has no third-party package dependencies. No API keys, environment variables, server, or production credentials are required.

## Build and install

Download or clone the repository and open a terminal in its root directory. To build the version described here:

```sh
git switch main
./scripts/test.sh
./scripts/build-app.sh
```

The build script creates `dist/Zooom.app` and applies an ad-hoc development signature. It does not install or launch the app.

For a first installation, copy the bundle to a stable location and launch it:

```sh
mkdir -p "$HOME/Applications"
cp -R dist/Zooom.app "$HOME/Applications/"
open "$HOME/Applications/Zooom.app"
```

Open **System Settings → Privacy & Security → Accessibility**, add the installed **Zooom.app** if necessary, and enable it. The app checks permission but does not grant it or open a permission request automatically.

Before replacing an existing installation, choose **Restore and quit**. Rebuilding with an ad-hoc signature may require reauthorizing Accessibility access. If you use a persistent signing identity, use the same identity for updates to preserve signing continuity.

## Use

1. Start a disposable Zoom meeting and begin sharing your screen.
2. Make Zoom's sharing controls visible. The helper detects the English full toolbar or compact sharing strip and hides all Zoom windows by default.
3. Press **Control + Option + Z** or choose **Hide / restore selected windows** in the menu to reveal them. Press it again to hide them.
4. To hide only selected controls, turn off **All Zoom windows (including camera)** and choose the desired toolbar, strip or camera options. Changing preferences restores windows first; the new selection applies on the next hide.
5. To use only manual control, turn off **Hide automatically when sharing starts**.
6. Choose **Restore and quit** when finished.

| Menu item | Action |
| --- | --- |
| Hide / restore selected windows | Toggle visibility using the current window selection |
| Restore windows | Attempt to restore the hidden Zoom application and any parked windows |
| Hide automatically when sharing starts | Enable or disable automatic hiding |
| All Zoom windows (including camera) | Hide the Zoom application and any remaining visible Zoom windows |
| Sharing toolbar / Small Stop share strip / Camera video panel | Choose individual window types when all-windows mode is off |
| Restore and quit | Restore windows, then quit; remain running if restoration fails |

The menu's first line reports the current status. Ordinary **Escape** is not registered, intercepted, suppressed, or synthesized by the helper. The app does not click meeting controls or send keyboard input to Zoom.

## Recovery and troubleshooting

Window movement can be rejected by macOS or undone by Zoom. All-windows mode hides the Zoom application first, then attempts to move any remaining visible windows offscreen. Individual mode moves only the selected window types. The helper verifies offscreen movement and retains recovery state if restoration fails. Display changes trigger an attempt to restore windows onto an available display.

| Status or symptom | What to check |
| --- | --- |
| Accessibility permission required | Enable the installed Zooom app in Accessibility settings |
| No accessible Zoom windows | Check that Zoom is running and Accessibility permission is enabled |
| No matching visible windows | Show the sharing controls and check the menu's window selection; detection expects English control labels |
| Shortcut unavailable | Use the menu controls and check whether another app has registered Control + Option + Z |
| Could not hide one or more windows | Movement may have been refused or constrained; use **Restore windows** to recover |
| Restore failed | Keep the helper running and retry **Restore windows** before quitting or changing permissions |

Use **Restore windows** before revoking Accessibility permission. Recovery state exists only in memory: force-quitting the helper, a crash, or revoking permission can leave windows hidden or offscreen.

If recovery fails, try Zoom's own control for showing its floating meeting controls. Its ability to recover an offscreen toolbar is unverified. If needed, finish the meeting normally through Zoom's main window, then restart Zoom. Avoid restarting Zoom during an active meeting just to recover the toolbar.

When hidden Zoom windows disappear from Accessibility's window list, the helper retains recovery state. It cannot reliably detect a new sharing session while those windows remain absent; use **Restore windows** if needed. Camera-panel detection and different Zoom toolbar layouts still require live verification.

### Remove the app

Choose **Restore and quit**, remove the installed `Zooom.app`, and remove its entry from Accessibility settings. The helper does not install a login item, launch agent, or background service.

## Privacy and permissions

- All processing takes place locally. The app makes no network requests and includes no analytics or telemetry.
- Accessibility access is used to inspect Zoom's window geometry and control labels, and to move its windows.
- The helper does not capture screen images, audio, video, or meeting transcripts. It does not request Screen Recording or Input Monitoring permission.
- Menu preferences are stored locally in UserDefaults. Window recovery state is not persisted across launches.

Accessibility is a broad macOS permission; the implementation limits its window inspection to the Zoom application. The bundle identifier is retained for compatibility with existing installations.

## Development

| Path | Purpose |
| --- | --- |
| [Sources/Zooom](Sources/Zooom) | Menu-bar app, global shortcut and Accessibility adapter |
| [Sources/ZooomCore](Sources/ZooomCore) | Window geometry and recovery logic |
| [Tests/ZooomCoreTests](Tests/ZooomCoreTests) | Standalone Swift assertions for the core behavior |
| [scripts/build-app.sh](scripts/build-app.sh) | Release build and app-bundle packaging |
| [Package.swift](Package.swift) | Swift package definition |

Run checks from the repository root:

```sh
./scripts/test.sh
./scripts/build-app.sh
./scripts/test-icons.sh
python3 scripts/test-readme.py
python3 scripts/test-privacy.py
```

The documentation and privacy checks require Python 3. The privacy check scans tracked files and branch/tag history for personal references, allowing the existing bundle identifier for installation compatibility. Core tests run as a Swift executable and do not require XCTest, a running Zoom instance, or production services. The app build uses a temporary Swift build directory and writes its bundle to `dist/`.

Run the icon checks after building; they inspect the app bundle and menu-bar icon rendering.

### Live integration checklist

Automated checks cannot establish that a particular Zoom version permits offscreen window movement. Before relying on a build, verify these behaviors in a disposable meeting:

- [ ] The intended toolbar is detected and no unrelated window moves.
- [ ] Repeated hide / restore operations work through both the shortcut and menu.
- [ ] Ordinary Escape behaves normally in the foreground application.
- [ ] The meeting, screen sharing and recording remain uninterrupted.
- [ ] Display changes and disconnection allow the toolbar to be recovered.
- [ ] Failed movement, missing permission and shortcut conflicts are handled visibly.
- [ ] **Restore and quit** restores the toolbar before closing.
- [ ] Automatic hiding, individual window selections, saved preferences and new sharing sessions behave as expected.

### Contributing

Start with a GitHub issue containing a description and acceptance criteria. Work on a separate branch, add relevant automated checks, and run the applicable tests before proposing a merge. Keep unrelated feature work separate.

Historical commits imported before the standalone extraction refer to issue numbers in the original repository. New issue numbers belong to this repository.
