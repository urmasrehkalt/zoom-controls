# Zoom Controls

A small native macOS menu-bar app for moving Zoom's screen-sharing controls out of the way and bringing them back.

Zoom Controls uses macOS Accessibility APIs to move the sharing toolbar outside the visible displays, remembers its original position, and restores it on command. The installed app and its menu-bar entry are named **Zooom**.

**Experimental:** automated tests cover window geometry and recovery logic. A complete live Zoom screen-sharing session has not been verified. Try it in a disposable meeting before relying on it.

## Available versions

This README describes the code on `main`. Additional functionality is being developed separately:

| Behavior | `main` | `feature/1-standalone` |
| --- | --- | --- |
| Global hide / restore shortcut | **Control + Escape** | **Control + Option + Z** |
| What can be hidden | One matching sharing toolbar | All Zoom windows or selected sharing controls and camera panel |
| Automatic hiding when sharing starts | No | Enabled by default |
| Compact sharing strip | Not supported | Supported by detection logic |
| Saved menu preferences | No | Yes |
| App and menu-bar icons | Text menu-bar entry | Custom icons |

The development branch also includes further window-restoration fixes. These changes are not yet merged into `main`; its live Zoom behavior still needs verification.

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
2. Make the full floating sharing toolbar visible, including its English **Stop share** and **Pause share** controls.
3. Press **Control + Escape** or choose **Hide / restore controls** in the **Zooom** menu.
4. Press the shortcut again to restore the toolbar.
5. Choose **Restore and quit** when finished.

| Menu item | Action |
| --- | --- |
| Hide / restore controls | Toggle the detected toolbar between its original position and an offscreen position |
| Restore controls | Attempt to bring a previously hidden toolbar back |
| Restore and quit | Restore the toolbar, then quit; remain running if restoration fails |

The menu's first line reports the current status. Ordinary **Escape** is not registered, intercepted, suppressed, or synthesized by the helper. The app does not click meeting controls or send keyboard input to Zoom.

## Recovery and troubleshooting

Window movement can be rejected by macOS or undone by Zoom. The helper verifies that a hidden toolbar is outside all displays and retains its saved position if restoration fails. Display changes trigger an attempt to restore the toolbar onto an available display.

| Status or symptom | What to check |
| --- | --- |
| Accessibility permission required | Enable the installed Zooom app in Accessibility settings |
| No unique English sharing toolbar found | Share your screen and show the full English toolbar; `main` requires exactly one movable match and does not recognize the compact strip |
| Control + Escape is unavailable | Use the menu controls and check whether another app has registered the shortcut |
| Parking failed | Check the toolbar in Zoom; movement may have been refused or constrained |
| Restore failed | Keep the helper running and retry **Restore controls** before quitting or changing permissions |

Use **Restore controls** before revoking Accessibility permission. Recovery state exists only in memory: force-quitting the helper, a crash, or revoking permission can leave a toolbar offscreen.

If recovery fails, try Zoom's own control for showing its floating meeting controls. Its ability to recover an offscreen toolbar is unverified. If needed, finish the meeting normally through Zoom's main window, then restart Zoom. Avoid restarting Zoom during an active meeting just to recover the toolbar.

On `main`, a toolbar larger than the available display area may not satisfy the restoration check. The helper will retain recovery state and refuse a normal quit in that situation.

### Remove the app

Choose **Restore and quit**, remove the installed `Zooom.app`, and remove its entry from Accessibility settings. The helper does not install a login item, launch agent, or background service.

## Privacy and permissions

- All processing takes place locally. The app makes no network requests and includes no analytics or telemetry.
- Accessibility access is used to inspect Zoom's window geometry and control labels, and to move its windows.
- The helper does not capture screen images, audio, video, or meeting transcripts. It does not request Screen Recording or Input Monitoring permission.
- The standalone development branch stores menu preferences locally in UserDefaults. Window recovery state is not persisted across launches.

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
python3 scripts/test-readme.py
```

The documentation check requires Python 3. Core tests run as a Swift executable and do not require XCTest, a running Zoom instance, or production services. The app build uses a temporary Swift build directory and writes its bundle to `dist/`.

On `feature/1-standalone`, also run `./scripts/test-icons.sh` after building. That script and its icon assets do not exist on `main` yet.

### Live integration checklist

Automated checks cannot establish that a particular Zoom version permits offscreen window movement. Before relying on a build, verify these behaviors in a disposable meeting:

- [ ] The intended toolbar is detected and no unrelated window moves.
- [ ] Repeated hide / restore operations work through both the shortcut and menu.
- [ ] Ordinary Escape behaves normally in the foreground application.
- [ ] The meeting, screen sharing and recording remain uninterrupted.
- [ ] Display changes and disconnection allow the toolbar to be recovered.
- [ ] Failed movement, missing permission and shortcut conflicts are handled visibly.
- [ ] **Restore and quit** restores the toolbar before closing.
- [ ] For the standalone branch, automatic hiding, individual window selections, saved preferences and new sharing sessions behave as expected.

### Contributing

Start with a GitHub issue containing a description and acceptance criteria. Work on a separate branch, add relevant automated checks, and run the applicable tests before proposing a merge. Keep unrelated feature work separate.

Historical commits imported before the standalone extraction refer to issue numbers in the original repository. New issue numbers belong to this repository.
